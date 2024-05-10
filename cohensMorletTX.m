%File: cohensMorletTX.m
%Author: Liam Foulger
%Date Created: 2022-05-22
%Last Updated: 2024-02-05
%
%[h,f,t] = cohensMorletTX(x,freqList,fwhmList,fs)
%
%Function to apply a Morlet Wavelet transform with variable "Full width at
%half maximum". Based off of Mike X Cohen's code & work. 
%Citation:
%Cohen, M. X. (2019). A better way to define and describe Morlet wavelets 
%for time-frequency analysis. NeuroImage, 199, 81–86. 
%https://doi.org/10.1016/j.neuroimage.2019.05.048
%
%Inputs:
%x: data array (n x 1)
%freqList: array of frequencies you want to analyze (m x 1) (Hz)
%fwhmList: array of full widths at half maximum that correspond to each
%element in the frequency list. Note that they shouldn't be shorter than
%1/f and increasing the width will decrease time resolution but increase
%frequence resolution. Read the paper for more info. (m x 1) (seconds)
%fs: sampling rate of data
%Outputs:
%-h: data matrix (m x n)
%-f: frequencies (m x 1) (Hz) AKA the freqList you input
%-t: time points (s) 

function [h,f,t] = cohensMorletTX(x,freqList,fwhmList,fs)

x = x';
pnts = length(x);

% setup wavelet and convolution parameters
wavet = -2:1/fs:2;
halfw = floor(length(wavet)/2)+1;
nConv = pnts + length(wavet) - 1;

%%% time-frequency analysis
frex = freqList;
fwhm = fwhmList;

% initialize time-frequency matrix
h = zeros(length(frex),pnts);

% spectrum of data
dataX = fft(x,nConv);

% loop through each specified frequency
for fi=1:length(frex)
    
    % create wavelet
    waveX1 = fft( exp(2*1i*pi*frex(fi)*wavet).*exp(-4*log(2)*wavet.^2/fwhm(fi).^2),nConv );
    waveX = waveX1./max(waveX1); % normalize
    
    % convolve
    as = ifft( waveX.*dataX );
    % trim and reshape
    as = as(halfw:end-halfw+1);
    h(fi,:) = as;

end

f = freqList;
t = 1/fs:1/fs:length(x)/fs;

end