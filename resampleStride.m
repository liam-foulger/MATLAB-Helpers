%File: trimStride.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-20
%
%trimStride = resampleStride(data, midIDX, newLength, shiftPercent)
%
%Function to to trim stride data to remove 25% from strart and end of the
%data. Also allows you to shift the data circularly to account for an
%offset
%
%Inputs:
% - data (n x m; where n is samples and m is different measures)
% - midIDX: middle index of stride
% - newLength: length of stride to resample to
% - shiftPercent (optional): how much to shift the data
%Output:
% - trimmed stride data (newLength x m)

function trimStride = resampleStride(data, midIDX, newLength, shiftPercent)
    arguments
        data double
        midIDX double
        newLength double
        shiftPercent (1,1) {mustBeNumeric} = 0
    end
        

    step1 = interp1(1:midIDX*2, data(1:(midIDX*2),:),linspace(1,midIDX*2,newLength));
    step2 = interp1(1:size(data((midIDX*2)+1:end,:),1), data((midIDX*2)+1:end,:),linspace(1,size(data(((midIDX*2)+1):end,:),1),newLength));
    normStride = [step1; step2];
    trimStride = normStride(((newLength/2)+1):(end-newLength/2),:);
    
    trimStride = circshift(trimStride, -round(shiftPercent.*newLength));

end