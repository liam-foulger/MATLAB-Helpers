%File: optotrakOrientation.m
%Author: Liam Foulger
%Date Created: 2022-08-30
%Last Updated: 2022-08-30
%
% optoAngles = optotrakOrientation(marker1,marker2,marker3)
%
% Function to return the orientation of a 3 marker optotrak rigid body.
% Assumes the markers are oriented in a triangle with marker 1 on the top,
% marker 2 on the bottom left, and marker 3 on the bottom right. 
%
%Inputs:
% - markers: nx3 matrix (where n is number of data points)
% - NamePairArguments (optional)
%    - 'fs': sample rate of data (Hz). Must be included for filtering.
%    - 'FilterCutoff': Cutoff for optional butterworth filter (Hz). Default is 0 (no filter
%    applied).
%    - 'FilterOrder': Order for optional butterworth filter. Default is 2.
%    - 'FilterType':  Filter type for optional butterworth filter. Options
%    are: 'low' (default), 'high','stop', or 'bandpass'
%
%Outputs:
% - optotrak orientation:
%     - Col 1: Roll
%     - Col 2: Pitch
%     - Col 3: Yaw

%Requires:
% - SpaceLib Library
function optoAngles = optotrakOrientation(marker1,marker2,marker3,NamePairArguments)

    arguments
        marker1 double
        marker2 double
        marker3 double
        NamePairArguments.fs (1,1) {mustBeNumeric} = 0
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 2
        NamePairArguments.FilterType (1,1) string = "low"
    end
    %load spacelib library
    addpath("SpaceLib Functions")
    run('spacelib.m')
    
    body = zeros(3,3,length(marker1));
    optoAngles = zeros(length(marker1),3);
    for ii = 1:length(marker1)
        %create rotation matrix of frame defined from the 3 markers 
        body(:,:,ii) = framep(marker3(ii,:), marker2(ii,:), marker1(ii,:),Y,Z);
        %convert rotation matrix to Euler angles with raw, pitch, then roll
        %rotations
        optoAngles(ii,:) = rtocarda(body(:,:,ii),Z,Y,X);
    end
    %unwrap & convert to degress
    optoAngles = rad2deg(unwrap(optoAngles));
    %reorganize 
    optoAngles = [-optoAngles(:,3) optoAngles(:,2) optoAngles(:,1)];
    
    if NamePairArguments.FilterCutoff > 0
        if NamePairArguments.fs == 0
            error('Must input sample rate for filtering!')
            
        end
        [b,a] = butter(NamePairArguments.FilterOrder, NamePairArguments.FilterCutoff./(NamePairArguments.fs/2),NamePairArguments.FilterType);
        optoAngles = filtfilt(b,a,optoAngles);
    end
end

