%File: getCoherence.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-12
%
%[f, coherence, gain] = getCoherence(input, output, windowLength, fs)
%
%Function to calculate the coherence (& gain) between two signals
% coherence = |Pxy|^2 / Pxx*Pyy
% gain = |Pxy / Pxx|
%(Note I've validated that this works correctly with Neurospec 2.0)
%
%Inputs:
% - input signal (n x 1)
% - output signal (n x 1)
% - length of window for fft analysis (s)
% - signal sample rate (Hz)
%Outputs: 
% - f: array of frequencies
% - coherence between input and output
% - gain between input and output

function [f, coherence, gain] = getCoherence(input, output, windowLength, fs,NamePairArguments)
    
    arguments 
        input double
        output double
        windowLength double
        fs double
        NamePairArguments.padding (1,1) {mustBeNumeric} = 0
        NamePairArguments.window (1,1) string = "square"
    end
    
    
    
    %remove means
    input = input - mean(input);
    output = output - mean(output);
    
    if size(input,2) > 1    %check if signals are already reshaped
        inputR = input;
        outputR = output;
        N = size(input,1);
    else
        N = windowLength*fs;

        %determine number of sections based on window length
        numSegs = floor(length(input)/N);
        %trim ends if segments do not fit evenly in signals
        input = input(1:(N*numSegs));
        output = output(1:(N*numSegs));

        %split signals into matrix of with each section as column
        inputR = reshape(input, [N, numSegs]);
        outputR = reshape(output, [N numSegs]);
    end
    if NamePairArguments.padding > 0
        pad = zeros(NamePairArguments.padding, size(inputR,2));
        inputR = [pad; inputR; pad];
        outputR = [pad; outputR; pad];
        N = size(outputR,1);
    end
    
    switch NamePairArguments.window
        case 'square'
            wind = ones(N,1);
        case 'hamming'
            wind = hamming(N);
        case 'hanning'
            wind = hann(N);
    end
    inputR = inputR.*wind;
    outputR = outputR.*wind;
    %get FFT 
    inputFFT = fft(inputR);
    outputFFT = fft(outputR);
    
    %calculate auto and cross spectra
    autoInput = inputFFT.*conj(inputFFT);
    autoOutput = outputFFT.*conj(outputFFT);
    crossAB = inputFFT.*conj(outputFFT);
    
    %sum across windows to get total 
    allCross = sum(crossAB,2);
    allInput = sum(autoInput,2);
    allOutput = sum(autoOutput,2);
    
    f = linspace(0,fs/2,N/2 + 1);

    %calculate coherence
    coherence = ((abs(allCross).^2)./(allInput.*allOutput))';
    coherence = coherence(1:N/2+1);
    
    %calculate gain
    gain = abs(allCross./allInput);
    gain = gain(1:N/2+1);
    
end