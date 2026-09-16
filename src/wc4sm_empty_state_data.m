function Data = wc4sm_empty_state_data()
%WC4SM_EMPTY_STATE_DATA Initial Data-domain state (spectrum, reference, libraries).
%   Data = WC4SM_EMPTY_STATE_DATA() returns the Data domain of the application
%   state: the measured spectrum, the external reference spectrum, and the
%   Hg-Ar line libraries (three built-in plus one external file slot). Each
%   field comment records the legacy closure variable it replaces during the
%   C1 (State-grouping) refactor.
%
%   Library always mirrors the currently active library; it starts as the
%   built-in Basic 21 library and is reassigned when the user switches source.

    Data = struct();
    Data.Spectrum = wc4sm_empty_data();                        % D
    Data.Reference = wc4sm_empty_reference();                  % R
    Data.LibraryBasic = wc4sm_load_builtin_library("basic");   % Lbasic
    Data.LibraryPaper = wc4sm_load_builtin_library("paper24"); % Lpaper
    Data.LibraryNim = wc4sm_load_builtin_library("nim");       % Lnim
    Data.LibraryExternal = wc4sm_empty_line_library();         % Lexternal
    Data.Library = Data.LibraryBasic;                          % L (active library)
end
