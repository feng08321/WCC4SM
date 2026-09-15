classdef TestInitialMappingModules < matlab.unittest.TestCase
    % Cover the extracted initial-mapping pipeline: anchor-based provisional
    % model build, model evaluation, and the dynamic-programming ordered
    % sequence matcher used by auto-match.

    methods (Test)
        function buildInitialModelDegreeOne(testCase)
            % Two anchors -> degree 1; a/b must match the plain-line fit.
            px = [100; 500];
            wl = [400; 900];
            m = wc4sm_build_initial_model(px,wl);
            testCase.verifyTrue(m.valid);
            testCase.verifyEqual(m.Degree,1);
            testCase.verifyEqual(m.a,1.25,'AbsTol',1e-12);
            testCase.verifyEqual(m.b,275,'AbsTol',1e-10);
            testCase.verifyEqual(wc4sm_evaluate_wavelength_model(m,300),650,'AbsTol',1e-8);
        end

        function buildInitialModelDegreeCappedAtThree(testCase)
            px = (1:10).';
            wl = 300 + 0.4*px + 1e-4*px.^3;
            m = wc4sm_build_initial_model(px,wl);
            testCase.verifyEqual(m.Degree,3);
            testCase.verifyEqual(wc4sm_evaluate_wavelength_model(m,px),wl,'AbsTol',1e-8);
        end

        function buildInitialModelRejectsBadInput(testCase)
            testCase.verifyError(@()wc4sm_build_initial_model(5,600), ...
                'WCC4SM:InsufficientAnchors');
            testCase.verifyError(@()wc4sm_build_initial_model([7;7],[600;601]), ...
                'WCC4SM:DuplicateAnchorPixels');
            testCase.verifyError(@()wc4sm_build_initial_model([1;2;3],[600;601]), ...
                'WCC4SM:InitialModelSizeMismatch');
        end

        function evaluateEmptyModelReturnsNaN(testCase)
            m = wc4sm_empty_initial_model();
            wl = wc4sm_evaluate_wavelength_model(m,[10;20;30]);
            testCase.verifyEqual(wl,[NaN;NaN;NaN]);
        end

        function orderedSequencePerfectMatch(testCase)
            refW = [300; 400; 500; 600; 700];
            refIdx = (11:15).';
            matched = wc4sm_match_ordered_sequence([301;499;698],refW,refIdx,5);
            testCase.verifyEqual(matched,[11;13;15]);
        end

        function orderedSequenceSkipsExtraReference(testCase)
            refW = [300; 350; 400; 500];
            refIdx = (1:4).';
            % Predicted peaks skip the 350 line; alignment must not shift.
            matched = wc4sm_match_ordered_sequence([299;401;498],refW,refIdx,6);
            testCase.verifyEqual(matched,[1;3;4]);
        end

        function orderedSequenceLeavesDistantPeakUnmatched(testCase)
            refW = [300; 400; 500];
            refIdx = (21:23).';
            matched = wc4sm_match_ordered_sequence([301;450;499],refW,refIdx,5);
            testCase.verifyEqual(matched,[21;0;23]);
        end

        function orderedSequenceEnforcesMonotonicity(testCase)
            % Nearest-neighbour would map both peaks to the 400 line; the
            % monotonic constraint must prevent that.
            refW = [400; 405];
            refIdx = [31; 32];
            matched = wc4sm_match_ordered_sequence([399;404.5],refW,refIdx,10);
            testCase.verifyEqual(matched,[31;32]);
            testCase.verifyTrue(issorted(matched(matched>0)));
        end
    end
end
