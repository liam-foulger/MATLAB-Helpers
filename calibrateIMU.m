%File: calibrateIMU.m
%Author: Liam Foulger
%Date Created: 2022-06-01
%Last Updated: 2022-06-30
%
%Function to remove the gyroscope offsets apply a calibration rotation
%matrix to IMU data
%Inputs:
%-IMUuc: uncalibrated IMU data (n x 6), XYZ acceleration and XYZ gyroscope
%-R: 3x3 rotation calibration matrix
%-offset: gyroscope offset (1x3).
%Outputs: 
%-IMUcalibrated: calibrated IMU data (n x 6)

function IMUcalibrated = calibrateIMU(IMUuc, R, offset)
    R1 = R;
    IMU1uc = IMUuc;
    IMU1uc(:,4:6) = IMUuc(:,4:6) - offset;

    IMUcalibrated = [R1(1,1).*IMU1uc(:,1) + R1(2,1).*IMU1uc(:,2) + R1(3,1).*IMU1uc(:,3)...
        R1(1,2).*IMU1uc(:,1) + R1(2,2).*IMU1uc(:,2) + R1(3,2).*IMU1uc(:,3)...
        R1(1,3).*IMU1uc(:,1) + R1(2,3).*IMU1uc(:,2) + R1(3,3).*IMU1uc(:,3)...
        R1(1,1).*IMU1uc(:,4) + R1(2,1).*IMU1uc(:,5) + R1(3,1).*IMU1uc(:,6)...
        R1(1,2).*IMU1uc(:,4) + R1(2,2).*IMU1uc(:,5) + R1(3,2).*IMU1uc(:,6)...
        R1(1,3).*IMU1uc(:,4) + R1(2,3).*IMU1uc(:,5) + R1(3,3).*IMU1uc(:,6)];


end