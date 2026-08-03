function WCC4SM_V0_5_3
%WCC4SM_V0_5_3 Wavelength Characterization and Calibration for Spectrometer.
% Peak analysis plus reference-line matching and provisional calibration.
% MATLAB R2022a or later. Signal Processing Toolbox is required for findpeaks.

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
    selectedRow = 0;
    selectedDatasetRow = 0;
    selectedRefRow = 0;
    selectedPairRow = 0;
    selectedValidationRow = 0;
    selectedModelRow = 0;
    localCandidates = emptyLocalCandidates();
    selectedLocalCandidate = 0;
    referenceResolutionNm = 3;
    C = colors();

    fig=uifigure('Name','WCC4SM V0.5.3 | Peak Analysis','Position',[25 30 1580 900],'Color',C.bg);
    root=uigridlayout(fig,[2 3]); root.RowHeight={50,'1x'}; root.ColumnWidth={330,'1x',400};
    root.ColumnWidth={'1x',330,400};
    root.Padding=[10 9 10 10]; root.RowSpacing=8; root.ColumnSpacing=8;

    head=uipanel(root,'BackgroundColor',C.navy,'BorderType','none'); head.Layout.Row=1; head.Layout.Column=[1 3];
    hg=uigridlayout(head,[1 3]); hg.ColumnWidth={310,'1x',520}; hg.Padding=[14 5 14 5];
    uilabel(hg,'Text','WCC4SM  V0.5.3','FontSize',20,'FontWeight','bold','FontColor',[.10 .55 .95]);
    uilabel(hg,'Text','Wavelength Characterization and Calibration for Spectrometer','FontSize',14,'FontWeight','bold','FontColor',[.10 .55 .95],'HorizontalAlignment','center');
    headerTools=uigridlayout(hg,[1 3]);headerTools.ColumnWidth={185,90,'1x'};headerTools.Padding=[0 0 0 0];headerTools.ColumnSpacing=6;
    openFigDrop=uidropdown(headerTools,'Items',{'Peak Analysis','Peak Parameter Statistics','Wavelength Matching', ...
        'Calibration Fit & Residuals','Model Validation','Model Comparison','Calibrated Performance'}, ...
        'Value','Peak Analysis','Tooltip','Choose a plot tab whose subplots will be opened as separate editable figures');
    uibutton(headerTools,'Text','OPEN FIG','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@openSelectedTabFigures);
    topStatus=uilabel(headerTools,'Text','Load a spectrum','FontWeight','bold','FontColor',[1 1 1],'HorizontalAlignment','right');

    %% LEFT CONTROL COLUMN
    leftTabs=uitabgroup(root); leftTabs.Layout.Row=2; leftTabs.Layout.Column=2;
    tabDataDisplay=uitab(leftTabs,'Title','Data & Display'); tabDetection=uitab(leftTabs,'Title','Peak Detection');tabCurrent=uitab(leftTabs,'Title','Current Peak');tabReference=uitab(leftTabs,'Title','Reference Lines');

    dg=uigridlayout(tabDataDisplay,[18 2]); dg.ColumnWidth={135,'1x'};
    dg.RowHeight={32,32,24,30,30,30,24,30,30,38,30,30,30,30,30,24,34,'1x'}; dg.Padding=[9 8 9 9]; dg.RowSpacing=6;
    bLoad=uibutton(dg,'Text','Load spectrum CSV','ButtonPushedFcn',@loadSpectrum); bLoad.Layout.Column=[1 2];
    bRef=uibutton(dg,'Text','Pop out current spectrum plots','ButtonPushedFcn',@popOutSpectrumPlots); bRef.Layout.Column=[1 2];
    sectionAuto(dg,'Input interpretation');
    uilabel(dg,'Text','Two-column X'); inputType=uidropdown(dg,'Items',{'Wavelength (nm)','Pixel index'},'Value','Wavelength (nm)');
    uilabel(dg,'Text','Natural pixel start'); pixelStart=uispinner(dg,'Limits',[0 1],'Step',1,'Value',0);
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
    uilabel(dg,'Text','X axis'); axisButton=uibutton(dg,'Text','X Axis: Pixel  ⇄','ButtonPushedFcn',@toggleMainAxis);
    refCheck=uicheckbox(dg,'Text','Show detected peak markers','Value',true,'ValueChangedFcn',@displayChanged); refCheck.Layout.Column=[1 2];
    sectionAuto(dg,'Weak-peak subwindow search');
    localSearchBtn=uibutton(dg,'Text','OPEN SUBWINDOW SEARCH','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@openLocalSearchDialog);localSearchBtn.Layout.Column=[1 2];
    dataHelp=uilabel(dg,'Text','Use full-spectrum detection first. Subwindow search creates candidates only; manually add a candidate before analysis.', ...
        'WordWrap','on','FontColor',C.muted); dataHelp.Layout.Column=[1 2];

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
    tabPlots=uitab(plotTabs,'Title','Peak Analysis');tabPeakStatistics=uitab(plotTabs,'Title','Peak Parameter Statistics');tabMatchingPlots=uitab(plotTabs,'Title','Wavelength Matching');tabResults=uitab(plotTabs,'Title','Calibration Fit & Residuals');tabValidation=uitab(plotTabs,'Title','Model Validation');tabModelCompare=uitab(plotTabs,'Title','Model Comparison');tabCalibratedStatistics=uitab(plotTabs,'Title','Calibrated Performance');
    plotHost=uigridlayout(tabPlots,[1 1]);plotHost.Padding=[0 0 0 0];
    middle=uipanel(plotHost,'Title','Measured spectrum / Selected peak','FontWeight','bold','BackgroundColor','white');
    mg=uigridlayout(middle,[2 1]); mg.RowHeight={'1.2x','1x'}; mg.Padding=[7 4 7 7];
    axFull=uiaxes(mg); styleAxes(axFull,C); title(axFull,'Full spectrum');
    axPeak=uiaxes(mg); styleAxes(axPeak,C); title(axPeak,'Select a peak from the list');

    statsHost=uigridlayout(tabPeakStatistics,[2 2]);statsHost.RowHeight={'1x','1x'};statsHost.ColumnWidth={'1x','1x'};statsHost.Padding=[7 7 7 7];
    axWidthTrend=uiaxes(statsHost);styleAxes(axWidthTrend,C);title(axWidthTrend,'FWHM and ERW versus confirmed peak position');
    axWidthRelation=uiaxes(statsHost);styleAxes(axWidthRelation,C);title(axWidthRelation,'FWHM versus ERW');
    axPositionDelta=uiaxes(statsHost);styleAxes(axPositionDelta,C);title(axPositionDelta,'Peak-position differences from FWHM center');
    axPositionHistogram=uiaxes(statsHost);styleAxes(axPositionHistogram,C);title(axPositionHistogram,'Peak-position-difference histograms');

    calibratedStatsHost=uigridlayout(tabCalibratedStatistics,[2 2]);calibratedStatsHost.RowHeight={'1x','1x'};calibratedStatsHost.ColumnWidth={'1x','1x'};calibratedStatsHost.Padding=[7 7 7 7];
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

    matchHost=uigridlayout(tabMatchingPlots,[2 1]);matchHost.RowHeight={'1x','1x'};matchHost.Padding=[7 7 7 7];
    axMatchMeasured=uiaxes(matchHost);styleAxes(axMatchMeasured,C);title(axMatchMeasured,'Selected measured peaks');
    axMatchReference=uiaxes(matchHost);styleAxes(axMatchReference,C);title(axMatchReference,'Reference wavelength lines');

    %% RIGHT TABS
    tabs=uitabgroup(root); tabs.Layout.Row=2; tabs.Layout.Column=3;
    tabList=uitab(tabs,'Title','Peak List'); tabData=uitab(tabs,'Title','Peak Dataset');
    tabCal=uitab(tabs,'Title','Matching'); tabFit=uitab(tabs,'Title','Calibration Fit');
    tabs.SelectionChangedFcn=@rightTabChanged;

    gl=uigridlayout(tabList,[4 1]); gl.RowHeight={28,'1x',32,32}; gl.Padding=[7 7 7 7];
    peakCountLabel=uilabel(gl,'Text','No detected peaks','FontWeight','bold','FontColor',C.navy);
    peakTable=uitable(gl,'ColumnName',{'ID','Pixel','Input X','Height','Prom.','Width','Status'}, ...
        'ColumnWidth',{44,58,68,65,58,52,70},'RowName',[],'CellSelectionCallback',@selectPeak);
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

    %% LEAVE-ONE-OUT MODEL VALIDATION
    gv=uigridlayout(tabValidation,[4 1]);gv.RowHeight={'1x','1x',34,235};gv.Padding=[7 7 7 7];
    axLOO=uiaxes(gv);styleAxes(axLOO,C);title(axLOO,'Leave-one-out prediction residual');
    axInfluence=uiaxes(gv);styleAxes(axInfluence,C);title(axInfluence,'Maximum calibration-curve change after deleting one point');
    validationTools=uigridlayout(gv,[1 4]);validationTools.ColumnWidth={'1.5x','1x','1x','1x'};validationTools.Padding=[0 0 0 0];
    validationSummary=uilabel(validationTools,'Text','Fit a model to run validation','FontWeight','bold','FontColor',C.navy);
    uibutton(validationTools,'Text','Open selected peak','ButtonPushedFcn',@openValidationPeak);
    uibutton(validationTools,'Text','Remove selected pair','ButtonPushedFcn',@removeValidationPair);
    uibutton(validationTools,'Text','Refresh validation','ButtonPushedFcn',@refreshValidationView);
    validationTable=uitable(gv,'ColumnName',{'Peak','Pixel','Ref nm','Fit r nm','LOO r nm','Curve change nm','FWHM px','ERW/FWHM','Centroid-Center','Flag'}, ...
        'ColumnWidth',{48,58,68,70,75,100,65,78,105,90},'RowName',[],'CellSelectionCallback',@selectValidationRow);

    %% MODEL RESIDUAL COMPARISON
    gc=uigridlayout(tabModelCompare,[3 1]);gc.RowHeight={92,'1x',190};gc.Padding=[7 7 7 7];
    compareTools=uigridlayout(gc,[3 4]);compareTools.ColumnWidth={'1x','1x','1x','1x'};compareTools.RowHeight={28,28,24};compareTools.Padding=[0 0 0 0];
    uibutton(compareTools,'Text','Refresh overlays','ButtonPushedFcn',@drawModelComparison);
    uibutton(compareTools,'Text','Import model MAT','ButtonPushedFcn',@importCalibrationModels);
    uibutton(compareTools,'Text','Export current model','ButtonPushedFcn',@exportCurrentModel);
    uibutton(compareTools,'Text','Clear model list','ButtonPushedFcn',@clearCalibrationModels);
    uibutton(compareTools,'Text','Apply selected model','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@applySelectedModel);
    uibutton(compareTools,'Text','Apply current final model','ButtonPushedFcn',@applyCurrentModel);
    uibutton(compareTools,'Text','Import && apply model MAT','ButtonPushedFcn',@importAndApplyModel);
    uibutton(compareTools,'Text','Clear applied model','ButtonPushedFcn',@clearAppliedModel);
    appliedStatus=uilabel(compareTools,'Text','Applied model: none | spectrum axis remains Pixel','FontWeight','bold','FontColor',C.navy);appliedStatus.Layout.Column=[1 4];
    axModelCompare=uiaxes(gc);styleAxes(axModelCompare,C);title(axModelCompare,'Stored-model residual comparison');
    modelComparisonTable=uitable(gc,'ColumnName',{'Model','N','Peak position','Degree','Fit RMS','LOO RMS','LOO max','Influence','STD','Max','Equation'}, ...
        'ColumnWidth',{58,38,100,50,65,68,68,68,60,60,320},'RowName',[],'CellSelectionCallback',@selectModelRow);

    %% REFERENCE OVERVIEW AND FINAL FIT TAB
    gf=uigridlayout(tabFit,[12 2]); gf.ColumnWidth={145,'1x'};
    gf.RowHeight={24,'1x',24,26,26,32,32,32,34,105,55,40};
    gf.Padding=[7 7 7 7]; gf.RowSpacing=3;
    sectionAuto(gf,'Active reference set');
    activeRefTable=uitable(gf,'ColumnName',{'nm','Intensity','Spacing','Status'},'ColumnWidth',{72,70,65,95},'RowName',[]); activeRefTable.Layout.Column=[1 2];
    sectionAuto(gf,'Final calibration model');
    uilabel(gf,'Text','Peak position'); positionDrop=uidropdown(gf,'Items',{'Direct peak','Interpolated peak','FWHM center','Centroid','Gaussian fit'},'Value','FWHM center');
    uilabel(gf,'Text','Polynomial degree'); degreeSpin=uispinner(gf,'Limits',[1 6],'Step',1,'Value',3);
    fitBtn=uibutton(gf,'Text','FIT CALIBRATION MODEL','FontWeight','bold','BackgroundColor',C.greenLight,'ButtonPushedFcn',@fitFinalCalibration); fitBtn.Layout.Column=[1 2];
    residualBtn=uibutton(gf,'Text','Open fit & residual analysis','FontWeight','bold','ButtonPushedFcn',@openResidualAnalysis); residualBtn.Layout.Column=[1 2];
    saveModelBtn=uibutton(gf,'Text','SAVE / EXPORT CURRENT MODEL','FontWeight','bold','ButtonPushedFcn',@exportCurrentModel);saveModelBtn.Layout.Column=[1 2];
    calibratedStatsBtn=uibutton(gf,'Text','PLOT CALIBRATED PERFORMANCE','FontWeight','bold','BackgroundColor',C.cyan,'ButtonPushedFcn',@plotCalibratedPerformance);calibratedStatsBtn.Layout.Column=[1 2];
    equationDisplay=uitextarea(gf,'Value',{'No calibration equation.'},'Editable','off','FontName','Courier New');equationDisplay.Layout.Column=[1 2];
    fitResultLabel=uilabel(gf,'Text','No final calibration model. At least degree+2 matched points are recommended.', ...
        'WordWrap','on','FontColor',C.navy,'FontWeight','bold'); fitResultLabel.Layout.Column=[1 2];
    fitHelp=uilabel(gf,'Text','Create about six manual anchor pairs, update the initial model, then use Auto extend. Every final fit is retained as a model snapshot for residual comparison.', ...
        'WordWrap','on','FontColor',C.muted); fitHelp.Layout.Column=[1 2];

    %% CALLBACKS
    function loadSpectrum(~,~)
        [fn,pn]=uigetfile({'*.csv','CSV (*.csv)'},'Load wavelength-lamp spectrum'); if isequal(fn,0), return; end
        try
            if strcmp(inputType.Value,'Wavelength (nm)')
                inputKind='Wavelength';
            else
                inputKind='Pixel';
            end
            D=wc4sm_read_spectrum_file(fullfile(pn,fn),inputKind,pixelStart.Value);
            y=D.raw;
            sourceLabel.Text=fn; mainAxisMode='Pixel'; matchingAxisMode='Pixel'; axisButton.Text='X Axis: Pixel  ⇄'; selectedRow=0; peaks=emptyPeaks(); peakDataset=emptyDataset();
            localCandidates=emptyLocalCandidates();selectedLocalCandidate=0;
            baselineField.Enable='on';clearDarkBtn.Enable='off';darkStatus.Text='Dark: none (manual constant baseline is active)';
            pixelViewStart.Value=min(D.pixel); pixelViewEnd.Value=max(D.pixel);
            calPairs=emptyCalPairs(); provisional=emptyInitialModel(); selectedPairRow=0;
            finalModel=emptyFinalModel();appliedModel=emptyFinalModel();appliedModelName='';appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';calibrationModels=emptyCalibrationModels();refreshModelComparison();
            preprocess(); refreshAll(); topStatus.Text=sprintf('%d samples loaded',numel(y));
        catch ME
            uialert(fig,ME.message,'Import failed');
        end
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
        finalModel=emptyFinalModel();appliedModel=emptyFinalModel();appliedModelName='';
        D.calibratedWavelength=[];mainAxisMode='Pixel';matchingAxisMode='Pixel';axisButton.Text='X Axis: Pixel  ⇄';
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
    end
    function rightTabChanged(~,~)
        if tabs.SelectedTab==tabCal,showCalibrationView([],[]);end
    end
    function toggleMainAxis(~,~)
        if strcmp(mainAxisMode,'Pixel')
            if ~isempty(D.calibratedWavelength),mainAxisMode='Wavelength';
            else,uialert(fig,'No calibration model is currently applied. Select a validated model in Model Comparison and click Apply.','Wavelength unavailable');return;end
        else,mainAxisMode='Pixel';end
        matchingAxisMode=mainAxisMode;
        axisButton.Text=['X Axis: ' mainAxisMode '  ⇄'];
        drawFull();if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
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
        ld=uifigure('Name','WCC4SM V0.5.3 | Weak-peak subwindow search','Position',[180 160 520 520],'Color',C.bg);
        lg=uigridlayout(ld,[13 2]);lg.ColumnWidth={180,'1x'};lg.RowHeight={32,30,30,30,30,30,30,30,34,34,30,34,'1x'};lg.Padding=[12 12 12 12];
        note=uilabel(lg,'Text','Local search normalizes within this window, uses separate sensitive parameters, and produces candidates only.','FontColor',C.navy,'FontWeight','bold','WordWrap','on');note.Layout.Column=[1 2];
        uilabel(lg,'Text','Start pixel');lStart=uieditfield(lg,'numeric','Value',viewLimits(1));
        uilabel(lg,'Text','End pixel');lEnd=uieditfield(lg,'numeric','Value',viewLimits(2));
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
        selectedRow=event.Indices(1); plotTabs.SelectedTab=tabPlots;showSelected(); leftTabs.SelectedTab=tabCurrent;
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
        [fn,pn]=uigetfile({'*.lit;*.txt;*.csv','Reference lines (*.lit,*.txt,*.csv)';'*.*','All files'},'Load reference-line list');
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
            plot(axMatchMeasured,peaks(jj).Pixel,ym(peaks(jj).Index),'v','Color',C.green,'MarkerFaceColor',C.green,'MarkerSize',5);
            text(axMatchMeasured,peaks(jj).Pixel,ym(peaks(jj).Index),peaks(jj).ID,'FontSize',10,'FontWeight','bold','Color',C.green,'VerticalAlignment','bottom');
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
            text(axMatchReference,xr,hr(ii),sprintf(' %.3f',xr),'Rotation',75,'FontSize',10,'FontWeight','bold','Color',col,'VerticalAlignment','bottom');
        end
        for jj=1:numel(calPairs)
            if calPairs(jj).ReferenceIndex<=0,continue;end
            xx=calPairs(jj).ReferenceWavelength;
            plot(axMatchReference,xx,1.03,'v','Color',C.green,'MarkerFaceColor',C.green,'MarkerSize',6,'HandleVisibility','off');
            text(axMatchReference,xx,1.03,calPairs(jj).PeakID,'FontSize',10,'FontWeight','bold','Color',C.green,'VerticalAlignment','bottom','HorizontalAlignment','center');
        end
        hold(axMatchReference,'off');grid(axMatchReference,'on');xlabel(axMatchReference,'Reference wavelength (nm)');ylabel(axMatchReference,'Log-normalized reference intensity');
        ylim(axMatchReference,[0 1.18]);xlim(axMatchReference,[wavelengthViewStart.Value wavelengthViewEnd.Value]);
        dp=pixelViewEnd.Value-pixelViewStart.Value;dw=wavelengthViewEnd.Value-wavelengthViewStart.Value;
        localA=dw/dp;localB=wavelengthViewStart.Value-localA*pixelViewStart.Value;
        title(axMatchReference,sprintf('Reference template | local guide: lambda = %.7g pixel %+.7g | %s',localA,localB,shortName(L.source)));
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
        if sum([calPairs.ReferenceIndex]>0)>=2,buildInitialCalibration([],[]);else,refreshCalibration();showCalibrationView([],[]);end
        topStatus.Text=sprintf('%s paired with %.8g nm',id,L.effective(selectedRefRow));
    end

    function removePair(~,~)
        if selectedPairRow<1 || selectedPairRow>numel(calPairs), return; end
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
        xpos=finalModel.Pixel;wl=finalModel.ReferenceWavelength;ids=finalModel.PeakID;
        modelItem=struct('ModelID',sprintf('M%03d',numel(calibrationModels)+1),'CreatedAt',datetime('now'), ...
            'PairCount',numel(xpos),'PositionMethod',positionDrop.Value,'Degree',deg,'PairIDs',{ids},'Model',finalModel);
        calibrationModels(end+1)=modelItem;selectedModelRow=numel(calibrationModels);refreshModelComparison();
        try,modelComparisonTable.Selection=[selectedModelRow 1];catch,end
        drawModelComparison([],[]);refreshValidationView([],[]);
        fitResultLabel.Text=sprintf('%s | degree %d | N=%d | mean %.5g nm | STD %.5g nm | 2STD %.5g nm | RMS %.5g nm | max|r| %.5g nm', ...
            positionDrop.Value,deg,numel(xpos),finalModel.MeanResidual,finalModel.STD,2*finalModel.STD,finalModel.RMS,finalModel.MaxAbsResidual);
        equationDisplay.Value={sprintf('%s | %s',modelItem.ModelID,finalModel.Equation), ...
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
        T=table(string(finalModel.PeakID(:)),finalModel.Pixel(:),finalModel.ReferenceWavelength(:), ...
            finalModel.FittedWavelength(:),finalModel.Residual(:),finalModel.LOOResidual(:),finalModel.DeletionMaxCurveChange(:), ...
            'VariableNames',{'PeakID','Pixel','Reference_nm','Fitted_nm','Residual_nm','LOO_residual_nm','Deletion_max_curve_change_nm'});
        writetable(T,fullfile(pn,[stem '_residuals.csv']));
        fid=fopen(fullfile(pn,[stem '_equation.txt']),'w');
        if fid>=0
            fprintf(fid,'WCC4SM wavelength calibration model\n%s\nPeak position: %s\nDegree: %d\nN: %d\nFit RMS: %.12g nm\nLOO RMS: %.12g nm\nLOO max abs: %.12g nm\nMax deletion influence: %.12g nm\nSTD: %.12g nm\nMax abs residual: %.12g nm\n', ...
                finalModel.Equation,finalModel.PositionMethod,finalModel.Degree,numel(finalModel.Pixel),finalModel.RMS,finalModel.LOORMS,finalModel.LOOMaxAbs,finalModel.MaxDeletionInfluence,finalModel.STD,finalModel.MaxAbsResidual);
            fprintf(fid,'Normalized coefficients: %s\nmu: %s\nNatural pixel coefficients: %s\n',mat2str(finalModel.Coefficients,16),mat2str(finalModel.Mu,16),mat2str(finalModel.NaturalCoefficients,16));fclose(fid);
        end
        topStatus.Text='Current calibration model saved (MAT + CSV + TXT)';
    end

    function importCalibrationModels(~,~)
        [fn,pn]=uigetfile('*.mat','Import calibration model(s)','MultiSelect','on');if isequal(fn,0),return;end
        if ischar(fn),fn={fn};end
        added=0;
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
                calibrationModels(end+1)=item;added=added+1; %#ok<AGROW>
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

    function selectModelRow(~,event)
        if isempty(event.Indices),selectedModelRow=0;else,selectedModelRow=event.Indices(1);end
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
        appliedModel=m;appliedModelName=char(name);D.calibratedWavelength=wl(:);mainAxisMode='Wavelength';axisButton.Text='X Axis: Wavelength  ⇄';
        appliedStatus.Text=sprintf('Applied model: %s | %s | degree %d | %.4g to %.4g nm',appliedModelName,m.PositionMethod,m.Degree,min(wl),max(wl));
        drawFull();if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
        plotTabs.SelectedTab=tabPlots;topStatus.Text=sprintf('%s applied to spectrum wavelength axis',appliedModelName);
    end

    function clearAppliedModel(~,~)
        appliedModel=emptyFinalModel();appliedModelName='';D.calibratedWavelength=[];mainAxisMode='Pixel';axisButton.Text='X Axis: Pixel  ⇄';
        appliedStatus.Text='Applied model: none | spectrum axis remains Pixel';drawFull();
        if selectedRow>0&&selectedRow<=numel(peaks)&&~isempty(peaks(selectedRow).Result),drawPeak(peaks(selectedRow).Result);showParameters(peaks(selectedRow).Result);end
        topStatus.Text='Applied calibration cleared; pixel coordinates restored';
    end

    function drawModelComparison(~,~)
        legend(axModelCompare,'off');cla(axModelCompare,'reset');styleAxes(axModelCompare,C);
        if isempty(calibrationModels),title(axModelCompare,'No stored calibration models');return;end
        cols=lines(max(1,numel(calibrationModels)));hold(axModelCompare,'on');
        for kk=1:numel(calibrationModels)
            m=calibrationModels(kk).Model;
            scatter(axModelCompare,m.ReferenceWavelength,m.Residual,32,cols(kk,:),'filled','DisplayName',sprintf('%s | %s d%d',calibrationModels(kk).ModelID,m.PositionMethod,m.Degree));
            [x,o]=sort(m.ReferenceWavelength);plot(axModelCompare,x,m.Residual(o),'-','Color',cols(kk,:),'HandleVisibility','off');
        end
        yline(axModelCompare,0,'-','Color',C.gray,'HandleVisibility','off');hold(axModelCompare,'off');grid(axModelCompare,'on');
        xlabel(axModelCompare,'Reference wavelength (nm)');ylabel(axModelCompare,'Reference - fitted (nm)');title(axModelCompare,'Residual overlays of stored calibration models');
        legend(axModelCompare,'Location','best','Interpreter','none');
    end

    function openResidualAnalysis(~,~)
        if ~finalModel.valid,uialert(fig,'Fit a final calibration model first.','No final model');return;end
        rf=uifigure('Name','WCC4SM V0.5.3 | Calibration Fit & Residual Analysis','Position',[120 90 1160 760],'Color',C.bg);
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
        dat=cell(numel(calibrationModels),11);
        for kk=1:numel(calibrationModels)
            mm=calibrationModels(kk);ff=mm.Model;
            if isfield(ff,'Equation'),eq=ff.Equation;else,eq='';end
            dat(kk,:)={mm.ModelID,mm.PairCount,mm.PositionMethod,mm.Degree,ff.RMS,ff.LOORMS,ff.LOOMaxAbs,ff.MaxDeletionInfluence,ff.STD,ff.MaxAbsResidual,eq};
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
        plotTabs.SelectedTab=tabPeakStatistics;
        topStatus.Text=sprintf('Peak parameter statistics refreshed from %d confirmed snapshots',n);
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

        n=numel(rows);centerNm=nan(n,1);fwhmNm=nan(n,1);erwNm=nan(n,1);
        for jj=1:n
            rr=peakDataset(rows(jj)).AnalysisResult;
            if isfinite(rr.CenterX)
                centerLambda=evaluateWavelengthModel(finalModel,rr.CenterX);
                centerLambda=centerLambda(1);
                if isfinite(rr.LeftHalfX)&&isfinite(rr.RightHalfX)
                    fwhmNm(jj)=evaluateWavelengthModel(finalModel,rr.RightHalfX)-evaluateWavelengthModel(finalModel,rr.LeftHalfX);
                end
                centerNm(jj)=centerLambda;
            end
            if ~isempty(rr.InterpX)&&~isempty(rr.InterpNetY)&&isfinite(rr.InterpolatedPeakY)&&rr.InterpolatedPeakY>0
                lambdaDense=evaluateWavelengthModel(finalModel,rr.InterpX);
                erwNm(jj)=trapz(lambdaDense,max(rr.InterpNetY,0))/rr.InterpolatedPeakY;
            end
        end
        [centerNm,order]=sort(centerNm);fwhmNm=fwhmNm(order);erwNm=erwNm(order);

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
            if sum(good)>=2&&(max(fwhmNm(good))-min(fwhmNm(good)))>eps
                fitCoef=polyfit(fwhmNm(good),erwNm(good),1);fitX=linspace(min(fwhmNm(good)),max(fwhmNm(good)),100);
                yHat=polyval(fitCoef,fwhmNm(good));ssTot=sum((erwNm(good)-mean(erwNm(good))).^2);
                if ssTot>eps,rSquared=1-sum((erwNm(good)-yHat).^2)/ssTot;else,rSquared=NaN;end
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
            meanFwhm=mean(validFwhm);medianFwhm=median(validFwhm);stdFwhm=std(validFwhm);
            minFwhm=min(validFwhm);maxFwhm=max(validFwhm);
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
        pixelAxis=D.pixel(:);lambdaAxis=evaluateWavelengthModel(finalModel,pixelAxis);
        intervalNm=diff(lambdaAxis);intervalWavelength=0.5*(lambdaAxis(1:end-1)+lambdaAxis(2:end));
        goodInterval=isfinite(intervalNm)&isfinite(intervalWavelength)&intervalNm>0;
        if any(goodInterval)
            plot(axPixelInterval,intervalWavelength(goodInterval),intervalNm(goodInterval),'-','Color',C.purple,'LineWidth',1.6);
            meanInterval=mean(intervalNm(goodInterval));minInterval=min(intervalNm(goodInterval));maxInterval=max(intervalNm(goodInterval));
            yline(axPixelInterval,meanInterval,'--',sprintf('Mean %.6g nm/pixel',meanInterval),'Color',C.red);
            xlabel(axPixelInterval,'Calibrated wavelength (nm)');ylabel(axPixelInterval,'Pixel wavelength interval (nm/pixel)');
            title(axPixelInterval,sprintf('Pixel wavelength interval | mean %.6g | min %.6g | max %.6g nm/pixel',meanInterval,minInterval,maxInterval));
            grid(axPixelInterval,'on');grid(axPixelInterval,'minor');
        else
            showNoStatistics(axPixelInterval,'Calibration model does not give positive pixel intervals');
        end
        plotTabs.SelectedTab=tabCalibratedStatistics;
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
        pf=figure('Name','WCC4SM V0.5.3 | Current spectrum plots','Color','white','Position',[100 80 1100 760]);
        t=tiledlayout(pf,2,1,'Padding','compact','TileSpacing','compact');
        if plotTabs.SelectedTab==tabMatchingPlots,s1=axMatchMeasured;s2=axMatchReference;else,s1=axFull;s2=axPeak;end
        a1=nexttile(t);copyAxesState(s1,a1);a2=nexttile(t);copyAxesState(s2,a2);
    end

    function openSelectedTabFigures(~,~)
        tabName=openFigDrop.Value;
        switch tabName
            case 'Peak Analysis'
                sourceAxes=[axFull axPeak];
            case 'Peak Parameter Statistics'
                sourceAxes=[axWidthTrend axWidthRelation axPositionDelta axPositionHistogram];
            case 'Wavelength Matching'
                sourceAxes=[axMatchMeasured axMatchReference];
            case 'Calibration Fit & Residuals'
                sourceAxes=[axFitResult axResidualResult axHistogramResult];
            case 'Model Validation'
                sourceAxes=[axLOO axInfluence];
            case 'Model Comparison'
                sourceAxes=axModelCompare;
            case 'Calibrated Performance'
                sourceAxes=[axCalWidthTrend axCalWidthRelation axCalPositionDelta axPixelInterval];
            otherwise
                uialert(fig,'Select a plot tab first.','Open Fig');
                return;
        end
        for kk=1:numel(sourceAxes)
            plotTitle=axesTitleText(sourceAxes(kk),sprintf('Subplot %d',kk));
            left=80+32*mod(kk-1,5);bottom=80+28*mod(kk-1,5);
            pf=figure('Name',sprintf('WCC4SM V0.5.3 | %s | %s',tabName,plotTitle), ...
                'NumberTitle','off','Color','white','Position',[left bottom 900 620]);
            targetAxes=axes('Parent',pf,'Position',[.10 .12 .85 .80]);
            copyAxesState(sourceAxes(kk),targetAxes);
        end
        topStatus.Text=sprintf('%s: opened %d editable figure(s)',tabName,numel(sourceAxes));
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
        copyobj(allchild(source),target);
        transferable={'XLim','YLim','XScale','YScale','XDir','YDir','XGrid','YGrid','XMinorGrid','YMinorGrid', ...
            'XTick','YTick','XTickLabel','YTickLabel','Box','Color','FontName','FontSize','LineWidth','ColorOrder'};
        for pp=1:numel(transferable)
            try,target.(transferable{pp})=source.(transferable{pp});catch,end
        end
        try,xlabel(target,source.XLabel.String,'Interpreter',source.XLabel.Interpreter);catch,xlabel(target,source.XLabel.String);end
        try,ylabel(target,source.YLabel.String,'Interpreter',source.YLabel.Interpreter);catch,ylabel(target,source.YLabel.String);end
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
    function refreshPeakTable
        dat=cell(numel(peaks),7);
        for i=1:numel(peaks), dat(i,:)={peaks(i).ID,peaks(i).Pixel,peaks(i).InputX,peaks(i).Height,peaks(i).Prominence,peaks(i).Width,peaks(i).Status}; end
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
            datRef=cell(numel(L.wavelength),4);
            for jj=1:numel(L.wavelength),datRef(jj,:)={L.effective(jj),L.intensity(jj),L.order(jj),st{jj}};end
            refTable.Data=datRef;
            lineInfo.Text=sprintf('%d lines | %s',numel(L.wavelength),shortName(L.source));
            active=find(~strcmp(st,'Out of range') & ~strcmp(st,'Disabled'));
            datActive=cell(numel(active),4);
            for jj=1:numel(active),q=active(jj);datActive(jj,:)={L.effective(q),L.intensity(q),spacing(q),st{q}};end
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
        if selectedRow>0 && selectedRow<=numel(peaks)
            k=peaks(selectedRow).Index; plot(axFull,x(k),yplot(k),'o','Color',C.red,'LineWidth',1.8,'MarkerSize',9,'HitTest','off');
        end
        hold(axFull,'off'); grid(axFull,'on'); xlabel(axFull,xlab); ylabel(axFull,ylab);
        ttl=['Full spectrum | ' shortName(D.source)];
        if strcmp(mainAxisMode,'Wavelength') && ~isempty(appliedModelName), ttl=[ttl ' | ' appliedModelName]; end
        title(axFull,ttl);
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
end

function M=cleanMatrix(M)
    M=M(~all(isnan(M),2),:); M=M(:,~all(isnan(M),1));
    if isempty(M),error('CSV contains no numeric data.');end
    if size(M,2)>2,M=M(:,1:2);end
end
function D=emptyData, D=struct('raw',[],'dark',[],'darkSource','','corrected',[],'normalized',[],'pixel',[],'inputX',[],'inputWavelength',[],'calibratedWavelength',[],'xKind','Pixel','source',''); end
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
    m=struct('ModelID',{},'CreatedAt',{},'PairCount',{},'PositionMethod',{},'Degree',{},'PairIDs',{},'Model',{});
end
function q=makeCalPair(id,idx,pixel,refIdx,refWavelength,ord,mode,locked,status,confidence)
    if nargin<10,confidence=NaN;end
    q=struct('PeakID',id,'PeakIndex',idx,'DetectionPixel',pixel,'ReferenceIndex',refIdx,'ReferenceWavelength',refWavelength, ...
        'Order',ord,'Mode',mode,'Confidence',confidence,'Locked',locked,'Status',status);
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
