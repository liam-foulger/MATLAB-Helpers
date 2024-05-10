%File: resampleStride.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2023-08-14
%
%[trimStride, normIDXs] = resampleStride(data, strideIDXs, newLength, shiftSamples, eventTimings)
%
%Function to to trim stride data to remove 25% from start and end of the
%data and resample to given stride cycle timings
% Also allows you to shift the data circularly to account for an offset
%
%Inputs:
% - data: n (for each stride) x 1 cell, with each stride spilt into a
% different cell, with each row as a sample (l x m)
% - strideIDXs: the gait event indexes (either 3 or 5 rows, depending on if
% toe off is included)
% - newLength (optional): length of stride to resample to
% - shiftSamples (optional): how much to shift the data
% - eventTimings (optional): percentage gait timing events to set
% resampling to
%Output:
% - trimmed stride data (newLength x m x n)
% - gait event indexes that strides were resampled to

function [trimStride, normIDXs] = resampleStride(data, strideIDXs, newLength, shiftSamples, eventTimings)
    arguments
        data cell
        strideIDXs double
        newLength (1,1) {mustBeNumeric} = 0
        shiftSamples (1,1) {mustBeNumeric} = 0
        eventTimings =[];
    end
    avgLength = round(mean(strideIDXs(end,:)-strideIDXs(1,:)+1));
    if newLength == 0
        newLength = avgLength;
        if rem(newLength,2) == 1
            newLength = newLength +1;
        end
    end
    trimStride = NaN(newLength, size(data{1},2), length(data));
    if size(strideIDXs,1) == 3
        
        [strideTiming, normIDXs] = getStrideTiming(strideIDXs, newLength,eventTimings);


        for ii = 1:size(data,1)
            step1_length = strideIDXs(2,ii) - strideIDXs(1,ii);
            step2_length = strideIDXs(3,ii) - strideIDXs(2,ii) + 1;
            padLength = round(length(strideIDXs(1,ii):strideIDXs(3,ii))/2);
            cutStride = data{ii}( (padLength+1):(end-padLength),:);
            cutStride = circshift(cutStride, -shiftSamples);
            
            step1 = interp1( (1:step1_length)', cutStride(1:step1_length,:),linspace(1,step1_length,strideTiming.newStep1));
            step2 = interp1( (1:step2_length)', cutStride(step1_length+1:end,:),linspace(1,step2_length,strideTiming.newStep2));
            
            trimStride(:,:,ii) = [step1;step2];
        end
        
    elseif size(strideIDXs,1) == 5
%         doubleSupport = round(mean([mean(strideIDXs(4,:)-strideIDXs(3,:)+1)...
%                     mean(strideIDXs(2,:)-strideIDXs(1,:)+1)])/avgLength*newLength);
        % doubleSupport = round(newLength*0.1);
        % swingPhase = (newLength - doubleSupport*2)/2;

        [strideTiming, normIDXs] = getStrideTiming(strideIDXs, newLength,eventTimings);

        for ii = 1:size(data,1)
            step1_length = strideIDXs(3,ii) - strideIDXs(1,ii);
            step2_length = strideIDXs(5,ii) - strideIDXs(3,ii) + 1;
            
            padLength = round(length(strideIDXs(1,ii):strideIDXs(5,ii))/2);
            cutStride = data{ii}( (padLength+1):(end-padLength),:);
            cutStride = circshift(cutStride, -shiftSamples);
            
            double1_length = length(strideIDXs(1,ii):strideIDXs(2,ii));
            swing1_length = length(strideIDXs(2,ii)+1:strideIDXs(3,ii)-1);
            double2_length = length(strideIDXs(3,ii):strideIDXs(4,ii));
            swing2_length = length(strideIDXs(4,ii)+1:strideIDXs(5,ii));
            %resample from current to desired lengths for each
            %phase
            double1norm = interp1( (1:double1_length)',cutStride( 1:double1_length,: ), linspace(1,double1_length,strideTiming.newDouble1) );
            swing1norm = interp1( (1:swing1_length)',cutStride( double1_length+1:step1_length,: ), linspace(1,swing1_length,strideTiming.newSwing1) );
            double2norm = interp1( (1:double2_length)',cutStride( (step1_length+1):(step1_length+double2_length),: ), linspace(1,double2_length,strideTiming.newDouble2) );
            swing2norm = interp1( (1:swing2_length)',cutStride( (step1_length+double2_length+1):end,: ), linspace(1,swing2_length,strideTiming.newSwing2) );

            trimStride(:,:,ii) =  [double1norm;swing1norm;double2norm;swing2norm];
            
            
        end
        
            
    else
        error('Unrecognized Stride Indexes')
    end
    

end