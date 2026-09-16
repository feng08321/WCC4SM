function State = wc4sm_empty_state()
%WC4SM_EMPTY_STATE Assemble the five-domain application state structure.
%   State = WC4SM_EMPTY_STATE() returns the canonical initial state for the
%   WCC4SM V1.0 application, grouping the formerly scattered closure variables
%   into five domain structs: Data, Peaks, Calibration, Design, UI.
%
%   This factory is introduced ahead of the C1 refactor. It changes no existing
%   code; it defines the target State layout and lets tests construct a clean
%   application state. Each field comment records the legacy closure variable
%   it will replace during the refactor.
%
%   Domain layout:
%     State.Data        - spectrum, reference, and line libraries
%     State.Peaks       - detected peaks and local peak search
%     State.Calibration - calibration pairs and wavelength models
%     State.Design      - optimization / influence / subset / cross-validation
%     State.UI          - selections, view modes, colors, session bookkeeping

    % --- State.Data: spectrum, reference, and line libraries ---
    Data = struct();
    Data.Spectrum = wc4sm_empty_data();                    % D
    Data.Reference = wc4sm_empty_reference();              % R
    Data.LibraryBasic = wc4sm_load_builtin_library("basic");   % Lbasic
    Data.LibraryPaper = wc4sm_load_builtin_library("paper24"); % Lpaper
    Data.LibraryNim = wc4sm_load_builtin_library("nim");       % Lnim
    Data.LibraryExternal = wc4sm_empty_line_library();     % Lexternal
    Data.Library = Data.LibraryBasic;                      % L (active library)

    % --- State.Peaks: detected peaks and local peak search ---
    Peaks = struct();
    Peaks.Raw = wc4sm_empty_peaks();                       % peaks
    Peaks.Dataset = wc4sm_empty_peak_dataset();            % peakDataset
    Peaks.LocalCandidates = wc4sm_empty_local_candidates(); % localCandidates
    Peaks.LocalSearchWindow = [NaN NaN];                   % localSearchWindow
    Peaks.SymmetryThresholdPx = 0.2;                       % symmetryThresholdPx

    % --- State.Calibration: calibration pairs and wavelength models ---
    Calibration = struct();
    Calibration.Pairs = wc4sm_empty_calibration_pairs();   % calPairs
    Calibration.Provisional = wc4sm_empty_initial_model(); % provisional
    Calibration.FinalModel = wc4sm_empty_final_model();    % finalModel
    Calibration.AppliedModel = wc4sm_empty_final_model();  % appliedModel
    Calibration.AppliedModelName = '';                     % appliedModelName
    Calibration.Models = wc4sm_empty_calibration_models(); % calibrationModels
    Calibration.ReferenceResolutionNm = 3;                 % referenceResolutionNm

    % --- State.Design: optimization / influence / subset / cross-validation ---
    Design = struct();
    Design.OptimizationPath = struct();                    % optimizationPath
    Design.OptimizationStability = struct();               % optimizationStability
    Design.OptimizationOrder = struct([]);                 % optimizationOrder
    Design.InfluenceResult = struct();                     % influenceResult
    Design.InfluenceOrderStats = struct([]);               % influenceOrderStats
    Design.SeedComboResult = struct();                     % seedComboResult
    Design.PendingSeedModelItem = struct();                % pendingSeedModelItem
    Design.SubsetDesignProfile = struct();                 % subsetDesignProfile
    Design.SubsetBeamState = struct();                     % subsetBeamState
    Design.SubsetDesignCandidates = struct([]);            % subsetDesignCandidates
    Design.SubsetWindowPartition = struct();               % subsetWindowPartition
    Design.WindowInfluenceDegree = 3;                      % windowInfluenceDegree
    Design.WindowSelectedMask = [];                        % windowSelectedMask
    Design.PositionCrossResult = struct();                 % positionCrossResult
    Design.PaperPeakDifferenceExcludedIDs = {};            % paperPeakDifferenceExcludedIDs
    Design.PaperPeakAllExcludedIDs = {};                   % paperPeakAllExcludedIDs
    Design.PaperPeakDifferenceResult = struct();           % paperPeakDifferenceResult
    Design.PaperPeakPairArchive = wc4sm_empty_calibration_pairs(); % paperPeakPairArchive

    % --- State.UI: selections, view modes, colors, session bookkeeping ---
    UI = wc4sm_empty_state_ui();

    State = struct('Data',Data,'Peaks',Peaks,'Calibration',Calibration, ...
        'Design',Design,'UI',UI);
end
