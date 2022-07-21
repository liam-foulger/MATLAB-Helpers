%File: invCross.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-13
%
%xCorr = invCross(input, output, windowLength, fs)
%
%Function to calculate the cross correlation as the inverse fft of the
%autospectrum
%(Note I've validated that this works correctly with Neurospec 2.0)
%
%Inputs:
% - input signal (n x 1)
% - output signal (n x 1)
% - length of window for fft analysis (s)
% - signal sample rate (Hz)
%Outputs: 
% - t: time lag (s)
% - cumulant density/ x-corr

function [t,xCorr] = invCross(input, output, windowLength, fs)
    %set up
    N = windowLength*fs;
    numSegs = floor(length(input)/N);
    t=((1:N)'-N/2-1)*(1/fs);

    %remove means
    input = input - mean(input);
    output = output - mean(output);
    
    %trim ends if segments do not fit evenly in signals
    input = input(1:(N*numSegs));
    output = output(1:(N*numSegs));
    
    %split signals into matrix of with each section as column
    inputR = reshape(input, [N, numSegs]);
    outputR = reshape(output, [N numSegs]);
    
    %get FFTs of input & output
    inputFFT = fft(inputR,N);
    outputFFT = fft(outputR,N);

    %get cross spectrum
    crossAB = outputFFT.*conj(inputFFT);
    allCross = sum(crossAB,2)./(numSegs*N);
    
    %get x-corr with ifft
    cov = ifft(allCross);
    xCorr([N/2+1:N,1:N/2],1)=real(cov(1:N));
end