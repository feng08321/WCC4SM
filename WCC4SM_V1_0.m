function WCC4SM_V1_0
%WCC4SM_V1_0 Wavelength Characterization and Calibration for Spectrometer.
% Peak analysis plus reference-line matching and provisional calibration.
% MATLAB R2022a or later. Signal Processing Toolbox is required for findpeaks.

    packageRoot = fileparts(mfilename('fullpath'));
    distributionRoot = packageRoot;
    if isdeployed && ispc
        try
            process = System.Diagnostics.Process.GetCurrentProcess();
            distributionRoot = fileparts(char(process.MainModule.FileName));
        catch
            distributionRoot = pwd;
        end
    end
    addpath(fullfile(packageRoot,'src'));

    D = emptyData();
    R = emptyReference();
    peaks = emptyPeaks();
    peakDataset = emptyDataset();
    Lbasic = basicHgArLibrary();
    Lpaper = paper24HgArLibrary();
    Lnim = nimHgArLibrary();
    Lexternal = emptyLineLibrary();
    L = Lbasic;
    calPairs = emptyCalPairs();
    provisional = emptyInitialModel();
    matchingAxisMode = 'Pixel';
    mainAxisMode = 'Pixel';
    finalModel = emptyFinalModel();
    appliedModel = emptyFinalModel();
    appliedModelName = '';
    calibrationModels = emptyCalibrationModels();
    optimizationPath = struct();
    optimizationStability = struct();
    optimizationOrder = struct([]);
    influenceResult = struct();
    influenceOrderStats = struct([]);
    seedComboResult = struct();
    influenceViewMode = 'Point influence';
    optimizationViewMode = '';
    selectedResidualContext = struct('X',[],'Residual',[],'Label','','XAxisLabel','');
    selectedRow = 0;
    selectedDatasetRow = 0;
    selectedRefRow = 0;
    selectedPairRow = 0;
    selectedValidationRow = 0;
    positionCrossResult = struct();
    selectedPositionCrossRow = 1;
    selectedPositionCrossColumn = 1;
    positionCrossBusy = false;
    paperPeakDifferenceExcludedIDs = {};
    paperPeakAllExcludedIDs = {};
    paperPeakDifferenceSelectedID = '';
    paperPeakDifferenceResult = struct();
    paperPeakPairArchive = emptyCalPairs();
    paperPeakAllSelectedRows = [];
    paperPeakCalibrationSelectedRows = [];
    selectedModelRow = 0;
    selectedSeedRound = 0;
    pendingSeedModelItem = struct();
    subsetDesignProfile = struct();
    subsetBeamState = struct();
    subsetDesignCandidates = struct([]);
    selectedSubsetCandidate = 0;
    subsetWindowPartition = struct();
    windowInfluenceDegree = 3;
    windowSelectedMask = [];
    localCandidates = emptyLocalCandidates();
    selectedLocalCandidate = 0;
    localSearchWindow = [NaN NaN];
    referenceResolutionNm = 3;
    symmetryThresholdPx = 0.2;
    sessionMetadata = struct();
    currentSessionPath = '';
    C = colors();
    referenceDataDir = fullfile(distributionRoot,'reference_data');
    if ~isfolder(referenceDataDir), referenceDataDir = fullfile(packageRoot,'reference_data'); end
    documentationDir = fullfile(distributionRoot,'docs');
    if ~isfolder(documentationDir), documentationDir = fullfile(packageRoot,'docs'); end

    fig=uifigure('Name','WCC4SM V1.0 | Peak Analysis','Position',[25 30 1580 900],'Color',C.bg);
    root=uigridlayout(fig,[2 3]); root.RowHeight={50,'1x'}; root.ColumnWidth={330,'1x',400};
    root.ColumnWidth={'1x',330,400};
    root.Padding=[10 9 10 10]; root.RowSpacing=8; root.ColumnSpacing=8;

    head=uipanel(root,'BackgroundColor',C.bg,'BorderType','none'); head.Layout.Row=1; head.Layout.Column=[1 3];
    hg=uigridlayout(head,[1 2]); hg.ColumnWidth={'1x',760}; hg.Padding=[14 5 14 5]; hg.BackgroundColor=C.bg;
    uilabel(hg,'Text','WCC4SM (Wavelength Characterization and Calibration for Spectrometer) V1.0', ...
        'FontSize',16,'FontWeight','bold','FontColor',C.blue,'HorizontalAlignment','left');
    headerTools=uigridlayout(hg,[1 6]);headerTools.ColumnWidth={175,85,110,110,75,'1x'};headerTools.Padding=[0 0 0 0];headerTools.ColumnSpacing=5;headerTools.BackgroundColor=C.bg;
    openFigDrop=uidropdown(headerTools,'Items',{'Peak Analysis','Peak Parameter Statistics','Wavelength Matching', ...
        'Calibration Fit & Residuals','Model Validation','Model Comparison','Selected Residuals','Calibrated Performance','Calibration Optimization','Point Influence','Set Design'}, ...
        'Value','Peak Analysis','Tooltip','Choose a plot tab whose subplots will be opened as separate editable figures');
    uibutton(headerTools,'Text','OPEN FIG','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@openSelectedTabFigures);
    uibutton(headerTools,'Text','SAVE SESSION','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@saveSession);
    uibutton(headerTools,'Text','LOAD SESSION','FontWeight','bold','BackgroundColor',C.yellow,'ButtonPushedFcn',@loadSession);
    uibutton(headerTools,'Text','HELP','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@openHelpDialog);
    topStatus=uilabel(headerTools,'Text','Load a spectrum','FontWeight','bold','FontColor',C.navy,'BackgroundColor',C.bg,'HorizontalAlignment','left','Tooltip','Current workflow status');

    %% LEFT CONTROL COLUMN
    leftTabs=uitabgroup(root); leftTabs.Layout.Row=2; leftTabs.Layout.Column=2;
    tabDataDisplay=uitab(leftTabs,'Title','Data & Display'); tabDetection=uitab(leftTabs,'Title','Peak Detection');tabCurrent=uitab(leftTabs,'Title','Current Peak');tabReference=uitab(leftTabs,'Title','Reference Lines');

    dg=uigridlayout(tabDataDisplay,[19 2]); dg.ColumnWidth={135,'1x'};
    dg.RowHeight={32,32,24,30,30,30,24,30,30,38,30,30,30,30,30,24,34,54,24}; dg.Padding=[9 8 9 9]; dg.RowSpacing=6;
    bLoad=uibutton(dg,'Text','Load spectrum CSV','ButtonPushedFcn',@loadSpectrum); bLoad.Layout.Column=[1 2];
    bRef=uibutton(dg,'Text','Pop out current spectrum plots','ButtonPushedFcn',@popOutSpectrumPlots); bRef.Layout.Column=[1 2];
    sectionAuto(dg,'Input interpretation');
    uilabel(dg,'Text','Two-column X'); inputType=uidropdown(dg,'Items',{'Wavelength (nm)','Pixel index'},'Value','Wavelength (nm)');
    uilabel(dg,'Text','Pixel sequence'); pixelMode=uidropdown(dg, ...
        'Items',{'Full detector sequence','Valid-pixel sequence'}, ...
        'Value','Full detector sequence', ...
        'ValueChangedFcn',@pixelModeChanged, ...
        'Tooltip','Full detector: uncalibrated instrument exposes every detector pixel. Valid-pixel: calibrated instrument outputs only its usable cropped sequence. Both sequences start at 1.');
    sourceLabel=uilabel(dg,'Text','No spectrum','FontColor',C.muted); sourceLabel.Layout.Column=[1 2];
    sectionAuto(dg,'Preprocessing & display');
    uilabel(dg,'Text','Manual baseline'); baselineField=uieditfield(dg,'numeric','Value',0,'ValueChangedFcn',@preprocessChanged);
    darkTools=uigridlayout(dg,[1 2]);darkTools.Layout.Column=[1 2];darkTools.ColumnWidth={'1x','1x'};darkTools.Padding=[0 0 0 0];
    uibutton(darkTools,'Text','Load dark spectrum','ButtonPushedFcn',@loadDarkSpectrum);
    clearDarkBtn=uibutton(darkTools,'Text','Clear dark','ButtonPushedFcn',@clearDarkSpectrum,'Enable','off');
    darkStatus=uilabel(dg,'Text','Dark: none (manual constant baseline is active)','FontColor',C.muted,'WordWrap','on');darkStatus.Layout.Column=[1 2];
    clampCheck=uicheckbox(dg,'Text','Set negative values to zero','Value',true,'ValueChangedFcn',@preprocessChanged); clampCheck.Layout.Column=[1 2];
    uilabel(dg,'Text','Display signal'); displayDrop=uidropdown(dg,'Items',{'Corrected AD counts','Normalized','Raw AD counts'},'Value','Corrected AD counts','ValueChangedFcn',@displayChanged);
    uilabel(dg,'Text','Y scale'); scaleDrop=uidropdown(dg,'Items',{'Linear','Log'},'Value','Linear','ValueChangedFcn',@displayChanged);
    uilabel(dg,'Text','X axis'); axisButton=uibutton(dg,'Text','X Axis: Pixel  <->','ButtonPushedFcn',@toggleMainAxis);
    refCheck=uicheckbox(dg,'Text','Show detected peak markers','Value',true,'ValueChangedFcn',@displayChanged); refCheck.Layout.Column=[1 2];
    sectionAuto(dg,'Weak-peak subwindow search');
    localSearchBtn=uibutton(dg,'Text','OPEN SUBWINDOW SEARCH','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@openLocalSearchDialog);localSearchBtn.Layout.Column=[1 2];
    viewPanel=uipanel(dg,'Title','Full-spectrum view range','FontWeight','bold'); viewPanel.Layout.Column=[1 2];
    viewGrid=uigridlayout(viewPanel,[1 5]);viewGrid.ColumnWidth={55,'1x',45,'1x',90};viewGrid.RowHeight={25};viewGrid.Padding=[3 2 3 2];
    uilabel(viewGrid,'Text','Start X');fullViewStart=uieditfield(viewGrid,'numeric','Value',0,'ValueChangedFcn',@fullViewChanged);
    uilabel(viewGrid,'Text','End X');fullViewEnd=uieditfield(viewGrid,'numeric','Value',2000,'ValueChangedFcn',@fullViewChanged);
    uibutton(viewGrid,'Text','RESET RANGE','ButtonPushedFcn',@resetFullViewRange);
    showMatchingCheck=uicheckbox(dg,'Text','Show matching annotations','Value',true,'ValueChangedFcn',@displayChanged);showMatchingCheck.Layout.Column=[1 2];

    pg=uigridlayout(tabDetection,[16 2]); pg.ColumnWidth={135,'1x'};
    pg.RowHeight={24,30,30,30,30,30,30,32,36,24,30,30,30,30,30,'1x'}; pg.Padding=[9 8 9 9]; pg.RowSpacing=6;
    sectionAuto(pg,'findpeaks parameters');
    normalizedSearch=uicheckbox(pg,'Text','Search normalized signal','Value',true,'ValueChangedFcn',@markDetectionPending); normalizedSearch.Layout.Column=[1 2];
    uilabel(pg,'Text','Min peak height'); minHeight=uieditfield(pg,'numeric','Value',0.02,'Limits',[0 Inf],'ValueChangedFcn',@markDetectionPending);
    uilabel(pg,'Text','Min prominence'); minProm=uieditfield(pg,'numeric','Value',0.005,'Limits',[0 Inf],'ValueChangedFcn',@markDetectionPending);
    uilabel(pg,'Text','Min distance (px)'); minDist=uispinner(pg,'Limits',[1 10000],'Step',1,'Value',3,'ValueChangedFcn',@markDetectionPending);
    uilabel(pg,'Text','Min width (px)'); minWidth=uieditfield(pg,'numeric','Value',0,'Limits',[0 Inf],'ValueChangedFcn',@markDetectionPending);
    uilabel(pg,'Text','Max width (px)'); maxWidth=uieditfield(pg,'numeric','Value',Inf,'Limits',[0 Inf],'ValueChangedFcn',@markDetectionPending);
    findHelp=uilabel(pg,'Text','Set parameters first. Detection runs only after pressing the button below.', ...
        'WordWrap','on','FontColor',C.muted); findHelp.Layout.Column=[1 2];
    detectBtn=uibutton(pg,'Text','CONFIRM & DETECT ALL PEAKS','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@detectPeaks); detectBtn.Layout.Column=[1 2];
    sectionAuto(pg,'Selected peak window');
    uilabel(pg,'Text','Left pixels'); leftSpin=uispinner(pg,'Limits',[1 5000],'Step',1,'Value',5,'ValueChangedFcn',@windowChanged);
    uilabel(pg,'Text','Right pixels'); rightSpin=uispinner(pg,'Limits',[1 5000],'Step',1,'Value',5,'ValueChangedFcn',@windowChanged);
    uilabel(pg,'Text','Interpolation'); methodDrop=uidropdown(pg, ...
        'Items',{'PCHIP (recommended)','Linear (comparison)','Spline (research)'}, ...
        'ItemsData',{'pchip','linear','spline'},'Value','pchip', ...
        'ValueChangedFcn',@windowChanged);
    uilabel(pg,'Text','Factor'); factorSpin=uispinner(pg,'Limits',[1 500],'Step',1,'Value',20,'ValueChangedFcn',@windowChanged);
    detectInfo=uilabel(pg,'Text','Detected: 0 | Dataset: 0','FontColor',C.muted,'WordWrap','on'); detectInfo.Layout.Column=[1 2];
    windowPanel=uipanel(pg,'Title','Wavelength matching windows','FontWeight','bold');windowPanel.Layout.Column=[1 2];
    wg=uigridlayout(windowPanel,[7 2]);wg.ColumnWidth={125,'1x'};wg.RowHeight={25,25,25,25,30,30,'1x'};wg.Padding=[5 3 5 5];
    uilabel(wg,'Text','Start pixel'); pixelViewStart=uieditfield(wg,'numeric','Value',0,'ValueChangedFcn',@localWindowChanged);
    uilabel(wg,'Text','End pixel'); pixelViewEnd=uieditfield(wg,'numeric','Value',2000,'ValueChangedFcn',@localWindowChanged);
    uilabel(wg,'Text','Start wavelength'); wavelengthViewStart=uieditfield(wg,'numeric','Value',300,'ValueChangedFcn',@localWindowChanged);
    uilabel(wg,'Text','End wavelength'); wavelengthViewEnd=uieditfield(wg,'numeric','Value',450,'ValueChangedFcn',@localWindowChanged);
    localNav=uigridlayout(wg,[1 4]);localNav.Layout.Column=[1 2];localNav.ColumnWidth={'1x','1x','1x','1x'};localNav.Padding=[0 0 0 0];
    uibutton(localNav,'Text','< Seg','ButtonPushedFcn',@previousLocalSegment);uibutton(localNav,'Text','Seg >','ButtonPushedFcn',@nextLocalSegment);
    uibutton(localNav,'Text','Zoom +','ButtonPushedFcn',@zoomLocalIn);uibutton(localNav,'Text','Zoom -','ButtonPushedFcn',@zoomLocalOut);
    refNav=uigridlayout(wg,[1 3]);refNav.Layout.Column=[1 2];refNav.ColumnWidth={'1x','1x','1x'};refNav.Padding=[0 0 0 0];
    uibutton(refNav,'Text','Ref <','ButtonPushedFcn',@shiftReferenceLeft);
    matchingViewBtn=uibutton(refNav,'Text','Open / Refresh','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@showCalibrationView);
    uibutton(refNav,'Text','Ref >','ButtonPushedFcn',@shiftReferenceRight);

    %% CENTER PLOTS
    plotTabs=uitabgroup(root);plotTabs.Layout.Row=2;plotTabs.Layout.Column=1;
    tabPlots=uitab(plotTabs,'Title','Peak Analysis');tabPeakStatistics=uitab(plotTabs,'Title','Peak Parameter Statistics');tabMatchingPlots=uitab(plotTabs,'Title','Wavelength Matching');tabResults=uitab(plotTabs,'Title','Calibration Fit & Residuals');tabValidation=uitab(plotTabs,'Title','Model Validation');tabModelCompare=uitab(plotTabs,'Title','Model Comparison');tabSelectedResidual=uitab(plotTabs,'Title','Selected Residuals');tabCalibratedStatistics=uitab(plotTabs,'Title','Calibrated Performance');tabOptimization=uitab(plotTabs,'Title','Calibration Optimization');tabInfluence=uitab(plotTabs,'Title','Point Influence');tabSetDesign=uitab(plotTabs,'Title','Set Design');
    plotHost=uigridlayout(tabPlots,[1 1]);plotHost.Padding=[0 0 0 0];
    peakAnalysisTabs=uitabgroup(plotHost,'SelectionChangedFcn',@peakAnalysisTabChanged);
    peakAnalysisCurrentTab=uitab(peakAnalysisTabs,'Title','Current spectrum and selected peak');
    peakGalleryTab=uitab(peakAnalysisTabs,'Title','8x8 peak-shape gallery');
    currentPeakHost=uigridlayout(peakAnalysisCurrentTab,[1 1]);currentPeakHost.Padding=[0 0 0 0];
    middle=uipanel(currentPeakHost,'Title','Measured spectrum / Selected peak','FontWeight','bold','BackgroundColor','white');
    mg=uigridlayout(middle,[2 1]); mg.RowHeight={'1.2x','1x'}; mg.Padding=[7 4 7 7];
    axFull=uiaxes(mg); styleAxes(axFull,C); title(axFull,'Full spectrum');
    axPeak=uiaxes(mg); styleAxes(axPeak,C); title(axPeak,'Select a peak from the list');
    peakGalleryHost=uigridlayout(peakGalleryTab,[2 1]);peakGalleryHost.RowHeight={32,'1x'};peakGalleryHost.Padding=[5 5 5 5];peakGalleryHost.RowSpacing=3;
    peakGalleryTools=uigridlayout(peakGalleryHost,[1 3]);peakGalleryTools.ColumnWidth={100,'1x',220};peakGalleryTools.Padding=[0 0 0 0];peakGalleryTools.ColumnSpacing=6;
    peakGalleryRefresh=uibutton(peakGalleryTools,'Text','Refresh gallery','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@refreshPeakGallery);peakGalleryRefresh.Layout.Column=1;
    peakGalleryStatus=uilabel(peakGalleryTools,'Text','Run batch pre-analysis to populate all detected-peak windows.','FontColor',C.navy);peakGalleryStatus.Layout.Column=2;
    peakGalleryLegend=uilabel(peakGalleryTools,'Text','Blue: matched benchmark   Red: not selected','HorizontalAlignment','right','FontColor',C.muted);peakGalleryLegend.Layout.Column=3;
    peakGalleryGrid=uigridlayout(peakGalleryHost,[8 8]);peakGalleryGrid.Layout.Row=2;peakGalleryGrid.RowHeight=repmat({'1x'},1,8);peakGalleryGrid.ColumnWidth=repmat({'1x'},1,8);peakGalleryGrid.Padding=[2 2 2 2];peakGalleryGrid.RowSpacing=2;peakGalleryGrid.ColumnSpacing=2;
    peakGalleryAxes=gobjects(0);

    peakStatisticsOuterHost=uigridlayout(tabPeakStatistics,[1 1]);peakStatisticsOuterHost.Padding=[0 0 0 0];
    peakStatisticsTabs=uitabgroup(peakStatisticsOuterHost);
    peakStatisticsOverviewTab=uitab(peakStatisticsTabs,'Title','Overview');
    peakPositionDifferenceTab=uitab(peakStatisticsTabs,'Title','Peak Position Differences');
    statsHost=uigridlayout(peakStatisticsOverviewTab,[2 2]);statsHost.RowHeight={'1x','1x'};statsHost.ColumnWidth={'1x','1x'};statsHost.Padding=[7 7 7 7];
    axWidthTrend=uiaxes(statsHost);styleAxes(axWidthTrend,C);title(axWidthTrend,'FWHM and ERW versus confirmed peak position');
    axWidthRelation=uiaxes(statsHost);styleAxes(axWidthRelation,C);title(axWidthRelation,'FWHM versus ERW');
    axPositionDelta=uiaxes(statsHost);styleAxes(axPositionDelta,C);title(axPositionDelta,'Peak-position differences from FWHM center');
    axPositionHistogram=uiaxes(statsHost);styleAxes(axPositionHistogram,C);title(axPositionHistogram,'Peak-position-difference histograms');

    peakDifferenceHost=uigridlayout(peakPositionDifferenceTab,[2 1]);peakDifferenceHost.RowHeight={64,'1x'};peakDifferenceHost.Padding=[7 7 7 7];peakDifferenceHost.RowSpacing=4;
    peakDifferenceTools=uigridlayout(peakDifferenceHost,[2 8]);peakDifferenceTools.ColumnWidth={85,145,70,145,70,190,'1x',1};peakDifferenceTools.RowHeight={28,28};peakDifferenceTools.Padding=[0 0 0 0];peakDifferenceTools.ColumnSpacing=5;peakDifferenceTools.RowSpacing=4;
    differenceUnitLabel=uilabel(peakDifferenceTools,'Text','Difference unit','HorizontalAlignment','right');differenceUnitLabel.Layout.Row=1;differenceUnitLabel.Layout.Column=1;
    peakDifferenceUnit=uidropdown(peakDifferenceTools,'Items',{'Pixel difference','Wavelength difference'},'Value','Pixel difference','ValueChangedFcn',@peakDifferenceDisplayChanged);peakDifferenceUnit.Layout.Row=1;peakDifferenceUnit.Layout.Column=2;
    peakDifferenceXLabel=uilabel(peakDifferenceTools,'Text','Plot 1 X','HorizontalAlignment','right');peakDifferenceXLabel.Layout.Row=1;peakDifferenceXLabel.Layout.Column=3;
    peakDifferenceXMode=uidropdown(peakDifferenceTools,'Items',{'Center wavelength','Center pixel'},'Value','Center wavelength','ValueChangedFcn',@peakDifferenceDisplayChanged);peakDifferenceXMode.Layout.Row=1;peakDifferenceXMode.Layout.Column=4;
    peakDifferenceSeriesLabel=uilabel(peakDifferenceTools,'Text','Difference series','HorizontalAlignment','right');peakDifferenceSeriesLabel.Layout.Row=1;peakDifferenceSeriesLabel.Layout.Column=5;
    peakDifferenceSeries=uidropdown(peakDifferenceTools,'Items',{'Direct - center','Centroid - center','Interpolated - center'},'Value','Centroid - center','ValueChangedFcn',@peakDifferenceDisplayChanged);peakDifferenceSeries.Layout.Row=1;peakDifferenceSeries.Layout.Column=6;
    peakDifferenceFitLabel=uilabel(peakDifferenceTools,'Text','Fit target','HorizontalAlignment','right');peakDifferenceFitLabel.Layout.Row=2;peakDifferenceFitLabel.Layout.Column=1;
    peakDifferenceFitTarget=uidropdown(peakDifferenceTools,'Items',{'Direct peak','Centroid','Interpolated peak'},'Value','Centroid','ValueChangedFcn',@peakDifferenceDisplayChanged);peakDifferenceFitTarget.Layout.Row=2;peakDifferenceFitTarget.Layout.Column=2;
    peakDifferenceOrderLabel=uilabel(peakDifferenceTools,'Text','Fit order','HorizontalAlignment','right');peakDifferenceOrderLabel.Layout.Row=2;peakDifferenceOrderLabel.Layout.Column=3;
    peakDifferenceFitOrder=uidropdown(peakDifferenceTools,'Items',{'No fit','Degree 1','Degree 2','Degree 3'},'Value','Degree 1','ValueChangedFcn',@peakDifferenceDisplayChanged);peakDifferenceFitOrder.Layout.Row=2;peakDifferenceFitOrder.Layout.Column=4;
    peakDifferenceStatus=uilabel(peakDifferenceTools,'Text','Confirm peak parameters, then refresh statistics.','FontColor',C.muted);peakDifferenceStatus.Layout.Row=[1 2];peakDifferenceStatus.Layout.Column=7;
    peakDifferenceCharts=uigridlayout(peakDifferenceHost,[2 2]);peakDifferenceCharts.RowHeight={'1x','1x'};peakDifferenceCharts.ColumnWidth={'1x','1x'};peakDifferenceCharts.Padding=[0 0 0 0];peakDifferenceCharts.RowSpacing=4;peakDifferenceCharts.ColumnSpacing=4;
    axPeakDifferenceMap=uiaxes(peakDifferenceCharts);styleAxes(axPeakDifferenceMap,C);title(axPeakDifferenceMap,'Peak-position differences versus coordinate');
    axPeakDifferenceFit=uiaxes(peakDifferenceCharts);styleAxes(axPeakDifferenceFit,C);title(axPeakDifferenceFit,'Peak-position mapping fit');
    peakDifferenceDistributionHost=uigridlayout(peakDifferenceCharts,[2 1]);peakDifferenceDistributionHost.RowHeight={'1x',30};peakDifferenceDistributionHost.Padding=[0 0 0 0];peakDifferenceDistributionHost.RowSpacing=3;
    axPeakDifferenceDistribution=uiaxes(peakDifferenceDistributionHost);styleAxes(axPeakDifferenceDistribution,C);title(axPeakDifferenceDistribution,'Peak-position-difference distribution');
    peakDifferenceDistributionTools=uigridlayout(peakDifferenceDistributionHost,[1 8]);peakDifferenceDistributionTools.ColumnWidth={30,45,36,60,36,60,82,58};peakDifferenceDistributionTools.Padding=[0 0 0 0];peakDifferenceDistributionTools.ColumnSpacing=3;
    uilabel(peakDifferenceDistributionTools,'Text','Bins');peakDifferenceDistributionBinCount=uispinner(peakDifferenceDistributionTools,'Limits',[1 100],'Step',1,'Value',8,'ValueChangedFcn',@peakDifferenceDisplayChanged);
    uilabel(peakDifferenceDistributionTools,'Text','X min');peakDifferenceDistributionXMin=uieditfield(peakDifferenceDistributionTools,'numeric','Value',-0.1,'ValueChangedFcn',@peakDifferenceDisplayChanged);
    uilabel(peakDifferenceDistributionTools,'Text','X max');peakDifferenceDistributionXMax=uieditfield(peakDifferenceDistributionTools,'numeric','Value',0.1,'ValueChangedFcn',@peakDifferenceDisplayChanged);
    peakDifferenceDistributionRangeMode=uidropdown(peakDifferenceDistributionTools,'Items',{'Auto full','Symmetric','+/-3 STD','Manual'},'Value','Auto full','ValueChangedFcn',@peakDifferenceDisplayChanged);
    uibutton(peakDifferenceDistributionTools,'Text','Refresh','ButtonPushedFcn',@peakDifferenceDisplayChanged);
    peakDifferenceHistHost=uigridlayout(peakDifferenceCharts,[2 1]);peakDifferenceHistHost.RowHeight={'1x',30};peakDifferenceHistHost.Padding=[0 0 0 0];peakDifferenceHistHost.RowSpacing=3;
    axPeakDifferenceHistogram=uiaxes(peakDifferenceHistHost);styleAxes(axPeakDifferenceHistogram,C);title(axPeakDifferenceHistogram,'Linear-fit residual histogram');
    peakDifferenceHistControls=uigridlayout(peakDifferenceHistHost,[1 9]);peakDifferenceHistControls.ColumnWidth={32,48,40,62,40,62,80,62,'1x'};peakDifferenceHistControls.Padding=[0 0 0 0];peakDifferenceHistControls.ColumnSpacing=3;
    uilabel(peakDifferenceHistControls,'Text','Bins');peakDifferenceHistBinCount=uispinner(peakDifferenceHistControls,'Limits',[1 100],'Step',1,'Value',8,'ValueChangedFcn',@peakDifferenceHistogramChanged);
    uilabel(peakDifferenceHistControls,'Text','X min');peakDifferenceHistXMin=uieditfield(peakDifferenceHistControls,'numeric','Value',-0.1,'ValueChangedFcn',@peakDifferenceHistogramChanged);
    uilabel(peakDifferenceHistControls,'Text','X max');peakDifferenceHistXMax=uieditfield(peakDifferenceHistControls,'numeric','Value',0.1,'ValueChangedFcn',@peakDifferenceHistogramChanged);
    peakDifferenceHistRangeMode=uidropdown(peakDifferenceHistControls,'Items',{'Auto full','Symmetric','+/-3 STD','Manual'},'Value','Auto full','ValueChangedFcn',@peakDifferenceHistogramChanged);
    uibutton(peakDifferenceHistControls,'Text','Refresh','ButtonPushedFcn',@peakDifferenceHistogramChanged);

    calibratedStatsRoot=uigridlayout(tabCalibratedStatistics,[1 1]);calibratedStatsRoot.Padding=[0 0 0 0];
    calibratedStatsTabs=uitabgroup(calibratedStatsRoot);
    calibratedOverviewTab=uitab(calibratedStatsTabs,'Title','Wavelength-domain performance');
    paperPeakDifferenceTab=uitab(calibratedStatsTabs,'Title','Peak-position wavelength dependence');
    calibratedStatsHost=uigridlayout(calibratedOverviewTab,[2 2]);calibratedStatsHost.RowHeight={'1x','1x'};calibratedStatsHost.ColumnWidth={'1x','1x'};calibratedStatsHost.Padding=[7 7 7 7];
    axCalWidthTrend=uiaxes(calibratedStatsHost);styleAxes(axCalWidthTrend,C);title(axCalWidthTrend,'Spectral resolution versus wavelength');
    axCalWidthRelation=uiaxes(calibratedStatsHost);styleAxes(axCalWidthRelation,C);title(axCalWidthRelation,'FWHM versus ERW in wavelength domain');
    fwhmHistHost=uigridlayout(calibratedStatsHost,[2 1]);fwhmHistHost.Layout.Row=2;fwhmHistHost.Layout.Column=1;
    fwhmHistHost.RowHeight={'1x',30};fwhmHistHost.Padding=[0 0 0 0];fwhmHistHost.RowSpacing=3;
    axCalPositionDelta=uiaxes(fwhmHistHost);styleAxes(axCalPositionDelta,C);title(axCalPositionDelta,'FWHM distribution');
    fwhmHistControls=uigridlayout(fwhmHistHost,[1 10]);
    fwhmHistControls.ColumnWidth={34,48,42,64,42,64,82,62,'1x',1};fwhmHistControls.Padding=[0 0 0 0];fwhmHistControls.ColumnSpacing=4;
    uilabel(fwhmHistControls,'Text','Bins');
    fwhmHistBinCount=uispinner(fwhmHistControls,'Limits',[1 100],'Step',1,'Value',8,'ValueChangedFcn',@fwhmHistogramControlsChanged);
    uilabel(fwhmHistControls,'Text','X min');
    fwhmHistXMin=uieditfield(fwhmHistControls,'numeric','Value',0.7,'ValueChangedFcn',@fwhmHistogramControlsChanged);
    uilabel(fwhmHistControls,'Text','X max');
    fwhmHistXMax=uieditfield(fwhmHistControls,'numeric','Value',1.5,'ValueChangedFcn',@fwhmHistogramControlsChanged);
    fwhmHistRangeMode=uidropdown(fwhmHistControls,'Items',{'Auto full','Manual'},'Value','Auto full','ValueChangedFcn',@fwhmHistogramControlsChanged);
    uibutton(fwhmHistControls,'Text','Refresh','ButtonPushedFcn',@fwhmHistogramControlsChanged);
    axPixelInterval=uiaxes(calibratedStatsHost);axPixelInterval.Layout.Row=2;axPixelInterval.Layout.Column=2;
    styleAxes(axPixelInterval,C);title(axPixelInterval,'Pixel wavelength interval');

    paperPeakDifferenceGrid=uigridlayout(paperPeakDifferenceTab,[3 2]);
    paperPeakDifferenceGrid.RowHeight={88,'1x','1x'};paperPeakDifferenceGrid.ColumnWidth={'1x','1x'};
    paperPeakDifferenceGrid.Padding=[7 7 7 7];paperPeakDifferenceGrid.RowSpacing=4;paperPeakDifferenceGrid.ColumnSpacing=5;
    paperPeakDifferenceTools=uigridlayout(paperPeakDifferenceGrid,[3 8]);paperPeakDifferenceTools.Layout.Row=1;paperPeakDifferenceTools.Layout.Column=[1 2];
    paperPeakDifferenceTools.RowHeight={26,26,26};paperPeakDifferenceTools.ColumnWidth={82,72,118,78,82,82,108,'1x'};
    paperPeakDifferenceTools.Padding=[0 0 0 0];paperPeakDifferenceTools.ColumnSpacing=4;paperPeakDifferenceTools.RowSpacing=4;
    paperPeakDifferenceRefresh=uibutton(paperPeakDifferenceTools,'Text','Refresh data','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@refreshPaperPeakDifference);paperPeakDifferenceRefresh.Layout.Row=1;paperPeakDifferenceRefresh.Layout.Column=1;
    paperPeakDifferenceFitLabel=uilabel(paperPeakDifferenceTools,'Text','Fit series','HorizontalAlignment','right');paperPeakDifferenceFitLabel.Layout.Row=1;paperPeakDifferenceFitLabel.Layout.Column=2;
    paperPeakDifferenceFitSeries=uidropdown(paperPeakDifferenceTools,'Items',{'Direct - FWHM center','Interpolated - FWHM center','Centroid - FWHM center'}, ...
        'Value','Centroid - FWHM center','ValueChangedFcn',@paperPeakDifferenceFitChanged);paperPeakDifferenceFitSeries.Layout.Row=1;paperPeakDifferenceFitSeries.Layout.Column=3;
    paperPeakDifferenceFitOrder=uidropdown(paperPeakDifferenceTools,'Items',{'No fit','Degree 1','Degree 2','Degree 3'},'Value','Degree 1','ValueChangedFcn',@paperPeakDifferenceFitChanged);paperPeakDifferenceFitOrder.Layout.Row=1;paperPeakDifferenceFitOrder.Layout.Column=4;
    paperPeakDifferenceRestore=uibutton(paperPeakDifferenceTools,'Text','Restore all','ButtonPushedFcn',@restorePaperPeakDifferenceRows);paperPeakDifferenceRestore.Layout.Row=1;paperPeakDifferenceRestore.Layout.Column=5;
    paperPeakDifferenceExport=uibutton(paperPeakDifferenceTools,'Text','Export CSV','ButtonPushedFcn',@exportPaperPeakDifferenceTable);paperPeakDifferenceExport.Layout.Row=1;paperPeakDifferenceExport.Layout.Column=6;
    paperPeakDifferenceGuide=uilabel(paperPeakDifferenceTools,'Text','Tables and confirmed add/delete actions are in the right-side dataset tab.','WordWrap','on','FontColor',C.muted);paperPeakDifferenceGuide.Layout.Row=1;paperPeakDifferenceGuide.Layout.Column=[7 8];
    paperShowDirect=uicheckbox(paperPeakDifferenceTools,'Text','Direct - center','Value',true,'ValueChangedFcn',@paperPeakSeriesChanged);paperShowDirect.Layout.Row=2;paperShowDirect.Layout.Column=[1 2];
    paperShowInterpolated=uicheckbox(paperPeakDifferenceTools,'Text','Interpolated - center','Value',true,'ValueChangedFcn',@paperPeakSeriesChanged);paperShowInterpolated.Layout.Row=2;paperShowInterpolated.Layout.Column=[3 4];
    paperShowCentroid=uicheckbox(paperPeakDifferenceTools,'Text','Centroid - center','Value',true,'ValueChangedFcn',@paperPeakSeriesChanged);paperShowCentroid.Layout.Row=2;paperShowCentroid.Layout.Column=[5 6];
    paperShowCalibrationOnly=uicheckbox(paperPeakDifferenceTools,'Text','Calibration set only','Value',false,'ValueChangedFcn',@paperPeakSeriesChanged);paperShowCalibrationOnly.Layout.Row=2;paperShowCalibrationOnly.Layout.Column=7;
    paperClearHighlight=uibutton(paperPeakDifferenceTools,'Text','Clear highlight','ButtonPushedFcn',@clearPaperPeakHighlight);paperClearHighlight.Layout.Row=2;paperClearHighlight.Layout.Column=8;
    paperPeakDifferenceStatus=uilabel(paperPeakDifferenceTools,'Text','Fit a final calibration model, then refresh.','FontColor',C.navy,'WordWrap','on');paperPeakDifferenceStatus.Layout.Row=3;paperPeakDifferenceStatus.Layout.Column=[1 8];
    axPaperAllPeakDifferences=uiaxes(paperPeakDifferenceGrid);axPaperAllPeakDifferences.Layout.Row=2;axPaperAllPeakDifferences.Layout.Column=[1 2];styleAxes(axPaperAllPeakDifferences,C);title(axPaperAllPeakDifferences,'All detected-peak position differences');
    axPaperCentroidDifference=uiaxes(paperPeakDifferenceGrid);axPaperCentroidDifference.Layout.Row=3;axPaperCentroidDifference.Layout.Column=[1 2];styleAxes(axPaperCentroidDifference,C);title(axPaperCentroidDifference,'Benchmark Centroid - FWHM center');

    optimizationGrid=uigridlayout(tabOptimization,[4 2]);optimizationGrid.RowHeight={46,46,'1x','1x'};optimizationGrid.ColumnWidth={330,'1x'};optimizationGrid.Padding=[7 7 7 7];optimizationGrid.RowSpacing=4;
    optimizationTools=uigridlayout(optimizationGrid,[3 8]);optimizationTools.Layout.Row=[1 2];optimizationTools.Layout.Column=[1 2];optimizationTools.ColumnWidth={48,65,65,90,110,90,190,'1x'};optimizationTools.RowHeight={28,28,28};optimizationTools.Padding=[0 0 0 0];optimizationTools.ColumnSpacing=5;optimizationTools.RowSpacing=4;
    optimizationDegreeLabel=uilabel(optimizationTools,'Text','Degree');optimizationDegreeLabel.Layout.Row=1;optimizationDegreeLabel.Layout.Column=1;
    optimizationDegree=uispinner(optimizationTools,'Limits',[1 20],'Value',3,'Step',1,'ValueChangedFcn',@optimizationPositionMethodChanged);optimizationDegree.Layout.Row=1;optimizationDegree.Layout.Column=2;
    optimizationKeepLabel=uilabel(optimizationTools,'Text','Keep');optimizationKeepLabel.Layout.Row=1;optimizationKeepLabel.Layout.Column=3;
    optimizationStop=uispinner(optimizationTools,'Limits',[0 10000],'Value',0,'Step',1,'Tooltip','Number of benchmark points intentionally left out at the end. Use 0 to reach the complete set.');optimizationStop.Layout.Row=1;optimizationStop.Layout.Column=4;
    optimizationRefreshBtn=uibutton(optimizationTools,'Text','Refresh seeds','ButtonPushedFcn',@refreshOptimizationSeeds);optimizationRefreshBtn.Layout.Row=1;optimizationRefreshBtn.Layout.Column=5;
    optimizationSelectAllBtn=uibutton(optimizationTools,'Text','Select all','ButtonPushedFcn',@selectAllOptimizationSeeds);optimizationSelectAllBtn.Layout.Row=1;optimizationSelectAllBtn.Layout.Column=6;
    optimizationClearBtn=uibutton(optimizationTools,'Text','Clear all','ButtonPushedFcn',@clearOptimizationSeeds);optimizationClearBtn.Layout.Row=1;optimizationClearBtn.Layout.Column=7;
    optimizationAddOneBtn=uibutton(optimizationTools,'Text','Run Add-One','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@runOptimizationPath);optimizationAddOneBtn.Layout.Row=2;optimizationAddOneBtn.Layout.Column=[1 2];
    optimizationSeedValidationBtn=uibutton(optimizationTools,'Text','Validate Set Replacements','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@runSeedReplacements);optimizationSeedValidationBtn.Layout.Row=2;optimizationSeedValidationBtn.Layout.Column=[3 5];
    optimizationExportBtn=uibutton(optimizationTools,'Text','Export CSV','ButtonPushedFcn',@exportOptimizationResults);optimizationExportBtn.Layout.Row=2;optimizationExportBtn.Layout.Column=6;
    optimizationBenchmarkMode=uidropdown(optimizationTools,'Items',{'All valid pairs','Symmetry-recommended benchmark'},'Value','All valid pairs','Tooltip','Restrict Add-One and selected-set replacement candidates to symmetry-recommended peaks.');optimizationBenchmarkMode.Layout.Row=2;optimizationBenchmarkMode.Layout.Column=7;
    optimizationOrderBtn=uibutton(optimizationTools,'Text','Scan orders 1..k','ButtonPushedFcn',@runOptimizationOrder);optimizationOrderBtn.Layout.Row=2;optimizationOrderBtn.Layout.Column=8;
    optimizationOrderLabel=uilabel(optimizationTools,'Text','Max order');optimizationOrderLabel.Layout.Row=3;optimizationOrderLabel.Layout.Column=1;
    optimizationMaxOrder=uispinner(optimizationTools,'Limits',[1 20],'Value',10,'Step',1);optimizationMaxOrder.Layout.Row=3;optimizationMaxOrder.Layout.Column=2;
    optimizationPositionLabel=uilabel(optimizationTools,'Text','Peak position');optimizationPositionLabel.Layout.Row=3;optimizationPositionLabel.Layout.Column=3;
    optimizationPositionMethod=uidropdown(optimizationTools,'Items',{'Direct peak','Interpolated peak','FWHM center','Centroid','Gaussian fit'},'Value','FWHM center','ValueChangedFcn',@optimizationPositionMethodChanged,'Tooltip','Peak coordinate used consistently by Add-One and selected-set replacement.');optimizationPositionMethod.Layout.Row=3;optimizationPositionMethod.Layout.Column=[4 5];
    optimizationStatus=uilabel(optimizationTools,'Text','Confirm calibration pairs first.','FontColor',C.navy);optimizationStatus.Layout.Row=3;optimizationStatus.Layout.Column=[6 8];
    optimizationSeedTable=uitable(optimizationGrid,'ColumnName',{'Seed','Peak','Pixel','Reference nm'},'ColumnEditable',[true false false false],'CellEditCallback',@optimizationSeedEdited);optimizationSeedTable.Layout.Row=3;optimizationSeedTable.Layout.Column=1;
    optimizationHistoryTable=uitable(optimizationGrid,'ColumnName',{'Round','Ncal','Selected','Fit RMSE','All-point RMSE','P95','MAX','Candidates','Status'},'CellSelectionCallback',@selectOptimizationHistoryRow);optimizationHistoryTable.Layout.Row=3;optimizationHistoryTable.Layout.Column=2;
    optimizationAxes=uiaxes(optimizationGrid);styleAxes(optimizationAxes,C);title(optimizationAxes,'Sequential Add-One validation path');optimizationAxes.Layout.Row=4;optimizationAxes.Layout.Column=[1 2];

    influenceRoot=uigridlayout(tabInfluence,[1 1]);influenceRoot.Padding=[7 7 7 7];
    influenceFeatureTabs=uitabgroup(influenceRoot);
    sampleInfluenceTab=uitab(influenceFeatureTabs,'Title','Sample influence');
    setReplacementTab=uitab(influenceFeatureTabs,'Title','Set replacement');
    influenceGrid=uigridlayout(sampleInfluenceTab,[3 1]);influenceGrid.RowHeight={62,'1x','1x'};influenceGrid.Padding=[5 5 5 5];influenceGrid.RowSpacing=4;
    influenceTools=uigridlayout(influenceGrid,[2 6]);influenceTools.Layout.Row=1;influenceTools.ColumnWidth={80,120,70,70,'1x','1x'};influenceTools.RowHeight={28,28};influenceTools.Padding=[0 0 0 0];influenceTools.RowSpacing=4;influenceTools.ColumnSpacing=5;
    uilabel(influenceTools,'Text','Degree');influenceDegree=uispinner(influenceTools,'Limits',[1 20],'Value',3,'Step',1,'Tooltip','Unified analysis limit is 20; the actual usable order is also constrained by the number of matched points.');influenceDegree.Layout.Row=1;influenceDegree.Layout.Column=2;
    uilabel(influenceTools,'Text','Scan max');influenceMaxOrder=uispinner(influenceTools,'Limits',[1 20],'Value',10,'Step',1,'Tooltip','Maximum order for the influence scan. Orders requiring too many points are omitted automatically.');influenceMaxOrder.Layout.Row=1;influenceMaxOrder.Layout.Column=4;
    sampleResponseBtn=uibutton(influenceTools,'Text','Analyze sample response','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@runPointInfluence);sampleResponseBtn.Layout.Row=1;sampleResponseBtn.Layout.Column=5;
    influenceOrderScanBtn=uibutton(influenceTools,'Text','Scan influence 1..k','FontWeight','bold','ButtonPushedFcn',@runInfluenceOrderScan);influenceOrderScanBtn.Layout.Row=1;influenceOrderScanBtn.Layout.Column=6;
    influencePositionLabel=uilabel(influenceTools,'Text','Peak position');influencePositionLabel.Layout.Row=2;influencePositionLabel.Layout.Column=1;
    influencePositionMethod=uidropdown(influenceTools,'Items',{'Direct peak','Interpolated peak','FWHM center','Centroid','Gaussian fit'},'Value','FWHM center','ValueChangedFcn',@influencePositionMethodChanged,'Tooltip','Peak coordinate used by both the single-degree influence analysis and the 1..k order scan.');influencePositionMethod.Layout.Row=2;influencePositionMethod.Layout.Column=2;
    influenceXAxisLabel=uilabel(influenceTools,'Text','Plot X axis');influenceXAxisLabel.Layout.Row=2;influenceXAxisLabel.Layout.Column=3;
    influenceXAxisMode=uidropdown(influenceTools,'Items',{'Sample index','Pixel','Wavelength'},'Value','Sample index','ValueChangedFcn',@influenceXAxisChanged,'Tooltip','Change only the display coordinate; influence values are unchanged. Wavelength uses the matched reference wavelength.');influenceXAxisMode.Layout.Row=2;influenceXAxisMode.Layout.Column=4;
    refreshInfluenceBtn=uibutton(influenceTools,'Text','Refresh pairs','ButtonPushedFcn',@refreshInfluenceTable);refreshInfluenceBtn.Layout.Row=2;refreshInfluenceBtn.Layout.Column=5;
    influenceStatus=uilabel(influenceTools,'Text','Analyze one degree or set Scan max and compare orders.','FontColor',C.navy);influenceStatus.Layout.Row=2;influenceStatus.Layout.Column=6;
    influenceTable=uitable(influenceGrid,'ColumnName',{'Index','Peak','Pixel','Reference nm','Residual','Deleted Fit RMSE','Deleted LOO RMSE','Curve change','Influence','Match status','Class','Recommendation'},'RowName',[],'CellSelectionCallback',@selectInfluenceResultRow);influenceTable.Layout.Row=2;
    influenceDiagnosticTabs=uitabgroup(influenceGrid);influenceDiagnosticTabs.Layout.Row=3;
    pointInfluencePlotTab=uitab(influenceDiagnosticTabs,'Title','Per-point influence');
    influenceOrderPlotTab=uitab(influenceDiagnosticTabs,'Title','Across orders');
    sampleResponsePlotHost=uigridlayout(pointInfluencePlotTab,[2 1]);sampleResponsePlotHost.RowHeight={30,'1x'};sampleResponsePlotHost.Padding=[5 5 5 5];sampleResponsePlotHost.RowSpacing=3;
    influenceAxisTools=uigridlayout(sampleResponsePlotHost,[1 6]);influenceAxisTools.Layout.Row=1;influenceAxisTools.ColumnWidth={55,100,45,100,45,100};influenceAxisTools.Padding=[0 0 0 0];
    uilabel(influenceAxisTools,'Text','Y axis');influenceYMode=uidropdown(influenceAxisTools,'Items',{'Auto','Manual'},'Value','Auto','ValueChangedFcn',@influenceAxisSettingsChanged);
    uilabel(influenceAxisTools,'Text','Y min');influenceYMin=uieditfield(influenceAxisTools,'numeric','Value',0,'ValueChangedFcn',@influenceAxisSettingsChanged);
    uilabel(influenceAxisTools,'Text','Y max');influenceYMax=uieditfield(influenceAxisTools,'numeric','Value',0.5,'ValueChangedFcn',@influenceAxisSettingsChanged);
    influenceAxes=uiaxes(sampleResponsePlotHost);influenceAxes.Layout.Row=2;styleAxes(influenceAxes,C);title(influenceAxes,'Point influence by deletion');
    influenceOrderPlotGrid=uigridlayout(influenceOrderPlotTab,[1 1]);influenceOrderPlotGrid.Padding=[3 3 3 3];
    influenceOrderViewTabs=uitabgroup(influenceOrderPlotGrid);
    influenceFullOrderTab=uitab(influenceOrderViewTabs,'Title','Full Fit vs LOO');
    influenceGapOrderTab=uitab(influenceOrderViewTabs,'Title','Generalization gap');
    influenceDeletionOrderTab=uitab(influenceOrderViewTabs,'Title','Deletion stability');
    influenceStatisticsOrderTab=uitab(influenceOrderViewTabs,'Title','Influence statistics');
    influenceFullOrderGrid=uigridlayout(influenceFullOrderTab,[1 1]);influenceFullOrderGrid.Padding=[5 5 5 5];
    influenceFullErrorAxes=uiaxes(influenceFullOrderGrid);styleAxes(influenceFullErrorAxes,C);title(influenceFullErrorAxes,'Full-set Fit versus LOO RMSE');
    influenceGapOrderGrid=uigridlayout(influenceGapOrderTab,[1 1]);influenceGapOrderGrid.Padding=[5 5 5 5];
    influenceGapAxes=uiaxes(influenceGapOrderGrid);styleAxes(influenceGapAxes,C);title(influenceGapAxes,'Generalization gap: LOO RMSE - Fit RMSE');
    influenceDeletionOrderGrid=uigridlayout(influenceDeletionOrderTab,[1 1]);influenceDeletionOrderGrid.Padding=[5 5 5 5];
    influenceDeletionErrorAxes=uiaxes(influenceDeletionOrderGrid);styleAxes(influenceDeletionErrorAxes,C);title(influenceDeletionErrorAxes,'Full-set and point-deleted model errors');
    influenceStatisticsOrderGrid=uigridlayout(influenceStatisticsOrderTab,[1 1]);influenceStatisticsOrderGrid.Padding=[5 5 5 5];
    influenceOrderStatsAxes=uiaxes(influenceStatisticsOrderGrid);styleAxes(influenceOrderStatsAxes,C);title(influenceOrderStatsAxes,'Influence statistics across polynomial orders');

    replacementGrid=uigridlayout(setReplacementTab,[3 1]);replacementGrid.RowHeight={96,'1x','1x'};replacementGrid.Padding=[5 5 5 5];replacementGrid.RowSpacing=4;
    replacementTools=uigridlayout(replacementGrid,[3 4]);replacementTools.Layout.Row=1;replacementTools.ColumnWidth={110,150,160,'1x'};replacementTools.RowHeight={28,28,28};replacementTools.Padding=[0 0 0 0];replacementTools.RowSpacing=4;replacementTools.ColumnSpacing=5;
    rmseThresholdLabel=uilabel(replacementTools,'Text','RMSE th (nm)');rmseThresholdLabel.Layout.Row=1;rmseThresholdLabel.Layout.Column=1;
    replacementRMSEThreshold=uieditfield(replacementTools,'numeric','Value',0.1,'Limits',[0 Inf],'Tooltip','Minimum RMSE decrease required before a replacement is recommended.');replacementRMSEThreshold.Layout.Row=1;replacementRMSEThreshold.Layout.Column=2;
    seedValidationLabel=uilabel(replacementTools,'Text','Validation pool');seedValidationLabel.Layout.Row=1;seedValidationLabel.Layout.Column=3;
    seedValidationMode=uidropdown(replacementTools,'Items',{'All points','Non-selected points'},'Value','All points','Tooltip','Choose the fixed residual validation pool for selected-set replacement.');seedValidationMode.Layout.Row=1;seedValidationMode.Layout.Column=4;
    seedReplacementBtn=uibutton(replacementTools,'Text','Validate selected-set replacements','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@runSeedReplacements);seedReplacementBtn.Layout.Row=2;seedReplacementBtn.Layout.Column=[1 2];
    addRecommendedSeedModelBtn=uibutton(replacementTools,'Text','Add recommended model to comparison','Enable','off','ButtonPushedFcn',@addRecommendedSeedModel);addRecommendedSeedModelBtn.Layout.Row=2;addRecommendedSeedModelBtn.Layout.Column=[3 4];
    replacementStatus=uilabel(replacementTools,'Text','Select a set in Calibration Optimization and leave at least one valid candidate unselected.','FontColor',C.navy);replacementStatus.Layout.Row=3;replacementStatus.Layout.Column=[1 4];
    replacementTable=uitable(replacementGrid,'ColumnName',{'Round','Removed point','Replacement','Fit RMSE','Validation RMSE','Delta RMSE','P95','MAX','Conclusion'},'RowName',[],'CellSelectionCallback',@selectReplacementResultRow);replacementTable.Layout.Row=2;
    seedReplacementPlotHost=uigridlayout(replacementGrid,[1 1]);seedReplacementPlotHost.Layout.Row=3;seedReplacementPlotHost.Padding=[5 5 5 5];
    seedReplacementAxes=uiaxes(seedReplacementPlotHost);styleAxes(seedReplacementAxes,C);title(seedReplacementAxes,'Set replacement residuals');

    setDesignRoot=uigridlayout(tabSetDesign,[1 1]);setDesignRoot.Padding=[0 0 0 0];
    setDesignWorkspaceTabs=uitabgroup(setDesignRoot);
    setDesignSearchTab=uitab(setDesignWorkspaceTabs,'Title','Subset Search');
    windowPartitionTab=uitab(setDesignWorkspaceTabs,'Title','Window Partition');
    setDesignGrid=uigridlayout(setDesignSearchTab,[3 2]);setDesignGrid.RowHeight={142,'1x','1x'};setDesignGrid.ColumnWidth={'1x','1.25x'};setDesignGrid.Padding=[7 7 7 7];setDesignGrid.RowSpacing=4;
    setDesignTools=uigridlayout(setDesignGrid,[5 8]);setDesignTools.Layout.Row=1;setDesignTools.Layout.Column=[1 2];setDesignTools.RowHeight={27,27,27,27,22};setDesignTools.ColumnWidth={'1x','1x','1x','1x','1x','1x','1x','1x'};setDesignTools.Padding=[0 0 0 0];setDesignTools.RowSpacing=3;setDesignTools.ColumnSpacing=4;
    refreshSetDesignBtn=uibutton(setDesignTools,'Text','Refresh pool','ButtonPushedFcn',@refreshSetDesignPool);refreshSetDesignBtn.Layout.Row=1;refreshSetDesignBtn.Layout.Column=1;
    setDesignMethod=uidropdown(setDesignTools,'Items',{'Manual selection','Top-k influence','Maximin coverage','Locked boundary + coverage','Window influence','Window quality','Window center'},'Value','Top-k influence');setDesignMethod.Layout.Row=1;setDesignMethod.Layout.Column=[2 3];
    setDesignKLabel=uilabel(setDesignTools,'Text','Target K','HorizontalAlignment','right');setDesignKLabel.Layout.Row=1;setDesignKLabel.Layout.Column=4;setDesignK=uispinner(setDesignTools,'Limits',[4 100],'Step',1,'Value',10);setDesignK.Layout.Row=1;setDesignK.Layout.Column=5;
    generateSetDesignBtn=uibutton(setDesignTools,'Text','Generate rule set','ButtonPushedFcn',@generateSetDesignCandidate);generateSetDesignBtn.Layout.Row=1;generateSetDesignBtn.Layout.Column=[6 8];
    setDesignBPerfLabel=uilabel(setDesignTools,'Text','B perf','HorizontalAlignment','right');setDesignBPerfLabel.Layout.Row=2;setDesignBPerfLabel.Layout.Column=1;setDesignBPerf=uispinner(setDesignTools,'Limits',[0 50],'Step',1,'Value',5);setDesignBPerf.Layout.Row=2;setDesignBPerf.Layout.Column=2;
    setDesignBDivLabel=uilabel(setDesignTools,'Text','B div','HorizontalAlignment','right');setDesignBDivLabel.Layout.Row=2;setDesignBDivLabel.Layout.Column=3;setDesignBDiv=uispinner(setDesignTools,'Limits',[0 50],'Step',1,'Value',5);setDesignBDiv.Layout.Row=2;setDesignBDiv.Layout.Column=4;
    setDesignEpsilonRMSLabel=uilabel(setDesignTools,'Text','eps RMS','HorizontalAlignment','right');setDesignEpsilonRMSLabel.Layout.Row=2;setDesignEpsilonRMSLabel.Layout.Column=5;setDesignEpsilonRMS=uieditfield(setDesignTools,'numeric','Limits',[0 Inf],'Value',0.01);setDesignEpsilonRMS.Layout.Row=2;setDesignEpsilonRMS.Layout.Column=6;
    setDesignEpsilonMAXLabel=uilabel(setDesignTools,'Text','eps MAX','HorizontalAlignment','right');setDesignEpsilonMAXLabel.Layout.Row=2;setDesignEpsilonMAXLabel.Layout.Column=7;setDesignEpsilonMAX=uieditfield(setDesignTools,'numeric','Limits',[0 Inf],'Value',0.03);setDesignEpsilonMAX.Layout.Row=2;setDesignEpsilonMAX.Layout.Column=8;
    initializeBeamBtn=uibutton(setDesignTools,'Text','Initialize Beam','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@initializeSetDesignBeam);initializeBeamBtn.Layout.Row=3;initializeBeamBtn.Layout.Column=[1 2];
    calculateBeamLayerBtn=uibutton(setDesignTools,'Text','Calculate K-1','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@calculateSetDesignBeamLayer);calculateBeamLayerBtn.Layout.Row=3;calculateBeamLayerBtn.Layout.Column=[3 4];
    acceptBeamLayerBtn=uibutton(setDesignTools,'Text','Confirm checked','FontWeight','bold','ButtonPushedFcn',@acceptSetDesignBeamLayer);acceptBeamLayerBtn.Layout.Row=3;acceptBeamLayerBtn.Layout.Column=[5 6];
    resetBeamBtn=uibutton(setDesignTools,'Text','Reinitialize','ButtonPushedFcn',@initializeSetDesignBeam,'Tooltip','Discard the current Beam path and initialize again with the displayed parameters.');resetBeamBtn.Layout.Row=3;resetBeamBtn.Layout.Column=[7 8];
    sendSubsetToAddOneBtn=uibutton(setDesignTools,'Text','Send to Add-One','ButtonPushedFcn',@sendSetDesignToAddOne);sendSubsetToAddOneBtn.Layout.Row=4;sendSubsetToAddOneBtn.Layout.Column=[1 2];
    addSubsetModelBtn=uibutton(setDesignTools,'Text','Add model to comparison','ButtonPushedFcn',@addSetDesignModel);addSubsetModelBtn.Layout.Row=4;addSubsetModelBtn.Layout.Column=[3 5];
    exportSetDesignBtn=uibutton(setDesignTools,'Text','Export results','ButtonPushedFcn',@exportSetDesignResults);exportSetDesignBtn.Layout.Row=4;exportSetDesignBtn.Layout.Column=[6 7];
    setDesignGuideBtn=uibutton(setDesignTools,'Text','Guide','ButtonPushedFcn',@showSetDesignGuide);setDesignGuideBtn.Layout.Row=4;setDesignGuideBtn.Layout.Column=8;
    setDesignStatus=uilabel(setDesignTools,'Text','Refresh the calibration pool to begin.','FontColor',C.navy);setDesignStatus.Layout.Row=5;setDesignStatus.Layout.Column=[1 8];
    setDesignPoolTabs=uitabgroup(setDesignGrid);setDesignPoolTabs.Layout.Row=2;setDesignPoolTabs.Layout.Column=1;
    setDesignFullPoolTab=uitab(setDesignPoolTabs,'Title','Full pool / manual selection');
    setDesignSelectedTab=uitab(setDesignPoolTabs,'Title','Selected subset members');
    setDesignPoolTable=uitable(setDesignFullPoolTab,'Units','normalized','Position',[0 0 1 1],'ColumnName',{'Use','Rank','Peak','Pixel','Wavelength','Influence','Percentile','Quality','Spacing','Boundary'},'ColumnEditable',[true false false false false false false false false false],'RowName',[]);
    setDesignSelectedTable=uitable(setDesignSelectedTab,'Units','normalized','Position',[0 0 1 1],'ColumnName',{'Peak','Pixel','Wavelength','Influence','Rank','Percentile','Quality','Spacing','Boundary'},'ColumnEditable',false(1,9),'RowName',[]);
    setDesignCandidateTable=uitable(setDesignGrid,'ColumnName',{'Keep','ID','State','Source','Role','K','Deleted','All RMSE','P95','MAX','D RMS','D MAX','Cover'},'ColumnEditable',[true false false false false false false false false false false false false],'RowName',[],'CellSelectionCallback',@selectSetDesignCandidate);setDesignCandidateTable.Layout.Row=2;setDesignCandidateTable.Layout.Column=2;
    setDesignSelectionAxes=uiaxes(setDesignGrid);setDesignSelectionAxes.Layout.Row=3;setDesignSelectionAxes.Layout.Column=1;styleAxes(setDesignSelectionAxes,C);title(setDesignSelectionAxes,'Selected sample coverage and influence');
    setDesignResidualAxes=uiaxes(setDesignGrid);setDesignResidualAxes.Layout.Row=3;setDesignResidualAxes.Layout.Column=2;styleAxes(setDesignResidualAxes,C);title(setDesignResidualAxes,'Selected subset residuals on the full pool');

    windowPartitionGrid=uigridlayout(windowPartitionTab,[3 1]);windowPartitionGrid.RowHeight={92,'1x','1x'};windowPartitionGrid.Padding=[7 7 7 7];windowPartitionGrid.RowSpacing=4;
    windowPartitionTools=uigridlayout(windowPartitionGrid,[3 8]);windowPartitionTools.Layout.Row=1;windowPartitionTools.RowHeight={28,28,28};windowPartitionTools.ColumnWidth={70,90,85,'1x','1x','1x','1x',110};windowPartitionTools.Padding=[0 0 0 0];windowPartitionTools.RowSpacing=4;windowPartitionTools.ColumnSpacing=5;
    windowKLabel=uilabel(windowPartitionTools,'Text','Target K','HorizontalAlignment','right');windowKLabel.Layout.Row=1;windowKLabel.Layout.Column=1;windowPartitionK=uispinner(windowPartitionTools,'Limits',[4 100],'Step',1,'Value',6,'Tooltip','Window count. No sample is selected during Window Partition.');windowPartitionK.Layout.Row=1;windowPartitionK.Layout.Column=2;
    windowRuleLabel=uilabel(windowPartitionTools,'Text','Rule','HorizontalAlignment','right');windowRuleLabel.Layout.Row=1;windowRuleLabel.Layout.Column=3;windowPartitionRule=uidropdown(windowPartitionTools,'Items',{'Equal wavelength width','Equal cumulative influence'},'Value','Equal wavelength width');windowPartitionRule.Layout.Row=1;windowPartitionRule.Layout.Column=[4 5];
    generateWindowsBtn=uibutton(windowPartitionTools,'Text','Generate Windows','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@generateWindowPartition);generateWindowsBtn.Layout.Row=1;generateWindowsBtn.Layout.Column=[6 7];
    clearWindowsBtn=uibutton(windowPartitionTools,'Text','Clear Windows','ButtonPushedFcn',@clearWindowPartition);clearWindowsBtn.Layout.Row=1;clearWindowsBtn.Layout.Column=8;
    windowInfluenceLabel=uilabel(windowPartitionTools,'Text','Influence','HorizontalAlignment','right');windowInfluenceLabel.Layout.Row=2;windowInfluenceLabel.Layout.Column=1;
    windowInfluenceMode=uidropdown(windowPartitionTools,'Items',{'Normalized weight','Raw influence'},'Value','Normalized weight','ValueChangedFcn',@windowPartitionDisplayChanged);windowInfluenceMode.Layout.Row=2;windowInfluenceMode.Layout.Column=2;
    windowShowCumulative=uicheckbox(windowPartitionTools,'Text','Show cumulative curve','Value',true,'ValueChangedFcn',@windowPartitionDisplayChanged);windowShowCumulative.Layout.Row=2;windowShowCumulative.Layout.Column=[3 4];
    windowSymmetryThreshold=uieditfield(windowPartitionTools,'numeric','Value',0.2,'Limits',[0 Inf],'Tooltip','Peak symmetry threshold in pixels: abs(FWHM center - centroid). Smaller is better.');windowSymmetryThreshold.Layout.Row=2;windowSymmetryThreshold.Layout.Column=5;
    windowPartitionStatus=uilabel(windowPartitionTools,'Text','Window status','Visible','off');
    windowInfluenceThreshold=uieditfield(windowPartitionTools,'numeric','Value',25,'Limits',[0 1000],'Tooltip','Recommend when influence is at least this percentage above the window mean.');windowInfluenceThreshold.Layout.Row=2;windowInfluenceThreshold.Layout.Column=6;
    recommendWindowSamplesBtn=uibutton(windowPartitionTools,'Text','Recommend','ButtonPushedFcn',@recommendWindowSamples);recommendWindowSamplesBtn.Layout.Row=2;recommendWindowSamplesBtn.Layout.Column=7;
    confirmWindowSamplesBtn=uibutton(windowPartitionTools,'Text','Confirm set','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@confirmWindowSamples);confirmWindowSamplesBtn.Layout.Row=2;confirmWindowSamplesBtn.Layout.Column=8;
    windowLeftExtensionLabel=uilabel(windowPartitionTools,'Text','Left ext (px)','HorizontalAlignment','right');windowLeftExtensionLabel.Layout.Row=3;windowLeftExtensionLabel.Layout.Column=1;
    windowLeftExtension=uispinner(windowPartitionTools,'Limits',[0 5000],'Step',1,'Value',0,'ValueChangedFcn',@windowExtensionChanged);windowLeftExtension.Layout.Row=3;windowLeftExtension.Layout.Column=2;
    windowRightExtensionLabel=uilabel(windowPartitionTools,'Text','Right ext (px)','HorizontalAlignment','right');windowRightExtensionLabel.Layout.Row=3;windowRightExtensionLabel.Layout.Column=3;
    windowRightExtension=uispinner(windowPartitionTools,'Limits',[0 5000],'Step',1,'Value',0,'ValueChangedFcn',@windowExtensionChanged);windowRightExtension.Layout.Row=3;windowRightExtension.Layout.Column=4;
    windowDegreeLabel=uilabel(windowPartitionTools,'Text','Influence degree','HorizontalAlignment','right');windowDegreeLabel.Layout.Row=3;windowDegreeLabel.Layout.Column=5;
    windowDegreeSpinner=uispinner(windowPartitionTools,'Limits',[1 20],'Step',1,'Value',3,'ValueChangedFcn',@windowDegreeChanged,'Tooltip','Polynomial degree used to calculate deletion influence for both windows and recommendations.');windowDegreeSpinner.Layout.Row=3;windowDegreeSpinner.Layout.Column=6;
    windowExtensionStatus=uilabel(windowPartitionTools,'Text','Membership unchanged by display extension.','FontColor',C.muted);windowExtensionStatus.Layout.Row=3;windowExtensionStatus.Layout.Column=7;
    windowResetExtensionBtn=uibutton(windowPartitionTools,'Text','Reset ext','ButtonPushedFcn',@resetWindowExtension);windowResetExtensionBtn.Layout.Row=3;windowResetExtensionBtn.Layout.Column=8;
    windowTableTabs=uitabgroup(windowPartitionGrid);windowTableTabs.Layout.Row=2;
    windowBoundaryTab=uitab(windowTableTabs,'Title','Window boundaries');
    windowSamplesTab=uitab(windowTableTabs,'Title','Window sample selection');
    windowPartitionTable=uitable(windowBoundaryTab,'Units','normalized','Position',[0 0 1 1],'ColumnName',{'Window','Start nm','End nm','First','Last','N','Sum influence','Weight','Mean influence','Max influence','Max peak','Max wavelength','Target weight','Deviation','Status'},'ColumnEditable',false(1,15),'RowName',[]);
    windowMemberTable=uitable(windowSamplesTab,'Units','normalized','Position',[0 0 1 1],'ColumnName',{'Use','Window','Peak','Pixel','Wavelength','Influence','Influence / mean','Symmetry px','Score','Recommendation'},'ColumnEditable',[true false false false false false false false false false],'CellEditCallback',@windowMemberEdited,'RowName',[]);
    windowTableTabs.SelectedTab=windowSamplesTab;
    windowPartitionPlots=uigridlayout(windowPartitionGrid,[2 1]);windowPartitionPlots.Layout.Row=3;windowPartitionPlots.RowHeight={'1x','1x'};windowPartitionPlots.Padding=[3 3 3 3];windowPartitionPlots.RowSpacing=4;
    windowResidualAxes=uiaxes(windowPartitionPlots);styleAxes(windowResidualAxes,C);title(windowResidualAxes,'Full-set residual with window boundaries');
    windowInfluenceAxes=uiaxes(windowPartitionPlots);styleAxes(windowInfluenceAxes,C);title(windowInfluenceAxes,'Influence weight distribution');
    linkaxes([windowResidualAxes windowInfluenceAxes],'x');

    matchHost=uigridlayout(tabMatchingPlots,[2 1]);matchHost.RowHeight={'1x','1x'};matchHost.Padding=[7 7 7 7];
    axMatchMeasured=uiaxes(matchHost);styleAxes(axMatchMeasured,C);title(axMatchMeasured,'Selected measured peaks');
    axMatchReference=uiaxes(matchHost);styleAxes(axMatchReference,C);title(axMatchReference,'Reference wavelength lines');

    %% RIGHT TABS
    tabs=uitabgroup(root); tabs.Layout.Row=2; tabs.Layout.Column=3;
    tabList=uitab(tabs,'Title','Peak List'); tabData=uitab(tabs,'Title','Peak Dataset');
    tabCal=uitab(tabs,'Title','Matching'); tabFit=uitab(tabs,'Title','Calibration Fit');
    tabPeakDifferenceData=uitab(tabs,'Title','Peak-difference dataset');
    tabs.SelectionChangedFcn=@rightTabChanged;

    gl=uigridlayout(tabList,[5 1]); gl.RowHeight={28,30,'1x',32,32}; gl.Padding=[7 7 7 7];
    peakCountLabel=uilabel(gl,'Text','No detected peaks','FontWeight','bold','FontColor',C.navy);
    symmetryTools=uigridlayout(gl,[1 2]);symmetryTools.ColumnWidth={190,'1x'};symmetryTools.Padding=[0 0 0 0];
    uilabel(symmetryTools,'Text','Symmetry |Centroid-Center| (px)');
    symmetryThreshold=uieditfield(symmetryTools,'numeric','Value',symmetryThresholdPx,'Limits',[0 Inf],'ValueChangedFcn',@symmetryThresholdChanged);
    peakTable=uitable(gl,'ColumnName',{'ID','Pixel','Input X','Height','Prom.','Width','Symmetry'}, ...
        'ColumnWidth',{44,58,68,65,58,52,100},'RowName',[],'CellSelectionCallback',@selectPeak);
    nav=uigridlayout(gl,[1 2]); nav.ColumnWidth={'1x','1x'}; nav.Padding=[0 0 0 0];
    uibutton(nav,'Text','< Previous','ButtonPushedFcn',@previousPeak); uibutton(nav,'Text','Next >','ButtonPushedFcn',@nextPeak);
    excludeBtn=uibutton(gl,'Text','Exclude / Restore selected','ButtonPushedFcn',@toggleExclude,'Enable','off');

    gc=uigridlayout(tabCurrent,[6 1]); gc.RowHeight={28,'1x',110,34,34,34}; gc.Padding=[7 7 7 7];
    currentLabel=uilabel(gc,'Text','No peak selected','FontWeight','bold','FontColor',C.navy);
    currentTable=uitable(gc,'ColumnName',{'Parameter','Pixel domain','Wavelength domain'},'ColumnWidth',{155,90,105},'RowName',[]);
    warnings=uitextarea(gc,'Editable','off','Value',{'No result.'});
    analyzeBtn=uibutton(gc,'Text','Analyze / Refresh','ButtonPushedFcn',@analyzeSelected,'Enable','off');
    addBtn=uibutton(gc,'Text','CONFIRM PEAK PARAMETERS','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@confirmPeak,'Enable','off');
    confirmNextBtn=uibutton(gc,'Text','CONFIRM & NEXT','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@confirmAndNext,'Enable','off');

    rgRef=uigridlayout(tabReference,[6 1]);rgRef.RowHeight={32,28,22,'1x',64,46};rgRef.Padding=[7 7 7 7];
    loadLinesBtn=uibutton(rgRef,'Text','Load reference master file (.lit/.txt/.csv)','ButtonPushedFcn',@loadLineLibrary);
    referenceSetDrop=uidropdown(rgRef,'Items',{'Basic 21','Paper 24','NIM Certificate 34','External / User'},'Value','Basic 21','ValueChangedFcn',@referenceSetChanged);
    lineInfo=uilabel(rgRef,'Text','21 lines | Built-in Hg-Ar Basic 21','FontColor',C.muted);
    refTable=uitable(rgRef,'ColumnName',{'nm','Intensity','Order','Status'},'ColumnWidth',{78,72,48,100}, ...
        'RowName',[],'CellSelectionCallback',@selectReferenceLine);
    modeTools=uigridlayout(rgRef,[2 2]);modeTools.ColumnWidth={'1x','1x'};modeTools.RowHeight={28,28};modeTools.Padding=[0 0 0 0];
    uibutton(modeTools,'Text','Use selected line','ButtonPushedFcn',@enableSelectedReference);
    uibutton(modeTools,'Text','Disable selected line','ButtonPushedFcn',@disableSelectedReference);
    uibutton(modeTools,'Text','Import selection mode','ButtonPushedFcn',@importReferenceMode);
    uibutton(modeTools,'Text','Export selection mode','ButtonPushedFcn',@exportReferenceMode);
    refHelp=uilabel(rgRef,'Text','The master library is the traceable source. Basic/Paper/NIM entries are reusable selection modes. Disabled lines remain in the master and are only excluded from the active mode.', ...
        'WordWrap','on','FontColor',C.muted);

    gd=uigridlayout(tabData,[6 1]); gd.RowHeight={28,'1x',36,36,34,34}; gd.Padding=[7 7 7 7];
    datasetLabel=uilabel(gd,'Text','Confirmed peaks: 0','FontWeight','bold','FontColor',C.navy);
    datasetTable=uitable(gd,'ColumnName',{'ID','Pixel','Ref. nm','FWHM px','ERW px','Status'}, ...
        'ColumnWidth',{48,62,70,72,70,72},'RowName',[],'ColumnEditable',[false false true false false false], ...
        'CellSelectionCallback',@selectDatasetRow,'CellEditCallback',@editDatasetCell);
    uibutton(gd,'Text','BATCH PRE-ANALYSIS (PREVIEW ONLY)','FontWeight','bold','BackgroundColor',C.orange,'ButtonPushedFcn',@analyzeAll);
    uibutton(gd,'Text','PLOT CONFIRMED PEAK PARAMETERS','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@plotConfirmedPeakParameters);
    uibutton(gd,'Text','Remove selected dataset row','ButtonPushedFcn',@removeDataset);
    uibutton(gd,'Text','Export Peak Dataset MAT + CSV','FontWeight','bold','ButtonPushedFcn',@exportDataset);

    peakDifferenceDataGrid=uigridlayout(tabPeakDifferenceData,[6 1]);peakDifferenceDataGrid.RowHeight={24,'1x',32,24,'1x',34};peakDifferenceDataGrid.Padding=[6 6 6 6];peakDifferenceDataGrid.RowSpacing=4;
    peakDifferenceAllLabel=uilabel(peakDifferenceDataGrid,'Text','All valid analyzed peaks','FontWeight','bold','FontColor',C.navy);
    paperAllPeakTable=uitable(peakDifferenceDataGrid,'ColumnName',{'Show','Peak','Wave nm','D-C px','I-C px','Cent-C px','Set status','Addable'}, ...
        'ColumnWidth',{42,48,70,62,62,70,92,58},'ColumnEditable',[true false false false false false false false], ...
        'RowName',[],'CellEditCallback',@paperAllPeakTableEdited,'CellSelectionCallback',@paperAllPeakTableSelected);
    paperAddSelectedBtn=uibutton(peakDifferenceDataGrid,'Text','CONFIRM ADD SELECTED TO CALIBRATION SET','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@paperAddSelectedPeak);
    peakDifferenceCalibrationLabel=uilabel(peakDifferenceDataGrid,'Text','Current calibration peaks: uncheck Fit to mark temporary deletion','FontWeight','bold','FontColor',C.navy);
    paperCalibrationPeakTable=uitable(peakDifferenceDataGrid,'ColumnName',{'Fit','Peak','Ref. nm','FWHM px','Centroid px','Delta px','State'}, ...
        'ColumnWidth',{38,48,68,68,72,62,82},'ColumnEditable',[true false false false false false false], ...
        'RowName',[],'CellEditCallback',@paperCalibrationTableEdited,'CellSelectionCallback',@paperCalibrationTableSelected);
    paperCalibrationButtons=uigridlayout(peakDifferenceDataGrid,[1 3]);paperCalibrationButtons.ColumnWidth={'1x','1x','1x'};paperCalibrationButtons.Padding=[0 0 0 0];paperCalibrationButtons.ColumnSpacing=4;
    uibutton(paperCalibrationButtons,'Text','Refresh fit','ButtonPushedFcn',@refreshPaperPeakDifference);
    uibutton(paperCalibrationButtons,'Text','Restore temporary','ButtonPushedFcn',@restorePaperPeakDifferenceRows);
    uibutton(paperCalibrationButtons,'Text','CONFIRM DELETE','FontWeight','bold','BackgroundColor',C.orange,'ButtonPushedFcn',@paperConfirmDeletePeaks);

    %% MATCHING TAB
    gcal=uigridlayout(tabCal,[15 2]); gcal.ColumnWidth={135,'1x'};
    gcal.RowHeight={28,42,24,26,30,28,24,26,26,26,32,'1x',28,40,45};
    gcal.Padding=[7 7 7 7]; gcal.RowSpacing=3;
    refSummary=uilabel(gcal,'Text','Reference lines are managed in the middle Reference Lines tab.','FontColor',C.muted,'WordWrap','on');refSummary.Layout.Column=[1 2];
    equationLabel=uilabel(gcal,'Text','Local linear guide: set the two windows','FontColor',C.navy,'FontWeight','bold','WordWrap','on'); equationLabel.Layout.Column=[1 2];
    sectionAuto(gcal,'Peak-reference pairing');
    uilabel(gcal,'Text','Measured peak'); calPeakDrop=uidropdown(gcal,'Items',{'(none)'},'Value','(none)');
    pairBtn=uibutton(gcal,'Text','Pair peak with selected reference line','ButtonPushedFcn',@addManualPair); pairBtn.Layout.Column=[1 2];
    pairTools=uigridlayout(gcal,[1 2]); pairTools.Layout.Column=[1 2]; pairTools.ColumnWidth={'1x','1x'}; pairTools.Padding=[0 0 0 0];
    uibutton(pairTools,'Text','Remove pair','ButtonPushedFcn',@removePair);
    uibutton(pairTools,'Text','Lock / Unlock','ButtonPushedFcn',@togglePairLock);
    sectionAuto(gcal,'Automatic extension');
    uilabel(gcal,'Text','Match tolerance (nm)'); matchTolerance=uieditfield(gcal,'numeric','Value',2,'Limits',[0 Inf]);
    uilabel(gcal,'Text','Lock confidence'); confidenceThreshold=uieditfield(gcal,'numeric','Value',0.75,'Limits',[0 1]);
    sourceDrop=uidropdown(gcal,'Items',{'Confirmed Peak Dataset','All detected peaks'},'Value','Confirmed Peak Dataset'); sourceDrop.Layout.Column=[1 2];
    calButtons=uigridlayout(gcal,[1 3]); calButtons.Layout.Column=[1 2]; calButtons.ColumnWidth={'1x','1x','1x'}; calButtons.Padding=[0 0 0 0];
    uibutton(calButtons,'Text','Update model','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@buildInitialCalibration);
    uibutton(calButtons,'Text','Auto extend','ButtonPushedFcn',@autoMatchPeaks);
    uibutton(calButtons,'Text','Lock high','ButtonPushedFcn',@lockHighConfidencePairs);
    pairTable=uitable(gcal,'ColumnName',{'Peak','Pixel','Ref. nm','Mode','Conf.','Lock','Status'}, ...
        'ColumnWidth',{46,55,68,62,48,40,82},'RowName',[],'CellSelectionCallback',@selectPairRow); pairTable.Layout.Column=[1 2];
    exportCalBtn=uibutton(gcal,'Text','Export calibration MAT + CSV','ButtonPushedFcn',@exportCalibration); exportCalBtn.Layout.Column=[1 2];
    calHelp=uilabel(gcal,'Text','Upper plot shows only the measured pixel subrange; lower plot shows only the reference wavelength subrange. Local scale/shift assists pairing and is independent of the final polynomial calibration.', ...
        'WordWrap','on','FontColor',C.muted); calHelp.Layout.Column=[1 2];

    %% EMBEDDED FIT AND RESIDUAL PLOTS
    gr=uigridlayout(tabResults,[4 1]); gr.RowHeight={'1x','1x',30,'1x'}; gr.Padding=[7 7 7 7];
    axFitResult=uiaxes(gr); styleAxes(axFitResult,C); title(axFitResult,'Calibration fit');
    axResidualResult=uiaxes(gr); styleAxes(axResidualResult,C); title(axResidualResult,'Residual trend');
    histControls=uigridlayout(gr,[1 9]); histControls.ColumnWidth={32,48,40,65,40,65,82,70,'1x'}; histControls.Padding=[0 0 0 0];
    uilabel(histControls,'Text','Bins'); histBinCount=uispinner(histControls,'Limits',[1 100],'Step',1,'Value',8,'ValueChangedFcn',@histogramControlsChanged);
    uilabel(histControls,'Text','X min'); histXMin=uieditfield(histControls,'numeric','Value',-0.5,'ValueChangedFcn',@histogramControlsChanged);
    uilabel(histControls,'Text','X max'); histXMax=uieditfield(histControls,'numeric','Value',0.5,'ValueChangedFcn',@histogramControlsChanged);
    histRangeMode=uidropdown(histControls,'Items',{'Auto full','Symmetric','+/-3 STD','Manual'},'Value','Auto full','ValueChangedFcn',@histogramControlsChanged);
    uibutton(histControls,'Text','Refresh','ButtonPushedFcn',@histogramControlsChanged);
    axHistogramResult=uiaxes(gr); styleAxes(axHistogramResult,C); title(axHistogramResult,'Residual histogram');

    %% SELECTED RESULT RESIDUAL DIAGNOSTICS
    selectedResidualGrid=uigridlayout(tabSelectedResidual,[4 1]);selectedResidualGrid.RowHeight={36,'1x',30,'1x'};selectedResidualGrid.Padding=[7 7 7 7];selectedResidualGrid.RowSpacing=4;
    selectedResidualSummary=uilabel(selectedResidualGrid,'Text','Select a model, Add-One round, model degree, or set replacement round.','FontWeight','bold','FontColor',C.navy);
    axSelectedResidualTrend=uiaxes(selectedResidualGrid);styleAxes(axSelectedResidualTrend,C);title(axSelectedResidualTrend,'Selected residual trend');
    selectedHistControls=uigridlayout(selectedResidualGrid,[1 9]);selectedHistControls.ColumnWidth={32,48,40,65,40,65,82,70,'1x'};selectedHistControls.Padding=[0 0 0 0];
    uilabel(selectedHistControls,'Text','Bins');selectedHistBinCount=uispinner(selectedHistControls,'Limits',[1 100],'Step',1,'Value',8,'ValueChangedFcn',@selectedResidualHistogramControlsChanged);
    uilabel(selectedHistControls,'Text','X min');selectedHistXMin=uieditfield(selectedHistControls,'numeric','Value',-0.5,'ValueChangedFcn',@selectedResidualHistogramControlsChanged);
    uilabel(selectedHistControls,'Text','X max');selectedHistXMax=uieditfield(selectedHistControls,'numeric','Value',0.5,'ValueChangedFcn',@selectedResidualHistogramControlsChanged);
    selectedHistRangeMode=uidropdown(selectedHistControls,'Items',{'Auto full','Symmetric','+/-3 STD','Manual'},'Value','Auto full','ValueChangedFcn',@selectedResidualHistogramControlsChanged);
    uibutton(selectedHistControls,'Text','Refresh','ButtonPushedFcn',@selectedResidualHistogramControlsChanged);
    axSelectedResidualHistogram=uiaxes(selectedResidualGrid);styleAxes(axSelectedResidualHistogram,C);title(axSelectedResidualHistogram,'Selected residual histogram');

    %% MODEL VALIDATION
    validationRoot=uigridlayout(tabValidation,[1 1]);validationRoot.Padding=[0 0 0 0];
    validationTabs=uitabgroup(validationRoot);
    currentModelValidationTab=uitab(validationTabs,'Title','Current model');
    positionCrossValidationTab=uitab(validationTabs,'Title','Peak-position cross validation');
    gv=uigridlayout(currentModelValidationTab,[4 1]);gv.RowHeight={'1x','1x',34,235};gv.Padding=[7 7 7 7];
    axLOO=uiaxes(gv);styleAxes(axLOO,C);title(axLOO,'Leave-one-out prediction residual');
    axInfluence=uiaxes(gv);styleAxes(axInfluence,C);title(axInfluence,'Maximum calibration-curve change after deleting one point');
    validationTools=uigridlayout(gv,[1 4]);validationTools.ColumnWidth={'1.5x','1x','1x','1x'};validationTools.Padding=[0 0 0 0];
    validationSummary=uilabel(validationTools,'Text','Fit a model to run validation','FontWeight','bold','FontColor',C.navy);
    uibutton(validationTools,'Text','Open selected peak','ButtonPushedFcn',@openValidationPeak);
    uibutton(validationTools,'Text','Remove selected pair','ButtonPushedFcn',@removeValidationPair);
    uibutton(validationTools,'Text','Refresh validation','ButtonPushedFcn',@refreshValidationView);
    validationTable=uitable(gv,'ColumnName',{'Peak','Pixel','Ref nm','Fit r nm','LOO r nm','Curve change nm','FWHM px','ERW/FWHM','Centroid-Center','Flag'}, ...
        'ColumnWidth',{48,58,68,70,75,100,65,78,105,90},'RowName',[],'CellSelectionCallback',@selectValidationRow);

    positionCrossViewRoot=uigridlayout(positionCrossValidationTab,[1 1]);positionCrossViewRoot.Padding=[0 0 0 0];positionCrossViewRoot.RowSpacing=0;positionCrossViewRoot.ColumnSpacing=0;
    positionCrossViewTabs=uitabgroup(positionCrossViewRoot);positionCrossViewTabs.Layout.Row=1;positionCrossViewTabs.Layout.Column=1;
    positionCrossDetailTab=uitab(positionCrossViewTabs,'Title','Detail');
    positionCrossMetricOverviewTab=uitab(positionCrossViewTabs,'Title','All metrics');
    positionCrossRowResidualTab=uitab(positionCrossViewTabs,'Title','Calibration-row residuals');
    positionCrossHistogramOverviewTab=uitab(positionCrossViewTabs,'Title','All histograms');

    positionCrossGrid=uigridlayout(positionCrossDetailTab,[3 2]);positionCrossGrid.RowHeight={124,'1x','1x'};positionCrossGrid.ColumnWidth={'1x','1x'};positionCrossGrid.Padding=[7 7 7 7];positionCrossGrid.RowSpacing=4;positionCrossGrid.ColumnSpacing=4;
    positionCrossTools=uigridlayout(positionCrossGrid,[4 8]);positionCrossTools.Layout.Row=1;positionCrossTools.Layout.Column=[1 2];positionCrossTools.RowHeight={28,28,28,28};positionCrossTools.ColumnWidth={80,70,70,130,45,160,105,95};positionCrossTools.Padding=[0 0 0 0];positionCrossTools.RowSpacing=4;positionCrossTools.ColumnSpacing=4;
    uilabel(positionCrossTools,'Text','Degree');positionCrossDegree=uispinner(positionCrossTools,'Limits',[1 20],'Step',1,'Value',3);positionCrossDegree.Layout.Row=1;positionCrossDegree.Layout.Column=2;
    uilabel(positionCrossTools,'Text','Validation');positionCrossValidationMode=uidropdown(positionCrossTools,'Items',{'Full fit','LOO'},'Value','LOO');positionCrossValidationMode.Layout.Row=1;positionCrossValidationMode.Layout.Column=4;
    uilabel(positionCrossTools,'Text','Pool');positionCrossPoolMode=uidropdown(positionCrossTools, ...
        'Items',{'All-method common peaks (recommended)','Per-pair available peaks'}, ...
        'ItemsData',{'Common intersection','Pairwise available'},'Value','Common intersection', ...
        'Tooltip','All-method common peaks uses the same rows in every matrix cell; per-pair available peaks uses all valid rows for each calibration/application pair.');positionCrossPoolMode.Layout.Row=1;positionCrossPoolMode.Layout.Column=6;
    runPositionCrossBtn=uibutton(positionCrossTools,'Text','Run cross validation','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@runPositionCrossValidation);runPositionCrossBtn.Layout.Row=1;runPositionCrossBtn.Layout.Column=7;
    positionCrossStatus=uilabel(positionCrossTools,'Text','Row = calibration | Column = application.','FontColor',C.navy, ...
        'Tooltip','Matrix rows identify the peak-position definition used to fit calibration; columns identify the peak-position definition supplied during application.');positionCrossStatus.Layout.Row=4;positionCrossStatus.Layout.Column=[1 8];
    positionCrossTrainingLabel=uilabel(positionCrossTools,'Text','Training set');positionCrossTrainingLabel.Layout.Row=2;positionCrossTrainingLabel.Layout.Column=1;
    positionCrossTrainingSource=uidropdown(positionCrossTools, ...
        'Items',{'All matched pairs','Current final model','Selected comparison model','Selected Set Design candidate'}, ...
        'Value','All matched pairs','Tooltip',['Choose the Peak IDs used to fit each matrix row. Full fit evaluates those models on all matched pairs; ' ...
        'LOO evaluates held-out points from the selected training set.']);positionCrossTrainingSource.Layout.Row=2;positionCrossTrainingSource.Layout.Column=[2 4];
    positionCrossTrainingSummary=uilabel(positionCrossTools,'Text','Evaluation set: all matched pairs','FontColor',C.muted);positionCrossTrainingSummary.Layout.Row=2;positionCrossTrainingSummary.Layout.Column=[5 8];
    positionCrossMetricLabel=uilabel(positionCrossTools,'Text','Matrix metric');positionCrossMetricLabel.Layout.Row=3;positionCrossMetricLabel.Layout.Column=1;positionCrossMetric=uidropdown(positionCrossTools,'Items',{'RMSE','Bias','STD','P95','MAX','Slope'},'Value','RMSE','ValueChangedFcn',@positionCrossDisplayChanged);positionCrossMetric.Layout.Row=3;positionCrossMetric.Layout.Column=2;
    positionCrossResidualLabel=uilabel(positionCrossTools,'Text','Residuals');positionCrossResidualLabel.Layout.Row=3;positionCrossResidualLabel.Layout.Column=3;positionCrossResidualView=uidropdown(positionCrossTools, ...
        'Items',{'Selected cell','Selected calibration row','Diagonal comparison'},'Value','Selected cell', ...
        'Tooltip','Selected cell: one calibration-to-application pair. Selected calibration row: one calibration method applied to every method. Diagonal comparison: each method calibrated and applied with the same definition.', ...
        'ValueChangedFcn',@positionCrossDisplayChanged);positionCrossResidualView.Layout.Row=3;positionCrossResidualView.Layout.Column=4;
    exportPositionCrossBtn=uibutton(positionCrossTools,'Text','Export CSV','ButtonPushedFcn',@exportPositionCrossValidation);exportPositionCrossBtn.Layout.Row=3;exportPositionCrossBtn.Layout.Column=8;
    positionCrossSelectionLabel=uilabel(positionCrossTools,'Text','No selected result.','FontColor',C.muted,'Tooltip','No selected result.');positionCrossSelectionLabel.Layout.Row=3;positionCrossSelectionLabel.Layout.Column=[5 7];
    positionCrossHeatmapAxes=uiaxes(positionCrossGrid);positionCrossHeatmapAxes.Layout.Row=2;positionCrossHeatmapAxes.Layout.Column=1;styleAxes(positionCrossHeatmapAxes,C);title(positionCrossHeatmapAxes,'Mismatch matrix');
    positionCrossTable=uitable(positionCrossGrid,'Data',cell(4,4),'ColumnName',{'Direct','Interpolated','FWHM center','Centroid'}, ...
        'ColumnWidth',{58,72,78,64},'RowName',{'Direct','Interpolated','FWHM center','Centroid'}, ...
        'Tooltip','Rows = calibration peak position; columns = application peak position.','CellSelectionCallback',@selectPositionCrossTableCell);positionCrossTable.Layout.Row=2;positionCrossTable.Layout.Column=2;
    positionCrossResidualAxes=uiaxes(positionCrossGrid);positionCrossResidualAxes.Layout.Row=3;positionCrossResidualAxes.Layout.Column=1;styleAxes(positionCrossResidualAxes,C);title(positionCrossResidualAxes,'Cross-method residuals');
    positionCrossHistHost=uigridlayout(positionCrossGrid,[2 1]);positionCrossHistHost.Layout.Row=3;positionCrossHistHost.Layout.Column=2;positionCrossHistHost.RowHeight={'1x',28};positionCrossHistHost.Padding=[0 0 0 0];positionCrossHistHost.RowSpacing=3;
    positionCrossHistogramAxes=uiaxes(positionCrossHistHost);styleAxes(positionCrossHistogramAxes,C);title(positionCrossHistogramAxes,'Selected mismatch residual histogram');
    positionCrossHistTools=uigridlayout(positionCrossHistHost,[1 9]);positionCrossHistTools.Layout.Row=2;positionCrossHistTools.ColumnWidth={32,48,40,65,40,65,82,70,'1x'};positionCrossHistTools.Padding=[0 0 0 0];
    uilabel(positionCrossHistTools,'Text','Bins');positionCrossHistBins=uispinner(positionCrossHistTools,'Limits',[1 100],'Step',1,'Value',10,'ValueChangedFcn',@positionCrossHistogramChanged);
    uilabel(positionCrossHistTools,'Text','X min');positionCrossHistXMin=uieditfield(positionCrossHistTools,'numeric','Value',-0.1,'ValueChangedFcn',@positionCrossHistogramChanged);
    uilabel(positionCrossHistTools,'Text','X max');positionCrossHistXMax=uieditfield(positionCrossHistTools,'numeric','Value',0.1,'ValueChangedFcn',@positionCrossHistogramChanged);
    positionCrossHistRangeMode=uidropdown(positionCrossHistTools,'Items',{'Auto full','Symmetric','+/-3 STD','Manual'},'Value','Auto full','ValueChangedFcn',@positionCrossHistogramChanged);
    uibutton(positionCrossHistTools,'Text','Refresh','ButtonPushedFcn',@positionCrossHistogramChanged);

    positionCrossMetricOverviewGrid=uigridlayout(positionCrossMetricOverviewTab,[2 3]);positionCrossMetricOverviewGrid.RowHeight={'1x','1x'};positionCrossMetricOverviewGrid.ColumnWidth={'1x','1x','1x'};positionCrossMetricOverviewGrid.Padding=[5 5 5 5];positionCrossMetricOverviewGrid.RowSpacing=4;positionCrossMetricOverviewGrid.ColumnSpacing=4;
    positionCrossMetricOverviewAxes=gobjects(1,6);
    for crossInitAxesIndex=1:6,positionCrossMetricOverviewAxes(crossInitAxesIndex)=uiaxes(positionCrossMetricOverviewGrid);styleAxes(positionCrossMetricOverviewAxes(crossInitAxesIndex),C);end

    positionCrossRowResidualGrid=uigridlayout(positionCrossRowResidualTab,[2 2]);positionCrossRowResidualGrid.RowHeight={'1x','1x'};positionCrossRowResidualGrid.ColumnWidth={'1x','1x'};positionCrossRowResidualGrid.Padding=[5 5 5 5];positionCrossRowResidualGrid.RowSpacing=4;positionCrossRowResidualGrid.ColumnSpacing=4;
    positionCrossRowResidualAxes=gobjects(1,4);
    for crossInitAxesIndex=1:4,positionCrossRowResidualAxes(crossInitAxesIndex)=uiaxes(positionCrossRowResidualGrid);styleAxes(positionCrossRowResidualAxes(crossInitAxesIndex),C);end

    positionCrossHistogramOverviewGrid=uigridlayout(positionCrossHistogramOverviewTab,[4 4]);positionCrossHistogramOverviewGrid.RowHeight={'1x','1x','1x','1x'};positionCrossHistogramOverviewGrid.ColumnWidth={'1x','1x','1x','1x'};positionCrossHistogramOverviewGrid.Padding=[4 4 4 4];positionCrossHistogramOverviewGrid.RowSpacing=3;positionCrossHistogramOverviewGrid.ColumnSpacing=3;
    positionCrossHistogramOverviewAxes=gobjects(4,4);
    for crossInitVisualRow=1:4
        for crossInitColumnIndex=1:4
            positionCrossHistogramOverviewAxes(crossInitVisualRow,crossInitColumnIndex)=uiaxes(positionCrossHistogramOverviewGrid);
            styleAxes(positionCrossHistogramOverviewAxes(crossInitVisualRow,crossInitColumnIndex),C);
            positionCrossHistogramOverviewAxes(crossInitVisualRow,crossInitColumnIndex).FontSize=7;
        end
    end

    %% MODEL RESIDUAL COMPARISON
    gc=uigridlayout(tabModelCompare,[3 1]);gc.RowHeight={116,'1x',190};gc.Padding=[7 7 7 7];
    compareTools=uigridlayout(gc,[4 4]);compareTools.ColumnWidth={'1x','1x','1x','1x'};compareTools.RowHeight={28,28,28,24};compareTools.Padding=[0 0 0 0];
    uibutton(compareTools,'Text','Refresh overlays','ButtonPushedFcn',@drawModelComparison);
    uibutton(compareTools,'Text','Import model MAT','ButtonPushedFcn',@importCalibrationModels);
    uibutton(compareTools,'Text','Export current model','ButtonPushedFcn',@exportCurrentModel);
    uibutton(compareTools,'Text','Clear model list','ButtonPushedFcn',@clearCalibrationModels);
    uibutton(compareTools,'Text','Apply selected model','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@applySelectedModel);
    uibutton(compareTools,'Text','Apply current final model','ButtonPushedFcn',@applyCurrentModel);
    uibutton(compareTools,'Text','Import && apply model MAT','ButtonPushedFcn',@importAndApplyModel);
    uibutton(compareTools,'Text','Clear applied model','ButtonPushedFcn',@clearAppliedModel);
    uibutton(compareTools,'Text','Hide / show selected','ButtonPushedFcn',@toggleSelectedModelVisibility);
    uibutton(compareTools,'Text','Delete selected','ButtonPushedFcn',@deleteSelectedModel);
    compareResidualMode=uidropdown(compareTools,'Items',{'Fit residual','LOO residual','All matched points'},'Value','Fit residual','ValueChangedFcn',@drawModelComparison);compareResidualMode.Layout.Row=3;compareResidualMode.Layout.Column=3;
    uibutton(compareTools,'Text','Reset plot scale','ButtonPushedFcn',@resetModelCompareView);
    appliedStatus=uilabel(compareTools,'Text','Applied model: none | spectrum axis remains Pixel','FontWeight','bold','FontColor',C.navy);appliedStatus.Layout.Column=[1 4];appliedStatus.Layout.Row=4;
    axModelCompare=uiaxes(gc);styleAxes(axModelCompare,C);title(axModelCompare,'Stored-model residual comparison');
    modelComparisonTable=uitable(gc,'ColumnName',{'Model','N','Peak position','Degree','Pixel mode','Pixel domain','Fit RMS','LOO RMS','LOO max','Influence','STD','Max','Equation'}, ...
        'ColumnWidth',{58,38,100,50,135,90,65,68,68,68,60,60,320},'RowName',[],'CellSelectionCallback',@selectModelRow);

    %% REFERENCE OVERVIEW AND FINAL FIT TAB
    gf=uigridlayout(tabFit,[11 2]); gf.ColumnWidth={145,'1x'};
    gf.RowHeight={24,'1x',24,26,26,32,32,34,105,55,40};
    gf.Padding=[7 7 7 7]; gf.RowSpacing=3;
    sectionAuto(gf,'Active reference set');
    activeRefTable=uitable(gf,'ColumnName',{'nm','Intensity','Spacing','Status'},'ColumnWidth',{72,70,65,95},'RowName',[]); activeRefTable.Layout.Column=[1 2];
    sectionAuto(gf,'Final calibration model');
    uilabel(gf,'Text','Peak position'); positionDrop=uidropdown(gf,'Items',{'Direct peak','Interpolated peak','FWHM center','Centroid','Gaussian fit'},'Value','FWHM center');
    uilabel(gf,'Text','Polynomial degree'); degreeSpin=uispinner(gf,'Limits',[1 20],'Step',1,'Value',3);
    fitBtn=uibutton(gf,'Text','FIT CALIBRATION MODEL','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@fitFinalCalibration); fitBtn.Layout.Column=[1 2];
    saveModelBtn=uibutton(gf,'Text','SAVE / EXPORT CURRENT MODEL','FontWeight','bold','ButtonPushedFcn',@exportCurrentModel);saveModelBtn.Layout.Column=[1 2];
    calibratedStatsBtn=uibutton(gf,'Text','PLOT CALIBRATED PERFORMANCE','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@plotCalibratedPerformance);calibratedStatsBtn.Layout.Column=[1 2];
    equationDisplay=uitextarea(gf,'Value',{'No calibration equation.'},'Editable','off','FontName','Courier New');equationDisplay.Layout.Column=[1 2];
    fitResultLabel=uilabel(gf,'Text','No final calibration model. At least degree+2 matched points are recommended.', ...
        'WordWrap','on','FontColor',C.navy,'FontWeight','bold'); fitResultLabel.Layout.Column=[1 2];
    fitHelp=uilabel(gf,'Text','Create about six manual anchor pairs, update the initial model, then use Auto extend. Every final fit is retained as a model snapshot for residual comparison.', ...
        'WordWrap','on','FontColor',C.muted); fitHelp.Layout.Column=[1 2];

    function refreshOptimizationSeeds(~,~)
        valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
        if isempty(valid)
            optimizationSeedTable.Data=cell(0,4);optimizationStatus.Text='No valid calibration pairs.';return;
        end
        oldData=optimizationSeedTable.Data;oldIDs=strings(0,1);oldSelected=false(0,1);
        if ~isempty(oldData)
            oldIDs=string(oldData(:,2));oldSelected=logical(cell2mat(oldData(:,1)));
        end
        dat=cell(0,4);excluded=0;
        for k=1:numel(valid)
            q=calPairs(valid(k));xp=pairPeakPosition(q,optimizationPositionMethod.Value);
            if ~isfinite(xp),excluded=excluded+1;continue;end
            use=true;oldRow=find(oldIDs==string(q.PeakID),1);if ~isempty(oldRow),use=oldSelected(oldRow);end
            dat(end+1,:)={use,q.PeakID,xp,q.ReferenceWavelength}; %#ok<AGROW>
        end
        optimizationSeedTable.Data=dat;
        optimizationStatus.Text=sprintf('%d usable pairs | %s | %d unavailable excluded.',size(dat,1),optimizationPositionMethod.Value,excluded);
    end

    function optimizationPositionMethodChanged(~,~)
        optimizationPath=struct();optimizationStability=struct();optimizationViewMode='';optimizationHistoryTable.Data=cell(0,9);
        cla(optimizationAxes,'reset');styleAxes(optimizationAxes,C);title(optimizationAxes,'Sequential Add-One validation path');
        clearSetDesignState('Peak-position method changed; refresh the Set Design pool.');
        refreshOptimizationSeeds([],[]);
    end

    function influencePositionMethodChanged(~,~)
        refreshInfluenceTable('preserveSeed',[]);
        influenceStatus.Text=sprintf('%s selected; run a single degree or the 1..k scan.',influencePositionMethod.Value);
    end

    function optimizationSeedEdited(~,~)
        optimizationPath=struct();optimizationStability=struct();optimizationViewMode='';optimizationHistoryTable.Data=cell(0,9);cla(optimizationAxes);
        title(optimizationAxes,'Sequential Add-One validation path');
        clearReplacementResults('Selected set changed; run replacement validation again.');
    end

    function selectAllOptimizationSeeds(~,~)
        dat=optimizationSeedTable.Data;
        if isempty(dat),return;end
        for k=1:size(dat,1),dat{k,1}=true;end
        optimizationSeedTable.Data=dat;optimizationSeedEdited([],[]);
    end

    function clearOptimizationSeeds(~,~)
        dat=optimizationSeedTable.Data;
        if isempty(dat),return;end
        for k=1:size(dat,1),dat{k,1}=false;end
        optimizationSeedTable.Data=dat;optimizationSeedEdited([],[]);
    end

    function [px,wl,seedMask,sourceRows]=optimizationInputs
        dat=optimizationSeedTable.Data;
        if isempty(dat),error('WCC4SM:OptimizationNoPairs','No valid calibration pairs are available.');end
        include=true(size(dat,1),1);if strcmp(optimizationBenchmarkMode.Value,'Symmetry-recommended benchmark')
            for ii=1:size(dat,1),include(ii)=isSymmetryRecommended(char(string(dat{ii,2})));end
        end
        sourceRows=find(include);seedMask=logical(cell2mat(dat(sourceRows,1)));px=cell2mat(dat(sourceRows,3));wl=cell2mat(dat(sourceRows,4));
        if sum(seedMask)<optimizationDegree.Value+1
            error('WCC4SM:OptimizationInsufficientSeed','Select at least degree+1 points.');
        end
    end

    function runOptimizationPath(~,~)
        try
            [px,wl,seedMask]=optimizationInputs();
            optimizationViewMode='Add-One';try,optimizationHistoryTable.Selection=[];catch,end
            optimizationHistoryTable.ColumnName={'Round','Ncal','Selected','Fit RMSE','All-point RMSE','P95','MAX','Candidates','Status'};
            optimizationPath=wc4sm_analyze_add_one_path(px,wl,seedMask,optimizationDegree.Value,px,struct('StopWhenCandidates',optimizationStop.Value,'ValidationMode','All points'));
            h=optimizationPath.History;
            if isempty(h)
                optimizationHistoryTable.Data=cell(0,9);
            else
                optimizationHistoryTable.Data=num2cell([[h.Round].',[h.Ncal].',[h.SelectedIndex].',[h.FitRMSE].',[h.ValidationRMSE].',[h.ValidationP95].',[h.ValidationMAX].',[h.CandidateCount].']);
                optimizationHistoryTable.Data(:,9)=cellstr(string({h.Status}.'));
            end
            plotOptimizationPath(optimizationPath);
            if isfinite(optimizationPath.FullSetRMSEGap)
                optimizationStatus.Text=sprintf('Completed full set | %s | Fit/All-point RMSE gap %.3g nm',optimizationPositionMethod.Value,optimizationPath.FullSetRMSEGap);
            else
                optimizationStatus.Text=sprintf('Completed: %s | %s | fixed All points validation',optimizationPath.TerminationReason,optimizationPositionMethod.Value);
            end
        catch ME
            uialert(fig,ME.message,'Calibration optimization failed');
        end
    end

    function runOptimizationStability(~,~)
        try
            [px,wl,seedMask]=optimizationInputs();
            optimizationViewMode='Seed stability';try,optimizationHistoryTable.Selection=[];catch,end
            optimizationHistoryTable.ColumnName={'Seed set','Seed count','Final Ncal','Final RMSE','P95','MAX','Rounds','Added indices'};
            seeds=[seedMask,seedMask];
            alternate=find(seedMask,1,'first'); replacement=find(~seedMask,1,'first');
            if ~isempty(alternate)&&~isempty(replacement)
                seeds(alternate,2)=false;seeds(replacement,2)=true;
            end
            optimizationStability=wc4sm_analyze_seed_stability(px,wl,seeds,optimizationDegree.Value,px,struct('StopWhenCandidates',optimizationStop.Value,'ValidationMode','All points'));
            s=optimizationStability.Summary;optimizationHistoryTable.Data=cell(numel(s),8);
            for k=1:numel(s),optimizationHistoryTable.Data(k,:)={s(k).SeedID,s(k).SeedCount,s(k).FinalNcal,s(k).FinalValidationRMSE,NaN,NaN,s(k).Rounds,mat2str(s(k).SelectedIndices)};end
            cla(optimizationAxes);optimizationAxes.YScale='linear';bar(optimizationAxes,[s.FinalValidationRMSE]);xlabel(optimizationAxes,'Seed set');ylabel(optimizationAxes,'Final validation RMSE (nm)');title(optimizationAxes,'Seed stability comparison');grid(optimizationAxes,'on');optimizationStatus.Text=sprintf('Compared %d seed sets.',numel(s));
        catch ME
            uialert(fig,ME.message,'Seed stability failed');
        end
    end

    function runOptimizationOrder(~,~)
        try
            optimizationViewMode='Model order';try,optimizationHistoryTable.Selection=[];catch,end
            dat=optimizationSeedTable.Data;
            if isempty(dat),error('WCC4SM:OptimizationNoPairs','No valid calibration pairs are available.');end
            px=cell2mat(dat(:,3));wl=cell2mat(dat(:,4));
            requestedMax=round(optimizationMaxOrder.Value);
            maxDegree=min(requestedMax,numel(px)-2);
            if maxDegree<1
                error('WCC4SM:OptimizationInsufficientPoints','At least three reference points are required for paired Fit and LOO order analysis.');
            end
            optimizationOrder=wc4sm_analyze_model_order(px,wl,1:maxDegree,px);
            r=optimizationOrder;
            optimizationHistoryTable.ColumnName={'Degree','Fit RMSE','Fit MAX','LOO RMSE','LOO MAX','Status'};
            dat=cell(numel(r),6);
            for k=1:numel(r)
                dat(k,:)={r(k).Degree,r(k).FitRMSE,r(k).FitMAX,r(k).LOORMSE,r(k).LOOMAX,r(k).Status};
            end
            optimizationHistoryTable.Data=dat;
            cla(optimizationAxes);optimizationAxes.YScale='log';hold(optimizationAxes,'on');
            plot(optimizationAxes,[r.Degree],[r.FitRMSE],'-o','DisplayName','Fit RMSE');
            plot(optimizationAxes,[r.Degree],[r.LOORMSE],'-s','DisplayName','LOO RMSE');
            hold(optimizationAxes,'off');grid(optimizationAxes,'on');xlabel(optimizationAxes,'Polynomial degree');ylabel(optimizationAxes,'Error (nm)');title(optimizationAxes,'Polynomial model-order scan | logarithmic Y axis');legend(optimizationAxes,'Location','best');
            if maxDegree<requestedMax
                optimizationStatus.Text=sprintf('Requested order %d; scanned 1..%d because paired Fit/LOO analysis requires degree+2 points.',requestedMax,maxDegree);
            else
                optimizationStatus.Text=sprintf('Scanned polynomial orders 1 to %d on a logarithmic error axis.',maxDegree);
            end
        catch ME
            uialert(fig,ME.message,'Model-order scan failed');
        end
    end

    function plotOptimizationPath(path)
        h=path.History;cla(optimizationAxes);optimizationAxes.YScale='linear';if isempty(h),title(optimizationAxes,'No valid Add-One rounds');return;end
        plot(optimizationAxes,[h.Ncal],[h.FitRMSE],'-d','LineWidth',1.2,'DisplayName','Fit RMSE');hold(optimizationAxes,'on');
        plot(optimizationAxes,[h.Ncal],[h.ValidationRMSE],'-o','LineWidth',1.4,'DisplayName','All-point RMSE');
        plot(optimizationAxes,[h.Ncal],[h.ValidationP95],'-s','DisplayName','All-point P95');plot(optimizationAxes,[h.Ncal],[h.ValidationMAX],'-^','DisplayName','All-point MAX');
        hold(optimizationAxes,'off');grid(optimizationAxes,'on');xlabel(optimizationAxes,'Calibration points');ylabel(optimizationAxes,'Error (nm)');
        title(optimizationAxes,sprintf('Sequential Add-One | %s | fixed All points validation',optimizationPositionMethod.Value));legend(optimizationAxes,'Location','best');
    end

    function selectOptimizationHistoryRow(~,event)
        if isempty(event.Indices),return;end
        row=event.Indices(end,1);
        switch optimizationViewMode
            case 'Add-One'
                if ~isfield(optimizationPath,'History')||row>numel(optimizationPath.History),return;end
                h=optimizationPath.History(row);
                setSelectedResidualDiagnostics(h.EvaluationPixels,h.Residual, ...
                    sprintf('Add-One round %d | Ncal %d | %s d%d',h.Round,h.Ncal,optimizationPositionMethod.Value,optimizationDegree.Value),'Pixel');
            case 'Model order'
                if row>numel(optimizationOrder)||isempty(optimizationOrder(row).Model),return;end
                m=optimizationOrder(row).Model;
                setSelectedResidualDiagnostics(m.ReferenceWavelength,m.Residual, ...
                    sprintf('Model order degree %d | %s',optimizationOrder(row).Degree,optimizationPositionMethod.Value),'Reference wavelength (nm)');
            case 'Seed stability'
                if ~isfield(optimizationStability,'Paths')||row>numel(optimizationStability.Paths),return;end
                path=optimizationStability.Paths{row};if isempty(path.History),return;end
                h=path.History(end);
                setSelectedResidualDiagnostics(h.EvaluationPixels,h.Residual, ...
                    sprintf('Seed stability set %d | final Ncal %d | %s d%d',row,h.Ncal,optimizationPositionMethod.Value,optimizationDegree.Value),'Pixel');
        end
    end

    function exportOptimizationResults(~,~)
        if isempty(fieldnames(optimizationPath)),uialert(fig,'Run Add-One Path first.','Nothing to export');return;end
        [fn,pn]=uiputfile('add_one_history.csv','Export Add-One history');if isequal(fn,0),return;end
        try
            files=wc4sm_export_optimization_csv([],optimizationPath,pn);if ~isempty(files.AddOneHistory)&&~strcmp(files.AddOneHistory,fullfile(pn,'add_one_history.csv')),movefile(files.AddOneHistory,fullfile(pn,fn),'f');end
            optimizationStatus.Text=['Exported: ' fullfile(pn,fn)];
        catch ME
            uialert(fig,ME.message,'Export failed');
        end
    end

    function refreshInfluenceTable(source,~)
        if nargin<1,source=[];end
        preserveSeed=ischar(source)&&strcmp(source,'preserveSeed');
        influenceResult=struct();influenceOrderStats=struct([]);influenceViewMode='Point influence';
        if ~preserveSeed
            clearReplacementResults('Calibration pairs changed; select a set and run replacement validation again.');
        end
        cla(influenceAxes,'reset');styleAxes(influenceAxes,C);title(influenceAxes,'Point influence by deletion');
        cla(influenceFullErrorAxes,'reset');styleAxes(influenceFullErrorAxes,C);title(influenceFullErrorAxes,'Full-set Fit versus LOO RMSE');
        cla(influenceGapAxes,'reset');styleAxes(influenceGapAxes,C);title(influenceGapAxes,'Generalization gap: LOO RMSE - Fit RMSE');
        cla(influenceOrderStatsAxes,'reset');styleAxes(influenceOrderStatsAxes,C);title(influenceOrderStatsAxes,'Influence statistics across polynomial orders');
        cla(influenceDeletionErrorAxes,'reset');styleAxes(influenceDeletionErrorAxes,C);title(influenceDeletionErrorAxes,'Full-set and point-deleted model errors');
        valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
        influenceTable.ColumnName={'Index','Peak','Pixel','Reference nm','Residual','Deleted Fit RMSE','Deleted LOO RMSE','Curve change','Influence','Match status','Class','Recommendation'};
        dat=cell(numel(peaks),12);
        for k=1:numel(peaks)
            id=peaks(k).ID;q=find(strcmp({calPairs.PeakID},id) & [calPairs.ReferenceIndex]>0,1);
            if isempty(q)
                dat(k,:)={k,id,peaks(k).Pixel,NaN,NaN,NaN,NaN,NaN,NaN,'Unmatched','Unclassified','Not available for calibration'};
            else
                xp=pairPeakPosition(calPairs(q),influencePositionMethod.Value);
                if isfinite(xp)
                    dat(k,:)={k,id,xp,calPairs(q).ReferenceWavelength,NaN,NaN,NaN,NaN,NaN,'Active matched','Pending analysis','Analyze influence'};
                else
                    dat(k,:)={k,id,NaN,calPairs(q).ReferenceWavelength,NaN,NaN,NaN,NaN,NaN,'Unavailable','Unclassified',[influencePositionMethod.Value ' position unavailable']};
                end
            end
        end
        usable=sum(strcmp(dat(:,10),'Active matched'));
        influenceTable.Data=dat;influenceStatus.Text=sprintf('%d usable pairs | %s.',usable,influencePositionMethod.Value);
    end

    function clearReplacementResults(message)
        if nargin<1||isempty(message),message='Select a set in Calibration Optimization and leave at least one valid candidate unselected.';end
        seedComboResult=struct();selectedSeedRound=0;pendingSeedModelItem=struct();addRecommendedSeedModelBtn.Enable='off';
        try,replacementTable.Selection=[];catch,end
        replacementTable.ColumnName={'Round','Removed point','Replacement','Fit RMSE','Validation RMSE','Delta RMSE','P95','MAX','Conclusion'};
        replacementTable.Data=cell(0,9);
        legend(seedReplacementAxes,'off');cla(seedReplacementAxes,'reset');styleAxes(seedReplacementAxes,C);title(seedReplacementAxes,'Set replacement residuals');
        replacementStatus.Text=message;
    end

    function runPointInfluence(~,~)
        try
            refreshInfluenceTable('preserveSeed',[]);
            influenceViewMode='Point influence';
            % Use the peak-position convention explicitly selected on this page.
            [px,wl,ids]=analysisInputsForPosition(influencePositionMethod.Value);
            influenceResult=wc4sm_analyze_point_influence(px,wl,influenceDegree.Value);
            influenceResult.PositionMethod=influencePositionMethod.Value;
            p=influenceResult.Points;dat=influenceTable.Data;
            for k=1:numel(p)
                row=find(strcmp(dat(:,2),ids{k}),1);
                dat(row,5:9)={p(k).Residual,p(k).DeletedRMS,p(k).DeletedLOORMSE,p(k).CurveChange,p(k).InfluenceRatio};
                dat(row,11:12)={p(k).Class,p(k).Recommendation};
            end
            influenceTable.Data=dat;
            drawPointInfluence();
            influenceDiagnosticTabs.SelectedTab=pointInfluencePlotTab;
            influenceFeatureTabs.SelectedTab=sampleInfluenceTab;
            influenceStatus.Text=sprintf('Analyzed %d matched points | %s | degree %d.',numel(p),influencePositionMethod.Value,influenceResult.Degree);
        catch ME
            uialert(fig,ME.message,'Point influence analysis failed');
        end
    end

    function runInfluenceOrderScan(~,~)
        try
            refreshInfluenceTable('preserveSeed',[]);influenceViewMode='Influence order scan';
            % Keep the order scan on the same pool/position coordinates as the
            % single-degree influence analysis.
            [px,wl]=analysisInputsForPosition(influencePositionMethod.Value);
            requestedMax=round(influenceMaxOrder.Value);
            maxDegree=min(requestedMax,numel(px)-3);
            if maxDegree<1,error('WCC4SM:InfluenceInsufficientPoints','At least four matched points are required so point-deleted models retain LOO validation.');end
            influenceOrderStats=wc4sm_analyze_influence_orders(px,wl,1:maxDegree);
            s=influenceOrderStats;influenceTable.ColumnName={'Degree','Full Fit RMSE','Full LOO RMSE','Full gap','Deleted Fit RMSE','Deleted LOO RMSE','Deleted gap','Mean influence','RMS influence','P95 influence','MAX influence','Status'};
            dat=cell(numel(s),12);
            for k=1:numel(s)
                influenceOrderStats(k).PositionMethod=influencePositionMethod.Value;
                dat(k,:)={s(k).Degree,s(k).FullFitRMSE,s(k).FullLOORMSE,s(k).FullGeneralizationGap,s(k).DeletionFitRMSE,s(k).DeletionLOORMSE,s(k).DeletionGeneralizationGap,s(k).MeanInfluence,s(k).RMSInfluence,s(k).P95Influence,s(k).MAXInfluence,s(k).Status};
            end
            influenceTable.Data=dat;available=find(strcmp({s.Status},'Available'));
            if isempty(available),error('WCC4SM:InfluenceOrderScanFailed','No model order produced valid influence statistics.');end
            row=find([s.Degree]==min(influenceDegree.Value,maxDegree)&strcmp({s.Status},'Available'),1);
            if isempty(row),row=available(1);end
            influenceResult=s(row).Result;influenceDegree.Value=s(row).Degree;drawPointInfluence();drawInfluenceOrderCurves();
            try,influenceTable.Selection=[row 1];catch,end
            influenceFeatureTabs.SelectedTab=sampleInfluenceTab;influenceDiagnosticTabs.SelectedTab=influenceOrderPlotTab;influenceOrderViewTabs.SelectedTab=influenceFullOrderTab;
            if maxDegree<requestedMax
                influenceStatus.Text=sprintf('%s | requested order %d; scanned 1..%d because nested point-deletion LOO requires degree+3 points.',influencePositionMethod.Value,requestedMax,maxDegree);
            else
                influenceStatus.Text=sprintf('%s | influence and deletion-error statistics completed for degrees 1..%d; select a row for per-point detail.',influencePositionMethod.Value,maxDegree);
            end
        catch ME
            uialert(fig,ME.message,'Influence order scan failed');
        end
    end

    function drawInfluenceOrderCurves
        cla(influenceFullErrorAxes,'reset');styleAxes(influenceFullErrorAxes,C);
        cla(influenceGapAxes,'reset');styleAxes(influenceGapAxes,C);
        cla(influenceOrderStatsAxes,'reset');styleAxes(influenceOrderStatsAxes,C);
        cla(influenceDeletionErrorAxes,'reset');styleAxes(influenceDeletionErrorAxes,C);
        if isempty(influenceOrderStats),return;end
        s=influenceOrderStats;d=[s.Degree];
        hold(influenceFullErrorAxes,'on');
        semilogy(influenceFullErrorAxes,d,[s.FullFitRMSE],'-o','DisplayName','Fit RMSE');
        semilogy(influenceFullErrorAxes,d,[s.FullLOORMSE],'-s','DisplayName','LOO RMSE');
        hold(influenceFullErrorAxes,'off');influenceFullErrorAxes.YScale='log';influenceFullErrorAxes.YLimMode='auto';grid(influenceFullErrorAxes,'on');
        xlabel(influenceFullErrorAxes,'Polynomial degree');ylabel(influenceFullErrorAxes,'RMSE (nm)');
        title(influenceFullErrorAxes,sprintf('%s | Full-set Fit versus LOO RMSE | logarithmic Y axis',influencePositionMethod.Value));legend(influenceFullErrorAxes,'Location','best');
        fullGap=[s.FullGeneralizationGap];deletedGap=[s.DeletionGeneralizationGap];
        gapValues=[fullGap deletedGap];finiteGap=gapValues(isfinite(gapValues));
        hold(influenceGapAxes,'on');
        if ~isempty(finiteGap)&&all(finiteGap>0)
            semilogy(influenceGapAxes,d,fullGap,'-o','DisplayName','Full-set gap');
            semilogy(influenceGapAxes,d,deletedGap,'-s','DisplayName','Point-deleted pool gap');
            influenceGapAxes.YScale='log';gapScale='logarithmic Y axis';
        else
            plot(influenceGapAxes,d,fullGap,'-o','DisplayName','Full-set gap');
            plot(influenceGapAxes,d,deletedGap,'-s','DisplayName','Point-deleted pool gap');
            yline(influenceGapAxes,0,'--','HandleVisibility','off');
            influenceGapAxes.YScale='linear';gapScale='linear Y axis (signed gap includes zero or negative values)';
        end
        hold(influenceGapAxes,'off');influenceGapAxes.YLimMode='auto';grid(influenceGapAxes,'on');
        xlabel(influenceGapAxes,'Polynomial degree');ylabel(influenceGapAxes,'LOO RMSE - Fit RMSE (nm)');
        title(influenceGapAxes,sprintf('%s | Generalization gap | %s',influencePositionMethod.Value,gapScale));legend(influenceGapAxes,'Location','best');
        hold(influenceOrderStatsAxes,'on');
        semilogy(influenceOrderStatsAxes,d,[s.MeanInfluence],'-o','DisplayName','Mean influence');
        semilogy(influenceOrderStatsAxes,d,[s.RMSInfluence],'-s','DisplayName','RMS influence');
        semilogy(influenceOrderStatsAxes,d,[s.P95Influence],'-d','DisplayName','P95 influence');
        semilogy(influenceOrderStatsAxes,d,[s.MAXInfluence],'-^','DisplayName','MAX influence');
        hold(influenceOrderStatsAxes,'off');influenceOrderStatsAxes.YScale='log';influenceOrderStatsAxes.YLimMode='auto';grid(influenceOrderStatsAxes,'on');
        xlabel(influenceOrderStatsAxes,'Polynomial degree');ylabel(influenceOrderStatsAxes,'Influence ratio (dimensionless)');
        title(influenceOrderStatsAxes,sprintf('%s | Deletion influence statistics | logarithmic Y axis',influencePositionMethod.Value));legend(influenceOrderStatsAxes,'Location','best');
        hold(influenceDeletionErrorAxes,'on');
        semilogy(influenceDeletionErrorAxes,d,[s.FullFitRMSE],'-o','DisplayName','Full Fit RMSE');
        semilogy(influenceDeletionErrorAxes,d,[s.FullLOORMSE],'-s','DisplayName','Full LOO RMSE');
        semilogy(influenceDeletionErrorAxes,d,[s.DeletionFitRMSE],'-d','DisplayName','Deleted-model Fit RMSE');
        semilogy(influenceDeletionErrorAxes,d,[s.DeletionLOORMSE],'-^','DisplayName','Deleted-model LOO RMSE');
        hold(influenceDeletionErrorAxes,'off');influenceDeletionErrorAxes.YScale='log';influenceDeletionErrorAxes.YLimMode='auto';grid(influenceDeletionErrorAxes,'on');
        xlabel(influenceDeletionErrorAxes,'Polynomial degree');ylabel(influenceDeletionErrorAxes,'RMSE (nm)');
        title(influenceDeletionErrorAxes,sprintf('%s | Full-set versus pooled point-deleted models | logarithmic Y axis',influencePositionMethod.Value));legend(influenceDeletionErrorAxes,'Location','best');
    end

    function influenceXAxisChanged(~,~)
        drawPointInfluence();
    end

    function influenceAxisSettingsChanged(~,~)
        drawPointInfluence();
    end

    function drawPointInfluence
        cla(influenceAxes,'reset');styleAxes(influenceAxes,C);title(influenceAxes,'Point influence by deletion');
        if isempty(fieldnames(influenceResult))||~isfield(influenceResult,'Points')||isempty(influenceResult.Points)
            xlabel(influenceAxes,influenceXAxisMode.Value);ylabel(influenceAxes,'Deletion influence');return;
        end
        p=influenceResult.Points;y=[p.InfluenceRatio];
        switch influenceXAxisMode.Value
            case 'Pixel'
                x=[p.Pixel];xLabel='Pixel';
            case 'Wavelength'
                x=[p.Wavelength];xLabel='Reference wavelength (nm)';
            otherwise
                x=1:numel(p);xLabel='Sample index';
        end
        [x,ord]=sort(x);y=y(ord);
        bar(influenceAxes,x,y,0.75,'FaceColor',C.blue);grid(influenceAxes,'on');
        if strcmp(influenceYMode.Value,'Manual')
            lo=influenceYMin.Value;hi=influenceYMax.Value;
            if isfinite(lo)&&isfinite(hi)&&hi>lo
                ylim(influenceAxes,[lo hi]);
            else
                influenceStatus.Text='Manual Y axis requires finite values with Y max greater than Y min.';
            end
        end
        xlabel(influenceAxes,xLabel);ylabel(influenceAxes,'Deletion influence');
        title(influenceAxes,sprintf('Point influence by deletion | %s | degree %d | %s',influencePositionMethod.Value,influenceResult.Degree,xLabel));
    end

    function runSeedReplacements(~,~)
        try
            selectedSeedRound=0;pendingSeedModelItem=struct();addRecommendedSeedModelBtn.Enable='off';
            try,replacementTable.Selection=[];catch,end
            legend(seedReplacementAxes,'off');cla(seedReplacementAxes,'reset');styleAxes(seedReplacementAxes,C);title(seedReplacementAxes,'Set replacement residuals');
            [px,wl,seedMask,sourceRows]=optimizationInputs();
            if all(seedMask),error('WCC4SM:SetReplacementNoCandidates','Leave at least one valid pair unselected as a replacement candidate.');end
            seedComboResult=wc4sm_analyze_seed_replacements(px,wl,seedMask,optimizationDegree.Value,struct('ValidationMode',seedValidationMode.Value,'RMSEThreshold',replacementRMSEThreshold.Value));
            seedComboResult.PositionMethod=optimizationPositionMethod.Value;r=seedComboResult.BestByRemovedSeed;
            replacementTable.ColumnName={'Round','Removed point','Replacement','Fit RMSE','Validation RMSE','Delta RMSE','P95','MAX','Conclusion'};dat=cell(numel(r),9);seedData=optimizationSeedTable.Data;
            for k=1:numel(r)
                conclusion='Not recommended';if r(k).IsRecommended,conclusion='Recommended';elseif r(k).IsImprovement,conclusion='Small improvement';else,conclusion='Worse';end
                removedLabel=sprintf('%s [%d]',char(string(seedData(sourceRows(r(k).RemovedIndex),2))),r(k).RemovedIndex);replacementLabel=sprintf('%s [%d]',char(string(seedData(sourceRows(r(k).CandidateIndex),2))),r(k).CandidateIndex);
                dat(k,:)={k,removedLabel,replacementLabel,r(k).FitRMSE,r(k).ValidationRMSE,r(k).DeltaRMSE,r(k).ValidationP95,r(k).ValidationMAX,conclusion};
            end
            replacementTable.Data=dat;drawSeedReplacementResiduals();influenceFeatureTabs.SelectedTab=setReplacementTab;
            improved=sum([r.IsRecommended]);
            recommendedRounds=find([r.IsRecommended]);if isempty(recommendedRounds),replacementStatus.Text=sprintf('Completed %d replacement trials | %s d%d | %s; no replacement exceeded the RMSE threshold %.4g nm.',seedComboResult.TotalTrials,seedComboResult.PositionMethod,seedComboResult.Degree,seedComboResult.ValidationMode,replacementRMSEThreshold.Value);return;end
            [~,localBest]=min([r(recommendedRounds).ValidationRMSE]);bestRound=recommendedRounds(localBest);recommendedIndices=r(bestRound).SeedIndices(:);recommendedPixels=px(recommendedIndices);recommendedWavelengths=wl(recommendedIndices);recommendedIDs=cellstr(string(seedData(sourceRows(recommendedIndices),2)));
            recommendedModel=wc4sm_fit_calibration(recommendedPixels,recommendedWavelengths,optimizationDegree.Value,px,optimizationPositionMethod.Value,recommendedIDs);recommendedModel=attachPixelCoordinateMetadata(recommendedModel);
            pendingSeedModelItem=struct('ModelID','','CreatedAt',datetime('now'),'PairCount',numel(recommendedIndices),'PositionMethod',optimizationPositionMethod.Value,'Degree',recommendedModel.Degree,'PairIDs',{recommendedIDs},'Model',recommendedModel,'Visible',true);
            addRecommendedSeedModelBtn.Enable='on';
            replacementStatus.Text=sprintf('Completed %d replacement trials in %d rounds | %s d%d | %s; %d replacements exceed the RMSE threshold. Review, then add manually.',seedComboResult.TotalTrials,numel(r),seedComboResult.PositionMethod,seedComboResult.Degree,seedComboResult.ValidationMode,improved);
        catch ME
            replacementStatus.Text=ME.message;
            uialert(fig,ME.message,'Selected-set replacement validation failed');
        end
    end

    function selectInfluenceResultRow(~,event)
        if isempty(event.Indices),return;end
        row=event.Indices(end,1);
        if strcmp(influenceViewMode,'Influence order scan')
            if row<1||row>numel(influenceOrderStats)||isempty(influenceOrderStats(row).Result),return;end
            influenceResult=influenceOrderStats(row).Result;influenceDegree.Value=influenceOrderStats(row).Degree;
            drawPointInfluence();influenceFeatureTabs.SelectedTab=sampleInfluenceTab;influenceDiagnosticTabs.SelectedTab=pointInfluencePlotTab;
            influenceStatus.Text=sprintf('%s | degree %d | full Fit/LOO/gap %.6g/%.6g/%.6g nm | deleted Fit/LOO/gap %.6g/%.6g/%.6g nm | RMS influence %.6g.', ...
                influencePositionMethod.Value,influenceOrderStats(row).Degree,influenceOrderStats(row).FullFitRMSE,influenceOrderStats(row).FullLOORMSE, ...
                influenceOrderStats(row).FullGeneralizationGap,influenceOrderStats(row).DeletionFitRMSE, ...
                influenceOrderStats(row).DeletionLOORMSE,influenceOrderStats(row).DeletionGeneralizationGap,influenceOrderStats(row).RMSInfluence);
            return;
        end
    end

    function selectReplacementResultRow(~,event)
        if isempty(event.Indices)||~isstruct(seedComboResult)||~isfield(seedComboResult,'BestByRemovedSeed'),return;end
        row=event.Indices(end,1);
        if row<1||row>numel(seedComboResult.BestByRemovedSeed),selectedSeedRound=0;return;end
        selectedSeedRound=row;drawSeedReplacementResiduals();
    end

    function drawSeedReplacementResiduals
        if ~isstruct(seedComboResult)||~isfield(seedComboResult,'BestByRemovedSeed'),return;end
        r=seedComboResult.BestByRemovedSeed;baseline=seedComboResult.Baseline.ValidationRMSE;
        hold(seedReplacementAxes,'off');legend(seedReplacementAxes,'off');cla(seedReplacementAxes,'reset');styleAxes(seedReplacementAxes,C);hold(seedReplacementAxes,'on');
        scatter(seedReplacementAxes,seedComboResult.Baseline.EvaluationPixels,seedComboResult.Baseline.Residual,28,'k','filled','DisplayName','Baseline');
        cols=lines(max(1,numel(r)));
        for jj=1:numel(r)
            if jj==selectedSeedRound,continue;end
            scatter(seedReplacementAxes,r(jj).EvaluationPixels,r(jj).Residual,22,cols(jj,:),'filled','DisplayName',sprintf('Round %d',jj));
        end
        if selectedSeedRound>=1&&selectedSeedRound<=numel(r)
            rr=r(selectedSeedRound);[sx,ord]=sort(rr.EvaluationPixels);sy=rr.Residual(ord);
            plot(seedReplacementAxes,sx,sy,'-','Color',cols(selectedSeedRound,:),'LineWidth',1.8,'HandleVisibility','off');
            scatter(seedReplacementAxes,rr.EvaluationPixels,rr.Residual,52,cols(selectedSeedRound,:),'filled','MarkerEdgeColor','k','LineWidth',1.0, ...
                'DisplayName',sprintf('[SELECTED] Round %d',selectedSeedRound));
            text(seedReplacementAxes,.015,.97,sprintf('Selected Round %d | RMSE %.6g nm',selectedSeedRound,rr.ValidationRMSE), ...
                'Units','normalized','VerticalAlignment','top','FontWeight','bold','Color',cols(selectedSeedRound,:), ...
                'BackgroundColor','white','Margin',4);
            setSelectedResidualDiagnostics(rr.EvaluationPixels,rr.Residual, ...
                sprintf('Set replacement round %d | %s d%d | %s',selectedSeedRound,seedComboResult.PositionMethod,seedComboResult.Degree,seedComboResult.ValidationMode),'Pixel');
        end
        hold(seedReplacementAxes,'off');grid(seedReplacementAxes,'on');xlabel(seedReplacementAxes,'Pixel');ylabel(seedReplacementAxes,'Wavelength residual (nm)');
        title(seedReplacementAxes,sprintf('Residual points | %s d%d | %s | baseline validation RMSE %.6g | fit RMSE %.6g nm', ...
            seedComboResult.PositionMethod,seedComboResult.Degree,seedComboResult.ValidationMode,baseline,seedComboResult.Baseline.FitRMSE));legend(seedReplacementAxes,'Location','best');
        influenceFeatureTabs.SelectedTab=setReplacementTab;
    end

    function addRecommendedSeedModel(~,~)
        if isempty(fieldnames(pendingSeedModelItem))
            uialert(fig,'Run selected-set replacement validation and obtain a recommended model first.','No pending model');return;
        end
        choice=uiconfirm(fig,'Add the current recommended replacement model to Model Comparison?', ...
            'Confirm model addition','Options',{'Add model','Cancel'},'DefaultOption',1,'CancelOption',2);
        if strcmp(choice,'Cancel'),return;end
        item=pendingSeedModelItem;item.ModelID=sprintf('M%03d',numel(calibrationModels)+1);
        calibrationModels(end+1)=item;selectedModelRow=numel(calibrationModels);
        pendingSeedModelItem=struct();addRecommendedSeedModelBtn.Enable='off';
        refreshModelComparison();drawModelComparison([],[]);
        replacementStatus.Text=sprintf('Recommended model %s was manually added to Model Comparison.',item.ModelID);
    end

    function [px,wl,ids,quality]=setDesignInputs
        [px,wl,ids,quality]=analysisInputsForPosition(optimizationPositionMethod.Value);
    end

    function [px,wl,ids,quality]=analysisInputsForPosition(positionMethod)
        valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
        px=[];wl=[];ids={};quality=[];
        for kk=1:numel(valid)
            q=calPairs(valid(kk));xp=pairPeakPosition(q,positionMethod);
            if ~isfinite(xp),continue;end
            px(end+1,1)=xp;wl(end+1,1)=q.ReferenceWavelength;ids{end+1,1}=q.PeakID; %#ok<AGROW>
            quality(end+1,1)=double(isSymmetryRecommended(q.PeakID)); %#ok<AGROW>
        end
        if numel(px)<5,error('WCC4SM:SetDesignInsufficientPool','At least five usable calibration pairs are required.');end
        [wl,ord]=sort(wl);px=px(ord);ids=ids(ord);quality=quality(ord);
    end

    function refreshSetDesignPool(~,~)
        try
            [px,wl,ids,quality]=setDesignInputs();
            windowInfluenceDegree=round(windowDegreeSpinner.Value);
            subsetDesignProfile=wc4sm_build_influence_profile(px,wl,windowInfluenceDegree,ids,quality);
            subsetDesignProfile.BaselineModel=wc4sm_fit_calibration(px,wl,3,px,optimizationPositionMethod.Value,ids);
            subsetDesignProfile.Pixel=px;subsetDesignProfile.Wavelength=wl;
            subsetDesignProfile.PeakIDs=ids;subsetDesignProfile.Quality=quality;
            s=subsetDesignProfile.Samples;populateSetDesignPoolTable(true(numel(s),1));
            setDesignK.Limits=[4 numel(s)];setDesignK.Value=min(max(10,4),numel(s));
            windowPartitionK.Limits=[4 numel(s)];windowPartitionK.Value=min(max(6,4),numel(s));
            subsetBeamState=struct();subsetDesignCandidates=struct([]);selectedSubsetCandidate=0;
            clearWindowPartition('Set Design pool refreshed; choose K and a partition rule.',[]);
            refreshSetDesignCandidateTable();drawSetDesignCandidate();
            setDesignStatus.Text=sprintf('%d-point pool ready | degree 3 | %s | influence ranking available.',numel(s),optimizationPositionMethod.Value);
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Set Design refresh failed');
        end
    end

    function generateWindowPartition(~,~)
        try
            requireSetDesignPool();s=subsetDesignProfile.Samples;
            subsetWindowPartition=wc4sm_partition_subset_windows([s.Wavelength].',[s.Influence].', ...
                round(windowPartitionK.Value),windowPartitionRule.Value,{s.PeakID}.');
            subsetWindowPartition.Degree=windowInfluenceDegree;
            populateWindowPartitionTable();drawWindowPartition();setDesignWorkspaceTabs.SelectedTab=windowPartitionTab;
            emptyCount=sum([subsetWindowPartition.Windows.NumberOfSamples]==0);
            dominantCount=numel(subsetWindowPartition.DominantSamples);
            if strcmp(subsetWindowPartition.Rule,'Equal cumulative influence')
                deviation=max(abs([subsetWindowPartition.Windows.DeviationFromTarget]));
                windowPartitionStatus.Text=sprintf('%s | K=%d | max weight deviation %.5g | %d dominant | %d empty.', ...
                    subsetWindowPartition.Rule,subsetWindowPartition.TargetK,deviation,dominantCount,emptyCount);
            else
                windowPartitionStatus.Text=sprintf('%s | K=%d | %d dominant | %d empty.', ...
                    subsetWindowPartition.Rule,subsetWindowPartition.TargetK,dominantCount,emptyCount);
            end
        catch ME
            windowPartitionStatus.Text=ME.message;uialert(fig,ME.message,'Window partition failed');
        end
    end

    function populateWindowPartitionTable
        if isempty(fieldnames(subsetWindowPartition))||~isfield(subsetWindowPartition,'Windows')
            windowPartitionTable.Data=cell(0,15);return;
        end
        q=subsetWindowPartition.Windows;dat=cell(numel(q),15);
        for kk=1:numel(q)
            dat(kk,:)={q(kk).WindowID,q(kk).StartWavelength,q(kk).EndWavelength, ...
                q(kk).FirstSampleIndex,q(kk).LastSampleIndex,q(kk).NumberOfSamples, ...
                q(kk).SumInfluence,q(kk).NormalizedInfluenceSum,q(kk).MeanInfluence, ...
                q(kk).MaxInfluence,q(kk).MaxInfluencePeakID,q(kk).MaxInfluenceWavelength, ...
                q(kk).TargetWeight,q(kk).DeviationFromTarget,q(kk).Status};
        end
        windowPartitionTable.Data=dat;
        populateWindowMemberTable();
    end

    function populateWindowMemberTable
        if isempty(fieldnames(subsetWindowPartition))||~isfield(subsetWindowPartition,'SortedWindowIndex')
            windowMemberTable.Data=cell(0,10);return;
        end
        r=subsetWindowPartition;s=subsetDesignProfile.Samples;ord=r.SortedOriginalIndices;
        if isempty(windowSelectedMask)||numel(windowSelectedMask)~=numel(s),windowSelectedMask=false(numel(s),1);end
        dat=cell(numel(ord),10);
        for k=1:numel(ord)
            q=ord(k);w=r.SortedWindowIndex(k);meanW=r.Windows(w).MeanInfluence;
            ratio=r.SortedInfluence(k)/max(meanW,eps);score=ratio;
            symmetry=windowSampleSymmetryDistance(s(q).PeakID);
            dat(k,:)={windowSelectedMask(q),sprintf('W%d',w),s(q).PeakID,s(q).Pixel,s(q).Wavelength,s(q).Influence,ratio,symmetry,score,'Manual'};
        end
        windowMemberTable.Data=dat;
    end

    function windowMemberEdited(~,~)
        dat=windowMemberTable.Data;if isempty(dat),return;end
        ord=subsetWindowPartition.SortedOriginalIndices;
        windowSelectedMask=false(numel(subsetDesignProfile.Samples),1);
        for k=1:numel(ord),windowSelectedMask(ord(k))=logical(dat{k,1});end
    end

    function recommendWindowSamples(~,~)
        if isempty(fieldnames(subsetWindowPartition)),uialert(fig,'Generate windows first.','No windows');return;end
        r=subsetWindowPartition;s=subsetDesignProfile.Samples;ord=r.SortedOriginalIndices;
        opts=struct('InfluenceThresholdPercent',windowInfluenceThreshold.Value,'SymmetryThresholdPixels',windowSymmetryThreshold.Value,'MaxPerWindow',3);
        symmetry=nan(size(r.SortedInfluence));
        for k=1:numel(ord),symmetry(k)=windowSampleSymmetryDistance(s(ord(k)).PeakID);end
        rec=wc4sm_recommend_window_samples(r.SortedWindowIndex,r.SortedInfluence,symmetry,opts);
        windowSelectedMask=false(numel(s),1);dat=windowMemberTable.Data;
        for k=1:numel(ord)
            windowSelectedMask(ord(k))=rec.Recommended(k);dat{k,1}=rec.Recommended(k);dat{k,9}=rec.Score(k);dat{k,10}=rec.Reason{k};
        end
        windowMemberTable.Data=dat;windowPartitionStatus.Text='Recommendations applied; adjust Use manually, then Confirm set.';
    end

    function d=windowSampleSymmetryDistance(id)
        d=NaN;id=char(string(id));
        k=find(strcmp({peakDataset.PeakID},id)&[peakDataset.Confirmed],1);
        if isempty(k)||isempty(peakDataset(k).AnalysisResult),return;end
        a=peakDataset(k).AnalysisResult;
        if isfield(a,'CenterX')&&isfield(a,'CentroidX')&&isfinite(a.CenterX)&&isfinite(a.CentroidX)
            d=abs(a.CenterX-a.CentroidX);
        end
    end

    function confirmWindowSamples(~,~)
        try
            requireSetDesignPool();windowMemberEdited([],[]);mask=windowSelectedMask(:);
            if sum(mask)<4,error('WCC4SM:WindowSelectionTooSmall','Select at least four samples before confirmation.');end
            options=struct('PeakIDs',{subsetDesignProfile.PeakIDs},'PositionMethod',optimizationPositionMethod.Value,'SkipLOO',false);
            record=wc4sm_evaluate_subset(subsetDesignProfile.Pixel,subsetDesignProfile.Wavelength,mask,3,subsetDesignProfile.Pixel,subsetDesignProfile.BaselineModel,options);
            id=sprintf('W%03d',numel(subsetDesignCandidates)+1);
            item=makeSetDesignItem(id,'Generated','Window manual selection','Window',mask,record,'-',true,NaN);
            % Candidate arrays may have been restored from an older session
            % with a different field order. Normalize before appending.
            if isempty(subsetDesignCandidates)
                subsetDesignCandidates=item;
            else
                oldFields=fieldnames(subsetDesignCandidates);newFields=fieldnames(item);
                if ~isequal(sort(oldFields),sort(newFields))
                    error('WCC4SM:WindowSelectionCandidateSchema','The existing Set Design candidates use an incompatible schema. Clear or refresh Set Design candidates first.');
                end
                item=orderfields(item,oldFields);
                subsetDesignCandidates(end+1)=item;
            end
            selectedSubsetCandidate=numel(subsetDesignCandidates);refreshSetDesignCandidateTable();
            setDesignWorkspaceTabs.SelectedTab=setDesignSearchTab;setDesignPoolTabs.SelectedTab=setDesignSelectedTab;
            populateSetDesignPoolTable(mask);drawSetDesignCandidate();
            setDesignStatus.Text=sprintf('%s confirmed: %d samples. Use Add model to comparison.',id,sum(mask));
        catch ME
            windowPartitionStatus.Text=ME.message;uialert(fig,ME.message,'Window selection failed');
        end
    end

    function windowPartitionDisplayChanged(~,~)
        drawWindowPartition();
    end

    function windowExtensionChanged(~,~)
        if ~isempty(fieldnames(subsetWindowPartition)),drawWindowPartition();end
    end

    function windowDegreeChanged(~,~)
        windowInfluenceDegree=round(windowDegreeSpinner.Value);
        % Influence values belong to the selected polynomial degree; invalidate
        % the old partition so it cannot be mistaken for the new degree.
        clearWindowPartition(sprintf('Degree changed to %d; refresh the Set Design pool and regenerate windows.',windowInfluenceDegree),[]);
    end

    function resetWindowExtension(~,~)
        windowLeftExtension.Value=0;windowRightExtension.Value=0;
        if ~isempty(fieldnames(subsetWindowPartition)),drawWindowPartition();end
    end

    function drawWindowPartition
        cla(windowResidualAxes,'reset');styleAxes(windowResidualAxes,C);title(windowResidualAxes,'Full-set residual with window boundaries');
        cla(windowInfluenceAxes,'reset');styleAxes(windowInfluenceAxes,C);title(windowInfluenceAxes,'Influence weight distribution');
        if isempty(fieldnames(subsetWindowPartition))||~isfield(subsetWindowPartition,'Windows'),return;end
        r=subsetWindowPartition;s=subsetDesignProfile.Samples;ord=r.SortedOriginalIndices;
        wl=r.SortedWavelength(:);residual=[s(ord).Residual].';
        hold(windowResidualAxes,'on');yline(windowResidualAxes,0,'-','Color',[.55 .55 .55],'HandleVisibility','off');
        scatter(windowResidualAxes,wl,residual,30,[.45 .45 .45],'filled','DisplayName','Full-set residual');
        drawWindowBoundaries(windowResidualAxes,r,true);
        [displayStart,displayEnd]=windowDisplayRange(r,s);
        xline(windowResidualAxes,displayStart,':','Color',C.orange,'LineWidth',1.4,'HandleVisibility','off');
        xline(windowResidualAxes,displayEnd,':','Color',C.orange,'LineWidth',1.4,'HandleVisibility','off');
        hold(windowResidualAxes,'off');grid(windowResidualAxes,'on');xlabel(windowResidualAxes,'Reference wavelength (nm)');ylabel(windowResidualAxes,'Reference - fitted (nm)');
        title(windowResidualAxes,sprintf('Full-set residual | %s | K=%d | no samples selected',r.Rule,r.TargetK));

        yyaxis(windowInfluenceAxes,'left');hold(windowInfluenceAxes,'on');
        if strcmp(windowInfluenceMode.Value,'Raw influence')
            y=r.SortedInfluence(:);yLabel='Deletion influence';
        else
            y=r.NormalizedWeight(:);yLabel='Normalized influence weight';
        end
        stem(windowInfluenceAxes,wl,y,'Marker','none','LineWidth',1.1,'Color',C.blue,'DisplayName',windowInfluenceMode.Value);
        drawWindowBoundaries(windowInfluenceAxes,r,false);
        hold(windowInfluenceAxes,'off');ylabel(windowInfluenceAxes,yLabel);grid(windowInfluenceAxes,'on');
        if windowShowCumulative.Value
            yyaxis(windowInfluenceAxes,'right');hold(windowInfluenceAxes,'on');
            stairs(windowInfluenceAxes,wl,r.CumulativeWeight(:),'-','Color',C.orange,'LineWidth',1.4,'DisplayName','Cumulative weight');
            for kk=1:r.TargetK-1,yline(windowInfluenceAxes,kk/r.TargetK,':','Color',[.65 .65 .65],'HandleVisibility','off');end
            hold(windowInfluenceAxes,'off');ylim(windowInfluenceAxes,[0 1]);ylabel(windowInfluenceAxes,'Cumulative influence weight');
            yyaxis(windowInfluenceAxes,'left');
        end
        xlabel(windowInfluenceAxes,'Reference wavelength (nm)');title(windowInfluenceAxes,'Influence distribution and shared window boundaries');
        xline(windowInfluenceAxes,displayStart,':','Color',C.orange,'LineWidth',1.4,'HandleVisibility','off');
        xline(windowInfluenceAxes,displayEnd,':','Color',C.orange,'LineWidth',1.4,'HandleVisibility','off');
        xlim(windowResidualAxes,[displayStart displayEnd]);xlim(windowInfluenceAxes,[displayStart displayEnd]);
        linkaxes([windowResidualAxes windowInfluenceAxes],'x');
    end

    function [displayStart,displayEnd]=windowDisplayRange(r,s)
        sampleStart=r.SortedWavelength(1);sampleEnd=r.SortedWavelength(end);
        model=subsetDesignProfile.BaselineModel;px=[s.Pixel];px=px(:);
        displayStart=polyval(model.Coefficients,min(px)-windowLeftExtension.Value,[],model.Mu);
        displayEnd=polyval(model.Coefficients,max(px)+windowRightExtension.Value,[],model.Mu);
        if ~isfinite(displayStart)||displayStart>=sampleStart,displayStart=sampleStart;end
        if ~isfinite(displayEnd)||displayEnd<=sampleEnd,displayEnd=sampleEnd;end
    end

    function drawWindowBoundaries(ax,r,showLabels)
        for kk=1:numel(r.Boundaries),xline(ax,r.Boundaries(kk),'--','Color',[.35 .35 .35],'HandleVisibility','off');end
        if ~showLabels,return;end
        drawnow limitrate;yl=ylim(ax);span=yl(2)-yl(1);if span<=0,span=1;end
        for kk=1:numel(r.Windows)
            q=r.Windows(kk);x=(q.StartWavelength+q.EndWavelength)/2;
            text(ax,x,yl(2)-0.04*span,q.WindowID,'HorizontalAlignment','center','VerticalAlignment','top', ...
                'FontWeight','bold','Color',C.navy,'Clipping','on');
        end
    end

    function clearWindowPartition(source,~)
        message='No window partition. Generate windows after refreshing the Set Design pool.';
        if nargin>=1&&ischar(source),message=source;end
        subsetWindowPartition=struct();windowPartitionTable.Data=cell(0,15);
        windowSelectedMask=[];windowMemberTable.Data=cell(0,10);
        cla(windowResidualAxes,'reset');styleAxes(windowResidualAxes,C);title(windowResidualAxes,'Full-set residual with window boundaries');
        cla(windowInfluenceAxes,'reset');styleAxes(windowInfluenceAxes,C);title(windowInfluenceAxes,'Influence weight distribution');
        windowPartitionStatus.Text=message;
    end

    function populateSetDesignPoolTable(useMask)
        s=subsetDesignProfile.Samples;n=numel(s);
        if nargin<1||numel(useMask)~=n,useMask=true(n,1);else,useMask=logical(useMask(:));end
        dat=cell(n,10);
        for kk=1:n
            qualityLabel='Review';if s(kk).Quality>=1,qualityLabel='Recommended';end
            dat(kk,:)={useMask(kk),s(kk).Rank,s(kk).PeakID,s(kk).Pixel,s(kk).Wavelength, ...
                s(kk).Influence,s(kk).Percentile,qualityLabel,s(kk).LocalSpacing,s(kk).Boundary};
        end
        setDesignPoolTable.Data=dat;
    end

    function refreshSetDesignCandidateTable
        if isempty(subsetDesignCandidates)
            setDesignCandidateTable.Data=cell(0,13);return;
        end
        dat=cell(numel(subsetDesignCandidates),13);
        for kk=1:numel(subsetDesignCandidates)
            q=subsetDesignCandidates(kk);r=q.Record;
            dat(kk,:)={q.Keep,q.CandidateID,q.State,q.Source,q.Role,r.K,q.DeletedLabel, ...
                r.AllRMSE,r.AllP95,r.AllMAX,r.DistanceRMS,r.DistanceMAX,q.CoverID};
        end
        setDesignCandidateTable.Data=dat;
    end

    function selectSetDesignCandidate(~,event)
        if isempty(event.Indices),return;end
        row=event.Indices(end,1);
        if row<1||row>numel(subsetDesignCandidates),return;end
        selectedSubsetCandidate=row;drawSetDesignCandidate();
        setDesignPoolTabs.SelectedTab=setDesignSelectedTab;
    end

    function drawSetDesignCandidate
        cla(setDesignSelectionAxes,'reset');styleAxes(setDesignSelectionAxes,C);
        cla(setDesignResidualAxes,'reset');styleAxes(setDesignResidualAxes,C);
        if isempty(fieldnames(subsetDesignProfile))||~isfield(subsetDesignProfile,'Samples')
            title(setDesignSelectionAxes,'Selected sample coverage and influence');
            title(setDesignResidualAxes,'Selected subset residuals on the full pool');return;
        end
        s=subsetDesignProfile.Samples;w=[s.Wavelength].';infl=[s.Influence].';
        if selectedSubsetCandidate>=1&&selectedSubsetCandidate<=numel(subsetDesignCandidates)
            q=subsetDesignCandidates(selectedSubsetCandidate);mask=q.Mask(:);r=q.Record;
        else
            mask=true(numel(s),1);r=[];
        end
        poolData=setDesignPoolTable.Data;
        if size(poolData,1)==numel(mask)
            for kk=1:numel(mask),poolData{kk,1}=mask(kk);end
            setDesignPoolTable.Data=poolData;
        end
        selected=find(mask);memberData=cell(numel(selected),9);
        for jj=1:numel(selected)
            kk=selected(jj);qualityLabel='Review';if s(kk).Quality>=1,qualityLabel='Recommended';end
            memberData(jj,:)={s(kk).PeakID,s(kk).Pixel,s(kk).Wavelength,s(kk).Influence, ...
                s(kk).Rank,s(kk).Percentile,qualityLabel,s(kk).LocalSpacing,s(kk).Boundary};
        end
        setDesignSelectedTable.Data=memberData;
        hold(setDesignSelectionAxes,'on');
        scatter(setDesignSelectionAxes,w(~mask),infl(~mask),24,[.7 .7 .7],'filled','DisplayName','Not selected');
        scatter(setDesignSelectionAxes,w(mask),infl(mask),44,C.blue,'filled','MarkerEdgeColor','k','DisplayName','Selected');
        hold(setDesignSelectionAxes,'off');grid(setDesignSelectionAxes,'on');xlabel(setDesignSelectionAxes,'Reference wavelength (nm)');ylabel(setDesignSelectionAxes,'Deletion influence');
        title(setDesignSelectionAxes,sprintf('Coverage | %d of %d samples',sum(mask),numel(mask)));legend(setDesignSelectionAxes,'Location','best');
        if isempty(r),return;end
        hold(setDesignResidualAxes,'on');yline(setDesignResidualAxes,0,'-','Color',[.55 .55 .55],'HandleVisibility','off');
        scatter(setDesignResidualAxes,w(~mask),r.Residual(~mask),25,[.65 .65 .65],'filled','DisplayName','Validation-only');
        scatter(setDesignResidualAxes,w(mask),r.Residual(mask),45,C.orange,'filled','MarkerEdgeColor','k','DisplayName','Fit subset');
        hold(setDesignResidualAxes,'off');grid(setDesignResidualAxes,'on');xlabel(setDesignResidualAxes,'Reference wavelength (nm)');ylabel(setDesignResidualAxes,'Reference - fitted (nm)');
        title(setDesignResidualAxes,sprintf('%s | K=%d | all RMSE %.6g | D RMS %.6g nm',q.CandidateID,r.K,r.AllRMSE,r.DistanceRMS));legend(setDesignResidualAxes,'Location','best');
        setSelectedResidualDiagnostics(w,r.Residual,sprintf('Set Design %s | K=%d | degree 3',q.CandidateID,r.K),'Reference wavelength (nm)');
    end

    function generateSetDesignCandidate(~,~)
        try
            requireSetDesignPool();n=numel(subsetDesignProfile.Samples);targetK=setDesignK.Value;
            options=struct('Influence',[subsetDesignProfile.Samples.Influence].', ...
                'Quality',subsetDesignProfile.Quality);
            if strcmp(setDesignMethod.Value,'Manual selection')
                dat=setDesignPoolTable.Data;
                if isempty(dat),error('WCC4SM:SetDesignNoManualPool','Refresh the source pool first.');end
                options.ManualMask=logical(cell2mat(dat(:,1)));
            end
            generated=wc4sm_generate_subset_mask(subsetDesignProfile.Wavelength,targetK,setDesignMethod.Value,options);
            evalOptions=struct('PeakIDs',{subsetDesignProfile.PeakIDs}, ...
                'PositionMethod',optimizationPositionMethod.Value,'SkipLOO',false);
            record=wc4sm_evaluate_subset(subsetDesignProfile.Pixel,subsetDesignProfile.Wavelength, ...
                generated.Mask,3,subsetDesignProfile.Pixel,subsetDesignProfile.BaselineModel,evalOptions);
            id=sprintf('S%03d',numel(subsetDesignCandidates)+1);
            item=makeSetDesignItem(id,'Generated',setDesignMethod.Value,'Rule',generated.Mask,record,'-',true,NaN);
            subsetDesignCandidates(end+1)=item;updateSetDesignCovers();refreshSetDesignCandidateTable();
            selectedSubsetCandidate=numel(subsetDesignCandidates);drawSetDesignCandidate();
            setDesignStatus.Text=sprintf('%s generated | K=%d | all-point RMSE %.6g nm.',setDesignMethod.Value,n-sum(~generated.Mask),record.AllRMSE);
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Set generation failed');
        end
    end

    function initializeSetDesignBeam(~,~)
        try
            requireSetDesignPool();n=numel(subsetDesignProfile.Pixel);
            options=struct('BPerf',setDesignBPerf.Value,'BDiv',setDesignBDiv.Value, ...
                'EpsilonRMS',setDesignEpsilonRMS.Value,'EpsilonMAX',setDesignEpsilonMAX.Value, ...
                'PeakIDs',{subsetDesignProfile.PeakIDs},'PositionMethod',optimizationPositionMethod.Value);
            subsetBeamState=wc4sm_initialize_backward_beam(subsetDesignProfile.Pixel, ...
                subsetDesignProfile.Wavelength,3,setDesignK.Value,subsetDesignProfile.Pixel,options);
            subsetDesignCandidates=makeSetDesignItem('B000','Accepted','Full pool','Baseline', ...
                true(n,1),subsetBeamState.BaselineRecord,'-',true,1);
            selectedSubsetCandidate=1;refreshSetDesignCandidateTable();drawSetDesignCandidate();
            setDesignStatus.Text=sprintf('Beam initialized at K=%d; click Calculate K-1. Target K=%d.',n,setDesignK.Value);
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Beam initialization failed');
        end
    end

    function calculateSetDesignBeamLayer(~,~)
        try
            if isempty(fieldnames(subsetBeamState)),error('WCC4SM:SetDesignBeamNotInitialized','Initialize Beam first.');end
            if setDesignK.Value~=subsetBeamState.TargetK||setDesignBPerf.Value~=subsetBeamState.BPerf|| ...
                    setDesignBDiv.Value~=subsetBeamState.BDiv||setDesignEpsilonRMS.Value~=subsetBeamState.EpsilonRMS|| ...
                    setDesignEpsilonMAX.Value~=subsetBeamState.EpsilonMAX
                error('WCC4SM:SetDesignBeamParametersChanged','Beam parameters changed; initialize a new Beam before calculating the next layer.');
            end
            [subsetBeamState,proposal]=wc4sm_backward_beam_step(subsetBeamState);
            for kk=1:numel(proposal.Candidates)
                c=proposal.Candidates(kk);deleted=subsetBeamState.PeakIDs{c.DeletedIndex};
                id=sprintf('K%02d-C%03d',proposal.K,kk);
                item=makeSetDesignItem(id,'Pending',sprintf('Beam K=%d',proposal.K),c.Role, ...
                    c.Mask,c.Record,deleted,c.Recommended,c.CoverID);
                item.PendingRow=kk;subsetDesignCandidates(end+1)=item; %#ok<AGROW>
            end
            refreshSetDesignCandidateTable();
            pending=find(strcmp({subsetDesignCandidates.State},'Pending'),1);
            if ~isempty(pending),selectedSubsetCandidate=pending;drawSetDesignCandidate();end
            setDesignStatus.Text=proposal.Status;
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Beam layer calculation failed');
        end
    end

    function acceptSetDesignBeamLayer(~,~)
        try
            if isempty(fieldnames(subsetBeamState))||isempty(subsetBeamState.PendingCandidates)
                error('WCC4SM:SetDesignNoPendingBeam','Calculate a K-1 layer first.');
            end
            dat=setDesignCandidateTable.Data;pending=find(strcmp({subsetDesignCandidates.State},'Pending'));
            selectedRows=[];
            for kk=1:numel(pending)
                row=pending(kk);subsetDesignCandidates(row).Keep=logical(dat{row,1});
                if subsetDesignCandidates(row).Keep,selectedRows(end+1)=subsetDesignCandidates(row).PendingRow;end %#ok<AGROW>
            end
            if isempty(selectedRows),error('WCC4SM:SetDesignNoBeamSelection','Check at least one pending candidate before confirmation.');end
            [subsetBeamState,acceptedIDs]=wc4sm_accept_beam_layer(subsetBeamState,selectedRows);
            for kk=1:numel(pending)
                row=pending(kk);q=subsetDesignCandidates(row).PendingRow;
                pos=find(selectedRows==q,1);
                if isempty(pos)
                    subsetDesignCandidates(row).State='Rejected';subsetDesignCandidates(row).Role='Not retained';subsetDesignCandidates(row).Keep=false;
                else
                    subsetDesignCandidates(row).State='Accepted';
                    subsetDesignCandidates(row).Role=subsetBeamState.Nodes(acceptedIDs(pos)).Role;
                end
            end
            refreshSetDesignCandidateTable();setDesignStatus.Text=subsetBeamState.Status;
            acceptedRows=find(strcmp({subsetDesignCandidates.State},'Accepted'));
            if ~isempty(acceptedRows),selectedSubsetCandidate=acceptedRows(end);drawSetDesignCandidate();end
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Beam confirmation failed');
        end
    end

    function item=makeSetDesignItem(id,state,source,role,mask,record,deleted,keep,coverID)
        item=struct('CandidateID',id,'State',state,'Source',source,'Role',role, ...
            'Mask',logical(mask(:)),'Record',record,'DeletedLabel',deleted,'Keep',logical(keep), ...
            'CoverID',coverID,'PendingRow',NaN);
    end

    function requireSetDesignPool
        if isempty(fieldnames(subsetDesignProfile))||~isfield(subsetDesignProfile,'Pixel')
            error('WCC4SM:SetDesignPoolNotReady','Refresh the Set Design calibration pool first.');
        end
    end

    function updateSetDesignCovers
        if isempty(subsetDesignCandidates),return;end
        kvals=unique(arrayfun(@(q)q.Record.K,subsetDesignCandidates));
        for kval=kvals(:).'
            rows=find(arrayfun(@(q)q.Record.K==kval,subsetDesignCandidates));
            cover=wc4sm_build_epsilon_cover([subsetDesignCandidates(rows).Record], ...
                setDesignEpsilonRMS.Value,setDesignEpsilonMAX.Value);
            for jj=1:numel(rows),subsetDesignCandidates(rows(jj)).CoverID=cover.Assignment(jj);end
        end
    end

    function sendSetDesignToAddOne(~,~)
        try
            q=selectedSetDesignItem();
            if strcmp(q.State,'Pending')||strcmp(q.State,'Rejected')
                error('WCC4SM:SetDesignUnconfirmedCandidate','Select a generated or accepted candidate first.');
            end
            dat=optimizationSeedTable.Data;
            if isempty(dat),refreshOptimizationSeeds([],[]);dat=optimizationSeedTable.Data;end
            selectedIDs=string(q.Record.SelectedIDs);
            matched=0;
            for kk=1:size(dat,1)
                dat{kk,1}=any(selectedIDs==string(dat{kk,2}));
                matched=matched+double(dat{kk,1});
            end
            optimizationSeedTable.Data=dat;optimizationSeedEdited([],[]);
            plotTabs.SelectedTab=tabOptimization;
            optimizationStatus.Text=sprintf('%s sent to Add-One: %d of %d selected points matched.',q.CandidateID,matched,q.Record.K);
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Send to Add-One failed');
        end
    end

    function addSetDesignModel(~,~)
        try
            q=selectedSetDesignItem();
            if strcmp(q.State,'Pending')||strcmp(q.State,'Rejected')
                error('WCC4SM:SetDesignUnconfirmedCandidate','Select a generated or accepted candidate first.');
            end
            choice=uiconfirm(fig,sprintf('Refit %s with full LOO diagnostics and add it to Model Comparison?',q.CandidateID), ...
                'Confirm model addition','Options',{'Add model','Cancel'},'DefaultOption',1,'CancelOption',2);
            if strcmp(choice,'Cancel'),return;end
            mask=q.Mask(:);ids=subsetDesignProfile.PeakIDs(mask);
            model=wc4sm_fit_calibration(subsetDesignProfile.Pixel(mask),subsetDesignProfile.Wavelength(mask), ...
                3,subsetDesignProfile.Pixel,optimizationPositionMethod.Value,ids);
            model=attachPixelCoordinateMetadata(model);
            item=struct('ModelID',sprintf('M%03d',numel(calibrationModels)+1), ...
                'CreatedAt',datetime('now'),'PairCount',sum(mask), ...
                'PositionMethod',optimizationPositionMethod.Value,'Degree',3, ...
                'PairIDs',{ids},'Model',model,'Visible',true);
            calibrationModels(end+1)=item;selectedModelRow=numel(calibrationModels);
            refreshModelComparison();drawModelComparison([],[]);plotTabs.SelectedTab=tabModelCompare;
            setDesignStatus.Text=sprintf('%s added to Model Comparison as %s.',q.CandidateID,item.ModelID);
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Add subset model failed');
        end
    end

    function q=selectedSetDesignItem
        if selectedSubsetCandidate<1||selectedSubsetCandidate>numel(subsetDesignCandidates)
            error('WCC4SM:SetDesignNoCandidate','Select a candidate row first.');
        end
        q=subsetDesignCandidates(selectedSubsetCandidate);
    end

    function showSetDesignGuide(~,~)
        message=sprintf([ ...
            'Target K: final number of calibration samples. Rule generators create K points directly; Beam stops when K is reached.\n\n' ...
            'B perf: number of best-performing child subsets retained at each deletion layer, ranked by fixed full-pool RMSE, P95 and MAX.\n\n' ...
            'B div: additional child subsets retained because their calibration curves differ from the performance branches. It protects alternative model paths; it is not a sample count.\n\n' ...
            'eps RMS / eps MAX: two model-curve distance thresholds used only to group engineering-equivalent models. Smaller values create more cover groups.\n\n' ...
            'Recommended first run: B perf=5, B div=5, eps RMS=0.01 nm, eps MAX=0.03 nm. Initialize once, calculate one K-1 layer, inspect members/residuals, then confirm checked candidates.\n\n' ...
            'For sensitivity analysis, repeat with B=3+3, 5+5 and 10+10. If the best subsets and cover representatives remain stable, the search width is likely sufficient.']);
        uialert(fig,message,'Set Design parameter guide','Icon','info');
    end

    function state=captureSetDesignState
        useMask=[];
        dat=setDesignPoolTable.Data;
        if ~isempty(dat),useMask=logical(cell2mat(dat(:,1)));end
        settings=struct('Method',setDesignMethod.Value,'TargetK',setDesignK.Value, ...
            'BPerf',setDesignBPerf.Value,'BDiv',setDesignBDiv.Value, ...
            'EpsilonRMS',setDesignEpsilonRMS.Value,'EpsilonMAX',setDesignEpsilonMAX.Value, ...
            'WindowK',windowPartitionK.Value,'WindowRule',windowPartitionRule.Value, ...
            'WindowInfluenceMode',windowInfluenceMode.Value,'WindowShowCumulative',windowShowCumulative.Value);
        state=struct('Profile',subsetDesignProfile,'BeamState',subsetBeamState, ...
            'Candidates',subsetDesignCandidates,'SelectedCandidate',selectedSubsetCandidate, ...
            'PoolUseMask',useMask,'WindowPartition',subsetWindowPartition,'Settings',settings);
    end

    function exportSetDesignResults(~,~)
        try
            requireSetDesignPool();
            [fn,pn]=uiputfile('WCC4SM_set_design.mat','Export Set Design results');
            if isequal(fn,0),return;end
            [~,stem]=fileparts(fn);SetDesignExport=captureSetDesignState(); %#ok<NASGU>
            save(fullfile(pn,fn),'SetDesignExport');
            s=subsetDesignProfile.Samples;n=numel(s);
            pool=table(string({s.PeakID}).',[s.Pixel].',[s.Wavelength].',[s.Influence].', ...
                [s.Rank].',[s.Percentile].',[s.Quality].',[s.LocalSpacing].',string({s.Boundary}).', ...
                'VariableNames',{'PeakID','Pixel','Wavelength_nm','Influence','InfluenceRank', ...
                'InfluencePercentile','QualityScore','LocalSpacing_nm','Boundary'});
            writetable(pool,fullfile(pn,[stem '_pool.csv']));
            if ~isempty(fieldnames(subsetWindowPartition))&&isfield(subsetWindowPartition,'Windows')
                q=subsetWindowPartition.Windows;
                windowSummary=table(string({q.WindowID}).',[q.StartWavelength].',[q.EndWavelength].', ...
                    [q.FirstSampleIndex].',[q.LastSampleIndex].',[q.NumberOfSamples].',[q.SumInfluence].', ...
                    [q.NormalizedInfluenceSum].',[q.MeanInfluence].',[q.MaxInfluence].', ...
                    string({q.MaxInfluencePeakID}).',[q.MaxInfluenceWavelength].',[q.TargetWeight].', ...
                    [q.DeviationFromTarget].',[q.CumulativeEndWeight].',string({q.Status}).', ...
                    'VariableNames',{'WindowID','StartWavelength_nm','EndWavelength_nm','FirstSortedIndex', ...
                    'LastSortedIndex','NumberOfSamples','SumInfluence','NormalizedInfluenceSum', ...
                    'MeanInfluence','MaxInfluence','MaxInfluencePeakID','MaxInfluenceWavelength_nm', ...
                    'TargetWeight','DeviationFromTarget','CumulativeEndWeight','Status'});
                writetable(windowSummary,fullfile(pn,[stem '_windows.csv']));
                r=subsetWindowPartition;windowNumber=r.SortedWindowIndex(:);sortedSamples=s(r.SortedOriginalIndices);
                windowID=arrayfun(@(x)sprintf('W%d',x),windowNumber,'UniformOutput',false);
                windowMembers=table(string(r.SortedPeakIDs(:)),r.SortedOriginalIndices(:), ...
                    [sortedSamples.Pixel].',r.SortedWavelength(:),[sortedSamples.Residual].', ...
                    r.SortedInfluence(:),r.NormalizedWeight(:),r.CumulativeWeight(:), ...
                    [sortedSamples.Quality].',windowNumber,string(windowID(:)), ...
                    'VariableNames',{'PeakID','OriginalPoolIndex','Pixel','Wavelength_nm','FullSetResidual_nm', ...
                    'Influence','NormalizedWeight','CumulativeWeight','QualityScore','WindowNumber','WindowID'});
                writetable(windowMembers,fullfile(pn,[stem '_window_members.csv']));
            end
            if ~isempty(subsetDesignCandidates)
                c=subsetDesignCandidates;r=[c.Record];
                summary=table(string({c.CandidateID}).',string({c.State}).',string({c.Source}).', ...
                    string({c.Role}).',[r.K].',string({c.DeletedLabel}).',[r.FitRMSE].',[r.AllRMSE].', ...
                    [r.AllP95].',[r.AllMAX].',[r.DistanceRMS].',[r.DistanceMAX].',[c.CoverID].', ...
                    [r.MaxWavelengthGap].',[r.ShortBoundaryIncluded].',[r.LongBoundaryIncluded].', ...
                    'VariableNames',{'CandidateID','State','Source','Role','K','DeletedPeak', ...
                    'FitRMSE_nm','AllPointRMSE_nm','AllPointP95_nm','AllPointMAX_nm', ...
                    'CurveDistanceRMS_nm','CurveDistanceMAX_nm','CoverID','MaxWavelengthGap_nm', ...
                    'ShortBoundaryIncluded','LongBoundaryIncluded'});
                writetable(summary,fullfile(pn,[stem '_candidates.csv']));
                candidateID=strings(0,1);peakID=strings(0,1);pixel=[];wavelength=[];influence=[];rank=[];quality=[];
                for kk=1:numel(c)
                    ids=find(c(kk).Mask);
                    candidateID=[candidateID;repmat(string(c(kk).CandidateID),numel(ids),1)]; %#ok<AGROW>
                    peakID=[peakID;string({s(ids).PeakID}).'];pixel=[pixel;[s(ids).Pixel].']; %#ok<AGROW>
                    wavelength=[wavelength;[s(ids).Wavelength].'];influence=[influence;[s(ids).Influence].']; %#ok<AGROW>
                    rank=[rank;[s(ids).Rank].'];quality=[quality;[s(ids).Quality].']; %#ok<AGROW>
                end
                members=table(candidateID,peakID,pixel,wavelength,influence,rank,quality, ...
                    'VariableNames',{'CandidateID','PeakID','Pixel','Wavelength_nm','Influence','InfluenceRank','QualityScore'});
                writetable(members,fullfile(pn,[stem '_members.csv']));
            end
            if ~isempty(fieldnames(subsetBeamState))&&isfield(subsetBeamState,'Layers')
                layers=subsetBeamState.Layers;
                accepted=strings(numel(layers),1);
                for kk=1:numel(layers),accepted(kk)=strjoin(string(layers(kk).AcceptedNodeIDs),';');end
                layerTable=table([layers.K].',[layers.CandidateCount].',accepted,[layers.CoverCount].', ...
                    'VariableNames',{'K','CandidateCount','AcceptedNodeIDs','CoverCount'});
                writetable(layerTable,fullfile(pn,[stem '_beam_layers.csv']));
                nodes=subsetBeamState.Nodes;nodePath=strings(numel(nodes),1);deletedPeak=strings(numel(nodes),1);
                for kk=1:numel(nodes)
                    nodePath(kk)=strjoin(string(nodes(kk).PathNodeIDs),';');
                    if isfinite(nodes(kk).DeletedIndex),deletedPeak(kk)=string(subsetBeamState.PeakIDs{nodes(kk).DeletedIndex});end
                end
                nodeRecords=[nodes.Record];
                nodeTable=table([nodes.NodeID].',[nodes.ParentNodeID].',[nodes.K].',string({nodes.Role}).', ...
                    deletedPeak,[nodeRecords.AllRMSE].',[nodeRecords.AllP95].',[nodeRecords.AllMAX].', ...
                    [nodeRecords.DistanceRMS].',[nodeRecords.DistanceMAX].',[nodes.CoverRepresentativeNodeID].',nodePath, ...
                    'VariableNames',{'NodeID','ParentNodeID','K','Role','DeletedPeak','AllPointRMSE_nm', ...
                    'AllPointP95_nm','AllPointMAX_nm','CurveDistanceRMS_nm','CurveDistanceMAX_nm', ...
                    'CoverRepresentativeNodeID','PathNodeIDs'});
                writetable(nodeTable,fullfile(pn,[stem '_beam_nodes.csv']));
            end
            setDesignStatus.Text=['Set Design results exported: ' fullfile(pn,fn)];
        catch ME
            setDesignStatus.Text=ME.message;uialert(fig,ME.message,'Set Design export failed');
        end
    end

    function clearSetDesignState(message)
        subsetDesignProfile=struct();subsetBeamState=struct();subsetDesignCandidates=struct([]);selectedSubsetCandidate=0;subsetWindowPartition=struct();
        try,setDesignPoolTable.Data=cell(0,10);setDesignSelectedTable.Data=cell(0,9);setDesignCandidateTable.Data=cell(0,13);catch,end
        try,cla(setDesignSelectionAxes,'reset');styleAxes(setDesignSelectionAxes,C);title(setDesignSelectionAxes,'Selected sample coverage and influence');catch,end
        try,cla(setDesignResidualAxes,'reset');styleAxes(setDesignResidualAxes,C);title(setDesignResidualAxes,'Selected subset residuals on the full pool');catch,end
        try,clearWindowPartition('No saved Window Partition result.',[]);catch,end
        if nargin>0,try,setDesignStatus.Text=message;catch,end,end
    end

    %% SESSION MANAGEMENT
    function saveSession(~,~)
        try
            if ~editSessionMetadata(),return;end
            sessionState=captureSessionState();
            WCC4SMSession=wc4sm_create_session(sessionState,sessionMetadata);
            WCC4SMSession.SoftwareVersion='0.9';
            defaultName='WCC4SM_session.mat';
            if ~isempty(currentSessionPath),[~,n,e]=fileparts(currentSessionPath);defaultName=[n e];end
            [fn,pn]=uiputfile('*.mat','Save complete WCC4SM session',defaultName);
            if isequal(fn,0),return;end
            target=fullfile(pn,fn);
            wc4sm_save_session(target,WCC4SMSession);
            currentSessionPath=target;
            topStatus.Text=['Session saved: ' shortName(target)];
        catch ME
            uialert(fig,ME.message,'Session save failed');
        end
    end

    function loadSession(~,~)
        [fn,pn]=uigetfile('*.mat','Load complete WCC4SM session');if isequal(fn,0),return;end
        oldState=captureSessionState();oldMetadata=sessionMetadata;oldPath=currentSessionPath;
        try
            target=fullfile(pn,fn);
            [loaded,report]=wc4sm_load_session(target);
            applySessionState(loaded.State);
            sessionMetadata=loaded.Metadata;currentSessionPath=target;
            refreshSessionViews();
            if report.WarningCount>0
                topStatus.Text=sprintf('Session loaded with %d provenance warning(s): %s', ...
                    report.WarningCount,shortName(target));
            else
                topStatus.Text=['Session loaded: ' shortName(target)];
            end
        catch ME
            try
                applySessionState(oldState);sessionMetadata=oldMetadata;currentSessionPath=oldPath;
                refreshSessionViews();
            catch
            end
            uialert(fig,ME.message,'Session load failed; previous state retained');
        end
    end

    function tf=editSessionMetadata
        provenance=defaultProvenance();
        defaults={metadataText('Operator',getenv('USERNAME')),metadataText('InstrumentID',''), ...
            metadataText('InstrumentModel',''),metadataText('Notes',''), ...
            char(string(provenance.MasterLibrary)),char(string(provenance.MasterVersion)), ...
            char(string(provenance.Authority)),char(string(provenance.WavelengthMedium)), ...
            char(string(provenance.SelectionMode)),char(string(provenance.SelectionModeVersion)), ...
            char(string(provenance.Notes))};
        prompt={'Operator','Instrument ID','Instrument model','Session notes', ...
            'Reference master library','Reference master version','Reference authority/source', ...
            'Wavelength medium (Air/Vacuum/Unspecified)','Reference selection mode', ...
            'Selection mode version','Reference traceability notes'};
        answer=inputdlg(prompt,'WCC4SM session metadata and traceability',[1 62],defaults);
        if isempty(answer),tf=false;return;end
        provenance=struct('MasterLibrary',answer{5},'MasterVersion',answer{6}, ...
            'Authority',answer{7},'WavelengthMedium',answer{8}, ...
            'SelectionMode',answer{9},'SelectionModeVersion',answer{10},'Notes',answer{11});
        measurementTime=NaT;if isfield(sessionMetadata,'MeasurementTime'),measurementTime=sessionMetadata.MeasurementTime;end
        sessionMetadata=struct('Operator',answer{1},'InstrumentID',answer{2}, ...
            'InstrumentModel',answer{3},'MeasurementTime',measurementTime, ...
            'MeasurementFile',D.source,'DarkFile',D.darkSource,'Notes',answer{4}, ...
            'ReferenceProvenance',provenance);
        tf=true;
    end

    function textValue=metadataText(name,fallback)
        textValue=fallback;
        if isfield(sessionMetadata,name)
            value=sessionMetadata.(name);
            if ~(isdatetime(value)&&isnat(value)),textValue=char(string(value));end
        end
    end

    function provenance=defaultProvenance
        provenance=struct('MasterLibrary',shortName(L.source),'MasterVersion','', ...
            'Authority',inferReferenceAuthority(L.source),'WavelengthMedium','Unspecified', ...
            'SelectionMode',referenceSetDrop.Value,'SelectionModeVersion','','Notes','');
        if isfield(sessionMetadata,'ReferenceProvenance')&&isstruct(sessionMetadata.ReferenceProvenance)
            old=sessionMetadata.ReferenceProvenance;names=fieldnames(old);
            for kk=1:numel(names),provenance.(names{kk})=old.(names{kk});end
        end
    end

    function authority=inferReferenceAuthority(source)
        name=lower(string(source));
        if contains(name,'nist'),authority='NIST';elseif contains(name,'avantes'),authority='Avantes';else,authority='';end
    end

    function state=captureSessionState
        state=struct('Spectrum',D,'Peaks',peaks,'PeakDataset',peakDataset, ...
            'ReferenceLines',L,'CalibrationPairs',calPairs, ...
            'InitialCalibration',provisional,'FinalCalibration',finalModel, ...
            'CalibrationModels',calibrationModels,'AppliedModel',appliedModel, ...
            'AppliedModelName',appliedModelName,'SetDesign',captureSetDesignState(), ...
            'PositionCrossValidation',positionCrossResult, ...
            'PaperPeakDifferenceExcludedIDs',{paperPeakDifferenceExcludedIDs}, ...
            'PaperPeakAllExcludedIDs',{paperPeakAllExcludedIDs}, ...
            'PaperPeakPairArchive',paperPeakPairArchive, ...
            'UISettings',captureUISettings());
    end

    function settings=captureUISettings
        settings=struct('InputType',inputType.Value,'PixelCoordinateMode',pixelMode.Value, ...
            'ManualBaseline',baselineField.Value,'ClampNegative',clampCheck.Value, ...
            'DisplaySignal',displayDrop.Value,'YScale',scaleDrop.Value, ...
            'MainAxisMode',mainAxisMode,'MatchingAxisMode',matchingAxisMode, ...
            'NormalizedSearch',normalizedSearch.Value,'MinHeight',minHeight.Value, ...
            'MinProminence',minProm.Value,'MinDistance',minDist.Value, ...
            'MinWidth',minWidth.Value,'MaxWidth',maxWidth.Value, ...
            'LeftPixels',leftSpin.Value,'RightPixels',rightSpin.Value, ...
            'InterpolationMethod',methodDrop.Value,'InterpolationFactor',factorSpin.Value, ...
            'PositionMethod',positionDrop.Value,'PolynomialDegree',degreeSpin.Value, ...
            'ConfidenceThreshold',confidenceThreshold.Value,'ResidualBins',histBinCount.Value, ...
            'FWHMBins',fwhmHistBinCount.Value,'FWHMRangeMode',fwhmHistRangeMode.Value, ...
            'FWHMXMin',fwhmHistXMin.Value,'FWHMXMax',fwhmHistXMax.Value, ...
            'PaperPeakDifferenceFitOrder',paperPeakDifferenceFitOrder.Value, ...
            'PaperPeakDifferenceFitSeries',paperPeakDifferenceFitSeries.Value, ...
            'PaperShowDirect',paperShowDirect.Value,'PaperShowInterpolated',paperShowInterpolated.Value,'PaperShowCentroid',paperShowCentroid.Value, ...
            'PaperShowCalibrationOnly',paperShowCalibrationOnly.Value, ...
            'PeakDifferenceUnit',peakDifferenceUnit.Value,'PeakDifferenceXMode',peakDifferenceXMode.Value, ...
            'PeakDifferenceSeries',peakDifferenceSeries.Value,'PeakDifferenceFitTarget',peakDifferenceFitTarget.Value,'PeakDifferenceFitOrder',peakDifferenceFitOrder.Value, ...
            'PeakDifferenceDistributionBins',peakDifferenceDistributionBinCount.Value, ...
            'PeakDifferenceDistributionRangeMode',peakDifferenceDistributionRangeMode.Value, ...
            'PeakDifferenceDistributionXMin',peakDifferenceDistributionXMin.Value,'PeakDifferenceDistributionXMax',peakDifferenceDistributionXMax.Value, ...
            'PeakDifferenceHistBins',peakDifferenceHistBinCount.Value,'PeakDifferenceHistRangeMode',peakDifferenceHistRangeMode.Value, ...
            'PeakDifferenceHistXMin',peakDifferenceHistXMin.Value,'PeakDifferenceHistXMax',peakDifferenceHistXMax.Value, ...
            'ReferenceResolutionNm',referenceResolutionNm,'SymmetryThresholdPx',symmetryThresholdPx, ...
            'OptimizationPositionMethod',optimizationPositionMethod.Value, ...
            'OptimizationDegree',optimizationDegree.Value,'OptimizationStop',optimizationStop.Value, ...
            'OptimizationMaxOrder',optimizationMaxOrder.Value, ...
            'InfluenceDegree',influenceDegree.Value,'InfluenceMaxOrder',influenceMaxOrder.Value, ...
            'InfluencePositionMethod',influencePositionMethod.Value, ...
            'InfluenceXAxisMode',influenceXAxisMode.Value, ...
            'PositionCrossDegree',positionCrossDegree.Value,'PositionCrossValidationMode',positionCrossValidationMode.Value, ...
            'PositionCrossPoolMode',positionCrossPoolMode.Value,'PositionCrossTrainingSource',positionCrossTrainingSource.Value,'PositionCrossMetric',positionCrossMetric.Value, ...
            'PositionCrossView',positionCrossViewTabs.SelectedTab.Title, ...
            'PositionCrossResidualView',positionCrossResidualView.Value,'PositionCrossHistBins',positionCrossHistBins.Value, ...
            'PositionCrossHistRangeMode',positionCrossHistRangeMode.Value,'PositionCrossHistXMin',positionCrossHistXMin.Value,'PositionCrossHistXMax',positionCrossHistXMax.Value, ...
            'InfluenceYMode',influenceYMode.Value,'InfluenceYMin',influenceYMin.Value,'InfluenceYMax',influenceYMax.Value, ...
            'ReplacementRMSEThreshold',replacementRMSEThreshold.Value,'ReplacementValidationMode',seedValidationMode.Value, ...
            'SelectedResidualBins',selectedHistBinCount.Value, ...
            'SelectedResidualRangeMode',selectedHistRangeMode.Value, ...
            'SelectedResidualXMin',selectedHistXMin.Value,'SelectedResidualXMax',selectedHistXMax.Value);
    end

    function applySessionState(state)
        if isempty(fieldnames(state.Spectrum)),D=emptyData();else,D=state.Spectrum;end
        if ~isfield(D,'PixelCoordinateMode')||isempty(D.PixelCoordinateMode)
            D.PixelCoordinateMode='Legacy natural pixel sequence';
        end
        if ~isfield(D,'PixelFirst')||isempty(D.PixelFirst),D.PixelFirst=minOrNaN(D.pixel);end
        if ~isfield(D,'PixelLast')||isempty(D.PixelLast),D.PixelLast=maxOrNaN(D.pixel);end
        peaks=state.Peaks;peakDataset=state.PeakDataset;
        if isempty(fieldnames(state.ReferenceLines)),L=emptyLineLibrary();else,L=state.ReferenceLines;end
        Lexternal=L;calPairs=state.CalibrationPairs;
        if isempty(fieldnames(state.InitialCalibration)),provisional=emptyInitialModel();else,provisional=state.InitialCalibration;end
        if isempty(fieldnames(state.FinalCalibration)),finalModel=emptyFinalModel();else,finalModel=state.FinalCalibration;end
        calibrationModels=state.CalibrationModels;
        if ~isempty(calibrationModels) && ~isfield(calibrationModels,'Visible'),[calibrationModels.Visible]=deal(true);end
        if isempty(fieldnames(state.AppliedModel)),appliedModel=emptyFinalModel();else,appliedModel=state.AppliedModel;end
        appliedModelName=char(string(state.AppliedModelName));
        localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
        selectedRow=0;selectedDatasetRow=0;selectedRefRow=0;selectedPairRow=0;
        selectedValidationRow=0;selectedModelRow=0;selectedSeedRound=0;selectedPositionCrossRow=1;selectedPositionCrossColumn=1;pendingSeedModelItem=struct();addRecommendedSeedModelBtn.Enable='off';R=emptyReference();
        influenceResult=struct();influenceOrderStats=struct([]);influenceViewMode='Point influence';seedComboResult=struct();
        selectedResidualContext=struct('X',[],'Residual',[],'Label','','XAxisLabel','');
        paperPeakDifferenceExcludedIDs={};paperPeakAllExcludedIDs={};paperPeakDifferenceSelectedID='';paperPeakDifferenceResult=struct();paperPeakPairArchive=emptyCalPairs();
        if isfield(state,'PaperPeakDifferenceExcludedIDs')
            paperPeakDifferenceExcludedIDs=cellstr(string(state.PaperPeakDifferenceExcludedIDs(:)));
        end
        if isfield(state,'PaperPeakAllExcludedIDs')
            paperPeakAllExcludedIDs=cellstr(string(state.PaperPeakAllExcludedIDs(:)));
        end
        if isfield(state,'PaperPeakPairArchive')&&isstruct(state.PaperPeakPairArchive),paperPeakPairArchive=state.PaperPeakPairArchive;end
        if isfield(state,'PositionCrossValidation')&&isstruct(state.PositionCrossValidation),positionCrossResult=state.PositionCrossValidation;else,positionCrossResult=struct();end
        restoreUISettings(state.UISettings);
        restoreSetDesignSessionState(state);
        drawSelectedResidualDiagnostics();drawPositionCrossValidation();
    end

    function restoreSetDesignSessionState(state)
        clearSetDesignState('No saved Set Design results in this session.');
        if ~isfield(state,'SetDesign')||~isstruct(state.SetDesign)||~isscalar(state.SetDesign),return;end
        sd=state.SetDesign;
        if isfield(sd,'Settings')&&isstruct(sd.Settings)
            q=sd.Settings;
            restoreControl(setDesignMethod,q,'Method');restoreControl(setDesignBPerf,q,'BPerf');
            restoreControl(setDesignBDiv,q,'BDiv');restoreControl(setDesignEpsilonRMS,q,'EpsilonRMS');
            restoreControl(setDesignEpsilonMAX,q,'EpsilonMAX');
            restoreControl(windowPartitionRule,q,'WindowRule');restoreControl(windowInfluenceMode,q,'WindowInfluenceMode');
            restoreControl(windowShowCumulative,q,'WindowShowCumulative');
        end
        if isfield(sd,'Profile')&&isstruct(sd.Profile),subsetDesignProfile=sd.Profile;end
        if isfield(sd,'BeamState')&&isstruct(sd.BeamState),subsetBeamState=sd.BeamState;end
        if isfield(sd,'Candidates')&&isstruct(sd.Candidates),subsetDesignCandidates=sd.Candidates;end
        if isfield(sd,'WindowPartition')&&isstruct(sd.WindowPartition)&&isscalar(sd.WindowPartition),subsetWindowPartition=sd.WindowPartition;end
        if isfield(sd,'SelectedCandidate')&&isscalar(sd.SelectedCandidate),selectedSubsetCandidate=sd.SelectedCandidate;end
        if isempty(fieldnames(subsetDesignProfile))||~isfield(subsetDesignProfile,'Samples')
            selectedSubsetCandidate=0;return;
        end
        n=numel(subsetDesignProfile.Samples);setDesignK.Limits=[4 max(4,n)];
        windowPartitionK.Limits=[4 max(4,n)];
        target=min(max(4,min(10,n)),n);
        if isfield(sd,'Settings')&&isfield(sd.Settings,'TargetK'),target=min(max(4,sd.Settings.TargetK),n);end
        setDesignK.Value=target;
        windowTarget=min(max(4,min(6,n)),n);
        if isfield(sd,'Settings')&&isfield(sd.Settings,'WindowK'),windowTarget=min(max(4,sd.Settings.WindowK),n);end
        windowPartitionK.Value=windowTarget;
        useMask=true(n,1);
        if isfield(sd,'PoolUseMask')&&numel(sd.PoolUseMask)==n,useMask=logical(sd.PoolUseMask(:));end
        populateSetDesignPoolTable(useMask);
        if selectedSubsetCandidate<1||selectedSubsetCandidate>numel(subsetDesignCandidates),selectedSubsetCandidate=0;end
        refreshSetDesignCandidateTable();drawSetDesignCandidate();
        if ~isempty(fieldnames(subsetWindowPartition))&&isfield(subsetWindowPartition,'Windows')
            populateWindowPartitionTable();drawWindowPartition();
            windowPartitionStatus.Text=sprintf('Session restored | %s | K=%d | no samples selected.',subsetWindowPartition.Rule,subsetWindowPartition.TargetK);
        end
        if ~isempty(fieldnames(subsetBeamState))&&isfield(subsetBeamState,'Status')
            setDesignStatus.Text=['Session restored | ' subsetBeamState.Status];
        else
            setDesignStatus.Text=sprintf('Session restored | %d-point Set Design pool | %d candidates.',n,numel(subsetDesignCandidates));
        end
    end

    function restoreUISettings(s)
        restoreControl(inputType,s,'InputType');restoreControl(pixelMode,s,'PixelCoordinateMode');
        restoreControl(baselineField,s,'ManualBaseline');restoreControl(clampCheck,s,'ClampNegative');
        restoreControl(displayDrop,s,'DisplaySignal');restoreControl(scaleDrop,s,'YScale');
        restoreControl(normalizedSearch,s,'NormalizedSearch');restoreControl(minHeight,s,'MinHeight');
        restoreControl(minProm,s,'MinProminence');restoreControl(minDist,s,'MinDistance');
        restoreControl(minWidth,s,'MinWidth');restoreControl(maxWidth,s,'MaxWidth');
        restoreControl(leftSpin,s,'LeftPixels');restoreControl(rightSpin,s,'RightPixels');
        restoreControl(methodDrop,s,'InterpolationMethod');restoreControl(factorSpin,s,'InterpolationFactor');
        restoreControl(positionDrop,s,'PositionMethod');restoreControl(degreeSpin,s,'PolynomialDegree');
        restoreControl(paperPeakDifferenceFitOrder,s,'PaperPeakDifferenceFitOrder');
        restoreControl(paperPeakDifferenceFitSeries,s,'PaperPeakDifferenceFitSeries');
        restoreControl(paperShowDirect,s,'PaperShowDirect');restoreControl(paperShowInterpolated,s,'PaperShowInterpolated');restoreControl(paperShowCentroid,s,'PaperShowCentroid');
        restoreControl(paperShowCalibrationOnly,s,'PaperShowCalibrationOnly');
        restoreControl(optimizationPositionMethod,s,'OptimizationPositionMethod');
        restoreControl(optimizationDegree,s,'OptimizationDegree');restoreControl(optimizationStop,s,'OptimizationStop');
        restoreControl(optimizationMaxOrder,s,'OptimizationMaxOrder');
        restoreControl(influenceDegree,s,'InfluenceDegree');restoreControl(influenceMaxOrder,s,'InfluenceMaxOrder');
        restoreControl(influencePositionMethod,s,'InfluencePositionMethod');
        restoreControl(influenceXAxisMode,s,'InfluenceXAxisMode');
        restoreControl(positionCrossDegree,s,'PositionCrossDegree');restoreControl(positionCrossValidationMode,s,'PositionCrossValidationMode');
        restoreControl(positionCrossPoolMode,s,'PositionCrossPoolMode');restoreControl(positionCrossTrainingSource,s,'PositionCrossTrainingSource');restoreControl(positionCrossMetric,s,'PositionCrossMetric');
        if isfield(s,'PositionCrossView')
            crossViewTabs=[positionCrossDetailTab positionCrossMetricOverviewTab positionCrossRowResidualTab positionCrossHistogramOverviewTab];
            crossViewTitles=arrayfun(@(q)string(q.Title),crossViewTabs);
            crossViewIndex=find(crossViewTitles==string(s.PositionCrossView),1);
            if ~isempty(crossViewIndex),positionCrossViewTabs.SelectedTab=crossViewTabs(crossViewIndex);end
        end
        restoreControl(positionCrossResidualView,s,'PositionCrossResidualView');restoreControl(positionCrossHistBins,s,'PositionCrossHistBins');
        restoreControl(positionCrossHistRangeMode,s,'PositionCrossHistRangeMode');restoreControl(positionCrossHistXMin,s,'PositionCrossHistXMin');restoreControl(positionCrossHistXMax,s,'PositionCrossHistXMax');
        restoreControl(influenceYMode,s,'InfluenceYMode');restoreControl(influenceYMin,s,'InfluenceYMin');restoreControl(influenceYMax,s,'InfluenceYMax');
        restoreControl(replacementRMSEThreshold,s,'ReplacementRMSEThreshold');restoreControl(seedValidationMode,s,'ReplacementValidationMode');
        restoreControl(selectedHistBinCount,s,'SelectedResidualBins');
        restoreControl(selectedHistRangeMode,s,'SelectedResidualRangeMode');
        restoreControl(selectedHistXMin,s,'SelectedResidualXMin');restoreControl(selectedHistXMax,s,'SelectedResidualXMax');
        restoreControl(confidenceThreshold,s,'ConfidenceThreshold');restoreControl(histBinCount,s,'ResidualBins');
        restoreControl(fwhmHistBinCount,s,'FWHMBins');restoreControl(fwhmHistRangeMode,s,'FWHMRangeMode');
        restoreControl(fwhmHistXMin,s,'FWHMXMin');restoreControl(fwhmHistXMax,s,'FWHMXMax');
        restoreControl(peakDifferenceUnit,s,'PeakDifferenceUnit');restoreControl(peakDifferenceXMode,s,'PeakDifferenceXMode');
        restoreControl(peakDifferenceSeries,s,'PeakDifferenceSeries');
        if isfield(s,'PeakDifferenceFitTarget')
            oldFitTarget=char(string(s.PeakDifferenceFitTarget));
            if strcmp(oldFitTarget,'Direct - center'),s.PeakDifferenceFitTarget='Direct peak';
            elseif strcmp(oldFitTarget,'Interpolated - center'),s.PeakDifferenceFitTarget='Interpolated peak';end
        end
        restoreControl(peakDifferenceFitTarget,s,'PeakDifferenceFitTarget');restoreControl(peakDifferenceFitOrder,s,'PeakDifferenceFitOrder');
        restoreControl(peakDifferenceDistributionBinCount,s,'PeakDifferenceDistributionBins');
        restoreControl(peakDifferenceDistributionRangeMode,s,'PeakDifferenceDistributionRangeMode');
        restoreControl(peakDifferenceDistributionXMin,s,'PeakDifferenceDistributionXMin');restoreControl(peakDifferenceDistributionXMax,s,'PeakDifferenceDistributionXMax');
        restoreControl(peakDifferenceHistBinCount,s,'PeakDifferenceHistBins');restoreControl(peakDifferenceHistRangeMode,s,'PeakDifferenceHistRangeMode');
        restoreControl(peakDifferenceHistXMin,s,'PeakDifferenceHistXMin');restoreControl(peakDifferenceHistXMax,s,'PeakDifferenceHistXMax');
        if isfield(s,'ReferenceResolutionNm'),referenceResolutionNm=s.ReferenceResolutionNm;end
        if isfield(s,'SymmetryThresholdPx')&&isfinite(s.SymmetryThresholdPx)&&s.SymmetryThresholdPx>=0,symmetryThresholdPx=s.SymmetryThresholdPx;end
        symmetryThreshold.Value=symmetryThresholdPx;
        if isfield(s,'MainAxisMode'),mainAxisMode=char(string(s.MainAxisMode));else,mainAxisMode='Pixel';end
        if isfield(s,'MatchingAxisMode'),matchingAxisMode=char(string(s.MatchingAxisMode));else,matchingAxisMode='Pixel';end
    end

    function restoreControl(control,settings,name)
        if ~isfield(settings,name),return;end
        value=settings.(name);
        if isprop(control,'Limits')&&isnumeric(value)&&isscalar(value)&&isfinite(value)
            limits=control.Limits;
            if isnumeric(limits)&&numel(limits)==2
                value=min(max(value,limits(1)),limits(2));
            end
        end
        control.Value=value;
    end

    function refreshSessionViews
        sourceLabel.Text=shortName(D.source);
        if isempty(D.dark)
            baselineField.Enable='on';clearDarkBtn.Enable='off';darkStatus.Text='Dark: none (manual constant baseline is active)';
        else
            baselineField.Enable='off';clearDarkBtn.Enable='on';darkStatus.Text=['Dark active: ' shortName(D.darkSource) ' | manual baseline disabled'];
        end
        if ~isempty(D.pixel),pixelViewStart.Value=min(D.pixel);pixelViewEnd.Value=max(D.pixel);end
        if L.loaded,referenceSetDrop.Value='External / User';end
        if isfield(appliedModel,'valid')&&appliedModel.valid&&~isempty(D.pixel)
            wl=evaluateWavelengthModel(appliedModel,D.pixel);
            if all(isfinite(wl))&&all(diff(wl)>0)
                D.calibratedWavelength=wl(:);
                [coordinateMode,coordinateDomain]=modelCoordinateLabels(appliedModel);
                appliedStatus.Text=sprintf('Applied: %s | %s | pixels %s | degree %d | %.4g to %.4g nm', ...
                    appliedModelName,coordinateMode,coordinateDomain,appliedModel.Degree,min(wl),max(wl));
            else
                appliedModel=emptyFinalModel();appliedModelName='';D.calibratedWavelength=[];mainAxisMode='Pixel';
            end
        else
            D.calibratedWavelength=[];mainAxisMode='Pixel';
            appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';
        end
        if strcmp(mainAxisMode,'Wavelength')&&isempty(D.calibratedWavelength),mainAxisMode='Pixel';end
        axisButton.Text=['X Axis: ' mainAxisMode '  <->'];
        refreshAll();refreshModelComparison();drawModelComparison([],[]);refreshValidationView([],[]);
        if finalModel.valid,drawEmbeddedResults();end
    end

    %% CALLBACKS
    function loadSpectrum(~,~)
        [fn,pn]=uigetfile({'*.csv','CSV (*.csv)'},'Load wavelength-lamp spectrum'); if isequal(fn,0), return; end
        try
            if strcmp(inputType.Value,'Wavelength (nm)')
                inputKind='Wavelength';
            else
                inputKind='Pixel';
            end
            D=wc4sm_read_spectrum_file(fullfile(pn,fn),inputKind,1);
            D.PixelCoordinateMode=pixelMode.Value;
            D.PixelFirst=min(D.pixel);D.PixelLast=max(D.pixel);
            y=D.raw;
            sourceLabel.Text=fn; mainAxisMode='Pixel'; matchingAxisMode='Pixel'; axisButton.Text='X Axis: Pixel  <->'; selectedRow=0; peaks=emptyPeaks(); peakDataset=emptyDataset();
            paperPeakDifferenceExcludedIDs={};paperPeakAllExcludedIDs={};paperPeakDifferenceSelectedID='';paperPeakDifferenceResult=struct();paperPeakPairArchive=emptyCalPairs();
            localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
            baselineField.Enable='on';clearDarkBtn.Enable='off';darkStatus.Text='Dark: none (manual constant baseline is active)';
            pixelViewStart.Value=min(D.pixel); pixelViewEnd.Value=max(D.pixel);
            fullViewStart.Value=min(D.pixel); fullViewEnd.Value=max(D.pixel);
            calPairs=emptyCalPairs(); provisional=emptyInitialModel(); selectedPairRow=0;
            finalModel=emptyFinalModel();appliedModel=emptyFinalModel();appliedModelName='';appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';calibrationModels=emptyCalibrationModels();refreshModelComparison();
            preprocess(); refreshAll(); topStatus.Text=sprintf('%d samples loaded',numel(y));
        catch ME
            uialert(fig,ME.message,'Import failed');
        end
    end

    function pixelModeChanged(~,~)
        if isempty(D.raw),return;end
        D.PixelCoordinateMode=pixelMode.Value;
        calPairs=emptyCalPairs();provisional=emptyInitialModel();finalModel=emptyFinalModel();
        appliedModel=emptyFinalModel();appliedModelName='';D.calibratedWavelength=[];
        calibrationModels=emptyCalibrationModels();mainAxisMode='Pixel';matchingAxisMode='Pixel';
        paperPeakDifferenceExcludedIDs={};paperPeakAllExcludedIDs={};paperPeakDifferenceSelectedID='';paperPeakDifferenceResult=struct();paperPeakPairArchive=emptyCalPairs();
        axisButton.Text='X Axis: Pixel  ⇄';appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';
        refreshCalibration();refreshModelComparison();drawFull();
        topStatus.Text=['Pixel sequence changed to ' pixelMode.Value '; calibration models were cleared'];
    end

    function loadDarkSpectrum(~,~)
        if isempty(D.raw)
            uialert(fig,'Load the measured spectrum before importing its dark spectrum.','Dark spectrum');
            return;
        end
        [fn,pn]=uigetfile({'*.csv','CSV (*.csv)'},'Load dark spectrum');if isequal(fn,0),return;end
        try
            darkResult=wc4sm_read_dark_spectrum(fullfile(pn,fn),D.inputX);
            D.dark=darkResult.values;D.darkSource=darkResult.source;
            baselineField.Enable='off';clearDarkBtn.Enable='on';
            darkStatus.Text=['Dark active: ' fn ' | manual baseline disabled'];
            preprocessingReset('Dark spectrum loaded: detect peaks again');
        catch ME
            uialert(fig,ME.message,'Dark-spectrum import failed');
        end
    end

    function clearDarkSpectrum(~,~)
        if isempty(D.raw),return;end
        D.dark=[];D.darkSource='';
        baselineField.Enable='on';clearDarkBtn.Enable='off';
        darkStatus.Text='Dark: none (manual constant baseline is active)';
        preprocessingReset('Dark spectrum cleared: detect peaks again');
    end

    function preprocessingReset(message)
        preprocess();peaks=emptyPeaks();localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
        selectedRow=0;peakDataset=emptyDataset();calPairs=emptyCalPairs();provisional=emptyInitialModel();
        paperPeakDifferenceExcludedIDs={};paperPeakAllExcludedIDs={};paperPeakDifferenceSelectedID='';paperPeakDifferenceResult=struct();paperPeakPairArchive=emptyCalPairs();
        finalModel=emptyFinalModel();appliedModel=emptyFinalModel();appliedModelName='';
        D.calibratedWavelength=[];mainAxisMode='Pixel';matchingAxisMode='Pixel';axisButton.Text='X Axis: Pixel  <->';
        appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';
        calibrationModels=emptyCalibrationModels();refreshModelComparison();
        refreshAll();refreshCalibration();topStatus.Text=message;
    end

    function loadReference(~,~)
        [fn,pn]=uigetfile({'*.csv','CSV (*.csv)'},'Load reference spectrum'); if isequal(fn,0), return; end
        try
            M=cleanMatrix(readmatrix(fullfile(pn,fn))); if size(M,2)<2, error('Reference spectrum requires two numeric columns.'); end
            R.x=M(:,1); R.y=M(:,2); good=isfinite(R.x)&isfinite(R.y); R.x=R.x(good); R.y=R.y(good);
            if any(diff(R.x)<=0), error('Reference X must be strictly increasing.'); end
            R.source=fullfile(pn,fn); R.loaded=true; drawFull(); topStatus.Text=['Reference: ' fn];
        catch ME
            uialert(fig,ME.message,'Reference import failed');
        end
    end

    function preprocessChanged(~,~)
        if isempty(D.raw), return; end
        preprocessingReset('Preprocessing changed: detect peaks again');
    end
    function displayChanged(~,~)
        if ~isempty(D.raw), drawFull(); end
        if exist('showMatchingCheck','var') && tabs.SelectedTab==tabMatchingPlots
            showCalibrationView([],[]);
        end
    end
    function fullViewChanged(~,~)
        if isempty(D.raw),return;end
        if ~isfinite(fullViewStart.Value)||~isfinite(fullViewEnd.Value)||fullViewEnd.Value<=fullViewStart.Value
            uialert(fig,'Full-spectrum End X must be greater than Start X.','Invalid full-spectrum range');
            resetFullViewRange();return;
        end
        drawFull();
    end
    function resetFullViewRange(varargin)
        if isempty(D.raw),return;end
        [x,~]=displayX();
        fullViewStart.Value=min(x);fullViewEnd.Value=max(x);
        drawFull();
    end
    function rightTabChanged(~,~)
        if tabs.SelectedTab==tabCal,showCalibrationView([],[]);end
    end
    function peakAnalysisTabChanged(~,event)
        if event.NewValue==peakGalleryTab,refreshPeakGallery();end
    end
    function ensurePeakGalleryAxes
        if numel(peakGalleryAxes)==64&&all(isgraphics(peakGalleryAxes)),return;end
        peakGalleryStatus.Text='Creating the 8x8 gallery for first use...';drawnow;
        peakGalleryAxes=gobjects(64,1);
        for galleryIndex=1:64
            peakGalleryAxes(galleryIndex)=uiaxes(peakGalleryGrid);peakGalleryAxes(galleryIndex).Layout.Row=ceil(galleryIndex/8);peakGalleryAxes(galleryIndex).Layout.Column=mod(galleryIndex-1,8)+1;
            peakGalleryAxes(galleryIndex).FontSize=7;peakGalleryAxes(galleryIndex).Box='on';peakGalleryAxes(galleryIndex).XGrid='off';peakGalleryAxes(galleryIndex).YGrid='off';
            peakGalleryAxes(galleryIndex).XTick=[];peakGalleryAxes(galleryIndex).YTick=[];
            if mod(galleryIndex,8)==0,peakGalleryStatus.Text=sprintf('Creating gallery axes: %d / 64',galleryIndex);drawnow limitrate;end
        end
    end
    function refreshPeakGallery(~,~)
        ensurePeakGalleryAxes();
        matchedMask=[calPairs.ReferenceIndex]>0&isfinite([calPairs.ReferenceWavelength]);
        matchedIDs=string({calPairs(matchedMask).PeakID});
        useWavelength=strcmp(mainAxisMode,'Wavelength')&&appliedModel.valid;
        analyzedCount=0;displayCount=min(numel(peaks),64);
        for galleryIndex=1:64
            ax=peakGalleryAxes(galleryIndex);cla(ax,'reset');ax.FontSize=7;ax.Box='on';
            ax.XGrid='off';ax.YGrid='off';ax.XTick=[];ax.YTick=[];ax.XTickLabel={};ax.YTickLabel={};
            if galleryIndex>displayCount
                axis(ax,'off');continue;
            end
            p=peaks(galleryIndex);isBenchmark=any(matchedIDs==string(p.ID));
            if isBenchmark,lineColor=C.blueStrong;else,lineColor=C.red;end
            if isempty(p.Result)||~isstruct(p.Result)||~isfield(p.Result,'WindowX')||isempty(p.Result.WindowX)
                axis(ax,'on');ax.XTick=[];ax.YTick=[];title(ax,p.ID,'Color',lineColor,'FontSize',7,'FontWeight','bold','Interpreter','none');
                text(ax,.5,.5,'not analyzed','Units','normalized','HorizontalAlignment','center','FontSize',6,'Color',C.muted);
                continue;
            end
            rr=p.Result;x=rr.WindowX(:);y=rr.NetY(:);
            if useWavelength,x=evaluateWavelengthModel(appliedModel,x);end
            good=isfinite(x)&isfinite(y);x=x(good);y=y(good);
            if isempty(x),axis(ax,'off');continue;end
            plot(ax,x,y,'o-','Color',lineColor,'LineWidth',0.75,'MarkerSize',3.2, ...
                'MarkerFaceColor',C.yellow,'MarkerEdgeColor',lineColor,'HitTest','off');
            xlim(ax,sort([x(1) x(end)]));ymin=min(y);ymax=max(y);span=max(ymax-ymin,eps);
            ylim(ax,[ymin-.06*span ymax+.10*span]);
            centerX=NaN;if isfield(rr,'CenterX'),centerX=rr.CenterX;end
            if appliedModel.valid&&isfinite(centerX)
                centerWavelength=evaluateWavelengthModel(appliedModel,centerX);
                if isfinite(centerWavelength),galleryTitle=sprintf('%s | %.3f nm',p.ID,centerWavelength);else,galleryTitle=p.ID;end
            elseif isfinite(centerX)
                galleryTitle=sprintf('%s | %.2f px',p.ID,centerX);
            else
                galleryTitle=p.ID;
            end
            title(ax,galleryTitle,'Color',lineColor,'FontSize',6.5,'FontWeight','bold','Interpreter','none');
            analyzedCount=analyzedCount+1;
        end
        if useWavelength,coordinate='calibrated wavelength';else,coordinate='natural pixel';end
        peakGalleryStatus.Text=sprintf('%d / %d detected peaks displayed with analyzed windows | X: %s',analyzedCount,numel(peaks),coordinate);
        peakGalleryStatus.Tooltip=peakGalleryStatus.Text;
    end
    function toggleMainAxis(~,~)
        if strcmp(mainAxisMode,'Pixel')
            if ~isempty(D.calibratedWavelength),mainAxisMode='Wavelength';
            else,uialert(fig,'No calibration model is currently applied. Select a validated model in Model Comparison and click Apply.','Wavelength unavailable');return;end
        else,mainAxisMode='Pixel';end
        matchingAxisMode=mainAxisMode;
        axisButton.Text=['X Axis: ' mainAxisMode '  <->'];
        % Pixel and wavelength coordinates have different numerical domains.
        % A previous zoom or guide line can leave XLimMode manual, so force a
        % fresh fit whenever the coordinate system changes.
        xlim(axFull,'auto');ylim(axFull,'auto');resetFullViewRange();
        drawFull();if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
        if peakAnalysisTabs.SelectedTab==peakGalleryTab,refreshPeakGallery();end
        if tabs.SelectedTab==tabCal,showCalibrationView([],[]);end
    end
    function markDetectionPending(~,~)
        if isempty(D.raw)
            topStatus.Text='Load a spectrum before peak detection';
        else
            topStatus.Text='Detection parameters changed: press CONFIRM & DETECT ALL PEAKS';
            detectBtn.BackgroundColor=C.orange;
        end
    end
    function windowChanged(~,~)
        if selectedRow>0
            invalidateConfirmation(selectedRow);
            analyzeSelected();
        end
    end

    function invalidateConfirmation(row)
        if row<1 || row>numel(peaks),return;end
        k=find(strcmp({peakDataset.PeakID},peaks(row).ID),1);
        if ~isempty(k) && peakDataset(k).Confirmed
            peakDataset(k).Confirmed=false;
            peakDataset(k).Status='Modified - unconfirmed';
            peaks(row).Status='Modified - unconfirmed';
            topStatus.Text=[peaks(row).ID ' settings changed: reconfirm before calibration'];
            refreshDataset();refreshCalibration();
        end
    end

    function preprocess
        processed=wc4sm_preprocess_spectrum( ...
            D.raw,D.dark,baselineField.Value,clampCheck.Value);
        D.corrected=processed.corrected;
        D.normalized=processed.normalized;
    end

    function detectPeaks(~,~)
        if isempty(D.raw), return; end
        try
            if normalizedSearch.Value, ys=D.normalized; else, ys=D.corrected; end
            args={'MinPeakHeight',minHeight.Value,'MinPeakProminence',minProm.Value,'MinPeakDistance',minDist.Value};
            if minWidth.Value>0, args=[args {'MinPeakWidth',minWidth.Value}]; end %#ok<AGROW>
            if isfinite(maxWidth.Value), args=[args {'MaxPeakWidth',maxWidth.Value}]; end %#ok<AGROW>
            [pks,locs,widths,proms]=findpeaks(ys,args{:});
            peaks=emptyPeaks();
            localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
            for i=1:numel(locs)
                peaks(i).ID=sprintf('P%03d',i); peaks(i).Index=locs(i); peaks(i).Pixel=D.pixel(locs(i));
                peaks(i).InputX=D.inputX(locs(i)); peaks(i).Height=pks(i); peaks(i).Prominence=proms(i);
                peaks(i).Width=widths(i); peaks(i).Status='Unreviewed'; peaks(i).Result=[];
            end
            selectedRow=0; refreshPeakTable(); drawFull(); clearCurrent();
            peakCountLabel.Text=sprintf('Detected peaks: %d',numel(peaks)); topStatus.Text=peakCountLabel.Text;
            detectBtn.BackgroundColor=C.cyan;
            refreshCalibration();
        catch ME
            uialert(fig,[ME.message newline 'findpeaks requires Signal Processing Toolbox.'],'Peak detection failed');
        end
    end

    function openLocalSearchDialog(~,~)
        if isempty(D.raw)
            uialert(fig,'Load a spectrum first.','Subwindow search');return;
        end
        if isempty(peaks)
            uialert(fig,'Run full-spectrum detection first. Local detection supplements, rather than replaces, the full peak list.','Subwindow search');return;
        end
        limits=[min(D.pixel) max(D.pixel)];
        viewLimits=limits;
        try
            if strcmp(mainAxisMode,'Pixel')
                viewLimits=[max(limits(1),axFull.XLim(1)) min(limits(2),axFull.XLim(2))];
            elseif ~isempty(D.calibratedWavelength)
                [~,q1]=min(abs(D.calibratedWavelength-axFull.XLim(1)));
                [~,q2]=min(abs(D.calibratedWavelength-axFull.XLim(2)));
                viewLimits=sort([D.pixel(q1) D.pixel(q2)]);
            end
        catch
        end
        if diff(viewLimits)<1,viewLimits=limits;end
        ld=uifigure('Name','WCC4SM V1.0 | Weak-peak subwindow search','Position',[180 160 520 520],'Color',C.bg);
        lg=uigridlayout(ld,[13 2]);lg.ColumnWidth={180,'1x'};lg.RowHeight={32,30,30,30,30,30,30,30,34,34,30,34,'1x'};lg.Padding=[12 12 12 12];
        note=uilabel(lg,'Text','Local search normalizes within this window, uses separate sensitive parameters, and produces candidates only.','FontColor',C.navy,'FontWeight','bold','WordWrap','on');note.Layout.Column=[1 2];
        uilabel(lg,'Text','Start pixel');lStart=uieditfield(lg,'numeric','Value',viewLimits(1));
        uilabel(lg,'Text','End pixel');lEnd=uieditfield(lg,'numeric','Value',viewLimits(2));
        localSearchWindow=sort(viewLimits);drawFull();
        lStart.ValueChangedFcn=@(~,~)updateLocalSearchWindow(lStart,lEnd);
        lEnd.ValueChangedFcn=@(~,~)updateLocalSearchWindow(lStart,lEnd);
        ld.CloseRequestFcn=@(~,~)closeLocalSearchDialog(ld);
        lNorm=uicheckbox(lg,'Text','Search normalized signal','Value',true);lNorm.Layout.Column=[1 2];
        uilabel(lg,'Text','Min peak height');lHeight=uieditfield(lg,'numeric','Value',max(eps,minHeight.Value/5),'Limits',[0 Inf]);
        uilabel(lg,'Text','Min prominence');lProm=uieditfield(lg,'numeric','Value',max(eps,minProm.Value/5),'Limits',[0 Inf]);
        uilabel(lg,'Text','Min distance (px)');lDist=uispinner(lg,'Limits',[1 10000],'Step',1,'Value',max(1,minDist.Value));
        uilabel(lg,'Text','Min width (px)');lWidth=uieditfield(lg,'numeric','Value',0,'Limits',[0 Inf]);
        detectLocalBtn=uibutton(lg,'Text','DETECT CANDIDATES IN WINDOW','FontWeight','bold','BackgroundColor',C.cyan);detectLocalBtn.Layout.Column=[1 2];
        uilabel(lg,'Text','Candidate');candidateDrop=uidropdown(lg,'Items',{'(none)'},'Value','(none)');
        candidateInfo=uilabel(lg,'Text','No local candidates.','FontColor',C.muted,'WordWrap','on');candidateInfo.Layout.Column=[1 2];
        addLocalBtn=uibutton(lg,'Text','ADD SELECTED CANDIDATE TO PEAK LIST','FontWeight','bold','BackgroundColor',C.greenLight,'Enable','off');addLocalBtn.Layout.Column=[1 2];
        clearLocalBtn=uibutton(lg,'Text','Clear candidate markers','Enable','off');clearLocalBtn.Layout.Column=[1 2];
        detectLocalBtn.ButtonPushedFcn=@(~,~)detectLocalCandidates(lStart,lEnd,lNorm,lHeight,lProm,lDist,lWidth,candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
        candidateDrop.ValueChangedFcn=@(~,~)selectLocalCandidate(candidateDrop,candidateInfo);
        addLocalBtn.ButtonPushedFcn=@(~,~)addLocalCandidate(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
        clearLocalBtn.ButtonPushedFcn=@(~,~)clearLocalCandidates(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
    end

    function updateLocalSearchWindow(lStart,lEnd)
        if isempty(D.pixel),return;end
        lo=max(min(D.pixel),min(lStart.Value,lEnd.Value));
        hi=min(max(D.pixel),max(lStart.Value,lEnd.Value));
        if hi<lo,lo=min(D.pixel);hi=max(D.pixel);end
        lStart.Value=lo;lEnd.Value=hi;localSearchWindow=[lo hi];drawFull();
        topStatus.Text=sprintf('Subwindow preview: pixel %.6g to %.6g',lo,hi);
    end

    function closeLocalSearchDialog(dialogFigure)
        localSearchWindow=[NaN NaN];drawFull();delete(dialogFigure);
    end

    function detectLocalCandidates(lStart,lEnd,lNorm,lHeight,lProm,lDist,lWidth,candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn)
        try
            lo=min(lStart.Value,lEnd.Value);hi=max(lStart.Value,lEnd.Value);
            use=find(D.pixel>=lo & D.pixel<=hi);
            if numel(use)<3,error('The selected subwindow must contain at least three samples.');end
            ys=D.corrected(use);
            if lNorm.Value
                localMax=max(ys);
                if localMax>0,ys=ys/localMax;else,ys=zeros(size(ys));end
            end
            args={'MinPeakHeight',lHeight.Value,'MinPeakProminence',lProm.Value,'MinPeakDistance',lDist.Value};
            if lWidth.Value>0,args=[args {'MinPeakWidth',lWidth.Value}];end %#ok<AGROW>
            [pksLocal,locsLocal,widthsLocal,promsLocal]=findpeaks(ys,args{:});
            indices=use(locsLocal);
            isNew=true(size(indices));
            if ~isempty(peaks)
                for jj=1:numel(indices),isNew(jj)=~any([peaks.Index]==indices(jj));end
            end
            indices=indices(isNew);pksLocal=pksLocal(isNew);widthsLocal=widthsLocal(isNew);promsLocal=promsLocal(isNew);
            localCandidates=emptyLocalCandidates();
            for jj=1:numel(indices)
                localCandidates(jj).Index=indices(jj);localCandidates(jj).Pixel=D.pixel(indices(jj));
                localCandidates(jj).InputX=D.inputX(indices(jj));localCandidates(jj).Height=pksLocal(jj);
                localCandidates(jj).Prominence=promsLocal(jj);localCandidates(jj).Width=widthsLocal(jj);
            end
            selectedLocalCandidate=double(~isempty(localCandidates));
            updateLocalCandidateControls(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
            drawFull();plotTabs.SelectedTab=tabPlots;
            topStatus.Text=sprintf('Subwindow search: %d new candidate(s), awaiting manual addition',numel(localCandidates));
        catch ME
            uialert(fig,ME.message,'Subwindow detection failed');
        end
    end

    function selectLocalCandidate(candidateDrop,candidateInfo)
        if isempty(localCandidates),return;end
        selectedLocalCandidate=find(strcmp(candidateDrop.Items,candidateDrop.Value),1);
        if isempty(selectedLocalCandidate),selectedLocalCandidate=1;end
        updateLocalCandidateControls(candidateDrop,candidateInfo,[],[]);
        drawFull();
    end

    function updateLocalCandidateControls(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn)
        if isempty(localCandidates)
            candidateDrop.Items={'(none)'};candidateDrop.Value='(none)';
            candidateInfo.Text='No new candidate outside the full-spectrum peak list.';
            if ~isempty(addLocalBtn),addLocalBtn.Enable='off';end
            if ~isempty(clearLocalBtn),clearLocalBtn.Enable='off';end
            return;
        end
        items=cell(1,numel(localCandidates));
        for jj=1:numel(localCandidates)
            items{jj}=sprintf('C%02d | pixel %.6g | prom %.4g',jj,localCandidates(jj).Pixel,localCandidates(jj).Prominence);
        end
        selectedLocalCandidate=max(1,min(selectedLocalCandidate,numel(items)));
        candidateDrop.Items=items;candidateDrop.Value=items{selectedLocalCandidate};
        q=localCandidates(selectedLocalCandidate);
        candidateInfo.Text=sprintf('Candidate %d/%d | pixel %.6g | input X %.7g | height %.4g | prominence %.4g | width %.4g px', ...
            selectedLocalCandidate,numel(localCandidates),q.Pixel,q.InputX,q.Height,q.Prominence,q.Width);
        if ~isempty(addLocalBtn),addLocalBtn.Enable='on';end
        if ~isempty(clearLocalBtn),clearLocalBtn.Enable='on';end
    end

    function addLocalCandidate(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn)
        if isempty(localCandidates)||selectedLocalCandidate<1||selectedLocalCandidate>numel(localCandidates),return;end
        q=localCandidates(selectedLocalCandidate);
        if any([peaks.Index]==q.Index)
            uialert(fig,'This candidate is already present in the peak list.','Duplicate candidate');return;
        end
        oldIDs={peaks.ID};oldIndices=[peaks.Index];
        item=struct('ID','','Index',q.Index,'Pixel',q.Pixel,'InputX',q.InputX,'Height',q.Height, ...
            'Prominence',q.Prominence,'Width',q.Width,'Status','Locally added - unreviewed','Result',[]);
        peaks(end+1)=item;
        [~,order]=sort([peaks.Index]);peaks=peaks(order);
        for jj=1:numel(peaks),peaks(jj).ID=sprintf('P%03d',jj);end
        remapStoredPeakIDs(oldIDs,oldIndices);
        selectedRow=find([peaks.Index]==q.Index,1);
        localCandidates(selectedLocalCandidate)=[];
        selectedLocalCandidate=min(selectedLocalCandidate,numel(localCandidates));
        updateLocalCandidateControls(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
        refreshPeakTable();refreshDataset();refreshCalibration();drawFull();showSelected();
        topStatus.Text=sprintf('%s inserted from local search at pixel %.6g; manually analyze and confirm it',peaks(selectedRow).ID,q.Pixel);
    end

    function remapStoredPeakIDs(oldIDs,oldIndices)
        newIDs=oldIDs;
        for jj=1:numel(oldIDs)
            newRow=find([peaks.Index]==oldIndices(jj),1);
            if isempty(newRow),continue;end
            newIDs{jj}=peaks(newRow).ID;
            k=find([peakDataset.PeakIndex]==oldIndices(jj));
            for kk=k,peakDataset(kk).PeakID=newIDs{jj};end
            k=find([calPairs.PeakIndex]==oldIndices(jj));
            for kk=k,calPairs(kk).PeakID=newIDs{jj};end
        end
        if finalModel.valid
            original=finalModel.PeakID;
            for jj=1:numel(oldIDs),finalModel.PeakID(strcmp(original,oldIDs{jj}))=newIDs(jj);end
        end
        for mm=1:numel(calibrationModels)
            if isfield(calibrationModels(mm),'PairIDs')
                original=calibrationModels(mm).PairIDs;
                for jj=1:numel(oldIDs),calibrationModels(mm).PairIDs(strcmp(original,oldIDs{jj}))=newIDs(jj);end
            end
            if isfield(calibrationModels(mm),'Model') && isfield(calibrationModels(mm).Model,'PeakID')
                original=calibrationModels(mm).Model.PeakID;
                for jj=1:numel(oldIDs),calibrationModels(mm).Model.PeakID(strcmp(original,oldIDs{jj}))=newIDs(jj);end
            end
        end
    end

    function clearLocalCandidates(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn)
        localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
        updateLocalCandidateControls(candidateDrop,candidateInfo,addLocalBtn,clearLocalBtn);
        drawFull();topStatus.Text='Local candidate markers cleared';
    end

    function selectPeak(~,event)
        if isempty(event.Indices), return; end
        selectedRow=event.Indices(1);plotTabs.SelectedTab=tabPlots;peakAnalysisTabs.SelectedTab=peakAnalysisCurrentTab;showSelected();leftTabs.SelectedTab=tabCurrent;
    end
    function previousPeak(~,~)
        if isempty(peaks), return; end
        selectedRow=max(1,selectedRow-1); showSelected();
    end
    function nextPeak(~,~)
        if isempty(peaks), return; end
        selectedRow=min(numel(peaks),max(1,selectedRow+1)); showSelected();
    end

    function showSelected
        if selectedRow<1 || selectedRow>numel(peaks), return; end
        p=peaks(selectedRow); currentLabel.Text=sprintf('%s | Pixel %g | Input X %.8g',p.ID,p.Pixel,p.InputX);
        analyzeBtn.Enable='on'; excludeBtn.Enable='on'; analyzeSelected(); highlightTableRow();
    end

    function analyzeSelected(~,~)
        if selectedRow<1 || selectedRow>numel(peaks), return; end
        try
            p=peaks(selectedRow); center=D.pixel(p.Index);
            % Global manual baseline is already removed. The local engine uses
            % a linear endpoint baseline to isolate the selected peak.
            rr=wc4sm_analyze_peak(D.pixel,D.corrected,center,leftSpin.Value,rightSpin.Value,methodDrop.Value,factorSpin.Value,'linear');
            rr=classifyPeakWindow(rr,p.Index);
            peaks(selectedRow).Result=rr;
            if ~strcmp(peaks(selectedRow).Status,'Excluded')
                k=find(strcmp({peakDataset.PeakID},p.ID),1);
                if isempty(k) || ~peakDataset(k).Confirmed
                    if strcmp(rr.CalibrationUsability,'PositionOnly')
                        peaks(selectedRow).Status='Position only - unconfirmed';
                    else
                        peaks(selectedRow).Status='Analyzed - unconfirmed';
                    end
                end
            end
            drawFull(); drawPeak(rr); showParameters(rr); addBtn.Enable='on';confirmNextBtn.Enable='on'; refreshPeakTable();
        catch ME
            warnings.Value={ME.message}; addBtn.Enable='off';
        end
    end

    function rr=classifyPeakWindow(rr,currentPeakIndex)
        % The full-spectrum detector is the primary source for deciding
        % whether the selected subwindow contains more than one peak top.
        detectedIndices=[peaks.Index];
        inWindow=detectedIndices>=rr.WindowIndex(1) & detectedIndices<=rr.WindowIndex(2);
        memberIndices=detectedIndices(inWindow);
        memberIDs={peaks(inWindow).ID};

        rr.DetectedPeakCount=numel(memberIndices);
        rr.DetectedPeakIDs=memberIDs;
        rr.PeakShapeStatus='SinglePeak';
        rr.CalibrationUsability='Full';
        rr.InterferenceFlag=false;
        rr.LocalInterpolationBounds=[rr.WindowX(1) rr.WindowX(end)];

        if numel(memberIndices)<=1
            return;
        end

        % Restrict interpolation for the selected feature by the measured
        % valleys between it and its nearest detected neighbours. This
        % prevents a stronger neighbour from capturing the interpolated
        % peak position.
        leftCandidates=memberIndices(memberIndices<currentPeakIndex);
        rightCandidates=memberIndices(memberIndices>currentPeakIndex);
        leftBoundIndex=rr.WindowIndex(1);
        rightBoundIndex=rr.WindowIndex(2);
        if ~isempty(leftCandidates)
            leftNeighbour=max(leftCandidates);
            [~,q]=min(D.corrected(leftNeighbour:currentPeakIndex));
            leftBoundIndex=leftNeighbour+q-1;
        end
        if ~isempty(rightCandidates)
            rightNeighbour=min(rightCandidates);
            [~,q]=min(D.corrected(currentPeakIndex:rightNeighbour));
            rightBoundIndex=currentPeakIndex+q-1;
        end
        leftBound=D.pixel(leftBoundIndex);
        rightBound=D.pixel(rightBoundIndex);
        localMask=rr.InterpX>=leftBound & rr.InterpX<=rightBound;
        if any(localMask)
            localIndices=find(localMask);
            [localHeight,q]=max(rr.InterpNetY(localMask));
            localIndex=localIndices(q);
            rr.InterpolatedPeakX=rr.InterpX(localIndex);
            rr.InterpolatedPeakY=localHeight;
        end

        rr.PeakShapeStatus='MultiPeak';
        rr.CalibrationUsability='PositionOnly';
        rr.InterferenceFlag=true;
        rr.LocalInterpolationBounds=[leftBound rightBound];
        rr.Status='MultiPeak - position only';
        rr.Warnings=[string(rr.Warnings(:)); ...
            "Multiple detected peak tops occur in this subwindow."; ...
            "Only the direct sampled peak and valley-bounded local interpolated peak are valid for calibration."; ...
            "FWHM center, centroid, FWHM, ERW, area and Gaussian-fit parameters are disabled."];

        % Shape and moment parameters do not represent the selected line
        % independently once another detected peak lies in the subwindow.
        rr.CenterX=NaN;
        rr.CentroidX=NaN;
        rr.LeftHalfX=NaN;
        rr.RightHalfX=NaN;
        rr.FWHM=NaN;
        rr.LeftHWHM=NaN;
        rr.RightHWHM=NaN;
        rr.ERW=NaN;
        rr.PeakArea=NaN;
        rr.PeakCenterDelta=NaN;
        rr.InterpolationCenterDelta=NaN;
        rr.CentroidCenterDelta=NaN;
        rr.ERWminusFWHM=NaN;
        rr.ERWdivFWHM=NaN;
        rr.SamplingRatio=NaN;
        rr.ERWSamplingRatio=NaN;
    end

    function confirmPeak(~,~)
        if selectedRow<1 || isempty(peaks(selectedRow).Result), return; end
        p=peaks(selectedRow); rr=p.Result; k=find(strcmp({peakDataset.PeakID},p.ID),1);
        item=struct('PeakID',p.ID,'PeakIndex',p.Index,'Pixel',p.Pixel,'InputX',p.InputX,'ReferenceWavelength',NaN, ...
            'Source',D.source,'WindowPixel',rr.WindowX,'WindowADCounts',D.raw(rr.WindowIndex(1):rr.WindowIndex(2)), ...
            'WindowCorrected',rr.WindowY,'AnalysisResult',rr,'FindPeakHeight',p.Height,'FindPeakProminence',p.Prominence, ...
            'FindPeakWidth',p.Width,'Status','Confirmed','Confirmed',true,'ConfirmedAt',datetime('now'), ...
            'ConfirmedSettings',analysisSettings());
        if isempty(k), peakDataset(end+1)=item; else, item.ReferenceWavelength=peakDataset(k).ReferenceWavelength; peakDataset(k)=item; end
        if strcmp(rr.CalibrationUsability,'PositionOnly')
            peakDataset(find(strcmp({peakDataset.PeakID},p.ID),1)).Status='Confirmed - PositionOnly';
            peaks(selectedRow).Status='Confirmed - PositionOnly';
            topStatus.Text=[p.ID ' confirmed: position-only calibration feature'];
        else
            peaks(selectedRow).Status='Confirmed';
            topStatus.Text=[p.ID ' peak parameters confirmed'];
        end
        refreshPeakTable(); refreshDataset();
        refreshCalibration();
    end

    function s=analysisSettings
        s=struct('LeftPixels',leftSpin.Value,'RightPixels',rightSpin.Value, ...
            'InterpolationMethod',methodDrop.Value,'InterpolationFactor',factorSpin.Value, ...
            'LocalBaselineMethod','linear-endpoint');
    end

    function confirmAndNext(~,~)
        if selectedRow<1,return;end
        confirmPeak([],[]);
        q=findNextUnconfirmed(selectedRow);
        if q>0
            selectedRow=q;showSelected();
        else
            topStatus.Text='All non-excluded detected peaks have been confirmed';
        end
    end

    function q=findNextUnconfirmed(afterRow)
        q=0;n=numel(peaks);
        for step=1:n
            ii=mod(afterRow-1+step,n)+1;
            if strcmp(peaks(ii).Status,'Excluded'),continue;end
            k=find(strcmp({peakDataset.PeakID},peaks(ii).ID),1);
            if isempty(k) || ~peakDataset(k).Confirmed,q=ii;return;end
        end
    end

    function analyzeAll(~,~)
        if isempty(peaks),uialert(fig,'Detect peaks first.','No detected peaks');return;end
        dlg=uiprogressdlg(fig,'Title','Batch peak analysis','Message','Analyzing detected peaks...','Indeterminate','off');
        okCount=0;skipCount=0;failCount=0;
        for ii=1:numel(peaks)
            dlg.Value=ii/numel(peaks);dlg.Message=sprintf('Analyzing %s (%d/%d)',peaks(ii).ID,ii,numel(peaks));drawnow limitrate;
            if strcmp(peaks(ii).Status,'Excluded'),skipCount=skipCount+1;continue;end
            try
                p=peaks(ii);center=D.pixel(p.Index);
                rr=wc4sm_analyze_peak(D.pixel,D.corrected,center,leftSpin.Value,rightSpin.Value,methodDrop.Value,factorSpin.Value,'linear');
                rr=classifyPeakWindow(rr,p.Index);
                peaks(ii).Result=rr;
                if strcmp(rr.CalibrationUsability,'PositionOnly')
                    peaks(ii).Status='Position only - unconfirmed';
                else
                    peaks(ii).Status='Analyzed - unconfirmed';
                end
                okCount=okCount+1;
            catch
                peaks(ii).Status='Analysis failed';failCount=failCount+1;
            end
        end
        close(dlg);refreshPeakTable();refreshDataset();refreshCalibration();drawFull();
        if peakAnalysisTabs.SelectedTab==peakGalleryTab,refreshPeakGallery();end
        topStatus.Text=sprintf('Batch preview: %d analyzed, %d excluded, %d failed; confirmation states unchanged',okCount,skipCount,failCount);
        uialert(fig,topStatus.Text,'Batch analysis completed','Icon','success');
    end

    function toggleExclude(~,~)
        if selectedRow<1, return; end
        if strcmp(peaks(selectedRow).Status,'Excluded'), peaks(selectedRow).Status='Unreviewed';
        else
            invalidateConfirmation(selectedRow);
            peaks(selectedRow).Status='Excluded';
        end
        refreshPeakTable(); drawFull();
    end

    function removeDataset(~,~)
        row=selectedDatasetRow; if row<1 || row>numel(peakDataset), return; end
        id=peakDataset(row).PeakID; peakDataset(row)=[]; k=find(strcmp({peaks.ID},id),1);
        if ~isempty(k)
            if isempty(peaks(k).Result),peaks(k).Status='Unreviewed';else,peaks(k).Status='Analyzed - unconfirmed';end
        end
        selectedDatasetRow=0;
        refreshDataset(); refreshPeakTable(); refreshCalibration(); drawFull();
    end

    function selectDatasetRow(~,event)
        if isempty(event.Indices), selectedDatasetRow=0; else, selectedDatasetRow=event.Indices(1); end
    end

    function editDatasetCell(~,event)
        if isempty(event.Indices), return; end
        row=event.Indices(1); col=event.Indices(2);
        if col==3 && row>=1 && row<=numel(peakDataset)
            peakDataset(row).ReferenceWavelength=numberOrNaN(event.NewData);
        end
    end

    function exportDataset(~,~)
        if isempty(peakDataset), uialert(fig,'Peak Dataset is empty.','Nothing to export'); return; end
        % Synchronize editable reference wavelengths from the table.
        td=datasetTable.Data; for i=1:numel(peakDataset), peakDataset(i).ReferenceWavelength=numberOrNaN(td{i,3}); end
        [fn,pn]=uiputfile('WCC4SM_peak_dataset.mat','Export Peak Dataset'); if isequal(fn,0), return; end
        PeakDataset=peakDataset; Spectrum=D; save(fullfile(pn,fn),'PeakDataset','Spectrum'); %#ok<NASGU>
        T=datasetSummaryTable(); [~,stem]=fileparts(fn); writetable(T,fullfile(pn,[stem '.csv'])); topStatus.Text='Peak Dataset exported';
    end

    %% REFERENCE LINE MATCHING AND INITIAL CALIBRATION
    function loadLineLibrary(~,~)
        [fn,pn]=uigetfile({'*.lit;*.txt;*.csv','Reference lines (*.lit,*.txt,*.csv)';'*.*','All files'}, ...
            'Load reference-line list',fullfile(referenceDataDir,'*.lit'));
        if isequal(fn,0), return; end
        try
            M=readmatrix(fullfile(pn,fn),'FileType','text');
            M=M(~all(isnan(M),2),:); M=M(:,~all(isnan(M),1));
            if size(M,2)<2, error('Reference-line file requires at least wavelength and relative-intensity columns.'); end
            w=M(:,1); inten=M(:,2);
            if size(M,2)>=3, ord=M(:,3); else, ord=ones(size(w)); end
            good=isfinite(w)&isfinite(inten)&isfinite(ord)&w>0&ord>=1;
            w=w(good); inten=inten(good); ord=round(ord(good));
            if numel(w)<2, error('At least two valid reference lines are required.'); end
            [~,ix]=sort(w.*ord); w=w(ix); inten=inten(ix); ord=ord(ix);
            Lexternal=emptyLineLibrary(); Lexternal.wavelength=w(:); Lexternal.intensity=inten(:); Lexternal.order=ord(:);
            Lexternal.effective=Lexternal.wavelength.*Lexternal.order; Lexternal.enabled=true(size(Lexternal.wavelength));Lexternal.source=fullfile(pn,fn); Lexternal.loaded=true;
            L=Lexternal; referenceSetDrop.Value='External / User';
            selectedRefRow=0; calPairs=emptyCalPairs(); provisional=emptyInitialModel(); selectedPairRow=0;
            finalModel=emptyFinalModel();calibrationModels=emptyCalibrationModels();refreshModelComparison();
            refreshCalibration(); showCalibrationView([],[]); topStatus.Text=sprintf('%d reference lines loaded',numel(w));
        catch ME
            uialert(fig,ME.message,'Reference-line import failed');
        end
    end

    function selectReferenceLine(~,event)
        if isempty(event.Indices), selectedRefRow=0; else, selectedRefRow=event.Indices(1); end
        if selectedRefRow>0, showCalibrationView([],[]); end
    end

    function enableSelectedReference(~,~)
        if selectedRefRow<1||selectedRefRow>numel(L.effective),return;end
        L.enabled(selectedRefRow)=true;refreshCalibration();showCalibrationView([],[]);
    end
    function disableSelectedReference(~,~)
        if selectedRefRow<1||selectedRefRow>numel(L.effective),return;end
        L.enabled(selectedRefRow)=false;refreshCalibration();showCalibrationView([],[]);
    end
    function importReferenceMode(~,~)
        if ~L.loaded,uialert(fig,'Load a reference master file first.','No master library');return;end
        [fn,pn]=uigetfile({'*.csv;*.txt','Reference selection mode (*.csv,*.txt)'},'Import reference selection mode');if isequal(fn,0),return;end
        try
            T=readtable(fullfile(pn,fn));names=lower(string(T.Properties.VariableNames));
            iw=find(contains(names,'wavelength'),1);io=find(strcmp(names,'order'),1);
            if isempty(iw),wmode=table2array(T(:,1));else,wmode=table2array(T(:,iw));end
            if isempty(io),omode=ones(size(wmode));else,omode=table2array(T(:,io));end
            L.enabled=false(size(L.effective));
            for kk=1:numel(wmode)
                [d,jj]=min(abs(L.wavelength-wmode(kk))+1000*abs(L.order-omode(kk)));
                if d<0.02,L.enabled(jj)=true;end
            end
            refreshCalibration();showCalibrationView([],[]);topStatus.Text=sprintf('Selection mode imported: %d/%d master lines enabled',sum(L.enabled),numel(L.enabled));
        catch ME,uialert(fig,ME.message,'Mode import failed');end
    end
    function exportReferenceMode(~,~)
        if ~L.loaded,return;end
        [fn,pn]=uiputfile('WCC4SM_reference_selection_mode.csv','Export reference selection mode');if isequal(fn,0),return;end
        use=find(L.enabled);LineID=strings(numel(use),1);Wavelength_nm=L.wavelength(use);Order=L.order(use);MasterSource=repmat(string(L.source),numel(use),1);
        for kk=1:numel(use),LineID(kk)=sprintf('WL%.6f_O%d',Wavelength_nm(kk),Order(kk));end
        writetable(table(LineID,Wavelength_nm,Order,MasterSource),fullfile(pn,fn));topStatus.Text='Reference selection mode exported';
    end

    function referenceSetChanged(~,~)
        switch referenceSetDrop.Value
            case 'Basic 21',L=Lbasic;
            case 'Paper 24',L=Lpaper;
            case 'NIM Certificate 34',L=Lnim;
            otherwise
                if ~Lexternal.loaded
                    referenceSetDrop.Value='Basic 21';L=Lbasic;
                    uialert(fig,'Load an external reference-line file first.','External library unavailable');
                else,L=Lexternal;end
        end
        selectedRefRow=0; calPairs=emptyCalPairs(); provisional=emptyInitialModel(); finalModel=emptyFinalModel();calibrationModels=emptyCalibrationModels();refreshModelComparison();
        refreshCalibration(); showCalibrationView([],[]);
    end

    function localWindowChanged(~,~)
        normalizeLocalWindows(); showCalibrationView([],[]);
    end
    function previousLocalSegment(~,~)
        shiftBothWindows(-0.8);
    end
    function nextLocalSegment(~,~)
        shiftBothWindows(0.8);
    end
    function zoomLocalIn(~,~)
        scaleBothWindows(0.65);
    end
    function zoomLocalOut(~,~)
        scaleBothWindows(1.5);
    end
    function shiftReferenceLeft(~,~)
        shiftReferenceWindow(-0.15);
    end
    function shiftReferenceRight(~,~)
        shiftReferenceWindow(0.15);
    end
    function shiftBothWindows(fraction)
        dp=pixelViewEnd.Value-pixelViewStart.Value; dw=wavelengthViewEnd.Value-wavelengthViewStart.Value;
        pixelViewStart.Value=pixelViewStart.Value+fraction*dp; pixelViewEnd.Value=pixelViewEnd.Value+fraction*dp;
        wavelengthViewStart.Value=wavelengthViewStart.Value+fraction*dw; wavelengthViewEnd.Value=wavelengthViewEnd.Value+fraction*dw;
        normalizeLocalWindows();showCalibrationView([],[]);
    end
    function scaleBothWindows(factor)
        cp=mean([pixelViewStart.Value pixelViewEnd.Value]);cw=mean([wavelengthViewStart.Value wavelengthViewEnd.Value]);
        hp=.5*factor*(pixelViewEnd.Value-pixelViewStart.Value);hw=.5*factor*(wavelengthViewEnd.Value-wavelengthViewStart.Value);
        pixelViewStart.Value=cp-hp;pixelViewEnd.Value=cp+hp;wavelengthViewStart.Value=cw-hw;wavelengthViewEnd.Value=cw+hw;
        normalizeLocalWindows();showCalibrationView([],[]);
    end
    function shiftReferenceWindow(fraction)
        dw=wavelengthViewEnd.Value-wavelengthViewStart.Value;
        wavelengthViewStart.Value=wavelengthViewStart.Value+fraction*dw;wavelengthViewEnd.Value=wavelengthViewEnd.Value+fraction*dw;
        normalizeLocalWindows();showCalibrationView([],[]);
    end
    function normalizeLocalWindows
        if pixelViewEnd.Value<=pixelViewStart.Value,pixelViewEnd.Value=pixelViewStart.Value+1;end
        if wavelengthViewEnd.Value<=wavelengthViewStart.Value,wavelengthViewEnd.Value=wavelengthViewStart.Value+1;end
        if ~isempty(D.pixel)
            span=max(D.pixel)-min(D.pixel);if span<=0,span=1;end
            width=min(pixelViewEnd.Value-pixelViewStart.Value,span);
            pixelViewStart.Value=max(min(D.pixel),min(pixelViewStart.Value,max(D.pixel)-width));pixelViewEnd.Value=pixelViewStart.Value+width;
        end
    end

    function ysel=selectedPeakSpectrum
        ysel=zeros(size(D.corrected));
        for ii=1:numel(peakDataset)
            wp=peakDataset(ii).WindowPixel;
            if isempty(wp), continue; end
            use=D.pixel>=min(wp)&D.pixel<=max(wp);
            ysel(use)=D.corrected(use);
        end
    end

    function showCalibrationView(~,~)
        plotTabs.SelectedTab=tabMatchingPlots;
        cla(axMatchMeasured,'reset');styleAxes(axMatchMeasured,C);
        cla(axMatchReference,'reset');styleAxes(axMatchReference,C);
        if isempty(D.raw)
            title(axMatchMeasured,'Load a measured spectrum first'); return;
        end
        normalizeLocalWindows();
        localPeakMask=[peaks.Pixel]>=pixelViewStart.Value & [peaks.Pixel]<=pixelViewEnd.Value & ~strcmp({peaks.Status},'Excluded');
        localPeakItems={peaks(localPeakMask).ID};
        if isempty(localPeakItems)
            calPeakDrop.Items={'(none)'};calPeakDrop.Value='(none)';
        else
            oldPeak=calPeakDrop.Value;calPeakDrop.Items=localPeakItems;
            if any(strcmp(localPeakItems,oldPeak)),calPeakDrop.Value=oldPeak;else,calPeakDrop.Value=localPeakItems{1};end
        end
        ysel=selectedPeakSpectrum();ym=log10(1+max(ysel,0));if max(ym)>0,ym=ym/max(ym);end
        plot(axMatchMeasured,D.pixel,ym,'-','Color',C.blue,'LineWidth',1.1);hold(axMatchMeasured,'on');
        for jj=find(localPeakMask)
            if showMatchingCheck.Value
                plot(axMatchMeasured,peaks(jj).Pixel,ym(peaks(jj).Index),'v','Color',C.green,'MarkerFaceColor',C.green,'MarkerSize',5);
                text(axMatchMeasured,peaks(jj).Pixel,ym(peaks(jj).Index),peaks(jj).ID,'FontSize',10,'FontWeight','bold','Color',C.green,'VerticalAlignment','bottom');
            end
        end
        hold(axMatchMeasured,'off');grid(axMatchMeasured,'on');xlim(axMatchMeasured,[pixelViewStart.Value pixelViewEnd.Value]);
        xlabel(axMatchMeasured,'Natural pixel coordinate');ylabel(axMatchMeasured,'Selected-peak log-normalized signal');title(axMatchMeasured,'Calibration peak dataset - measured subrange');
        [lineStatus,~]=referenceStatuses();
        active=find(L.effective>=wavelengthViewStart.Value & L.effective<=wavelengthViewEnd.Value & L.enabled(:));
        hold(axMatchReference,'on');
        hr=referenceDisplayHeights([]);
        for jj=1:numel(active)
            ii=active(jj); xr=L.effective(ii);col=C.orange;lw=1.1;
            if strcmp(lineStatus{ii},'Unresolved'),col=C.gray;elseif strcmp(lineStatus{ii},'Marginal'),col=[.85 .62 .12];end
            if ii==selectedRefRow,col=C.red;lw=2;end
            plot(axMatchReference,[xr xr],[0 hr(ii)],'-','Color',col,'LineWidth',lw,'HandleVisibility','off');
            if showMatchingCheck.Value
                text(axMatchReference,xr,hr(ii),sprintf(' %.3f',xr),'Rotation',75,'FontSize',10,'FontWeight','bold','Color',col,'VerticalAlignment','bottom');
            end
        end
        for jj=1:numel(calPairs)
            if calPairs(jj).ReferenceIndex<=0,continue;end
            xx=calPairs(jj).ReferenceWavelength;
            if showMatchingCheck.Value
                plot(axMatchReference,xx,1.03,'v','Color',C.green,'MarkerFaceColor',C.green,'MarkerSize',6,'HandleVisibility','off');
                text(axMatchReference,xx,1.03,calPairs(jj).PeakID,'FontSize',10,'FontWeight','bold','Color',C.green,'VerticalAlignment','bottom','HorizontalAlignment','center');
            end
        end
        hold(axMatchReference,'off');grid(axMatchReference,'on');xlabel(axMatchReference,'Reference wavelength (nm)');ylabel(axMatchReference,'Log-normalized reference intensity');
        ylim(axMatchReference,[0 1.18]);xlim(axMatchReference,[wavelengthViewStart.Value wavelengthViewEnd.Value]);
        dp=pixelViewEnd.Value-pixelViewStart.Value;dw=wavelengthViewEnd.Value-wavelengthViewStart.Value;
        localA=dw/dp;localB=wavelengthViewStart.Value-localA*pixelViewStart.Value;
        title(axMatchReference,sprintf('Reference template | local guide: lambda = %.7g pixel %+.7g | %s',localA,localB,shortName(L.source)),'Interpreter','none');
        if provisional.valid
            equationLabel.Text=sprintf('Local guide a=%.7g, b=%+.7g | fitted initial degree %d, RMS %.5g nm',localA,localB,provisional.Degree,initialRMS());
        else
            equationLabel.Text=sprintf('Local linear guide: lambda = %.7g pixel %+.7g',localA,localB);
        end
    end

    function model=modelForDisplay
        if provisional.valid,model=provisional;return;end
        model=emptyInitialModel();
        if isempty(D.pixel),return;end
        a=(wavelengthViewEnd.Value-wavelengthViewStart.Value)/max(eps,pixelViewEnd.Value-pixelViewStart.Value); b=wavelengthViewStart.Value-a*pixelViewStart.Value;
        model.valid=true;model.Degree=1;model.Coefficients=[a b];model.Mu=[0 1];model.a=a;model.b=b;
    end

    function wl=evaluateWavelengthModel(model,pixel)
        if isempty(model.Coefficients),wl=nan(size(pixel));else,wl=polyval(model.Coefficients,pixel,[],model.Mu);end
    end

    function model=attachPixelCoordinateMetadata(model)
        model.PixelCoordinateMode=currentPixelCoordinateMode();
        model.PixelFirst=minOrNaN(D.pixel);
        model.PixelLast=maxOrNaN(D.pixel);
        model.PixelCount=numel(D.pixel);
        model.CalibrationPixelFirst=minOrNaN(model.Pixel);
        model.CalibrationPixelLast=maxOrNaN(model.Pixel);
    end

    function [mode,domain,calibrationDomain]=modelCoordinateLabels(model)
        mode='Legacy / unspecified';domain='unspecified';calibrationDomain='unspecified';
        if isfield(model,'PixelCoordinateMode')&&~isempty(model.PixelCoordinateMode)
            mode=char(string(model.PixelCoordinateMode));
        end
        if isfield(model,'PixelFirst')&&isfield(model,'PixelLast')&& ...
                isfinite(model.PixelFirst)&&isfinite(model.PixelLast)
            domain=sprintf('%.12g..%.12g',model.PixelFirst,model.PixelLast);
        end
        if isfield(model,'CalibrationPixelFirst')&&isfield(model,'CalibrationPixelLast')&& ...
                isfinite(model.CalibrationPixelFirst)&&isfinite(model.CalibrationPixelLast)
            calibrationDomain=sprintf('%.12g..%.12g',model.CalibrationPixelFirst,model.CalibrationPixelLast);
        elseif isfield(model,'Pixel')&&~isempty(model.Pixel)
            calibrationDomain=sprintf('%.12g..%.12g',min(model.Pixel),max(model.Pixel));
        end
    end

    function mode=currentPixelCoordinateMode
        mode=pixelMode.Value;
        if isfield(D,'PixelCoordinateMode')&&~isempty(D.PixelCoordinateMode)
            mode=char(string(D.PixelCoordinateMode));
        end
    end

    function [compatible,message]=modelPixelCoordinatesCompatible(model)
        compatible=true;message='';
        if ~isfield(model,'PixelCoordinateMode')||isempty(model.PixelCoordinateMode)
            return; % V0.6.0 and earlier models remain loadable as legacy models.
        end
        modelMode=char(string(model.PixelCoordinateMode));dataMode=currentPixelCoordinateMode();
        if ~strcmp(modelMode,dataMode)
            compatible=false;
            message=sprintf(['Model pixel sequence is "%s", but the loaded spectrum uses "%s". ' ...
                'Select or load data in the matching sequence; coefficients cannot be silently shifted.'],modelMode,dataMode);
        end
    end

    function pixel=invertWavelengthModel(model,wavelength)
        pixel=nan(size(wavelength)); if isempty(D.pixel)||isempty(model.Coefficients),return;end
        pg=linspace(min(D.pixel),max(D.pixel),max(4000,4*numel(D.pixel))); wg=evaluateWavelengthModel(model,pg);
        good=isfinite(wg);pg=pg(good);wg=wg(good);[wg,ia]=unique(wg,'stable');pg=pg(ia);
        if numel(wg)<2||any(diff(wg)<=0),return;end
        pixel=interp1(wg,pg,wavelength,'linear',NaN);
    end

    function h=referenceDisplayHeights(targetY)
        if isempty(L.intensity), h=[]; return; end
        z=max(L.intensity,0); z=log10(1+z); mx=max(z); if mx>0,z=z/mx;end
        if nargin>0 && ~isempty(targetY)
            amp=max(targetY); if amp<=0,amp=max(D.corrected);end; if amp<=0,amp=1;end
            h=z*amp;
        else
            h=z;
        end
    end

    function addManualPair(~,~)
        confirmedMask=false(1,numel(peakDataset));
        if ~isempty(peakDataset),confirmedMask=[peakDataset.Confirmed];end
        if ~any(confirmedMask), uialert(fig,'Confirm peak parameters before wavelength matching.','No confirmed peaks'); return; end
        if ~L.loaded || selectedRefRow<1, uialert(fig,'Select one row in the reference-line table.','No reference selected'); return; end
        if ~L.enabled(selectedRefRow),uialert(fig,'This reference line is disabled in the current selection mode. Enable it first.','Reference line disabled');return;end
        id=calPeakDrop.Value; k=find(strcmp({peakDataset.PeakID},id) & confirmedMask,1);
        if ~isempty(k)
            peakIndex=peakDataset(k).PeakIndex; peakPixel=peakDataset(k).Pixel;
        else
            uialert(fig,'The selected peak is not confirmed. Reconfirm it before matching.','Unconfirmed peak'); return;
        end
        calPairs=removePairByPeakOrReference(calPairs,id,selectedRefRow);
        q=makeCalPair(id,peakIndex,peakPixel,selectedRefRow,L.effective(selectedRefRow),L.order(selectedRefRow),'Manual',true,'Manual locked');
        calPairs(end+1)=q; selectedPairRow=numel(calPairs);
        archiveCurrentPaperCalibrationPairs();
        if sum([calPairs.ReferenceIndex]>0)>=2,buildInitialCalibration([],[]);else,refreshCalibration();showCalibrationView([],[]);end
        topStatus.Text=sprintf('%s paired with %.8g nm',id,L.effective(selectedRefRow));
    end

    function removePair(~,~)
        if selectedPairRow<1 || selectedPairRow>numel(calPairs), return; end
        archiveCurrentPaperCalibrationPairs();
        calPairs(selectedPairRow)=[]; selectedPairRow=0;
        if sum([calPairs.ReferenceIndex]>0)>=2,buildInitialCalibration([],[]);else,provisional=emptyInitialModel();refreshCalibration();showCalibrationView([],[]);end
    end

    function togglePairLock(~,~)
        if selectedPairRow<1 || selectedPairRow>numel(calPairs), return; end
        calPairs(selectedPairRow).Locked=~calPairs(selectedPairRow).Locked;
        if calPairs(selectedPairRow).Locked, calPairs(selectedPairRow).Status='Locked'; else, calPairs(selectedPairRow).Status='Unlocked'; end
        refreshCalibration();
    end

    function selectPairRow(~,event)
        if isempty(event.Indices), selectedPairRow=0; return; end
        selectedPairRow=event.Indices(1);
        if selectedPairRow<=numel(calPairs) && calPairs(selectedPairRow).ReferenceIndex>0
            selectedRefRow=calPairs(selectedPairRow).ReferenceIndex;
            calPeakDrop.Value=calPairs(selectedPairRow).PeakID; try,refTable.Selection=[selectedRefRow 1];catch,end
            showCalibrationView([],[]);
        end
    end

    function buildInitialCalibration(~,~)
        valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
        valid=valid(arrayfun(@(q)isPeakConfirmed(calPairs(q).PeakID),valid));
        if numel(valid)<2, uialert(fig,'At least two confirmed peak-reference pairs are required.','Insufficient pairs'); return; end
        px=[calPairs(valid).DetectionPixel].'; wl=[calPairs(valid).ReferenceWavelength].';
        if numel(unique(px))<2, uialert(fig,'Calibration pairs require at least two different pixel positions.','Invalid pairs'); return; end
        deg=min(3,numel(valid)-1); [c,~,mu]=polyfit(px,wl,deg);
        provisional=emptyInitialModel();provisional.valid=true;provisional.Degree=deg;provisional.Coefficients=c;provisional.Mu=mu;
        if deg==1
            % Convert normalized-coordinate coefficients to conventional a,b for export compatibility.
            provisional.a=c(1)/mu(2); provisional.b=c(2)-c(1)*mu(1)/mu(2);
        end
        refreshCalibration(); showCalibrationView([],[]); topStatus.Text=sprintf('Initial degree-%d polynomial updated from %d anchors',deg,numel(valid));
    end

    function autoMatchPeaks(~,~)
        if ~provisional.valid, uialert(fig,'Confirm at least two anchor pairs and update the polynomial first.','No initial model'); return; end
        if ~L.loaded, return; end
        % Preserve locked anchors, then globally align the remaining ordered
        % peak and wavelength sequences. This avoids greedy nearest-neighbour
        % choices consuming a line needed by the next measured peak.
        if ~isempty(calPairs), calPairs=calPairs([calPairs.Locked]); end
        if strcmp(sourceDrop.Value,'All detected peaks')
            ids={peaks.ID}; idx=[peaks.Index]; px=[peaks.Pixel]; ok=~strcmp({peaks.Status},'Excluded');
            ids=ids(ok); idx=idx(ok); px=px(ok);
        else
            ok=[peakDataset.Confirmed];
            ids={peakDataset(ok).PeakID}; idx=[peakDataset(ok).PeakIndex]; px=[peakDataset(ok).Pixel];
        end
        usedRef=[calPairs.ReferenceIndex]; usedPeak={calPairs.PeakID}; tol=max(matchTolerance.Value,eps);
        keep=~ismember(ids,usedPeak);ids=ids(keep);idx=idx(keep);px=px(keep);
        [px,ord]=sort(px);ids=ids(ord);idx=idx(ord);
        refPool=setdiff(usableReferenceIndices(),usedRef,'stable');
        [~,ord]=sort(L.effective(refPool));refPool=refPool(ord);
        predicted=evaluateWavelengthModel(provisional,px);
        matchRef=orderedSequenceMatch(predicted,L.effective(refPool),refPool,tol);
        matched=0; high=0;
        for ii=1:numel(ids)
            r=matchRef(ii);
            if r==0
                q=makeCalPair(ids{ii},idx(ii),px(ii),0,NaN,NaN,'Auto global',false,'Unmatched',0);
            else
                d=abs(L.effective(r)-predicted(ii)); allDist=sort(abs(L.effective(refPool)-predicted(ii)));
                base=max(0,1-d/tol); separation=1;
                if numel(allDist)>1,separation=min(1,max(0,(allDist(2)-allDist(1))/tol));end
                conf=0.7*base+0.3*separation;
                if conf>=confidenceThreshold.Value,st='High confidence';high=high+1;
                elseif conf>=0.4,st='Review';else,st='Low confidence';end
                q=makeCalPair(ids{ii},idx(ii),px(ii),r,L.effective(r),L.order(r),'Auto global',false,st,conf);matched=matched+1;
            end
            calPairs(end+1)=q; %#ok<AGROW>
        end
        refreshCalibration(); showCalibrationView([],[]);
        topStatus.Text=sprintf('Auto extension: %d matched, %d high-confidence, %d unmatched',matched,high,numel(ids)-matched);
    end

    function lockHighConfidencePairs(~,~)
        if isempty(calPairs),return;end
        n=0;
        for ii=1:numel(calPairs)
            if calPairs(ii).ReferenceIndex>0 && startsWith(calPairs(ii).Mode,'Auto') && calPairs(ii).Confidence>=confidenceThreshold.Value
                calPairs(ii).Locked=true;calPairs(ii).Status='Auto locked';n=n+1;
            end
        end
        refreshCalibration();topStatus.Text=sprintf('%d high-confidence automatic pairs locked',n);
    end

    function exportCalibration(~,~)
        if isempty(calPairs), uialert(fig,'No calibration pairs to export.','Nothing to export'); return; end
        [fn,pn]=uiputfile('WCC4SM_initial_calibration.mat','Export initial calibration'); if isequal(fn,0),return;end
        CalibrationPairs=calPairs; InitialCalibration=provisional; FinalCalibration=finalModel; CalibrationModels=calibrationModels;ReferenceLines=L; PeakDataset=peakDataset; Spectrum=D; %#ok<NASGU>
        save(fullfile(pn,fn),'CalibrationPairs','InitialCalibration','FinalCalibration','CalibrationModels','ReferenceLines','PeakDataset','Spectrum');
        T=calibrationPairTable(); [~,stem]=fileparts(fn); writetable(T,fullfile(pn,[stem '.csv'])); topStatus.Text='Initial calibration exported';
    end

    %% FINAL CALIBRATION MODEL
    function fitFinalCalibration(~,~)
        valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
        if isempty(valid),uialert(fig,'No matched calibration pairs are available.','No calibration points');return;end
        ids={}; xpos=[]; wl=[]; unavailableIDs={};
        for jj=valid
            xp=pairPeakPosition(calPairs(jj),positionDrop.Value);
            if isfinite(xp)
                ids{end+1}=calPairs(jj).PeakID; xpos(end+1)=xp; wl(end+1)=calPairs(jj).ReferenceWavelength; %#ok<AGROW>
            else
                unavailableIDs{end+1}=calPairs(jj).PeakID; %#ok<AGROW>
            end
        end
        deg=degreeSpin.Value;
        if numel(xpos)<deg+2
            uialert(fig,sprintf('Degree %d fitting requires at least %d valid points in this program. Current valid points: %d.',deg,deg+2,numel(xpos)),'Insufficient calibration points');return;
        end
        finalModel=wc4sm_fit_calibration(xpos(:),wl(:),deg,D.pixel, ...
            positionDrop.Value,ids(:));
        finalModel=attachPixelCoordinateMetadata(finalModel);
        xpos=finalModel.Pixel;wl=finalModel.ReferenceWavelength;ids=finalModel.PeakID;
        modelItem=struct('ModelID',sprintf('M%03d',numel(calibrationModels)+1),'CreatedAt',datetime('now'), ...
            'PairCount',numel(xpos),'PositionMethod',positionDrop.Value,'Degree',deg,'PairIDs',{ids},'Model',finalModel,'Visible',true);
        calibrationModels(end+1)=modelItem;selectedModelRow=numel(calibrationModels);refreshModelComparison();
        try,modelComparisonTable.Selection=[selectedModelRow 1];catch,end
        drawModelComparison([],[]);refreshValidationView([],[]);
        [coordinateMode,coordinateDomain,calibrationDomain]=modelCoordinateLabels(finalModel);
        fitResultLabel.Text=sprintf('%s | %s | pixels %s | fit domain %s | degree %d | N=%d | RMS %.5g nm | max|r| %.5g nm', ...
            positionDrop.Value,coordinateMode,coordinateDomain,calibrationDomain,deg,numel(xpos),finalModel.RMS,finalModel.MaxAbsResidual);
        equationDisplay.Value={sprintf('%s | %s',modelItem.ModelID,finalModel.Equation), ...
            sprintf('Pixel mode: %s | data domain: %s | calibration domain: %s',coordinateMode,coordinateDomain,calibrationDomain), ...
            sprintf('MATLAB normalized form: z=(pixel-%.12g)/%.12g',finalModel.Mu(1),finalModel.Mu(2)), ...
            sprintf('Coefficients(z): %s',mat2str(finalModel.Coefficients,12))};
        if isempty(unavailableIDs)
            topStatus.Text='Final calibration model fitted and leave-one-out validation completed';
        else
            topStatus.Text=sprintf('Model fitted; %d position-only/method-incompatible peaks excluded',numel(unavailableIDs));
            fitResultLabel.Text=[fitResultLabel.Text sprintf(' | excluded: %s',strjoin(unavailableIDs,', '))];
        end
        drawEmbeddedResults();plotTabs.SelectedTab=tabResults;
    end

    function xp=pairPeakPosition(pair,method)
        xp=NaN; k=find(strcmp({peakDataset.PeakID},pair.PeakID) & [peakDataset.Confirmed],1);
        rr=[]; if ~isempty(k),rr=peakDataset(k).AnalysisResult;end
        if isempty(rr),return;end
        positionOnly=~isempty(rr) && isfield(rr,'CalibrationUsability') && ...
            strcmp(rr.CalibrationUsability,'PositionOnly');
        switch method
            case 'Direct peak'
                if ~isempty(rr)&&isfield(rr,'DirectPeakX'),xp=rr.DirectPeakX;else,xp=pair.DetectionPixel;end
            case 'Interpolated peak'
                if ~isempty(rr),xp=rr.InterpolatedPeakX;end
            case 'FWHM center'
                if ~isempty(rr),xp=rr.CenterX;end
            case 'Centroid'
                if ~isempty(rr),xp=rr.CentroidX;end
            case 'Gaussian fit'
                if ~isempty(rr)&&~positionOnly,xp=gaussianPeakPosition(rr);end
        end
    end

    function tf=isPeakConfirmed(id)
        k=find(strcmp({peakDataset.PeakID},id),1);
        tf=~isempty(k) && peakDataset(k).Confirmed;
    end

    function xp=gaussianPeakPosition(rr)
        x=rr.WindowX(:); y=rr.NetY(:); good=isfinite(x)&isfinite(y); x=x(good);y=y(good); xp=NaN;
        if numel(x)<5||max(y)<=min(y),return;end
        amp=max(y)-min(y); mu0=rr.InterpolatedPeakX; sig0=max(rr.FWHM/2.35482,median(diff(x)));
        p0=[amp mu0 log(max(sig0,eps)) min(y)];
        objective=@(p)sum((y-(p(1)*exp(-0.5*((x-p(2))/exp(p(3))).^2)+p(4))).^2);
        try
            p=fminsearch(objective,p0,optimset('Display','off','MaxIter',1000,'MaxFunEvals',3000));
            if p(2)>=min(x)&&p(2)<=max(x)&&isfinite(p(2)),xp=p(2);end
        catch
            xp=NaN;
        end
    end

    function refreshValidationView(~,~)
        cla(axLOO,'reset');cla(axInfluence,'reset');styleAxes(axLOO,C);styleAxes(axInfluence,C);selectedValidationRow=0;
        if ~finalModel.valid || isempty(finalModel.LOOResidual)
            validationTable.Data=cell(0,10);validationSummary.Text='Fit a model to run validation';
            title(axLOO,'No validated model');title(axInfluence,'No validated model');return;
        end
        n=numel(finalModel.Pixel);loo=finalModel.LOOResidual(:);infl=finalModel.DeletionMaxCurveChange(:);wl=finalModel.ReferenceWavelength(:);
        looLimit=robustUpperLimit(abs(loo));influenceLimit=robustUpperLimit(infl);
        dat=cell(n,10);
        for ii=1:n
            id=finalModel.PeakID{ii};fwhm=NaN;ratio=NaN;centroidShift=NaN;
            k=find(strcmp({peaks.ID},id),1);
            if ~isempty(k)&&~isempty(peaks(k).Result)
                rr=peaks(k).Result;fwhm=rr.FWHM;if isfinite(rr.FWHM)&&rr.FWHM~=0,ratio=rr.ERW/rr.FWHM;end
                centroidShift=rr.CentroidX-rr.CenterX;
            end
            flags={};if abs(loo(ii))>looLimit,flags{end+1}='LOO outlier';end %#ok<AGROW>
            if infl(ii)>influenceLimit,flags{end+1}='High influence';end %#ok<AGROW>
            if isfinite(ratio)&&ratio>1.8,flags{end+1}='Broad wings';end %#ok<AGROW>
            if isfinite(centroidShift)&&abs(centroidShift)>0.3,flags{end+1}='Asymmetric';end %#ok<AGROW>
            if isempty(flags),flag='OK';else,flag=strjoin(flags,'; ');end
            dat(ii,:)={id,finalModel.Pixel(ii),wl(ii),finalModel.Residual(ii),loo(ii),infl(ii),fwhm,ratio,centroidShift,flag};
        end
        validationTable.Data=dat;
        yline(axLOO,0,'-','Color',C.gray);hold(axLOO,'on');scatter(axLOO,wl,loo,36,C.red,'filled');
        yline(axLOO,looLimit,'--','Color',C.orange);yline(axLOO,-looLimit,'--','Color',C.orange);hold(axLOO,'off');grid(axLOO,'on');
        xlabel(axLOO,'Reference wavelength (nm)');ylabel(axLOO,'LOO residual (nm)');title(axLOO,sprintf('LOO prediction | RMS %.5g nm | max %.5g nm',finalModel.LOORMS,finalModel.LOOMaxAbs));
        bar(axInfluence,wl,infl,'FaceColor',C.cyanDark);hold(axInfluence,'on');yline(axInfluence,influenceLimit,'--','Color',C.orange);hold(axInfluence,'off');grid(axInfluence,'on');
        xlabel(axInfluence,'Reference wavelength (nm)');ylabel(axInfluence,'Max curve change (nm)');title(axInfluence,sprintf('Deletion influence | max %.5g nm',finalModel.MaxDeletionInfluence));
        validationSummary.Text=sprintf('N=%d | fit RMS %.4g | LOO RMS %.4g | max influence %.4g nm',n,finalModel.RMS,finalModel.LOORMS,finalModel.MaxDeletionInfluence);
    end

    function runPositionCrossValidation(~,~)
        if positionCrossBusy,return;end
        positionCrossBusy=true;
        positionCrossControls={runPositionCrossBtn,positionCrossDegree,positionCrossValidationMode, ...
            positionCrossPoolMode,positionCrossTrainingSource,positionCrossMetric,positionCrossResidualView,exportPositionCrossBtn};
        for controlIndex=1:numel(positionCrossControls)
            if isvalid(positionCrossControls{controlIndex}),positionCrossControls{controlIndex}.Enable='off';end
        end
        runPositionCrossBtn.Text='Calculating ...';
        progressDialog=[];
        try
            progressDialog=uiprogressdlg(fig,'Title','Peak-position cross validation', ...
                'Message','Fitting calibration models and evaluating the mismatch matrix ...', ...
                'Indeterminate','on','Cancelable','off');
        catch
            progressDialog=[];
        end
        runCleanup=onCleanup(@()finishPositionCrossRun(progressDialog,positionCrossControls)); %#ok<NASGU>
        try
            methods={'Direct peak','Interpolated peak','FWHM center','Centroid'};
            valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));
            if isempty(valid),error('WCC4SM:CrossPositionNoPairs','No matched calibration pairs are available.');end
            positions=nan(numel(valid),numel(methods));wavelength=nan(numel(valid),1);peakIDs=cell(numel(valid),1);
            for i=1:numel(valid)
                q=calPairs(valid(i));wavelength(i)=q.ReferenceWavelength;peakIDs{i}=q.PeakID;
                for j=1:numel(methods),positions(i,j)=pairPeakPosition(q,methods{j});end
            end
            [trainingMask,trainingLabel,trainingPeakIDs]=positionCrossTrainingSelection(peakIDs);
            options=struct('ValidationMode',positionCrossValidationMode.Value,'PoolMode',positionCrossPoolMode.Value, ...
                'TrainingMask',trainingMask,'EvaluationMask',true(numel(peakIDs),1), ...
                'TrainingSetLabel',trainingLabel,'EvaluationSetLabel','All matched pairs');
            positionCrossStatus.Text='Computing cross-validation matrix ...';positionCrossStatus.Tooltip=positionCrossStatus.Text;drawnow limitrate;
            positionCrossResult=wc4sm_cross_validate_peak_positions(positions,wavelength,methods,positionCrossDegree.Value,options);
            if ~any(strcmp({positionCrossResult.Cells.Status},'Available')),error('WCC4SM:CrossPositionInsufficientPoints','No peak-position combination has enough points for the selected degree and validation mode.');end
            positionCrossResult.PeakIDs=peakIDs;positionCrossResult.TrainingPeakIDs=trainingPeakIDs;
            positionCrossResult.EvaluationPeakIDs=peakIDs;selectedPositionCrossRow=1;selectedPositionCrossColumn=1;
            drawPositionCrossValidation();
            validationTabs.SelectedTab=positionCrossValidationTab;
            positionCrossStatus.Text=sprintf('%s | %s | d%d | train %s | eval %s | %d fits | %.2f s.', ...
                positionCrossResult.ValidationMode,positionCrossResult.PoolMode,positionCrossResult.Degree, ...
                positionCrossCountText(positionCrossResult.NTrain),positionCrossCountText(positionCrossResult.N), ...
                positionCrossResult.CalibrationFitCount,positionCrossResult.ElapsedSeconds);
            positionCrossTrainingSummary.Text=sprintf('Training: %s | Evaluation: %s',positionCrossResult.TrainingSetLabel,positionCrossResult.EvaluationSetLabel);
            positionCrossStatus.Tooltip=positionCrossStatus.Text;positionCrossTrainingSummary.Tooltip=positionCrossTrainingSummary.Text;
        catch ME
            if ~isempty(progressDialog)&&isvalid(progressDialog),delete(progressDialog);end
            if isvalid(positionCrossStatus),positionCrossStatus.Text=['Cross validation failed: ' ME.message];positionCrossStatus.Tooltip=positionCrossStatus.Text;end
            uialert(fig,ME.message,'Peak-position cross validation failed');
        end
    end

    function [mask,label,ids]=positionCrossTrainingSelection(availablePeakIDs)
        source=positionCrossTrainingSource.Value;
        switch source
            case 'Current final model'
                if ~isstruct(finalModel)||~isfield(finalModel,'valid')||~finalModel.valid||~isfield(finalModel,'PeakID')||isempty(finalModel.PeakID)
                    error('WCC4SM:CrossPositionNoFinalModel','Fit or load a current final calibration model first.');
                end
                ids=cellstr(string(finalModel.PeakID(:)));label=sprintf('Current final model (%d IDs)',numel(ids));
            case 'Selected comparison model'
                if selectedModelRow<1||selectedModelRow>numel(calibrationModels)
                    error('WCC4SM:CrossPositionNoComparisonModel','Select a row in Model Comparison first.');
                end
                item=calibrationModels(selectedModelRow);ids=cellstr(string(item.PairIDs(:)));
                label=sprintf('%s selected comparison model (%d IDs)',item.ModelID,numel(ids));
            case 'Selected Set Design candidate'
                q=selectedSetDesignItem();
                if isempty(fieldnames(subsetDesignProfile))||~isfield(subsetDesignProfile,'PeakIDs')||numel(q.Mask)~=numel(subsetDesignProfile.PeakIDs)
                    error('WCC4SM:CrossPositionInvalidSetDesign','The selected Set Design candidate has no compatible Peak ID list.');
                end
                ids=cellstr(string(subsetDesignProfile.PeakIDs(logical(q.Mask(:)))));
                label=sprintf('%s Set Design candidate (%d IDs)',q.CandidateID,numel(ids));
            otherwise
                ids=cellstr(string(availablePeakIDs(:)));label=sprintf('All matched pairs (%d IDs)',numel(ids));
        end
        requestedCount=numel(unique(string(ids)));
        mask=ismember(string(availablePeakIDs(:)),string(ids(:)));
        ids=cellstr(string(availablePeakIDs(mask)));
        if ~any(mask),error('WCC4SM:CrossPositionEmptyTrainingSet','The selected training set has no Peak IDs in the current matched-pair pool.');end
        if sum(mask)<requestedCount
            label=sprintf('%s | %d matched',label,sum(mask));
        end
    end

    function textValue=positionCrossCountText(values)
        values=values(isfinite(values));
        if isempty(values),textValue='N=0';return;end
        lo=min(values);hi=max(values);
        if lo==hi,textValue=sprintf('N=%d',round(lo));else,textValue=sprintf('N=%d..%d',round(lo),round(hi));end
    end

    function finishPositionCrossRun(progressDialog,controls)
        positionCrossBusy=false;
        for controlIndex=1:numel(controls)
            if isvalid(controls{controlIndex}),controls{controlIndex}.Enable='on';end
        end
        if isvalid(runPositionCrossBtn),runPositionCrossBtn.Text='Run cross validation';end
        if ~isempty(progressDialog)&&isvalid(progressDialog),delete(progressDialog);end
    end

    function positionCrossDisplayChanged(~,~)
        drawPositionCrossValidation();
    end

    function positionCrossHistogramChanged(~,~)
        if strcmp(positionCrossHistRangeMode.Value,'Manual')&&positionCrossHistXMax.Value<=positionCrossHistXMin.Value
            positionCrossHistXMax.Value=positionCrossHistXMin.Value+max(1e-6,abs(positionCrossHistXMin.Value)*0.01);
        end
        drawPositionCrossValidation();
    end

    function selectPositionCrossTableCell(~,event)
        if isempty(event.Indices),return;end
        selectedPositionCrossRow=event.Indices(end,1);selectedPositionCrossColumn=event.Indices(end,2);
        drawPositionCrossValidation();
    end

    function selectPositionCrossHeatmapCell(~,~)
        cp=positionCrossHeatmapAxes.CurrentPoint;column=round(cp(1,1));row=round(cp(1,2));
        if row<1||column<1||row>4||column>4,return;end
        selectedPositionCrossRow=row;selectedPositionCrossColumn=column;
        try,positionCrossTable.Selection=[row column];catch,end
        drawPositionCrossValidation();
    end

    function values=positionCrossMetricValues
        if isempty(fieldnames(positionCrossResult)),values=[];return;end
        values=positionCrossResult.(positionCrossMetric.Value);
    end

    function drawPositionCrossValidation
        cla(positionCrossHeatmapAxes,'reset');styleAxes(positionCrossHeatmapAxes,C);
        cla(positionCrossResidualAxes,'reset');styleAxes(positionCrossResidualAxes,C);
        cla(positionCrossHistogramAxes,'reset');styleAxes(positionCrossHistogramAxes,C);
        if isempty(fieldnames(positionCrossResult))||~isfield(positionCrossResult,'Cells')
            positionCrossTable.Data=cell(4,4);positionCrossSelectionLabel.Text='No selected result.';
            title(positionCrossHeatmapAxes,'Run cross validation');title(positionCrossResidualAxes,'No cross-validation residuals');title(positionCrossHistogramAxes,'No selected residuals');clearPositionCrossOverviews();return;
        end
        methods=positionCrossResult.Methods;values=positionCrossMetricValues();
        if isfield(positionCrossResult,'TrainingSetLabel'),trainingLabel=positionCrossResult.TrainingSetLabel;else,trainingLabel='All matched pairs (legacy result)';end
        if isfield(positionCrossResult,'EvaluationSetLabel'),evaluationLabel=positionCrossResult.EvaluationSetLabel;else,evaluationLabel='All matched pairs (legacy result)';end
        positionCrossTrainingSummary.Text=sprintf('Training: %s | Evaluation: %s',trainingLabel,evaluationLabel);
        positionCrossTrainingSummary.Tooltip=positionCrossTrainingSummary.Text;
        selectedPositionCrossRow=min(max(1,selectedPositionCrossRow),numel(methods));
        selectedPositionCrossColumn=min(max(1,selectedPositionCrossColumn),numel(methods));
        drawPositionCrossOverviews(methods);
        tableNames=strrep(methods,' peak','');
        positionCrossTable.ColumnName=tableNames;positionCrossTable.RowName=tableNames;positionCrossTable.Data=num2cell(values);
        h=imagesc(positionCrossHeatmapAxes,values);h.AlphaData=isfinite(values);h.ButtonDownFcn=@selectPositionCrossHeatmapCell;
        positionCrossHeatmapAxes.YDir='normal';positionCrossHeatmapAxes.XTick=1:numel(methods);positionCrossHeatmapAxes.YTick=1:numel(methods);
        positionCrossHeatmapAxes.XTickLabel=methods;positionCrossHeatmapAxes.YTickLabel=methods;positionCrossHeatmapAxes.XTickLabelRotation=18;
        xlabel(positionCrossHeatmapAxes,'Application peak position');ylabel(positionCrossHeatmapAxes,'Calibration peak position');
        title(positionCrossHeatmapAxes,sprintf('%s mismatch matrix | %s',positionCrossMetric.Value,positionCrossResult.ValidationMode));
        colormap(positionCrossHeatmapAxes,parula);colorbar(positionCrossHeatmapAxes);grid(positionCrossHeatmapAxes,'off');
        finiteValues=values(isfinite(values));
        if strcmp(positionCrossMetric.Value,'Bias')&&~isempty(finiteValues)
            lim=max(abs(finiteValues));if lim<=0,lim=1e-12;end;caxis(positionCrossHeatmapAxes,[-lim lim]);
        end
        hold(positionCrossHeatmapAxes,'on');rectangle('Parent',positionCrossHeatmapAxes,'Position',[selectedPositionCrossColumn-.5 selectedPositionCrossRow-.5 1 1],'EdgeColor',C.red,'LineWidth',2,'HitTest','off');hold(positionCrossHeatmapAxes,'off');

        colors=lines(numel(methods));hold(positionCrossResidualAxes,'on');
        switch positionCrossResidualView.Value
            case 'Selected calibration row'
                for b=1:numel(methods),addPositionCrossResidualSeries(selectedPositionCrossRow,b,colors(b,:),sprintf('%s -> %s',methods{selectedPositionCrossRow},methods{b}));end
            case 'Diagonal comparison'
                for a=1:numel(methods),addPositionCrossResidualSeries(a,a,colors(a,:),sprintf('%s matched',methods{a}));end
            otherwise
                addPositionCrossResidualSeries(selectedPositionCrossRow,selectedPositionCrossColumn,colors(selectedPositionCrossColumn,:),sprintf('%s -> %s',methods{selectedPositionCrossRow},methods{selectedPositionCrossColumn}));
        end
        yline(positionCrossResidualAxes,0,'-','Color',C.gray,'HandleVisibility','off');hold(positionCrossResidualAxes,'off');grid(positionCrossResidualAxes,'on');
        xlabel(positionCrossResidualAxes,'Reference wavelength (nm)');ylabel(positionCrossResidualAxes,'Reference - fitted (nm)');
        title(positionCrossResidualAxes,[positionCrossResidualView.Value ' residuals'],'Interpreter','none');legend(positionCrossResidualAxes,'Location','best');

        selected=positionCrossResult.Cells(selectedPositionCrossRow,selectedPositionCrossColumn);
        positionCrossSelectionLabel.Text=sprintf('%s -> %s | train N=%d | eval N=%d',selected.TrainMethod,selected.ApplicationMethod,selected.NTrain,selected.N);
        positionCrossSelectionLabel.Tooltip=positionCrossSelectionLabel.Text;
        r=selected.Residual(:);r=r(isfinite(r));
        if isempty(r),title(positionCrossHistogramAxes,'Selected combination is unavailable');return;end
        [lo,hi,nb]=positionCrossHistogramSettings(r);
        histogram(positionCrossHistogramAxes,r,'NumBins',nb,'BinLimits',[lo hi],'FaceColor',C.purple,'FaceAlpha',.72,'EdgeColor','white');
        hold(positionCrossHistogramAxes,'on');xline(positionCrossHistogramAxes,0,'--','Color',C.gray);xline(positionCrossHistogramAxes,selected.Bias,'-','Color',C.red,'LineWidth',1.3);hold(positionCrossHistogramAxes,'off');
        xlim(positionCrossHistogramAxes,[lo hi]);grid(positionCrossHistogramAxes,'on');xlabel(positionCrossHistogramAxes,'Residual (nm)');ylabel(positionCrossHistogramAxes,'Count');
        title(positionCrossHistogramAxes,sprintf('%s -> %s | RMSE %.5g | bias %.5g | STD %.5g nm',selected.TrainMethod,selected.ApplicationMethod,selected.RMSE,selected.Bias,selected.STD),'Interpreter','none');
    end

    function clearPositionCrossOverviews
        overviewAxes=[positionCrossMetricOverviewAxes(:);positionCrossRowResidualAxes(:);positionCrossHistogramOverviewAxes(:)];
        for axesIndex=1:numel(overviewAxes)
            cla(overviewAxes(axesIndex),'reset');styleAxes(overviewAxes(axesIndex),C);
            title(overviewAxes(axesIndex),'Run cross validation');
        end
    end

    function drawPositionCrossOverviews(methods)
        metricNames={'RMSE','STD','Bias','P95','MAX','Slope'};
        shortNames={'Direct','Interp.','FWHM','Centroid'};
        for metricIndex=1:numel(metricNames)
            ax=positionCrossMetricOverviewAxes(metricIndex);cla(ax,'reset');styleAxes(ax,C);
            values=positionCrossResult.(metricNames{metricIndex});
            h=imagesc(ax,values);h.AlphaData=isfinite(values);h.ButtonDownFcn=@selectPositionCrossOverviewCell;
            ax.YDir='normal';ax.XTick=1:numel(methods);ax.YTick=1:numel(methods);
            ax.XTickLabel=shortNames;ax.YTickLabel=shortNames;ax.XTickLabelRotation=18;ax.FontSize=8;
            title(ax,sprintf('%s | %s',metricNames{metricIndex},positionCrossResult.ValidationMode),'Interpreter','none');
            xlabel(ax,'Application');ylabel(ax,'Calibration');colormap(ax,parula);colorbar(ax);grid(ax,'off');
            finiteValues=values(isfinite(values));
            if ~isempty(finiteValues)
                if any(strcmp(metricNames{metricIndex},{'Bias','Slope'}))
                    limit=max(abs(finiteValues));if limit<=0,limit=1e-12;end;caxis(ax,[-limit limit]);
                elseif max(finiteValues)>min(finiteValues)
                    caxis(ax,[min(finiteValues) max(finiteValues)]);
                end
            end
            hold(ax,'on');rectangle('Parent',ax,'Position',[selectedPositionCrossColumn-.5 selectedPositionCrossRow-.5 1 1], ...
                'EdgeColor',C.red,'LineWidth',1.4,'HitTest','off');hold(ax,'off');
        end

        colors=lines(numel(methods));
        for applicationIndex=1:numel(methods)
            ax=positionCrossRowResidualAxes(applicationIndex);cla(ax,'reset');styleAxes(ax,C);
            q=positionCrossResult.Cells(selectedPositionCrossRow,applicationIndex);
            if strcmp(q.Status,'Available')&&~isempty(q.Residual)
                scatter(ax,q.Wavelength,q.Residual,22,colors(applicationIndex,:),'filled');
                hold(ax,'on');yline(ax,0,'-','Color',C.gray);hold(ax,'off');grid(ax,'on');
                title(ax,sprintf('%s -> %s | RMSE %.4g | N=%d',shortNames{selectedPositionCrossRow},shortNames{applicationIndex},q.RMSE,q.N),'Interpreter','none');
            else
                title(ax,sprintf('%s -> %s | unavailable',shortNames{selectedPositionCrossRow},shortNames{applicationIndex}),'Interpreter','none');
            end
            xlabel(ax,'Reference wavelength (nm)');ylabel(ax,'Reference - fitted (nm)');
        end

        allResiduals=[];
        for calibrationIndex=1:numel(methods)
            for applicationIndex=1:numel(methods)
                q=positionCrossResult.Cells(calibrationIndex,applicationIndex);
                if strcmp(q.Status,'Available'),allResiduals=[allResiduals;q.Residual(:)];end %#ok<AGROW>
            end
        end
        [lo,hi,nb]=positionCrossOverviewHistogramSettings(allResiduals);
        for visualRow=1:numel(methods)
            calibrationIndex=numel(methods)-visualRow+1;
            for applicationIndex=1:numel(methods)
                ax=positionCrossHistogramOverviewAxes(visualRow,applicationIndex);cla(ax,'reset');styleAxes(ax,C);ax.FontSize=7;
                q=positionCrossResult.Cells(calibrationIndex,applicationIndex);
                residual=q.Residual(:);residual=residual(isfinite(residual));
                if ~isempty(residual)
                    histogram(ax,residual,'NumBins',nb,'BinLimits',[lo hi],'FaceColor',colors(applicationIndex,:),'FaceAlpha',.72,'EdgeColor','white');
                    hold(ax,'on');xline(ax,0,'--','Color',C.gray);xline(ax,q.Bias,'-','Color',C.red,'LineWidth',1);hold(ax,'off');
                    xlim(ax,[lo hi]);grid(ax,'on');
                    title(ax,sprintf('%s -> %s | R %.3g',shortNames{calibrationIndex},shortNames{applicationIndex},q.RMSE),'Interpreter','none','FontSize',8);
                else
                    title(ax,sprintf('%s -> %s | unavailable',shortNames{calibrationIndex},shortNames{applicationIndex}),'Interpreter','none','FontSize',8);
                end
                if visualRow==numel(methods),xlabel(ax,'Residual (nm)');end
                if applicationIndex==1,ylabel(ax,'Count');end
            end
        end
    end

    function selectPositionCrossOverviewCell(source,~)
        ax=source.Parent;cp=ax.CurrentPoint;column=round(cp(1,1));row=round(cp(1,2));
        if row<1||column<1||row>4||column>4,return;end
        selectedPositionCrossRow=row;selectedPositionCrossColumn=column;
        try,positionCrossTable.Selection=[row column];catch,end
        drawPositionCrossValidation();
    end

    function [lo,hi,nb]=positionCrossOverviewHistogramSettings(residual)
        residual=residual(isfinite(residual));nb=max(1,min(100,round(positionCrossHistBins.Value)));
        if isempty(residual),lo=-1;hi=1;return;end
        mu=mean(residual);sigma=std(residual,1);
        switch positionCrossHistRangeMode.Value
            case 'Manual'
                lo=positionCrossHistXMin.Value;hi=positionCrossHistXMax.Value;
            case 'Symmetric'
                limit=max(abs(residual));if ~isfinite(limit)||limit<=0,limit=1e-6;end;lo=-1.05*limit;hi=1.05*limit;
            case '+/-3 STD'
                limit=3*sigma;if ~isfinite(limit)||limit<=0,limit=max(abs(residual-mu));end
                if ~isfinite(limit)||limit<=0,limit=1e-6;end;lo=-limit;hi=limit;
            otherwise
                lo=min(residual);hi=max(residual);span=hi-lo;if ~isfinite(span)||span<=0,span=max(1e-6,abs(lo)*.02);end
                lo=lo-.05*span;hi=hi+.05*span;
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo,lo=-1e-6;hi=1e-6;end
    end

    function addPositionCrossResidualSeries(a,b,colorValue,label)
        q=positionCrossResult.Cells(a,b);if ~strcmp(q.Status,'Available')||isempty(q.Residual),return;end
        scatter(positionCrossResidualAxes,q.Wavelength,q.Residual,28,colorValue,'filled','DisplayName',label);
    end

    function [lo,hi,nb]=positionCrossHistogramSettings(r)
        nb=max(1,min(100,round(positionCrossHistBins.Value)));mu=mean(r);sigma=std(r,1);
        switch positionCrossHistRangeMode.Value
            case 'Manual'
                lo=positionCrossHistXMin.Value;hi=positionCrossHistXMax.Value;
            case 'Symmetric'
                lim=max(abs(r));if ~isfinite(lim)||lim<=0,lim=1e-6;end;lo=-1.05*lim;hi=1.05*lim;
            case '+/-3 STD'
                lim=3*sigma;if ~isfinite(lim)||lim<=0,lim=max(abs(r-mu));end
                if ~isfinite(lim)||lim<=0,lim=1e-6;end;lo=-lim;hi=lim;
            otherwise
                lo=min(r);hi=max(r);span=hi-lo;if ~isfinite(span)||span<=0,span=max(1e-6,abs(lo)*.02);end
                lo=lo-.05*span;hi=hi+.05*span;
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo,lo=-1e-6;hi=1e-6;end
        if ~strcmp(positionCrossHistRangeMode.Value,'Manual'),positionCrossHistXMin.Value=lo;positionCrossHistXMax.Value=hi;end
    end

    function exportPositionCrossValidation(~,~)
        if isempty(fieldnames(positionCrossResult))||~isfield(positionCrossResult,'Cells')
            uialert(fig,'Run peak-position cross validation first.','No cross-validation result');return;
        end
        [fn,pn]=uiputfile('*.csv','Export cross-validation matrix','peak_position_cross_validation.csv');if isequal(fn,0),return;end
        try
            methods=positionCrossResult.Methods;values=positionCrossMetricValues();
            matrixTable=array2table(values,'VariableNames',matlab.lang.makeValidName(methods),'RowNames',methods);
            writetable(matrixTable,fullfile(pn,fn),'WriteRowNames',true);
            [~,base,~]=fileparts(fn);summaryRows=cell(0,15);residualRows=cell(0,10);
            if isfield(positionCrossResult,'TrainingSetLabel'),trainingLabel=positionCrossResult.TrainingSetLabel;else,trainingLabel='All matched pairs (legacy result)';end
            if isfield(positionCrossResult,'EvaluationSetLabel'),evaluationLabel=positionCrossResult.EvaluationSetLabel;else,evaluationLabel='All matched pairs (legacy result)';end
            for a=1:numel(methods)
                for b=1:numel(methods)
                    q=positionCrossResult.Cells(a,b);
                    summaryRows(end+1,:)={q.TrainMethod,q.ApplicationMethod,q.Degree,q.ValidationMode,q.PoolMode,trainingLabel,evaluationLabel,q.NTrain,q.N,q.Bias,q.RMSE,q.STD,q.P95,q.MAX,q.Slope}; %#ok<AGROW>
                    for k=1:numel(q.Residual)
                        idx=q.ValidIndex(k);peakID='';if isfield(positionCrossResult,'PeakIDs')&&idx<=numel(positionCrossResult.PeakIDs),peakID=positionCrossResult.PeakIDs{idx};end
                        residualRows(end+1,:)={q.TrainMethod,q.ApplicationMethod,trainingLabel,evaluationLabel,peakID,q.Wavelength(k),q.TrainPosition(k),q.ApplicationPosition(k),q.Residual(k),q.ValidationMode}; %#ok<AGROW>
                    end
                end
            end
            summaryTable=cell2table(summaryRows,'VariableNames',{'CalibrationMethod','ApplicationMethod','Degree','ValidationMode','PoolMode','TrainingSet','EvaluationSet','NTrain','NEval','Bias','RMSE','STD','P95','MAX','Slope'});
            residualTable=cell2table(residualRows,'VariableNames',{'CalibrationMethod','ApplicationMethod','TrainingSet','EvaluationSet','PeakID','ReferenceWavelength','CalibrationPosition','ApplicationPosition','Residual','ValidationMode'});
            writetable(summaryTable,fullfile(pn,[base '_summary.csv']));writetable(residualTable,fullfile(pn,[base '_residuals.csv']));
            positionCrossStatus.Text=sprintf('Exported matrix, summary, and residuals: %s',pn);
        catch ME
            uialert(fig,ME.message,'Cross-validation export failed');
        end
    end

    function selectValidationRow(~,event)
        if isempty(event.Indices),selectedValidationRow=0;else,selectedValidationRow=event.Indices(1);end
    end

    function openValidationPeak(~,~)
        if selectedValidationRow<1||selectedValidationRow>numel(finalModel.PeakID),return;end
        id=finalModel.PeakID{selectedValidationRow};k=find(strcmp({peaks.ID},id),1);if isempty(k),return;end
        selectedRow=k;plotTabs.SelectedTab=tabPlots;leftTabs.SelectedTab=tabCurrent;tabs.SelectedTab=tabList;showSelected();
    end

    function removeValidationPair(~,~)
        if selectedValidationRow<1||selectedValidationRow>numel(finalModel.PeakID),return;end
        id=finalModel.PeakID{selectedValidationRow};k=find(strcmp({calPairs.PeakID},id),1);
        if isempty(k),return;end
        calPairs(k)=[];finalModel=emptyFinalModel();refreshCalibration();drawEmbeddedResults();refreshValidationView([],[]);
        topStatus.Text=sprintf('%s removed from current calibration pairs; refit is required',id);tabs.SelectedTab=tabCal;
    end

    function exportCurrentModel(~,~)
        if ~finalModel.valid,uialert(fig,'Fit a calibration model first.','No final model');return;end
        [fn,pn]=uiputfile('WCC4SM_calibration_model.mat','Save current calibration model');if isequal(fn,0),return;end
        CalibrationModel=finalModel;CalibrationPairs=calPairs;ReferenceLines=L; %#ok<NASGU>
        save(fullfile(pn,fn),'CalibrationModel','CalibrationPairs','ReferenceLines');
        [~,stem]=fileparts(fn);
        [coordinateMode,coordinateDomain,calibrationDomain]=modelCoordinateLabels(finalModel);
        rowCount=numel(finalModel.Pixel);
        T=table(repmat(string(coordinateMode),rowCount,1),repmat(string(coordinateDomain),rowCount,1), ...
            repmat(string(calibrationDomain),rowCount,1),string(finalModel.PeakID(:)),finalModel.Pixel(:),finalModel.ReferenceWavelength(:), ...
            finalModel.FittedWavelength(:),finalModel.Residual(:),finalModel.LOOResidual(:),finalModel.DeletionMaxCurveChange(:), ...
            'VariableNames',{'PixelMode','DataPixelDomain','CalibrationPixelDomain','PeakID','Pixel','Reference_nm','Fitted_nm','Residual_nm','LOO_residual_nm','Deletion_max_curve_change_nm'});
        writetable(T,fullfile(pn,[stem '_residuals.csv']));
        fid=fopen(fullfile(pn,[stem '_equation.txt']),'w');
        if fid>=0
            fprintf(fid,'WCC4SM wavelength calibration model\nPixel coordinate mode: %s\nData pixel domain: %s\nCalibration pixel domain: %s\n%s\nPeak position: %s\nDegree: %d\nN: %d\nFit RMS: %.12g nm\nLOO RMS: %.12g nm\nLOO max abs: %.12g nm\nMax deletion influence: %.12g nm\nSTD: %.12g nm\nMax abs residual: %.12g nm\n', ...
                coordinateMode,coordinateDomain,calibrationDomain,finalModel.Equation,finalModel.PositionMethod,finalModel.Degree,numel(finalModel.Pixel),finalModel.RMS,finalModel.LOORMS,finalModel.LOOMaxAbs,finalModel.MaxDeletionInfluence,finalModel.STD,finalModel.MaxAbsResidual);
            fprintf(fid,'Normalized coefficients: %s\nmu: %s\nNatural pixel coefficients: %s\n',mat2str(finalModel.Coefficients,16),mat2str(finalModel.Mu,16),mat2str(finalModel.NaturalCoefficients,16));fclose(fid);
        end
        topStatus.Text='Current calibration model saved (MAT + CSV + TXT)';
    end

    function importCalibrationModels(~,~)
        [fn,pn]=uigetfile('*.mat','Import calibration model(s)','MultiSelect','on');if isequal(fn,0),return;end
        if ischar(fn),fn={fn};end
        added=0;
        if ~isempty(calibrationModels) && ~isfield(calibrationModels,'Visible'),[calibrationModels.Visible]=deal(true);end
        for kk=1:numel(fn)
            S=load(fullfile(pn,fn{kk}));incoming={};
            if isfield(S,'CalibrationModel'),incoming={S.CalibrationModel};
            elseif isfield(S,'FinalCalibration'),incoming={S.FinalCalibration};
            elseif isfield(S,'CalibrationModels'),incoming=arrayfun(@(q)q.Model,S.CalibrationModels,'UniformOutput',false);end
            for jj=1:numel(incoming)
                m=incoming{jj};if ~isstruct(m)||~isfield(m,'valid')||~m.valid,continue;end
                if ~isfield(m,'NaturalCoefficients')||isempty(m.NaturalCoefficients),m.NaturalCoefficients=normalizedToNaturalPolynomial(m.Coefficients,m.Mu);end
                if ~isfield(m,'Equation')||isempty(m.Equation),m.Equation=formatCalibrationEquation(m.NaturalCoefficients);end
                if ~isfield(m,'LOOResidual')||isempty(m.LOOResidual)
                    validation=wc4sm_validate_calibration_loo(m.Pixel(:), ...
                        m.ReferenceWavelength(:),m.Degree,m.Coefficients,m.Mu,m.Pixel(:));
                    m.LOOResidual=validation.LOOResidual;
                    m.DeletionMaxCurveChange=validation.DeletionMaxCurveChange;
                    m.LOORMS=validation.LOORMS;m.LOOMaxAbs=validation.LOOMaxAbs;
                    m.MaxDeletionInfluence=validation.MaxDeletionInfluence;
                end
                id=sprintf('M%03d',numel(calibrationModels)+1);item=struct('ModelID',id,'CreatedAt',datetime('now'), ...
                    'PairCount',numel(m.Pixel),'PositionMethod',m.PositionMethod,'Degree',m.Degree,'PairIDs',{m.PeakID},'Model',m);
                item.Visible=true; calibrationModels(end+1)=item;added=added+1; %#ok<AGROW>
            end
        end
        refreshModelComparison();drawModelComparison([],[]);plotTabs.SelectedTab=tabModelCompare;
        if added>0
            selectedModelRow=numel(calibrationModels);
            try,modelComparisonTable.Selection=[selectedModelRow 1];catch,end
        end
        topStatus.Text=sprintf('%d calibration model(s) imported',added);
    end

    function clearCalibrationModels(~,~)
        calibrationModels=emptyCalibrationModels();selectedModelRow=0;refreshModelComparison();drawModelComparison([],[]);topStatus.Text='Stored model list cleared';
    end

    function toggleSelectedModelVisibility(~,~)
        if selectedModelRow<1||selectedModelRow>numel(calibrationModels)
            uialert(fig,'Select a model row first.','No model selected');return;
        end
        if ~isfield(calibrationModels,'Visible'),[calibrationModels.Visible]=deal(true);end
        calibrationModels(selectedModelRow).Visible=~calibrationModels(selectedModelRow).Visible;
        refreshModelComparison();drawModelComparison([],[]);
    end

    function deleteSelectedModel(~,~)
        if selectedModelRow<1||selectedModelRow>numel(calibrationModels)
            uialert(fig,'Select a model row first.','No model selected');return;
        end
        id=calibrationModels(selectedModelRow).ModelID;
        choice=uiconfirm(fig,sprintf('Delete stored model %s? This cannot be undone after the session is saved.',id), ...
            'Delete model','Options',{'Delete','Cancel'},'DefaultOption',2,'CancelOption',2);
        if strcmp(choice,'Cancel'),return;end
        calibrationModels(selectedModelRow)=[];
        selectedModelRow=min(selectedModelRow,numel(calibrationModels));
        refreshModelComparison();drawModelComparison([],[]);
    end

    function selectModelRow(~,event)
        if isempty(event.Indices),selectedModelRow=0;else,selectedModelRow=event.Indices(1);end
        drawModelComparison([],[]);
    end

    function applySelectedModel(~,~)
        if isempty(calibrationModels),uialert(fig,'Import or fit a calibration model first.','No model available');return;end
        if selectedModelRow<1||selectedModelRow>numel(calibrationModels)
            if numel(calibrationModels)==1
                selectedModelRow=1;
            else
                uialert(fig,'Click any cell in the desired model row, then press Apply selected model.','Select a model row');return;
            end
        end
        try,modelComparisonTable.Selection=[selectedModelRow 1];catch,end
        item=calibrationModels(selectedModelRow);validateAndApplyModel(item.Model,item.ModelID);
    end

    function applyCurrentModel(~,~)
        if ~finalModel.valid,uialert(fig,'Fit or import a valid final model first.','No final model');return;end
        name='Current final';if ~isempty(calibrationModels),name=calibrationModels(end).ModelID;end
        validateAndApplyModel(finalModel,name);
    end

    function importAndApplyModel(~,~)
        [fn,pn]=uigetfile('*.mat','Import and apply calibration model');if isequal(fn,0),return;end
        S=load(fullfile(pn,fn));m=[];name=shortName(fn);
        if isfield(S,'CalibrationModel'),m=S.CalibrationModel;
        elseif isfield(S,'FinalCalibration'),m=S.FinalCalibration;
        elseif isfield(S,'CalibrationModels')&&~isempty(S.CalibrationModels),m=S.CalibrationModels(end).Model;end
        if isempty(m),uialert(fig,'No CalibrationModel, FinalCalibration, or CalibrationModels entry was found.','Invalid model file');return;end
        validateAndApplyModel(m,name);
    end

    function validateAndApplyModel(m,name)
        if isempty(D.pixel),uialert(fig,'Load a spectrum before applying a model.','No spectrum');return;end
        if ~isstruct(m)||~isfield(m,'valid')||~m.valid||~isfield(m,'Coefficients')||isempty(m.Coefficients)||~isfield(m,'Mu')||numel(m.Mu)~=2
            uialert(fig,'The selected object is not a valid wavelength calibration model.','Invalid model');return;
        end
        if ~isfield(m,'PositionMethod')||isempty(m.PositionMethod),m.PositionMethod='Imported model';end
        if ~isfield(m,'Degree')||~isfinite(m.Degree),m.Degree=numel(m.Coefficients)-1;end
        [coordinateCompatible,coordinateMessage]=modelPixelCoordinatesCompatible(m);
        if ~coordinateCompatible
            uialert(fig,coordinateMessage,'Pixel sequence mismatch');return;
        end
        wl=evaluateWavelengthModel(m,D.pixel);
        if any(~isfinite(wl))||any(diff(wl)<=0)
            uialert(fig,'The model does not produce a finite, strictly increasing wavelength axis for this spectrum.','Model rejected');return;
        end
        outside=false(size(D.pixel));
        if isfield(m,'Pixel')&&~isempty(m.Pixel),outside=(D.pixel<min(m.Pixel)) | (D.pixel>max(m.Pixel));end
        if any(outside)
            frac=100*sum(outside)/numel(outside);
            choice=uiconfirm(fig,sprintf('%.1f%% of spectrum pixels lie outside the model calibration-point range and will be extrapolated.',frac), ...
                'Extrapolation warning','Options',{'Apply anyway','Cancel'},'DefaultOption',2,'CancelOption',2);
            if strcmp(choice,'Cancel'),return;end
        end
        appliedModel=m;appliedModelName=char(name);D.calibratedWavelength=wl(:);mainAxisMode='Wavelength';axisButton.Text='X Axis: Wavelength  <->';resetFullViewRange();
        [coordinateMode,coordinateDomain]=modelCoordinateLabels(m);
        appliedStatus.Text=sprintf('Applied: %s | %s | pixels %s | degree %d | %.4g to %.4g nm',appliedModelName,coordinateMode,coordinateDomain,m.Degree,min(wl),max(wl));
        drawFull();if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
        if peakAnalysisTabs.SelectedTab==peakGalleryTab,refreshPeakGallery();end
        plotTabs.SelectedTab=tabPlots;topStatus.Text=sprintf('%s applied to spectrum wavelength axis',appliedModelName);
    end

    function clearAppliedModel(~,~)
        appliedModel=emptyFinalModel();appliedModelName='';D.calibratedWavelength=[];mainAxisMode='Pixel';axisButton.Text='X Axis: Pixel  <->';resetFullViewRange();
        appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';drawFull();
        if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
        if peakAnalysisTabs.SelectedTab==peakGalleryTab,refreshPeakGallery();end
        topStatus.Text='Applied calibration cleared; pixel coordinates restored';
    end

    function drawModelComparison(~,~)
        legend(axModelCompare,'off');cla(axModelCompare,'reset');styleAxes(axModelCompare,C);
        if isempty(calibrationModels),title(axModelCompare,'No stored calibration models');return;end
        cols=lines(max(1,numel(calibrationModels)));hold(axModelCompare,'on');mode='Fit residual';if exist('compareResidualMode','var'),mode=compareResidualMode.Value;end
        for kk=1:numel(calibrationModels)
            if isfield(calibrationModels(kk),'Visible') && ~calibrationModels(kk).Visible,continue;end
            m=calibrationModels(kk).Model;[x,residual]=comparisonResiduals(m,mode);
            if kk==selectedModelRow,continue;end
            scatter(axModelCompare,x,residual,24,cols(kk,:),'filled','DisplayName',sprintf('%s | %s d%d',calibrationModels(kk).ModelID,calibrationModels(kk).PositionMethod,calibrationModels(kk).Degree));
        end
        if selectedModelRow>=1&&selectedModelRow<=numel(calibrationModels)
            item=calibrationModels(selectedModelRow);
            if ~isfield(item,'Visible')||item.Visible
                [x,residual]=comparisonResiduals(item.Model,mode);[sx,ord]=sort(x);sy=residual(ord);
                plot(axModelCompare,sx,sy,'-','Color',cols(selectedModelRow,:),'LineWidth',1.8,'HandleVisibility','off');
                scatter(axModelCompare,x,residual,58,cols(selectedModelRow,:),'filled','MarkerEdgeColor','k','LineWidth',1.0, ...
                    'DisplayName',sprintf('[SELECTED] %s | %s d%d',item.ModelID,item.PositionMethod,item.Degree));
                text(axModelCompare,.015,.97,sprintf('Selected model: %s | %s | degree %d | %s',item.ModelID,item.PositionMethod,item.Degree,mode), ...
                    'Units','normalized','VerticalAlignment','top','FontWeight','bold','Color',cols(selectedModelRow,:), ...
                    'BackgroundColor','white','Margin',4,'Interpreter','none');
                setSelectedResidualDiagnostics(x,residual, ...
                    sprintf('Model %s | %s d%d | %s',item.ModelID,item.PositionMethod,item.Degree,mode),'Reference wavelength (nm)');
            end
        end
        yline(axModelCompare,0,'-','Color',C.gray,'HandleVisibility','off');hold(axModelCompare,'off');grid(axModelCompare,'on');
        xlabel(axModelCompare,'Reference wavelength (nm)');ylabel(axModelCompare,'Reference - fitted (nm)');title(axModelCompare,['Residual overlays | ' mode]);legend(axModelCompare,'Location','best','Interpreter','none');
    end

    function [x,residual]=comparisonResiduals(m,mode)
        switch mode
            case 'LOO residual'
                x=m.ReferenceWavelength;residual=m.LOOResidual;
            case 'All matched points'
                valid=find([calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]));x=[calPairs(valid).ReferenceWavelength].';px=nan(size(x));for ii=1:numel(valid),px(ii)=pairPeakPosition(calPairs(valid(ii)),m.PositionMethod);end;residual=x-polyval(m.Coefficients,px,[],m.Mu);
            otherwise
                x=m.ReferenceWavelength;residual=m.Residual;
        end
        good=isfinite(x)&isfinite(residual);x=x(good);residual=residual(good);
    end

    function setSelectedResidualDiagnostics(x,residual,label,xAxisLabel)
        x=x(:);residual=residual(:);n=min(numel(x),numel(residual));x=x(1:n);residual=residual(1:n);
        good=isfinite(x)&isfinite(residual);selectedResidualContext=struct( ...
            'X',x(good),'Residual',residual(good),'Label',char(string(label)),'XAxisLabel',char(string(xAxisLabel)));
        drawSelectedResidualDiagnostics();
    end

    function selectedResidualHistogramControlsChanged(~,~)
        if strcmp(selectedHistRangeMode.Value,'Manual')&&selectedHistXMax.Value<=selectedHistXMin.Value
            selectedHistXMax.Value=selectedHistXMin.Value+max(1e-6,abs(selectedHistXMin.Value)*0.01);
        end
        drawSelectedResidualDiagnostics();
    end

    function drawSelectedResidualDiagnostics
        cla(axSelectedResidualTrend,'reset');styleAxes(axSelectedResidualTrend,C);
        cla(axSelectedResidualHistogram,'reset');styleAxes(axSelectedResidualHistogram,C);
        r=selectedResidualContext.Residual(:);x=selectedResidualContext.X(:);
        if isempty(r)
            selectedResidualSummary.Text='Select a model, Add-One round, model degree, or set replacement round.';
            showNoStatistics(axSelectedResidualTrend,'No selected residual data');
            showNoStatistics(axSelectedResidualHistogram,'No selected residual data');
            return;
        end
        selectedResidualSummary.Text=sprintf('%s | N=%d',selectedResidualContext.Label,numel(r));
        [sx,ord]=sort(x);sr=r(ord);hold(axSelectedResidualTrend,'on');
        scatter(axSelectedResidualTrend,x,r,30,C.blue,'filled','DisplayName','Residual');
        yline(axSelectedResidualTrend,0,'-','Color',C.gray,'HandleVisibility','off');
        if numel(sr)>=5
            span=min(5,numel(sr));plot(axSelectedResidualTrend,sx,movmean(sr,span),'-','Color',C.red,'LineWidth',1.5,'DisplayName',sprintf('%d-point moving mean',span));
            legend(axSelectedResidualTrend,'Location','best');
        end
        hold(axSelectedResidualTrend,'off');grid(axSelectedResidualTrend,'on');
        xlabel(axSelectedResidualTrend,selectedResidualContext.XAxisLabel);ylabel(axSelectedResidualTrend,'Residual (nm)');
        title(axSelectedResidualTrend,[selectedResidualContext.Label ' | residual trend'],'Interpreter','none');

        [lo,hi,nb]=selectedResidualHistogramSettings(r);
        histogram(axSelectedResidualHistogram,r,'NumBins',nb,'BinLimits',[lo hi], ...
            'FaceColor',C.cyanDark,'FaceAlpha',0.70,'EdgeColor','white');
        grid(axSelectedResidualHistogram,'on');xlim(axSelectedResidualHistogram,[lo hi]);
        xlabel(axSelectedResidualHistogram,'Residual (nm)');ylabel(axSelectedResidualHistogram,'Count');
        mu=mean(r);sigma=std(r,1);rmsValue=sqrt(mean(r.^2));skewValue=NaN;excessKurtosis=NaN;
        if sigma>eps
            z=(r-mu)/sigma;skewValue=mean(z.^3);excessKurtosis=mean(z.^4)-3;
        end
        title(axSelectedResidualHistogram,sprintf('%s | residual distribution',selectedResidualContext.Label),'Interpreter','none');
        text(axSelectedResidualHistogram,.98,.96,sprintf('N = %d\nRMS = %.6g nm\nMean = %.6g nm\nSTD = %.6g nm\nSkew = %.4g\nExcess kurtosis = %.4g', ...
            numel(r),rmsValue,mu,sigma,skewValue,excessKurtosis),'Units','normalized', ...
            'HorizontalAlignment','right','VerticalAlignment','top','FontWeight','bold', ...
            'Color',C.navy,'BackgroundColor','white','Margin',4);
    end

    function [lo,hi,nb]=selectedResidualHistogramSettings(r)
        nb=max(1,min(100,round(selectedHistBinCount.Value)));mu=mean(r);sigma=std(r,1);
        switch selectedHistRangeMode.Value
            case 'Manual'
                lo=selectedHistXMin.Value;hi=selectedHistXMax.Value;
            case 'Symmetric'
                lim=max(abs(r));if ~isfinite(lim)||lim<=0,lim=1e-6;end
                lim=1.05*lim;lo=-lim;hi=lim;
            case '+/-3 STD'
                lim=3*sigma;if ~isfinite(lim)||lim<=0,lim=max(abs(r-mu));end
                if ~isfinite(lim)||lim<=0,lim=1e-6;end
                lo=-lim;hi=lim;
            otherwise
                lo=min(r);hi=max(r);span=hi-lo;
                if ~isfinite(span)||span<=0,span=max(1e-6,abs(lo)*0.02);end
                lo=lo-0.05*span;hi=hi+0.05*span;
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo,lo=-1e-6;hi=1e-6;end
        if ~strcmp(selectedHistRangeMode.Value,'Manual'),selectedHistXMin.Value=lo;selectedHistXMax.Value=hi;end
    end

    function resetModelCompareView(~,~)
        xlim(axModelCompare,'auto');ylim(axModelCompare,'auto');drawModelComparison([],[]);
    end

    function openResidualAnalysis(~,~)
        if ~finalModel.valid,uialert(fig,'Fit a final calibration model first.','No final model');return;end
        rf=uifigure('Name','WCC4SM V1.0 | Calibration Fit & Residual Analysis','Position',[120 90 1160 760],'Color',C.bg);
        rg=uigridlayout(rf,[2 2]); rg.RowHeight={'1.05x','1x'}; rg.ColumnWidth={'1.25x','1x'}; rg.Padding=[12 10 12 12];
        a1=uiaxes(rg); a1.Layout.Column=[1 2]; styleAxes(a1,C); hold(a1,'on');
        xx=linspace(min(finalModel.Pixel),max(finalModel.Pixel),800); yy=polyval(finalModel.Coefficients,xx,[],finalModel.Mu);
        plot(a1,xx,yy,'-','Color',C.blue,'LineWidth',1.5,'DisplayName','Polynomial fit');
        scatter(a1,finalModel.Pixel,finalModel.ReferenceWavelength,42,C.orange,'filled','DisplayName','Calibration points');
        for jj=1:numel(finalModel.Pixel),text(a1,finalModel.Pixel(jj),finalModel.ReferenceWavelength(jj),[' ' finalModel.PeakID{jj}],'FontSize',7,'Color',C.muted);end
        hold(a1,'off');grid(a1,'on');xlabel(a1,'Peak position (pixel)');ylabel(a1,'Reference wavelength (nm)');
        title(a1,{sprintf('%s | degree %d | N=%d',finalModel.PositionMethod,finalModel.Degree,numel(finalModel.Pixel)),finalModel.Equation},'Interpreter','none');legend(a1,'Location','best');
        a2=uiaxes(rg);styleAxes(a2,C);hold(a2,'on');yline(a2,0,'-','Color',C.gray);
        scatter(a2,finalModel.ReferenceWavelength,finalModel.Residual,40,C.red,'filled');
        for jj=1:numel(finalModel.Pixel),text(a2,finalModel.ReferenceWavelength(jj),finalModel.Residual(jj),[' ' finalModel.PeakID{jj}],'FontSize',7,'Color',C.muted);end
        if numel(finalModel.Residual)>1
            yline(a2,finalModel.MeanResidual+finalModel.STD,'--','+1 sigma','Color',C.green);
            yline(a2,finalModel.MeanResidual-finalModel.STD,'--','-1 sigma','Color',C.green);
        end
        hold(a2,'off');grid(a2,'on');xlabel(a2,'Reference wavelength (nm)');ylabel(a2,'Residual: reference - fitted (nm)');title(a2,'Residual trend');
        a3=uiaxes(rg);styleAxes(a3,C); [lo,hi,nb]=histogramSettings();
        histogram(a3,finalModel.Residual,'NumBins',nb,'BinLimits',[lo hi],'FaceColor',C.cyanDark,'FaceAlpha',0.65);hold(a3,'on');
        if numel(finalModel.Residual)>=6 && finalModel.STD>0
            xr=linspace(lo,hi,300); bw=(hi-lo)/nb;
            pdfv=exp(-0.5*((xr-finalModel.MeanResidual)/finalModel.STD).^2)/(finalModel.STD*sqrt(2*pi));
            plot(a3,xr,pdfv*numel(finalModel.Residual)*bw,'-','Color',C.red,'LineWidth',1.5);
        end
        hold(a3,'off');grid(a3,'on');xlim(a3,[lo hi]);xlabel(a3,'Residual (nm)');ylabel(a3,'Count');
        title(a3,sprintf('Mean %.4g | STD %.4g | RMS %.4g | Max %.4g nm',finalModel.MeanResidual,finalModel.STD,finalModel.RMS,finalModel.MaxAbsResidual));
    end

    function drawEmbeddedResults
        cla(axFitResult);cla(axResidualResult);cla(axHistogramResult);
        styleAxes(axFitResult,C);styleAxes(axResidualResult,C);styleAxes(axHistogramResult,C);
        if ~finalModel.valid
            title(axFitResult,'Fit a final calibration model first');return;
        end
        xx=linspace(min(finalModel.Pixel),max(finalModel.Pixel),600);yy=polyval(finalModel.Coefficients,xx,[],finalModel.Mu);
        plot(axFitResult,xx,yy,'-','Color',C.blue,'LineWidth',1.4);hold(axFitResult,'on');
        scatter(axFitResult,finalModel.Pixel,finalModel.ReferenceWavelength,30,C.orange,'filled');hold(axFitResult,'off');grid(axFitResult,'on');
        xlabel(axFitResult,'Peak position (pixel)');ylabel(axFitResult,'Wavelength (nm)');
        title(axFitResult,{sprintf('%s | degree %d | N=%d',finalModel.PositionMethod,finalModel.Degree,numel(finalModel.Pixel)),finalModel.Equation},'Interpreter','none');
        yline(axResidualResult,0,'-','Color',C.gray);hold(axResidualResult,'on');
        scatter(axResidualResult,finalModel.ReferenceWavelength,finalModel.Residual,30,C.red,'filled');hold(axResidualResult,'off');grid(axResidualResult,'on');
        xlabel(axResidualResult,'Reference wavelength (nm)');ylabel(axResidualResult,'Reference - fitted (nm)');
        title(axResidualResult,sprintf('Residual trend | RMS %.5g nm | max %.5g nm',finalModel.RMS,finalModel.MaxAbsResidual));
        [lo,hi,nb]=histogramSettings();histogram(axHistogramResult,finalModel.Residual,'NumBins',nb,'BinLimits',[lo hi],'FaceColor',C.cyanDark,'FaceAlpha',.7);
        xlim(axHistogramResult,[lo hi]);grid(axHistogramResult,'on');xlabel(axHistogramResult,'Residual (nm)');ylabel(axHistogramResult,'Count');
        title(axHistogramResult,sprintf('Mean %.5g | STD %.5g nm',finalModel.MeanResidual,finalModel.STD));
    end

    function histogramControlsChanged(~,~)
        if strcmp(histRangeMode.Value,'Manual') && histXMax.Value<=histXMin.Value
            histXMax.Value=histXMin.Value+max(1e-6,abs(histXMin.Value)*0.01);
        end
        if finalModel.valid,drawEmbeddedResults();end
    end

    function [lo,hi,nb]=histogramSettings
        r=finalModel.Residual(:);nb=max(1,round(histBinCount.Value));
        switch histRangeMode.Value
            case 'Manual'
                lo=histXMin.Value;hi=histXMax.Value;
            case 'Symmetric'
                lim=max(abs(r));if ~isfinite(lim)||lim<=0,lim=1e-6;end
                lim=lim*1.05;lo=-lim;hi=lim;
            case '+/-3 STD'
                lim=3*finalModel.STD;if ~isfinite(lim)||lim<=0,lim=max(abs(r));end
                if ~isfinite(lim)||lim<=0,lim=1e-6;end
                lo=-lim;hi=lim;
            otherwise
                lo=min(r);hi=max(r);span=hi-lo;
                if ~isfinite(span)||span<=0,span=max(1e-6,abs(lo)*0.02);end
                lo=lo-0.05*span;hi=hi+0.05*span;
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo,lo=-1e-6;hi=1e-6;end
        if ~strcmp(histRangeMode.Value,'Manual'),histXMin.Value=lo;histXMax.Value=hi;end
    end

    function refreshModelComparison
        dat=cell(numel(calibrationModels),13);
        for kk=1:numel(calibrationModels)
            mm=calibrationModels(kk);ff=mm.Model;
            if isfield(ff,'Equation'),eq=ff.Equation;else,eq='';end
            [coordinateMode,coordinateDomain]=modelCoordinateLabels(ff);
            label=mm.ModelID;if isfield(mm,'Visible')&&~mm.Visible,label=[label ' (hidden)'];end
            dat(kk,:)={label,mm.PairCount,mm.PositionMethod,mm.Degree,coordinateMode,coordinateDomain,ff.RMS,ff.LOORMS,ff.LOOMaxAbs,ff.MaxDeletionInfluence,ff.STD,ff.MaxAbsResidual,eq};
        end
        modelComparisonTable.Data=dat;
    end

    function plotConfirmedPeakParameters(~,~)
        confirmed=false(1,numel(peakDataset));
        if ~isempty(peakDataset),confirmed=[peakDataset.Confirmed];end
        rows=find(confirmed);
        if isempty(rows)
            uialert(fig,'Confirm peak parameters before drawing the statistics.','No confirmed peaks');
            return;
        end

        n=numel(rows);
        peakOrder=nan(n,1);fwhm=nan(n,1);erw=nan(n,1);
        directDelta=nan(n,1);centroidDelta=nan(n,1);interpDelta=nan(n,1);
        for jj=1:n
            dd=peakDataset(rows(jj));rr=dd.AnalysisResult;
            peakOrder(jj)=str2double(regexprep(dd.PeakID,'\D',''));
            fwhm(jj)=rr.FWHM;erw(jj)=rr.ERW;
            if isfinite(rr.CenterX)
                directDelta(jj)=rr.DirectPeakX-rr.CenterX;
                centroidDelta(jj)=rr.CentroidX-rr.CenterX;
                interpDelta(jj)=rr.InterpolatedPeakX-rr.CenterX;
            end
        end
        [peakOrder,order]=sort(peakOrder);
        fwhm=fwhm(order);erw=erw(order);
        directDelta=directDelta(order);centroidDelta=centroidDelta(order);interpDelta=interpDelta(order);

        cla(axWidthTrend,'reset');styleAxes(axWidthTrend,C);hold(axWidthTrend,'on');
        goodF=isfinite(peakOrder)&isfinite(fwhm);
        goodE=isfinite(peakOrder)&isfinite(erw);
        if any(goodF),plot(axWidthTrend,peakOrder(goodF),fwhm(goodF),'o-','Color',C.blue,'LineWidth',1.5,'MarkerFaceColor','white','DisplayName','FWHM');end
        if any(goodE),plot(axWidthTrend,peakOrder(goodE),erw(goodE),'o-','Color',C.orange,'LineWidth',1.5,'MarkerFaceColor','white','DisplayName','ERW');end
        xlabel(axWidthTrend,'Confirmed peak sequence (Peak ID)');ylabel(axWidthTrend,'Width (pixel)');
        title(axWidthTrend,sprintf('FWHM and ERW trend (%d confirmed peaks)',n));grid(axWidthTrend,'on');grid(axWidthTrend,'minor');
        if any(goodF)|any(goodE),legend(axWidthTrend,'Location','best');else,showNoStatistics(axWidthTrend,'No valid FWHM / ERW values');end

        cla(axWidthRelation,'reset');styleAxes(axWidthRelation,C);
        good=isfinite(fwhm)&isfinite(erw);
        if any(good)
            xFit=fwhm(good);yFit=erw(good);
            plot(axWidthRelation,xFit,yFit,'o','LineStyle','none','Color',C.purple,'MarkerFaceColor',C.cyan,'DisplayName','Confirmed peaks');
            hold(axWidthRelation,'on');
            if sum(good)>=2 && (max(xFit)-min(xFit))>eps
                fitCoef=polyfit(xFit,yFit,1);
                fitX=linspace(min(xFit),max(xFit),100);
                fitY=polyval(fitCoef,fitX);
                yHat=polyval(fitCoef,xFit);
                ssTot=sum((yFit-mean(yFit)).^2);
                if ssTot>eps,rSquared=1-sum((yFit-yHat).^2)/ssTot;else,rSquared=NaN;end
                plot(axWidthRelation,fitX,fitY,'-','Color',C.red,'LineWidth',1.8,'DisplayName','Linear fit');
                eqText=sprintf('ERW = %.4f FWHM %+.4f\nR^2 = %.4f',fitCoef(1),fitCoef(2),rSquared);
                text(axWidthRelation,.04,.96,eqText,'Units','normalized','VerticalAlignment','top', ...
                    'Color',C.red,'FontWeight','bold','BackgroundColor','white','Margin',4);
                legend(axWidthRelation,'Location','southeast');
            end
            hold(axWidthRelation,'off');
            xlabel(axWidthRelation,'FWHM (pixel)');ylabel(axWidthRelation,'ERW (pixel)');grid(axWidthRelation,'on');grid(axWidthRelation,'minor');
            title(axWidthRelation,sprintf('FWHM versus ERW with linear fit (n = %d)',sum(good)));
        else
            showNoStatistics(axWidthRelation,'No complete single-peak width data');
        end

        cla(axPositionDelta,'reset');styleAxes(axPositionDelta,C);
        deltaMatrix=[directDelta centroidDelta interpDelta];
        if any(isfinite(deltaMatrix(:)))
            b=bar(axPositionDelta,peakOrder,deltaMatrix,'grouped');
            b(1).FaceColor=C.blue;b(1).DisplayName='Direct - FWHM center';
            b(2).FaceColor=C.green;b(2).DisplayName='Centroid - FWHM center';
            b(3).FaceColor=C.orange;b(3).DisplayName='Interpolated - FWHM center';
            xlabel(axPositionDelta,'Confirmed peak sequence (Peak ID)');ylabel(axPositionDelta,'Position difference (pixel)');
            title(axPositionDelta,'Peak-position differences');grid(axPositionDelta,'on');grid(axPositionDelta,'minor');legend(axPositionDelta,'Location','best');
            yline(axPositionDelta,0,'-','Color',C.gray,'HandleVisibility','off');
        else
            showNoStatistics(axPositionDelta,'No valid FWHM-center comparisons');
        end

        cla(axPositionHistogram,'reset');styleAxes(axPositionHistogram,C);hold(axPositionHistogram,'on');
        allDelta=deltaMatrix(isfinite(deltaMatrix));
        if ~isempty(allDelta)
            binCount=max(5,min(15,ceil(sqrt(numel(allDelta)))));
            lo=min(allDelta);hi=max(allDelta);
            if hi<=lo,lo=lo-0.05;hi=hi+0.05;end
            edges=linspace(lo,hi,binCount+1);
            binCenters=edges(1:end-1)+diff(edges)/2;
            countMatrix=[histcounts(directDelta(isfinite(directDelta)),edges); ...
                histcounts(centroidDelta(isfinite(centroidDelta)),edges); ...
                histcounts(interpDelta(isfinite(interpDelta)),edges)]';
            hb=bar(axPositionHistogram,binCenters,countMatrix,'grouped');
            hb(1).FaceColor=C.blue;hb(1).DisplayName='Direct - center';
            hb(2).FaceColor=C.green;hb(2).DisplayName='Centroid - center';
            hb(3).FaceColor=C.orange;hb(3).DisplayName='Interpolated - center';
            xlabel(axPositionHistogram,'Position difference (pixel)');ylabel(axPositionHistogram,'Count');
            title(axPositionHistogram,sprintf('Position-difference distributions (%d bins)',binCount));
            grid(axPositionHistogram,'on');grid(axPositionHistogram,'minor');legend(axPositionHistogram,'Location','best');
            xline(axPositionHistogram,0,'-','Color',C.gray,'HandleVisibility','off');
        else
            showNoStatistics(axPositionHistogram,'No valid peak-position differences');
        end
        drawPeakPositionDifferenceMap();
        plotTabs.SelectedTab=tabPeakStatistics;
        topStatus.Text=sprintf('Peak parameter statistics refreshed from %d confirmed snapshots',n);
    end

    function peakDifferenceDisplayChanged(~,~)
        drawPeakPositionDifferenceMap();
    end

    function peakDifferenceHistogramChanged(~,~)
        drawPeakPositionDifferenceMap();
    end

    function drawPeakPositionDifferenceMap
        cla(axPeakDifferenceMap,'reset');styleAxes(axPeakDifferenceMap,C);
        clearPeakDifferenceAuxiliary('Refresh confirmed peak statistics to calculate diagnostics.');
        confirmed=false(1,numel(peakDataset));
        if ~isempty(peakDataset),confirmed=[peakDataset.Confirmed];end
        rows=find(confirmed);
        if isempty(rows)
            showNoStatistics(axPeakDifferenceMap,'Confirm peak parameters before drawing the difference map');
            clearPeakDifferenceAuxiliary('No confirmed peak snapshots');
            peakDifferenceStatus.Text='No confirmed peak snapshots.';
            return;
        end

        n=numel(rows);peakID=cell(n,1);centerPx=nan(n,1);
        directPx=nan(n,1);centroidPx=nan(n,1);interpPx=nan(n,1);centerNm=nan(n,1);
        directNm=nan(n,1);centroidNm=nan(n,1);interpNm=nan(n,1);
        for jj=1:n
            dd=peakDataset(rows(jj));rr=dd.AnalysisResult;peakID{jj}=dd.PeakID;
            if isempty(rr),continue;end
            centerPx(jj)=rr.CenterX;directPx(jj)=rr.DirectPeakX;centroidPx(jj)=rr.CentroidX;interpPx(jj)=rr.InterpolatedPeakX;
            if appliedModel.valid
                centerNm(jj)=evaluateWavelengthModel(appliedModel,centerPx(jj));
                directNm(jj)=evaluateWavelengthModel(appliedModel,directPx(jj));
                centroidNm(jj)=evaluateWavelengthModel(appliedModel,centroidPx(jj));
                interpNm(jj)=evaluateWavelengthModel(appliedModel,interpPx(jj));
            end
        end

        if strcmp(peakDifferenceXMode.Value,'Center pixel')
            x=centerPx;xLabelText='FWHM center position (pixel)';
        elseif appliedModel.valid
            x=centerNm;xLabelText='FWHM center wavelength (nm)';
        else
            showNoStatistics(axPeakDifferenceMap,'Apply a calibration model or select Center pixel for Plot 1 X');
            clearPeakDifferenceAuxiliary('Center-wavelength coordinates require an applied calibration model');
            peakDifferenceStatus.Text='Center wavelength requires an applied calibration model.';
            return;
        end
        if strcmp(peakDifferenceUnit.Value,'Wavelength difference')
            if ~appliedModel.valid
                showNoStatistics(axPeakDifferenceMap,'Apply a calibration model to display wavelength-domain differences');
                clearPeakDifferenceAuxiliary('Apply a calibration model for wavelength-domain diagnostics');
                xlabel(axPeakDifferenceMap,xLabelText);ylabel(axPeakDifferenceMap,'Position difference (nm)');
                peakDifferenceStatus.Text='Wavelength differences require an applied calibration model.';
                return;
            end
            y=[directNm-centerNm,centroidNm-centerNm,interpNm-centerNm];yLabelText='Position difference (nm)';
        else
            y=[directPx-centerPx,centroidPx-centerPx,interpPx-centerPx];yLabelText='Position difference (pixel)';
        end

        labels={'Direct peak - FWHM center','Centroid - FWHM center','Interpolated peak - FWHM center'};
        seriesColor={C.blue,C.green,C.orange};comparisonPx=[directPx centroidPx interpPx];
        if strcmp(peakDifferenceSeries.Value,'Direct - center'),seriesColumn=1;
        elseif strcmp(peakDifferenceSeries.Value,'Interpolated - center'),seriesColumn=3;
        else,seriesColumn=2;end
        good=isfinite(x)&isfinite(y(:,seriesColumn));
        sourceRows=find(good);[xPlot,order]=sort(x(good));sourceRows=sourceRows(order);yPlot=y(sourceRows,seriesColumn);
        if ~isempty(sourceRows)
            h=plot(axPeakDifferenceMap,xPlot,yPlot,'o','LineStyle','none','LineWidth',0.8,'MarkerSize',6, ...
                'Color',seriesColor{seriesColumn},'MarkerEdgeColor',seriesColor{seriesColumn},'MarkerFaceColor',seriesColor{seriesColumn},'DisplayName',labels{seriesColumn});
            try
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Peak ID',peakID(sourceRows));
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Center pixel',centerPx(sourceRows));
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Compared pixel',comparisonPx(sourceRows,seriesColumn));
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Pixel difference',comparisonPx(sourceRows,seriesColumn)-centerPx(sourceRows));
            catch
            end
        end
        hold(axPeakDifferenceMap,'on');
        yline(axPeakDifferenceMap,0,'-','Color',C.gray,'LineWidth',1,'HandleVisibility','off');
        hold(axPeakDifferenceMap,'off');xlabel(axPeakDifferenceMap,xLabelText);ylabel(axPeakDifferenceMap,yLabelText);
        grid(axPeakDifferenceMap,'on');grid(axPeakDifferenceMap,'minor');
        if isempty(sourceRows)
            showNoStatistics(axPeakDifferenceMap,'No valid wavelength / peak-position pairs');
            clearPeakDifferenceAuxiliary('No valid peak-position differences');
            peakDifferenceStatus.Text='No valid points for the selected coordinates.';
            return;
        end
        title(axPeakDifferenceMap,sprintf('%s versus %s',labels{seriesColumn},xLabelText),'Interpreter','none');
        legend(axPeakDifferenceMap,'Location','best','Interpreter','none');
        peakDifferenceStatus.Text=sprintf('%d points | Plot 1/3: %s | Plot 2: %s / %s.',numel(sourceRows),peakDifferenceSeries.Value,peakDifferenceFitTarget.Value,peakDifferenceFitOrder.Value);
        if strcmp(peakDifferenceUnit.Value,'Wavelength difference')
            centerCoordinate=centerNm;positionMatrix=[directNm centroidNm interpNm];
        else
            centerCoordinate=centerPx;positionMatrix=[directPx centroidPx interpPx];
        end
        drawPeakDifferenceRelationDiagnostics(y,peakID,centerCoordinate,positionMatrix);
    end

    function clearPeakDifferenceAuxiliary(message)
        axesList=[axPeakDifferenceFit axPeakDifferenceDistribution axPeakDifferenceHistogram];
        for aa=axesList
            cla(aa,'reset');styleAxes(aa,C);showNoStatistics(aa,message);
        end
    end

    function drawPeakDifferenceRelationDiagnostics(deltaMatrix,peakID,centerCoordinate,positionMatrix)
        labels={'Direct peak - FWHM center','Centroid - FWHM center','Interpolated peak - FWHM center'};
        seriesColor={C.blue,C.green,C.orange};
        if strcmp(peakDifferenceUnit.Value,'Wavelength difference'),unit='nm';else,unit='pixel';end

        if strcmp(peakDifferenceSeries.Value,'Direct - center'),distributionColumn=1;
        elseif strcmp(peakDifferenceSeries.Value,'Interpolated - center'),distributionColumn=3;
        else,distributionColumn=2;end
        distributionValues=deltaMatrix(:,distributionColumn);distributionValues=distributionValues(isfinite(distributionValues));
        cla(axPeakDifferenceDistribution,'reset');styleAxes(axPeakDifferenceDistribution,C);
        if isempty(distributionValues)
            showNoStatistics(axPeakDifferenceDistribution,'No valid peak-position differences');
        else
            [edges,lo,hi]=peakDifferenceDistributionHistogramSettings(distributionValues);binCount=numel(edges)-1;
            histogram(axPeakDifferenceDistribution,distributionValues,edges,'FaceColor',seriesColor{distributionColumn},'EdgeColor','white');hold(axPeakDifferenceDistribution,'on');
            xline(axPeakDifferenceDistribution,0,'-','Color',C.gray,'HandleVisibility','off');
            hold(axPeakDifferenceDistribution,'off');xlabel(axPeakDifferenceDistribution,['Position difference (' unit ')']);ylabel(axPeakDifferenceDistribution,'Count');
            xlim(axPeakDifferenceDistribution,[lo hi]);
            title(axPeakDifferenceDistribution,sprintf('%s distribution (%d bins)',labels{distributionColumn},binCount),'Interpreter','none');
            grid(axPeakDifferenceDistribution,'on');
        end

        xFit=centerCoordinate;
        if strcmp(peakDifferenceFitTarget.Value,'Interpolated peak'),targetColumn=3;targetLabel='Interpolated peak position';fitColor=C.orange;
        elseif strcmp(peakDifferenceFitTarget.Value,'Centroid'),targetColumn=2;targetLabel='Centroid position';fitColor=C.green;
        else,targetColumn=1;targetLabel='Direct peak position';fitColor=C.blue;end
        yFit=positionMatrix(:,targetColumn);good=isfinite(xFit)&isfinite(yFit);
        cla(axPeakDifferenceFit,'reset');styleAxes(axPeakDifferenceFit,C);
        if sum(good)<2 || max(xFit(good))-min(xFit(good))<=eps
            showNoStatistics(axPeakDifferenceFit,'At least two distinct center positions are required');
            cla(axPeakDifferenceHistogram,'reset');styleAxes(axPeakDifferenceHistogram,C);showNoStatistics(axPeakDifferenceHistogram,'No valid fit residuals');
            return;
        end
        xx=xFit(good);yy=yFit(good);ids=peakID(good);
        hold(axPeakDifferenceFit,'on');h=plot(axPeakDifferenceFit,xx,yy,'o','LineStyle','none','LineWidth',0.8,'MarkerSize',6, ...
            'Color',C.blue,'MarkerEdgeColor',C.blue,'MarkerFaceColor',C.sky,'DisplayName','Confirmed peaks');
        try,h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Peak ID',ids);catch,end
        xlabel(axPeakDifferenceFit,['FWHM center position (' unit ')']);ylabel(axPeakDifferenceFit,[targetLabel ' (' unit ')']);
        if strcmp(peakDifferenceFitOrder.Value,'No fit')
            hold(axPeakDifferenceFit,'off');title(axPeakDifferenceFit,[targetLabel ' versus FWHM center | points only']);
            grid(axPeakDifferenceFit,'on');grid(axPeakDifferenceFit,'minor');legend(axPeakDifferenceFit,'Location','best','Interpreter','none');
            cla(axPeakDifferenceHistogram,'reset');styleAxes(axPeakDifferenceHistogram,C);showNoStatistics(axPeakDifferenceHistogram,'Select polynomial degree 1..3 to calculate fit residuals');
            return;
        end
        fitOrder=str2double(regexprep(peakDifferenceFitOrder.Value,'\D',''));
        if numel(xx)<fitOrder+1 || numel(unique(xx))<fitOrder+1
            hold(axPeakDifferenceFit,'off');showNoStatistics(axPeakDifferenceFit,sprintf('Degree %d fit requires at least %d distinct X values',fitOrder,fitOrder+1));
            cla(axPeakDifferenceHistogram,'reset');styleAxes(axPeakDifferenceHistogram,C);showNoStatistics(axPeakDifferenceHistogram,'Insufficient data for selected fit order');return;
        end
        coef=polyfit(xx,yy,fitOrder);predicted=polyval(coef,xx);residual=yy-predicted;
        ssTotal=sum((yy-mean(yy)).^2);if ssTotal>eps,rSquared=1-sum(residual.^2)/ssTotal;else,rSquared=NaN;end
        fitX=linspace(min(xx),max(xx),100);fitY=polyval(coef,fitX);
        plot(axPeakDifferenceFit,fitX,fitY,'--','Color',fitColor,'LineWidth',1.0,'DisplayName',sprintf('Degree %d fit',fitOrder));hold(axPeakDifferenceFit,'off');
        equation=sprintf('y = %s\nR^2 = %.5f | n = %d',poly2str(coef,'x'),rSquared,numel(xx));
        text(axPeakDifferenceFit,.04,.96,equation,'Units','normalized','VerticalAlignment','top','Color',C.red,'FontWeight','bold','BackgroundColor','white','Margin',4);
        title(axPeakDifferenceFit,sprintf('%s versus FWHM center | degree %d',targetLabel,fitOrder));grid(axPeakDifferenceFit,'on');grid(axPeakDifferenceFit,'minor');legend(axPeakDifferenceFit,'Location','best','Interpreter','none');

        drawPeakDifferenceResidualHistogram(residual,unit,targetLabel,coef,rSquared,fitOrder);
    end

    function drawPeakDifferenceResidualHistogram(residual,unit,targetLabel,coef,rSquared,fitOrder)
        residual=residual(isfinite(residual));cla(axPeakDifferenceHistogram,'reset');styleAxes(axPeakDifferenceHistogram,C);
        if isempty(residual),showNoStatistics(axPeakDifferenceHistogram,'No valid linear-fit residuals');return;end
        [edges,lo,hi]=peakDifferenceResidualHistogramSettings(residual);
        histogram(axPeakDifferenceHistogram,residual,edges,'FaceColor',C.purple,'EdgeColor','white');hold(axPeakDifferenceHistogram,'on');
        xline(axPeakDifferenceHistogram,0,'-','Color',C.gray,'LineWidth',1.2);xline(axPeakDifferenceHistogram,mean(residual),'--','Color',C.red,'LineWidth',1.2,'DisplayName','Mean');hold(axPeakDifferenceHistogram,'off');
        xlim(axPeakDifferenceHistogram,[lo hi]);xlabel(axPeakDifferenceHistogram,['Fit residual (' unit ')']);ylabel(axPeakDifferenceHistogram,'Count');
        title(axPeakDifferenceHistogram,sprintf('%s d%d residuals | RMS %.5g | R^2 %.4f',targetLabel,fitOrder,sqrt(mean(residual.^2)),rSquared),'Interpreter','none');grid(axPeakDifferenceHistogram,'on');
        axPeakDifferenceHistogram.UserData=struct('Coefficients',coef,'Residual',residual);
    end

    function [edges,lo,hi]=peakDifferenceResidualHistogramSettings(residual)
        mode=peakDifferenceHistRangeMode.Value;binCount=max(1,round(peakDifferenceHistBinCount.Value));
        switch mode
            case 'Manual'
                lo=peakDifferenceHistXMin.Value;hi=peakDifferenceHistXMax.Value;
            case 'Symmetric'
                span=max(abs(residual));if span<=0,span=0.05;end;lo=-span;hi=span;
            case '+/-3 STD'
                center=mean(residual);span=3*std(residual);if span<=0,span=max(0.05,abs(center)*0.05);end;lo=center-span;hi=center+span;
            otherwise
                lo=min(residual);hi=max(residual);
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo
            center=mean(residual);span=max(0.05,max(abs(residual-center)));lo=center-span;hi=center+span;
        end
        if ~strcmp(mode,'Manual'),peakDifferenceHistXMin.Value=lo;peakDifferenceHistXMax.Value=hi;end
        edges=linspace(lo,hi,binCount+1);
    end

    function [edges,lo,hi]=peakDifferenceDistributionHistogramSettings(values)
        mode=peakDifferenceDistributionRangeMode.Value;binCount=max(1,round(peakDifferenceDistributionBinCount.Value));
        switch mode
            case 'Manual'
                lo=peakDifferenceDistributionXMin.Value;hi=peakDifferenceDistributionXMax.Value;
            case 'Symmetric'
                span=max(abs(values));if span<=0,span=0.05;end;lo=-span;hi=span;
            case '+/-3 STD'
                center=mean(values);span=3*std(values);if span<=0,span=max(0.05,abs(center)*0.05);end;lo=center-span;hi=center+span;
            otherwise
                lo=min(values);hi=max(values);
        end
        if ~isfinite(lo)||~isfinite(hi)||hi<=lo
            center=mean(values);span=max(0.05,max(abs(values-center)));lo=center-span;hi=center+span;
        end
        if ~strcmp(mode,'Manual'),peakDifferenceDistributionXMin.Value=lo;peakDifferenceDistributionXMax.Value=hi;end
        edges=linspace(lo,hi,binCount+1);
    end

    function refreshPaperPeakDifference(~,~)
        if ~finalModel.valid
            uialert(fig,'Fit a final calibration model before drawing wavelength-dependent peak-position differences.','No final calibration model');
            return;
        end
        archiveCurrentPaperCalibrationPairs();
        drawPaperAllPeakDifferences();
        drawPaperBenchmarkDifference();
        calibratedStatsTabs.SelectedTab=paperPeakDifferenceTab;
        plotTabs.SelectedTab=tabCalibratedStatistics;
        tabs.SelectedTab=tabPeakDifferenceData;
    end

    function drawPaperAllPeakDifferences
        cla(axPaperAllPeakDifferences,'reset');styleAxes(axPaperAllPeakDifferences,C);hold(axPaperAllPeakDifferences,'on');
        n=numel(peaks);ids=cell(n,1);wavelength=nan(n,1);delta=nan(n,3);
        for kk=1:n
            ids{kk}=peaks(kk).ID;rr=peaks(kk).Result;
            if isempty(rr)||~isstruct(rr)||~isfield(rr,'CenterX')||~isfinite(rr.CenterX),continue;end
            wavelength(kk)=evaluateWavelengthModel(finalModel,rr.CenterX);
            if isfield(rr,'DirectPeakX'),delta(kk,1)=rr.DirectPeakX-rr.CenterX;end
            if isfield(rr,'InterpolatedPeakX'),delta(kk,2)=rr.InterpolatedPeakX-rr.CenterX;end
            if isfield(rr,'CentroidX'),delta(kk,3)=rr.CentroidX-rr.CenterX;end
        end
        names={'Direct - FWHM center','Interpolated - FWHM center','Centroid - FWHM center'};
        colors={C.blue,C.orange,C.purple};markers={'s','d','o'};
        analysisIncluded=~ismember(string(ids),string(paperPeakAllExcludedIDs));
        if paperShowCalibrationOnly.Value
            activeIDs=string({calPairs([calPairs.ReferenceIndex]>0).PeakID});
            analysisIncluded=analysisIncluded&ismember(string(ids),activeIDs);
        end
        visible=[paperShowDirect.Value paperShowInterpolated.Value paperShowCentroid.Value];plotted=false;
        for jj=1:3
            if ~visible(jj),continue;end
            good=isfinite(wavelength)&isfinite(delta(:,jj))&analysisIncluded;source=find(good);
            [xx,order]=sort(wavelength(good));source=source(order);yy=delta(source,jj);
            if isempty(source),continue;end
            h=plot(axPaperAllPeakDifferences,xx,yy,markers{jj},'LineStyle','none','MarkerSize',6, ...
                'MarkerEdgeColor',colors{jj},'MarkerFaceColor',colors{jj},'Color',colors{jj},'DisplayName',names{jj}, ...
                'ButtonDownFcn',@paperPeakDifferencePointClicked);
            h.UserData=struct('IDs',{ids(source)},'Wavelength',xx,'Difference',yy);
            try
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Peak ID',ids(source));
                h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Difference (pixel)',yy);
            catch
            end
            plotted=true;
        end
        yline(axPaperAllPeakDifferences,0,'-','Color',C.gray,'HandleVisibility','off');
        highlightDelta=delta;highlightDelta(:,~visible)=NaN;highlightDelta(~analysisIncluded,:)=NaN;
        drawPaperPeakHighlight(axPaperAllPeakDifferences,ids,wavelength,highlightDelta);
        hold(axPaperAllPeakDifferences,'off');grid(axPaperAllPeakDifferences,'on');grid(axPaperAllPeakDifferences,'minor');
        xlabel(axPaperAllPeakDifferences,'Calibrated FWHM-center wavelength (nm)');
        ylabel(axPaperAllPeakDifferences,'Position difference relative to FWHM center (pixel)');
        available=sum(any(isfinite(delta),2)&isfinite(wavelength));
        displayed=sum(any(isfinite(delta),2)&isfinite(wavelength)&analysisIncluded);
        title(axPaperAllPeakDifferences,sprintf('Detected-peak position differences | %d displayed of %d valid (%d detected)',displayed,available,n));
        if plotted,legend(axPaperAllPeakDifferences,'Location','best','Interpreter','none');else,showNoStatistics(axPaperAllPeakDifferences,'Analyze detected peaks before refreshing');end
        refreshPaperAllPeakTable(ids,wavelength,delta);
    end

    function paperPeakSeriesChanged(~,~)
        if finalModel.valid,drawPaperAllPeakDifferences();end
    end

    function clearPaperPeakHighlight(~,~)
        paperPeakDifferenceSelectedID='';
        if finalModel.valid,drawPaperAllPeakDifferences();drawPaperBenchmarkAxes();end
    end

    function drawPaperBenchmarkDifference
        valid=find([calPairs.ReferenceIndex]>0&isfinite([calPairs.ReferenceWavelength]));
        n=numel(valid);ids=cell(n,1);wavelength=nan(n,1);center=nan(n,1);
        direct=nan(n,1);interpolated=nan(n,1);centroid=nan(n,1);
        for kk=1:n
            q=calPairs(valid(kk));ids{kk}=q.PeakID;wavelength(kk)=q.ReferenceWavelength;
            center(kk)=pairPeakPosition(q,'FWHM center');direct(kk)=pairPeakPosition(q,'Direct peak');
            interpolated(kk)=pairPeakPosition(q,'Interpolated peak');centroid(kk)=pairPeakPosition(q,'Centroid');
        end
        [position,differenceLabel,positionLabel,differenceIndex]=paperSelectedFitSeries(direct,interpolated,centroid);
        good=isfinite(wavelength)&isfinite(center)&isfinite(position);
        ids=ids(good);wavelength=wavelength(good);center=center(good);direct=direct(good);
        interpolated=interpolated(good);centroid=centroid(good);position=position(good);
        [wavelength,order]=sort(wavelength);ids=ids(order);center=center(order);direct=direct(order);
        interpolated=interpolated(order);centroid=centroid(order);position=position(order);
        delta=position-center;included=~ismember(string(ids),string(paperPeakDifferenceExcludedIDs));
        prediction=nan(size(delta));residual=nan(size(delta));fit=struct();
        if ~strcmp(paperPeakDifferenceFitOrder.Value,'No fit')
            degree=str2double(regexprep(paperPeakDifferenceFitOrder.Value,'\D',''));
            if sum(included)>=degree+1&&numel(unique(wavelength(included)))>=degree+1
                fit=wc4sm_fit_peak_position_difference(wavelength,delta,included,degree);
                prediction=fit.Prediction;residual=fit.Residual;
            end
        end
        paperPeakDifferenceResult=struct('PeakID',{ids},'ReferenceWavelength',wavelength,'FWHMCenter',center, ...
            'Direct',direct,'Interpolated',interpolated,'Centroid',centroid,'SelectedPosition',position, ...
            'Difference',delta,'DifferenceLabel',differenceLabel,'PositionLabel',positionLabel, ...
            'DifferenceIndex',differenceIndex,'Included',included,'Prediction',prediction,'Residual',residual,'Fit',fit);
        drawPaperBenchmarkAxes();
        data=cell(numel(ids),7);
        for kk=1:numel(ids)
            if included(kk),status='Calibration';else,status='Temporary delete';end
            data(kk,:)={included(kk),ids{kk},wavelength(kk),center(kk),position(kk),delta(kk),status};
        end
        paperCalibrationPeakTable.ColumnName={'Fit','Peak','Ref. nm','FWHM px',[positionLabel ' px'],'Delta px','State'};
        paperCalibrationPeakTable.Data=data;
    end

    function [position,differenceLabel,positionLabel,differenceIndex]=paperSelectedFitSeries(direct,interpolated,centroid)
        switch paperPeakDifferenceFitSeries.Value
            case 'Direct - FWHM center'
                position=direct;differenceLabel='Direct - FWHM center';positionLabel='Direct';differenceIndex=1;
            case 'Interpolated - FWHM center'
                position=interpolated;differenceLabel='Interpolated - FWHM center';positionLabel='Interp.';differenceIndex=2;
            otherwise
                position=centroid;differenceLabel='Centroid - FWHM center';positionLabel='Centroid';differenceIndex=3;
        end
        position=position(:);
    end

    function drawPaperBenchmarkAxes
        cla(axPaperCentroidDifference,'reset');styleAxes(axPaperCentroidDifference,C);
        if isempty(fieldnames(paperPeakDifferenceResult))||~isfield(paperPeakDifferenceResult,'Difference')
            showNoStatistics(axPaperCentroidDifference,'No common matched FWHM-center/Centroid data');return;
        end
        r=paperPeakDifferenceResult;included=r.Included;excluded=~included;
        hold(axPaperCentroidDifference,'on');
        [allIDs,allWavelength,allDelta]=paperAllPeakArrays();
        differenceIndex=r.DifferenceIndex;differenceLabel=r.DifferenceLabel;
        other=isfinite(allWavelength)&isfinite(allDelta(:,differenceIndex))&~ismember(string(allIDs),string(r.PeakID)) ...
            &~ismember(string(allIDs),string(paperPeakAllExcludedIDs));
        if any(other)
            hg=plot(axPaperCentroidDifference,allWavelength(other),allDelta(other,differenceIndex),'d','LineStyle','none', ...
                'MarkerSize',5,'MarkerEdgeColor',[.48 .48 .48],'MarkerFaceColor',[.72 .72 .72],'Color',[.55 .55 .55], ...
                'DisplayName','Outside current calibration set','ButtonDownFcn',@paperPeakDifferencePointClicked);
            hg.UserData=struct('IDs',{allIDs(other)},'Wavelength',allWavelength(other),'Difference',allDelta(other,differenceIndex));
        end
        h=plot(axPaperCentroidDifference,r.ReferenceWavelength(included),r.Difference(included),'o','LineStyle','none', ...
            'MarkerSize',6,'MarkerEdgeColor',C.purple,'MarkerFaceColor',C.purple,'Color',C.purple,'DisplayName','Included benchmark peaks', ...
            'ButtonDownFcn',@paperPeakDifferencePointClicked);
        h.UserData=struct('IDs',{r.PeakID(included)},'Wavelength',r.ReferenceWavelength(included),'Difference',r.Difference(included));
        try
            h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Peak ID',r.PeakID(included));
            h.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Difference (pixel)',r.Difference(included));
        catch
        end
        if any(excluded)
            hx=plot(axPaperCentroidDifference,r.ReferenceWavelength(excluded),r.Difference(excluded),'x','LineStyle','none', ...
                'MarkerSize',7,'LineWidth',1.3,'Color',C.red,'DisplayName','Excluded from fit','ButtonDownFcn',@paperPeakDifferencePointClicked);
            hx.UserData=struct('IDs',{r.PeakID(excluded)},'Wavelength',r.ReferenceWavelength(excluded),'Difference',r.Difference(excluded));
        end
        if isstruct(r.Fit)&&isfield(r.Fit,'FitX')
            plot(axPaperCentroidDifference,r.Fit.FitX,r.Fit.FitY,'--','Color',C.red,'LineWidth',1.1, ...
                'DisplayName',sprintf('Degree %d fit',r.Fit.Degree));
            sigma=std(r.Fit.FitResidual,0);
            if isfinite(sigma)&&sigma>0
                plot(axPaperCentroidDifference,r.Fit.FitX,r.Fit.FitY+2*sigma,'--','Color',C.orange,'LineWidth',0.9,'DisplayName','+/-2 STD');
                plot(axPaperCentroidDifference,r.Fit.FitX,r.Fit.FitY-2*sigma,'--','Color',C.orange,'LineWidth',0.9,'HandleVisibility','off');
                plot(axPaperCentroidDifference,r.Fit.FitX,r.Fit.FitY+3*sigma,'-.','Color',C.cyan,'LineWidth',0.9,'DisplayName','+/-3 STD');
                plot(axPaperCentroidDifference,r.Fit.FitX,r.Fit.FitY-3*sigma,'-.','Color',C.cyan,'LineWidth',0.9,'HandleVisibility','off');
            end
            equation=poly2str(r.Fit.Coefficients,'z');
            eq=sprintf('Delta p = %s\nd%d | RMS = %.6g pixel | R^2 = %.5f | n = %d\nz = (lambda - %.8g) / %.8g', ...
                equation,r.Fit.Degree,r.Fit.RMSE,r.Fit.RSquared,r.Fit.N,r.Fit.Mu(1),r.Fit.Mu(2));
            text(axPaperCentroidDifference,.02,.97,eq,'Units','normalized','VerticalAlignment','top', ...
                'Color',C.red,'BackgroundColor','white','Margin',3,'FontWeight','bold','Interpreter','none');
        end
        yline(axPaperCentroidDifference,0,'-','Color',C.gray,'HandleVisibility','off');
        drawPaperPeakHighlight(axPaperCentroidDifference,r.PeakID,r.ReferenceWavelength,r.Difference);
        hold(axPaperCentroidDifference,'off');grid(axPaperCentroidDifference,'on');grid(axPaperCentroidDifference,'minor');
        xlabel(axPaperCentroidDifference,'Reference wavelength (nm)');ylabel(axPaperCentroidDifference,[differenceLabel ' (pixel)']);
        displayedAll=sum(isfinite(allDelta(:,differenceIndex))&~ismember(string(allIDs),string(paperPeakAllExcludedIDs)));
        title(axPaperCentroidDifference,sprintf('%s | displayed valid %d | calibration %d | fit %d | temporary delete %d',differenceLabel,displayedAll,numel(included),sum(included),sum(excluded)));
        legend(axPaperCentroidDifference,'Location','best','Interpreter','none');
        if isstruct(r.Fit)&&isfield(r.Fit,'RMSE')
            paperPeakDifferenceStatus.Text=sprintf('%s versus wavelength. Benchmark N=%d, fit N=%d, degree %d, RMS %.6g pixel.', ...
                differenceLabel,numel(included),r.Fit.N,r.Fit.Degree,r.Fit.RMSE);
        else
            paperPeakDifferenceStatus.Text=sprintf('Benchmark N=%d, included=%d. Select degree 1..3 to fit; unchecked rows remain visible but are excluded.',numel(included),sum(included));
        end
        paperPeakDifferenceStatus.Tooltip=paperPeakDifferenceStatus.Text;
    end

    function paperPeakDifferenceFitChanged(~,~)
        if finalModel.valid,drawPaperBenchmarkDifference();end
    end

    function [ids,wavelength,delta]=paperAllPeakArrays
        n=numel(peaks);ids=cell(n,1);wavelength=nan(n,1);delta=nan(n,3);
        for kk=1:n
            ids{kk}=peaks(kk).ID;rr=peaks(kk).Result;
            if isempty(rr)||~isstruct(rr)||~isfield(rr,'CenterX')||~isfinite(rr.CenterX),continue;end
            wavelength(kk)=evaluateWavelengthModel(finalModel,rr.CenterX);
            q=find(strcmp({calPairs.PeakID},ids{kk})&[calPairs.ReferenceIndex]>0,1);
            if isempty(q)
                q=find(strcmp({paperPeakPairArchive.PeakID},ids{kk})&[paperPeakPairArchive.ReferenceIndex]>0,1,'last');
                if ~isempty(q),wavelength(kk)=paperPeakPairArchive(q).ReferenceWavelength;end
            else
                wavelength(kk)=calPairs(q).ReferenceWavelength;
            end
            if isfield(rr,'DirectPeakX'),delta(kk,1)=rr.DirectPeakX-rr.CenterX;end
            if isfield(rr,'InterpolatedPeakX'),delta(kk,2)=rr.InterpolatedPeakX-rr.CenterX;end
            if isfield(rr,'CentroidX'),delta(kk,3)=rr.CentroidX-rr.CenterX;end
        end
    end

    function archiveCurrentPaperCalibrationPairs
        for kk=1:numel(calPairs)
            q=calPairs(kk);if q.ReferenceIndex<=0||~isfinite(q.ReferenceWavelength),continue;end
            duplicate=find(strcmp({paperPeakPairArchive.PeakID},q.PeakID)&[paperPeakPairArchive.ReferenceIndex]==q.ReferenceIndex,1);
            if isempty(duplicate),paperPeakPairArchive(end+1)=q;else,paperPeakPairArchive(duplicate)=q;end
        end
    end

    function refreshPaperAllPeakTable(ids,wavelength,delta)
        available=isfinite(wavelength)&any(isfinite(delta),2);rows=find(available);data=cell(numel(rows),8);
        activeIDs=string({calPairs([calPairs.ReferenceIndex]>0).PeakID});archiveIDs=string({paperPeakPairArchive.PeakID});
        for jj=1:numel(rows)
            kk=rows(jj);id=ids{kk};isActive=any(activeIDs==string(id));isTemporary=isActive&&any(string(paperPeakDifferenceExcludedIDs)==string(id));
            isArchived=any(archiveIDs==string(id));show=~any(string(paperPeakAllExcludedIDs)==string(id));
            if ~show,status='Analysis excluded';elseif isTemporary,status='Temporary delete';elseif isActive,status='Calibration';elseif isArchived,status='Removed / archived';else,status='Unmatched';end
            data(jj,:)={show,id,wavelength(kk),delta(kk,1),delta(kk,2),delta(kk,3),status,~isActive&&isArchived};
        end
        paperAllPeakTable.Data=data;paperAllPeakTable.UserData=struct('SourceRows',rows,'PeakIDs',{ids(rows)});
        displayed=sum(~ismember(string(ids(rows)),string(paperPeakAllExcludedIDs)));
        peakDifferenceAllLabel.Text=sprintf('All valid analyzed peaks: %d | shown %d | calibration %d | temporary %d',numel(rows),displayed,sum(ismember(string(ids(rows)),activeIDs)),numel(paperPeakDifferenceExcludedIDs));
    end

    function paperAllPeakTableEdited(~,event)
        if isempty(event.Indices)||event.Indices(2)~=1||~isstruct(paperAllPeakTable.UserData),return;end
        ids=paperAllPeakTable.UserData.PeakIDs;row=event.Indices(1);if row>numel(ids),return;end
        id=ids{row};
        if logical(event.NewData)
            paperPeakAllExcludedIDs=paperPeakAllExcludedIDs(string(paperPeakAllExcludedIDs)~=string(id));
        elseif ~any(string(paperPeakAllExcludedIDs)==string(id))
            paperPeakAllExcludedIDs{end+1}=id;
        end
        if any(string(paperPeakAllExcludedIDs)==string(paperPeakDifferenceSelectedID)),paperPeakDifferenceSelectedID='';end
        drawPaperAllPeakDifferences();drawPaperBenchmarkAxes();
    end

    function paperAllPeakTableSelected(~,event)
        if isempty(event.Indices)||~isstruct(paperAllPeakTable.UserData),paperPeakAllSelectedRows=[];return;end
        paperPeakAllSelectedRows=unique(event.Indices(:,1));ids=paperAllPeakTable.UserData.PeakIDs;
        row=paperPeakAllSelectedRows(1);if row<=numel(ids),togglePaperPeakHighlight(ids{row});end
    end

    function paperCalibrationTableSelected(~,event)
        if isempty(event.Indices),paperPeakCalibrationSelectedRows=[];return;end
        paperPeakCalibrationSelectedRows=unique(event.Indices(:,1));
        row=paperPeakCalibrationSelectedRows(1);if row<=numel(paperPeakDifferenceResult.PeakID),togglePaperPeakHighlight(paperPeakDifferenceResult.PeakID{row});end
    end

    function paperCalibrationTableEdited(~,event)
        if isempty(event.Indices)||event.Indices(2)~=1||isempty(fieldnames(paperPeakDifferenceResult)),return;end
        row=event.Indices(1);if row>numel(paperPeakDifferenceResult.PeakID),return;end
        id=paperPeakDifferenceResult.PeakID{row};
        if logical(event.NewData)
            paperPeakDifferenceExcludedIDs=paperPeakDifferenceExcludedIDs(string(paperPeakDifferenceExcludedIDs)~=string(id));
        elseif ~any(string(paperPeakDifferenceExcludedIDs)==string(id))
            paperPeakDifferenceExcludedIDs{end+1}=id;
        end
        paperPeakDifferenceSelectedID=id;drawPaperAllPeakDifferences();drawPaperBenchmarkDifference();
    end

    function paperAddSelectedPeak(~,~)
        if isempty(paperPeakAllSelectedRows)||~isstruct(paperAllPeakTable.UserData),uialert(fig,'Select one or more rows in the all-peak table first.','No peak selected');return;end
        ids=paperAllPeakTable.UserData.PeakIDs;rows=paperPeakAllSelectedRows(paperPeakAllSelectedRows<=numel(ids));selectedIDs=string(ids(rows));
        archiveIDs=string({paperPeakPairArchive.PeakID});added=0;notAvailable=strings(0,1);
        for jj=1:numel(selectedIDs)
            qidx=find(archiveIDs==selectedIDs(jj),1,'last');
            if isempty(qidx),notAvailable(end+1)=selectedIDs(jj);continue;end %#ok<AGROW>
            q=paperPeakPairArchive(qidx);calPairs=removePairByPeakOrReference(calPairs,q.PeakID,q.ReferenceIndex);calPairs(end+1)=q;added=added+1;
        end
        if added>0
            paperPeakDifferenceExcludedIDs=paperPeakDifferenceExcludedIDs(~ismember(string(paperPeakDifferenceExcludedIDs),selectedIDs));
            if sum([calPairs.ReferenceIndex]>0)>=2,buildInitialCalibration([],[]);else,refreshCalibration();end
            drawPaperAllPeakDifferences();drawPaperBenchmarkDifference();
        end
        if ~isempty(notAvailable),uialert(fig,['No archived reference pairing is available for: ' strjoin(cellstr(notAvailable),', ') '. Pair these peaks in Wavelength Matching first.'],'Cannot add unmatched peaks');end
        topStatus.Text=sprintf('Peak-difference dataset: %d archived peak(s) added to the calibration set.',added);
    end

    function paperConfirmDeletePeaks(~,~)
        activeIDs=string({calPairs.PeakID});deleteIDs=intersect(activeIDs,string(paperPeakDifferenceExcludedIDs),'stable');
        if isempty(deleteIDs),uialert(fig,'Uncheck Fit for one or more calibration rows before confirming deletion.','No temporary deletion');return;end
        choice=uiconfirm(fig,sprintf('Remove %d temporarily deleted peak(s) from the current calibration set? Their reference pairings will remain archived for restoration.',numel(deleteIDs)), ...
            'Confirm calibration-set deletion','Options',{'Confirm delete','Cancel'},'DefaultOption',2,'CancelOption',2);
        if ~strcmp(choice,'Confirm delete'),return;end
        archiveCurrentPaperCalibrationPairs();calPairs=calPairs(~ismember(string({calPairs.PeakID}),deleteIDs));
        paperPeakDifferenceExcludedIDs=paperPeakDifferenceExcludedIDs(~ismember(string(paperPeakDifferenceExcludedIDs),deleteIDs));
        selectedPairRow=0;if sum([calPairs.ReferenceIndex]>0)>=2,buildInitialCalibration([],[]);else,provisional=emptyInitialModel();refreshCalibration();end
        drawPaperAllPeakDifferences();drawPaperBenchmarkDifference();
        topStatus.Text=sprintf('%d peak(s) removed from the current calibration set; refit the final calibration model when ready.',numel(deleteIDs));
    end

    function togglePaperPeakHighlight(id)
        if string(paperPeakDifferenceSelectedID)==string(id),paperPeakDifferenceSelectedID='';else,paperPeakDifferenceSelectedID=char(string(id));end
        drawPaperAllPeakDifferences();drawPaperBenchmarkAxes();
    end

    function paperPeakDifferenceTableEdited(~,event)
        if isempty(event.Indices)||event.Indices(2)~=1||isempty(fieldnames(paperPeakDifferenceResult)),return;end
        row=event.Indices(1);if row<1||row>numel(paperPeakDifferenceResult.PeakID),return;end
        id=paperPeakDifferenceResult.PeakID{row};
        if logical(event.NewData)
            keep=string(paperPeakDifferenceExcludedIDs)~=string(id);
            paperPeakDifferenceExcludedIDs=paperPeakDifferenceExcludedIDs(keep);
        elseif ~any(string(paperPeakDifferenceExcludedIDs)==string(id))
            paperPeakDifferenceExcludedIDs{end+1}=id;
        end
        paperPeakDifferenceSelectedID=id;drawPaperBenchmarkDifference();
    end

    function paperPeakDifferenceTableSelected(~,event)
        if isempty(event.Indices)||isempty(fieldnames(paperPeakDifferenceResult)),return;end
        row=event.Indices(1);if row<1||row>numel(paperPeakDifferenceResult.PeakID),return;end
        paperPeakDifferenceSelectedID=paperPeakDifferenceResult.PeakID{row};
        drawPaperAllPeakDifferences();drawPaperBenchmarkAxes();
    end

    function paperPeakDifferencePointClicked(source,event)
        if ~isstruct(source.UserData)||~isfield(source.UserData,'IDs')||isempty(source.UserData.IDs),return;end
        point=event.IntersectionPoint;xx=source.XData(:);yy=source.YData(:);
        sx=max(max(xx)-min(xx),eps);sy=max(max(yy)-min(yy),eps);
        [~,q]=min(((xx-point(1))/sx).^2+((yy-point(2))/sy).^2);
        togglePaperPeakHighlight(source.UserData.IDs{q});
    end

    function drawPaperPeakHighlight(ax,ids,wavelength,delta)
        if isempty(paperPeakDifferenceSelectedID),return;end
        q=find(string(ids)==string(paperPeakDifferenceSelectedID),1);
        if isempty(q)||~isfinite(wavelength(q)),return;end
        values=delta(q,:);values=values(isfinite(values));if isempty(values),return;end
        plot(ax,repmat(wavelength(q),size(values)),values,'o','LineStyle','-','MarkerSize',9,'LineWidth',1.4, ...
            'MarkerFaceColor',C.yellow,'MarkerEdgeColor',C.red,'Color',C.red,'HandleVisibility','off');
        text(ax,wavelength(q),values(end),['  ' paperPeakDifferenceSelectedID],'Color',C.red,'FontWeight','bold','Interpreter','none');
    end

    function restorePaperPeakDifferenceRows(~,~)
        paperPeakDifferenceExcludedIDs={};paperPeakDifferenceSelectedID='';
        if finalModel.valid,drawPaperAllPeakDifferences();drawPaperBenchmarkDifference();end
    end

    function exportPaperPeakDifferenceTable(~,~)
        if isempty(fieldnames(paperPeakDifferenceResult))||~isfield(paperPeakDifferenceResult,'PeakID')
            uialert(fig,'Refresh the wavelength-dependent peak-position page before exporting.','No data');return;
        end
        r=paperPeakDifferenceResult;
        T=table(string(r.PeakID(:)),r.ReferenceWavelength(:),r.FWHMCenter(:),r.Direct(:),r.Interpolated(:),r.Centroid(:), ...
            r.Direct(:)-r.FWHMCenter(:),r.Interpolated(:)-r.FWHMCenter(:),r.Centroid(:)-r.FWHMCenter(:), ...
            repmat(string(r.DifferenceLabel),numel(r.PeakID),1),r.Difference(:),logical(r.Included(:)),r.Prediction(:),r.Residual(:), ...
            'VariableNames',{'PeakID','ReferenceWavelength_nm','FWHMCenter_pixel','Direct_pixel','Interpolated_pixel','Centroid_pixel', ...
            'DirectMinusFWHMCenter_pixel','InterpolatedMinusFWHMCenter_pixel','CentroidMinusFWHMCenter_pixel', ...
            'SelectedDifferenceType','SelectedDifference_pixel','IncludedInFit','FittedDifference_pixel','FitResidual_pixel'});
        [fn,pn]=uiputfile('WCC4SM_peak_position_differences_vs_wavelength.csv','Export peak-position difference table');
        if isequal(fn,0),return;end
        writetable(T,fullfile(pn,fn));topStatus.Text='Peak-position wavelength-dependence table exported';
    end

    function plotCalibratedPerformance(~,~)
        if ~finalModel.valid
            uialert(fig,'Fit a final calibration model before drawing wavelength-domain performance.','No final calibration model');
            return;
        end
        confirmed=false(1,numel(peakDataset));
        if ~isempty(peakDataset),confirmed=[peakDataset.Confirmed];end
        rows=find(confirmed);
        if isempty(rows)
            uialert(fig,'No confirmed peak snapshots are available.','No confirmed peaks');
            return;
        end

        n=numel(rows);confirmedResults=cell(n,1);
        for jj=1:n
            confirmedResults{jj}=peakDataset(rows(jj)).AnalysisResult;
        end
        calibratedPerformance=wc4sm_calculate_calibrated_performance( ...
            finalModel,confirmedResults,D.pixel(:));
        centerNm=calibratedPerformance.CenterWavelength_nm;
        fwhmNm=calibratedPerformance.FWHM_nm;
        erwNm=calibratedPerformance.ERW_nm;

        cla(axCalWidthTrend,'reset');styleAxes(axCalWidthTrend,C);hold(axCalWidthTrend,'on');
        goodF=isfinite(centerNm)&isfinite(fwhmNm);goodE=isfinite(centerNm)&isfinite(erwNm);
        if any(goodF),plot(axCalWidthTrend,centerNm(goodF),fwhmNm(goodF),'o-','Color',C.blue,'LineWidth',1.5,'MarkerFaceColor','white','DisplayName','FWHM');end
        if any(goodE),plot(axCalWidthTrend,centerNm(goodE),erwNm(goodE),'o-','Color',C.orange,'LineWidth',1.5,'MarkerFaceColor','white','DisplayName','ERW');end
        xlabel(axCalWidthTrend,'Calibrated peak-center wavelength (nm)');ylabel(axCalWidthTrend,'Width (nm)');
        title(axCalWidthTrend,sprintf('Wavelength-domain FWHM and ERW (%d confirmed peaks)',n));grid(axCalWidthTrend,'on');grid(axCalWidthTrend,'minor');
        if any(goodF)|any(goodE),legend(axCalWidthTrend,'Location','best');else,showNoStatistics(axCalWidthTrend,'No valid wavelength-domain widths');end

        cla(axCalWidthRelation,'reset');styleAxes(axCalWidthRelation,C);
        good=isfinite(fwhmNm)&isfinite(erwNm);
        if any(good)
            plot(axCalWidthRelation,fwhmNm(good),erwNm(good),'o','LineStyle','none','Color',C.purple,'MarkerFaceColor',C.cyan,'DisplayName','Confirmed peaks');
            hold(axCalWidthRelation,'on');
            if all(isfinite(calibratedPerformance.WidthRelation.Coefficients))
                fitCoef=calibratedPerformance.WidthRelation.Coefficients;
                rSquared=calibratedPerformance.WidthRelation.RSquared;
                fitX=linspace(min(fwhmNm(good)),max(fwhmNm(good)),100);
                plot(axCalWidthRelation,fitX,polyval(fitCoef,fitX),'-','Color',C.red,'LineWidth',1.8,'DisplayName','Linear fit');
                text(axCalWidthRelation,.04,.96,sprintf('ERW = %.4f FWHM %+.4f nm\nR^2 = %.4f',fitCoef(1),fitCoef(2),rSquared), ...
                    'Units','normalized','VerticalAlignment','top','Color',C.red,'FontWeight','bold','BackgroundColor','white','Margin',4);
                legend(axCalWidthRelation,'Location','southeast');
            end
            hold(axCalWidthRelation,'off');xlabel(axCalWidthRelation,'FWHM (nm)');ylabel(axCalWidthRelation,'ERW (nm)');
            title(axCalWidthRelation,sprintf('FWHM versus ERW (n = %d)',sum(good)));grid(axCalWidthRelation,'on');grid(axCalWidthRelation,'minor');
        else
            showNoStatistics(axCalWidthRelation,'No complete wavelength-domain width data');
        end

        cla(axCalPositionDelta,'reset');styleAxes(axCalPositionDelta,C);
        validFwhm=fwhmNm(isfinite(fwhmNm)&fwhmNm>0);
        if ~isempty(validFwhm)
            nFwhm=numel(validFwhm);
            [fwhmLo,fwhmHi,nBins]=fwhmHistogramSettings(validFwhm);
            h=histogram(axCalPositionDelta,validFwhm,'NumBins',nBins,'BinLimits',[fwhmLo fwhmHi], ...
                'FaceColor',C.blue,'FaceAlpha',0.72,'EdgeColor','white');
            fwhmSummary=calibratedPerformance.FWHMStatistics;
            meanFwhm=fwhmSummary.Mean;medianFwhm=fwhmSummary.Median;stdFwhm=fwhmSummary.STD;
            minFwhm=fwhmSummary.Minimum;maxFwhm=fwhmSummary.Maximum;
            shownCount=sum(validFwhm>=fwhmLo&validFwhm<=fwhmHi);
            if shownCount>0
                [~,modalIndex]=max(h.Values);
                modalLow=h.BinEdges(modalIndex);modalHigh=h.BinEdges(modalIndex+1);
                modalText=sprintf('Modal bin = %.4g-%.4g nm',modalLow,modalHigh);
            else
                modalText='Modal bin = -- (no data in manual range)';
            end
            hold(axCalPositionDelta,'on');
            xline(axCalPositionDelta,meanFwhm,'--',sprintf('Mean %.4g nm',meanFwhm),'Color',C.red,'LineWidth',1.5);
            xline(axCalPositionDelta,medianFwhm,':',sprintf('Median %.4g nm',medianFwhm),'Color',C.purple,'LineWidth',1.8);
            text(axCalPositionDelta,.98,.96,sprintf(['N = %d\nMean = %.4g nm\nMedian = %.4g nm\nSTD = %.4g nm\n' ...
                'Range = %.4g-%.4g nm\nDisplayed = %d\n%s'], ...
                nFwhm,meanFwhm,medianFwhm,stdFwhm,minFwhm,maxFwhm,shownCount,modalText), ...
                'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top', ...
                'Color',C.navy,'FontWeight','bold','BackgroundColor','white','Margin',4);
            hold(axCalPositionDelta,'off');
            xlabel(axCalPositionDelta,'FWHM (nm)');ylabel(axCalPositionDelta,'Count');
            title(axCalPositionDelta,sprintf('FWHM distribution (N = %d, displayed = %d, %d bins)',nFwhm,shownCount,nBins));
            grid(axCalPositionDelta,'on');grid(axCalPositionDelta,'minor');
        else
            showNoStatistics(axCalPositionDelta,'No valid wavelength-domain FWHM values');
        end

        cla(axPixelInterval,'reset');styleAxes(axPixelInterval,C);
        intervalNm=calibratedPerformance.PixelInterval_nm;
        intervalWavelength=calibratedPerformance.IntervalWavelength_nm;
        goodInterval=calibratedPerformance.ValidPixelInterval;
        if any(goodInterval)
            plot(axPixelInterval,intervalWavelength(goodInterval),intervalNm(goodInterval),'-','Color',C.purple,'LineWidth',1.6);
            intervalSummary=calibratedPerformance.PixelIntervalStatistics;
            meanInterval=intervalSummary.Mean;minInterval=intervalSummary.Minimum;maxInterval=intervalSummary.Maximum;
            yline(axPixelInterval,meanInterval,'--',sprintf('Mean %.6g nm/pixel',meanInterval),'Color',C.red);
            xlabel(axPixelInterval,'Calibrated wavelength (nm)');ylabel(axPixelInterval,'Pixel wavelength interval (nm/pixel)');
            title(axPixelInterval,sprintf('Pixel wavelength interval | mean %.6g | min %.6g | max %.6g nm/pixel',meanInterval,minInterval,maxInterval));
            grid(axPixelInterval,'on');grid(axPixelInterval,'minor');
        else
            showNoStatistics(axPixelInterval,'Calibration model does not give positive pixel intervals');
        end
        plotTabs.SelectedTab=tabCalibratedStatistics;
        calibratedStatsTabs.SelectedTab=calibratedOverviewTab;
        topStatus.Text='Calibrated wavelength-domain performance refreshed';
    end

    function fwhmHistogramControlsChanged(~,~)
        if ~finalModel.valid
            topStatus.Text='FWHM histogram settings saved; fit a final model to draw the histogram';
            return;
        end
        if strcmp(fwhmHistRangeMode.Value,'Manual')&&fwhmHistXMax.Value<=fwhmHistXMin.Value
            uialert(fig,'FWHM histogram X max must be greater than X min.','Invalid FWHM histogram range');
            return;
        end
        plotCalibratedPerformance([],[]);
    end

    function [lo,hi,nb]=fwhmHistogramSettings(values)
        nb=max(1,min(100,round(fwhmHistBinCount.Value)));
        if strcmp(fwhmHistRangeMode.Value,'Manual')
            lo=fwhmHistXMin.Value;
            hi=fwhmHistXMax.Value;
            if ~isfinite(lo)||~isfinite(hi)||hi<=lo
                lo=min(values);hi=max(values);
            end
        else
            lo=min(values);hi=max(values);
            if hi<=lo
                pad=max(0.01,abs(lo)*0.05);
                lo=lo-pad;hi=hi+pad;
            else
                pad=0.02*(hi-lo);
                lo=lo-pad;hi=hi+pad;
            end
            fwhmHistXMin.Value=lo;
            fwhmHistXMax.Value=hi;
        end
    end

    function showNoStatistics(ax,message)
        title(ax,message);xlabel(ax,'');ylabel(ax,'');grid(ax,'off');
        text(ax,.5,.5,message,'Units','normalized','HorizontalAlignment','center','Color',C.muted,'FontWeight','bold');
    end

    function popOutSpectrumPlots(~,~)
        pf=figure('Name','WCC4SM V1.0 | Current spectrum plots','Color','white','Position',[100 80 1100 760]);
        t=tiledlayout(pf,2,1,'Padding','compact','TileSpacing','compact');
        if plotTabs.SelectedTab==tabMatchingPlots,s1=axMatchMeasured;s2=axMatchReference;else,s1=axFull;s2=axPeak;end
        a1=nexttile(t);copyAxesState(s1,a1);a2=nexttile(t);copyAxesState(s2,a2);
    end

    function openSelectedTabFigures(~,~)
        tabName=openFigDrop.Value;
        switch tabName
            case 'Peak Analysis'
                if peakAnalysisTabs.SelectedTab==peakGalleryTab
                    refreshPeakGallery();openPeakGalleryFigure();return;
                else
                    sourceAxes=[axFull axPeak];
                end
            case 'Peak Parameter Statistics'
                if peakStatisticsTabs.SelectedTab==peakPositionDifferenceTab
                    sourceAxes=[axPeakDifferenceMap axPeakDifferenceFit axPeakDifferenceDistribution axPeakDifferenceHistogram];
                else
                    sourceAxes=[axWidthTrend axWidthRelation axPositionDelta axPositionHistogram];
                end
            case 'Wavelength Matching'
                sourceAxes=[axMatchMeasured axMatchReference];
            case 'Calibration Fit & Residuals'
                sourceAxes=[axFitResult axResidualResult axHistogramResult];
            case 'Model Validation'
                if validationTabs.SelectedTab==positionCrossValidationTab
                    if isempty(fieldnames(positionCrossResult))
                        uialert(fig,'Run peak-position cross validation before opening these figures.','No cross-validation result');return;
                    end
                    if positionCrossViewTabs.SelectedTab==positionCrossMetricOverviewTab
                        openPositionCrossAxesGrid(positionCrossMetricOverviewAxes,2,3,'All mismatch metrics',true);return;
                    elseif positionCrossViewTabs.SelectedTab==positionCrossRowResidualTab
                        openPositionCrossAxesGrid(positionCrossRowResidualAxes,2,2,'Calibration-row residuals',false);return;
                    elseif positionCrossViewTabs.SelectedTab==positionCrossHistogramOverviewTab
                        overviewHistogramAxes=reshape(positionCrossHistogramOverviewAxes.',1,[]);
                        openPositionCrossAxesGrid(overviewHistogramAxes,4,4,'All mismatch histograms',false);return;
                    else
                        sourceAxes=[positionCrossHeatmapAxes positionCrossResidualAxes positionCrossHistogramAxes];
                    end
                else
                    sourceAxes=[axLOO axInfluence];
                end
            case 'Model Comparison'
                sourceAxes=axModelCompare;
            case 'Selected Residuals'
                sourceAxes=[axSelectedResidualTrend axSelectedResidualHistogram];
            case 'Calibrated Performance'
                if calibratedStatsTabs.SelectedTab==paperPeakDifferenceTab
                    if isempty(fieldnames(paperPeakDifferenceResult))
                        uialert(fig,'Refresh peak-position wavelength dependence before opening these figures.','No peak-position difference result');return;
                    end
                    sourceAxes=[axPaperAllPeakDifferences axPaperCentroidDifference];
                else
                    sourceAxes=[axCalWidthTrend axCalWidthRelation axCalPositionDelta axPixelInterval];
                end
            case 'Calibration Optimization'
                sourceAxes=optimizationAxes;
            case 'Point Influence'
                if influenceFeatureTabs.SelectedTab==setReplacementTab
                    if ~isstruct(seedComboResult)||~isfield(seedComboResult,'Baseline')
                        uialert(fig,'Run selected-set replacement analysis before opening this figure.','No replacement result');
                        return;
                    end
                    sourceAxes=seedReplacementAxes;
                elseif influenceDiagnosticTabs.SelectedTab==influenceOrderPlotTab
                    if isempty(influenceOrderStats)
                        uialert(fig,'Run the influence order scan before opening Across orders figures.','No order-scan result');
                        return;
                    end
                    sourceAxes=[influenceFullErrorAxes influenceGapAxes influenceDeletionErrorAxes influenceOrderStatsAxes];
                else
                    if isempty(fieldnames(influenceResult))||~isfield(influenceResult,'Points')
                        uialert(fig,'Run sample influence analysis or select an order-scan row first.','No point-influence result');
                        return;
                    end
                    sourceAxes=influenceAxes;
                end
            case 'Set Design'
                if setDesignWorkspaceTabs.SelectedTab==windowPartitionTab
                    if isempty(fieldnames(subsetWindowPartition))||~isfield(subsetWindowPartition,'Windows')
                        uialert(fig,'Generate a Window Partition before opening its figures.','No window partition result');return;
                    end
                    sourceAxes=[windowResidualAxes windowInfluenceAxes];
                else
                    sourceAxes=[setDesignSelectionAxes setDesignResidualAxes];
                end
            otherwise
                uialert(fig,'Select a plot tab first.','Open Fig');
                return;
        end
        for kk=1:numel(sourceAxes)
            plotTitle=axesTitleText(sourceAxes(kk),sprintf('Subplot %d',kk));
            left=80+32*mod(kk-1,5);bottom=80+28*mod(kk-1,5);
            pf=figure('Name',sprintf('WCC4SM V1.0 | %s | %s',tabName,plotTitle), ...
                'NumberTitle','off','Color','white','Position',[left bottom 900 620]);
            targetAxes=axes('Parent',pf,'Position',[.10 .12 .85 .80]);
            copyAxesState(sourceAxes(kk),targetAxes);
        end
        topStatus.Text=sprintf('%s: opened %d editable figure(s)',tabName,numel(sourceAxes));
    end

    function openPositionCrossAxesGrid(sourceAxes,rowCount,columnCount,figureTitle,showColorbars)
        pf=figure('Name',sprintf('WCC4SM V1.0 | Model Validation | %s',figureTitle), ...
            'NumberTitle','off','Color','white','Position',[35 45 1500 850]);
        layout=tiledlayout(pf,rowCount,columnCount,'Padding','compact','TileSpacing','compact');
        for axesIndex=1:numel(sourceAxes)
            targetAxes=nexttile(layout);copyAxesState(sourceAxes(axesIndex),targetAxes);
            if showColorbars,colorbar(targetAxes);end
        end
        try,sgtitle(layout,figureTitle,'Interpreter','none','FontWeight','bold');catch,end
        topStatus.Text=sprintf('Model Validation: opened %s as one editable %dx%d figure.',figureTitle,rowCount,columnCount);
    end

    function openPeakGalleryFigure
        pf=figure('Name','WCC4SM V1.0 | Peak Analysis | 8x8 peak-shape gallery', ...
            'NumberTitle','off','Color','white','Position',[20 35 1840 980]);
        layout=tiledlayout(pf,8,8,'Padding','compact','TileSpacing','compact');
        for axesIndex=1:64
            targetAxes=nexttile(layout);copyAxesState(peakGalleryAxes(axesIndex),targetAxes);
            targetAxes.FontSize=6;targetAxes.XTick=[];targetAxes.YTick=[];targetAxes.XTickLabel={};targetAxes.YTickLabel={};
        end
        coordinate='natural pixel';if strcmp(mainAxisMode,'Wavelength')&&appliedModel.valid,coordinate='calibrated wavelength';end
        try,sgtitle(layout,sprintf('Detected-peak subwindows | X: %s | blue: matched benchmark | red: not selected',coordinate), ...
                'Interpreter','none','FontWeight','bold');catch,end
        topStatus.Text='Peak Analysis: opened the 8x8 peak-shape gallery as one editable figure.';
    end

    function txt=axesTitleText(source,fallback)
        txt=fallback;
        try
            value=source.Title.String;
            if iscell(value),value=strjoin(string(value),' | ');end
            value=char(string(value));
            if ~isempty(strtrim(value)),txt=value;end
        catch
        end
    end

    function copyAxesState(source,target)
        dualYAxis=false;
        try
            dualYAxis=numel(source.YAxis)>1;
            if dualYAxis,yyaxis(target,'left');yyaxis(target,'right');yyaxis(target,'left');end
        catch
            dualYAxis=false;
        end
        copyobj(allchild(source),target);
        transferable={'XLim','YLim','CLim','XScale','YScale','XDir','YDir','XGrid','YGrid','XMinorGrid','YMinorGrid', ...
            'XTick','YTick','XTickLabel','YTickLabel','Box','Color','FontName','FontSize','LineWidth','ColorOrder'};
        for pp=1:numel(transferable)
            try,target.(transferable{pp})=source.(transferable{pp});catch,end
        end
        try,colormap(target,colormap(source));catch,end
        try,xlabel(target,source.XLabel.String,'Interpreter',source.XLabel.Interpreter);catch,xlabel(target,source.XLabel.String);end
        try,ylabel(target,source.YLabel.String,'Interpreter',source.YLabel.Interpreter);catch,ylabel(target,source.YLabel.String);end
        if dualYAxis
            for rr=1:2
                try,target.YAxis(rr).Limits=source.YAxis(rr).Limits;catch,end
                try,target.YAxis(rr).Scale=source.YAxis(rr).Scale;catch,end
                try,target.YAxis(rr).Color=source.YAxis(rr).Color;catch,end
                try,target.YAxis(rr).TickValues=source.YAxis(rr).TickValues;catch,end
                try,target.YAxis(rr).TickLabels=source.YAxis(rr).TickLabels;catch,end
                try,target.YAxis(rr).Label.String=source.YAxis(rr).Label.String;catch,end
            end
            try,yyaxis(target,'left');catch,end
        end
        try,title(target,source.Title.String,'Interpreter',source.Title.Interpreter);catch,title(target,source.Title.String);end
        try
            names=get(findobj(target,'-property','DisplayName'),'DisplayName');
            if ischar(names),names={names};end
            if any(~cellfun(@isempty,names)),legend(target,'show','Location','best','Interpreter','none');end
        catch
        end
        try,target.Toolbar.Visible='on';catch,end
    end

    %% DRAW AND TABLE HELPERS
    function refreshAll, refreshPeakTable(); refreshDataset(); refreshCalibration(); drawFull(); clearCurrent(); end
    function symmetryThresholdChanged(~,~)
        symmetryThresholdPx=symmetryThreshold.Value;
        refreshPeakTable();
        if selectedRow>0 && selectedRow<=numel(peaks) && ~isempty(peaks(selectedRow).Result),showSelected();end
    end
    function tf=isSymmetryRecommended(id)
        tf=false;k=find(strcmp({peakDataset.PeakID},char(id)) & [peakDataset.Confirmed],1);
        if isempty(k),return;end
        rr=peakDataset(k).AnalysisResult;tf=isfield(rr,'CentroidX')&&isfield(rr,'CenterX')&&isfinite(rr.CentroidX)&&isfinite(rr.CenterX)&&abs(rr.CentroidX-rr.CenterX)<=symmetryThresholdPx;
    end
    function [label,delta]=symmetryRecommendation(rr)
        delta=NaN;label='Unavailable';
        if isfield(rr,'CentroidX')&&isfield(rr,'CenterX')&&isfinite(rr.CentroidX)&&isfinite(rr.CenterX)
            delta=abs(rr.CentroidX-rr.CenterX);if delta<=symmetryThresholdPx,label=sprintf('Recommended (%.3g)',delta);else,label=sprintf('Review (%.3g)',delta);end
        end
    end
    function refreshPeakTable
        dat=cell(numel(peaks),7);
        for i=1:numel(peaks),rec='Unavailable';if ~isempty(peaks(i).Result),[rec,~]=symmetryRecommendation(peaks(i).Result);end;dat(i,:)={peaks(i).ID,peaks(i).Pixel,peaks(i).InputX,peaks(i).Height,peaks(i).Prominence,peaks(i).Width,rec};end
        nConfirmed=0;if ~isempty(peakDataset),nConfirmed=sum([peakDataset.Confirmed]);end
        peakTable.Data=dat; detectInfo.Text=sprintf('Detected: %d | Confirmed: %d',numel(peaks),nConfirmed);
    end
    function refreshDataset
        dat=cell(numel(peakDataset),6);
        for i=1:numel(peakDataset), rr=peakDataset(i).AnalysisResult; dat(i,:)={peakDataset(i).PeakID,peakDataset(i).Pixel,peakDataset(i).ReferenceWavelength,rr.FWHM,rr.ERW,peakDataset(i).Status}; end
        nConfirmed=0;nPositionOnly=0;
        if ~isempty(peakDataset)
            nConfirmed=sum([peakDataset.Confirmed]);
            nPositionOnly=sum([peakDataset.Confirmed] & strcmp({peakDataset.Status},'Confirmed - PositionOnly'));
        end
        nUnconfirmed=numel(peaks)-nConfirmed;
        datasetTable.Data=dat;
        datasetLabel.Text=sprintf('Confirmed %d / %d | PositionOnly %d | Unconfirmed %d',nConfirmed,numel(peaks),nPositionOnly,nUnconfirmed);
        detectInfo.Text=sprintf('Detected: %d | Confirmed: %d',numel(peaks),nConfirmed);
    end
    function refreshCalibration
        if L.loaded
            [st,spacing]=referenceStatuses();
            datRef=wc4sm_format_reference_table(L.effective,L.intensity,L.order,st);
            refTable.Data=datRef;
            lineInfo.Text=sprintf('%d lines | %s',numel(L.wavelength),shortName(L.source));
            active=find(~strcmp(st,'Out of range') & ~strcmp(st,'Disabled'));
            datActive=cell(numel(active),4);
            for jj=1:numel(active),q=active(jj);datActive(jj,:)={L.effective(q),sprintf('%.0f',L.intensity(q)),spacing(q),st{q}};end
            activeRefTable.Data=datActive;
        else
            refTable.Data=zeros(0,4); lineInfo.Text='No reference-line file';
            activeRefTable.Data=cell(0,4);
        end
        confirmedMask=false(1,numel(peakDataset));
        if ~isempty(peakDataset),confirmedMask=[peakDataset.Confirmed];end
        confirmedIDs={peakDataset(confirmedMask).PeakID};
        if isempty(confirmedIDs)
            calPeakDrop.Items={'(none)'}; calPeakDrop.Value='(none)';
        else
            old=calPeakDrop.Value; items=confirmedIDs; calPeakDrop.Items=items;
            if any(strcmp(items,old)),calPeakDrop.Value=old;else,calPeakDrop.Value=items{1};end
        end
        dat=cell(numel(calPairs),7);
        for ii=1:numel(calPairs)
            dat(ii,:)={calPairs(ii).PeakID,calPairs(ii).DetectionPixel,calPairs(ii).ReferenceWavelength, ...
                calPairs(ii).Mode,calPairs(ii).Confidence,logicalText(calPairs(ii).Locked),calPairs(ii).Status};
        end
        pairTable.Data=dat;
        if provisional.valid
            equationLabel.Text=sprintf('Initial model: degree %d | anchors %d | RMS %.5g nm | axis %s', ...
                provisional.Degree,sum([calPairs.ReferenceIndex]>0),initialRMS(),matchingAxisMode);
        else
            equationLabel.Text='Initial model: nominal linear prior (not calibrated)';
        end
        refreshOptimizationSeeds();
        refreshInfluenceTable();
    end
    function [status,spacing]=referenceStatuses
        n=numel(L.effective); status=repmat({'Recommended'},n,1); spacing=nan(n,1);
        if n==0,return;end
        if ~isfield(L,'enabled')||numel(L.enabled)~=n,L.enabled=true(n,1);end
        off=~L.enabled(:);status(off)=repmat({'Disabled'},sum(off),1);
        ids=find(L.enabled(:));
        for jj=1:numel(ids)
            q=ids(jj); others=ids(ids~=q);
            if isempty(others),d=Inf;else,d=min(abs(L.effective(others)-L.effective(q)));end
            spacing(q)=d;
            if d<referenceResolutionNm,status{q}='Unresolved';
            elseif d<1.5*referenceResolutionNm,status{q}='Marginal';
            else,status{q}='Recommended';end
        end
    end
    function ids=usableReferenceIndices
        [st,~]=referenceStatuses(); ids=find(strcmp(st,'Recommended')|strcmp(st,'Marginal'));
    end
    function drawFull
        % Guide lines use hidden handles to stay out of legends. CLA does not
        % reliably remove hidden ConstantLine objects in R2022a, so remove the
        % tagged guides explicitly before every redraw.
        delete(findall(axFull,'Tag','WCC4SMSubwindowGuide'));
        cla(axFull); if isempty(D.raw), return; end
        [x,xlab]=displayX(); [y,ylab]=displayY();
        if strcmp(scaleDrop.Value,'Log'), yplot=y; yplot(yplot<=0)=NaN; axFull.YScale='log'; else, yplot=y; axFull.YScale='linear'; end
        plot(axFull,x,yplot,'-','Color',C.blue,'LineWidth',1.05,'HitTest','off'); hold(axFull,'on');
        if ~isempty(peaks) && refCheck.Value
            for i=1:numel(peaks)
                px=x(peaks(i).Index); py=yplot(peaks(i).Index); col=C.orange;
                if contains(peaks(i).Status,'Locally added'),col=C.green;elseif strcmp(peaks(i).Status,'Excluded'),col=C.gray;end
                plot(axFull,px,py,'v','Color',col,'MarkerFaceColor',col,'MarkerSize',7,'HitTest','off');
                text(axFull,px,py,peaks(i).ID,'FontSize',10,'FontWeight','bold','Color',col,'VerticalAlignment','bottom','HorizontalAlignment','center','HitTest','off');
            end
        end
        if ~isempty(localCandidates)
            for jj=1:numel(localCandidates)
                k=localCandidates(jj).Index;col=C.purple;ms=8;
                if jj==selectedLocalCandidate,col=C.red;ms=10;end
                plot(axFull,x(k),yplot(k),'^','Color',col,'MarkerFaceColor','white','LineWidth',1.6,'MarkerSize',ms,'HitTest','off');
                text(axFull,x(k),yplot(k),sprintf(' C%02d',jj),'FontSize',10,'FontWeight','bold','Color',col, ...
                    'VerticalAlignment','top','HorizontalAlignment','left','HitTest','off');
            end
        end
        if all(isfinite(localSearchWindow))
            markerX=localSearchWindow;
            if strcmp(mainAxisMode,'Wavelength')&&appliedModel.valid
                markerX=evaluateWavelengthModel(appliedModel,markerX);
            end
            xline(axFull,markerX(1),'--','Subwindow start','Color',C.purple,'LineWidth',1.5, ...
                'LabelVerticalAlignment','bottom','HandleVisibility','off','Tag','WCC4SMSubwindowGuide');
            xline(axFull,markerX(2),'--','Subwindow end','Color',C.orange,'LineWidth',1.5, ...
                'LabelVerticalAlignment','bottom','HandleVisibility','off','Tag','WCC4SMSubwindowGuide');
        end
        if selectedRow>0 && selectedRow<=numel(peaks)
            k=peaks(selectedRow).Index; plot(axFull,x(k),yplot(k),'o','Color',C.red,'LineWidth',1.8,'MarkerSize',9,'HitTest','off');
        end
        hold(axFull,'off'); grid(axFull,'on'); xlabel(axFull,xlab); ylabel(axFull,ylab);
        ttl=['Full spectrum | ' shortName(D.source)];
        if strcmp(mainAxisMode,'Wavelength') && ~isempty(appliedModelName), ttl=[ttl ' | ' appliedModelName]; end
        title(axFull,ttl,'Interpreter','none');
        if isfinite(fullViewStart.Value)&&isfinite(fullViewEnd.Value)&&fullViewEnd.Value>fullViewStart.Value
            xlim(axFull,[fullViewStart.Value fullViewEnd.Value]);
        end
    end
    function drawPeak(rr)
        useWavelength=strcmp(mainAxisMode,'Wavelength') && appliedModel.valid;
        if useWavelength
            wx=evaluateWavelengthModel(appliedModel,rr.WindowX);
            ix=evaluateWavelengthModel(appliedModel,rr.InterpX);
            directX=evaluateWavelengthModel(appliedModel,rr.DirectPeakX);
            interpPeakX=evaluateWavelengthModel(appliedModel,rr.InterpolatedPeakX);
            centerX=evaluateWavelengthModel(appliedModel,rr.CenterX);
            centroidX=evaluateWavelengthModel(appliedModel,rr.CentroidX);
            leftX=evaluateWavelengthModel(appliedModel,rr.LeftHalfX);
            rightX=evaluateWavelengthModel(appliedModel,rr.RightHalfX);
            erwLeftX=evaluateWavelengthModel(appliedModel,rr.CentroidX-0.5*rr.ERW);
            erwRightX=evaluateWavelengthModel(appliedModel,rr.CentroidX+0.5*rr.ERW);
            xlab='Calibrated wavelength (nm)';
        else
            wx=rr.WindowX; ix=rr.InterpX; directX=rr.DirectPeakX; interpPeakX=rr.InterpolatedPeakX;
            centerX=rr.CenterX; centroidX=rr.CentroidX; leftX=rr.LeftHalfX; rightX=rr.RightHalfX;
            erwLeftX=rr.CentroidX-0.5*rr.ERW; erwRightX=rr.CentroidX+0.5*rr.ERW;
            xlab='Natural pixel coordinate';
        end
        % Clear every graphics primitive and the previous legend explicitly.
        % This avoids stale quiver/annotation objects on repeated redraws in
        % some UIAxes/MATLAB releases.
        legend(axPeak,'off');
        delete(allchild(axPeak));
        hold(axPeak,'on');

        % Dense interpolated samples are shown as area-bearing bars.  The
        % ERW interval is centred on the centroid; samples inside it are
        % cyan and the two outer wings are yellow.
        barY=max(rr.InterpNetY,0);
        inERW=isfinite(erwLeftX) & isfinite(erwRightX) & ...
            ix>=min(erwLeftX,erwRightX) & ix<=max(erwLeftX,erwRightX);
        wingY=barY; wingY(inERW)=NaN;
        erwY=barY; erwY(~inERW)=NaN;
        hWingBars=bar(axPeak,ix,wingY,1.0,'FaceColor',C.yellow, ...
            'EdgeColor',[0.86 0.69 0.05],'LineWidth',0.25,'FaceAlpha',0.82, ...
            'DisplayName',['Interpolated area - wings (' rr.Settings.InterpolationMethod ')']);
        hErwBars=bar(axPeak,ix,erwY,1.0,'FaceColor',C.sky, ...
            'EdgeColor',[0.10 0.58 0.68],'LineWidth',0.25,'FaceAlpha',0.82, ...
            'DisplayName','Interpolated area - ERW interval');

        % Original samples retain their actual sampling geometry.  The red
        % straight segments are also the visual linear-interpolation
        % reference; selecting "linear" makes every bar top coincide with
        % these segments.
        hRaw=plot(axPeak,wx,rr.NetY,'o-','Color',C.red,'LineWidth',2, ...
            'MarkerSize',12,'MarkerFaceColor',C.yellow,'MarkerEdgeColor',C.red, ...
            'DisplayName','Raw data / linear reference');

        % The baseline used by the analysis is the straight line joining
        % the first and last samples in the selected window.  Because all
        % plotted values are baseline-subtracted, that line appears at y=0.
        hBaseline=yline(axPeak,0,'--','Color',[0.38 0.38 0.38], ...
            'LineWidth',1.0,'DisplayName','Zero baseline (endpoint linear subtraction)');

        hDirect=gobjects(0); hInterp=gobjects(0); hCenter=gobjects(0); hCentroid=gobjects(0);
        if isfinite(directX)
            hDirect=xline(axPeak,directX,'-.','Color',C.red, ...
                'LineWidth',2.0,'DisplayName','Direct sampled peak');
        end
        if isfinite(interpPeakX)
            hInterp=xline(axPeak,interpPeakX,'--','Color',C.purple, ...
                'LineWidth',2.0,'DisplayName','Local interpolated peak');
        end
        if isfinite(centerX)
            hCenter=xline(axPeak,centerX,'-','Color',[0 0 0], ...
                'LineWidth',2.0,'DisplayName','FWHM center');
        end
        if isfinite(centroidX)
            hCentroid=xline(axPeak,centroidX,':','Color',C.blueStrong, ...
                'LineWidth',2.5,'DisplayName','Centroid');
        end

        hFwhm=gobjects(0);
        if isfinite(rr.FWHM)
            yh=.5*rr.InterpolatedPeakY;
            hFwhm=plot(axPeak,[leftX rightX],[yh yh],'-d','Color',[.12 .20 .18], ...
                'LineWidth',2.2,'MarkerSize',10,'MarkerFaceColor',C.greenBright, ...
                'MarkerEdgeColor',[.12 .20 .18],'DisplayName','FWHM');
            text(axPeak,rightX,yh,'  FWHM','Color',[.12 .20 .18], ...
                'FontWeight','bold','VerticalAlignment','bottom','HitTest','off');
        end

        % ERW is a plain horizontal line.  A line object also guarantees
        % that the legend symbol matches the graph and redraws cleanly.
        hErw=gobjects(0);
        if isfinite(rr.ERW) && isfinite(centroidX)
            yErw=.27*rr.InterpolatedPeakY;
            hErw=plot(axPeak,[erwLeftX erwRightX],[yErw yErw],'-', ...
                'Color',C.blueStrong,'LineWidth',2.2,'DisplayName','ERW');
            text(axPeak,erwLeftX,yErw,'ERW  ','Color',C.blueStrong, ...
                'FontWeight','bold','HorizontalAlignment','right', ...
                'VerticalAlignment','bottom','HitTest','off');
        end
        hold(axPeak,'off'); grid(axPeak,'on'); xlabel(axPeak,xlab); ylabel(axPeak,'Local net AD counts');
        xlim(axPeak,sort([wx(1) wx(end)]));
        ymax=max([rr.InterpolatedPeakY;rr.NetY(:)]);
        if isfinite(ymax) && ymax>0, ylim(axPeak,[min(0,min(rr.NetY)) 1.12*ymax]); end
        isMulti=isfield(rr,'PeakShapeStatus') && strcmp(rr.PeakShapeStatus,'MultiPeak');
        if useWavelength
            if isMulti
                title(axPeak,sprintf('MULTI-PEAK: position only | [%.4f, %.4f] nm | %s',wx(1),wx(end),appliedModelName), ...
                    'Color',C.orange,'FontWeight','bold');
            else
                title(axPeak,sprintf('Calibrated subwindow [%.4f, %.4f] nm | %s',wx(1),wx(end),appliedModelName));
            end
        else
            if isMulti
                title(axPeak,sprintf('MULTI-PEAK: position only | subwindow [%g, %g]',wx(1),wx(end)), ...
                    'Color',C.orange,'FontWeight','bold');
            else
                title(axPeak,sprintf('Selected subwindow [%g, %g]',wx(1),wx(end)));
            end
        end
        legendHandles=[hWingBars hErwBars hRaw hBaseline hFwhm hErw ...
            hDirect hInterp hCenter hCentroid];
        legendHandles=legendHandles(isgraphics(legendHandles));
        legend(axPeak,legendHandles,'Location','best');
    end
    function showParameters(rr)
        shapeStatus='SinglePeak'; usability='Full'; detectedCount=1;
        if isfield(rr,'PeakShapeStatus'),shapeStatus=rr.PeakShapeStatus;end
        if isfield(rr,'CalibrationUsability'),usability=rr.CalibrationUsability;end
        if isfield(rr,'DetectedPeakCount'),detectedCount=rr.DetectedPeakCount;end
        n={'Status';'Peak shape';'Calibration usability';'Detected peaks in window'; ...
            'Direct peak position';'Interpolated peak position';'FWHM center position';'Centroid position';'FWHM';'ERW'; ...
            'ERW - FWHM';'ERW / FWHM';'Direct - Center';'Interp - Center';'Centroid - Center';'Sampling ratio';'ERW sampling ratio'; ...
            'Peak area';'Local dispersion';'Window points'};
        pv={rr.Status;shapeStatus;usability;sprintf('%d',detectedCount); ...
            fmt(rr.DirectPeakX);fmt(rr.InterpolatedPeakX);fmt(rr.CenterX);fmt(rr.CentroidX);fmt(rr.FWHM);fmt(rr.ERW); ...
            fmt(rr.ERWminusFWHM);fmt(rr.ERWdivFWHM);fmt(rr.PeakCenterDelta);fmt(rr.InterpolationCenterDelta);fmt(rr.CentroidCenterDelta); ...
            fmt(rr.SamplingRatio);fmt(rr.ERWSamplingRatio);fmt(rr.PeakArea);'--';sprintf('%d',rr.OriginalPointCount)};
        wv=repmat({'--'},numel(n),1); wv(1:4)={rr.Status;shapeStatus;usability;sprintf('%d',detectedCount)};
        if appliedModel.valid
            q=wavelengthPeakParameters(rr);
            wv={rr.Status;shapeStatus;usability;sprintf('%d',detectedCount); ...
                fmt(q.Direct);fmt(q.Interp);fmt(q.Center);fmt(q.Centroid);fmt(q.FWHM);fmt(q.ERW); ...
                fmt(q.ERW-q.FWHM);fmt(q.ERW/q.FWHM);fmt(q.Direct-q.Center);fmt(q.Interp-q.Center);fmt(q.Centroid-q.Center); ...
                fmt(q.FWHM/q.Dispersion);fmt(q.ERW/q.Dispersion);fmt(q.Area);fmt(q.Dispersion);sprintf('%d',rr.OriginalPointCount)};
        end
        currentTable.Data=[n pv wv]; if isempty(rr.Warnings),warnings.Value={'No warning.'};else,warnings.Value=cellstr(rr.Warnings);end
    end
    function q=wavelengthPeakParameters(rr)
        q=struct();
        q.Direct=evaluateWavelengthModel(appliedModel,rr.DirectPeakX);
        q.Interp=evaluateWavelengthModel(appliedModel,rr.InterpolatedPeakX);
        if isfield(rr,'CalibrationUsability') && strcmp(rr.CalibrationUsability,'PositionOnly')
            q.Center=NaN;q.Centroid=NaN;q.FWHM=NaN;q.ERW=NaN;
            q.Area=NaN;q.Dispersion=NaN;
            return;
        end
        q.Center=evaluateWavelengthModel(appliedModel,rr.CenterX);
        q.Centroid=evaluateWavelengthModel(appliedModel,rr.CentroidX);
        left=evaluateWavelengthModel(appliedModel,rr.LeftHalfX); right=evaluateWavelengthModel(appliedModel,rr.RightHalfX);
        q.FWHM=abs(right-left);
        lam=evaluateWavelengthModel(appliedModel,rr.InterpX); yy=max(rr.InterpNetY,0);
        q.Area=abs(trapz(lam,yy)); ymax=max(yy);
        if ymax>0,q.ERW=q.Area/ymax;else,q.ERW=NaN;end
        den=trapz(lam,yy);
        if den~=0,q.Centroid=trapz(lam,lam.*yy)/den;end
        h=1e-3; q.Dispersion=abs((evaluateWavelengthModel(appliedModel,rr.CenterX+h)-evaluateWavelengthModel(appliedModel,rr.CenterX-h))/(2*h));
    end
    function clearCurrent
        currentTable.Data=cell(0,3); warnings.Value={'Select a row in Peak List.'}; currentLabel.Text='No peak selected';
        analyzeBtn.Enable='off'; addBtn.Enable='off';confirmNextBtn.Enable='off'; excludeBtn.Enable='off'; cla(axPeak); title(axPeak,'Select a peak from the list');
    end
    function highlightTableRow
        try, peakTable.Selection=[selectedRow 1]; catch, end
    end
    function [x,label]=displayX
        switch mainAxisMode
            case 'Pixel',x=D.pixel;label='Natural pixel coordinate';
            otherwise
                if ~isempty(D.calibratedWavelength),x=D.calibratedWavelength;label='Calibrated wavelength (nm)';
                else,x=D.pixel;label='Pixel (wavelength unavailable)';end
        end
    end
    function [y,label]=displayY
        switch displayDrop.Value
            case 'Raw AD counts',y=D.raw;label='Raw AD counts';
            case 'Normalized',y=D.normalized;label='Normalized signal';
            otherwise,y=D.corrected;label='Corrected AD counts';
        end
    end
    function T=datasetSummaryTable
        n=numel(peakDataset); ID=strings(n,1); Pixel=zeros(n,1); InputX=zeros(n,1); RefNm=nan(n,1); Direct=zeros(n,1); Interpolated=zeros(n,1); Center=zeros(n,1); Centroid=zeros(n,1); FWHM=zeros(n,1); ERW=zeros(n,1); Confirmed=false(n,1); Status=strings(n,1); ConfirmedAt=NaT(n,1);
        for i=1:n
            rr=peakDataset(i).AnalysisResult;ID(i)=peakDataset(i).PeakID;Pixel(i)=peakDataset(i).Pixel;InputX(i)=peakDataset(i).InputX;
            RefNm(i)=peakDataset(i).ReferenceWavelength;Direct(i)=rr.DirectPeakX;Interpolated(i)=rr.InterpolatedPeakX;Center(i)=rr.CenterX;
            Centroid(i)=rr.CentroidX;FWHM(i)=rr.FWHM;ERW(i)=rr.ERW;Confirmed(i)=peakDataset(i).Confirmed;
            Status(i)=peakDataset(i).Status;ConfirmedAt(i)=peakDataset(i).ConfirmedAt;
        end
        T=table(ID,Pixel,InputX,RefNm,Direct,Interpolated,Center,Centroid,FWHM,ERW,Confirmed,Status,ConfirmedAt);
    end
    function rmsValue=initialRMS
        use=[calPairs.ReferenceIndex]>0 & isfinite([calPairs.ReferenceWavelength]);
        if ~provisional.valid || ~any(use),rmsValue=NaN;return;end
        px=[calPairs(use).DetectionPixel]; wl=[calPairs(use).ReferenceWavelength];
        rr=wl-evaluateWavelengthModel(provisional,px); rmsValue=sqrt(mean(rr.^2));
    end
    function T=calibrationPairTable
        n=numel(calPairs); PeakID=strings(n,1); DetectionPixel=nan(n,1); ReferenceWavelength_nm=nan(n,1);
        PeakOrder=nan(n,1); Mode=strings(n,1); Confidence=nan(n,1); Locked=false(n,1); Status=strings(n,1); InitialResidual_nm=nan(n,1);
        for ii=1:n
            PeakID(ii)=calPairs(ii).PeakID; DetectionPixel(ii)=calPairs(ii).DetectionPixel;
            ReferenceWavelength_nm(ii)=calPairs(ii).ReferenceWavelength; PeakOrder(ii)=calPairs(ii).Order;
            Mode(ii)=calPairs(ii).Mode; Confidence(ii)=calPairs(ii).Confidence; Locked(ii)=calPairs(ii).Locked; Status(ii)=calPairs(ii).Status;
            if provisional.valid && isfinite(calPairs(ii).ReferenceWavelength)
                InitialResidual_nm(ii)=calPairs(ii).ReferenceWavelength-evaluateWavelengthModel(provisional,calPairs(ii).DetectionPixel);
            end
        end
        T=table(PeakID,DetectionPixel,ReferenceWavelength_nm,PeakOrder,Mode,Confidence,Locked,Status,InitialResidual_nm);
    end
    function openHelpDialog(~,~)
        helpFig=uifigure('Name','WCC4SM Help & About','Position',[420 260 700 310], ...
            'Color',C.bg,'WindowStyle','modal','Resize','off');
        helpGrid=uigridlayout(helpFig,[6 3]);
        helpGrid.ColumnWidth={110,'1x',105};
        helpGrid.RowHeight={34,34,34,70,34,'1x'};
        helpGrid.Padding=[16 14 16 14]; helpGrid.RowSpacing=8;
        titleLabel=uilabel(helpGrid,'Text','Help documents and references', ...
            'FontSize',17,'FontWeight','bold','FontColor',C.blue);
        titleLabel.Layout.Column=[1 3];
        uilabel(helpGrid,'Text','PDF document');
        documentDrop=uidropdown(helpGrid,'Items',{'Scanning docs ...'},'Enable','off');
        documentDrop.Layout.Column=2;
        readButton=uibutton(helpGrid,'Text','READ PDF','FontWeight','bold', ...
            'BackgroundColor',C.cyan,'Enable','off','ButtonPushedFcn',@readHelpDocument);
        readButton.Layout.Column=3;
        docsLocation=uilabel(helpGrid,'Text',['Folder: ' documentationDir], ...
            'FontColor',C.muted,'Tooltip',documentationDir);
        docsLocation.Layout.Column=[1 3];
        helpText=uilabel(helpGrid,'Text', ...
            ['Place manuals, standards and papers in the docs folder or its subfolders. ' ...
             'Refresh the list, select a PDF, then open it with the system PDF reader.'], ...
            'WordWrap','on','FontColor',C.muted);
        helpText.Layout.Column=[1 3];
        refreshButton=uibutton(helpGrid,'Text','REFRESH','ButtonPushedFcn',@refreshHelpDocuments);
        refreshButton.Layout.Column=2;
        aboutButton=uibutton(helpGrid,'Text','ABOUT','FontWeight','bold', ...
            'BackgroundColor',C.greenLight,'ButtonPushedFcn',@showAboutDialog);
        aboutButton.Layout.Column=3;
        setappdata(helpFig,'DocumentDrop',documentDrop);
        setappdata(helpFig,'ReadButton',readButton);
        refreshHelpDocuments(refreshButton,[]);
    end
    function refreshHelpDocuments(source,~)
        helpFig=ancestor(source,'figure');
        documentDrop=getappdata(helpFig,'DocumentDrop');
        readButton=getappdata(helpFig,'ReadButton');
        documents=wc4sm_list_pdf_documents(documentationDir);
        if isempty(documents)
            documentDrop.Items={'No PDF documents found'};
            documentDrop.ItemsData={''};
            documentDrop.Value='';
            documentDrop.Enable='off'; readButton.Enable='off';
        else
            documentDrop.Items={documents.Label};
            documentDrop.ItemsData={documents.Path};
            documentDrop.Value=documents(1).Path;
            documentDrop.Enable='on'; readButton.Enable='on';
        end
    end
    function readHelpDocument(source,~)
        helpFig=ancestor(source,'figure');
        documentDrop=getappdata(helpFig,'DocumentDrop');
        pdfPath=char(documentDrop.Value);
        if isempty(pdfPath) || ~isfile(pdfPath)
            uialert(helpFig,'The selected PDF file is no longer available. Refresh the document list.','PDF unavailable');
            return;
        end
        try
            if ispc
                winopen(pdfPath);
            else
                web(['file:///' strrep(pdfPath,'\','/')],'-browser');
            end
        catch ME
            uialert(helpFig,ME.message,'Unable to open PDF');
        end
    end
    function showAboutDialog(source,~)
        helpFig=ancestor(source,'figure');
        message=sprintf(['WCC4SM V1.0\n' ...
            'Wavelength Characterization and Calibration for Spectrometer\n\n' ...
            'Developed by Zheng Feng\n' ...
            'Copyright (c) 2026 Zheng Feng\n' ...
            'NewOptic - unregistered personal project label\n\n' ...
            'Contact: feng1214@126.com\n' ...
            'License: Apache License 2.0\n' ...
            'Repository: github.com/feng08321/WCC4SM']);
        uialert(helpFig,message,'About WCC4SM','Icon','info');
    end
end

function M=cleanMatrix(M)
    M=M(~all(isnan(M),2),:); M=M(:,~all(isnan(M),1));
    if isempty(M),error('CSV contains no numeric data.');end
    if size(M,2)>2,M=M(:,1:2);end
end
function D=emptyData, D=struct('raw',[],'dark',[],'darkSource','','corrected',[],'normalized',[],'pixel',[],'inputX',[],'inputWavelength',[],'calibratedWavelength',[],'xKind','Pixel','source','','PixelCoordinateMode','','PixelFirst',NaN,'PixelLast',NaN); end
function R=emptyReference, R=struct('x',[],'y',[],'source','','loaded',false); end
function L=emptyLineLibrary, L=struct('wavelength',[],'intensity',[],'order',[],'effective',[],'enabled',[],'source','','loaded',false); end
function L=basicHgArLibrary
    % Experience-screened Hg-Ar features for nominal 300-1050 nm instruments.
    % 296.73 nm is intentionally retained through the default 5 nm edge margin.
    w=[296.73;302.15;313.16;334.15;404.66;546.07;576.9598;579.0663;696.54;706.72;727.29;738.40; ...
       763.51;772.38;794.82;826.45;852.14;912.30;922.45;965.79;1013.98];
    inten=[321;60;320;41;767;2258.4;297.9;100;45;8.7;6;7.2;23;15;6.5;11;3.7;11.6;2.3;3.8;5];
    L=emptyLineLibrary(); L.wavelength=w; L.intensity=inten; L.order=ones(size(w)); L.effective=w;L.enabled=true(size(w));
    L.source='Built-in Hg-Ar Basic 21'; L.loaded=true;
end
function L=paper24HgArLibrary
    % Table 1 of the user's 2019 paper. Starred values are measured blended
    % peaks at the instrument's approximately 5 nm resolution.
    w=[313.16;334.15;365.06;404.66;435.72;546.07;578.01;696.54;706.72;727.29;738.40;750.82; ...
       763.51;772.38;794.82;801.08;811.09;826.45;841.81;852.14;912.30;922.45;965.79;1013.98];
    inten=ones(size(w));
    L=emptyLineLibrary();L.wavelength=w;L.intensity=inten;L.order=ones(size(w));L.effective=w;L.enabled=true(size(w));
    L.source='Paper Table 1 Hg-Ar 24 measured peaks';L.loaded=true;
end
function L=nimHgArLibrary
    w=[253.65;296.71;302.15;312.55;313.16;365.02;365.50;366.33;404.65;435.81;546.06;576.92;579.03; ...
       696.55;714.65;727.22;763.48;772.38;794.79;800.60;801.46;810.34;811.52;826.44;840.80;842.44; ...
       852.12;912.26;922.39;935.41;965.78;978.45;1013.98;1047.04];
    L=emptyLineLibrary();L.wavelength=w;L.intensity=ones(size(w));L.order=ones(size(w));L.effective=w;L.enabled=true(size(w));
    L.source='NIM Hg-Ar Certificate 34 GXcl2025-02617';L.loaded=true;
end
function p=emptyPeaks, p=struct('ID',{},'Index',{},'Pixel',{},'InputX',{},'Height',{},'Prominence',{},'Width',{},'Status',{},'Result',{}); end
function p=emptyLocalCandidates, p=struct('Index',{},'Pixel',{},'InputX',{},'Height',{},'Prominence',{},'Width',{}); end
function d=emptyDataset
    d=struct('PeakID',{},'PeakIndex',{},'Pixel',{},'InputX',{},'ReferenceWavelength',{},'Source',{}, ...
        'WindowPixel',{},'WindowADCounts',{},'WindowCorrected',{},'AnalysisResult',{}, ...
        'FindPeakHeight',{},'FindPeakProminence',{},'FindPeakWidth',{},'Status',{}, ...
        'Confirmed',{},'ConfirmedAt',{},'ConfirmedSettings',{});
end
function p=emptyCalPairs, p=struct('PeakID',{},'PeakIndex',{},'DetectionPixel',{},'ReferenceIndex',{},'ReferenceWavelength',{},'Order',{},'Mode',{},'Confidence',{},'Locked',{},'Status',{}); end
function m=emptyMappingCandidates, m=struct('a',{},'b',{},'RMS',{},'ReferenceIndices',{},'ReferenceWavelengths',{}); end
function m=emptyInitialModel
    m=struct('valid',false,'Degree',0,'Coefficients',[],'Mu',[0 1],'a',NaN,'b',NaN);
end
function f=emptyFinalModel
    f=struct('valid',false,'PositionMethod','','Degree',NaN,'Coefficients',[],'Mu',[],'S',[], ...
        'NaturalCoefficients',[],'Equation','','PeakID',{{}},'Pixel',[],'ReferenceWavelength',[],'FittedWavelength',[],'Residual',[], ...
        'MeanResidual',NaN,'STD',NaN,'RMS',NaN,'MaxAbsResidual',NaN,'LOOResidual',[], ...
        'DeletionMaxCurveChange',[],'LOORMS',NaN,'LOOMaxAbs',NaN,'MaxDeletionInfluence',NaN);
end
function p=normalizedToNaturalPolynomial(c,mu)
    % Horner composition of c(z), z=(pixel-mu(1))/mu(2).
    p=0;affine=[1/mu(2),-mu(1)/mu(2)];
    for k=1:numel(c)
        p=conv(p,affine);p(end)=p(end)+c(k);
    end
    first=find(abs(p)>max(1e-15,max(abs(p))*1e-14),1,'first');
    if isempty(first),p=0;else,p=p(first:end);end
end
function s=formatCalibrationEquation(p)
    n=numel(p)-1;parts={};
    for k=1:numel(p)
        power=n-k+1;a=p(k);if abs(a)<1e-15,continue;end
        if power==0,term=sprintf('%.12g',abs(a));elseif power==1,term=sprintf('%.12g*p',abs(a));else,term=sprintf('%.12g*p^%d',abs(a),power);end
        if isempty(parts),if a<0,term=['-' term];end;parts{end+1}=term; %#ok<AGROW>
        elseif a<0,parts{end+1}=[' - ' term];else,parts{end+1}=[' + ' term];end %#ok<AGROW>
    end
    if isempty(parts),rhs='0';else,rhs=strjoin(parts,'');end
    s=['lambda(nm) = ' rhs];
end
function [looResidual,maxCurveChange]=leaveOneOutDiagnostics(x,lambda,degree,fullCoef,fullMu,evaluationPixels)
    x=x(:);lambda=lambda(:);evaluationPixels=evaluationPixels(:).';n=numel(x);
    looResidual=nan(n,1);maxCurveChange=nan(n,1);fullCurve=polyval(fullCoef,evaluationPixels,[],fullMu);
    for i=1:n
        keep=true(n,1);keep(i)=false;
        if sum(keep)<=degree,continue;end
        [c,~,mu]=polyfit(x(keep),lambda(keep),degree);
        looResidual(i)=lambda(i)-polyval(c,x(i),[],mu);
        deletedCurve=polyval(c,evaluationPixels,[],mu);maxCurveChange(i)=max(abs(fullCurve-deletedCurve));
    end
end
function limit=robustUpperLimit(v)
    v=v(isfinite(v));if isempty(v),limit=Inf;return;end
    med=median(v);madv=median(abs(v-med));limit=med+3*1.4826*madv;
    if madv==0,limit=max(med,max(v)*0.5);end
    if limit<=0,limit=eps;end
end
function m=emptyCalibrationModels
    m=struct('ModelID',{},'CreatedAt',{},'PairCount',{},'PositionMethod',{},'Degree',{},'PairIDs',{},'Model',{},'Visible',{});
end
function q=makeCalPair(id,idx,pixel,refIdx,refWavelength,ord,mode,locked,status,confidence)
    if nargin<10,confidence=NaN;end
    q=struct('PeakID',id,'PeakIndex',idx,'DetectionPixel',pixel,'ReferenceIndex',refIdx,'ReferenceWavelength',refWavelength, ...
        'Order',ord,'Mode',mode,'Confidence',confidence,'Locked',locked,'Status',status);
end
function value=minOrNaN(values)
    if isempty(values),value=NaN;else,value=min(values);end
end
function value=maxOrNaN(values)
    if isempty(values),value=NaN;else,value=max(values);end
end
function matchedRef=orderedSequenceMatch(predicted,referenceWavelengths,referenceIndices,tolerance)
    % Dynamic-programming sequence alignment. Matches must remain monotonic;
    % either measured or reference lines may be skipped.
    predicted=predicted(:);referenceWavelengths=referenceWavelengths(:);referenceIndices=referenceIndices(:);
    n=numel(predicted);m=numel(referenceWavelengths);D=inf(n+1,m+1);B=zeros(n+1,m+1,'uint8');D(1,1)=0;
    skipPeak=1.0;skipReference=0.03;
    for i=0:n
        for j=0:m
            base=D(i+1,j+1);if ~isfinite(base),continue;end
            if i<n && base+skipPeak<D(i+2,j+1),D(i+2,j+1)=base+skipPeak;B(i+2,j+1)=2;end
            if j<m && base+skipReference<D(i+1,j+2),D(i+1,j+2)=base+skipReference;B(i+1,j+2)=3;end
            if i<n && j<m
                dist=abs(predicted(i+1)-referenceWavelengths(j+1));
                if dist<=tolerance
                    cost=base+0.8*(dist/tolerance)^2;
                    if cost<D(i+2,j+2),D(i+2,j+2)=cost;B(i+2,j+2)=1;end
                end
            end
        end
    end
    matchedRef=zeros(n,1);i=n;j=m;
    while i>0 || j>0
        action=B(i+1,j+1);
        if action==1,matchedRef(i)=referenceIndices(j);i=i-1;j=j-1;
        elseif action==2,i=i-1;
        elseif action==3,j=j-1;
        else
            if i>0,i=i-1;elseif j>0,j=j-1;end
        end
    end
end
function pairs=removePairByPeakOrReference(pairs,id,refIdx)
    if isempty(pairs),return;end
    keep=~strcmp({pairs.PeakID},id) & [pairs.ReferenceIndex]~=refIdx; pairs=pairs(keep);
end
function sectionAuto(g,t),q=uilabel(g,'Text',t,'FontWeight','bold','FontColor',[.07 .28 .46]);q.Layout.Column=[1 2];end
function styleAxes(a,C),a.Color='white';a.XColor=C.muted;a.YColor=C.muted;a.GridColor=[.86 .89 .92];a.Box='on';end
function s=fmt(v),if isnan(v),s='NaN';elseif isinf(v),s='Inf';else,s=sprintf('%.8g',v);end,end
function s=shortName(p),if isempty(p),s='';else,[~,n,e]=fileparts(p);s=[n e];end,end
function v=numberOrNaN(x),if isnumeric(x),v=x;else,v=str2double(string(x));end;if isempty(v)||~isfinite(v),v=NaN;end,end
function s=logicalText(v),if v,s='Yes';else,s='No';end,end
function C=colors
    C.bg=[.94 .96 .98];C.navy=[.055 .18 .30];C.blue=[.10 .38 .67];C.cyan=[.30 .82 .88];C.cyanDark=[0 .55 .64];
    C.orange=[.95 .49 .16];C.red=[.82 .18 .20];C.green=[.12 .55 .34];C.greenLight=[.72 .90 .79];C.purple=[.47 .28 .65];C.gray=[.55 .58 .61];C.muted=[.34 .40 .46];
    C.sky=[.16 .78 .88];C.yellow=[1.00 .88 .05];C.blueStrong=[.05 .18 .95];C.greenBright=[.15 .90 .08];
end


