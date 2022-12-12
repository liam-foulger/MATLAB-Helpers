function rmse = get_rmse(model, observed)

    %function to compute the RMSE (mm)
    rmse = sqrt(sum((observed - model).^2)/(length(model)));


end