function D = wc4sm_empty_data()
%WC4SM_EMPTY_DATA Create an empty spectrum data state structure.
% The returned structure carries the raw/dark/corrected/normalized spectra
% together with the pixel-axis bookkeeping used throughout the workflow.

    D = struct('raw',[],'dark',[],'darkSource','','corrected',[], ...
        'normalized',[],'pixel',[],'inputX',[],'inputWavelength',[], ...
        'calibratedWavelength',[],'xKind','Pixel','source','', ...
        'PixelCoordinateMode','','PixelFirst',NaN,'PixelLast',NaN);
end
