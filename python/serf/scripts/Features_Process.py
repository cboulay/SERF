import time
import numpy as np
import json
import zmq
from qtpy.QtCore import QSharedMemory
from serf.tools.db_wrap import DBWrapper


class FeaturesWorker:
    def __init__(self, zmq_ctrl_port: int=60001):

        # DB wrapper
        self.db_wrapper = DBWrapper()

        context = zmq.Context()
        self._ctrl_sock = context.socket(zmq.SUB)
        self._ctrl_sock.connect(f"tcp://localhost:{zmq_ctrl_port}")
        self._ctrl_sock.setsockopt_string(zmq.SUBSCRIBE, "feature_settings")

        self.procedure_id = None
        self.settings = []
        self.all_datum_ids = []
        self.gt = 0  # fetch datum ids greater than this value

        self.is_running = True

    def process_settings(self, sett_dict):
        # process inputs
        if 'procedure' in sett_dict.keys():
            self.reset_procedure(sett_dict['procedure'])

        if 'features' in sett_dict.keys():
            self.reset_features(sett_dict['features'])

    def reset_procedure(self, proc_dict):
        if "procedure_id" in proc_dict:
            self.procedure_id = proc_dict["procedure_id"]
            self.db_wrapper.select_procedure(self.procedure_id)
            self.reset_datum()

    def reset_features(self, feats):
        self.db_wrapper.select_features(feats)
        self.reset_datum()

    def reset_datum(self):
        # we will list all datum for the subject and all feature types that match the settings
        self.all_datum_ids = []
        self.gt = 0

    def run_forever(self):
        try:
            while self.is_running:
                try:
                    received_msg = self._ctrl_sock.recv_string(flags=zmq.NOBLOCK)[len("feature_settings")+1:]
                except zmq.ZMQError:
                    received_msg = None
                if received_msg:
                    settings_dict = json.loads(received_msg)
                    if "running" in settings_dict and not settings_dict["running"]:
                        self.is_running = False
                        continue
                    self.process_settings(settings_dict)

                new_datum = self.db_wrapper.list_all_datum_ids(gt=self.gt)

                if len(new_datum) > 0:
                    self.all_datum_ids += new_datum

                if len(self.all_datum_ids) > 0:
                    # get oldest data and check if all features have been computed
                    # in case we're stuck with a datum whose feature can't compute, we
                    # want to keep the largest datum id.
                    self.gt = max(self.all_datum_ids + [self.gt])
                    d_id = self.all_datum_ids.pop(0)
                    if not self.db_wrapper.check_and_compute_features(d_id):
                        # re append at the end of the list?
                        self.all_datum_ids.append(d_id)
                time.sleep(0.25)  # test to slow down process to decrease HDD load
                # time.sleep(0.1)
        except KeyboardInterrupt:
            pass


def main():
    worker = FeaturesWorker()
    worker.run_forever()


if __name__ == '__main__':
    main()
