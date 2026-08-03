classdef TestCalibratedPerformanceModule < matlab.unittest.TestCase
    methods (Test)
        function linearModelScalesPeakWidths(testCase)
            pixel = (0:10).';
            wavelength = 300+0.4*pixel;
            model = wc4sm_fit_calibration(pixel([1 6 11]), ...
                wavelength([1 6 11]),1,pixel,'Test',{});
            signal = exp(-0.5*((pixel-5)/1.2).^2);
            peak = wc4sm_analyze_peak(pixel,signal,5,5,5,'pchip',100,'none');
            result = wc4sm_calculate_calibrated_performance(model,{peak},pixel);

            testCase.verifyEqual(result.CenterWavelength_nm,302,'AbsTol',1e-10);
            testCase.verifyEqual(result.FWHM_nm,0.4*peak.FWHM,'AbsTol',1e-10);
            testCase.verifyEqual(result.ERW_nm,0.4*peak.ERW,'AbsTol',1e-10);
        end

        function nonlinearFwhmUsesBothHalfHeightCoordinates(testCase)
            pixel = (0:10).';
            wavelength = 280+0.3*pixel+0.002*pixel.^2;
            model = wc4sm_fit_calibration(pixel([1 4 8 11]), ...
                wavelength([1 4 8 11]),2,pixel,'Test',{});
            peak = TestCalibratedPerformanceModule.simplePeak(5,4,6);
            result = wc4sm_calculate_calibrated_performance(model,{peak},pixel);
            expected = polyval(model.Coefficients,6,[],model.Mu)- ...
                polyval(model.Coefficients,4,[],model.Mu);
            testCase.verifyEqual(result.FWHM_nm,expected,'AbsTol',1e-12);
        end

        function sortsPeaksAndPreservesSourceIndex(testCase)
            pixel = (0:10).';
            model = wc4sm_fit_calibration([0;5;10],[300;302;304],1, ...
                pixel,'Test',{});
            high = TestCalibratedPerformanceModule.simplePeak(8,7,9);
            low = TestCalibratedPerformanceModule.simplePeak(2,1,3);
            result = wc4sm_calculate_calibrated_performance( ...
                model,{high;low},pixel);
            testCase.verifyEqual(result.SourceIndex,[2;1]);
            testCase.verifyEqual(result.CenterWavelength_nm,[300.8;303.2], ...
                'AbsTol',1e-10);
        end

        function linearPixelIntervalIsConstant(testCase)
            pixel = (0:20).';
            model = wc4sm_fit_calibration([0;10;20],[300;305;310],1, ...
                pixel,'Test',{});
            result = wc4sm_calculate_calibrated_performance(model,{},pixel);
            testCase.verifyEqual(result.PixelInterval_nm,0.5*ones(20,1), ...
                'AbsTol',1e-12);
            testCase.verifyEqual(result.PixelIntervalStatistics.Mean,0.5, ...
                'AbsTol',1e-12);
            testCase.verifyEqual(result.PixelIntervalStatistics.Count,20);
        end

        function incompletePeakProducesUnavailableWidths(testCase)
            pixel = (0:10).';
            model = wc4sm_fit_calibration([0;5;10],[300;302;304],1, ...
                pixel,'Test',{});
            peak = struct('CenterX',5,'LeftHalfX',NaN,'RightHalfX',NaN, ...
                'InterpolatedPeakY',NaN,'InterpX',[],'InterpNetY',[]);
            result = wc4sm_calculate_calibrated_performance(model,{peak},pixel);
            testCase.verifyTrue(isnan(result.FWHM_nm));
            testCase.verifyTrue(isnan(result.ERW_nm));
            testCase.verifyEqual(result.FWHMStatistics.Count,0);
        end

        function invalidInputsAreRejected(testCase)
            pixel = (0:10).';
            model = wc4sm_fit_calibration([0;5;10],[300;302;304],1, ...
                pixel,'Test',{});
            invalidModel = model; invalidModel.valid = false;
            testCase.verifyError(@() wc4sm_calculate_calibrated_performance( ...
                invalidModel,{},pixel),'WCC4SM:InvalidCalibrationModel');
            testCase.verifyError(@() wc4sm_calculate_calibrated_performance( ...
                model,{},[0;2;1]),'WCC4SM:InvalidPixelAxis');
        end
    end

    methods (Static, Access=private)
        function peak = simplePeak(center,leftHalf,rightHalf)
            dense = linspace(leftHalf,rightHalf,101).';
            signal = max(0,1-abs(dense-center)/(rightHalf-leftHalf));
            peak = struct('CenterX',center,'LeftHalfX',leftHalf, ...
                'RightHalfX',rightHalf,'InterpolatedPeakY',max(signal), ...
                'InterpX',dense,'InterpNetY',signal);
        end
    end
end
