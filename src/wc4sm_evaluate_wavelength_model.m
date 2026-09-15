function wl = wc4sm_evaluate_wavelength_model(model,pixel)
%WC4SM_EVALUATE_WAVELENGTH_MODEL Evaluate a calibration model at pixel positions.
%   wl = WC4SM_EVALUATE_WAVELENGTH_MODEL(model,pixel) evaluates the normalized
%   polynomial stored in model.Coefficients/model.Mu. Returns NaN positions
%   when the model carries no coefficients.

    if isempty(model.Coefficients)
        wl = nan(size(pixel));
    else
        wl = polyval(model.Coefficients,pixel,[],model.Mu);
    end
end
