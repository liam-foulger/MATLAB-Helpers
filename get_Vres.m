%File: get_Vres.m
%Author: Liam Foulger
%Date Created: 2022-06-28
%Last Updated: 2023-10-11
%
% [Vres,SStot,SSres] = get_Vres(data)
%
% Function to calculate the Vres from head IMU data
%
% References:
% - MacNeilage, P. R., & Glasauer, S. (2017). 
% Quantification of head movement predictability and implications for 
% suppression of vestibular input during locomotion. Frontiers in 
% Computational Neuroscience, 11(47). https://doi.org/10.3389/fncom.2017.00047
% - Dietrich, H., Heidger, F., Schniepp, R., MacNeilage, P. R., Glasauer, 
% S., & Wuehr, M. (2020). Head motion predictability explains activity-dependent 
% suppression of vestibular balance control. Scientific Reports, 10(1), 1–10. 
% https://doi.org/10.1038/s41598-019-57400-z
%
% Inputs: 
% - data (m x v x n matrix):stride-normalized head IMU data, where m represents
% the number of samples in every stride, v represents the number of
% variables used to calculate Vres (will either be all the accel/gyro axis
% to calculate net vres (v = 3) or just a single axis in which case v = 1), and n
% represents the number of strides 
% Outputs:
% - Vres (m x 1): The Vres over the stride cycle
% - SStot (m x 1): The total sum of squares over the stride cycle. This
% represents the total magnitude of the signal(s) (i.e., the
% sensory/vestibular noise)
% - SSres (m x 1): The residual sum of squares over the stride cycle. This
% represents the deviation of signal from the average stride (i.e., the
% motor efference copy noise).




function [Vres,SStot,SSres] = get_Vres(data)
%     SStot = permute(mean((data - mean(data, [1 2])).^2,2), [1 3 2]);
%     SSres = permute(mean((data - mean(data, 2)).^2,2), [1 3 2]);

    SStot = sum(mean((data - mean(data, [1 3])).^2,3),2);
    SSres = sum(mean((data - mean(data, 3)).^2,3),2);
    
    Vres = SSres./SStot;

end