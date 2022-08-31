%File: get_ngAccel.m
%Author: Liam Foulger
%Date created: 2020-10-30
%Last updated: 2021-07-11
%
%[x_ng_accel, y_ng_accel] = get_ngAccel(accel, x_tilt, y_tilt,fs)
%
%Function to return the acceleration measures (from IMU) with gravity removed 
%Input: 
% - raw accelerations (NED) (n x 3) (m/s^2)
% - pitch tilt (N = +) (deg)
% - roll tilt (E = +) (deg)
% - sample rate (Hz)
% - filter cutoff (Hz)
%Output: 
% - accelerations in x and y directions without gravity (m/s^2)

function [x_ng_accel, y_ng_accel] = get_ngAccel(accel, x_tilt, y_tilt,fs, NamePairArguments)
    arguments 
        accel double
        x_tilt double
        y_tilt double
        fs double 
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 2
        NamePairArguments.FilterType (1,1) string = "low"
    end
    
    [x_grav, y_grav] = get_expected_g(x_tilt, y_tilt);
    
    ng_x = ((accel(:,1) - x_grav(:,1)).*cosd(x_tilt)) -((accel(:,3) - x_grav(:,2)).*sind(x_tilt));
    ng_y = ((accel(:,2) - y_grav(:,1)).*cosd(y_tilt)) -((accel(:,3) - y_grav(:,2)).*sind(y_tilt));
    
    [b1,a1] = butter(4, cutoff./(fs/2));
    x_ng_accel = filtfilt(b1,a1, ng_x);
    y_ng_accel = filtfilt(b1,a1, ng_y);  
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