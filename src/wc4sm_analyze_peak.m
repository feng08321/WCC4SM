function result = wc4sm_analyze_peak(x, y, centerValue, leftPixels, rightPixels, method, factor, baselineMode)
%WC4SM_ANALYZE_PEAK Analyze one sampled spectral peak without model fitting.
% Compatible with MATLAB R2022a.
%
% result = wc4sm_analyze_peak(x,y,centerValue,leftPixels,rightPixels,...
%                             method,factor,baselineMode)
%
% x              Pixel coordinate or wavelength, strictly increasing.
% y              AD counts.
% centerValue    Approximate peak position in x coordinates.
% leftPixels     Number of original samples retained left of nearest center.
% rightPixels    Number of original samples retained right of nearest center.
% method         'spline' (default), 'pchip', or 'linear'.
% factor         Interpolation subdivisions per original interval (>=1).
% baselineMode   'linear' (default), 'constant', or 'none'.

% Definitions:
%   Direct peak : maximum original sample after local baseline subtraction.
%   Interp peak : maximum interpolated signal.
%   Center      : midpoint of the left/right half-maximum crossings.
%   Centroid    : first moment over the confirmed full peak window.
%   FWHM        : separation of the half-maximum crossings.
%   ERW         : integrated net peak / net peak maximum.

% Interpolation refines numerical localization; it does not improve the
% physical spectral resolution of the instrument.

    arguments
        x (:,1) double
        y (:,1) double
        centerValue (1,1) double
        leftPixels (1,1) double {mustBeInteger,mustBeNonnegative}
        rightPixels (1,1) double {mustBeInteger,mustBeNonnegative}
        method (1,:) char = 'spline'
        factor (1,1) double {mustBeInteger,mustBePositive} = 20
        baselineMode (1,:) char = 'linear'
    end

    result = emptyResult();
    result.Settings = struct('CenterValue',centerValue, ...
        'LeftPixels',leftPixels,'RightPixels',rightPixels, ...
        'InterpolationMethod',lower(method),'InterpolationFactor',factor, ...
        'BaselineMode',lower(baselineMode));

    if numel(x) ~= numel(y) || numel(x) < 3
        error('WC4SM:InvalidData','x and y must have equal length and at least 3 samples.');
    end
    if any(~isfinite(x)) || any(~isfinite(y))
        error('WC4SM:InvalidData','x and y must contain finite numeric values only.');
    end
    if any(diff(x) <= 0)
        error('WC4SM:InvalidX','x must be strictly increasing.');
    end
    method = lower(method);
    if ~ismember(method,{'spline','pchip','linear'})
        error('WC4SM:InvalidMethod','Interpolation method must be spline, pchip, or linear.');
    end
    baselineMode = lower(baselineMode);
    if ~ismember(baselineMode,{'linear','constant','none'})
        error('WC4SM:InvalidBaseline','Baseline mode must be linear, constant, or none.');
    end

    [~,centerIndex] = min(abs(x-centerValue));
    iLeft = max(1,centerIndex-leftPixels);
    iRight = min(numel(x),centerIndex+rightPixels);
    if iRight-iLeft+1 < 3
        error('WC4SM:WindowTooSmall','Peak window must contain at least 3 original samples.');
    end
    xw = x(iLeft:iRight);
    yw = y(iLeft:iRight);
    baseline = buildBaseline(xw,yw,baselineMode);
    yNet = yw-baseline;

    nDense = (numel(xw)-1)*factor+1;
    xi = linspace(xw(1),xw(end),nDense).';
    yiRaw = interp1(xw,yw,xi,method);
    bi = interp1(xw,baseline,xi,'linear');
    yi = yiRaw-bi;

    [directHeight,localDirect] = max(yNet);
    directX = xw(localDirect);
    [interpHeight,interpIndex] = max(yi);
    interpX = xi(interpIndex);

    result.WindowIndex = [iLeft iRight];
    result.WindowX = xw;
    result.WindowY = yw;
    result.Baseline = baseline;
    result.NetY = yNet;
    result.InterpX = xi;
    result.InterpRawY = yiRaw;
    result.InterpBaseline = bi;
    result.InterpNetY = yi;
    result.DirectPeakX = directX;
    result.DirectPeakY = directHeight;
    result.InterpolatedPeakX = interpX;
    result.InterpolatedPeakY = interpHeight;
    result.PeakArea = trapz(xi,max(yi,0));
    result.ERW = NaN;
    result.CentroidX = NaN;
    result.CenterX = NaN;
    result.LeftHalfX = NaN;
    result.RightHalfX = NaN;
    result.FWHM = NaN;
    result.LeftHWHM = NaN;
    result.RightHWHM = NaN;

    warningList = strings(0,1);
    if interpHeight <= 0
        warningList(end+1) = "Net peak height is not positive.";
        result.Status = 'Invalid';
        result.Warnings = warningList;
        return;
    end

    result.ERW = result.PeakArea/interpHeight;
    positiveY = max(yi,0);
    denom = trapz(xi,positiveY);
    if denom > 0
        result.CentroidX = trapz(xi,xi.*positiveY)/denom;
    end

    halfLevel = 0.5*interpHeight;
    leftCross = findCrossing(xi(1:interpIndex),yi(1:interpIndex),halfLevel,'left');
    rightCross = findCrossing(xi(interpIndex:end),yi(interpIndex:end),halfLevel,'right');
    if isfinite(leftCross) && isfinite(rightCross) && rightCross > leftCross
        result.LeftHalfX = leftCross;
        result.RightHalfX = rightCross;
        result.CenterX = 0.5*(leftCross+rightCross);
        result.FWHM = rightCross-leftCross;
        result.LeftHWHM = result.CenterX-leftCross;
        result.RightHWHM = rightCross-result.CenterX;
    else
        warningList(end+1) = "One or both half-maximum crossings are outside the window.";
    end

    result.PeakCenterDelta = result.DirectPeakX-result.CenterX;
    result.InterpolationCenterDelta = result.InterpolatedPeakX-result.CenterX;
    result.CentroidCenterDelta = result.CentroidX-result.CenterX;
    result.RawInterpolationDelta = result.DirectPeakX-result.InterpolatedPeakX;
    result.ERWminusFWHM = result.ERW-result.FWHM;
    result.ERWdivFWHM = result.ERW/result.FWHM;
    result.LocalSamplingInterval = localSampling(xw,localDirect);
    result.SamplingRatio = result.FWHM/result.LocalSamplingInterval;
    result.ERWSamplingRatio = result.ERW/result.LocalSamplingInterval;
    result.OriginalPointCount = numel(xw);
    result.InterpolatedPointCount = numel(xi);

    if localDirect == 1 || localDirect == numel(xw)
        warningList(end+1) = "Direct peak is located at a window boundary.";
    end
    negativeFraction = mean(yNet < -0.01*interpHeight);
    if negativeFraction > 0.10
        warningList(end+1) = "More than 10% of window samples are significantly negative after baseline correction; centroid and area use nonnegative signal.";
    end
    result.Warnings = warningList;
    if isempty(warningList)
        result.Status = 'OK';
    else
        result.Status = 'Review';
    end
end

function baseline = buildBaseline(x,y,mode)
    switch mode
        case 'none'
            baseline = zeros(size(y));
        case 'constant'
            baseline = repmat(mean([y(1),y(end)]),size(y));
        case 'linear'
            baseline = y(1)+(y(end)-y(1))*(x-x(1))/(x(end)-x(1));
    end
end

function xc = findCrossing(x,y,level,side)
    xc = NaN;
    z = y-level;
    idx = find(z(1:end-1).*z(2:end) <= 0);
    if isempty(idx), return; end
    if strcmp(side,'left'), k = idx(end); else, k = idx(1); end
    x1=x(k); x2=x(k+1); y1=z(k); y2=z(k+1);
    if y2==y1, xc=0.5*(x1+x2); else, xc=x1-y1*(x2-x1)/(y2-y1); end
end

function d = localSampling(x,k)
    if numel(x)<2, d=NaN;
    elseif k==1, d=x(2)-x(1);
    elseif k==numel(x), d=x(end)-x(end-1);
    else, d=0.5*(x(k+1)-x(k-1));
    end
end

function r = emptyResult()
    r = struct('Status','NotCalculated','Warnings',strings(0,1), ...
        'Settings',struct(),'WindowIndex',[NaN NaN],'WindowX',[], ...
        'WindowY',[],'Baseline',[],'NetY',[],'InterpX',[], ...
        'InterpRawY',[],'InterpBaseline',[],'InterpNetY',[], ...
        'DirectPeakX',NaN,'DirectPeakY',NaN,'InterpolatedPeakX',NaN, ...
        'InterpolatedPeakY',NaN,'LeftHalfX',NaN,'RightHalfX',NaN, ...
        'CenterX',NaN,'CentroidX',NaN,'FWHM',NaN,'ERW',NaN, ...
        'PeakArea',NaN,'LeftHWHM',NaN,'RightHWHM',NaN, ...
        'PeakCenterDelta',NaN,'InterpolationCenterDelta',NaN, ...
        'CentroidCenterDelta',NaN,'RawInterpolationDelta',NaN, ...
        'ERWminusFWHM',NaN,'ERWdivFWHM',NaN, ...
        'LocalSamplingInterval',NaN,'SamplingRatio',NaN, ...
        'ERWSamplingRatio',NaN,'OriginalPointCount',NaN, ...
        'InterpolatedPointCount',NaN);
end

