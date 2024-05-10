%File: strideDetection.m
%Author: Liam Foulger
%Date Created: 2022-05-28
%Last Updated: 2023-10-28
%
% [strideIDXs, stepCadence,nStridesRemoved] = strideDetection(rightIMU, leftIMU, fs,NamePairArguments)
%
%Function to detect strides from foot/ankle mounted IMUs on each
%ankle/foot. Returns the step indices for each foot contact. Uses 
%footStepDetection.m to determine the foot contact indexes
%
% References:
% Bötzel, K., Marti, F. M., Rodríguez, M. Á. C., Plate, A., & Vicente, A. O. (2016). 
% Gait recording with inertial sensors – How to determine initial and terminal contact. 
% Journal of Biomechanics, 49(3), 332–337. https://doi.org/10.1016/j.jbiomech.2015.12.035
% Mariani, B., Rouhani, H., Crevoisier, X., & Aminian, K. (2013). 
% Quantitative estimation of foot-flat and stance phase of gait using foot-worn inertial sensors. 
% Gait & Posture, 37(2), 229–234. https://doi.org/10.1016/j.gaitpost.2012.07.012
% 
%Inputs:
% - right IMU data (XYZ accel & XYZ gyro (deg/s); assumes X:forward, Y: right, Z:
% down) (n x 6)
% - left IMU data (n x 6)
% - sample rate (Hz)
% - NamePair arugments:
%    - 'HSmethod': Method to detect heel strikes. 
%        -'GYmin' (default): local minima of pitch (Y) angular velocity following midswing peak.
%               *BEST OPTION FOR SHANK IMU PLACEMENTS (Botzel et al, 2016)*
%        -'GYzero': + to - zero crossing following midswing peak 
%        -'NetAcc': local minimal of net linear acceleration following
%        midswing peak. Searches around the GYmin.
%               *BEST OPTION FOR FOOT IMU PLACEMENTS (Mariani et al., 2013)
%    - 'TOmethod': Method to detect toe off. 
%       -'GYzero' (default): finds the zero crossing of the pitch angular
%       velocity prior to the midswing peak as toe-off
%               *BEST OPTION FOR SHANK IMU PLACEMENTS (Botzel et al, 2016)*
%       -'GYmin': Finds the local minima prior to the pitch angular
%       velocity midswing peak as toe-off
%       -'NetAcc': finds the local maxima of the net linear acceleration
%       between the opposite foot heel strike and the ipsilateral midswing
%       angular velocity pitch peak
%               *BEST OPTION FOR FOOT IMU PLACEMENTS (Mariani et al, 2013)*
%    - 'Events': 'HS' (default) or 'HS&TO'. HS: returns indices for just
%    heel strike events as [rHS lHS rHS-1]. HS&TO: returns indices for heel
%    strike and toe off events as [rHS lTO lHS rTO rHS-1].
%    - 'Showplots': If you want to show the plots:
%           'no': do not show any plots from stride detection
%           'all': show all the relevant plots from the stride detection
%           (helpful for debugging)
%           'summary': show just the final, normalized plots (useful to
%           check that it worked OK)
%    - 'MinPeakHeight'. Min height of peak angular velocity. Default is
%    50. For findpeaks function.
%    - 'MinPeakProminence'. Min peak prominence of angular velocity. Default is
%    100. For findpeaks function.
%    - 'Buffer': Number of seconds at start and end of data that should not
%    be used to detect strides. Any detected strides within this point will
%    be removed. 
%    - 'badStrideCutoff': Multiplier for how strict to be when removing bad
%    strides (i.e., 50 = strides 50% shorter or longer are removed)
%    - 'badStrideType': How to remove bad strides:
%        - 'strideLength': based just on overall stride length (RHS to RHS)
%        *DEFAULT*
%        - 'gaitEvents': based on the deviation of any gait event duration
%        (ie if any are abnormally short/long, the whole stride is removed)
%        - 'none': no gait filtering
%Outputs: 
% - stride indices (3/5 x n). 
%     - for each column: 
%     - IF Events: "HS": r1: R foot heel strike. r2: L foot heel strike. r3: before
%     next foot heel strike (ie. end of stride cycle).
%     - IF Events: "HS&TO": r1: R foot heel strike. r2: L foot toe-off. r3: L foot heel strike. 
%       r4: right foot toe-off r5: before next foot heel strike (ie. end of stride cycle).
% - Cadence (1 x n): the step cadence between every step
% - nStridesRemoved (1 x 1): The total number of strides removed 
% 
%Dependencies:
% - getZeroCrossings.m

function [strideIDXs, stepCadence,nStridesRemoved] = strideDetection(rightIMU, leftIMU, fs,NamePairArguments)
    arguments
        rightIMU double
        leftIMU double
        fs double
        NamePairArguments.HSmethod {mustBeMember(NamePairArguments.HSmethod,['GYzero','GYmin','NetAcc'])} = 'GYmin'
        NamePairArguments.TOmethod {mustBeMember(NamePairArguments.TOmethod,['GYzero','GYmin','NetAcc'])} = 'GYzero'
        NamePairArguments.Events {mustBeMember(NamePairArguments.Events,['HS','HS&TO'])}= 'HS&TO'
        NamePairArguments.Showplots {mustBeMember(NamePairArguments.Showplots,['no','all','summary'])} = 'no'
        NamePairArguments.MinPeakHeight (1,1) {mustBeNumeric} = 50
        NamePairArguments.MinPeakProminence (1,1) {mustBeNumeric} = 100
        NamePairArguments.Buffer (1,1) {mustBeNumeric} = 0
        NamePairArguments.badStrideCutoff (1,1) {mustBeNumeric} = 50
        NamePairArguments.badStrideType {mustBeMember(NamePairArguments.badStrideType,['strideLength','gaitEvents','None'])}= 'strideLength'
    end
    if strcmp(NamePairArguments.Events,'HS&TO')
        NamePairArguments.Method  = 'zero';
    end
    %filter IMU data @ 20Hz lowpass (4th order)
    cutoff = 20;
    [b,a] = butter(4, cutoff./(fs/2));
    rightIMU = filtfilt(b,a,rightIMU);
    leftIMU = filtfilt(b,a,leftIMU);
    
    %for each IMU, find the HS
    strideIDXs = heelStrikeDetection(rightIMU, leftIMU, fs,'Method',NamePairArguments.HSmethod,...
        'Showplots',NamePairArguments.Showplots,'MinPeakHeight',NamePairArguments.MinPeakHeight,...
        'MinPeakProminence',NamePairArguments.MinPeakProminence);
   
    %find the TO between HS
    if strcmp(NamePairArguments.Events,'HS&TO')
        strideIDXs = toeOffDetection(rightIMU,leftIMU,strideIDXs, fs,'Method',NamePairArguments.TOmethod);
    end

     %remove stride if it is X amount longer or shorter than average stride
    
    switch NamePairArguments.badStrideType
        case 'strideLength'
            maxThreshold =  mean(strideIDXs(5,:) - strideIDXs(1,:))*(1+NamePairArguments.badStrideCutoff/100);
            minThreshold =  mean(strideIDXs(5,:) - strideIDXs(1,:))*(NamePairArguments.badStrideCutoff/100);
            badStrides = sum((strideIDXs(5,:) - strideIDXs(1,:) > maxThreshold) + (strideIDXs(5,:) - strideIDXs(1,:) < minThreshold),1) > 0;
        case 'gaitEvents'
            badStrides = sum((diff(strideIDXs) > mean(diff(strideIDXs),2)*(1+NamePairArguments.badStrideCutoff/100)) + (diff(strideIDXs) < mean(diff(strideIDXs),2)*(NamePairArguments.badStrideCutoff/100)),1) > 0;
        case 'none'
            badStrides = [];
    end
    strideIDXs(:,badStrides) = [];
    nStridesRemoved = sum(badStrides);

    % get step cadence
    numSteps = size(strideIDXs,2);
    cadenceTime = strideIDXs(1,1:numSteps).*1/fs;
    stepCadence = (fs./(mean([strideIDXs(3,:) - strideIDXs(1,:);...
        strideIDXs(5,:) - strideIDXs(3,:)+1],1) )).*60;

    %plotting
    if strcmp(NamePairArguments.Showplots,'all')
        
        figure
        plot(cadenceTime,stepCadence)
        xlabel('Time (s)')
        ylabel('Step Cadence (bpm)')
        box off
    end

    if strcmp(NamePairArguments.Events,'HS&TO')
        if ~strcmp(NamePairArguments.Showplots,'no')
            switch NamePairArguments.HSmethod
                case {'GYzero','GYmin'}
                    varR = rightIMU(:,5);
                    varL = leftIMU(:,5);
                    yLab = 'Angular Velocity (deg/s)';
                case 'NetAcc'
                    varR = vecnorm(rightIMU(:,1:3),2,2);
                    varL = vecnorm(leftIMU(:,1:3),2,2);
                    yLab = 'Linear Acceleration (m/s^2)';
            end
            t = (1:length(varR))'./fs;
            if strcmp(NamePairArguments.Showplots,'all')
            
                figure
                plot(t,varR,'r')
                hold on
                plot(t,varL,'b')
                plot(strideIDXs(1,:)./fs, varR(strideIDXs(1,:)),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
                plot((strideIDXs(5,:)+1)./fs, varR(strideIDXs(5,:)+1),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
                plot(strideIDXs(4,:)./fs, varR(strideIDXs(4,:)),'Marker','*','MarkerEdgeColor','r','LineStyle','none')
                plot(strideIDXs(3,:)./fs, varL(strideIDXs(3,:)),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
                plot(strideIDXs(2,:)./fs, varL(strideIDXs(2,:)),'Marker','*','MarkerEdgeColor','b','LineStyle','none')
                legend('R','L','HS','','TO')
                title('Heel Strikes & Toe-Offs')
                ylabel(yLab)
                xlabel('Time (s)')
            end
            % ADD SUMMARY PLOT HERE
            [strides, normIDXs, ~] = spiltStrides([varL varR], strideIDXs, 'normalize');
            strides = cat(3,strides{:});
            
            t = normIDXs(1):normIDXs(end);
            figure
            subplot(121)
            hold on
            plot(t,squeeze(strides(:,1,:)),'k','LineWidth',0.5)
            plot(t,mean(strides(:,1,:),3),'r','LineWidth',1.5)
            xline(normIDXs,'--r')
            box off
            xticks(normIDXs(1:end-1))
            xticklabels(["RHS","LTO","LHS","RTO"])
            title("Left IMU")
            subplot(122)
            hold on
            plot(t,squeeze(strides(:,2,:)),'k','LineWidth',0.5)
            plot(t,mean(strides(:,2,:),3),'r','LineWidth',1.5)
            xline(normIDXs,'--r')
            box off
            xticks(normIDXs(1:end-1))
            xticklabels(["RHS","LTO","LHS","RTO"])
            title("Right IMU")
        end
    else
        strideIDXs([2 4],:) = [];
    end
    
   
    
    %make adjustments given Mariani et al(2013) 
    % switch NamePairArguments.Events
    %     case 'HS&TO'
    %         switch NamePairArguments.HSmethod
    %             case 'GYzero'
    %                 strideIDXs([1 3 5],:) = strideIDXs([1 3 5],:) + round( 0.039*fs);
    %             case 'GYmin'
    %                  strideIDXs([1 3 5],:) = strideIDXs([1 3 5],:) - round( 0.029*fs);             
    %             case 'NetAcc'
    %                 strideIDXs([1 3 5],:) = strideIDXs([1 3 5],:) - round( 0.001*fs);
    %         end
    %         switch NamePairArguments.TOmethod
    %             case 'GYmin'
    %                 strideIDXs([2 4],:) = strideIDXs([2 4],:) + round( 0.033*fs);
    %             case 'NetAcc'
    %                 strideIDXs([2 4],:) = strideIDXs([2 4],:) + round( 0.003*fs);
    %         end
    %     case 'TO'
    %         case 'GYzero'
    %                 strideIDXs = strideIDXs + round( 0.039*fs);
    %         case 'GYmin'
    %              strideIDXs = strideIDXs - round( 0.029*fs);             
    %         case 'NetAcc'
    %             strideIDXs = strideIDXs - round( 0.001*fs);
    % end

    
    if NamePairArguments.Buffer > 0 
        strideIDXs(:,max(strideIDXs < NamePairArguments.Buffer*fs)) = [];
        strideIDXs(:,max(strideIDXs > (size(rightIMU,1) - (NamePairArguments.Buffer*fs)) )) = [];
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

function strideIDXs = toeOffDetection(rightIMU,leftIMU,strideIDXs, fs,NamePairArguments)
    arguments
        rightIMU double
        leftIMU double
        strideIDXs double
        fs double
        NamePairArguments.Method {mustBeMember(NamePairArguments.Method,['GYzero','GYmin','NetAcc'])} = 'GYzero'
    end
    numStrides = size(strideIDXs,2);
    

    RpitchVel = detrend(rightIMU(:,5));
    LpitchVel = detrend(leftIMU(:,5));
    [b,a] = butter(4,3/(fs/2),'low');
    RpitchVelMov = filtfilt(b,a,RpitchVel);
    LpitchVelMov = filtfilt(b,a,LpitchVel);
    
    switch NamePairArguments.Method
        case 'GYzero'
            for ii = 1:numStrides
                try
                    %find gyro zero crossing (rising) between TO
                    [~,midSwing] = max(LpitchVel(strideIDXs(1,ii):strideIDXs(3,ii))) ;
                    idx = getZeroCrossings(LpitchVel(strideIDXs(1,ii):(strideIDXs(1,ii)+midSwing) ),'up');

                    if ~isempty(idx)  && length(idx) == 1
                        strideIDXs(2,ii) = idx(end) + strideIDXs(1,ii) - 1;
                    end
                    
                    %find gyro zero crossing (rising) between TO
                    [~,midSwing] = max(RpitchVel(strideIDXs(3,ii):strideIDXs(5,ii)));
                    idx = getZeroCrossings(RpitchVel(strideIDXs(3,ii):(strideIDXs(3,ii)+midSwing) ),'up');
                    %find zero value between left HS and next right HS to find right TO
                    if ~isempty(idx)  && length(idx) == 1
                        strideIDXs(4,ii) = idx(end) + strideIDXs(3,ii) - 1;
                    end
                catch
                    strideIDXs(:,ii) = NaN;
                end
            end   

        case 'GYmin'
            for ii = 1:numStrides
                try
                    %find gyro zero crossing (rising) between TO
                    idx = getZeroCrossings(LpitchVel(strideIDXs(1,ii):strideIDXs(3,ii)),'up');
                    
                    %find min value between right HS and left HS to find left TO
                    [~,loc] = min(LpitchVel( strideIDXs(1,ii):strideIDXs(1,ii)+idx(1) ) );
                    if ~isempty(loc)
                        strideIDXs(2,ii) = loc + strideIDXs(1,ii) - 1;
                    end
                    
                    %find gyro zero crossing (rising) between TO
                    idx = getZeroCrossings(RpitchVel(strideIDXs(3,ii):strideIDXs(5,ii)),'up');
                    %find min value between left HS and next right HS to find right TO
                    [~,loc] = min(RpitchVel( strideIDXs(3,ii):strideIDXs(3,ii)+idx ) );
                    if ~isempty(loc)
                        strideIDXs(4,ii) = loc + strideIDXs(3,ii) - 1;
                    end
                catch
                    strideIDXs(:,ii) = NaN;
                end
            end
        case 'NetAcc'
            RnetAcc = vecnorm(rightIMU(:,1:3),2,2);
            LnetAcc = vecnorm(leftIMU ...
                (:,1:3),2,2);
            for ii = 1:numStrides
                try

                    %find the left foot midswing as the maximum angular pitch
                    %velocity between right heel strike and left heel strike
                    [~,lMidSwing] = max(LpitchVelMov( strideIDXs(1,ii):strideIDXs(3,ii) ) );
    
                    %find max value between right HS and left midswing to find left TO
                    [~,loc] = max(LnetAcc( strideIDXs(1,ii):(strideIDXs(1,ii)+lMidSwing) ) );
                    if ~isempty(loc)
                        strideIDXs(2,ii) = loc + strideIDXs(1,ii) - 1;
                    end
                    
                    %find the right foot midswing as the maximum angular pitch
                    %velocity between left heel strike and right heel strike
                    [~,rMidSwing] = max(RpitchVelMov( strideIDXs(3,ii):strideIDXs(5,ii) ) );
    
                    %find min value between left HS and next right HS to find right TO
                    [~,loc] = max(RnetAcc( strideIDXs(3,ii):(strideIDXs(3,ii)+rMidSwing) ) );
                    if ~isempty(loc)
                        strideIDXs(4,ii) = loc + strideIDXs(3,ii) - 1;
                    end
                catch
                    strideIDXs(:,ii) = NaN;
                end
            end
            
            
    end

    strideIDXs(:,((isnan(strideIDXs(2,:))+isnan(strideIDXs(4,:))) > 0)) = [];
    
end


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


function strideIDX = heelStrikeDetection(rightIMU, leftIMU, fs, NamePairArguments)
    
    arguments
        rightIMU double
        leftIMU double
        fs double
        NamePairArguments.Method {mustBeMember(NamePairArguments.Method,['GYzero','GYmin','NetAcc'])} = 'GYmin'
        NamePairArguments.Showplots {mustBeMember(NamePairArguments.Showplots,['no','all','summary'])} = 'no'
        NamePairArguments.MinPeakHeight (1,1) {mustBeNumeric} = 50
        NamePairArguments.MinPeakProminence (1,1) {mustBeNumeric} = 100
    end
    
    %detrend data
    RpitchVel = detrend(rightIMU(:,5));
    LpitchVel = detrend(leftIMU(:,5));
    
    %find max peaks of angular velocity (heavy filtered) using findpeaks function 

    [b,a] = butter(4,3/(fs/2),'low');
    RpitchVelMov = filtfilt(b,a,RpitchVel);
    LpitchVelMov = filtfilt(b,a,LpitchVel);

    [~, RfiltMax] = findpeaks(RpitchVelMov,'MinPeakHeight',NamePairArguments.MinPeakHeight, 'MinPeakProminence', NamePairArguments.MinPeakProminence);
    [~, LfiltMax] = findpeaks(LpitchVelMov,'MinPeakHeight',NamePairArguments.MinPeakHeight, 'MinPeakProminence', NamePairArguments.MinPeakProminence);
    
    %make sure no double steps detected
    [RfiltMax2, LfiltMax2] = removeDoubleSteps(RfiltMax,RpitchVelMov,LfiltMax,LpitchVelMov);
    
    
    %make sure first step is R
    if LfiltMax2(1) < RfiltMax2(1)
        LfiltMax2(1) = [];
    end

    %remove "false" first step
    if RpitchVel(RfiltMax2(1))*3 < mean(RpitchVel(RfiltMax2))
        RfiltMax2(1) = [];
        LfiltMax2(1) = [];
    end


    nStrides = min([length(RfiltMax2)-1 length(LfiltMax2)]);
    
    % rightHS = NaN(nStrides,1);
    % leftHS = NaN(nStrides,1);
    strideIDX = NaN(5,nStrides);
    %find final index depending on method
    switch NamePairArguments.Method
        case 'GYzero'
            for ii = 1:nStrides
                try

                    %set search range between right midswing peak and 1 second
                    %after
                    searchRange = min([length( RfiltMax2(ii):(RfiltMax2(ii)+(fs)) )...
                                        length( RfiltMax2(ii):RfiltMax2(end) )...
                                        ]);
                    idx = getZeroCrossings(RpitchVel((RfiltMax2(ii)):(RfiltMax2(ii)+searchRange)),'down');
                    strideIDX(1,ii) = RfiltMax2(ii) - 1 + idx(1);
                    
                    searchRange = min([length( LfiltMax2(ii):(LfiltMax2(ii)+(fs)) ) ...
                                        length( LfiltMax2(ii):LfiltMax2(end) )...
                                        ]);
                    idx = getZeroCrossings(LpitchVel((LfiltMax2(ii)):(LfiltMax2(ii)+searchRange)),'down');
                    strideIDX(3,ii) = LfiltMax2(ii) - 1 + idx(1);
                    if ii > 1
                        strideIDX(5,ii-1) = strideIDX(1,ii)-1;
                    end
                catch
                    strideIDX(:,ii) = NaN;
                end

            end
        case {'GYmin','NetAcc'}
            % this case finds the heel strike as the angular velocity pitch
            % minima. For the net acc case, it searches based on this.
            for ii = 1:nStrides
                try
                    %right HS
                    %set search range between right midswing peak and 20ms before left zero
                    %crossing (- to +) for pitch angular velocity
                    searchRange = getZeroCrossings(LpitchVel(RfiltMax2(ii):LfiltMax2(ii)),"up");
                    searchRange = searchRange(end) - round(fs/50);
                    %find mimima
                    [~,idx] = min(RpitchVel(RfiltMax2(ii):(RfiltMax2(ii)+searchRange)) );
                    % idx = find(islocalmin(RpitchVel(RfiltMax2(ii):(RfiltMax2(ii)+searchRange))));
                    % idx = idx(RpitchVel(idx) < 0);
                    % if isempty(idx)
                    %     [~,idx] = min(RpitchVel(RfiltMax2(ii):(RfiltMax2(ii)+searchRange)) );
                    % end
                    rightHS = RfiltMax2(ii) - 1 + idx(1);
                    
                    
                    %left HS
                    searchRange = getZeroCrossings(RpitchVel(LfiltMax2(ii):RfiltMax2(ii+1)),"up");
                    searchRange = searchRange(end)- round(fs/50);
                    %find minima
                    [~,idx] = min(LpitchVel(LfiltMax2(ii):(LfiltMax2(ii)+searchRange)) );
                    % idx = find(islocalmin(LpitchVel(LfiltMax2(ii):(LfiltMax2(ii)+searchRange))));
                    % idx = idx(RpitchVel(idx) < 0);
                    % if isempty(idx)
                    %     [~,idx] = min(LpitchVel(LfiltMax2(ii):(LfiltMax2(ii)+searchRange)) );
                    % 
                    % end
                    leftHS = LfiltMax2(ii)  - 1 + idx(1);
                    
                    % check that the index found has an angular velocity below
                    % 0, otherwise remove this stride
                    if RpitchVel(rightHS) >= 0 
                        rightHS = NaN;
                       
                    elseif LpitchVel(leftHS) >= 0
                        leftHS = NaN;
    
                    end
                    strideIDX(1,ii) = rightHS;
                    strideIDX(3,ii) = leftHS;
                    if ii > 1
                        strideIDX(5,ii-1) = strideIDX(1,ii)-1;
                    end
                catch
                    strideIDX(:,ii) = NaN;
                end
            end
    end 
    if strcmp(NamePairArguments.Method,'NetAcc')
        RnetAcc = vecnorm(rightIMU(:,1:3),2,2);
        LnetAcc = vecnorm(leftIMU(:,1:3),2,2);
        for ii = 1:nStrides
            try
                %set search range as -80ms to +20ms around GYmin
                searchRange = (strideIDX(1,ii)-round(fs*0.080)):(strideIDX(1,ii)+round(fs*0.020));
                %find minima of net acc
                [~, idx] = min( RnetAcc(searchRange));
                strideIDX(1,ii) = searchRange(1) - 1 + idx;
                
                %set search range as -80ms to +20ms around GYmin
                searchRange = (strideIDX(3,ii)-round(fs*0.080)):(strideIDX(3,ii)+round(fs*0.020));
                %find minima of net acc
                [~, idx] = min( LnetAcc(searchRange));
                strideIDX(3,ii) = searchRange(1) - 1 + idx;
    
                if ii > 1
                    strideIDX(5,ii-1) = strideIDX(1,ii)-1;
                end
            catch
                strideIDX(:,ii) = NaN;
            end
        end
        
            
    end
    % trim the array in case of removal during detection
    strideIDX(:,(isnan(strideIDX(1,:))+isnan(strideIDX(3,:))+isnan(strideIDX(5,:))) > 0) = [];    
    


    if strideIDX(3,1) < strideIDX(1,1)
        strideIDX(3,:) = circshift(strideIDX(3,:),-1);
        strideIDX(:,end) = [];
    end

  %show results 
    if strcmp(NamePairArguments.Showplots,'all')
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
        
        if strcmp('NetAcc',NamePairArguments.Method)
            figure
            plot(t,RnetAcc,'r')
            hold on
            plot(t,LnetAcc,'b')
            plot(strideIDX(1,:).*dt, RnetAcc(strideIDX(1,:)),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
            plot((strideIDX(5,:)+1).*dt, RnetAcc(strideIDX(5,:)+1),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
            plot(strideIDX(3,:).*dt, LnetAcc(strideIDX(3,:)),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
            legend('R','L')
            title(['HS Method: ' NamePairArguments.Method])
            ylabel('Linear Acceleration')
            xlabel('Time (s)')
            
        else
            figure
            plot(t,RpitchVel,'r')
            hold on
            plot(t,LpitchVel,'b')
            plot(strideIDX(1,:).*dt, RpitchVel(strideIDX(1,:)),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
            plot((strideIDX(5,:)+1).*dt, RpitchVel(strideIDX(5,:)+1),'Marker','o','MarkerEdgeColor','r','LineStyle','none')
            plot(strideIDX(3,:).*dt, LpitchVel(strideIDX(3,:)'),'Marker','o','MarkerEdgeColor','b','LineStyle','none')
            legend('R','L')
            title(['HS Method: ' NamePairArguments.Method])
            ylabel('Angular Velocity (deg/s)')
            xlabel('Time (s)')
        end
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
            if RstepIDX(Ridx+1) <= LstepIDX(Lidx)
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
            
        
        elseif foot ==2
            %check if next peak is on same side
            if LstepIDX(Lidx+1) <= RstepIDX(Ridx)
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
