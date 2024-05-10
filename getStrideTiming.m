% File: setStrideTiming.m
% Author: Liam Foulger
% Date Created: 2023-07-07
% Last Updated: 2023-07-07
%
% [strideTiming, normIDXs] = getStrideTiming(strideIDXs, newLength,eventTimings)
%
% Function to determine stride timing based on stride event indexes from
% stride detection algorithm
%
% Inputs:
% - stride IDXs: (3/5 x n) matrix of gait events: 
%    - IF 3 x n: events are RHS,LHS,next RHS -1
%    - IF 5 x n: events are RHS, LTO, LHS, RTO, next RHS - 1
% - newLength: length of stride array to be resampled to (optional) - if
% not inputted, the length will be set to the average duration of all the
% strides (closest even integer)
% - eventTimings: % values where the following events should occur
%    - if stride IDXs is 3 x n, eventTimings is scalar for % timing of LHS
%    (e.g., 50) 
%    - if stride IDXs is 5 xn, eventTimings is 3 x 1, with the % timings
%    for LTO, LHS, and RTO (e.g., [10 50 60])
% Outputs:
% - eventTimings: % values where the following events should occur
%    - if stride IDXs is 3 x n, eventTimings is scalar for % timing of LHS
%    (e.g., 50) 
% - normIDXs = indexes of gait events for normalized/resampled data

function [strideTiming, normIDXs,newLength] = getStrideTiming(strideIDXs, newLength,eventTimings)
    arguments
        strideIDXs (:,:) double
        newLength (1,1) double = 0
        eventTimings (:,:) double = [];
    end
    avgLength = mean(strideIDXs(end,:)-strideIDXs(1,:)+1);
    if rem(floor(avgLength),2) == 0
        avgLength = floor(avgLength);
    else
        avgLength = ceil(avgLength);
    end

    if newLength == 0
        newLength = avgLength;
    end
    
    if size(strideIDXs,1) == 3
        if ~(isempty(eventTimings))
            if length(eventTimings) ~= 1
                error('Too Many Values in Event Timing Input: Should only be 1')
            else
                strideTiming.newStep1 = newLength*(1-(eventTimings(1)/100));
                strideTiming.newStep2 = newLength*(eventTimings(1)/100);
            end
        else
            strideTiming.newStep1 = round((mean(strideIDXs(2,:) - strideIDXs(1,:)))/avgLength*newLength);
            strideTiming.newStep2 = newLength - strideTiming.newStep1;
            
        end
        normIDXs = [0 strideTiming.newStep1 newLength-1];
    elseif size(strideIDXs,1) == 5

        if ~(isempty(eventTimings))
            if length(eventTimings) ~= 3
                error('Too Many Values in Event Timing Input: Should be exactly 3')
            else
                strideTiming.newDouble1 = round((eventTimings(1)/100)*newLength);
                strideTiming.newSwing1 = round((eventTimings(2) - eventTimings(1))/100*newLength);
                strideTiming.newDouble2 = round((eventTimings(3) - eventTimings(2))/100*newLength);
                % strideTiming.newSwing2 = round((100 - options.RTOpercent)/100*newLength);
                strideTiming.newSwing2 = newLength - (strideTiming.newDouble1 + strideTiming.newSwing1 + strideTiming.newDouble2);
            end
        else
            strideTiming.newDouble1 = round((mean(strideIDXs(2,:) - strideIDXs(1,:)+1))/avgLength*newLength);
            strideTiming.newSwing1 = round(mean(strideIDXs(3,:) - strideIDXs(2,:)-1)/avgLength*newLength);
            strideTiming.newDouble2 = round(mean(strideIDXs(4,:) - strideIDXs(3,:)+1)/avgLength*newLength);
            % newSwing2 = round(mean(strideIDXs(5,:) - strideIDXs(4,:))/avgLength*newLength);
            strideTiming.newSwing2 = newLength - (strideTiming.newDouble1 + strideTiming.newSwing1 + strideTiming.newDouble2);
        end

        normIDXs = [0 strideTiming.newDouble1-1 (strideTiming.newSwing1+strideTiming.newDouble1) (strideTiming.newSwing1+strideTiming.newDouble1+strideTiming.newDouble2)-1 newLength-1];

    end

end