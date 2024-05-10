%File: getZeroCrossings.m
%Author: Liam Foulger
%Date Created: 2022-07-13
%Last Updated: 2022-12-17
%
%zeros = getZeroCrossings(signal,type)
%
%Function to return all indexes where there is a zero crossing (whatever
%side is closest to 0).
%Input:
% - signal
% - type of crossing: 'up' (- to +), 'down' (+ to -), 'all' (DEFAULT)
%Output:
% - zero crossing indexes

function zeros = getZeroCrossings(signal,type)
    arguments 
        signal double
        type {mustBeMember(type,{'up','down','all'})} = 'all'
    end
       
    zeros = [];
    positive = signal(1) > 0;
    
    switch type
        case 'all'
            f = @(x,pos) pos ~= (x > 0);
        case 'up'
            f = @(x,pos) pos == 0 && x > 0;
        case 'down'
            f = @(x,pos) pos == 1 && x < 0;
    end
    
    for ii = 2:length(signal)
        if f(signal(ii),positive)
            [~, loc] = min([abs(signal(ii-1)) abs(signal(ii))]);
            zeros = [zeros; ii-2+loc];
            %remove zero crossings if they are only for 1 sample
            if length(signal) > ii && (signal(ii) > 0) ~= (signal(ii+1) > 0)
                zeros(end) = [];
            end
        end
        
        positive = signal(ii) > 0;
    end

end

