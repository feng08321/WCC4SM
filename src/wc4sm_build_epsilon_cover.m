function cover = wc4sm_build_epsilon_cover(records,epsilonRMS,epsilonMAX)
%WC4SM_BUILD_EPSILON_COVER Assign subset models to engineering-equivalent representatives.
    if nargin<2||isempty(epsilonRMS),epsilonRMS=0.01;end
    if nargin<3||isempty(epsilonMAX),epsilonMAX=0.03;end
    if any(~isfinite([epsilonRMS epsilonMAX]))||epsilonRMS<0||epsilonMAX<0,error('WCC4SM:EpsilonInvalidThreshold','Epsilon thresholds must be nonnegative finite scalars.');end
    n=numel(records);assignment=zeros(n,1);representatives=zeros(0,1);members=cell(0,1);
    valid=arrayfun(@(r)strcmp(r.Status,'Available')&&~isempty(r.Curve)&&all(isfinite(r.Curve)),records);
    ids=find(valid);
    if ~isempty(ids)
        metric=[[records(ids).AllRMSE].',[records(ids).AllP95].',[records(ids).AllMAX].'];[~,ord]=sortrows(metric,[1 2 3]);ids=ids(ord);
    end
    for ii=ids(:).'
        assigned=0;
        for jj=1:numel(representatives)
            rr=representatives(jj);delta=records(ii).Curve-records(rr).Curve;
            if sqrt(mean(delta.^2))<=epsilonRMS && max(abs(delta))<=epsilonMAX,assigned=jj;break;end
        end
        if assigned==0
            representatives(end+1,1)=ii;members{end+1,1}=ii;assigned=numel(representatives); %#ok<AGROW>
        else
            members{assigned}(end+1)=ii;
        end
        assignment(ii)=assigned;
    end
    cover=struct('EpsilonRMS',epsilonRMS,'EpsilonMAX',epsilonMAX,'Assignment',assignment, ...
        'RepresentativeIndices',representatives,'Members',{members},'Count',numel(representatives));
end
