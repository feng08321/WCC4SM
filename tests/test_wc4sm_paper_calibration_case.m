function result = test_wc4sm_paper_calibration_case(showFigure)
%TEST_WC4SM_PAPER_CALIBRATION_CASE Reproduce the published 17-point case.
% Expected sample STD: direct ~=0.184 nm, Gaussian ~=0.0457 nm.
    if nargin<1, showFigure=true; end
    wavelength=[313.16 334.15 365.06 404.66 435.72 546.07 578.01 696.54 706.72 727.29 738.40 750.82 763.51 772.38 794.82 801.08 811.09 826.45 841.81 852.14 912.30 922.45 965.79 1013.98];
    direct=[120 168 239 327 397 642 713 976 998 1043 1069 1096 1124 1143 1194 1207 1230 1263 1298 1320 1454 1477 1573 1680];
    gauss=[120.26 168.07 238.47 327.13 396.59 642.05 713.12 975.67 998.46 1043.78 1068.33 1095.57 1124.15 1143.58 1193.48 1207.05 1229.95 1263.71 1297.83 1320.67 1454.54 1477.02 1573.57 1680.76];
    excluded=[3 5 7 12 16 17 19]; use=true(size(wavelength)); use(excluded)=false;
    [pd,~,mud]=polyfit(direct(use),wavelength(use),5); rd=wavelength(use)-polyval(pd,direct(use),[],mud);
    [pg,~,mug]=polyfit(gauss(use),wavelength(use),5); rg=wavelength(use)-polyval(pg,gauss(use),[],mug);
    result=struct('DirectSTD',std(rd),'GaussianSTD',std(rg),'DirectResidual',rd,'GaussianResidual',rg, ...
        'DirectCoefficients',pd,'DirectMu',mud,'GaussianCoefficients',pg,'GaussianMu',mug);
    fprintf('WC4SM published-case check\n');
    fprintf('Direct peak residual STD : %.8f nm (paper ~= 0.184 nm)\n',result.DirectSTD);
    fprintf('Gaussian residual STD    : %.8f nm (paper = 0.0457 nm)\n',result.GaussianSTD);
    assert(abs(result.DirectSTD-0.184)<0.003,'Direct-peak residual STD is outside expected tolerance.');
    assert(abs(result.GaussianSTD-0.0457)<0.001,'Gaussian residual STD is outside expected tolerance.');
    if showFigure
        figure('Name','WC4SM paper calibration regression test','Color','w');
        tiledlayout(1,2);
        nexttile; plot(wavelength(use),rd,'o-','LineWidth',1);hold on;yline(0);grid on;xlabel('Reference wavelength (nm)');ylabel('Residual (nm)');title(sprintf('Direct peak | STD %.4f nm',std(rd)));
        nexttile; plot(wavelength(use),rg,'o-','LineWidth',1);hold on;yline(0);grid on;xlabel('Reference wavelength (nm)');ylabel('Residual (nm)');title(sprintf('Gaussian peak | STD %.4f nm',std(rg)));
    end
end
