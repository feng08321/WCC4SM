function WCC4SM_V0_9_2
%WCC4SM_V0_9_2 Compatibility entry point for WCC4SM V0.9.3.
% Existing scripts may continue to use the V0.9.2 command. New workflows
% should call WCC4SM_V0_9_3 directly.
%
% LEGACY ENTRY — thin compatibility shim. Not maintained; use
% WCC4SM_V1_0 for all new work.

    warning('WCC4SM:LegacyEntryPoint', ...
        'WCC4SM_V0_9_2 is a compatibility entry point; starting WCC4SM V0.9.3.');
    WCC4SM_V0_9_3;
end
