%File: footStepDetection.m
%Author: Liam Foulger
%Date Created: 2022-06-17
%Last Updated: 2022-07-20
%
%[Rsteps,Lsteps] = footStepDetection(rightIMU, leftIMU, fs, options)
%
%Function to detect steps from left and right foot/ankle IMUs. Returns the
%step indices for each foot contact. 
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
% - right step indices
% - left step indices
%
%Dependencies
% - removeDoubleSteps.m
% - getZeroCrossings.m


function [Rsteps,Lsteps] = footStepDetection(rightIMU, leftIMU, fs, NamePairArguments)
    
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
    numSteps = min([length(RfiltMax2) length(LfiltMax2)]) -1;
    
    %make sure first step is R
    if LfiltMax2(1) < RfiltMax2(1)
        LfiltMax2(1) = [];
    end
    
    Rsteps = NaN(numSteps,1);
    Lsteps = NaN(numSteps,1);
    
    %find final index depending on method
    switch NamePairArguments.Method
        case 'zero'
            
            %find next zero crossing
            for ii = 1:numSteps
                searchRange = min([length( RfiltMax2(ii):(RfiltMax2(ii)+(fs)) )...
                                    length( RfiltMax2(ii):RfiltMax2(end) )...
                                    ]);
                idx = getZeroCrossings(RpitchVel((RfiltMax2(ii)):(RfiltMax2(ii)+searchRange)),'down');
                Rsteps(ii) = RfiltMax2(ii) - 1 + idx(1);
                
                searchRange = min([length( LfiltMax2(ii):(LfiltMax2(ii)+(fs)) ) ...
                                    length( LfiltMax2(ii):LfiltMax2(end) )...
                                    ]);
                idx = getZeroCrossings(LpitchVel((LfiltMax2(ii)):(LfiltMax2(ii)+searchRange)),'down');
                Lsteps(ii) = LfiltMax2(ii) - 1 + idx(1);
            end
        case 'peak'
            for ii = 1:numSteps
                searchRange = movRange*2;
                [~, idx] = max( RpitchVel((RfiltMax2(ii)-searchRange):(RfiltMax2(ii)+searchRange)) );
                Rsteps(ii) = RfiltMax2(ii) -searchRange - 1 + idx;

                [~, idx] = max( LpitchVel((LfiltMax2(ii)-searchRange):(LfiltMax2(ii)+searchRange)) );
                Lsteps(ii) = LfiltMax2(ii) -searchRange - 1 + idx;
            end
    end
    
    %remove duplicates
    [Rsteps, Lsteps] = removeDoubleSteps(Rsteps,-abs(RpitchVel),Lsteps,-abs(LpitchVel));

    %make sure first step is R
    if Lsteps(1) < Rsteps(1)
        Lsteps(1) = [];
    end

  %show results 
    if NamePairArguments.Showplots
        dt = 1/fs;
        t = (1:length(RpitchVelMov))'.*dt;
        figure
        plot(t,RpitchVelMov,'r')
        hold on
        plot(t,LpitchVelMov,'b')
        plot(RfiltMax2.*dt, RpitchVelMov(RfiltMax2),'o')
        plot(LfiltMax2.*dt, LpitchVelMov(LfiltMax2),'o')
        legend('R','L')
        title('Filtered Peak Detection')
        ylabel('Filtered Angular Velocity (deg/s)')
        xlabel('Time (s)')

        figure
        plot(t,RpitchVel,'r')
        hold on
        plot(t,LpitchVel,'b')
        plot(Rsteps.*dt, RpitchVel(Rsteps),'o')
        plot(Lsteps.*dt, LpitchVel(Lsteps),'o')
        legend('R','L')
        title('Method: ' + NamePairArguments.Method)
        ylabel('Angular Velocity (deg/s)')
        xlabel('Time (s)')
        
    end
    
    
    
    
  
end