classdef TestPeakPositionDifferenceFit < matlab.unittest.TestCase
    methods (Test)
        function reproducesQuadraticAndKeepsExcludedDiagnostics(testCase)
            wavelength=linspace(250,1050,41).';
            difference=0.02+3e-4*wavelength-2e-7*wavelength.^2;
            include=true(41,1);include(7)=false;
            r=wc4sm_fit_peak_position_difference(wavelength,difference,include,2);
            testCase.verifyEqual(r.N,40);
            testCase.verifyLessThan(r.RMSE,1e-12);
            testCase.verifyTrue(isfinite(r.Residual(7)));
            testCase.verifyFalse(r.FitMask(7));
        end

        function residualIsObservedMinusFitted(testCase)
            wavelength=(1:8).';difference=0.1*wavelength;
            difference(4)=difference(4)+0.2;
            r=wc4sm_fit_peak_position_difference(wavelength,difference,true(8,1),1);
            testCase.verifyEqual(r.Residual,difference-r.Prediction,'AbsTol',1e-14);
        end

        function rejectsUnsupportedDegree(testCase)
            testCase.verifyError(@()wc4sm_fit_peak_position_difference((1:5).',(1:5).',true(5,1),4), ...
                'WCC4SM:PeakDifferenceInvalidDegree');
        end
    end
end
