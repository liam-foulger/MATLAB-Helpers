%File: calibrateIMU.m
%Author: Liam Foulger
%Date Created: 2022-06-01
%Last Updated: 2022-12-01
%
%IMUcalibrated = calibrateIMU(IMUuc, R, accOffset, gyrOffset,fs,cutoff,NamePairArguments)
%
%Function to remove the gyroscope offsets apply a calibration rotation
%matrix to IMU data
%
%Inputs:
%-IMUuc: uncalibrated IMU data (n x 6), XYZ acceleration and XYZ gyroscope
%-R: 3x3 rotation calibration matrix
%-accOffset: accelerometer offset (1x3).
%-gyrOffset: gyroscope offset (1x3).
%Outputs: 
%-IMUcalibrated: calibrated IMU data (n x 6)

function IMUcalibrated = calibrateIMU(IMUuc, R, accOffset, gyrOffset,fs,cutoff,NamePairArguments)

    arguments
        IMUuc double
        R double
        accOffset (1,3) {mustBeNumeric} = [0 0 0]
        gyrOffset (1,3) {mustBeNumeric} = [0 0 0]
        fs (1,1) {mustBeNumeric} = 0
        cutoff (1,1) {mustBeNumeric} = 0
        NamePairArguments.offsetOrder{mustBeMember(NamePairArguments.offsetOrder,['before','after','none'])} = 'before'
    end
    
    if cutoff > 0
        cut=cutoff/(fs*0.5);
        [b,a]=butter(4,cut);
        IMUuc = filtfilt(b,a,IMUuc);
    end
    
    if strcmp(NamePairArguments.offsetOrder,'before')
        IMUuc(:,1:3) = IMUuc(:,1:3) + accOffset;
        IMUuc(:,4:6) = IMUuc(:,4:6) - gyrOffset;
    end
    
    IMUcalibrated = [R(1,1).*IMUuc(:,1) + R(2,1).*IMUuc(:,2) + R(3,1).*IMUuc(:,3)...
        R(1,2).*IMUuc(:,1) + R(2,2).*IMUuc(:,2) + R(3,2).*IMUuc(:,3)...
        R(1,3).*IMUuc(:,1) + R(2,3).*IMUuc(:,2) + R(3,3).*IMUuc(:,3)...
        R(1,1).*IMUuc(:,4) + R(2,1).*IMUuc(:,5) + R(3,1).*IMUuc(:,6)...
        R(1,2).*IMUuc(:,4) + R(2,2).*IMUuc(:,5) + R(3,2).*IMUuc(:,6)...
        R(1,3).*IMUuc(:,4) + R(2,3).*IMUuc(:,5) + R(3,3).*IMUuc(:,6)];
    
    if strcmp(NamePairArguments.offsetOrder,'after')
        IMUcalibrated(:,1:3) = IMUcalibrated(:,1:3) + accOffset;
        IMUcalibrated(:,4:6) = IMUcalibrated(:,4:6) - gyrOffset;
    end

end