%File: resampleStride.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-20
%
%trimStride = resampleStride(data, stepIDXs, newLength, shiftPercent)
%
%Function to to trim stride data to remove 25% from start and end of the
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

function [trimStride, normIDXs] = resampleStride(data, strideIDXs, newLength, shiftPercent)
    arguments
        data cell
        strideIDXs double
        newLength (1,1) {mustBeNumeric} = 0
        shiftPercent (1,1) {mustBeNumeric} = 0
    end
    avgLength = round(mean(strideIDXs(end,:)-strideIDXs(1,:)+1));
    if newLength == 0
        newLength = avgLength;
        if rem(newLength,2) == 1
            newLength = newLength +1;
        end
    end
    trimStride = NaN(newLength, size(data{1},2), size(data,1));
    if size(strideIDXs,1) == 3
        for ii = 1:size(data,1)
            step1_length = strideIDXs(2,ii) - strideIDXs(1,ii);
            step2_length = strideIDXs(3,ii) - strideIDXs(2,ii) + 1;
            cutStride = data{ii}( (step1_length+1):(end-step2_length),:);
            
            step1 = interp1( (1:step1_length)', cutStride(1:step1_length,:),linspace(1,step1_length,newLength/2));
            step2 = interp1( (1:step2_length)', cutStride(step1_length+1:end,:),linspace(1,step2_length,newLength/2));
            
            trimStride(:,:,ii) = [step1;step2];
        end
        normIDXs = [1 (newLength/2)+1 newLength];
    elseif size(strideIDXs,1) == 5
        doubleSupport = round(mean([mean(strideIDXs(4,:)-strideIDXs(3,:)+1)...
                    mean(strideIDXs(2,:)-strideIDXs(1,:)+1)])/avgLength*newLength);
        swingPhase = (newLength - doubleSupport*2)/2;
        for ii = 1:size(data,1)
            step1_length = strideIDXs(3,ii) - strideIDXs(1,ii);
            step2_length = strideIDXs(5,ii) - strideIDXs(3,ii) + 1;
            
            cutStride = data{ii}( (step1_length+1):(end-step2_length),:);
            
            double1_length = length(strideIDXs(1,ii):strideIDXs(2,ii));
            swing1_length = length(strideIDXs(2,ii)+1:strideIDXs(3,ii)-1);
            double2_length = length(strideIDXs(3,ii):strideIDXs(4,ii));
            swing2_length = length(strideIDXs(4,ii)+1:strideIDXs(5,ii));
            %resample from current to desired lengths for each
            %phase
            double1norm = interp1( (1:double1_length)',cutStride( 1:double1_length,: ), linspace(1,double1_length,doubleSupport) );
            swing1norm = interp1( (1:swing1_length)',cutStride( double1_length+1:step1_length,: ), linspace(1,swing1_length,swingPhase) );
            double2norm = interp1( (1:double2_length)',cutStride( (step1_length+1):(step1_length+double2_length),: ), linspace(1,double2_length,doubleSupport) );
            swing2norm = interp1( (1:swing2_length)',cutStride( (step1_length+double2_length+1):end,: ), linspace(1,swing2_length,swingPhase) );

            trimStride(:,:,ii) =  [double1norm;swing1norm;double2norm;swing2norm];
            
            
        end
        normIDXs = [1 doubleSupport (swingPhase+doubleSupport) (swingPhase+(doubleSupport*2)) newLength];
            
    else
        error('Unrecognized Stride Indexes')
    end
    
    trimStride = circshift(trimStride, -round(shiftPercent.*newLength));

end