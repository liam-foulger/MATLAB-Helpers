%File: createCalibration.m
%Author: Liam Foulger 
%Date Created: 20-07-2022
%Last Updated: 18-10-2022
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
% - Ori1: Accelerometer XYZ (1x3) in pose 1  *check array dimensions
% - Ori2: Accelerometer XYZ (1x3) in pose 2
% Output:
% - R: 3x3 calibration matrix
%
% Adapted from previous Mathscript (LabVIEW) code from Anthony Chen.

function R = createCalibration(ori1,ori2)
    %normalize vectors
    ori1_norm = ori1/sqrt(sum(ori1.^2)); 
    ori2_norm = ori2/sqrt(sum(ori2.^2)); 
    %get Y axis from cross product of estimated X and true Z axis
    new_third_axis = cross(ori1_norm, ori2_norm); 
    new_third_axis = new_third_axis ./ norm(new_third_axis); 
    %get true X axis from computed Y and true Z axis
    new_second_axis = cross(    ori1_norm,new_third_axis );
    new_second_axis = new_second_axis ./ norm(new_second_axis); 
    %create matrix
    R = real([ new_second_axis', new_third_axis', -ori1_norm' ] );

end