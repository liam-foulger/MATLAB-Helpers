%file: onsetDetection.m
%Author: Liam Foulger
%Date Created: 2023-02-22
%Last Updated: 2023-02-23
%
% onsetIDX = onsetDetection(m,fs,triggerIDX,onsetFreq,noiseRatio,window,c)
%
% Function to detect the movement onset from kinematic/kinetic data.
% Adapted from Dr. Gunter Siegmund's PhD Thesis (2001) - see page 138.
%
% Inputs:
% - m: signal to find movement onset (n x 1)
% - fs: signal sampling rate (Hz)
% - triggerIDX: index number indicating start of onset detection:
%      BEFORE this point: used to determine noise characteristics
%      AFTER this point: onset detection occurs
%      IF the onset occurs BEFORE this index, the algorithm will fail
% - onsetFreq: expected frequency of onset signal (i.e., how sharp is the
% change) (Hz)
% - noiseRatio: ratio of peak noise/peak signal amplitude. Must be << 1. If not provided,
% an estimate will be calculated from the inputted signal, but I'm not sure
% how well this will work so it is not recommended
% - halfWindow: size of 1/2 window for differentiation (milliseconds) - default
% will be calculated based on onset frequency & noise ratio. Note that for
% smaller windows you must have a high enough sampling rate or it will be
% rounded up. 
% - c: threshold multiplier - default is 1.5 (should be above 1)
% - NamePairArguments:
%   - 'Peak': which peak to use for determining peak signal amplitude (if not inputted):
%          - 'abs': absolute peak - DEFAULT
%          - 'max': positive peak
%          - 'min': negative peak

function onsetIDX = onsetDetection(m,fs,triggerIDX,onsetFreq,noiseRatio,halfWindow,c,NamePairArguments)
    %argument validation
    arguments
        m (:,1) double
        fs (1,1) double
        triggerIDX (1,1) double
        onsetFreq (1,1) double
        noiseRatio (1,1) double = 0
        halfWindow (1,1) double = 0
        c (1,1) double = 1.5
        NamePairArguments.Peak {mustBeMember(NamePairArguments.Peak,{'abs','max','min'})} = 'abs'
    end
    
    m = m - mean(m(1:triggerIDX));  %remove mean of signal from pre-trigger period
    dt = 1/fs; %sampling period
    
    %get max value of noise prior to trigger
    nMax = max(abs(m(1:triggerIDX)-mean(m(1:triggerIDX))));
    
    %estimate noise ratio if none provided
    if noiseRatio == 0
        switch NamePairArguments.Peak
            case 'abs'
                signalMax = max(abs(m(triggerIDX:end)));
            case 'max'
                signalMax = max(m(triggerIDX:end));
            case 'min'
                signalMax = abs(min(m(triggerIDX:end)));
        end
 
        noiseRatio = nMax/signalMax;
        % noiseRatio = nMax;
    end
    %calculate half window (in milliseconds) if none provided 
    if halfWindow == 0
        
        halfWindow = (1/(2*pi*onsetFreq))*(asin(2*c*noiseRatio - 1)+(pi/2))*1000;
        
    end
    
    
    iSample = round((halfWindow/1000*fs)); %# of samples on either side for given half window size
    mDot = NaN(size(m)); %pre-render array for differentiated signal

    %differentiate signal
    idx = 1+iSample;
    while idx+iSample <= size(m,1)
        mDot(idx) = ( m(idx+iSample) - m(idx-iSample) )/(2*iSample*dt);
        idx = idx + 1;
    end
    
    %determine threshold based on maximum possible value of noise
    threshold = (nMax*c)/(iSample*dt);
    
    %find point in differentiated signal that is above threshold, after the
    %trigger
    onsetIDX = find(abs(mDot(triggerIDX:end)) >= threshold ,1) + triggerIDX -1;
    
    %plotting function to check results & iterate through
%     figure(26);plot(m);hold on;yyaxis right;plot(mDot);xline(onsetIDX);xlim([onsetIDX-fs onsetIDX+fs])
%     pause
%     close(26)
end