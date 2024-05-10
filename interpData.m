%File: interpData.m
%Author: Liam Foulger
%Date created: 2021-03-25
%Last updated: 2023-05-26
%
% return_signal = interpData(signal,fs,timeGap,filterCut,filterOrder)
%
% Function to interpolate one or more columns of time series data, if
% interpolation is needed
% Also an option to filter the data as well
%Input:
%- signal to be interpolated - MUST BE IN COLUMN VECTOR(S) 
%- fs: sample rate (Hz)
%- timeGap: maximum allowable gap to interpolate (ms; default = 150)
%- filter cutoff (if want to filter)
%- filter order (if want to filter)
%Output:
% - interpolated (if needed) and filtered (if required) signal


function return_signal = interpData(signal,fs,timeGap,NamePairArguments)
    arguments
        signal double
        fs double
        timeGap (1,1) {mustBeNumeric} = 150
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 4
    end

    

    %set-up filter
    
    
    pts_gap_allowed = (timeGap/1000)/(1/fs);
    gaps = isnan(signal);
    gap_pts = find(gaps == 1);
    if sum(gaps) == 0
        if ~(NamePairArguments.FilterCutoff == 0) && ~(NamePairArguments.FilterOrder == 0)
            [b,a] = butter(NamePairArguments.FilterOrder , NamePairArguments.FilterCutoff./(fs/2));
            return_signal = filtfilt(b,a, signal);
        else
            return_signal = signal;
        end
    else 
        max_gap = 0;
        acc = 0;
        for ii = 2:length(gap_pts)
            if gap_pts(ii) == gap_pts(ii - 1) + 1
                acc = acc + 1;
                if acc > max_gap
                    max_gap = acc;
                end
            else
                acc = 0;
            end
        end
        if max_gap < pts_gap_allowed
            if ~(NamePairArguments.FilterCutoff == 0) && ~(NamePairArguments.FilterOrder == 0) 
                [b,a] = butter(NamePairArguments.FilterOrder , NamePairArguments.FilterCutoff./(fs/2));
                return_signal = filtfilt(b,a,interp_LF(signal));
            else
                return_signal = interp_LF(signal);
            end
        else 
            return_signal = signal;
        end
    end


end

function filled = interp_LF(signal)
    %linear interpolation function for multiple gaps in signal
    a = signal;
    x = 1:length(a) ;
    if size(a,2) > 1
        for ii = 1:size(a,2)
            a1 = a(:,ii);
            a1(isnan(a1)) = interp1(x(~isnan(a1)),a1(~isnan(a1)),x(isnan(a1))); 
            filled(:,ii) = a1;
        end
    else
        
        a(isnan(a)) = interp1(x(~isnan(a)),a(~isnan(a)),x(isnan(a))); 
        filled = a;
    end

end