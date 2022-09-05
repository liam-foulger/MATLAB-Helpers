%File: getHJW.m
%Author: Liam Foulger
%Date created: 2021-06-15
%Last updated: 2022-09-05
%
%hipJointWidth = getHipJointWidth(pelvicDepth,pelvicWidth)
%
%Function to get the Hip Joint Width (HJW; distances between hip joint
%centres)
%Based on paper: https://pubmed.ncbi.nlm.nih.gov/16584737/
%Note: the formulas are based on origin being directly in between
%ASISs, so we multiply result by 2 to get the total distance between
%Input:
% - pelvicDepth: measured as distance between the inter-ASIS and
% inter-PSIS lines
% - pelvicWidth: measured as distance between left and right ASIS
%Output (in same units in inputs):
% - Hip Joint Width: distance between hip joints

function hipJointWidth = getHipJointWidth(pelvicDepth,pelvicWidth)
    
    PD = pelvicDepth;
    PW = pelvicWidth;
    
    hipJointWidth =  2*(0.28*PD + 0.16*PW + 7.9);
    

end