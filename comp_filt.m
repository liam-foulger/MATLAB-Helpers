%File: comp_filt.m
%Author: Liam Foulger
%Date created: 2020-10-30
%Last updated: 2022-06-09 
%
%Complementary filter that combines the accelerometer and gyro data as
%as seen in general formula:
%angle = (weight of gyro data)*(angle+gyrData*dt) + (1-weight)(accData)
%input units:
% - accelerometer data (m/s^2)
% - gyro data (rad/s)
% - sensor sampling rate (Hz)
% - weight of gyroscope data for comp filter (recommended 0.98, but found best results @ d = 0.995)
%assumes North(x)-East(y)-Down(z) Orientation of sensor data
%output: tilt in degrees (Roll and pitch)
function [IMUPitch, IMURoll] = comp_filt(accel, gyro,fs, weight)
   
    
    
    [pitchAccel, rollAccel] = get_acc_angle(accel,fs);
    [pitchGyro,rollGyro] = getGyro_angle(gyro, fs);
    
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
    
    pitch = zeros(length(rollGyro),1);
    roll = zeros(length(rollGyro),1);
    
    pitch(1) = mean(pitchAccel(1:10));
    roll(1) = mean(rollAccel(1:10));
    for jj = 2:length(rollGyro)
        totalAccel = abs(accel(jj,1)) + abs(accel(jj,2)) + abs(accel(jj,3));
        if totalAccel > 4.9 && totalAccel < 19.6
            pitch(jj) = (pitch(jj - 1) + pitchGyro(jj-1)/fs)*weight + pitchAccel(jj)*(1-weight);
            roll(jj) = (roll(jj - 1) + rollGyro(jj-1)/fs)*weight + rollAccel(jj)*(1-weight);
        else
            pitch(jj) = (pitch(jj - 1) + pitchGyro(jj-1)/fs);
            roll(jj) = (roll(jj - 1) + rollGyro(jj-1)/fs);
        end
    end
    
    %final orientations:
    %Roll: right(+)
    %Pitch: forward(+)
%         figure
%         subplot(2,1,1)
%         plot(pitchAccel,'c')
%         hold on
%         
%         plot(gyro_anglePitch,'r')
%         plot(pitch,'k')
%         legend('Accelerometer Estimation','Gyroscope Estimation','Complementary Filter')
%         title('Pitch')
%         ylabel('Degrees')
%        
%         subplot(2,1,2)
%         plot(rollAccel,'c')
%         hold on
%         plot(gyro_angleRoll,'r')
%         plot(roll,'k')
%         legend('Accelerometer Estimation','Gyroscope Estimation','Complementary Filter')
%         title('Roll')

    
    IMUPitch = pitch;
    IMURoll = roll;
end

function [pitchAccel, rollAccel] = get_acc_angle(accel,fs)
    %returns the angle of the gravity vector from the accelerometer data
    %(m/s^2), lowpassed at 2Hz
    %assumes North(x)-East(y)-Down(z) Orientation of sensor data

    %pitch: forward: +
    pitch = atan2d(accel(:,1), -accel(:,3));
    %roll: right(east): +
    roll = atan2d(accel(:,2), -accel(:,3));
    
    %lowpass filter
    cutoff = 2;    %cutoff frequency 
    [b,a] = butter(2 , cutoff./(fs/2));
%     pitch_filt = filtfilt(b,a,pitch);
%     roll_filt = filtfilt(b,a,roll);
    pitch_filt = pitch;
    roll_filt = roll;
%     figure
%     subplot(2,1,1)
%     plot(pitch)
%     hold on
%     plot(pitch_filt)
%     legend('Raw','Filtered')
%     title('Pitch Angle')
%     subplot(2,1,2)
%     plot(roll)
%     hold on
%     plot(roll_filt)
%     title('Roll angle')

    pitchAccel = -pitch_filt;
    rollAccel = -roll_filt; 
end

function [pitchGyro,rollGyro] = getGyro_angle(gyro, ~)
    %calculates the angular position from the gyroscope data 
    %assumes North(x)-East(y)-Down(z) Orientation of sensor data
    %input: gyroscope data (rad/s) and sensor sampling rate (Hz)
    %output: pitch (fwd: +) and roll (right: +) velocities (degrees/s),
    %with bias removed
    

    x_offset = mean(gyro(:,1));
    y_offset = mean(gyro(:,2));
%     z_offset = mean(gyro(:,3)); %unused
    
%     

    pitch = gyro(:,2) - y_offset;
    roll = gyro(:,1) - x_offset;
       
    %need to switch sign of y angular velocity to get foward pitch: + 
    pitchGyro = -pitch * 180/pi;
    rollGyro = roll  * 180/pi;

end
