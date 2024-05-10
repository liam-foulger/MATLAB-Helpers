%File: FP8032.m
%Author: Liam Foulger
%Date Created: 2022-01-10
%Last Updated: 2022-12-16
%
% FP = FP8032(rawData,fs,cutoff)
%
%Function to convert raw (V) data from force plateform to calibrated forces
%(N) & moments (Nm) for AMTI OR6-7 "8032" (Note that the calibration matrix
%is specific for this device ONLY)
%Input:
% - raw data (1-3: Fx,Fy,Fz; 4-6: Mx,My,Mz; all in V). Must be as n x 6 matrix. 
% - sample rate (Hz) - optional: only needed if filtering
% - lowpass filter cutoff (Hz) - optional
%Output:
% - calibrated data (same order as input) in N or Nm. (n x 6)

function FP = FP8032(rawData,fs,cutoff)
    arguments
        rawData double
        fs (1,1) {mustBeNumeric} = 100
        cutoff (1,1) {mustBeNumeric} = 0
    end
      
    if cutoff > 0 
        cut=cutoff/(fs*0.5);
        [B,A]=butter(2,cut);
        Fx =  filtfilt(B,A,rawData(:,1));
        Fy =  filtfilt(B,A,rawData(:,2));
        Fz =  filtfilt(B,A,rawData(:,3));
        Mx =  filtfilt(B,A,rawData(:,4));
        My =  filtfilt(B,A,rawData(:,5));
        Mz =  filtfilt(B,A,rawData(:,6));
    else
        Fx =  rawData(:,1);
        Fy =  rawData(:,2);
        Fz =  rawData(:,3);
        Mx =  rawData(:,4);
        My =  rawData(:,5);
        Mz =  rawData(:,6);
    end

    SensitivityMatrix = ...
    [0.6665886 -0.0046187 -0.0015756 0.0041294 -0.0032712 0.006524745;...
    0.0037705 0.6672582 -0.000166 0.0024059 0.0050459 0.0210891;...
    0.0019082 0.00025399 0.17066389 0.00464854 -0.002901 0.0007858;...
    -0.0000982 -0.0002743 0.0017901 1.6812502 0.0088751 0.0049002;...
    0.000174 -0.0000512 -0.0000321 0.0027467 1.6720184 -0.0116545;...
    0.0001339 -0.0003784 -0.0006537 0.0043616 0.0106109 3.3295976];
    calib = inv(SensitivityMatrix); 

    V0 = 10; gain = 4000;

    %Matrix of uncalibrated data
    fxfinal = ((Fx*calib(1,1))+(Fy*calib(1,2))+(Fz*calib(1,3))+(Mx*calib(1,4))+(My*calib(1,5))+(Mz*calib(1,6)))./((.000001).*V0.*gain);
    fyfinal = ((Fx*calib(2,1))+(Fy*calib(2,2))+(Fz*calib(2,3))+(Mx*calib(2,4))+(My*calib(2,5))+(Mz*calib(2,6)))./((.000001).*V0.*gain);
    fzfinal = ((Fx*calib(3,1))+(Fy*calib(3,2))+(Fz*calib(3,3))+(Mx*calib(3,4))+(My*calib(3,5))+(Mz*calib(3,6)))./((.000001).*V0.*gain);
    mxfinal = ((Fx*calib(4,1))+(Fy*calib(4,2))+(Fz*calib(4,3))+(Mx*calib(4,4))+(My*calib(4,5))+(Mz*calib(4,6)))./((.000001).*V0.*gain);
    myfinal = ((Fx*calib(5,1))+(Fy*calib(5,2))+(Fz*calib(5,3))+(Mx*calib(5,4))+(My*calib(5,5))+(Mz*calib(5,6)))./((.000001).*V0.*gain);
    mzfinal = ((Fx*calib(6,1))+(Fy*calib(6,2))+(Fz*calib(6,3))+(Mx*calib(6,4))+(My*calib(6,5))+(Mz*calib(6,6)))./((.000001).*V0.*gain);

    %Offsets when no material covering forceplate (in meters)
    %From AMTI manual (yellow pages)
%     zoff = -1.629; yoff = -0.024; xoff = 0.017;
    zoff = -0.0413766; yoff = -0.0006096; xoff = 0.0004318;


    %Adjust moments to user coordinate system
    mxfinal = mxfinal-(fyfinal*zoff)-(fzfinal*yoff);
    myfinal = myfinal+(fxfinal*zoff)+(fzfinal*xoff);
    mzfinal = mzfinal-(fxfinal*yoff)-(fyfinal*xoff);

    FP = [fxfinal fyfinal fzfinal mxfinal myfinal mzfinal];
    
end