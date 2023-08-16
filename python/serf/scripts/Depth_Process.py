import time
import json
import numpy as np
import zmq
from cerebuswrapper import CbSdkConnection
from pylsl import stream_inlet, resolve_byprop
from django.utils import timezone
from serf.tools.db_wrap import DBWrapper


class NSPBufferWorker:

    def __init__(self, zmq_ctrl_port=60001, zmq_depth_port=60002):
        self.current_depth = None

        # try to resolve LSL stream
        # TODO: Use ZeroMQ
        self.depth_inlet = None
        self.resolve_stream()

        # DB wrapper
        self.db_wrapper = DBWrapper()

        # ZeroMQ subscription
        context = zmq.Context()
        self._ctrl_sock = context.socket(zmq.SUB)
        self._ctrl_sock.connect(f"tcp://localhost:{zmq_ctrl_port}")
        self._ctrl_sock.setsockopt_string(zmq.SUBSCRIBE, "feature_settings")

        # ZeroMQ publisher
        self._depth_sock = context.socket(zmq.PUB)
        self._depth_sock.bind(f"tcp://*:{zmq_depth_port}")

        # cbSDK; connect using default parameters
        self.cbsdk_conn = CbSdkConnection(simulate_ok=False)
        self.cbsdk_conn.connect()

        # Default settings
        self._buffer_dur = 6.0
        self._sample_dur = 4.0
        self._new_depth_delay = 0.5
        self._validity_thresh = 0.9
        self._sampling_group_id = 5
        self._reset_group_info()
        self.reset_buffer()

        self.start_time = timezone.now()
        self._depth_sock.send_string(f"depth_status startup")
        self.is_running = True

    def _reset_group_info(self):
        self.group_info = self.cbsdk_conn.get_group_config(self._sampling_group_id)
        self.n_chan = len(self.group_info)
        self.valid_electrodes = [x["chan"] for x in self.group_info]
        self.sampling_rate = 30000  # TODO: Get from sampling_group_id
        self.buffer_length = int(self.sampling_rate * self._buffer_dur)
        self.sample_length = int(self.sampling_rate * self._sample_dur)
        self.delay_length = int(self.sampling_rate * self._new_depth_delay)
        self.overwrite_depth = True
        # default values, might be overwritten by electrode_settings
        self.validity_threshold = [self.sample_length * self._validity_thresh] * self.n_chan
        self.threshold = [False] * self.n_chan

    def process_settings(self, sett_dict):
        # process inputs
        sett_keys = list(sett_dict.keys())

        if "procedure" in sett_keys and "procedure_id" in sett_dict["procedure"]:
            self.reset_procedure(sett_dict["procedure"]["procedure_id"])

        if "sampling_group_id" in sett_keys:
            self._sampling_group_id = sett_dict["sampling_group_id"]
            # self._validity_thresh = sett_dict["???"]
            self._reset_group_info()
            self.reset_buffer()

        if "buffer" in sett_keys and "electrode_settings" in sett_dict["buffer"]:
            for ii, info in enumerate(self.group_info):
                label = info["label"]
                if label in sett_dict["buffer"]["electrode_settings"]:
                    el_sett = sett_dict["buffer"]["electrode_settings"][label]
                    self.threshold[ii] = bool(el_sett["threshold"])
                    self.validity_threshold[ii] = float(el_sett["validity"]) / 100 * self.sample_length

    def reset_procedure(self, proc_id):
        self.procedure_id = proc_id
        self.db_wrapper.select_procedure(self.procedure_id)

    def reset_buffer(self):
        self.buffer = np.zeros((self.n_chan, self.buffer_length), dtype=np.int16)
        self.buffer_idx = 0
        # for each channel we will keep a bool array whether each sample point is valid or not
        # when a condition is met to trigger sending the sample to the DB we will pick the window
        # with highest validity count.
        self.validity = np.zeros((self.n_chan, self.buffer_length), dtype=bool)
        self.valid_idx = (0, 0)

        self.delay_counter = 0
        self.update_buffer_status = True
        self.delay_done = False

    def clear_buffer(self):
        if self.buffer is None:
            self.reset_buffer()
        self.buffer.fill(0)
        self.buffer_idx = 0

        self.validity.fill(False)
        # list of tuples: (index of validity value, value)
        # saves the index with largest validity across all channels
        self.valid_idx = (0, 0)
        self.delay_counter = 0

        self.update_buffer_status = True
        self.delay_done = False
        # self.start_time = timezone.now()

    def wait_for_delay_end(self, data):
        data_length = data[0][1].shape[0]
        self.delay_counter += data_length
        # check if we have accumulated enough data to end delay and start recording
        if self.delay_counter <= self.delay_length:
            return False
        else:
            # truncate the data to the first index over the delay period
            start_idx = max(0, int(self.delay_length - self.delay_counter))
            for chan_idx, (chan, values) in enumerate(data):
                data[chan_idx][1] = values[start_idx:]

            # now is for the last sample. subtract data length / SAMPLINGRATE to get time of first sample
            self.start_time = timezone.now()
            time_delta = timezone.timedelta(seconds=data[0][1].shape[0] / self.sampling_rate)
            self.start_time -= time_delta

            self._depth_sock.send_string(f"depth_status recording")
            return True

    def resolve_stream(self):
        # will register to LSL stream to read electrode depth
        info = resolve_byprop('source_id', 'depth1214', timeout=1)
        if len(info) > 0:
            self.depth_inlet = stream_inlet(info[0])
            sample = self.depth_inlet.pull_sample(0)
            # If new sample
            if sample[0]:
                self.current_depth = sample[0][0]

    def run_buffer(self):
        prev_status = None
        while self.is_running:
            try:
                received_msg = self._ctrl_sock.recv_string(flags=zmq.NOBLOCK)[len("feature_settings")+1:]
                settings_dict = json.loads(received_msg)
                # Check for kill signal
                if "running" in settings_dict and not settings_dict["running"]:
                    self.is_running = False
                    continue
                # Process remaining settings
                self.process_settings(settings_dict)
            except zmq.ZMQError:
                received_msg = None
            
            # collect NSP data, regardless of recording status to keep cbsdk buffer empty
            # data is a list of lists.
            # 1st level is a list of channels
            # 2nd level is a list [chan_id, np.array(data)]
            data = self.cbsdk_conn.get_continuous_data()
            # Only keep channels within our sampling group
            data = [x for x in data if x[0] in self.valid_electrodes]

            # only process the NSP data if Central is recording
            _status = "recording" if self.cbsdk_conn.get_recording_state() else "notrecording"
            if _status == "recording" and data and self.current_depth:

                if not self.delay_done:
                    self.delay_done = self.wait_for_delay_end(data)

                # Only process if we are in a new depth, past the delay, and we didn't just send a snippet to the db.
                if self.delay_done and self.update_buffer_status:
                    # all data segments should have the same length, so first check if we run out of buffer space
                    data_length = data[0][1].shape[0]
                    if (self.buffer_idx + data_length) >= self.buffer_length:
                        # if we run out of buffer space before data has been sent to the DB few things could have gone
                        # wrong:
                        #   - data in buffer is not good enough
                        #   - the new data chunk is larger than the difference between buffer and sample length
                        #       (e.g. 6s buffer and 4s sample, if the current buffer has 3s of data and it receives a 4s
                        #       long chunk then the buffer would overrun, and still not have enough data to send to DB.
                        #       Although unlikely in real-life, it happened during debugging.)

                        # trim data to only fill the buffer, discarding the rest
                        # TODO: is this the optimal solution? Slide buffer instead?
                        data_length = self.buffer_length - self.buffer_idx

                    # continue to validate received data
                    for chan_idx, (chan, values) in enumerate(data):

                        if data_length > 0:
                            # Validate data
                            valid = self.validate_data_sample(values[:data_length])

                            # append data to buffer
                            self.buffer[chan_idx,
                                        self.buffer_idx:self.buffer_idx + data_length] = values[:data_length]

                            self.validity[chan_idx,
                                          self.buffer_idx:self.buffer_idx + data_length] = valid
                            
                            _status = "accumulating"

                    # increment buffer index, all data segments should have same length, if they don't, will match
                    # the first channel
                    self.buffer_idx += data_length

                    # check if data length > sample length
                    if self.buffer_idx >= self.sample_length:

                        # compute total validity of last sample_length and if > threshold, send to DB
                        sample_idx = self.buffer_idx - self.sample_length

                        temp_sum = [np.sum(x[sample_idx:self.buffer_idx]) for x in self.validity]

                        # check if validity is better than previous sample, if so, store it
                        if np.sum(temp_sum) > self.valid_idx[1]:
                            self.valid_idx = (sample_idx, np.sum(temp_sum))

                        if all(x >= y for x, y in zip(temp_sum, self.validity_threshold)) or \
                                self.buffer_idx >= self.buffer_length:
                            # We have accumulated enough data for this depth. Send to db!
                            stored = self.send_to_db()
                            if stored:
                                _status = "done"

            # check for new depth
            # At this point, the individual channels have either been sent to the DB or are still collecting waiting for
            # either of the following conditions: acquire sufficient data (i.e. sample_length) or acquire sufficiently
            # clean data (i.e. validity_threshold). If the channel is still acquiring data but has sufficiently long
            # segments, we will send the cleanest segment to the DB (i.e. valid_idx).
            if not self.depth_inlet:
                self.resolve_stream()
            else:
                depth, ts = self.depth_inlet.pull_sample(0)
                # If new sample
                if depth:
                    # New depth
                    if depth[0] != self.current_depth or self.overwrite_depth:
                        # We are moving on. If still updating the buffer, then we can check to see if we have 
                        #  enough valid samples -- though maybe not high quality -- and save the best available segment.
                        if self.update_buffer_status:
                            _ = self.send_to_db()

                        # New depth verified. Let's clear the buffer for accumulation again.
                        self.clear_buffer()
                        self.current_depth = depth[0]

            # Optionally publish the recording status.
            b_send_status = prev_status is None  # Previously unknown
            # or status has changed, but not from done->recording -- we'd like to keep the "done" status for a bit.
            b_send_status |= _status != prev_status and not (prev_status == "done" and _status == "recording")
            if b_send_status:
                self._depth_sock.send_string(f"depth_status {_status}")
                prev_status = _status

            time.sleep(.010)

    def send_to_db(self):
        do_save = self.valid_idx[1] != 0
        # if we actually have a computed validity (i.e. segment is long enough)
        if do_save:
            # the info that needs to be sent the DB_wrapper is:
            #   Datum:
            #       - subject_id
            #       - is_good : to be determined by validity values
            #       - start_time / stop_time ?
            #   Datum Store:
            #       - channel_labels : from group_info
            #       - erp : actual data
            #       - n_channels and n_samples : determined by data size
            #       - x_vec: time ?
            #   DatumDetailValue:
            #       - detail_type: depth (fetch from DetailType
            #       - value: depth value
            self.db_wrapper.save_depth_datum(depth=self.current_depth,
                                             data=self.buffer[:,
                                                              self.valid_idx[0]:self.valid_idx[0]+self.sample_length],
                                             is_good=np.array([x >= y for x, y in zip(
                                                 np.sum(self.validity[:, self.valid_idx[0]:
                                                        self.valid_idx[0] + self.sample_length], axis=1),
                                                 self.validity_threshold)], dtype=bool),
                                             group_info=self.group_info,
                                             start_time=self.start_time,
                                             stop_time=timezone.now())
        self.update_buffer_status = False
        return do_save

    @staticmethod
    def validate_data_sample(data):
        # TODO: implement other metrics
        # SUPER IMPORTANT: when cbpy returns an int16 value, it can be -32768, however in numpy:
        #     np.abs(-32768) = -32768 for 16 bit integers since +32768 does not exist.
        # We therefore can't use the absolute value for the threshold.
        threshold = 30000  # arbitrarily set for now
        validity = np.array([-threshold < x < threshold for x in data])

        return validity


def main():
    worker = NSPBufferWorker()
    worker.run_buffer()


if __name__ == '__main__':
    main()
