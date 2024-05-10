% File: imuRemoveGravity.m
% Author: Liam Foulger
% Date Created: 2020-10-30
% Last Updated: 2024-02-15
%
% correctedData = imuRemoveGravity(imu, fs, options)
%
% Function to remove the gravitational linear acceleration component from
% IMU readings. Using the orientation as determined by a complementary
% filter to predict expected gravitational acceleration and remove it.
% There is also an option to correct the accelerations and gyroscope data
% back into the global frame.
%
% Inputs:
% - IMU data (n x 6): XYZ accelerometer (m/s^2) and XYZ gyro
% (deg/s)
% - fs: Sample rate (Hz) (1)
% - options:
%   - compWeight: weight of complementary filter (see that function for
%   more info)
%   - compGerror: gravity error for complementary filter (see that function for
%   more info)
%   - RemoveOffset: if you want to remove the gyro bias in the comp filter
%   (see that function for more info)
%   - Showplots: If you want to see the comp filter plots (default is no,
%   yes = 1)
%   - Filter Specs: 'FilterCutoff', 'FilterOrder', and 'FilterType' (default "low") for
%   optional Butterworth filter. Cutoff and Order must be included for
%   filtering to occur
%   - "ApplyCorrection": if you want to correct the data back into the
%   global frame 0 = no (default) and 1 = yes
% Outputs:
% - correctedIMU (n x 6): XYZ accelerometer (m/s^2) and XYZ gyro (deg/s) of
% gravity corrected IMU
% - IMUOri (n x 2): IMU tilt in X (roll) and Y (pitch) dimensions (deg)

function [correctedIMU, IMUOri] = imuRemoveGravity(imu, fs, options)
    arguments 
        imu (:,6) double
        fs (1,1) double 
        options.compWeight (1,1) {mustBeNumeric} = 0.995
        options.compGerror (1,1) {mustBeNumeric} = 0.5
        options.RemoveOffset (1,1) {mustBeNumeric} = 0
        options.Showplots (1,1) {mustBeNumeric} = 0
        options.FilterCutoff (1,:) {mustBeNumeric} = 0
        options.FilterOrder (1,1) {mustBeNumeric} = 0
        options.FilterType (1,1) string = "low"
        options.ApplyCorrection (1,1) double = 0
    end
    accel = imu(:,1:3);
    gyro = imu(:,4:6);
    %define gravity vector
    g = [0 0 -9.80665002864];
    expectedG = zeros(size(accel));
    %Use complementary filter to estimate IMU pitch & roll orientation
    [IMUOri,R] = complementaryFilter(imu,fs, options.compWeight, "Showplots",options.Showplots,...
        "gravityError",options.compGerror,"RemoveOffset",options.RemoveOffset);
    
    %for each sample...
    for ii = 1:size(R,3)

        
        %apply to gravity vector to get expected gravity vector
        expectedG(ii,:) = g*R(:,:,ii);
    end
    
    accelNoGravity = accel - expectedG;
    
    if options.ApplyCorrection == 1
        accelCorrected = NaN(size(accel));
        gyroCorrected = NaN(size(gyro));
        for ii = 1:size(R,3)
            R1 = R(:,:,ii)';
            accelCorrected(ii,:) = accelNoGravity(ii,:)*R1;

            gyroCorrected(ii,:) = gyro(ii,:)*R1;
        end
        correctedIMU = [accelCorrected gyroCorrected];
    else
        correctedIMU = [accelNoGravity gyro];
    end

    if options.FilterCutoff > 0 && options.FilterOrder > 0
        [b,a] = butter(options.FilterOrder,options.FilterCutoff/(fs/2),options.FilterType);
        correctedIMU = filtfilt(b,a,correctedIMU);

    end
end