%File: complementaryFilter.m
%Author: Liam Foulger
%Date created: 2020-10-30
%Last updated: 2024-01-11
%
% [IMUOri,R] = complementaryFilter(imu,fs, weight, NamePairArguments)
%
%Complementary filter that combines the accelerometer and gyro data as
%as seen in general formula:
%angle = (weight of gyro data)*(angle+gyrData*dt) + (1-weight)(accData)
%
%**assumes North/Forward(x)-East/Right(y)-Down(z) Orientation of sensor data**
%
% Inputs:
% - IMU data (m/s^2) (n x 6): XYZ accelerometer (m/s^2) and XYZ gyro
% (deg/s)
% - sensor sampling rate (Hz) (1)
% - weight of gyroscope data for comp filter (optional; default is 0.995 since best results found with that,
%   but can be 0.95 to <1) (1)
% - NamePairArguments (optional):
%    - 'RemoveOffset': 1 (true) or 0 (false; default). Remove the offset
%    from the gyroscope before angle estimation. Ideally the offset should
%    be removed (or determined to be removed post hoc) via a calibration 
%    procedure before the data collection. 
%    - 'Showplots': 1 (true) or 0 (false; default). True if you want to
%    show the plots of the results
%    - 'FilterCutoff': Cutoff for optional butterworth filter (Hz). Default is 0 (no filter
%    applied).
%    - 'FilterOrder': Order for optional butterworth filter. Default is 2.
%    - 'FilterType':  Filter type for optional butterworth filter. Options
%    are: 'low' (default), 'high','stop', or 'bandpass'
%    - 'gravityError': how much error is allowed in the accelerometer
%    measurement before it is ignored from angle estimation. 
%           0.5 = +/-50% error allowed (default)
%           Based on some casual testing, an error of 0.05-0.1 is ideal for
%           IMUs that have been properly calibrated during faster movements
%           (If the error value is too small, the accelerometer may be
%           completely ignored if not calibrated correctly)
%           Note that if you are decreasing the error value, my intuition
%           suggests that you also decrease the weighting factor (lowest to
%           about 0.98), since otherwise the accelerometer will be ignored
%           more often (due to lower errror value) and have less influence
%           (due to weighting factor)
%    - "returnType": how you would like the data to be returned: as either
%    Euler angles ("Euler") (degrees: (n x 2) in X (roll) and Y (pitch) dimensions
%    (deg)) or rotation matrix ("rotMat") (3x3xn)
% Outputs:
% - IMU tilt in either Euler angles (default; roll/X and pitch/Y) and rotation matrix (R)
%
% Reference:
% - P. Gui, L. Tang, S. Mukhopadhyay, MEMS based IMU for tilting measurement: 
% Comparison of complementary and kalman filter based data fusion, 
% in: 2015 IEEE 10th Conference on Industrial Electronics and Applications (ICIEA), 
% 2015: pp. 2004–2009. https://doi.org/10.1109/ICIEA.2015.7334442.

function [IMUOri,R] = complementaryFilter(imu,fs, weight, NamePairArguments)

    arguments 
        imu (:,6) double
        fs (1,1) double 
        weight (1,1) {mustBeNumeric} = 0.995
        NamePairArguments.RemoveOffset (1,1) {mustBeNumeric} = 0
        NamePairArguments.Showplots (1,1) {mustBeNumeric} = 0
        NamePairArguments.FilterCutoff (1,:) {mustBeNumeric} = 0
        NamePairArguments.FilterOrder (1,1) {mustBeNumeric} = 4
        NamePairArguments.FilterType (1,1) string = "low"
        NamePairArguments.gravityError (1,1) {mustBeNumeric} = 0.5
    end
    accel = imu(:,1:3);
    gyro = imu(:,4:6);

    %get predicted angle from accelerometer only
    [pitchAccel, rollAccel] = getAccAngle(accel);
    
    %remove gyro offset (if selected) 
    if NamePairArguments.RemoveOffset
        gyro = gyro-mean(gyro,'omitnan');
    end
    
    %set up pitch and roll arrays
    pitch = zeros(length(pitchAccel),1);
    roll = zeros(length(pitchAccel),1);

    % first sample orientation is based on the average orientation of the first 10
    % samples - based on the accelerometer estimate
    pitch(1) = mean(pitchAccel(1:10));
    roll(1) = mean(rollAccel(1:10));

    gError = NamePairArguments.gravityError;    %accepted gravity error 
    % (i.e., how far away from 9.81 can net linear acceleration be for us to still use the accel data) 

    g = 9.80665002864;  % gravity constant

    % set up rotation matrix
    R = NaN(3,3,length(pitchAccel));

    %step-by-step complimentary filter (starting from 2nd sample)
    for jj = 2:length(pitchAccel)
        % calculate net acceleration (to determine if it is within
        % acceptable range to use accel data)
        netAccel = sqrt(accel(jj,1)^2 + accel(jj,2)^2 +accel(jj,3)^2);

        % calculate rotation matrix of previous orientation (to correct
        % gyro data) - assumes no yaw
        R_x = [1 0 0; 0 cosd(roll(jj-1)) -sind(roll(jj-1));0 sind(roll(jj-1)) cosd(roll(jj-1))];
        R_y = [cosd(pitch(jj-1)) 0 sind(pitch(jj-1)); 0 1 0; -sind(pitch(jj-1)) 0 cosd(pitch(jj-1))];
        R(:,:,jj-1) = (R_x*R_y);
     
        %rotate gyroscope data
        gyro(jj,:) = gyro(jj,:)*R(:,:,jj-1);

        if (netAccel > (g - g*gError) && netAccel < (g + g*gError)) && ~isnan(pitchAccel(jj)) && ~sum(isnan(pitch(jj-1,:)))
            %this checks if there is too much acceleration (so you would
            %ignore the accelerometer estimate), and that both accel and
            %gyro measures are not NaNs
            pitch(jj) = (pitch(jj-1) + gyro(jj,2)/fs)*weight + pitchAccel(jj)*(1-weight);
            roll(jj) = (roll(jj-1) + gyro(jj,1)/fs)*weight + rollAccel(jj)*(1-weight);
        elseif ~sum(isnan(pitch(jj-1,:)))
            pitch(jj) = (pitch(jj-1) + gyro(jj,2)/fs);
            roll(jj) = (roll(jj-1) + gyro(jj,1)/fs);
        else
            pitch(jj) = pitch(jj-1);
            roll(jj) = roll(jj-1);
        end
    end

    %Plotting to visualize (if requested)
    if NamePairArguments.Showplots
        %calculate gyro only angle 
        gyro_anglePitch = zeros(length(gyro),1);
        gyro_angleRoll = zeros(length(gyro),1);
        for ii = 1:length(gyro)
            if ii == 1
                %starting at same point as accelerometer to account for initial IMU tilt
                gyro_anglePitch(ii) = mean(pitchAccel(1:10));
                gyro_angleRoll(ii) = mean(rollAccel(1:10));
            elseif ~sum(isnan(pitch(jj-1,:)))
                gyro_anglePitch(ii) = gyro_anglePitch(ii-1) + gyro(ii,2)/fs;
                gyro_angleRoll(ii) = gyro_angleRoll(ii-1) + gyro(ii,1)/fs;
            else
                gyro_anglePitch(ii) = gyro_anglePitch(ii-1);
                gyro_angleRoll(ii) = gyro_angleRoll(ii-1);
            end
        end
        
        t = (1/fs):(1/fs):(ii*(1/fs));  %create time array
        %plotting comparison
        figure
        subplot(2,1,1)
        plot(t,pitchAccel,'c')
        hold on
        plot(t,gyro_anglePitch,'r')
        plot(t,pitch,'k')
        legend('Accelerometer Estimation','Gyroscope Estimation','Complementary Filter')
        legend('boxoff')
        title('Pitch')
        ylabel('Degrees')
        xlabel('Time (s)')
        box off
        subplot(2,1,2)
        plot(t,rollAccel,'c')
        hold on
        plot(t,gyro_angleRoll,'r')
        plot(t,roll,'k')
        title('Roll')
        xlabel('Time (s)')
        box off
    end
    
    %apply filter if selected
    if NamePairArguments.FilterCutoff > 0
        [b,a] = butter(NamePairArguments.FilterOrder, NamePairArguments.FilterCutoff./(fs/2),NamePairArguments.FilterType);
        IMUPitch = filtfilt(b,a,pitch);
        IMURoll = filtfilt(b,a,roll);
    else
        IMUPitch = pitch;
        IMURoll = roll;
    end

    IMUOri = [IMURoll IMUPitch];
    %calculate rotation matrix of final sample 
    R_x = [1 0 0; 0 cosd(roll(jj)) -sind(roll(jj));0 sind(roll(jj)) cosd(roll(jj))];
    R_y = [cosd(pitch(jj)) 0 sind(pitch(jj)); 0 1 0; -sind(pitch(jj)) 0 cosd(pitch(jj))];
    R(:,:,jj) = (R_x*R_y);
end

function [pitchAccel, rollAccel] = getAccAngle(accel)
    %returns the angle of the gravity vector from the accelerometer data
    %(m/s^2)
    %assumes North(x)-East(y)-Down(z) Orientation of sensor data

    %pitch: forward: -
    pitchAccel = atan2d(accel(:,1), -accel(:,3));
    
    %roll: right(east): +
    % since the order of rotations is pitch followed by roll, the roll
    % calculation must take this into account 
    % for more info: https://mwrona.com/posts/accel-roll-pitch/
    rollAccel = -atan2d(accel(:,2), sqrt(accel(:,3).^2 + accel(:,1).^2));
end


