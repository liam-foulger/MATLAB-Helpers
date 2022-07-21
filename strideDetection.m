%File: strideDetection.m
%Author: Liam Foulger
%Date Created: 2022-05-28
%Last Updated: 2022-07-20
%
%strideIDXs = strideDetection(rightIMU, leftIMU, fs,options)
%
%Function to detect strides from foot/ankle mounted IMUs on each
%ankle/foot. Returns the step indices for each foot contact. Uses 
%footStepDetection.m to determine the foot contact indexes
%Inputs:
% - right IMU data (XYZ accel & XYZ gyro (deg/s); assumes X:forward, Y: right, Z:
% down) (n x 6)
% - left IMU data (n x 6)
% - sample rate (Hz)
% - NamePair arugments:
%    - 'Method': 'zero' (default) or 'peak' 
%    - 'Showplots': 1 (true) or 0 (false, default). If you want to show the plots
%    - 'MinPeakHeight'. Min height of peak angular velocity. Default is
%    50. For findpeaks function.
%    - 'MinPeakProminence'. Min peak prominence of angular velocity. Default is
%    100. For findpeaks function.
%Outputs: 
% - stride indices (3 x n). 
%     - for each column: r1: R foot contact. r2: L foot contact. r3: before
%     next foot contact (ie. end of stride cycle).
%
%Dependencies:
% - footStepDetection.m
% - removeDoubleSteps.m
% - getZeroCrossings.m

function strideIDXs = strideDetection(rightIMU, leftIMU, fs,options)
    arguments
        rightIMU double
        leftIMU double
        fs double
        options.Method (1,1) string = 'zero'
        options.Showplots (1,1) {mustBeNumeric} = 0
        options.MinPeakHeight (1,1) {mustBeNumeric} = 50
        options.MinPeakProminence (1,1) {mustBeNumeric} = 100
    end
    
    %for each IMU, find the steps
    [rightSteps,leftSteps] = footStepDetection(rightIMU, leftIMU, fs,'Method',options.Method,...
        'Showplots',options.Showplots,'MinPeakHeight',options.MinPeakHeight,...
        'MinPeakProminence',options.MinPeakProminence);
   


    %plotting
    if options.Showplots
        numSteps = min([length(rightSteps) length(leftSteps)]);
        figure
        plot(rightSteps(1:numSteps).*1/fs,(leftSteps(1:numSteps) - rightSteps(1:numSteps))/fs);
        xlabel('Time (s)')
        ylabel('Step Duration (s)')
        box off
    end
    
    %reorganize to give output that is nicely sorted
    numStrides = min([length(rightSteps)-1 length(leftSteps)]);
    strideIDXs = [rightSteps(1:numStrides)';leftSteps(1:numStrides)'; (rightSteps(2:numStrides+1)' - 1)];
end

