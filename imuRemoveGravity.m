


function accelNoGravity = imuRemoveGravity(accel, gyro, fs, NamePairArguments)
    arguments 
        accel double
        gyro double
        fs double 
        NamePairArguments.compWeight (1,1) {mustBeNumeric} = 0.995
        NamePairArguments.RemoveOffset (1,1) {mustBeNumeric} = 0
        NamePairArguments.Showplots (1,1) {mustBeNumeric} = 0
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 2
        NamePairArguments.FilterType (1,1) string = "low"
    end
    %define gravity vector
    g = [0 0 -9.80665002864];
    expectedG = zeros(size(accel));
%       NamePairArguments.Showplots = 1;  
    %Use complementary filter to estimate IMU pitch & roll orientation
    [IMUPitch, IMURoll] = complementaryFilter(accel, gyro,fs, NamePairArguments.compWeight, 'Showplots',NamePairArguments.Showplots,'RemoveOffset',NamePairArguments.RemoveOffset);

    
    %for each sample...
    for ii = 1:length(IMUPitch)
        %define rotation matrix (assuming no yaw)
        R_x = [1 0 0; 0 cosd(IMURoll(ii)) -sind(IMURoll(ii));0 sind(IMURoll(ii)) cosd(IMURoll(ii))];
        R_y = [cosd(IMUPitch(ii)) 0 sind(IMUPitch(ii)); 0 1 0; -sind(IMUPitch(ii)) 0 cosd(IMUPitch(ii))];
        R_z = [cosd(0) -sind(0) 0; sind(0) cosd(0) 0; 0 0 1];
        R = R_x*R_y*R_z;
        
        %apply to gravity vector to get 
        expectedG(ii,:) = g*R;
    end
    
    accelNoGravity = accel - expectedG;
    
end