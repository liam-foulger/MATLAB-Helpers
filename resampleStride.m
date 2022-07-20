function trimStride = resampleStride(data, midIDX, newLength, shiftPercent)

    step1 = interp1(1:midIDX*2, data(1:(midIDX*2),:),linspace(1,midIDX*2,newLength));
    step2 = interp1(1:size(data((midIDX*2)+1:end,:),1), data((midIDX*2)+1:end,:),linspace(1,size(data(((midIDX*2)+1):end,:),1),newLength));
    normStride = [step1; step2];
    trimStride = normStride(((newLength/2)+1):(end-newLength/2),:);
    
    trimStride = circshift(trimStride, -round(shiftPercent.*newLength));

end