%File: createCalibration.m
%Author: Liam Foulger 
%Date Created: 2022-07-20
%Last Updated: 2022-12-13
%
% Function to create a 3x3 calibration matrix for an IMU based on 2 static
% poses.
% Pose 1: Desired Z axis is perpendicular to the ground (parallel to
% gravity), (+)ve direction is pointing downwards
% Pose 2: Desired X axis is (approximately) perpendicular to the ground,
% with the desired (+)ve direction pointing downwards
%
% Units can be in m/s^2 or g's, since it is normalized either way
% 
% Inputs: 
% - Ori1: Mean accelerometer XYZ (1x3) in pose 1 
% - Ori2: Mean accelerometer XYZ (1x3) in pose 2
% Output:
% - R: 3x3 calibration matrix
%
% Adapted from previous Mathscript (LabVIEW) code from Anthony Chen.

function R = createCalibration(ori1,ori2)
    %normalize vectors
    ori1_norm = ori1/sqrt(sum(ori1.^2)); %true Z axis (flipped)
    ori2_norm = ori2/sqrt(sum(ori2.^2)); %estimated X axis
    %get true Z axis as negative (pointing down) of orientation 1
    true_Z_axis = -ori1_norm;
    %get true Y axis from cross product of estimated X and true Z axis
    true_Y_axis = cross(ori2_norm,true_Z_axis); 
    true_Y_axis = true_Y_axis ./ norm(true_Y_axis); 
    %get true X axis from computed Y and true Z axis
    true_X_axis = cross(true_Y_axis,true_Z_axis);
    true_X_axis = true_X_axis ./ norm(true_X_axis); 
    
    %create matrix
    R = real([ true_X_axis', true_Y_axis', true_Z_axis' ] );

end