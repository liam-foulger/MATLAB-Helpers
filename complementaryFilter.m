%File: complementaryFilter.m
%Author: Liam Foulger
%Date created: 2020-10-30
%Last updated: 2022-07-21 
%
%[IMUPitch, IMURoll] = complementaryFilter(accel, gyro,fs, weight,NamePairArguments)
%
%Complementary filter that combines the accelerometer and gyro data as
%as seen in general formula:
%angle = (weight of gyro data)*(angle+gyrData*dt) + (1-weight)(accData)
%
%**assumes North(x)-East(y)-Down(z) Orientation of sensor data**
%
%input units:
% - accelerometer data (m/s^2)
% - gyro data (rad/s)
% - sensor sampling rate (Hz)
% - weight of gyroscope data for comp filter (optional; default is 0.995 since best results found with that,
%   but can be 0.95 to <1)
% - NamePairArguments (optional):
%    - 'RemoveOffset': 1 (true; default) or 0 (false). Remove the offset
%    from the gyroscope before angle estimation. Ideally the offset should
%    be removed (or determined to be removed post hoc) via a calibration 
%    procedure before the data collection. 
%    - 'Showplots': 1 (true) or 0 (false; default). True if you want to
%    show the plots of the results
%outputs:
% - tilt in degrees (Roll and pitch)

function [IMUPitch, IMURoll] = complementaryFilter(accel, gyro,fs, weight, NamePairArguments)

    arguments 
        accel double
        gyro double
        fs double 
        weight (1,1) {mustBeNumeric} = 0.995
        NamePairArguments.RemoveOffset (1,1) {mustBeNumeric} = 1
        NamePairArguments.Showplots (1,1) {mustBeNumeric} = 0
    end
   
    %get predicted angle from accelerometer only
    [pitchAccel, rollAccel] = getAccAngle(accel);
    
    %converts gyro to deg/s and removes offset (if selected)
    [pitchGyro,rollGyro] = convertGyro(gyro, NamePairArguments);
    
    %step-by-step complimentary filter 
    pitch = zeros(length(rollGyro),1);
    roll = zeros(length(rollGyro),1);
    pitch(1) = mean(pitchAccel(1:10));
    roll(1) = mean(rollAccel(1:10));
    for jj = 2:length(rollGyro)
        totalAccel = abs(accel(jj,1)) + abs(accel(jj,2)) + abs(accel(jj,3));
        if totalAccel > 4.9 && totalAccel < 19.6    %this checks if there is too much acceleration (so you would ignore the accelerometer estimate)
            pitch(jj) = (pitch(jj - 1) + pitchGyro(jj-1)/fs)*weight + pitchAccel(jj)*(1-weight);
            roll(jj) = (roll(jj - 1) + rollGyro(jj-1)/fs)*weight + rollAccel(jj)*(1-weight);
        else
            pitch(jj) = (pitch(jj - 1) + pitchGyro(jj-1)/fs);
            roll(jj) = (roll(jj - 1) + rollGyro(jj-1)/fs);
        end
    end
    
    %Plotting to visualize 
    if NamePairArguments.Showplots
        %calculate gyro only angle 
        gyro_anglePitch = zeros(length(gyro),1);
        gyro_angleRoll = zeros(length(gyro),1);
        for ii = 1:length(gyro)
            if ii == 1
                %starting at same point as accelerometer to account for initial IMU tilt
                gyro_anglePitch(ii) = mean(pitchAccel(1:10));
                gyro_angleRoll(ii) = mean(rollAccel(1:10));
            else
                gyro_anglePitch(ii) = gyro_anglePitch(ii-1) + pitchGyro(ii-1)/fs;
                gyro_angleRoll(ii) = gyro_angleRoll(ii-1) + rollGyro(ii-1)/fs;
            end
        end
        
        %plotting comparison
        figure
        subplot(2,1,1)
        plot(pitchAccel,'c')
        hold on
        plot(gyro_anglePitch,'r')
        plot(pitch,'k')
        legend('Accelerometer Estimation','Gyroscope Estimation','Complementary Filter')
        legend('boxoff')
        title('Pitch')
        ylabel('Degrees')
        box off
        subplot(2,1,2)
        plot(rollAccel,'c')
        hold on
        plot(gyro_angleRoll,'r')
        plot(roll,'k')
        title('Roll')
        box off
    end
    
    IMUPitch = pitch;
    IMURoll = roll;
end

function [pitchAccel, rollAccel] = getAccAngle(accel)
    %returns the angle of the gravity vector from the accelerometer data
    %(m/s^2)
    %assumes North(x)-East(y)-Down(z) Orientation of sensor data

    %pitch: forward: +
    pitch = atan2d(accel(:,1), -accel(:,3));
    %roll: right(east): +
    roll = atan2d(accel(:,2), -accel(:,3));

    pitchAccel = -pitch;
    rollAccel = -roll; 
end

function [pitchGyro,rollGyro] = convertGyro(gyro, options)
    %converts gyroscope data to deg/s and removes sensor bias 
    %assumes North(x)-East(y)-Down(z) Orientation of sensor data
    %input: gyroscope data (rad/s)
    %output: pitch (fwd: +) and roll (right: +) velocities (degrees/s),
    %with bias removed
    
    if options.RemoveOffset
        x_offset = mean(gyro(:,1));
        y_offset = mean(gyro(:,2));

        pitch = gyro(:,2) - y_offset;
        roll = gyro(:,1) - x_offset;
    else 
        pitch = gyro(:,2);
        roll = gyro(:,1);
    end
       
    %need to switch sign of y angular velocity to get foward pitch: + 
    pitchGyro = -pitch * 180/pi;
    rollGyro = roll  * 180/pi;

end
