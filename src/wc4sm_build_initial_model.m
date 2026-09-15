function model = wc4sm_build_initial_model(pixel,wavelength)
%WC4SM_BUILD_INITIAL_MODEL Fit the provisional anchor-based mapping model.
%   model = WC4SM_BUILD_INITIAL_MODEL(pixel,wavelength) fits a normalized
%   polynomial of degree min(3, n-1) through the anchor pairs and returns the
%   initial-model structure. For degree 1 the conventional slope/offset
%   (a,b) are also stored for export compatibility.

    arguments
        pixel (:,1) double
        wavelength (:,1) double
    end
    if numel(pixel) ~= numel(wavelength)
        error('WCC4SM:InitialModelSizeMismatch', ...
            'Pixel and wavelength anchor vectors must have equal length.');
    end
    if numel(pixel) < 2
        error('WCC4SM:InsufficientAnchors', ...
            'At least two anchor pairs are required.');
    end
    if numel(unique(pixel)) < 2
        error('WCC4SM:DuplicateAnchorPixels', ...
            'Anchor pairs require at least two different pixel positions.');
    end

    deg = min(3,numel(pixel)-1);
    [c,~,mu] = polyfit(pixel,wavelength,deg);
    model = wc4sm_empty_initial_model();
    model.valid = true;
    model.Degree = deg;
    model.Coefficients = c;
    model.Mu = mu;
    if deg == 1
        % Convert normalized-coordinate coefficients to conventional a,b.
        model.a = c(1)/mu(2);
        model.b = c(2)-c(1)*mu(1)/mu(2);
    end
end
