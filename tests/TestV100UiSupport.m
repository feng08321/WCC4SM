classdef TestV100UiSupport < matlab.unittest.TestCase
    methods (Test)
        function sourceUsesV100EntryPointAndKeepsV093Available(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            wrapper = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V0_9_3.m'));
            testCase.verifySubstring(src,'function WCC4SM_V1_0');
            testCase.verifySubstring(src,'WCC4SM V1.0');
            testCase.verifySubstring(wrapper,'function WCC4SM_V0_9_3');
        end
        function sourceInitializesAllStateDomains(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'State.Data = wc4sm_empty_state_data();');
            testCase.verifySubstring(src,'State.Peaks = wc4sm_empty_state_peaks();');
            testCase.verifySubstring(src,'State.Design = wc4sm_empty_state_design();');
            testCase.verifySubstring(src,'State.UI = wc4sm_empty_state_ui();');
        end
        function sourceProvidesFullSpectrumRangeControls(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'fullViewStart');
            testCase.verifySubstring(src,'fullViewEnd');
            testCase.verifySubstring(src,'resetFullViewRange');
        end
        function sourceProvidesEightByEightPeakShapeGallery(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''8x8 peak-shape gallery''');
            testCase.verifySubstring(src,'peakGalleryAxes=gobjects(0)');
            testCase.verifySubstring(src,'function ensurePeakGalleryAxes');
            testCase.verifySubstring(src,'function refreshPeakGallery');
            testCase.verifySubstring(src,'galleryTitle=sprintf(''%s | %.3f nm''');
            testCase.verifySubstring(src,'ax.XTick=[];ax.YTick=[]');
            testCase.verifySubstring(src,'''MarkerFaceColor'',C.yellow');
            testCase.verifySubstring(src,'matchedIDs==string(p.ID)');
            testCase.verifySubstring(src,'useWavelength=strcmp(State.UI.MainAxisMode,''Wavelength'')&&appliedModel.valid');
            testCase.verifySubstring(src,'function openPeakGalleryFigure');
        end
        function sourceProvidesMatchingAnnotationToggle(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'Show matching annotations');
            testCase.verifySubstring(src,'showMatchingCheck.Value');
        end
        function sourceDisablesTeXForSpectrumTitles(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,"title(axFull,ttl,'Interpreter','none')");
        end
        function sourceProvidesSelectedResidualDiagnostics(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'Selected Residuals');
            testCase.verifySubstring(src,'function setSelectedResidualDiagnostics');
            testCase.verifySubstring(src,'selectedResidualHistogramSettings(r)');
            testCase.verifySubstring(src,'Excess kurtosis');
        end
        function sourceProvidesInteractivePeakPositionDifferenceMap(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Peak Position Differences''');
            testCase.verifySubstring(src,'''Pixel difference'',''Wavelength difference''');
            testCase.verifySubstring(src,'''Center wavelength'',''Center pixel''');
            testCase.verifyFalse(contains(src,'''Center wavelength'',''Center pixel'',''Reference wavelength'''));
            testCase.verifySubstring(src,'function drawPeakPositionDifferenceMap');
            testCase.verifySubstring(src,'function drawPeakDifferenceRelationDiagnostics');
            testCase.verifySubstring(src,'''No fit'',''Degree 1'',''Degree 2'',''Degree 3''');
            testCase.verifySubstring(src,'''Direct peak'',''Centroid'',''Interpolated peak''');
            testCase.verifySubstring(src,'xFit=centerCoordinate');
            testCase.verifySubstring(src,'positionMatrix=[directNm centroidNm interpNm]');
            testCase.verifySubstring(src,'''FWHM center position (''');
            testCase.verifySubstring(src,'''MarkerSize'',6');
            testCase.verifySubstring(src,'''MarkerFaceColor'',seriesColor{seriesColumn}');
            testCase.verifySubstring(src,'''MarkerFaceColor'',C.sky');
            testCase.verifySubstring(src,'plot(axPeakDifferenceFit,fitX,fitY,''--''');
            testCase.verifySubstring(src,'''Text'',''Difference series''');
            testCase.verifySubstring(src,'if strcmp(peakDifferenceSeries.Value,''Direct - center''),distributionColumn=1');
            testCase.verifyFalse(contains(src,'peakDifferenceDistributionTarget=uidropdown'));
            testCase.verifySubstring(src,'peakDifferenceDistributionBinCount');
            testCase.verifySubstring(src,'peakDifferenceDistributionHistogramSettings');
            testCase.verifySubstring(src,'peakDifferenceResidualHistogramSettings');
            testCase.verifySubstring(src,'dataTipTextRow(''Peak ID''');
            testCase.verifySubstring(src,'sourceAxes=[axPeakDifferenceMap axPeakDifferenceFit axPeakDifferenceDistribution axPeakDifferenceHistogram]');
            testCase.verifySubstring(src,'''PeakDifferenceUnit'',peakDifferenceUnit.Value');
            testCase.verifySubstring(src,'''PeakDifferenceFitOrder'',peakDifferenceFitOrder.Value');
        end
        function sourceProvidesPhysicalAxesForPointInfluence(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Limits'',[1 20]');
            testCase.verifySubstring(src,'{''Sample index'',''Pixel'',''Wavelength''}');
            testCase.verifySubstring(src,'function drawPointInfluence');
            testCase.verifySubstring(src,'x=[p.Wavelength];xLabel=''Reference wavelength (nm)''');
            testCase.verifySubstring(src,'''InfluenceXAxisMode'',influenceXAxisMode.Value');
            testCase.verifySubstring(src,'influencePositionMethod=uidropdown');
            testCase.verifySubstring(src,'analysisInputsForPosition(influencePositionMethod.Value)');
            testCase.verifySubstring(src,'''InfluencePositionMethod'',influencePositionMethod.Value');
            testCase.verifySubstring(src,'restoreControl(influencePositionMethod,s,''InfluencePositionMethod'')');
        end
        function sourceProvidesPaperPeakDifferenceWorkspace(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Peak-position wavelength dependence''');
            testCase.verifySubstring(src,'axPaperAllPeakDifferences');
            testCase.verifySubstring(src,'axPaperCentroidDifference');
            testCase.verifySubstring(src,'wc4sm_fit_peak_position_difference');
            testCase.verifySubstring(src,'''No fit'',''Degree 1'',''Degree 2'',''Degree 3''');
            testCase.verifySubstring(src,'''CentroidMinusFWHMCenter_pixel''');
            testCase.verifySubstring(src,'paperPeakDifferenceTableEdited');
            testCase.verifySubstring(src,'paperPeakDifferencePointClicked');
            testCase.verifySubstring(src,'''PaperPeakDifferenceExcludedIDs''');
            testCase.verifySubstring(src,'''PaperPeakAllExcludedIDs''');
            testCase.verifySubstring(src,'paperAllPeakTableEdited');
            testCase.verifySubstring(src,'''Analysis excluded''');
            testCase.verifySubstring(src,'''Show'',''Peak''');
            testCase.verifySubstring(src,'''PaperPeakDifferenceFitOrder''');
            testCase.verifySubstring(src,'poly2str(r.Fit.Coefficients,''z'')');
            testCase.verifySubstring(src,'''Title'',''Peak-difference dataset''');
            testCase.verifySubstring(src,'paperAllPeakTable');
            testCase.verifySubstring(src,'paperCalibrationPeakTable');
            testCase.verifySubstring(src,'paperShowDirect');
            testCase.verifySubstring(src,'paperPeakDifferenceFitSeries');
            testCase.verifySubstring(src,'paperShowCalibrationOnly');
            testCase.verifySubstring(src,'''SelectedDifferenceType''');
            testCase.verifySubstring(src,'paperShowInterpolated');
            testCase.verifySubstring(src,'paperShowCentroid');
            testCase.verifySubstring(src,'function paperConfirmDeletePeaks');
            testCase.verifySubstring(src,'function paperAddSelectedPeak');
            testCase.verifySubstring(src,'''PaperPeakPairArchive''');
            testCase.verifySubstring(src,'r.Fit.FitY+2*sigma');
            testCase.verifySubstring(src,'r.Fit.FitY+3*sigma');
            testCase.verifySubstring(src,'togglePaperPeakHighlight(source.UserData.IDs{q})');
        end
        function sourceProvidesInfluenceOrderStatisticsAndFixedYAxis(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'Scan influence 1..k');
            testCase.verifySubstring(src,'wc4sm_analyze_influence_orders');
            testCase.verifySubstring(src,'''Mean influence'',''RMS influence'',''P95 influence'',''MAX influence''');
            testCase.verifySubstring(src,'influenceYMode');
            testCase.verifySubstring(src,'ylim(influenceAxes,[lo hi])');
            testCase.verifySubstring(src,'influenceMaxOrder');
            testCase.verifySubstring(src,'function drawInfluenceOrderCurves');
            testCase.verifySubstring(src,'Deleted-model LOO RMSE');
            testCase.verifySubstring(src,'InfluenceMaxOrder');
            testCase.verifySubstring(src,'influenceOrderStatsAxes.YScale=''log''');
            testCase.verifySubstring(src,'influenceDeletionErrorAxes.YScale=''log''');
            testCase.verifySubstring(src,'influenceFullErrorAxes.YScale=''log''');
            testCase.verifySubstring(src,'''Title'',''Full Fit vs LOO''');
            testCase.verifySubstring(src,'''Title'',''Generalization gap''');
            testCase.verifySubstring(src,'''Title'',''Deletion stability''');
            testCase.verifySubstring(src,'''Title'',''Influence statistics''');
            testCase.verifySubstring(src,'influenceDiagnosticTabs.SelectedTab==influenceOrderPlotTab');
            testCase.verifySubstring(src,'FullGeneralizationGap');
            testCase.verifySubstring(src,'DeletionGeneralizationGap');
            testCase.verifySubstring(src,'sourceAxes=[influenceFullErrorAxes influenceGapAxes influenceDeletionErrorAxes influenceOrderStatsAxes]');
            testCase.verifyFalse(contains(src,'sourceAxes=[influenceAxes seedReplacementAxes]'));
        end
        function sourceProvidesPeakPositionCrossValidationWorkspace(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Peak-position cross validation''');
            testCase.verifySubstring(src,'wc4sm_cross_validate_peak_positions');
            testCase.verifySubstring(src,'''All-method common peaks (recommended)'',''Per-pair available peaks''');
            testCase.verifySubstring(src,'''ItemsData'',{''Common intersection'',''Pairwise available''}');
            testCase.verifySubstring(src,'''Text'',''Matrix metric''');
            testCase.verifySubstring(src,'''ColumnWidth'',{58,72,78,64}');
            testCase.verifySubstring(src,'''Row = calibration | Column = application.''');
            testCase.verifySubstring(src,'State.Design.PositionCrossResult.CalibrationFitCount');
            testCase.verifySubstring(src,'State.Design.PositionCrossResult.ElapsedSeconds');
            testCase.verifySubstring(src,'State.UI.PositionCrossBusy');
            testCase.verifySubstring(src,'''Calculating ...''');
            testCase.verifySubstring(src,'uiprogressdlg');
            testCase.verifySubstring(src,'finishPositionCrossRun');
            testCase.verifySubstring(src,'''All matched pairs'',''Current final model'',''Selected comparison model'',''Selected Set Design candidate''');
            testCase.verifySubstring(src,'''TrainingMask'',trainingMask');
            testCase.verifySubstring(src,'''EvaluationMask'',true(numel(peakIDs),1)');
            testCase.verifySubstring(src,'''PositionCrossTrainingSource'',positionCrossTrainingSource.Value');
            testCase.verifySubstring(src,'train N=%d | eval N=%d');
            testCase.verifySubstring(src,'positionCrossGrid.RowHeight={124,''1x'',''1x''}');
            testCase.verifySubstring(src,'positionCrossStatus.Layout.Column=[1 8]');
            testCase.verifySubstring(src,'positionCrossSelectionLabel.Layout.Column=[5 7]');
            testCase.verifySubstring(src,'''Title'',''All metrics''');
            testCase.verifySubstring(src,'positionCrossViewRoot=uigridlayout(positionCrossValidationTab,[1 1])');
            testCase.verifySubstring(src,'positionCrossViewTabs=uitabgroup(positionCrossViewRoot)');
            testCase.verifySubstring(src,'''Title'',''Calibration-row residuals''');
            testCase.verifySubstring(src,'''Title'',''All histograms''');
            testCase.verifySubstring(src,'positionCrossMetricOverviewAxes=gobjects(1,6)');
            testCase.verifySubstring(src,'positionCrossRowResidualAxes=gobjects(1,4)');
            testCase.verifySubstring(src,'positionCrossHistogramOverviewAxes=gobjects(4,4)');
            testCase.verifySubstring(src,'openPositionCrossAxesGrid');
            testCase.verifySubstring(src,'''PositionCrossView'',positionCrossViewTabs.SelectedTab.Title');
            testCase.verifySubstring(src,'''Selected cell'',''Selected calibration row'',''Diagonal comparison''');
            testCase.verifySubstring(src,'positionCrossHeatmapAxes');
            testCase.verifySubstring(src,'''PositionCrossValidation'',State.Design.PositionCrossResult');
            testCase.verifySubstring(src,'sourceAxes=[positionCrossHeatmapAxes positionCrossResidualAxes positionCrossHistogramAxes]');
        end
        function sourceUsesLogarithmicModelOrderDiagnostics(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'optimizationAxes.YScale=''log''');
            testCase.verifySubstring(src,'Full Fit RMSE');
            testCase.verifySubstring(src,'DeletionLOORMSE');
        end
        function sourceProvidesArbitrarySetReplacement(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'Validate selected-set replacements');
            testCase.verifyFalse(contains(src,'Select exactly 5 manual seed points'));
            testCase.verifySubstring(src,'''Removed point''');
            testCase.verifySubstring(src,'Leave at least one valid pair unselected');
        end
        function sourceSeparatesInfluenceAndReplacementWorkspaces(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Sample influence''');
            testCase.verifySubstring(src,'''Title'',''Set replacement''');
            testCase.verifySubstring(src,'replacementTable=uitable');
            testCase.verifySubstring(src,'function selectReplacementResultRow');
            testCase.verifySubstring(src,'function clearReplacementResults');
            testCase.verifyFalse(contains(src,'influencePlotTabs'));
        end
        function sourceProvidesStagedSetDesignWorkspace(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Set Design''');
            testCase.verifySubstring(src,'Calculate K-1');
            testCase.verifySubstring(src,'Confirm checked');
            testCase.verifySubstring(src,'wc4sm_backward_beam_step');
            testCase.verifySubstring(src,'wc4sm_accept_beam_layer');
            testCase.verifySubstring(src,'Add model to comparison');
            testCase.verifySubstring(src,'Send to Add-One');
        end
        function sourceProvidesWindowPartitionWorkspace(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'''Title'',''Window Partition''');
            testCase.verifySubstring(src,'''Equal wavelength width'',''Equal cumulative influence''');
            testCase.verifySubstring(src,'wc4sm_partition_subset_windows');
            testCase.verifySubstring(src,'Full-set residual with window boundaries');
            testCase.verifySubstring(src,'Show cumulative curve');
            testCase.verifySubstring(src,'WindowPartition'',State.Design.SubsetWindowPartition');
            testCase.verifySubstring(src,'''_windows.csv''');
            testCase.verifySubstring(src,'sourceAxes=[windowResidualAxes windowInfluenceAxes]');
            testCase.verifySubstring(src,'dualYAxis=numel(source.YAxis)>1');
        end
        function sourceProvidesSetDesignMembersGuideExportAndSession(testCase)
            src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))),'WCC4SM_V1_0.m'));
            testCase.verifySubstring(src,'Selected subset members');
            testCase.verifySubstring(src,'setDesignSelectedTable');
            testCase.verifySubstring(src,'function showSetDesignGuide');
            testCase.verifySubstring(src,'function exportSetDesignResults');
            testCase.verifySubstring(src,'''SetDesign'',captureSetDesignState()');
            testCase.verifySubstring(src,'function restoreSetDesignSessionState');
            testCase.verifySubstring(src,'''_members.csv''');
            testCase.verifySubstring(src,'''_beam_layers.csv''');
        end
    end
end

