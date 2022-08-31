%File: optoAccel.m
%Author: Liam Foulger
%Date Created: 2020-06-01 
%Last Updated: 2022-08-31
%
% accel = optoAccel(marker1, marker2, marker3, fs, NamePairArguments)
%
% Function to return the accelerations of a 3 marker optotrak rigid body
%
% Inputs: 
%   - 3 markers: nx3 matrix (where n is number of data points). 
%   - 'fs': sample rate of data (Hz). 
%   - NamePairArguments (optional)
%    - 'FilterCutoff': Cutoff for optional butterworth filter (Hz). Default is 0 (no filter
%    applied).
%    - 'FilterOrder': Order for optional butterworth filter. Default is 2.
%    - 'FilterType':  Filter type for optional butterworth filter. Options
%    are: 'low' (default), 'high','stop', or 'bandpass'
% Outputs:
%   - XYZ position, velocity, and, acceleration data. Output units will match input units. Ie. if
%   position data is inputted as metres, the resulting will be m/s^2.

function [pos, vel, accel] = optoRigidBody(marker1, marker2, marker3, fs, NamePairArguments)
    arguments 
        marker1 double
        marker2 double
        marker3 double
        fs double 
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 2
        NamePairArguments.FilterType (1,1) string = "low"
    end
    
    %Get average position of the 3 markers
    pos = mean(cat(3, marker1, marker2, marker3),3);
    pos = pos - mean(pos,1);
    vel = [zeros(1,3); diff(pos).*fs];
    accel = [zeros(1,3); diff(diff(pos).*fs).*fs; zeros(1,3)];
    
    if NamePairArguments.FilterCutoff > 0
        [b,a] = butter(NamePairArguments.FilterOrder, NamePairArguments.FilterCutoff./(fs/2),NamePairArguments.FilterType);
        pos = filtfilt(b,a,pos);
        vel = filtfilt(b,a,vel);
        accel = filtfilt(b,a,accel);
    end
end