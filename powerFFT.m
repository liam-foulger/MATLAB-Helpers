%File: powerFFT.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-12
%
%[f, power] = powerFFT(signal, windowLength, fs)
%
%Function to calculate the power spectrum of a signal
%(NOT YET VALIDATED WITH NEUROSPEC!!!!!)
%
%Inputs:
% - signal (n x 1)
% - length of window for fft analysis (s)
% - signal sample rate (Hz)
%Outputs: 
% - f: array of frequencies (Hz)
% - power spectrum 

function [f, power] = powerFFT(signal, windowLength, fs)

    N = windowLength*fs;
    f = linspace(0,fs/2,N/2 + 1);
    
    %determine number of sections based on window length
    numSegs = floor(length(signal)/N);
    
    %remove means
    signal = signal - mean(signal);
    
    %trim ends if segments do not fit evenly in signals
    signal = signal(1:(N*numSegs));
    
    %split signals into matrix of with each section as column
    signalR = reshape(signal, [N, numSegs]);
    
    %get FFT 
    signalFFT = fft(signalR);
    
    %calculate auto and cross spectra
    autoInput = 1/(N*numSegs).*real(signalFFT.*conj(signalFFT));
    
    
    %sum across windows to get total 
    power = mean(autoInput,2);
    power = power(1:N/2+1);
    
end