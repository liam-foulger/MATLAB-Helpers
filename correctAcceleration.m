%File: get_ngAccel.m
%Author: Liam Foulger
%Date created: 2020-10-30
%Last updated: 2021-07-11
%
% correctedAccel = correctAcceleration(accel, pitch, roll,fs, NamePairArguments)
%
% Function to return the acceleration measures (from IMU) with gravity removed 
% Input: 
% - raw accelerations (NED) (n x 3) (m/s^2)
% - pitch tilt (forward = +) (deg)
% - roll tilt (right = +) (deg)
% - sample rate (Hz)
% - NamePairArguments (optional)
%    - 'FilterCutoff': Cutoff for optional butterworth filter (Hz). Default is 0 (no filter
%    applied).
%    - 'FilterOrder': Order for optional butterworth filter. Default is 2.
%    - 'FilterType':  Filter type for optional butterworth filter. Options
%    are: 'low' (default), 'high','stop', or 'bandpass'
% Output: 
% - accelerations in x and y directions without gravity (m/s^2)

function correctedAccel = correctAcceleration(accel, pitch, roll,fs, NamePairArguments)
    arguments 
        accel double
        pitch double
        roll double
        fs double 
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 2
        NamePairArguments.FilterType (1,1) {mustBeMember(NamePairArguments.FilterType,{'low','high','stop','bandpass'})}  = "low"
    end
    
    [x_grav, y_grav] = get_expected_g(pitch, roll);
    
    ng_x = ((accel(:,1) - x_grav(:,1)).*cosd(pitch)) -((accel(:,3) - x_grav(:,2)).*sind(pitch));
    ng_y = ((accel(:,2) - y_grav(:,1)).*cosd(roll)) -((accel(:,3) - y_grav(:,2)).*sind(roll));
    
    
    
    if NamePairArguments.FilterCutoff > 0
        [b,a] = butter(NamePairArguments.FilterOrder, NamePairArguments.FilterCutoff./(fs/2),NamePairArguments.FilterType);
        correctedAccel(:,1) = filtfilt(b,a, ng_x);
        correctedAccel(:,2) = filtfilt(b,a, ng_y); 
%         correctedAccel(:,3) = filtfilt(b,a, ng_z); 
    else
        correctedAccel(:,1) = ng_x;
        correctedAccel(:,2) = ng_y; 
%         correctedAccel(:,3) = ng_z; 
    end
end

function [x_grav, y_grav] = get_expected_g(x_tilt, y_tilt)
    %function to return the expected gravity in the x and y vectors (north
    %and east) given the inputted AP and ML tilts
    %using simple trig functions
    %first column: AP/ML
    %second column: down 
    g = -9.80665002864;
    
    x_grav = [g.*sind(x_tilt) g.*cosd(x_tilt)];
    y_grav = [g.*sind(y_tilt) g.*cosd(y_tilt)];
    
end