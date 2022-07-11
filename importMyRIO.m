%File: importMyRIO.m
%Author: Liam Foulger
%Date Created: 2022-05-01
%Last Updated: 2022-06-30
%
%Function to get the data from a trial folder from the myRIO device, and
%collate all the minute folders into a single matrix that is correctly
%temporally ordered
%Input:
%-path of trial data. This will be a folder with each minute subfolder
%within
%Output:
%-rawData: collated raw data, where rows are time points and columns are
%different data measures from myRIO

function rawData = importMyRIO(selpath)
D = char(selpath);
S = dir(fullfile(D,'*'));
N = setdiff({S.name},{'.','..'}) ;
%resort N by minute #, not alphabetical

for ii = 1:numel(N)
    idx = sscanf(N{ii},'Minute_%d');
    N_sorted{idx} = N{ii};
    
end
rawData = [];
for ii = 1:numel(N)
    T = fullfile(D,N_sorted{ii});
    
    minuteData{ii} = readmatrix(T);
    rawData = [rawData; minuteData{ii}];
end

end