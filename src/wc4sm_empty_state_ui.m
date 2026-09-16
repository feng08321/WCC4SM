function UI = wc4sm_empty_state_ui()
%WC4SM_EMPTY_STATE_UI Initial UI-domain state (selections, view modes, colors).
%   UI = WC4SM_EMPTY_STATE_UI() returns the UI domain of the application state:
%   table/axes selections, axis and view modes, the shared color palette, and
%   session/file bookkeeping. Each field comment records the legacy closure
%   variable it replaces during the C1 (State-grouping) refactor.
%
%   ReferenceDataDir / DocumentationDir are returned empty here and assigned at
%   application startup, since they depend on the deployed/runtime location.

    UI = struct();
    UI.MatchingAxisMode = 'Pixel';                         % matchingAxisMode
    UI.MainAxisMode = 'Pixel';                             % mainAxisMode
    UI.InfluenceViewMode = 'Point influence';              % influenceViewMode
    UI.OptimizationViewMode = '';                          % optimizationViewMode
    UI.SelectedResidualContext = struct('X',[],'Residual',[],'Label','','XAxisLabel',''); % selectedResidualContext
    UI.SelectedRow = 0;                                    % selectedRow
    UI.SelectedDatasetRow = 0;                             % selectedDatasetRow
    UI.SelectedRefRow = 0;                                 % selectedRefRow
    UI.SelectedPairRow = 0;                                % selectedPairRow
    UI.SelectedValidationRow = 0;                          % selectedValidationRow
    UI.SelectedPositionCrossRow = 1;                       % selectedPositionCrossRow
    UI.SelectedPositionCrossColumn = 1;                    % selectedPositionCrossColumn
    UI.PositionCrossBusy = false;                          % positionCrossBusy
    UI.PaperPeakDifferenceSelectedID = '';                 % paperPeakDifferenceSelectedID
    UI.PaperPeakAllSelectedRows = [];                      % paperPeakAllSelectedRows
    UI.PaperPeakCalibrationSelectedRows = [];              % paperPeakCalibrationSelectedRows
    UI.SelectedModelRow = 0;                               % selectedModelRow
    UI.SelectedSeedRound = 0;                              % selectedSeedRound
    UI.SelectedSubsetCandidate = 0;                        % selectedSubsetCandidate
    UI.SelectedLocalCandidate = 0;                         % selectedLocalCandidate
    UI.Colors = wc4sm_colors();                            % C
    UI.SessionMetadata = struct();                         % sessionMetadata
    UI.CurrentSessionPath = '';                            % currentSessionPath
    UI.ReferenceDataDir = '';   % assigned at startup (was referenceDataDir)
    UI.DocumentationDir = '';   % assigned at startup (was documentationDir)
end
