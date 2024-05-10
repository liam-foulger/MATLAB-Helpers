%File: getCoM_LPF.m
%Author: Liam Foulger
%Date Created: 2023-05-24
%Last Updated: 2023-06-05
%
% CoM = getCoM_LPF(CoP, fs, height)
%
% Function to estimate the CoM displacement by filtering the force platform
% centre of pressure (CoP) as described in Caron et al. (1997) and Lafond et al. (2004). 
%
% Note that I'm not 100% sure about this one, especially the definition of
% the f array (wasn't clear in the paper). However, it seems to work pretty
% well and almost identical to a 0.3 Hz 4th order butterworth LPF - other
% than some edge effects.
%
% % Inputs:
% - CoP: force platform centre of pressure (CoP) data (n x 2) in AP (first column) 
% and ML (second column) directions
% - fs: sampling rate of the data (Hz)
% - height: participant height (m)
% Output:
% - CoM: centre of mass displacement (m; n x 2) in AP (first column) and ML
% (second column) directions
%
% References:
% Caron, O., Faure, B., & Brenière, Y. (1997). 
% Estimating the centre of gravity of the body on the basis of the centre of pressure in standing posture. 
% Journal of Biomechanics, 30(11), 1169–1171. https://doi.org/10.1016/S0021-9290(97)00094-8
% Lafond, D., Duarte, M., & Prince, F. (2004). 
% Comparison of three methods to estimate the center of mass during balance assessment. 
% Journal of Biomechanics, 37, 1421–1426. https://doi.org/10.1016/S0021-9290(03)00251-3


function CoM = getCoM_LPF(CoP, fs, height)
    arguments
        CoP (:,2) double
        fs (1,1) double 
        height (1,1) double 
    end
    
    %remove CoP offset at start to minimize filter instability @ start
    initOffsetAP = CoP(1,1);
    initOffsetML = CoP(1,2);
    CoP(:,1) = CoP(:,1) - initOffsetAP;
    CoP(:,2) = CoP(:,2) - initOffsetML;

    g = 9.80665002864;
    apSpec = fft(CoP(:,1));
    mlSpec = fft(CoP(:,2));
    N = size(CoP,1);
    
    f = [fs*(0:(N)/2)/N fliplr(-fs*(1:(N-1)/2)/N)];
    
    apFilt = (g/(0.0533*height))./( (g/(0.0533*height)) + (2.*pi.*f).^2)';
    mlFilt = (g/(0.0572*height))./( (g/(0.0572*height)) + (2.*pi.*f).^2)';
    CoM(:,1) = ifft(apSpec.*apFilt) + initOffsetAP;
    CoM(:,2) = ifft(mlSpec.*mlFilt) + initOffsetML;

end