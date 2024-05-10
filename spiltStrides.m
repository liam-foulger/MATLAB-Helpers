%File: splitStrides.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2023-08-14
%
% [strides, normIDXs, secIDXs] = spiltStrides(data, strideIDXs, type,NamePairArguments)
%
% Function to split data (in either struct or matrix format) into strides
% given stride indexes
%
% Inputs:
%   - data (l x m matrix or struct with any number of fields): the data to
%   be split into strides
%   - strideIDXs: the gait event indexes (either 3 or 5 rows, depending on if
%   toe off is included)
%   - type: what kind of resampling/padding you want to occur:
%       - 'none': no resampling/padding, data is saved in individual cells
%       for each stride
%       - 'normalize': data is resampled to either the average length and
%       gait event locations, unless otherwise specified in the inputs
%       "NewLength" and "eventTimings". 
%       - 'pad': data is padded with 50% of its length at both the start
%       and end.
%   - NamePairArguments:
%       - 'segmentDuration': if you want to split up the strides into timed
%       subsegments, this indicates the time in seconds for each segment.
%       The data will then be saved in n cells for each segment, with the
%       individual stride data within
%       - 'fs': sampling rate - needed for above segment splitting
%       - 'NewLength': number of samples to resample to for 'normalize'
%       type
%       - 'eventTimings': gait event timings to resample to



function [strides, normIDXs, secIDXs] = spiltStrides(data, strideIDXs, type,NamePairArguments)
    arguments
        data 
        strideIDXs double
        type {mustBeMember(type,['none','normalize','pad'])} = 'none'
        NamePairArguments.segmentDuration (1,1) {mustBeNumeric} = 0
        NamePairArguments.fs (1,1) {mustBeNumeric} = 0
        NamePairArguments.NewLength(1,1) {mustBeNumeric} = 0
        NamePairArguments.eventTimings (:,:) double = [];
    end
    strideCells = cell(size(strideIDXs,2),1);
    avgLength = round(mean(strideIDXs(end,:)-strideIDXs(1,:)+1));
    isStruct = isstruct(data);
    switch type
        case 'normalize'
            if NamePairArguments.NewLength == 0
                NamePairArguments.NewLength = avgLength;
                if rem(NamePairArguments.NewLength,2) == 1
                    NamePairArguments.NewLength = NamePairArguments.NewLength +1;
                end
            else
                if rem(NamePairArguments.NewLength,2) == 1
                    NamePairArguments.NewLength = NamePairArguments.NewLength +1;
                end
            end
            if size(strideIDXs,1) == 3
                %determine resample length for each step in stride
                [strideTiming, normIDXs] = getStrideTiming(strideIDXs, NamePairArguments.NewLength,NamePairArguments.eventTimings);


                for ii = 1:size(strideIDXs,2)
                    %find current lengths for each step
                    step1length = length(strideIDXs(1,ii):strideIDXs(2,ii)-1);
                    step2length = length(strideIDXs(2,ii):strideIDXs(3,ii));
                    %resample from current to desired (equal) lengths for
                    %each step
                    if isStruct
                        step1norm = structfun(@(x) interp1( (1:step1length)',x(strideIDXs(1,ii):(strideIDXs(2,ii)-1),: ), linspace(1,step1length,strideTiming.newStep1)' ) , data, 'UniformOutput', false);
                        step2norm = structfun(@(x) interp1( (1:step2length)',x( strideIDXs(2,ii):strideIDXs(3,ii),: ), linspace(1,step2length,strideTiming.newStep2)') , data, 'UniformOutput', false);
                       
                        combinedData = [step1norm;step2norm];
                        
                        f = fieldnames(combinedData);
                        for jj = 1:length(f)
                            strideCells{ii}.(f{jj}) = cat(1,combinedData.(f{jj}));
                        end
                    else
                        step1norm = interp1( (1:step1length)',data(strideIDXs(1,ii):(strideIDXs(2,ii)-1),: ), linspace(1,step1length,strideTiming.newStep1) );
                        step2norm = interp1( (1:step2length)',data( strideIDXs(2,ii):strideIDXs(3,ii),: ), linspace(1,step2length,strideTiming.newStep2));
                        %combine steps
                        strideCells{ii}  = [step1norm;step2norm];
                    end
                end

            elseif size(strideIDXs,1) == 5
                
                [strideTiming, normIDXs] = getStrideTiming(strideIDXs, NamePairArguments.NewLength,NamePairArguments.eventTimings);

                for ii = 1:size(strideIDXs,2)
                    %find current lengths for each stride phase
                    double1_length = length(strideIDXs(1,ii):strideIDXs(2,ii));
                    swing1_length = length(strideIDXs(2,ii)+1:strideIDXs(3,ii)-1);
                    double2_length = length(strideIDXs(3,ii):strideIDXs(4,ii));
                    swing2_length = length(strideIDXs(4,ii)+1:strideIDXs(5,ii));
                    %resample from current to desired lengths for each
                    %phase
                    if isStruct
                        
                        
                        double1norm = structfun(@(x) interp1( (1:double1_length)',x( strideIDXs(1,ii):strideIDXs(2,ii),: ), linspace(1,double1_length,strideTiming.newDouble1)') , data, 'UniformOutput', false);
                        swing1norm = structfun(@(x) interp1( (1:swing1_length)',x( strideIDXs(2,ii)+1:strideIDXs(3,ii)-1,: ), linspace(1,swing1_length,strideTiming.newSwing1)' ) , data, 'UniformOutput', false);
                        double2norm = structfun(@(x) interp1( (1:double2_length)',x( strideIDXs(3,ii):strideIDXs(4,ii),: ), linspace(1,double2_length,strideTiming.newDouble2)' ) , data, 'UniformOutput', false);
                        swing2norm = structfun(@(x) interp1( (1:swing2_length)',x( strideIDXs(4,ii)+1:strideIDXs(5,ii),: ), linspace(1,swing2_length,strideTiming.newSwing2)' ) , data, 'UniformOutput', false);
                        
                        combinedData = [double1norm;swing1norm;double2norm;swing2norm];
                        
                        f = fieldnames(combinedData);
                        for jj = 1:length(f)
                            strideCells{ii}.(f{jj}) = cat(1,combinedData.(f{jj}));
                        end
                    else
                        
                        double1norm = interp1( (1:double1_length)',data( strideIDXs(1,ii):strideIDXs(2,ii),: ), linspace(1,double1_length,strideTiming.newDouble1) );
                        swing1norm = interp1( (1:swing1_length)',data( strideIDXs(2,ii)+1:strideIDXs(3,ii)-1,: ), linspace(1,swing1_length,strideTiming.newSwing1) );
                        double2norm = interp1( (1:double2_length)',data( strideIDXs(3,ii):strideIDXs(4,ii),: ), linspace(1,double2_length,strideTiming.newDouble2) );
                        swing2norm = interp1( (1:swing2_length)',data( strideIDXs(4,ii)+1:strideIDXs(5,ii),: ), linspace(1,swing2_length,strideTiming.newSwing2) );

                        strideCells{ii} = [double1norm;swing1norm;double2norm;swing2norm];
                    end
                end
            else
                error('Unrecognized Stride Indexes')
            end
        case 'pad'
            if size(strideIDXs,1) == 3                
                for ii = 1:size(strideIDXs,2)
                    % step1length = length(strideIDXs(1,ii):strideIDXs(2,ii)-1);
                    % step2length = length(strideIDXs(2,ii):strideIDXs(3,ii));
                    padLength = round(length(strideIDXs(1,ii):strideIDXs(3,ii))/2);
%                     paddingPre = round(length(strideIDXs(1,ii):strideIDXs(3,ii))/2);
%                     paddingPost = round(length(strideIDXs(1,ii):strideIDXs(3,ii))/2);
                    if isStruct
                        strideCells{ii} = structfun(@(x) x((strideIDXs(1,ii)-padLength):(strideIDXs(3,ii)+padLength),:), data, 'UniformOutput', false);
                    else
                        strideCells{ii} = data( (strideIDXs(1,ii)-padLength):(strideIDXs(3,ii)+padLength),: );
                    end
                end
            elseif size(strideIDXs,1) == 5                
                for ii = 1:size(strideIDXs,2)
                    % step1length = length(strideIDXs(1,ii):strideIDXs(3,ii)-1);
                    % step2length = length(strideIDXs(3,ii):strideIDXs(5,ii));
                    padLength = round(length(strideIDXs(1,ii):strideIDXs(5,ii))/2);
%                     paddingPre = round(length(strideIDXs(1,ii):strideIDXs(5,ii))/2);
%                     paddingPost = round(length(strideIDXs(1,ii):strideIDXs(5,ii))/2);
                    if isStruct
                        strideCells{ii} = structfun(@(x) x((strideIDXs(1,ii)-padLength):(strideIDXs(5,ii)+padLength),:), data, 'UniformOutput', false);
                    else
                        
                        strideCells{ii} = data( (strideIDXs(1,ii)-padLength):(strideIDXs(5,ii)+padLength),: );
                    end
                end
            else
                error('Unrecognized Stride Indexes')
            end
            normIDXs = [];
        case 'none'
            for ii = 1:size(strideIDXs,2)
                if isStruct
                    strideCells{ii} = structfun(@(x) x(strideIDXs(1,ii) : strideIDXs(end,ii),:), data, 'UniformOutput', false);
                else
                    strideCells{ii} = data( strideIDXs(1,ii) : strideIDXs(end,ii),: );
                end
            end
            normIDXs = [];
    end
    %split into sections, if a section duration is inputted
    if NamePairArguments.segmentDuration > 0
        if NamePairArguments.fs == 0
            error('Sample rate must be inputted')
        end
        numSections = ceil( size(data,1)/ (NamePairArguments.segmentDuration*NamePairArguments.fs));
        strides = cell(numSections,1);
        secIDXs = cell(numSections,1);
        for ii = 1:numSections
            lowLimit = (ii-1)*(NamePairArguments.segmentDuration*NamePairArguments.fs);
            upLimit = ii*(NamePairArguments.segmentDuration*NamePairArguments.fs);
            [~, sIDX] = find(strideIDXs(1,:) >= lowLimit);
            [~, eIDX] = find(strideIDXs(end,:) < upLimit);

            strides{ii} = strideCells(sIDX(1):eIDX(end));
            secIDXs{ii} = strideIDXs(:,sIDX(1):eIDX(end));
        end
    
    else
        if isStruct
            strides = cat(1,strideCells{:});
        else
            strides = strideCells;
        end
        secIDXs = [];
    end

end