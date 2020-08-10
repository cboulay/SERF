import numpy as np
from serf.tools.utils.misc_functions import *
from scipy.signal import hilbert, decimate, filtfilt, iirnotch
from scipy.fft import fft, ifft, next_fast_len
from scipy.stats import linregress, chi2
from serf.tools.features.base.FeatureBase import FeatureBase
from pytf import FilterBank
from mspacman.algorithm.pac_ import (pad, pac_mi)

FS = 30000

BETABAND = [13, 30]
GAMMABAND = [60, 200]
MAXSEGLEN = 2**14


# DBS Features
class BetaPower(FeatureBase):
    name = "BetaPower"
    desc = "Band-Pass filter in the beta 13-30Hz range then np.abs(Hilbert)**2."
    category = "DBS"

    def run(self, data):
        """
        input datum store erp field and returns the mean RMS for the segment

        :param data:
            n_channel x n_samples numpy array a
        :return:
            n_channel x 1 RMS value
        """
        out_data = np.zeros((data.shape[0], 1))
        for idx, dat in enumerate(data):
            dat = int_to_voltage(dat)

            dat = band_pass_filter(dat, filt_order=4, bp=BETABAND)

            pwr = np.abs(hilbert(dat))**2

            out_data[idx] = np.mean(pwr)

        return out_data, np.zeros((out_data.shape[1],))


class NoiseRMS(FeatureBase):
    name = "NoiseRMS"
    desc = "Based on BlackRock's algorithm detailed in: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4332592/"
    # The behavior is described for 2 seconds of data (i.e. 100 mean-squared values of 600 samples = 60 000 samples)
    # - Filter for spikes: usually HP 250Hz 4th order Butterworth (BlackRock digital filter)
    # - Square all values
    # - Average values in 100 windows of 600 samples
    # - Discard the 5 lowest values and compute the sqrt of the average of the next 20 values
    # Since we will have segments of varying length, we will use 20% of the resulting samples to compute the RMS and
    # discard the lowest 5%
    # :param data: Neural data segment to compute noise RMS on. It is a Channel x Sample np.array
    # :return: RMS values for each channel and an array of 0s, one for each channel as the x_axis values"""
    category = "DBS"

    def run(self, data):
        """
        input datum store erp field and returns the mean RMS for the segment

        :param data:
            n_channel x n_samples numpy array a
        :return:
            n_channel x 1 RMS value
        """
        out_data = np.zeros((data.shape[0], 1))
        for idx, dat in enumerate(data):
            dat = high_pass_filter(dat)
            dat = np.square(dat)

            bin_size = 600
            n_bins = int(np.floor(dat.shape[0] / 600))
            bins = [np.mean(dat[x*bin_size:(x+1)*bin_size]) for x in range(n_bins)]

            # sort bins values
            bins = np.sort(bins)

            # discard the first 5% samples and keep the following 20%
            start_idx = int(0.05 * bins.shape[0])
            stop_idx = int(0.2 * bins.shape[0]) + start_idx

            avg = np.sqrt(np.mean(bins[start_idx:stop_idx]))

            # convert to voltage values
            avg = int_to_voltage(avg)

            out_data[idx] = avg

        return out_data, np.zeros((out_data.shape[1],))


class PAC(FeatureBase):

    name = "PAC"
    desc = """ Using MSPACMAN algorithm to compute Beta to high-gamma PAC. """
    category = "DBS"

    def __init__(self, db_id):
        super(PAC, self).__init__(db_id)

        # Create the filter banks
        decimate_by = 30
        fpsize = BETABAND[1] - BETABAND[0] + 1  # number of frequencies for phase
        fasize = np.int(np.round((GAMMABAND[1] - GAMMABAND[0]) / 10) + 1)   # number of frequencies for amp

        # from Dvorak and Fenton, JNeurosciMeth, 2014:
        #     For accurate PAC estimation, standard PAC algorithms require amplitude filters with a bandwidth
        #     at least twice the modulatory frequency. The phase filters must be moderately narrow-band, especially
        #     when the modulatory rhythm is non-sinusoidal. The minimally appropriate analysis window is ∼10 s.
        # As our highest beta band frequency is 30 Hz we set the gamma bandwidth to be 60Hz.
        bw_p = 2  # band width phase
        bw_a = 60  # band width amplitude

        # Get the phase-giving and amplitude-enveloping signals for comodulogram
        fp = np.linspace(BETABAND[0], BETABAND[1], fpsize)  # 13 - 30 Hz, 18 freqs; 1 Hz steps
        fa = np.linspace(GAMMABAND[0], GAMMABAND[1], fasize)  # 60 - 200 Hz, 15 steps; 10Hz steps

        fois_lo = np.asarray([(f - bw_p, f + bw_p) for f in fp])
        fois_hi = np.asarray([(f - bw_a, f + bw_a) for f in fa])

        self.los = FilterBank(binsize=2 ** 14,
                              freq_bands=fois_lo,
                              order=2 ** 12,
                              sample_rate=FS,
                              decimate_by=decimate_by,
                              hilbert=True)

        self.his = FilterBank(binsize=2 ** 14,
                              freq_bands=fois_hi,
                              order=2 ** 12,
                              sample_rate=FS,
                              decimate_by=decimate_by,
                              hilbert=True)

    def run(self, data):

        """
        input datum store erp field and returns mean and peak MI value for Beta-high-gamma PAC.

        :param data:
            n_channel x n_samples numpy array
        :return:
            n_channel x 2 MI value [peak, average, std]
        """
        data = int_to_voltage(data)

        x_los = self.los.analysis(data, window='hanning')
        x_his = self.his.analysis(data, window='hanning')

        angs, amps = np.angle(x_los), np.abs(x_his)

        # Compute PAC
        # phase-amplitude distribution (pad)
        pds = pad(angs, amps, nbins=10)
        # modulation indices: chan x los x his
        mis = pac_mi(pds)

        out_data = np.concatenate((np.atleast_2d(mis.max(axis=(2, 1))).T,
                                   np.atleast_2d(mis.mean(axis=(2, 1))).T,
                                   np.atleast_2d(mis.std(axis=(2, 1))).T), axis=1)

        return out_data, np.zeros((out_data.shape[1],))
