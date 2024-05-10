%File: powerFFT.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2024-04-17
%
% [f, power, phase] = powerFFT(signal, windowLength, fs, NamePairArguments)
%
% Function to calculate the power spectrum of a signal. Validated against
% neurospec2.0 - note that they normalize by 2pi*n, whereas I just
% normalize by n
%
% Inputs:
% - signal (nm x 1 OR n x m) (n = number of samples in window, m is
% number of windows)
% - length of window for fft analysis (s)
% - signal sample rate (Hz)
% - NamePairArguments:
%   - 'padding': number of zeros added to each end of segments
%   - 'window': type of windowing done on segment: 'square' (default),
%   'hanning', & 'hamming'
% Outputs: 
% - f: array of frequencies (Hz) (n/2 + 1, 1)
% - power spectrum of input signal (n/2 + 1, 1)
% - phase of signal (n/2 + 1, 1)

function [f, power, phase] = powerFFT(signal, windowLength, fs, NamePairArguments)
arguments 
        signal double
        windowLength double
        fs double
        NamePairArguments.padding (1,1) {mustBeNumeric} = 0
        NamePairArguments.window (1,1) string = "square"
        NamePairArguments.includeDC (1,1) logical = false
    end

    %remove mean
    signal = signal - mean(signal);    

    if size(signal,2) > 1    %check if signals are already reshaped
        signalR = signal;
        N = size(signal,1);
    else
        N = windowLength*fs;

        %determine number of sections based on window length
        numSegs = floor(length(signal)/N);
        %trim ends if segments do not fit evenly in signals
        signal = signal(1:(N*numSegs));

        %split signals into matrix of with each section as column
        signalR = reshape(signal, [N, numSegs]);
    end
    if NamePairArguments.padding > 0
        pad = zeros(NamePairArguments.padding, size(signalR,2));
        signalR = [pad; signalR; pad];
        N = size(signalR,1);
    end
    
    switch NamePairArguments.window
        case 'square'
            wind = ones(N,1);
        case 'hamming'
            wind = hamming(N);
        case 'hanning'
            wind = hann(N);
        case 'bartlett'
            wind = bartlett(N);
    end
    %apply window
    signalR = signalR.*wind;

    %get FFT 
    signalFFT = fft(signalR);
    
    %calculate auto and cross spectra
    autoInput = 1/(N).*real(signalFFT.*conj(signalFFT));
    f = linspace(0,fs/2,N/2 + 1);
    %average across windows to get total 
    power = mean(autoInput,2);
    power = power(1:N/2+1);
    %calculate phase
    phase = mean(unwrap(atan(imag(signalFFT)./real(signalFFT)),[],1),2);
    phase = phase(1:N/2+1);

    % include DC offset?
    if ~NamePairArguments.includeDC
        f = f(2:end);
        power = power(2:end);
        phase = phase(2:end);

    end
end