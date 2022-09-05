%File: strideDetection.m
%Author: Liam Foulger
%Date Created: 2022-05-28
%Last Updated: 2022-09-05
%
%strideIDXs = strideDetection(rightIMU, leftIMU, fs,options)
%
%Function to detect strides from foot/ankle mounted IMUs on each
%ankle/foot. Returns the step indices for each foot contact. Uses 
%footStepDetection.m to determine the foot contact indexes
%Inputs:
% - right IMU data (XYZ accel & XYZ gyro (deg/s); assumes X:forward, Y: right, Z:
% down) (n x 6)
% - left IMU data (n x 6)
% - sample rate (Hz)
% - NamePair arugments:
%    - 'Method': 'zero' (default) or 'peak'. Zero: uses the zero crossings 
%       to estimate the HS (& TO) events - this will be automatically set
%       if the event detect includes toe-off (TO). Peak: uses peak angular
%       velocity to detect HS events (not as good).
%    - 'Events': 'HS' (default) or 'HS&TO'. HS: returns indices for just
%    heel strike events as [rHS lHS rHS-1]. HS&TO: returns indices for heel
%    strike and toe off events as [rHS lTO lHS rTO rHS-1].
%    - 'Showplots': 1 (true) or 0 (false, default). If you want to show the plots
%    - 'MinPeakHeight'. Min height of peak angular velocity. Default is
%    50. For findpeaks function.
%    - 'MinPeakProminence'. Min peak prominence of angular velocity. Default is
%    100. For findpeaks function.
%Outputs: 
% - stride indices (3 x n). 
%     - for each column: r1: R foot contact. r2: L foot contact. r3: before
%     next foot contact (ie. end of stride cycle).
%
%Dependencies:
% - footStepDetection.m
% - removeDoubleSteps.m
% - getZeroCrossings.m

function strideIDXs = strideDetection(rightIMU, leftIMU, fs,options)
    arguments
        rightIMU double
        leftIMU double
        fs double
        options.Method (1,1) string = 'zero'
        options.Events {mustBeMember(options.Events,['HS','HS&TO'])}= 'HS'
        options.Showplots (1,1) {mustBeNumeric} = 0
        options.MinPeakHeight (1,1) {mustBeNumeric} = 50
        options.MinPeakProminence (1,1) {mustBeNumeric} = 100
    end
    if strcmp(options.Events,'HS&TO')
        options.Method  = 'zero';
    end
    
    %for each IMU, find the HS
    [rightHS,leftHS] = heelStrikeDetection(rightIMU, leftIMU, fs,'Method',options.Method,...
        'Showplots',options.Showplots,'MinPeakHeight',options.MinPeakHeight,...
        'MinPeakProminence',options.MinPeakProminence);
    
    %plotting
    if options.Showplots
        numSteps = min([length(rightHS) length(leftHS)]);
        figure
        plot(rightHS(1:numSteps).*1/fs,(leftHS(1:numSteps) - rightHS(1:numSteps))/fs);
        xlabel('Time (s)')
        ylabel('Step Duration (s)')
        box off
    end
    
    %find the TO between HS
    if strcmp(options.Events,'HS&TO')
        [rightTO,leftTO] = toeOffDetection(rightIMU,leftIMU,rightHS,leftHS);
        if options.Showplots
            t = (1:length(rightIMU))'./fs;
            figure
            plot(t,rightIMU(:,5),'r')
            hold on
            plot(t,leftIMU(:,5),'b')
            plot(rightHS./fs, rightIMU(rightHS,5),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
            plot(leftHS./fs, leftIMU(leftHS,5),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
            plot(rightTO./fs, rightIMU(rightTO,5),'Marker','*','MarkerEdgeColor','r','LineStyle','none')
            plot(leftTO./fs, leftIMU(leftTO,5),'Marker','*','MarkerEdgeColor','b','LineStyle','none')
            legend('R','L')
            title('Heel Strikes & Toe-Offs')
            ylabel('Angular Velocity (deg/s)')
            xlabel('Time (s)')
        end
    end
    
    %reorganize to give output that is nicely sorted
    numStrides = min([length(rightHS)-1 length(leftHS)]);
    if strcmp(options.Events,'HS&TO')
        strideIDXs = [rightHS(1:numStrides)'; leftTO(1:numStrides)'; leftHS(1:numStrides)';...
            rightTO(1:numStrides)'; (rightHS(2:numStrides+1)' - 1)];
    else
        strideIDXs = [rightHS(1:numStrides)';leftHS(1:numStrides)'; (rightHS(2:numStrides+1)' - 1)];
    end
end

%File: toeOffDetection.m
%Author: Liam Foulger
%Date Created: 2022-09-04
%Last Updated: 2022-09-04
%
% [rightTO,leftTO] = toeOffDetection(rightIMU,leftIMU,rightHS,leftHS)
%
% Function to detect the toe off events from right and left IMU sensors by
% using the angular velocity peaks (see Jasiewicz et al. (2006) for more
% info

function [rightTO,leftTO] = toeOffDetection(rightIMU,leftIMU,rightHS,leftHS)
    arguments
        rightIMU double
        leftIMU double
        rightHS double
        leftHS double
    end
    numStrides = min([length(rightHS)-1 length(leftHS)]);
    
    rightTO = NaN(numStrides,1);
    leftTO = NaN(numStrides,1);
    RpitchVel = detrend(rightIMU(:,5));
    LpitchVel = detrend(leftIMU(:,5));
    
    for ii = 1:numStrides
        %find min value between right HS and left HS to find left TO
        [~,loc] = min(LpitchVel( rightHS(ii):leftHS(ii) ) );
        leftTO(ii) = loc + rightHS(ii) - 1;
        
        %find min value between left HS and next right HS to find right TO
        [~,loc] = min(RpitchVel( leftHS(ii):rightHS(ii+1) ) );
        rightTO(ii) = loc + leftHS(ii) - 1;
    end
    
end

%File: footStepDetection.m
%Author: Liam Foulger
%Date Created: 2022-06-17
%Last Updated: 2022-09-04
%
%[rightHS,leftHS] = heelStrikeDetection(rightIMU, leftIMU, fs, options)
%
%Function to detect heel strikes from left and right foot/ankle IMUs. Returns the
%heel strike indices for each foot. 
%2 possible methods:
% 1) Y angular velocity zero crossings:
%   - Finds the + to - zero crossing following the peak + angular velocity
%   - Detected heel strikes are 50-100ms prior to the true timing, but better
%   reliability
%   - Based on method from Mariani et al. (2013) doi: 10.1109/TBME.2012.2227317
% 2) Y angular velocity peak
%   - finds the true peak angular velocity from filtered peak angular
%   velocity
%   - less delay than method 1 but more variable so I do not recommend.
%
%Inputs:
% - right IMU data (XYZ accel & XYZ gyro (deg/s); assumes X:forward, Y: right, Z:
% down)
% - left IMU data 
% - sample rate (Hz)
% - NamePairArugments:
%    - 'Method': 'zero' (default) or 'peak' 
%    - 'Showplots': 1 (true) or 0 (false, default). If you want to show the plots
%    - 'MinPeakHeight'. Min height of peak angular velocity. Default is
%    50. For findpeaks function.
%    - 'MinPeakProminence'. Min peak prominence of angular velocity. Default is
%    100. For findpeaks function.
%Outputs: 
% - right heel strike indices
% - left heel strike indices
%
%Dependencies
% - removeDoubleSteps.m
% - getZeroCrossings.m


function [rightHS,leftHS] = heelStrikeDetection(rightIMU, leftIMU, fs, NamePairArguments)
    
    arguments
        rightIMU double
        leftIMU double
        fs double
        NamePairArguments.Method (1,1) string = 'zero'
        NamePairArguments.Showplots (1,1) {mustBeNumeric} = 0
        NamePairArguments.MinPeakHeight (1,1) {mustBeNumeric} = 50
        NamePairArguments.MinPeakProminence (1,1) {mustBeNumeric} = 100
    end
    
    %detrend data
    RpitchVel = detrend(rightIMU(:,5));
    LpitchVel = detrend(leftIMU(:,5));
    
    %find max peaks of angular velocity (lightly filtered) using findpeaks function 
    movRange = fs/20;
    RpitchVelMov = movmean(RpitchVel, movRange);
    LpitchVelMov = movmean(LpitchVel, movRange);
    [~, RfiltMax] = findpeaks(RpitchVelMov,'MinPeakHeight',NamePairArguments.MinPeakHeight, 'MinPeakProminence', NamePairArguments.MinPeakProminence);
    [~, LfiltMax] = findpeaks(LpitchVelMov,'MinPeakHeight',NamePairArguments.MinPeakHeight, 'MinPeakProminence', NamePairArguments.MinPeakProminence);
    
    %make sure no double steps detected
    [RfiltMax2, LfiltMax2] = removeDoubleSteps(RfiltMax,RpitchVelMov,LfiltMax,LpitchVelMov);
    
    
    %make sure first step is R
    if LfiltMax2(1) < RfiltMax2(1)
        LfiltMax2(1) = [];
    end
    numSteps = min([length(RfiltMax2) length(LfiltMax2)]) -1;
    
    rightHS = NaN(numSteps,1);
    leftHS = NaN(numSteps,1);
    
    %find final index depending on method
    switch NamePairArguments.Method
        case 'zero'
            
            %find next zero crossing
            for ii = 1:numSteps
                searchRange = min([length( RfiltMax2(ii):(RfiltMax2(ii)+(fs)) )...
                                    length( RfiltMax2(ii):RfiltMax2(end) )...
                                    ]);
                idx = getZeroCrossings(RpitchVel((RfiltMax2(ii)):(RfiltMax2(ii)+searchRange)),'down');
                rightHS(ii) = RfiltMax2(ii) - 1 + idx(1);
                
                searchRange = min([length( LfiltMax2(ii):(LfiltMax2(ii)+(fs)) ) ...
                                    length( LfiltMax2(ii):LfiltMax2(end) )...
                                    ]);
                idx = getZeroCrossings(LpitchVel((LfiltMax2(ii)):(LfiltMax2(ii)+searchRange)),'down');
                leftHS(ii) = LfiltMax2(ii) - 1 + idx(1);
            end
        case 'peak'
            for ii = 1:numSteps
                searchRange = movRange*2;
                [~, idx] = max( RpitchVel((RfiltMax2(ii)-searchRange):(RfiltMax2(ii)+searchRange)) );
                rightHS(ii) = RfiltMax2(ii) -searchRange - 1 + idx;

                [~, idx] = max( LpitchVel((LfiltMax2(ii)-searchRange):(LfiltMax2(ii)+searchRange)) );
                leftHS(ii) = LfiltMax2(ii) -searchRange - 1 + idx;
            end
    end
    
    %remove duplicates
    [rightHS, leftHS] = removeDoubleSteps(rightHS,-abs(RpitchVel),leftHS,-abs(LpitchVel));

    %make sure first step is R
    if leftHS(1) < rightHS(1)
        leftHS(1) = [];
    end

  %show results 
    if NamePairArguments.Showplots
        dt = 1/fs;
        t = (1:length(RpitchVelMov))'.*dt;
        figure
        plot(t,RpitchVelMov,'r')
        hold on
        plot(t,LpitchVelMov,'b')
        plot(RfiltMax2.*dt, RpitchVelMov(RfiltMax2),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
        plot(LfiltMax2.*dt, LpitchVelMov(LfiltMax2),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
        legend('R','L')
        title('Filtered Peak Detection')
        ylabel('Filtered Angular Velocity (deg/s)')
        xlabel('Time (s)')

        figure
        plot(t,RpitchVel,'r')
        hold on
        plot(t,LpitchVel,'b')
        plot(rightHS.*dt, RpitchVel(rightHS),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
        plot(leftHS.*dt, LpitchVel(leftHS),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
        legend('R','L')
        title('Method: ' + NamePairArguments.Method)
        ylabel('Angular Velocity (deg/s)')
        xlabel('Time (s)')
        
    end
    
end

%File: removeDoubleSteps.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-19
%
%[RstepIDX, LstepIDX] = removeDoubleSteps(RstepIDX,Rsignal,LstepIDX,Lsignal)
%
%Function to remove double step indexes by choosing the largest peak when 2
%from the same foot are in a row
%
%Improve me!
%

function [RstepIDX, LstepIDX] = removeDoubleSteps(RstepIDX,Rsignal,LstepIDX,Lsignal)

    Ridx = 1;
    Lidx = 1;
    RstepPks = Rsignal(RstepIDX);
    LstepPks = Lsignal(LstepIDX);
    while (Lidx+1 <= length(LstepIDX) ) && (Ridx+1 <= length(RstepIDX) )
        [~, foot] = min([RstepIDX(Ridx); LstepIDX(Lidx)]);
        if foot ==1
            %check if next peak is on same side
            if RstepIDX(Ridx+1) < LstepIDX(Lidx)
                %find andd remove smaller peak
                [~, minPeak] = min([RstepPks(Ridx); RstepPks(Ridx+1)]);

                if minPeak ==1
                    RstepIDX(Ridx) = [];
                    RstepPks(Ridx) = [];
                else
                    RstepIDX(Ridx+1) = [];
                    RstepPks(Ridx+1) = [];
                end
            else
                Ridx = Ridx +1;
            end
            
        end
        if foot ==2
            %check if next peak is on same side
            if LstepIDX(Lidx+1) < RstepIDX(Ridx)
                %find andd remove smaller peak
                [~, minPeak] = min([LstepPks(Lidx); LstepPks(Lidx+1)]);
                if minPeak ==1
                    LstepIDX(Lidx) = [];
                    LstepPks(Lidx) = [];
                else
                    LstepIDX(Lidx+1) = [];
                    LstepPks(Lidx+1) = [];
                end
            else
                Lidx = Lidx +1;
                
            end
            
        end     
        
    end
end
