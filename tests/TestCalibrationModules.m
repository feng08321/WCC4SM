classdef TestCalibrationModules < matlab.unittest.TestCase
    methods (Test)
        function exactCubicModel(testCase)
            pixel = (0:100:1000).';
            natural = [2e-8 -3e-5 0.42 285];
            wavelength = polyval(natural,pixel);
            evaluation = (0:1000).';
            model = wc4sm_fit_calibration(pixel,wavelength,3,evaluation, ...
                'Synthetic exact cubic',{});

            testCase.verifyTrue(model.valid);
            testCase.verifyEqual(model.Degree,3);
            testCase.verifyLessThan(model.MaxAbsResidual,1e-10);
            testCase.verifyLessThan(model.LOORMS,1e-9);
            testCase.verifyEqual(polyval(model.NaturalCoefficients,evaluation), ...
                polyval(model.Coefficients,evaluation,[],model.Mu),'AbsTol',1e-9);
        end

        function publishedDirectCase(testCase)
            [wavelength,direct,~,use] = TestCalibrationModules.paperData();
            model = wc4sm_fit_calibration(direct(use),wavelength(use),5, ...
                direct,'Direct peak',{});
            testCase.verifyEqual(model.STD,0.18339283,'AbsTol',1e-8);
            testCase.verifyEqual(model.PositionMethod,'Direct peak');
            testCase.verifySize(model.LOOResidual,[17 1]);
        end

        function publishedGaussianCase(testCase)
            [wavelength,~,gaussian,use] = TestCalibrationModules.paperData();
            model = wc4sm_fit_calibration(gaussian(use),wavelength(use),5, ...
                gaussian,'Gaussian fit',{});
            testCase.verifyEqual(model.STD,0.04569137,'AbsTol',1e-8);
            testCase.verifyGreaterThan(model.LOORMS,model.RMS);
        end

        function looMatchesIndependentCalculation(testCase)
            pixel = (0:6).';
            wavelength = 300+0.5*pixel+[0;0.01;-0.02;0.03;-0.01;0.02;-0.01];
            [coefficients,~,mu] = polyfit(pixel,wavelength,2);
            result = wc4sm_validate_calibration_loo(pixel,wavelength,2, ...
                coefficients,mu,pixel);

            expected = nan(size(pixel));
            for k = 1:numel(pixel)
                keep = true(size(pixel)); keep(k) = false;
                [c,~,m] = polyfit(pixel(keep),wavelength(keep),2);
                expected(k) = wavelength(k)-polyval(c,pixel(k),[],m);
            end
            testCase.verifyEqual(result.LOOResidual,expected,'AbsTol',1e-12);
            testCase.verifyEqual(result.LOORMS,sqrt(mean(expected.^2)), ...
                'AbsTol',1e-12);
        end

        function sortingPreservesPeakIdentity(testCase)
            pixel = [30;10;20;40];
            wavelength = 300+0.4*pixel;
            ids = {'P3';'P1';'P2';'P4'};
            model = wc4sm_fit_calibration(pixel,wavelength,1,pixel, ...
                'Direct peak',ids);
            testCase.verifyEqual(model.Pixel,[10;20;30;40]);
            testCase.verifyEqual(model.PeakID,{'P1';'P2';'P3';'P4'});
        end

        function invalidCalibrationInputsAreRejected(testCase)
            testCase.verifyError(@() wc4sm_fit_calibration( ...
                [1;2],[300;301],2,[],'Test',{}), ...
                'WCC4SM:InsufficientCalibrationPoints');
            testCase.verifyError(@() wc4sm_fit_calibration( ...
                [1;1;2],[300;301;302],1,[],'Test',{}), ...
                'WCC4SM:DuplicateCalibrationPixel');
        end
    end

    methods (Static, Access=private)
        function [wavelength,direct,gaussian,use] = paperData()
            wavelength=[313.16 334.15 365.06 404.66 435.72 546.07 578.01 696.54 706.72 727.29 738.40 750.82 763.51 772.38 794.82 801.08 811.09 826.45 841.81 852.14 912.30 922.45 965.79 1013.98].';
            direct=[120 168 239 327 397 642 713 976 998 1043 1069 1096 1124 1143 1194 1207 1230 1263 1298 1320 1454 1477 1573 1680].';
            gaussian=[120.26 168.07 238.47 327.13 396.59 642.05 713.12 975.67 998.46 1043.78 1068.33 1095.57 1124.15 1143.58 1193.48 1207.05 1229.95 1263.71 1297.83 1320.67 1454.54 1477.02 1573.57 1680.76].';
            excluded=[3 5 7 12 16 17 19]; use=true(size(wavelength)); use(excluded)=false;
        end
    end
end
