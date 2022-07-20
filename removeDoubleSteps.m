%File: removeDoubleSteps.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-07-19
%
%Function to remove double step indexes by choosing the largest peak when 2
%from the same foot are in a row
%
%Improve me!
%

function [RstepIDX, LstepIDX] = removeDoubleSteps(RstepIDX,Rsignal,LstepIDX,Lsignal)

    Ridx = 1;
    Lidx = 1;
    RstepPks = Rsignal(RstepIDX);
    LstepPks = Lsignal(LstepIDX);
    while (Lidx+1 <= length(LstepIDX) ) && (Ridx+1 <= length(RstepIDX) )
        [~, foot] = min([RstepIDX(Ridx); LstepIDX(Lidx)]);
        if foot ==1
            %check if next peak is on same side
            if RstepIDX(Ridx+1) < LstepIDX(Lidx)
                %find andd remove smaller peak
                [~, minPeak] = min([RstepPks(Ridx); RstepPks(Ridx+1)]);

                if minPeak ==1
                    RstepIDX(Ridx) = [];
                    RstepPks(Ridx) = [];
                else
                    RstepIDX(Ridx+1) = [];
                    RstepPks(Ridx+1) = [];
                end
            else
                Ridx = Ridx +1;
            end
            
        end
        if foot ==2
            %check if next peak is on same side
            if LstepIDX(Lidx+1) < RstepIDX(Ridx)
                %find andd remove smaller peak
                [~, minPeak] = min([LstepPks(Lidx); LstepPks(Lidx+1)]);
                if minPeak ==1
                    LstepIDX(Lidx) = [];
                    LstepPks(Lidx) = [];
                else
                    LstepIDX(Lidx+1) = [];
                    LstepPks(Lidx+1) = [];
                end
            else
                Lidx = Lidx +1;
                
            end
            
        end     
        
    end
end
