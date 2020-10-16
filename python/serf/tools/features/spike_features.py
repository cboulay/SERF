import numpy as np
from serf.tools.utils.misc_functions import int_to_voltage, high_pass_filter
from serf.tools.features.base.FeatureBase import FeatureBase


class DBSSpikeFeatures(FeatureBase):
    name = "DBSSpikeFeatures"
    desc = "Computes: NoiseRMS, Spike Rate, Burst Index, Fano Factor"
    category = "Spikes"

    def __init__(self, db_id, sr=30000):
        super(DBSSpikeFeatures, self).__init__(db_id)
        self.SR = sr

    def run(self, data):
        """
        :param data:
            n_channel x n_samples numpy array a
        :return:
            n_channel x 4 [RMS, Rate, BI, FF]
        """
        out_data = np.zeros((data.shape[0], 4), dtype=np.float)
        for idx, dat in enumerate(data):
            dat = high_pass_filter(int_to_voltage(dat))

            # RMS value =====================================================
            # settings
            bin_size = 600
            n_bins = int(np.floor(dat.shape[0] / bin_size))

            s_dat = np.square(dat)
            bins = [np.mean(s_dat[x * bin_size:(x + 1) * bin_size]) for x in range(n_bins)]
            bins = np.sort(bins)

            # discard the first 5% samples and keep the following 20%
            start_idx = int(0.05 * bins.shape[0])
            stop_idx = int(0.2 * bins.shape[0]) + start_idx

            # RMS
            _RMS = np.sqrt(np.mean(bins[start_idx:stop_idx]))

            # Spike Rate ===============================================
            rms_mult = 4
            # delay before a second threshold crossing can be detected (BlackRock Settings)
            refractory_period = 38

            # find threshold crossings and remove contiguous samples
            thresh_cross = np.where(dat < - (rms_mult * _RMS))[0]
            diffs = np.diff(thresh_cross)
            to_keep = (diffs != 1) & (diffs > refractory_period)
            # always keep first threshold crossing
            if len(to_keep) > 0:
                to_keep = np.hstack((np.array([True], dtype=bool), to_keep.flatten()))
            thresh_cross = thresh_cross[to_keep]
            _Rate = len(thresh_cross) / dat.shape[0] * self.SR

            # Burst index ====================================================
            # from (Pralong et al., 2004) and (Hutchison et al., 1997; 1998) we define the BurstIndex as:
            # reciprocal of (time of peak in ISI histogram / mean firing rate of spike train)
            # ISI histogram is 250 bins 0-500 ms, 2 ms per bin
            if len(thresh_cross) > 0:
                ISI = np.diff(thresh_cross) / self.SR
                counts, edges = np.histogram(ISI, bins=500, range=(0, 0.5))

                # center of peak
                peak = np.where(counts == np.max(counts))[0] + 1
                _BI = np.mean(ISI) / float(edges[peak[0]])

                # Fano Factor
                # 100 ms bins @ 30 kHz: 3000 samples
                # assuming a "trial" of 100 ms, we will compute the std/mean of spike counts in each
                # "trial" and get the fano factor from these trials.
                win_size = 0.100  # sec
                overlap = 0.50  # %
                sample_per_bin = win_size * self.SR
                bins = np.arange(0, dat.shape[0], int(overlap * sample_per_bin))
                counts = [np.sum((thresh_cross >= x) & (thresh_cross < x + sample_per_bin)) for x in bins]
                _FF = (np.std(counts) ** 2) / np.mean(counts)
            else:
                _BI = 0
                _FF = 0

            # Some values are float64 for some reason.
            out_data[idx, 0] = np.float(_RMS)
            out_data[idx, 1] = np.float(_Rate)
            out_data[idx, 2] = np.float(_BI)
            out_data[idx, 3] = np.float(_FF)

        return out_data, np.zeros((out_data.shape[1],))


