%File: sortStrides.m
%Author: Liam Foulger
%Date Created: 2022-06-27
%Last Updated: 2022-07-19
%
%Function to return the dataset split into normalized strides and
%non-normalized padded strides
%
%Inputs:
% - data, as n x m where n is samples
% - stride indexes
% - sample rate (fs)
% - new stride length for (if blank, will resize to average stride length)
%Outputs:
% - strides: m x n x d matrix where n is the number of strides detected; m
% is the resized length of the stride; d is the number of data points used
% (ie. number of sensor measures)
%sample 0: right step
%sample m/2: left step
% - strides padded
% - the average step cadence


function [strides, stridesPadded, cadence] = sortStrides(varargin)
    if length(varargin) < 3
        return
    end

    data = varargin{1} ;
    strideIDXs = varargin{2};
    fs = varargin{3};
    
    avgStride = mean(strideIDXs(3,:) - strideIDXs(1,:));
    if rem(floor(avgStride),2) == 0
        avgStride = floor(avgStride);
    else
        avgStride = ceil(avgStride);
    end
    
    if length(varargin) < 4
        newLength = avgStride;
    else
        newLength = varargin{4};
    end
    halfLength = newLength/2;
    
    for jj = 1:size(strideIDXs,2)
        step1_length = length(strideIDXs(1,jj):strideIDXs(2,jj)-1);
        step2_length = length(strideIDXs(2,jj):strideIDXs(3,jj));
        
        step1norm = interp1(1:step1_length,data(strideIDXs(1,jj):(strideIDXs(2,jj)-1),: ), linspace(1,step1_length,halfLength) );
        step2norm = interp1(1:step2_length,data(strideIDXs(2,jj):strideIDXs(3,jj),: ), linspace(1,step2_length,halfLength));
        strideNorm(:,jj,:) = [step1norm;step2norm];
        
        paddedRange = (strideIDXs(1,jj)-step1_length):(strideIDXs(3,jj)+step2_length);
        if min(paddedRange) >= 1 && max(paddedRange) < size(data,1)
            stridesPadded{jj} = data(paddedRange,:);
        end

    end
        
    
    
    stridesPadded = stridesPadded(~cellfun('isempty',stridesPadded));
    strides = strideNorm;
    cadence = 60/((mean(strideIDXs(3,:)-strideIDXs(1,:))/fs)/2);
end