% File: transformIMUacc.m
% Author: Liam Foulger
% Date Created: 2023-08-22
% Last Updated: 2023-09-09
%
% IMU = headIMUaccTX(IMU,r,fs)
%
% Function to transform the accelerations detected from a mouthguard IMU to
% the approximate location of the vestibular system. Note that these
% distances should be measured from when the participant is in the pose 1
% (Z down) calibration position.
%
% Inputs:
%   - IMU (n x 6): the IMU measurements with the gravity correction applied
%   (but NOT rotated to the global reference frame). Must have the
%   following participant coordinate reference frame: X - forward, Y -
%   right, Z - down. Data format: XYZ linear accceleration (m/s^2) and XYZ
%   angular velocity (deg/s).
%   - r (1 x 3): Position vector between actual IMU location and desired
%   IMU location. [x y z] (Desired - actual)
%   - fs (1 x 1): The sampling rate (Hz)
% Output:
%   - IMU (n x 6): The IMU measurements that have been corrected to remove
%   the rotational accelerations. Same format as input data. 
%
% Has been tested and seems to work pretty well 
%
% Reference:
% - Blouin, J.-S., Siegmund, G. P., & Timothy Inglis, J. (2007). 
% Interaction between acoustic startle and habituated neck postural 
% responses in seated subjects. Journal of Applied Physiology, 
% 102(4), 1574–1586. https://doi.org/10.1152/japplphysiol.00703.2006


function IMU = transformIMUacc(IMU,r,fs)
    arguments
        IMU (:,6) double 
        r (1,3) double
        fs (1,1) double
    end

    a  = [0 0 0;diff(deg2rad(IMU(:,4:6)))*fs];
    w = deg2rad(IMU(:,4:6));
    r = repmat(r,[length(a) 1]);
    
    
    IMU(:,1:3) = IMU(:,1:3) + cross(a,r) + cross(w,cross(w,r));

end