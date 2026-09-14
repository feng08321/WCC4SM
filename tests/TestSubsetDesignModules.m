classdef TestSubsetDesignModules < matlab.unittest.TestCase
    methods (Test)
        function evaluatesFullPoolWithSharedMetric(testCase)
            p=(1:12).';w=300+0.42*p+0.002*p.^2+0.004*sin(p);
            ids=arrayfun(@(k)sprintf('P%02d',k),(1:12).','UniformOutput',false);
            baseline=wc4sm_fit_calibration(p,w,2,p,'FWHM center',ids);
            r=wc4sm_evaluate_subset(p,w,true(12,1),2,p,baseline, ...
                struct('PeakIDs',{ids},'PositionMethod','FWHM center'));
            testCase.verifyEqual(r.K,12);
            testCase.verifyEqual(r.AllRMSE,r.FitRMSE,'AbsTol',1e-12);
            testCase.verifyEqual(r.DistanceRMS,0,'AbsTol',1e-12);
            testCase.verifyEqual(r.DistanceMAX,0,'AbsTol',1e-12);
        end

        function skipLooSupportsFastCandidateFit(testCase)
            p=(1:8).';w=300+0.4*p+0.003*p.^2;
            m=wc4sm_fit_calibration(p,w,2,p,'Test',{},struct('SkipLOO',true));
            testCase.verifyTrue(all(isnan(m.LOOResidual)));
            testCase.verifyEqual(m.LOOStatus,'Skipped for batch search');
        end

        function deterministicGeneratorsHonorTargetAndBoundary(testCase)
            w=[300 302 310 350 430 600 800 1000].';
            influence=[1 8 2 7 3 6 4 5].';
            a=wc4sm_generate_subset_mask(w,4,'Top-k influence',struct('Influence',influence));
            testCase.verifyEqual(a.SelectedIndices,[2 4 6 8]);
            b=wc4sm_generate_subset_mask(w,5,'Locked boundary + coverage');
            testCase.verifyEqual(sum(b.Mask),5);
            testCase.verifyTrue(b.Mask(1)&&b.Mask(end));
            manual=false(8,1);manual([1 3 6 8])=true;
            c=wc4sm_generate_subset_mask(w,4,'Manual selection',struct('ManualMask',manual));
            testCase.verifyEqual(c.Mask,manual);
        end

        function epsilonCoverUsesBothCurveThresholds(testCase)
            template=struct('Status','Available','Curve',[],'AllRMSE',0,'AllP95',0,'AllMAX',0);
            r=repmat(template,3,1);r(1).Curve=[0 0 0].';r(2).Curve=[.004 .004 .004].';
            r(3).Curve=[0 .05 0].';r(2).AllRMSE=.01;r(3).AllRMSE=.02;
            cover=wc4sm_build_epsilon_cover(r,.01,.03);
            testCase.verifyEqual(cover.Assignment(1),cover.Assignment(2));
            testCase.verifyNotEqual(cover.Assignment(1),cover.Assignment(3));
            testCase.verifyEqual(cover.Count,2);
        end

        function stagedBeamDoesNotAdvanceBeforeConfirmation(testCase)
            p=(1:9).';w=300+0.41*p+0.002*p.^2+0.006*sin(p);
            options=struct('BPerf',2,'BDiv',2,'EpsilonRMS',.002,'EpsilonMAX',.006);
            state=wc4sm_initialize_backward_beam(p,w,2,5,p,options);
            [state,proposal]=wc4sm_backward_beam_step(state);
            testCase.verifyEqual(proposal.K,8);
            testCase.verifyEqual(state.CurrentNodeIDs,1);
            testCase.verifyEqual(state.Nodes(1).K,9);
            testCase.verifyNotEmpty(state.PendingCandidates);
            [state,accepted]=wc4sm_accept_beam_layer(state,proposal.RecommendedRows);
            testCase.verifyTrue(all([state.Nodes(accepted).K]==8));
            testCase.verifyEmpty(state.PendingCandidates);
            testCase.verifyFalse(state.Complete);
            while ~state.Complete
                [state,proposal]=wc4sm_backward_beam_step(state);
                [state,~]=wc4sm_accept_beam_layer(state,proposal.RecommendedRows);
            end
            testCase.verifyTrue(all([state.Nodes(state.CurrentNodeIDs).K]==5));
            testCase.verifyEqual([state.Layers.K],9:-1:5);
            testCase.verifyEqual(state.Status,sprintf('Target K=5 reached; %d subsets retained',numel(state.CurrentNodeIDs)));
        end
    end
end
