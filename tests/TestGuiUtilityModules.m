classdef TestGuiUtilityModules < matlab.unittest.TestCase
    %TESTGUIUTILITYMODULES Pin the behavior of the GUI utility helpers that
    % were extracted from the bottom of WCC4SM_V1_0.m (tech-debt batch D1-E).

    methods (Test)
        function colorsPalettePinned(testCase)
            C = wc4sm_colors();
            testCase.verifyEqual(sort(fieldnames(C)),sort({'bg';'navy';'blue'; ...
                'cyan';'cyanDark';'orange';'red';'green';'greenLight';'purple'; ...
                'gray';'muted';'sky';'yellow';'blueStrong';'greenBright'}));
            testCase.verifyEqual(C.bg,[.94 .96 .98],'AbsTol',1e-12);
            testCase.verifyEqual(C.navy,[.055 .18 .30],'AbsTol',1e-12);
            testCase.verifyEqual(C.muted,[.34 .40 .46],'AbsTol',1e-12);
            testCase.verifyEqual(C.greenBright,[.15 .90 .08],'AbsTol',1e-12);
        end

        function formatValueHandlesNaNInfAndNumbers(testCase)
            testCase.verifyEqual(wc4sm_format_value(NaN),'NaN');
            testCase.verifyEqual(wc4sm_format_value(Inf),'Inf');
            testCase.verifyEqual(wc4sm_format_value(-Inf),'Inf'); % original behavior: sign dropped
            testCase.verifyEqual(wc4sm_format_value(0.123456789012),sprintf('%.8g',0.123456789012));
            testCase.verifyEqual(wc4sm_format_value(0),'0');
        end

        function shortNameExtractsFileName(testCase)
            testCase.verifyEqual(wc4sm_short_name('C:\data\spectra\run01.csv'),'run01.csv');
            testCase.verifyEqual(wc4sm_short_name('run01.csv'),'run01.csv');
            testCase.verifyEqual(wc4sm_short_name(''),'');
        end

        function numberOrNanConvertsAndRejects(testCase)
            testCase.verifyEqual(wc4sm_number_or_nan(5),5);
            testCase.verifyEqual(wc4sm_number_or_nan('3.5'),3.5);
            testCase.verifyTrue(isnan(wc4sm_number_or_nan('abc')));
            testCase.verifyTrue(isnan(wc4sm_number_or_nan(Inf)));
            testCase.verifyTrue(isnan(wc4sm_number_or_nan([])));
        end

        function logicalTextYesNo(testCase)
            testCase.verifyEqual(wc4sm_logical_text(true),'Yes');
            testCase.verifyEqual(wc4sm_logical_text(false),'No');
        end

        function minMaxOrNanHandleEmpty(testCase)
            testCase.verifyTrue(isnan(wc4sm_min_or_nan([])));
            testCase.verifyTrue(isnan(wc4sm_max_or_nan([])));
            testCase.verifyEqual(wc4sm_min_or_nan([3 1 2]),1);
            testCase.verifyEqual(wc4sm_max_or_nan([3 1 2]),3);
        end

        function robustUpperLimitMatchesMedianMadRule(testCase)
            testCase.verifyEqual(wc4sm_robust_upper_limit([]),Inf);
            testCase.verifyEqual(wc4sm_robust_upper_limit(ones(1,5)),1); % zero MAD fallback
            v = 1:10;
            expected = median(v) + 3*1.4826*median(abs(v-median(v)));
            testCase.verifyEqual(wc4sm_robust_upper_limit(v),expected,'AbsTol',1e-12);
        end

        function cleanMatrixTrimsAndValidates(testCase)
            M = wc4sm_clean_matrix([1 2 NaN; NaN NaN NaN; 3 4 NaN]);
            testCase.verifyEqual(M,[1 2; 3 4]);
            M = wc4sm_clean_matrix([1 2 99; 3 4 99]);
            testCase.verifyEqual(M,[1 2; 3 4]); % third column dropped
            threw = false;
            try
                wc4sm_clean_matrix([NaN NaN; NaN NaN]); %#ok<NASGU>
            catch ME
                threw = true;
                testCase.verifyEqual(ME.message,'CSV contains no numeric data.');
            end
            testCase.verifyTrue(threw);
        end

        function polyNormalizedToNaturalExpands(testCase)
            % c(z) = 2z+1 with z=(x-10)/4 expands to 0.5x-4.
            p = wc4sm_poly_normalized_to_natural([2 1],[10 4]);
            testCase.verifyEqual(p,[0.5 -4],'AbsTol',1e-12);
            % constant model collapses to a scalar.
            p = wc4sm_poly_normalized_to_natural(1,[5 2]);
            testCase.verifyEqual(p,1,'AbsTol',1e-12);
        end

        function removeCalibrationPairMatchesEitherKey(testCase)
            pairs = struct('PeakID',{'P1';'P2';'P3'}, ...
                'ReferenceIndex',{5;7;9});
            r = wc4sm_remove_calibration_pair(pairs,'P2',0);
            testCase.verifyEqual({r.PeakID},{'P1' 'P3'});
            r = wc4sm_remove_calibration_pair(pairs,'',9);
            testCase.verifyEqual({r.PeakID},{'P1' 'P2'});
            testCase.verifyEmpty(wc4sm_remove_calibration_pair([],'P1',5));
        end

        function styleAxesAppliesSharedAppearance(testCase)
            f = figure('Visible','off');
            cleanup = onCleanup(@()close(f));
            ax = axes(f); %#ok<LAXES>
            C = wc4sm_colors();
            wc4sm_style_axes(ax,C);
            testCase.verifyEqual(ax.Color,[1 1 1]);
            testCase.verifyEqual(ax.XColor,C.muted,'AbsTol',1e-12);
            testCase.verifyEqual(ax.YColor,C.muted,'AbsTol',1e-12);
            testCase.verifyEqual(ax.GridColor,[.86 .89 .92],'AbsTol',1e-12);
            testCase.verifyEqual(char(ax.Box),'on');
        end
    end
end
