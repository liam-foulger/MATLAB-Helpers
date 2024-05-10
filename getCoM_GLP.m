%File: getCoM_GLP.m
%Author: Liam Foulger
%Date Created: 2023-05-25
%Last Updated: 2023-09-03
%
% CoM = getCoM_GLP(forcePlate,fs,mass)
% 
% Function to estimate the centre of mass displacement using the force
% platform data and the horizontal position of the gravity line (GLP) 
% as previously described in Zatsiorsky & King (1997) and Lafond et al.
% (2004).
% 
% Code adapted from previous work from Calvin Qiao.
%
% Inputs:
% - forcePlate: force platform data (n x 6) in the following format: 
%       - XYZ force (N) and XYZ moment (Nm). The outputs assume the axis
%       are oriented as:
%           - X: forward
%           - Y: right
%           - Z: down
% - fs: sampling rate of the data (Hz)
% - namePairArugments:
%       - filterCutoff (Hz): default = 10Hz
%       - filterOrder: default = 4
% Output:
% - CoM: centre of mass displacement (m; n x 2) in AP (first column) and ML
% (second column) directions
%
% References:
% Lafond, D., Duarte, M., & Prince, F. (2004). 
% Comparison of three methods to estimate the center of mass during balance assessment. 
% Journal of Biomechanics, 37, 1421–1426. https://doi.org/10.1016/S0021-9290(03)00251-3
% Zatsiorsky, V. M., & King, D. L. (1997). 
% An algorithm for determining gravity line location from posturographic recordings. 
% Journal of Biomechanics, 31(2), 161–164. https://doi.org/10.1016/S0021-9290(97)00116-4

function CoM = getCoM_GLP(forcePlate,fs,options)
    
    arguments
        forcePlate (:,6) double
        fs (1,1) double 
        options.filterCutoff (1,1) double = 10
        options.filterOrder (1,1) double = 4
    end

    %remove means from AP and ML forces
    forcePlate(:,1:2) = forcePlate(:,1:2) - mean(forcePlate(:,1:2),1);

    %calculate participant mass in kg
    g = 9.80665002864;
    mass = mean(forcePlate(:,3))/g;

    %filter force plate data
    if options.filterCutoff <= 0 || options.filterOrder <= 0
        error("Filter Order and/or Cutoff inputted are not valid (data must be filtered)")
    end

    [b,a] = butter(options.filterOrder , options.filterCutoff./(fs/2));
    forcePlate = filtfilt(b,a,forcePlate);
    
    %calculate CoP 
    CoP(:,1) = -forcePlate(:,5)./forcePlate(:,3);
    CoP(:,1) = CoP(:,1) - mean(CoP(:,1));
    CoP(:,2) = forcePlate(:,4)./forcePlate(:,3);
    CoP(:,2) = CoP(:,2) - mean(CoP(:,2));
    
    
    %get CoM displacement and filter
    %AP CoM
    CoM(:,1) = filtfilt(b,a,doubleIntegrator(CoP(:,1), -forcePlate(:,1), mass, 1/fs));
    %ML CoM
    CoM(:,2) = filtfilt(b,a,doubleIntegrator(CoP(:,2), -forcePlate(:,2), mass, 1/fs));

end

function CoM_estimate = doubleIntegrator(CoPx, Fx, mass, dt)

    %find zero crossings of horizontal force to split up data 
    getZeroCrossings = @(var) find(var(:).*circshift(var(:), [-1, 0]) <= 0);
    zeroCrosses = getZeroCrossings(Fx);

    CoPSegs = cell(length(zeroCrosses)+1,1); 
    FxSegs= cell(length(zeroCrosses)+1,1); 
    for iSegment = 1:length(zeroCrosses)+1
        if iSegment == length(zeroCrosses)+1
            CoPSegs{iSegment} = CoPx(zeroCrosses(iSegment-1)+1: end);
            FxSegs{iSegment} =Fx(zeroCrosses(iSegment-1)+1: end);
        elseif iSegment == 1
            CoPSegs{iSegment} = CoPx(1:zeroCrosses(iSegment));
            FxSegs{iSegment} =Fx(1:zeroCrosses(iSegment));
        else
            CoPSegs{iSegment} = CoPx(zeroCrosses(iSegment-1)+1:zeroCrosses(iSegment));
            FxSegs{iSegment} =Fx(zeroCrosses(iSegment-1)+1:zeroCrosses(iSegment));     
        end
    end

    % Double-integrate the Fx to get the position
    CoMSegs = cell(length(zeroCrosses)+1,1); 
    for iSegment = 1:length(CoPSegs)
        % CoPSeg = CoPSegs{iSegment}; 
        % FxSeg = FxSegs{iSegment};
        timeSeg = 0: dt: dt*(length(FxSegs{iSegment})-1);
        if isempty(CoPSegs{iSegment})
            continue;
        elseif length(CoPSegs{iSegment}) == 1 
            % 1 element (only the start point)
            % Calling cumtrapz in this condition will produce errors
            CoMSegs{iSegment} = CoPSegs{iSegment};
        else       
            integral = cumtrapz(timeSeg, cumtrapz(timeSeg, FxSegs{iSegment}/mass));
            v_t0 = (CoPSegs{iSegment}(end) - CoPSegs{iSegment}(1) ...
                - integral(end))/timeSeg(end);
            CoMSegs{iSegment} = integral + (v_t0*timeSeg') + CoPSegs{iSegment}(1);  
        end
        % CoMSegs{iSegment} = CoMSeg;
    end

    %concatenate all the CoM segments together
    CoM_estimate = cat(1,CoMSegs{:});
end