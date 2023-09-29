import numpy as np
from scipy.signal import decimate, iirnotch, filtfilt
from scipy.fft import fft, ifft
from scipy.stats import chi2, linregress
from serf.tools.utils.misc_functions import *
import os
import logging
from serf.tools.features.base.FeatureBase import FeatureBase

logger = logging.getLogger(__name__)

FS = 30000  # sampling frequency of raw signal
SR = 1000  # down sampled LFP rate

BETABAND = [13, 30]
GAMMABAND = [60, 200]
MAXSEGLEN = 2**14


# LFP
class LFPSpectrumAndEpisodes(FeatureBase):

    name = "LFPSpectrumAndEpisodes"
    desc = "Processes features from the LFPs: average power, p_episodes"
    category = "LFP"

    def __init__(self, db_id):
        super(LFPSpectrumAndEpisodes, self).__init__(db_id)

        # we will decimate the signal to 1kHz before running the analyses so we will set
        # a maximal segment length 2**14, which is plenty considering our ~3000 wavelet samples.
        # It will accept maximal segments lengths of ~13.5 seconds.
        self.seg_len = MAXSEGLEN
        self.fo = 4 ** np.arange(1, 4.1, 0.1)  # 4 - 256 Hz, 31 bands
        self.ds_factor = FS//SR
        self.wavelets, self.n = define_complex_morlet(self.fo,
                                                      max_segment_length=self.seg_len,
                                                      sampling_rate=SR,
                                                      c=7)
        self.pwr_thresholds = None

    def pre_process_data(self, data):
        # decimate, with anti-aliasing filter, the data to 1kHz.
        # from the scipy documentation :
        #     When using IIR downsampling, it is recommended to call decimate multiple times
        #     for downsampling factors higher than 13.
        ds_factor = self.ds_factor
        while ds_factor > 10:
            data = decimate(data, 10)
            ds_factor //= 10

        # We will then decimate by a factor of 10 until the factor is < 10
        data = decimate(data, ds_factor)

        # notch filter @ 60Hz
        b, a = iirnotch(60, 30.0, fs=SR)
        data = filtfilt(b, a, data)

        # notch filter @ 120Hz
        b, a = iirnotch(120, 60.0, fs=SR)
        data = filtfilt(b, a, data)

        # notch filter @ 180Hz
        b, a = iirnotch(180, 90.0, fs=SR)
        data = filtfilt(b, a, data)

        # notch filter @ 240
        b, a = iirnotch(240, 120.0, fs=SR)
        data = filtfilt(b, a, data)
        return data - np.atleast_2d(np.mean(data, axis=1)).T

    def compute_power(self, data):
        # FFT transform of data to speed up convolution with wavelets
        fft_data = fft(data, n=self.seg_len)
        # data is channel x samples, need to change to chan x freq x sample
        fft_data = np.atleast_3d(fft_data).reshape((fft_data.shape[0], 1, fft_data.shape[1]))

        pwr = np.abs(ifft(fft_data * self.wavelets)) ** 2
        # # remove zero padding
        return pwr[:, :, self.n // 2:self.n // 2 + pwr.shape[2]]

    def compute_pwr_thresholds(self, pwr):
        # compute power threshold from chi-square distribution
        df = 2
        thresh_ppf = chi2.ppf(.95, df)
        reg_pwr = np.zeros((pwr.shape[0], pwr.shape[1]))

        for idx, p in enumerate(pwr):
            avg_pwr = np.mean(p, axis=1)
            # linear regression on power data
            slope, intercept, r_value, p_value, std_err = linregress(np.log2(self.fo), 10 * np.log10(avg_pwr))

            # linear regression power converted to chi2 distribution
            reg_pwr[idx, :] = 10 ** ((np.log2(self.fo) * slope + intercept) / 10)

        # power thresholds
        return reg_pwr * (thresh_ppf / df)

    def compute_p_episodes(self, pwr, pwr_thresholds, n_periods=3):
        # 3 periods * 1kHz
        dur_thresholds = (n_periods * SR) // self.fo
        cross = np.greater(pwr, np.atleast_3d(pwr_thresholds)).astype(int)

        # since diff.shape[1] = cross.shape[1]-1 and the first sample might be above threshold
        # we need to concatenate the first cross column.
        diffs = np.concatenate((cross[:, :, 0:1], np.diff(cross, axis=2)), axis=2)

        # if the last sample is > threshold, need to set it's value to -1 only if
        # it is not the first threshold crossing sample
        diffs[np.logical_and(cross[:, :, -1] == 1, diffs[:, :, -1] == 0), -1] = -1
        diffs[diffs[:, :, -1] != -1, -1] = 0

        s_c, s_f, s_idx = np.nonzero(diffs == 1)
        e_c, e_f, e_idx = np.nonzero(diffs == -1)

        durations = e_idx - s_idx
        p_idx = np.nonzero(durations > dur_thresholds[s_f])
        p_episodes = np.zeros((pwr.shape[0], self.fo.shape[0]))

        # returns proportion of segment with oscillations
        for c, f, dur in zip(s_c[p_idx], s_f[p_idx], durations[p_idx]):
            p_episodes[c, f] += dur

        return p_episodes / pwr.shape[2]

    def run(self, data):
        data = self.pre_process_data(data)
        pwr = self.compute_power(data)
        pwr_thresholds = self.compute_pwr_thresholds(pwr)
        p_episodes = self.compute_p_episodes(pwr, pwr_thresholds)

        # we will combine the average beta power and p_episodes in one struct
        # chan x value, in this case values are 31 frequencies power, 31 frequencies p_episodes
        out_data = np.concatenate((pwr.mean(axis=2),
                                   p_episodes), axis=1)

        return out_data, self.fo


class MultiTaperSpectrum(FeatureBase):
    name = "MultiTaperSpectrum"
    desc = """ Functions for multi-taper power spectral density estimation. """
    category = "LFP"

    def run(self, data, tapers=None, fs=30000, time_half_bandwidth=2., k=None, onesided=True,
            nfft=None, return_with_raw=False):
        """Power spectral density estimate using the Thomson multitaper method."""
        from scipy.fftpack import fft, fftfreq
        out_data = None

        for idx, X in enumerate(data):
            if X.shape[0] == X.size:
                X = X.reshape((-1, 1))

            tapers, N, k = get_tapers(tapers, X.shape, time_half_bandwidth, k)

            if nfft is None:
                nfft = N

            # compute spectral density under each taper
            taperX = X.reshape(X.shape + (1,)) * tapers.reshape((X.shape[0], 1, -1))
            # noinspection PyTypeChecker
            try:
                _result = fft(taperX, n=nfft, axis=0)
            except MemoryError:
                # Workaround for what looks like an MKL bug (uses too much mem)
                print("Got MemoryError in fft with data shape %s; running trial by "
                      "trial." % (taperX.shape,))
                _result = np.nan*np.ones((nfft,) + taperX.shape[1:], dtype=complex)
                taperX_tmp = taperX.reshape(taperX.shape[0], -1)
                result_tmp = _result.reshape(_result.shape[0], -1)
                for k in range(result_tmp.shape[1]):
                    result_tmp[:, k] = fft(taperX_tmp[:, k])

            # keep desired number of freq bins
            if np.iscomplexobj(X) or not onesided:
                num_freqs = nfft
            else:
                num_freqs = (nfft + 1) // 2 if nfft % 2 else nfft // 2 + 1
            freqs = fftfreq(nfft, 1 / fs)[:num_freqs]
            _result = _result[:num_freqs, ...]

            Pxx = (np.abs(_result))**2

            if fs is None:
                Pxx /= (2 * np.pi)
                fs = 1.0
            else:
                Pxx /= fs

            # make sure that power is doubled in case of a onesided spectrum
            if num_freqs < nfft:
                if nfft % 2:
                    Pxx[1:, ...] *= 2
                else:
                    # (last point is unpaired Nyquist freq and requires special treatment)
                    Pxx[1:-1, ...] *= 2
                    freqs[-1] *= -1

            # average across tapers
            Pxx = np.sum(Pxx, axis=-1) / k

            if return_with_raw:
                return Pxx, freqs, _result, nfft

            if out_data is None:
                out_data = np.zeros((data.shape[0], Pxx.shape[0]))

            # Pxx is a (60000,1) array, need to flatten
            out_data[idx, :] = Pxx.flatten()

        return out_data, freqs


def get_tapers(tapers, data_shape, time_half_bandwidth, k):
    if tapers is None:
        tapers = dpss(data_shape[0], time_half_bandwidth, k)
    N = tapers.shape[0]
    max_tapers = tapers.shape[1]

    # sanity checks
    # To be coherent with other tools, the pmtm function uses 2*nw-1 tapers
    if k is None:
        k = max_tapers - 1
    if k > max_tapers:
        k = max_tapers - 1
        logger.warning('More tapers were requested than have been precomputed. '
                       'We will use a maximum of %s.' % k)
    if tapers.shape[0] != data_shape[0]:
        raise Exception('The data and tapers arrays must have the same length '
                        'along the first dimension. ')
    if float(time_half_bandwidth) / N > 0.5:
        logger.warning('Time-bandwidth product is greater than 0.5. Cannot '
                       'satisfy this. Increase your bandwidth, or time window '
                       'appropriately.')

    # prune tapers to first k (if needed)
    return tapers[:, 0:k], N, k


def dpss(window_length=1000, time_half_bandwidth=2.5, k=None):
    """
    Compute the desired discrete prolate spheroidal (Slepian) sequences using
    a precomputed version on stored locally.
    """
    from scipy.interpolate import interp1d

    # load precomputed tapers from disk or mem cache
    try:
        w = dpss.cached_w
    except AttributeError:
        from scipy.io import loadmat
        folder = os.path.dirname(__file__)
        filename = os.path.join(folder, '../resources/dpss.mat')
        dpss.cached_w = loadmat(os.path.normpath(filename))['w']
        w = dpss.cached_w

    # get # of sample points in the db (n), and # taper sets in the db (m)
    n = w[0, 0].shape[0]
    m = w.shape[1]

    # used to compute lookup position in db
    max_tapers = np.ceil(2 * time_half_bandwidth)
    # sanity checks
    if max_tapers > m:
        max_tapers = m
        logger.warning('The chosen half-bandwidth requires more tapers than '
                       'have been precomputed. We will use a maximum of '
                       '%s.' % max_tapers)

    # To be coherent with other tools, the DPSS function returns 2*nw tapers
    if k is None:
        k = max_tapers
    if k > max_tapers:
        k = max_tapers
        logger.warning('More tapers were requested than have been precomputed. '
                       'We will use a maximum of %s.' % k)

    # get index of correct set of DPSS tapers
    # taper sets are stored in ascending order from num_tapers = 2,3,...,100
    idx = max_tapers - 2

    # look up tapers and prune their number to k (also, we want it in double)
    tapers = np.array(w[0, int(idx)][:, 0:int(k)].T, dtype=float)

    # interpolate onto the desired number of samples
    f = interp1d(np.linspace(0, 1, n), tapers)
    return np.sqrt(float(n) / window_length) * f(np.linspace(0, 1,
                                                             window_length)).T

