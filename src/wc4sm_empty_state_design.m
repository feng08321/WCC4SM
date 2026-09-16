function Design = wc4sm_empty_state_design()
%WC4SM_EMPTY_STATE_DESIGN Initial Design-domain state (optimization, influence, subsets).
%   Design = WC4SM_EMPTY_STATE_DESIGN() returns the Design domain of the
%   application state: calibration optimization paths and stability, point
%   influence results, seed-combination and subset-design workspaces, window
%   influence settings, position cross-validation results, and the paper
%   peak-difference analysis workspace. Each field comment records the legacy
%   closure variable it replaces during the C1 (State-grouping) refactor.

    Design = struct();
    Design.OptimizationPath = struct();                      % optimizationPath
    Design.OptimizationStability = struct();                 % optimizationStability
    Design.OptimizationOrder = struct([]);                   % optimizationOrder
    Design.InfluenceResult = struct();                       % influenceResult
    Design.InfluenceOrderStats = struct([]);                 % influenceOrderStats
    Design.SeedComboResult = struct();                       % seedComboResult
    Design.PendingSeedModelItem = struct();                  % pendingSeedModelItem
    Design.SubsetDesignProfile = struct();                   % subsetDesignProfile
    Design.SubsetBeamState = struct();                       % subsetBeamState
    Design.SubsetDesignCandidates = struct([]);              % subsetDesignCandidates
    Design.SubsetWindowPartition = struct();                 % subsetWindowPartition
    Design.WindowInfluenceDegree = 3;                        % windowInfluenceDegree
    Design.WindowSelectedMask = [];                          % windowSelectedMask
    Design.PositionCrossResult = struct();                   % positionCrossResult
    Design.PaperPeakDifferenceExcludedIDs = {};              % paperPeakDifferenceExcludedIDs
    Design.PaperPeakAllExcludedIDs = {};                     % paperPeakAllExcludedIDs
    Design.PaperPeakDifferenceResult = struct();             % paperPeakDifferenceResult
    Design.PaperPeakPairArchive = wc4sm_empty_calibration_pairs(); % paperPeakPairArchive
end
