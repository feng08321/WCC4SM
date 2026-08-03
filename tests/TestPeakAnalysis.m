classdef TestPeakAnalysis < matlab.unittest.TestCase
    methods (Test)
        function symmetricGaussian(testCase)
            x = (-10:10).';
            sigma = 1.5;
            y = 200*exp(-0.5*(x/sigma).^2);
            r = wc4sm_analyze_peak(x,y,0,10,10,'pchip',100,'none');

            testCase.verifyEqual(r.Status,'OK');
            testCase.verifyEqual(r.DirectPeakX,0,'AbsTol',1e-12);
            testCase.verifyEqual(r.CenterX,0,'AbsTol',1e-12);
            testCase.verifyEqual(r.CentroidX,0,'AbsTol',1e-12);
            testCase.verifyEqual(r.FWHM,2*sqrt(2*log(2))*sigma,'RelTol',0.025);
            testCase.verifyEqual(r.ERW,sqrt(2*pi)*sigma,'RelTol',0.025);
        end

        function linearBaselineIsRemoved(testCase)
            x = (0:20).';
            baseline = 50 + 2*x;
            y = baseline + 300*exp(-0.5*((x-10)/1.8).^2);
            r = wc4sm_analyze_peak(x,y,10,10,10,'pchip',80,'linear');

            % PCHIP on a finite dense grid is not analytically symmetric to
            % machine precision. The protected accuracy here is 0.001 pixel,
            % well below the physical sampling interval and interpolation step.
            testCase.verifyEqual(r.CenterX,10,'AbsTol',1e-3);
            testCase.verifyEqual(r.CentroidX,10,'AbsTol',1e-3);
            testCase.verifyEqual(r.InterpolatedPeakY,300,'RelTol',0.01);
        end

        function truncatedWindowRequestsReview(testCase)
            x = (0:10).';
            y = exp(-0.5*((x-1)/2).^2);
            r = wc4sm_analyze_peak(x,y,1,1,3,'pchip',40,'none');

            testCase.verifyEqual(r.Status,'Review');
            testCase.verifyTrue(isnan(r.FWHM));
            testCase.verifyNotEmpty(r.Warnings);
        end

        function invalidCoordinatesAreRejected(testCase)
            x = [0;1;1;2];
            y = [0;1;0.5;0];
            testCase.verifyError(@() wc4sm_analyze_peak( ...
                x,y,1,1,1,'pchip',20,'none'),'WC4SM:InvalidX');
        end

        function paperCalibrationRegression(testCase)
            result = test_wc4sm_paper_calibration_case(false);
            testCase.verifyEqual(result.DirectSTD,0.184,'AbsTol',0.003);
            testCase.verifyEqual(result.GaussianSTD,0.0457,'AbsTol',0.001);
        end
    end
end
