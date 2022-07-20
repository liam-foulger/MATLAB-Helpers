%File: footStepDetection.m
%Author: Liam Foulger
%Date Created: 2022-06-17
%Last Updated: 2022-07-20
%
%Function to detect steps from left and right foot/ankle IMUs. Returns the
%step indices for each foot contact. 
%2 possible methods:
% 1) Y angular velocity zero crossings:
%   - Finds the + to - zero crossing following the peak + angular velocity
%   - Detected heel strikes have ~100ms delay from true timing, but better
%   reliability
%   - Based on method from Mariani et al. (2013) doi: 10.1109/TBME.2012.2227317
% 2) Y angular velocity peak
%   - finds the true peak angular velocity from filtered peak angular
%   velocity
%   - less delay than method 1 but more variable so I do not recommend.
%
%Inputs:
% - right IMU data (XYZ accel & XYZ gyro; assumes X:forward, Y: right, Z:
% down)
% - left IMU data 
% - sample rate (Hz)
% - method: 'zero' (default) or 'peak' 
%Outputs: 


%Dependencies
% - removeDoubleSteps.m
% - getZeroCrossings.m
function [leftSteps, rightSteps] = footStepDetection(varargin)
    if length(varargin) < 3
        return
    end

    rightIMU = varargin{1};
    leftIMU = varargin{2}
    fs = varargin{3}
    
    if length(varargin) < 4
        method = 'zero';
    else
        method = varargin{4};
    end
    
    
    RpitchVel = detrend(rightIMU(:,5));
    LpitchVel = detrend(leftIMU(:,5));
    
    %find max peaks of angular velocity (lightly filtered) using findpeaks function 
    movRange = fs/20;
    RpitchVelMov = movmean(RpitchVel, movRange);
    LpitchVelMov = movmean(LpitchVel, movRange);
    [~, Rmins] = findpeaks(RpitchVelMov,'MinPeakHeight',50, 'MinPeakProminence', 100);
    [~, Lmins] = findpeaks(LpitchVelMov,'MinPeakHeight',50, 'MinPeakProminence', 100);
    
    %show results
%     figure
%     plot(RpitchVelMov,'r')
%     hold on
%     plot(LpitchVelMov,'b')
%     plot(Rmins, RpitchVelMov(Rmins),'o')
%     plot(Lmins, LpitchVelMov(Lmins),'o')
%     legend('R','L')
    
    %make sure no double steps detected
    [Rmaxs, Lmaxs] = removeDoubleSteps(Rmins,RpitchVelMov,Lmins,LpitchVelMov);
    
%     %find max peak of angular velocity that is within first 1/2 of two mins
    numSteps = min([length(Rmins) length(Lmins)]) -1;
%     Rmaxs = NaN(numSteps,1);
%     Lmaxs = NaN(numSteps,1);
%     for ii = 1:numSteps
%         searchRange = round((Rmins(ii+1)-Rmins(ii))/2);
%         [~,idx] = max(RpitchVelMov(Rmins(ii):(Rmins(ii)+searchRange)));
%         Rmaxs(ii) = Rmins(ii) + idx - 1;
%         
%         searchRange = round((Lmins(ii+1)-Lmins(ii))/2);
%         [~,idx] = max(LpitchVelMov(Lmins(ii):(Lmins(ii)+searchRange)));
%         Lmaxs(ii) = Lmins(ii) + idx - 1;
% 
% %         searchRange = round((Rmins(ii+1)-Rmins(ii))/2);
% %         [~,idx] = max(RpitchVel(Rmins(ii)+searchRange:(Rmins(ii+1))));
% %         Rmaxs(ii) = Rmins(ii)+searchRange + idx - 1;
% %         
% %         searchRange = round((Lmins(ii+1)-Lmins(ii))/2);
% %         [~,idx] = max(LpitchVel(Lmins(ii)+searchRange:(Lmins(ii+1))));
% %         Lmaxs(ii) = Lmins(ii) +searchRange+ idx - 1;
%     end
%     
%     figure
%     plot(RpitchVel,'r')
%     hold on
%     plot(LpitchVel,'b')
%     plot(Rmaxs, RpitchVel(Rmaxs),'o')
%     plot(Lmaxs, LpitchVel(Lmaxs),'o')
%     legend('R','L')
    
    Rzeros = NaN(numSteps,1);
    Lzeros = NaN(numSteps,1);
    %find next zero crossing
    for ii = 1:numSteps
        idx = getZeroCrossings(RpitchVel(Rmaxs(ii):end),'down');
        Rzeros(ii) = Rmaxs(ii) - 1 + idx(1);
        
        idx = getZeroCrossings(LpitchVel(Lmaxs(ii):end),'down');
        Lzeros(ii) = Lmaxs(ii) - 1 + idx(1);
    end
%     
%     figure
%     plot(RpitchVel,'r')
%     hold on
%     plot(LpitchVel,'b')
%     plot(Rzeros, RpitchVel(Rzeros),'o')
%     plot(Lzeros, LpitchVel(Lzeros),'o')
%     legend('R','L')
    
    
    
    %assign to final variables
    leftSteps = Lzeros;
    rightSteps = Rzeros;
    
    %make sure first step is R
    if leftSteps(1) < rightSteps(1)
        leftSteps(1) = [];
    end
end