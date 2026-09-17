function Calibration = wc4sm_empty_state_calibration()
%WC4SM_EMPTY_STATE_CALIBRATION Initial Calibration-domain state (pairs and models).
%   Calibration = WC4SM_EMPTY_STATE_CALIBRATION() returns the Calibration
%   domain of the application state: the matched calibration pair list, the
%   provisional / final / applied wavelength models, the applied-model display
%   name, the model-comparison list, and the reference resolution used for
%   candidate matching. Each field comment records the legacy closure variable
%   it replaces during the C1 (State-grouping) refactor.

    Calibration = struct();
    Calibration.Pairs = wc4sm_empty_calibration_pairs();     % calPairs
    Calibration.Provisional = wc4sm_empty_initial_model();   % provisional
    Calibration.FinalModel = wc4sm_empty_final_model();      % finalModel
    Calibration.AppliedModel = wc4sm_empty_final_model();    % appliedModel
    Calibration.AppliedModelName = '';                       % appliedModelName
    Calibration.Models = wc4sm_empty_calibration_models();   % calibrationModels
    Calibration.ReferenceResolutionNm = 3;                   % referenceResolutionNm
end
