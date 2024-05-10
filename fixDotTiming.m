% File: fixDotTiming.m
% Author: Liam Foulger
% Date Created: 2023-09-27
% Last Updated: 2023-09-29
%
% data = fixDotTiming(data,fs)
%
% Given a struct with fields for each Xsens/Movella Dot Sensor, trim their
% timings so that they start and end at the same timestamp - to remove any 
% timing offsets that could occur
% Also will fix any jumping in the data (i.e., the data reads some really
% large number beyond the ranges of the sensors
%
% Inputs:
% - Data: the n Xsens Dot IMUs that were used simultaneously to record data
% (the complete matrix - KEY POINT: the second column MUST be the time
% stamps)
% n x m: where n is the number of samples and m is the number of measures
% (MAKE SURE NONE OF THE FIELDS ARE NAMED "t")
% - fs: Sampling rate of sensors (Hz)
% Outputs:
% - Data: the data with the timing fixed


function data = fixDotTiming(dataRaw,fs)
    START_OFFSET = 0;   % Adding points to start IDX, just to make sure first few points aren't NaN
    % get the names of the different fields
    fields = fieldnames(dataRaw);

    if sum(strcmp(fields,"t")) ~= 0
        error('Input Data Struct CANNOT contain field named "t"')
    end

    % STEP 0: trim START_OFFSET points from front of each data, to ensure
    % that there are no NaNs or 0s at the start
    for iField = 1:length(fields)
        data.(fields{iField}) = dataRaw.(fields{iField})(1+START_OFFSET:end,:);

    end

    % STEP 1: Fix Start Time
    % find the start timestamp for each field + also correct if time stamps
    % have wrapped around (when it goes past 70 mins)
    startTime = NaN(1,length(fields));
    for iField = 1:length(fields)
        startTime(iField) = data.(fields{iField})(1,2);
        % check if there is negative dt, if so, stop it from wrapping at 72
        % mins
        resetIDX = find(diff(data.(fields{iField})(:,2)) < 0,1);
        if ~isempty(resetIDX)
            data.(fields{iField})(resetIDX+1:end,2) = data.(fields{iField})(resetIDX+1:end,2) + data.(fields{iField})(resetIDX,2);
        end
    end
    
    % find the latest start time from all the sensors
    lateStart = max(startTime);

    % for each field, subtract the late start and then re-index the matrix
    % to start at the index closest to 0
    for iField = 1:length(fields)
        data.(fields{iField})(:,2) = (data.(fields{iField})(:,2) - lateStart)./1000000;
        [~,idx] = min(abs(data.(fields{iField})(:,2)));
        data.(fields{iField}) = data.(fields{iField})(idx+START_OFFSET:end,:);
    end
    
    % for each field, remove any data points that are beyond the range of the
    % sensors OR NaN 
    endTimes = NaN(1,length(fields));
    for iField = 1:length(fields)
        data.(fields{iField}) = fixJumps(data.(fields{iField}),(fields{iField}));
        endTimes(iField) = data.(fields{iField})(end,2);
    end

    % for each field, interpolate data (this will also trim the data to the
    % same end points)
    endTime = min(endTimes);
    data.t = (0:(1/fs):endTime)';
    for iField = 1:length(fields)
        data.(fields{iField}) = interp1(data.(fields{iField})(:,2), data.(fields{iField}), data.t);
    end

end

function data = fixJumps(inData,sensor)
    % function to remove data points that are beyond the range of the
    % sensors OR NaN
    [locGyr,~] = find(abs(inData(:,9:11)) > 2000);
    [locAcc,~] = find(abs(inData(:,6:8)) > 32*9.81);
    [rNaN,cNaN] = find(isnan(inData(:,6:11)));
    allLocs = sort(unique([locGyr; locAcc]));
    data = inData;

    % check that there aren't skipped samples
    dtDiffs = diff(data(:,1));
    checkPoints = sort(unique([allLocs;allLocs-1]));
    checkPoints = checkPoints(all([(checkPoints >= 1) (checkPoints<=length(dtDiffs))],2));
    checkDiff = (max(dtDiffs(checkPoints)) > 1);

    if ~isempty(allLocs) && checkDiff
        answer = questdlg({'Possible Error! Large data values detected. This may be due to a data exporter issue, so please try re-exporting data. Rows of detected problems:',...
            sensor, num2str(allLocs)},...
            'Possible Error',...
            'No, I will re-export data',...
            'Yes (WARNING)',...
            'No, I will re-export data');
        switch answer
            case 'No, I will re-export data'
                error('Calibration stopped')
            case 'Yes (WARNING)'
                disp('Continuing data calibration')
        end
    end

    if ~isempty(allLocs)
        disp(['Larger numbers detected in ' sensor ' sensor, running interpolation']);
        if allLocs(1) == 1
            data(1,:) = [];
            allLocs(1) = [];
            allLocs = allLocs -1;
        end
        if allLocs(end) == size(data,1)
            data(end,:) = [];
            allLocs(end) = [];

        end
        
        for ii = 1:length(allLocs)
            if allLocs(ii) == size(data,1)
                data(:,end) = [];
            end
            data(allLocs(ii),2:end) = mean([data(allLocs(ii)-1,2:end); data(allLocs(ii)+1,2:end)]);
        end
    end

    if isempty(rNaN)
        return
    end

    disp(['NaNs detected in ' sensor ' sensor, running interpolation']);

    if rNaN(1) == 1
        data(:,1) = [];
        rNaN(1) = [];
        rNaN = rNaN - 1;
    end
    for ii = 1:length(rNaN)
        if rNaN(ii) == size(data,1)
            data(:,end) = [];
        end
        data(rNaN(ii),cNaN+5) = mean([data(rNaN(ii)-1,cNaN+5); data(rNaN(ii)+1,cNaN+5)]);
    end
end