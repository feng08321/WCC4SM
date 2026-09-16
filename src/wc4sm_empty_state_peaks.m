function Peaks = wc4sm_empty_state_peaks()
%WC4SM_EMPTY_STATE_PEAKS Initial Peaks-domain state (detected peaks, local search).
%   Peaks = WC4SM_EMPTY_STATE_PEAKS() returns the Peaks domain of the
%   application state: detected peak list, the analyzed peak dataset, local
%   search candidates and window, and the peak symmetry threshold. Each field
%   comment records the legacy closure variable it replaces during the C1
%   (State-grouping) refactor.

    Peaks = struct();
    Peaks.Raw = wc4sm_empty_peaks();                         % peaks
    Peaks.Dataset = wc4sm_empty_peak_dataset();              % peakDataset
    Peaks.LocalCandidates = wc4sm_empty_local_candidates();  % localCandidates
    Peaks.LocalSearchWindow = [NaN NaN];                     % localSearchWindow
    Peaks.SymmetryThresholdPx = 0.2;                         % symmetryThresholdPx
end
