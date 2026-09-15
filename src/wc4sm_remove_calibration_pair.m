function pairs = wc4sm_remove_calibration_pair(pairs,id,refIdx)
%WC4SM_REMOVE_CALIBRATION_PAIR Drop pairs matching a peak ID or reference index.
% Operates on the calibration-pairs struct array used by the matching table.

    if isempty(pairs),return;end
    keep=~strcmp({pairs.PeakID},id) & [pairs.ReferenceIndex]~=refIdx; pairs=pairs(keep);
end
