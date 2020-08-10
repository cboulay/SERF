from scipy import signal, version
from scipy.fft import fft
import numpy as np


# Settings
HP_SPIKE_CUTOFF = 250  # in Hz


# common functions
def high_pass_filter(data, filt_order=4, cut_off=250, fs=30000):

    # Filter design
    if version.full_version not in ['1.4.1']:
        sos = signal.butter(filt_order, cut_off / (0.5*fs), 'hp', output='sos')
    else:
        sos = signal.butter(filt_order, cut_off, 'hp', fs=fs, output='sos')

    # mirror pad the signal to remove edge effects
    pad = np.concatenate((np.flip(data[:fs]), data, np.flip(data[-fs:])))

    # filter
    filtered = signal.sosfilt(sos, pad)

    # remove pad
    data = filtered[fs:-fs]

    return data


def band_pass_filter(data, filt_order=4, bp=[13, 30], fs=30000):
    # Filter design
    sos = signal.butter(filt_order, bp, 'bp', fs=fs, output='sos')

    # mirror pad the signal to remove edge effects
    pad = np.concatenate((np.flip(data[:fs]), data, np.flip(data[-fs:])))

    # filter
    filtered = signal.sosfilt(sos, pad)

    # remove pad
    data = filtered[fs:-fs]

    return data


# BlackRock documentation has a 0.25 uV per bit digitization.
def int_to_voltage(data, uV_per_bit=0.25):
    return data * uV_per_bit


def define_complex_morlet(fo, max_segment_length=120000, sampling_rate=30000, c=7):
    """
    Taken from an old Matlab script used for Doucet et al. 2019, Hippocampus.
    %--------------------------------------------------------------------------
    % SR                            Sampling Rate of signal
    % c                             Nomber of wavelet oscillations see :
    %     Hughes, A., Whitten, T., Caplan, J. & Dickson, C. BOSC: A better oscillation
    detection method, extracts both sustained and transient rhythms from rat hippocampal
    recordings. Hippocampus 22, 1417–1428 (2012)
    % fo                            Center frequencies for the wavelet family

    % The value of c should always be > 5, usually use 7 (Tallon-Beaudry et al. 1997)
    % The higher the number, the thighter the wavelets, meaning higher
    % frequency resolution and lower time resolution.

    % When using the STFT, you can adjust the transform window to enhance the
    % desired characteristic. A larger window allows for better frequency
    % resolution, and a smaller window allows for better temporal resolution.
    % However, for the STFT, the window size is constant throughout the algorithm.
    % This can pose a problem for some nonstationary signals. The wavelet
    % transform provides an alternative to the STFT that often provides a better
    % frequency/time representation of the signal.

    % From Tallon-Beaudry 1997 : The time resolution of this method thus
    % increases with frequency, whereas the frequency resolution decreases.

    %Outputs :
    %--------------------------------------------------------------------------
    % coeffs                        Dict with fft transformed wavelet coefficients
    % s_t                           Time decay (gaussian standard deviation)
    % s_f                           Wavelet Spectral Bandwidth
    %--------------------------------------------------------------------------
    """
    sampling_period = 1 / sampling_rate

    # Frequency and time bandwidth
    s_f = fo / c
    s_t = 1 / (2 * np.pi * s_f)

    # our longest wavelet is the lowest frequency
    _x = np.arange(-5 * s_t[0], 5 * s_t[0], sampling_period)

    # set coefficients to match input data shape of : chan x freq x samples
    coeffs = np.zeros((fo.shape[0], max_segment_length), dtype=np.complex128)
    for idx, f in enumerate(fo):
        # complex Morlet wavelet formula (FIND SOURCE)
        coeffs[idx, :] = fft((s_t[idx] * np.sqrt(np.pi)) ** (-1 / 2) *
                             np.exp(-_x ** 2 / (2 * s_t[idx] ** 2)) *
                             np.exp(1j * 2 * np.pi * f * _x), max_segment_length)

    return coeffs, _x.shape[0]
