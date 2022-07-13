%File: calibrateIMU.m
%Author: Liam Foulger
%Date Created: 2022-06-01
%Last Updated: 2022-06-30
%
%IMUcalibrated = calibrateIMU(IMUuc, R, offset,fs,cutoff)
%
%Function to remove the gyroscope offsets apply a calibration rotation
%matrix to IMU data
%
%Inputs:
%-IMUuc: uncalibrated IMU data (n x 6), XYZ acceleration and XYZ gyroscope
%-R: 3x3 rotation calibration matrix
%-offset: gyroscope offset (1x3).
%Outputs: 
%-IMUcalibrated: calibrated IMU data (n x 6)

function IMUcalibrated = calibrateIMU(IMUuc, R, offset,fs,cutoff)

    cut=cutoff/(fs*0.5);
    [b,a]=butter(4,cut);
    IMUuc = filtfilt(b,a,IMUuc);
    
    IMUuc(:,4:6) = IMUuc(:,4:6) - offset;

    IMUcalibrated = [R(1,1).*IMUuc(:,1) + R(2,1).*IMUuc(:,2) + R(3,1).*IMUuc(:,3)...
        R(1,2).*IMUuc(:,1) + R(2,2).*IMUuc(:,2) + R(3,2).*IMUuc(:,3)...
        R(1,3).*IMUuc(:,1) + R(2,3).*IMUuc(:,2) + R(3,3).*IMUuc(:,3)...
        R(1,1).*IMUuc(:,4) + R(2,1).*IMUuc(:,5) + R(3,1).*IMUuc(:,6)...
        R(1,2).*IMUuc(:,4) + R(2,2).*IMUuc(:,5) + R(3,2).*IMUuc(:,6)...
        R(1,3).*IMUuc(:,4) + R(2,3).*IMUuc(:,5) + R(3,3).*IMUuc(:,6)];


end