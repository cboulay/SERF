import time
import numpy as np
import json
from qtpy.QtCore import QSharedMemory
from serf.tools.db_wrap import DBWrapper


class FeaturesWorker:
    def __init__(self):

        # DB wrapper
        self.db_wrapper = DBWrapper()

        # attach to shared memory and read settings
        # shared memory object to receive kill signal
        self.shared_memory = QSharedMemory()
        self.shared_memory.setKey("Features_Process")

        self.procedure_id = None
        self.settings = []
        self.all_datum_ids = []
        self.gt = 0  # fetch datum ids greater than this value

        # process settings
        if self.shared_memory.attach(QSharedMemory.ReadWrite):
            # loop
            self.is_running = True
        else:
            self.is_running = False

    def process_settings(self, sett_str):
        # process inputs
        sett_dict = json.loads(sett_str)
        if 'procedure_id' in sett_dict.keys():
            self.reset_procedure(sett_dict['procedure_id'])

        if 'features' in sett_dict.keys():
            self.reset_features(sett_dict['features'])

    def reset_procedure(self, proc_id):
        self.procedure_id = proc_id
        self.db_wrapper.select_procedure(self.procedure_id)
        self.reset_datum()

    def reset_features(self, feats):
        self.db_wrapper.select_features(feats)
        self.reset_datum()

    def reset_datum(self):
        # we will list all datum for the subject and all feature types that match the settings
        self.all_datum_ids = []
        self.gt = 0

    def read_shared_memory(self):
        if self.shared_memory.isAttached():
            self.shared_memory.lock()
            signal = self.shared_memory.data()
            kill_sig = np.frombuffer(signal[-1], dtype=np.bool)
            settings = ''.join([x.decode('utf-8') for x in signal[:-1] if x != b'\x00'])
            # clear shared_memory
            self.shared_memory.data()[:] = np.zeros((self.shared_memory.size(),), dtype=np.int8).tobytes()
            self.shared_memory.unlock()
        else:
            kill_sig = True
            settings = ''
        return kill_sig, settings

    def run_check(self):
        while self.is_running:
            # check for kill signal or new settings
            kill_sig, new_settings = self.read_shared_memory()

            if kill_sig:
                self.is_running = False
                continue

            if new_settings != '':
                self.process_settings(new_settings)

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


if __name__ == '__main__':
    worker = FeaturesWorker()
    worker.run_check()
