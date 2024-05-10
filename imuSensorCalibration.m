% File: imuSensorCalibration.m
% Author: Liam Foulger
% Date Created: 2023-08-08
% Last Updated: 2023-08-10
%
% [R, accOff, gyrOff] = imuSensorCalibration(data)
%
% Function to calculate an IMUs sensor calibration to correct for any
% non-orthagonality in the axes and to remove any accelerometer and
% gyroscope offsets/bias.
%
% Based on LabVIEW code from Dr. Jesse M Charlton.
%
% Inputs: 
% - data: struct with the XYZ accel and gyro data OR means from the
% different calibration positions. Each field should be n x 6. Should
% contain the following fields: "Xup", "Xdown", "Yup", "Ydown", "Zup", &
% "Zdown"
% Outputs:
% - R = 3x3 rotation matrix
% - accOff = acceleration offsets (1 x 3)
% - gyroscope offsets (1 x 3)


function [R, accOff, gyrOff] = imuSensorCalibration(data)
    % set up gravity and idealized orientation matrix
    g = 9.80665002864;
    idealOri = [1 0 0;-1 0 0;0 1 0;0 -1 0;0 0 1;0 0 -1].*g;

    % get means from the data 
    allMean = [mean(data.Xup,1);mean(data.Xdown,1);mean(data.Yup,1);...
        mean(data.Ydown,1);mean(data.Zup,1);mean(data.Zdown,1)];

    accMeans = [allMean(:,1:3) ones([6 1])];
    
    % get the calibration matrix + offsets
    calibMat = ((accMeans'*accMeans)^(-1)*(accMeans'))*idealOri;

    % split into R, accel offset, and gyro offset
    R = calibMat(1:3,:);
    accOff = calibMat(4,:);
    gyrOff = mean(allMean(:,4:6),1)*R;
end

