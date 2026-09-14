# WCC4SM V0.9.2 波长定标优化与可信性自验证功能扩展实施说明 v2.0

> **文档状态说明（2026-09-01）**：本文保留为 V0.9.2 功能扩展的设计与实施轨迹，不作为当前操作依据。当前软件的完整操作、统一指标、代码架构和验收口径，分别以《WCC4SM V0.9.3 用户操作与完整工作流程说明 V1.0》《WCC4SM V0.9.3 数据处理算法与统一指标说明 V1.0》《WCC4SM V0.9.3 软件架构与核心模块说明 V1.0》《WCC4SM V0.9.3 测试验证与验收说明 V1.0》为准。部分早期 Seed Set 和组合遍历描述仅用于追溯，当前主流程已发展为固定全池评价、任意集合逐一替换、分阶段 Set Design/Beam Search 和峰位定义交叉验证。

> **目标版本基础**：WCC4SM V0.9.2\
> **文档用途**：供 Codex 在现有 MATLAB 工程上实施功能扩展\
> **开发原则**：优先复用现有定标核心；先完成计算链和测试，再完善
> GUI；不破坏现有数据与模型兼容性。

------------------------------------------------------------------------

## 1. 开发背景与总体目标

现有 WCC4SM 已经具备波长定标、峰参数分析、参考谱线匹配、LOO
验证、删除单点影响分析、模型保存和模型比较等基础能力。

本次扩展不是重新实现一套波长定标算法，而是在现有代码架构上增加一套用于回答以下工程问题的分析功能：

1.  **推荐采用几阶波长定标方程？**
2.  **对于确定的模型阶次，数学上至少需要几个参考波长点？**
3.  **在给定允许波长误差条件下，工程上至少需要多少个定标点？**
4.  **推荐使用多少个定标点？**
5.  **这些定标点应该怎样选择和分布？**
6.  **增加一个新的参考点，对模型预测能力实际改善多少？**
7.  **剩余未参与定标的可靠参考谱线能否作为验证集，对定标结果进行自验证？**
8.  **如何区分拟合残差、交叉验证误差和工程意义上的波长定标准确度？**

总体分析流程：

``` text
可信参考波长池
      ↓
模型阶次扫描
      ↓
确定推荐模型阶次 m
      ↓
建立最小 Seed Set（m+1 点）
      ↓
Sequential Add-One
      ↓
定标点数—预测性能曲线
      ↓
工程最小点数 / 推荐点数区间
      ↓
Seed Set / 几何配置遍历验证
      ↓
形成可解释、可验证的定标方案
```

------------------------------------------------------------------------

## 2. 现有工程中应优先复用的模块

在开始修改前，请重新检查工程代码并确认以下模块的实际接口、输入输出和调用关系。

当前已识别的核心文件包括：

``` text
src/wc4sm_fit_calibration.m
src/wc4sm_validate_calibration_loo.m
src/wc4sm_calculate_calibrated_performance.m
WCC4SM_V0_9_2.m
tests/TestCalibrationModules.m
```

其中：

### `wc4sm_fit_calibration.m`

作为现有多项式波长定标核心，应继续作为所有新分析的统一拟合入口或底层核心。

**不要在新模块中重新写另一套 polyfit / polyval 定标逻辑。**

### `wc4sm_validate_calibration_loo.m`

现有 LOO 和单点删除影响功能应继续复用。

新增功能与其关系是互补，而不是替代：

``` text
LOO      ：删除一个已有参考点，评价该点的一致性和影响
Add-One  ：增加一个候选参考点，评价该点对模型的增益
```

### `WCC4SM_V0_9_2.m`

现有 GUI、模型管理、Model Comparison 和 Validation
页面应尽量扩展，而不是重新建立独立应用。

### `tests/TestCalibrationModules.m`

所有新增数学功能必须增加自动化测试，确保现有定标结果不因本次扩展而改变。

------------------------------------------------------------------------

# 3. 首先处理：拟合与 LOO 的最小样本数解耦

这是本次扩展的一个关键前置修改。

当前代码中需要检查类似以下限制：

``` matlab
if numel(pixel) < degree + 2
    ...
end
```

其逻辑来源是：现有拟合函数在完成拟合后立即执行 LOO，因此若模型阶次为
`m`，至少需要：

\[ N `\ge `{=tex}m+2 \]

才能删除一个样本后仍有：

\[ N-1 `\ge `{=tex}m+1 \]

个点完成同阶拟合。

但是本次新增的最小定标集研究要求允许：

\[ N\_{`\min`{=tex}}\^{math}=m+1 \]

例如三次模型：

\[ m=3,`\qquad `{=tex}N\_{`\min`{=tex}}\^{math}=4 \]

因此需要将：

``` text
基础拟合能力
```

与：

``` text
LOO 验证能力
```

在逻辑上解耦。

建议规则：

``` matlab
if N < degree + 1
    % 无法完成该阶多项式拟合
elseif N == degree + 1
    % 可以拟合
    % LOO unavailable
elseif N >= degree + 2
    % 可以拟合
    % 可以执行 LOO
end
```

当：

``` text
N = degree + 1
```

时：

-   正常返回拟合系数；
-   正常返回训练残差；
-   LOO 指标返回 `NaN` 或明确的 `Unavailable` 状态；
-   不得因为无法 LOO 而拒绝建立模型；
-   GUI 中应明确显示 `LOO: unavailable for minimum-size model`。

**不要仅将 `degree+2` 粗暴改为 `degree+1` 而保持原有 LOO 调用不变。**

------------------------------------------------------------------------

# 4. 统一参考波长池的数据概念

新增分析应建立在用户已经确认的可靠参考波长池上。

定义：

\[ D_R={R_i}\_{i=1}\^{N_R} \]

每个参考点至少包含：

``` text
ReferenceID
PixelPosition
ReferenceWavelength
```

如现有数据结构已经包含峰参数，应直接关联或复用：

``` text
Peak
FWHMCenter
Centroid
InterpolatedPeak
FWHM
ERW
SNR / Intensity
Peak quality flags
Reference-line identity
```

建议在不破坏旧模型文件兼容性的前提下增加或映射以下逻辑字段：

``` text
ReferenceValid
CalibrationSelected
ValidationOnly
ManualRequired
ManualExcluded
ApplicationPriority
QualityFlag
OrderType
```

这些字段可以先存在分析对象中，不要求立即改变所有历史模型的数据格式。

------------------------------------------------------------------------

# 5. 新增模块一：Model Order Scan

建议新增独立计算函数，例如：

``` text
src/wc4sm_analyze_model_order.m
```

具体文件名可根据现有命名规范调整。

## 5.1 输入

至少包括：

``` matlab
pixel
referenceWavelength
degreeRange
pixelEvaluationRange
options
```

默认：

``` matlab
degreeRange = 1:7;
```

## 5.2 对每个阶次 m 计算

完整可信参考池拟合：

\[ `\hat`{=tex}`\lambda`{=tex}*m(p) = `\sum`{=tex}*{r=0}^{m}a_rp^r \]

输出至少包括：

### Fit

\[ RMSE\_{fit}(m) \]

\[ MAX\_{fit}(m)=`\max`{=tex}\_i \|e_i\| \]

\[ STD\_{fit}(m) \]

残差自由度：

\[ `\nu`{=tex}=N_R-(m+1) \]

### LOO

若满足：

\[ N_R`\ge `{=tex}m+2 \]

则计算：

\[ RMSE\_{LOO}(m) \]

\[ MAX\_{LOO}(m) \]

以及逐点 LOO residual。

### Deletion influence

复用现有删除单点分析。

对每个点：

\[ `\Delta`{=tex}*i(p) = `\hat `{=tex}f(p)-`\hat `{=tex}f*{(-i)}(p) \]

计算：

\[ I\_{i,RMS} = `\sqrt{
\frac1P
\sum_{p=1}^{P}
\Delta_i^2(p)
}`{=tex} \]

以及现有或新增：

\[ I\_{i,MAX} = `\max`{=tex}\_p\|`\Delta`{=tex}\_i(p)\| \]

阶次层面至少汇总：

``` text
MeanDeletionRMS
MedianDeletionRMS
MaxDeletionRMS
MaxDeletionCurveChange
```

------------------------------------------------------------------------

# 6. 模型阶次推荐逻辑

**禁止默认采用最小 Fit RMSE 对应的最高阶模型作为推荐模型。**

训练残差随模型自由度增加通常下降，因此 Fit RMSE
主要用于观察欠拟合到平台区的变化。

推荐应综合：

``` text
Fit residual structure
LOO RMSE
LOO maximum error
Deletion influence
Model complexity
```

建议计算：

\[ G_m= `\frac{
RMSE_{LOO}(m-1)-RMSE_{LOO}(m)
}{
RMSE_{LOO}(m-1)
}`{=tex} \]

作为增加一个阶次的相对预测收益。

同时计算：

\[ E\_{min} = `\min`{=tex}*m RMSE*{LOO}(m) \]

给定可配置容差：

\[ `\tau`{=tex}\_m \]

例如默认：

``` text
5 %
```

可以给出一个启发式推荐：

\[ RMSE\_{LOO}(m) `\le`{=tex} (1+`\tau`{=tex}*m)E*{min} \]

的最低阶次，并同时要求 deletion influence 没有明显恶化。

软件输出：

``` text
Recommended degree by heuristic: m
```

但必须允许用户人工确认或修改。

------------------------------------------------------------------------

# 7. Model Order Scan 图形

新增：

``` text
Model Order Analysis
```

至少显示：

``` text
Degree
Fit RMSE
LOO RMSE
MAX LOO Error
Maximum Deletion Influence
```

另提供：

``` text
Residual vs Wavelength by Degree
```

用于观察：

``` text
低阶：是否存在系统性残差结构
适阶：系统结构是否基本消失
高阶：是否主要在吸收单个参考点的位置误差
```

------------------------------------------------------------------------

# 8. 新增模块二：Seed Calibration Set

固定推荐阶次：

\[ m \]

数学最小样本数：

\[ N\_{`\min`{=tex}}\^{math}=m+1 \]

例如：

``` text
degree = 3
minimum seed size = 4
```

软件应允许用户从可靠参考池中人工选择 Seed Set。

当前研究中的工程先验可以是：

``` text
短波端约束点
长波端约束点
内部代表点
内部曲率/应用区域补充点
```

但：

**不得把任何具体波长硬编码进算法。**

Seed Set 必须是用户可编辑的。

------------------------------------------------------------------------

# 9. 最小 Seed Set 的评价原则

当：

\[ N=m+1 \]

时，多项式可能精确通过全部定标点，因此：

\[ RMSE\_{fit}`\approx0`{=tex} \]

此时训练残差几乎没有模型评价意义。

因此 Seed Set 必须用：

``` text
未参与建模的可靠参考波长点
```

进行评价。

设：

\[ C_k \]

为当前 calibration set，则：

\[ V_k=D_R`\setminus `{=tex}C_k \]

对所有：

\[ i`\in `{=tex}V_k \]

计算：

\[ e\_{i,val}\^{(k)} = `\lambda`{=tex}\_i-`\hat `{=tex}f_k(p_i) \]

并得到：

\[ RMSE\_{val}(k) \]

\[ MAX\_{val}(k) \]

\[ P95\_{val}(k) \]

其中：

``` text
P95 = percentile(abs(validation residual),95)
```

------------------------------------------------------------------------

# 10. 新增模块三：Sequential Add-One Analysis

建议新增核心函数，例如：

``` text
src/wc4sm_analyze_add_one.m
```

其功能是：

给定当前：

\[ C_k \]

遍历所有：

\[ j`\in `{=tex}D_R`\setminus `{=tex}C_k \]

建立：

\[ C\_{k,+j}=C_k`\cup`{=tex}{j} \]

然后分别拟合：

\[ `\hat `{=tex}f\_{k,+j} \]

并评价每一个候选新增点的实际贡献。

------------------------------------------------------------------------

# 11. Add-One 的主要评价指标

**不得以 Fit RMSE reduction 作为主要候选排序指标。**

主要评价未参与当前模型的可靠参考线预测误差。

当前模型：

\[ E_k=RMSE\_{val}(k) \]

增加候选点 (j) 后：

\[ E\_{k,+j}=RMSE\_{val}(k,+j) \]

定义：

\[ Gain\_{k,j} = E_k-E\_{k,+j} \]

相对收益：

\[ Gain\_{k,j}\^{rel} = `\frac{E_k-E_{k,+j}}{E_k}`{=tex} \]

同时输出：

``` text
NewValidationRMSE
NewValidationMAX
NewValidationP95
Gain
RelativeGain
```

------------------------------------------------------------------------

# 12. Dynamic Validation 与 Fixed Validation

Add-One 至少支持两种模式。

## 12.1 Dynamic Remaining-Points Validation

默认工程探索模式。

每次增加候选点后：

``` text
当前 calibration set = 已选择点
当前 validation set = 可靠参考池中剩余所有点
```

优点：

-   充分利用现有参考点；
-   适合探索最小/推荐定标集；
-   与逐步加点逻辑自然一致。

缺点：

不同候选模型的验证集合会因候选点被加入 calibration set 而相差一个点。

因此结果界面应注明：

``` text
Dynamic hold-out validation is intended for sequential engineering selection.
```

## 12.2 Fixed Validation Pool

正式论文分析应支持该模式。

用户预先指定：

\[ D_R=D\_{candidate}`\cup `{=tex}D\_{validation} \]

且：

\[ D\_{candidate}`\cap `{=tex}D\_{validation}=`\varnothing`{=tex} \]

Add-One 只能从：

\[ D\_{candidate} \]

中选择。

所有候选模型始终使用同一：

\[ D\_{validation} \]

进行比较。

------------------------------------------------------------------------

# 13. Add-One 候选排名

每轮生成完整候选表：

  -----------------------------------------------------------------------------------------------
  Rank   Ref     λref   Pixel   RMSEval   Gain Gain %   MAXval    P95   ΔModel   ΔModel Quality
         ID                                                                RMS      MAX 
  ------ ----- ------ ------- --------- ------ ------ -------- ------ -------- -------- ---------

  -----------------------------------------------------------------------------------------------

默认主排序建议：

``` text
1. Validation RMSE
2. Validation MAX
3. Model stability / full-model deviation
```

不要强制唯一自动选择。

输出：

``` text
Best candidate
Equivalent candidates
```

定义可配置的近似等效阈值，例如：

\[ Gain_j`\ge`{=tex}0.95Gain\_{best} \]

用户可以：

``` text
Accept Best
Select Another Candidate
Undo Last Add
```

------------------------------------------------------------------------

# 14. 与完整参考模型的差异

如果用户将全部可靠参考点模型定义为：

``` text
Full Reference Model
```

例如当前研究中的40点模型，则每个子集模型可与之比较：

\[ `\Delta`{=tex}*k(p) = `\hat `{=tex}f_k(p)-`\hat `{=tex}f*{ref}(p) \]

计算：

\[ D\_{RMS}(k) = `\sqrt{
\frac1P
\sum_p\Delta_k^2(p)
}`{=tex} \]

\[ D\_{MAX}(k) = `\max`{=tex}\_p\|`\Delta`{=tex}\_k(p)\| \]

必须统一使用相同像元范围。

界面及报告中称为：

``` text
Deviation from Full Reference Model
```

**不得称为 True Error 或 Ground Truth Error。**

完整40点模型本身仍然是一个估计模型，而不是绝对真值。

------------------------------------------------------------------------

# 15. 新增模块四：Calibration Sufficiency Analysis

Sequential Add-One 得到：

\[ C\_{m+1}, C\_{m+2}, C\_{m+3}, `\ldots`{=tex} \]

形成：

``` text
Calibration Set Size vs Predictive Performance
```

建议新增函数或由 Add-One history 直接生成。

横轴：

\[ N\_{cal} \]

纵轴至少包括：

``` text
Validation RMSE
Validation P95
Validation MAX
Deviation from Full Model RMS
Deviation from Full Model MAX
```

如果已有稳定性指标，也同时显示。

------------------------------------------------------------------------

# 16. 数学最小点数、工程最小点数与推荐点数

软件应明确区分三个概念。

## 16.1 数学最小点数

\[ N\_{`\min`{=tex}}\^{math}=m+1 \]

仅表示模型数学可解。

## 16.2 工程最小点数

用户输入允许误差，例如：

``` text
Target Validation RMSE
Target Validation MAX
```

定义：

\[ N\_{`\min`{=tex}}\^{eng} = `\min`{=tex} `\left`{=tex}{ N:
RMSE\_{val}(N)`\le `{=tex}T\_{RMS}, MAX\_{val}(N)`\le `{=tex}T\_{MAX}
`\right`{=tex}} \]

建议要求连续2或3个点数等级均满足要求后再标记，以避免偶然波动。

## 16.3 推荐点数

推荐点数不要求唯一，可以输出：

``` text
Recommended range: N1 – N2
```

例如研究结果未来可能出现：

``` text
7–9 points
```

但程序不得预设具体数值。

定义边际改善：

\[ B_N = `\frac{
RMSE_{val}(N-1)-RMSE_{val}(N)
}{
RMSE_{val}(N-1)
}`{=tex} \]

若连续若干次：

\[ B_N\<`\tau`{=tex}\_N \]

则标记：

``` text
Performance plateau reached
```

默认阈值可设置为5%，但必须允许用户修改。

------------------------------------------------------------------------

# 17. 精度分档输出

不要只输出一个"最佳方案"。

软件应允许比较不同操作复杂度下的定标能力，例如：

    Ncal   RMSEval   P95   MAXval   Full-model ΔMAX Status
  ------ --------- ----- -------- ----------------- --------
       4       ...   ...      ...               ... ...
       5       ...   ...      ...               ... ...
       6       ...   ...      ...               ... ...
       7       ...   ...      ...               ... ...
     ...       ...   ...      ...               ... ...

研究目的之一是回答：

``` text
如果应用只要求某一级波长精度，5点是否已经足够？
如果要求更高精度，增加到7、9、10或更多点能够改善多少？
继续增加点以后何时进入收益平台？
```

------------------------------------------------------------------------

# 18. 新增模块五：Seed Set 递进替换验证

建议新增：

``` text
src/wc4sm_analyze_seed_replacements.m
```

用于确认人工选择的 5 点 Seed Set 是否存在明显可替换的成员，而不再执行 `C(n,5)` 的全组合穷举。

------------------------------------------------------------------------

# 19. 逐点替换流程

1. 用户在 **Optimization** 页人工确认恰好 5 个 Seed 点；
2. 将原始 Seed 集之外的全部可靠参考点固定为共同验证池；
3. 依次剔除 5 个 Seed 点中的一个，形成 5 轮验证；
4. 每轮遍历每个非 Seed 点作为补充点，保持 Seed 集大小仍为 5；
5. 对原始 Seed 集和每个替换集，都在同一固定验证池上计算 `RMSE`、`P95` 与 `MAX`；
6. 每轮保留 `RMSE` 最小的替换方案，并以 `Delta RMSE = RMSEreplacement - RMSEbaseline` 判断是否优于原样本。

总拟合次数为：

\[
5 \times (N-5)
\]

其中 `N` 为可靠参考点数量；这避免了组合数随 `N` 急剧增长的 `C(N,5)` 穷举。

输出表每行对应一个被剔除的 Seed 点，显示其最佳补充点、验证误差及是否改善。若 5 行均为“不改善”，则人工 Seed 集在单点替换意义下可予以确认。

------------------------------------------------------------------------
# 20. 定标集合几何指标

每个组合至少计算：

## Coverage

\[ Coverage = `\lambda`{=tex}*{max,cal}-`\lambda`{=tex}*{min,cal} \]

## Coverage Ratio

\[ CoverageRatio = `\frac{
\lambda_{max,cal}-\lambda_{min,cal}
}{
\lambda_{max,R}-\lambda_{min,R}
}`{=tex} \]

## Maximum Gap

排序后：

\[ Gap\_{max} = `\max`{=tex}*i(`\lambda`{=tex}*{i+1}-`\lambda`{=tex}\_i)
\]

## Mean Gap

\[ Gap\_{mean} \]

## Gap CV

\[ CV\_{gap} = `\frac{STD(Gap)}{Mean(Gap)}`{=tex} \]

## Left Edge Distance

\[ d_L= `\lambda`{=tex}*{first,cal}-`\lambda`{=tex}*{min,R} \]

## Right Edge Distance

\[ d_R= `\lambda`{=tex}*{max,R}-`\lambda`{=tex}*{last,cal} \]

这些量用于检验优秀定标集合是否具有：

``` text
端点约束
全谱覆盖
较小最大空白区
合理内部间距
```

------------------------------------------------------------------------

# 21. 替换结果判读

每一轮只报告一个最佳替换方案：

``` text
Removed seed index
Best replacement index
Baseline RMSE
Replacement RMSE
Delta RMSE
Improved / Not improved
```

判读规则：

``` text
Delta RMSE < 0  ：该被剔除 Seed 点存在更优替换候选；
Delta RMSE >= 0 ：保留该人工 Seed 点。
```

若五轮均没有改善，说明该人工确认的 5 点 Seed Set 已通过单点替换自验证；若出现改善，用户可结合峰形、谱线归属与覆盖范围人工决定是否采纳该替换，再重新运行五轮验证。

------------------------------------------------------------------------
# 22. 应用关键波段

允许用户定义：

``` text
Application Regions
```

例如：

``` matlab
[lambdaStart lambdaEnd]
```

可以有多个区域。

对于每个模型额外计算：

\[ RMSE\_{region} \]

\[ MAX\_{region} \]

本版本中 Application Region 默认只用于：

``` text
局部性能报告
候选点标签
可选排序参考
```

**不要默认改变全谱最小二乘拟合权重。**

如未来需要应用加权拟合，应作为独立功能开发。

------------------------------------------------------------------------

# 23. LOO / Leave-N-Out 的定位

现有 LOO 功能继续保留，其工程意义定义为：

``` text
Reference-line consistency and single-sample influence diagnosis
```

即：

``` text
如果不使用该波长点，其余参考点所支持的连续映射能否正确预测它？
```

LOO 异常点后续可结合峰参数分析其物理原因，例如：

``` text
邻峰干扰
像差导致的非对称峰形
杂散光
二阶衍射
欠采样/像素采样相位
随机噪声
错误谱线匹配
```

后续可扩展：

``` text
Leave-2-Out
Leave-3-Out
```

用于研究多个参考点的联合影响。

但本次开发优先级低于：

``` text
Model Order Scan
Add-One
Calibration Sufficiency
Seed Combination Validation
```

------------------------------------------------------------------------

# 24. GUI 集成建议

尽量在现有 Calibration / Model Comparison / Validation 工作流附近增加：

``` text
Calibration Optimization
```

而不是新建独立应用。

建议包含以下区域。

## Reference Pool

显示：

``` text
Valid
Calibration
Validation
Excluded
Required
```

## Model Order

按钮：

``` text
Scan Degree 1–7
```

## Seed Set

按钮：

``` text
Create Seed Set
Validate Seed Set
Analyze Seed Combinations
```

## Add-One

显示当前：

``` text
Current calibration set size: N
```

按钮：

``` text
Evaluate All Candidates
Add Best
Add Selected
Undo
```

## Sufficiency

显示：

``` text
Mathematical Minimum
Engineering Minimum
Recommended Range
Performance Plateau
```

------------------------------------------------------------------------

# 25. 模型与分析结果追溯

每个生成模型必须保留：

``` text
ModelID
ParentModelID
CreationMode
PolynomialDegree
CalibrationReferenceIDs
ValidationReferenceIDs
AddedReferenceID
Coefficients
FitRMSE
FitMAX
LOORMSE
LOOMAX
ValidationRMSE
ValidationP95
ValidationMAX
DeletionInfluence
FullModelDeviationRMS
FullModelDeviationMAX
Timestamp
```

`CreationMode` 建议至少支持：

``` text
Manual
OrderScan
AddOne
SeedCombination
```

Add-One 应能够完整重建：

``` text
4 → 5 → 6 → 7 → ... → N
```

的选择路径。

------------------------------------------------------------------------

# 26. 数据导出

新增分析必须支持 CSV 导出。

至少输出：

## Model Order Results

每行一个模型阶次。

## Add-One History

每行一个定标点数。

## Add-One Candidate Ranking

**每一轮所有候选点都必须保存。**

不能只保存最终被选中的候选点。

## Seed Combination Results

每行一个组合，包含：

``` text
Reference IDs
Validation metrics
Geometry metrics
Full-model deviation
```

这些数据后续直接用于论文作图和统计分析。

------------------------------------------------------------------------

# 27. 自动化测试

在：

``` text
tests/TestCalibrationModules.m
```

或按现有测试架构新增测试文件。

至少覆盖：

## Test A：三次已知函数

生成：

\[ `\lambda`{=tex}=a_0+a_1p+a_2p^2+a_3p^3 \]

加入小扰动。

验证：

``` text
Model Order Scan 正常工作
三次附近进入性能平台
高阶 Fit RMSE 可以继续下降
高阶 LOO 不一定继续改善
```

## Test B：4点三次模型

仅用4点建立三次模型。

必须验证：

``` text
Fit succeeds
Fit RMSE ≈ 0
LOO = unavailable
Remaining-point validation works
```

这是本次开发最重要的边界测试之一。

## Test C：端点约束

构造平滑非线性色散关系。

比较：

``` text
包含端点的4点集合
缺失端点的4点集合
```

检查边界预测误差和 Full Model Deviation。

## Test D：Add-One

构造一个已知候选点加入后可明显改善预测性能的数据集。

确认该点在候选排名中表现靠前。

## Test E：异常参考点

人为给某参考点加入位置/波长偏差。

验证：

``` text
LOO residual responds
Deletion influence responds
No automatic deletion occurs
```

## Test F：旧功能回归

使用现有测试数据确认：

``` text
原有模型系数
原有 Fit RMSE
原有 LOO
原有 Model Comparison
```

在允许的数值精度范围内保持不变。

------------------------------------------------------------------------

# 28. 推荐开发顺序

## Phase 1：计算核心

先完成：

``` text
Fit / LOO minimum-size decoupling
Model Order Scan
Remaining-point validation helper
Sequential Add-One
CSV output
Unit tests
```

此阶段 GUI 可以非常简单。

先使用当前真实40点数据验证数学结果。

## Phase 2：定标充分性

增加：

``` text
Calibration Set Size vs Predictive Performance
Engineering Minimum
Recommended Range
Performance Plateau
```

## Phase 3：Seed / Geometry

增加：

``` text
Seed Set Exhaustive Validation
Geometry Metrics
Selection Frequency
```

## Phase 4：GUI 完善

将上述功能完整集成到现有界面。

## Phase 5：后续扩展

再考虑：

``` text
Leave-2-Out
Leave-3-Out
Joint influence
Application-region weighting
Automated scientific report
```

------------------------------------------------------------------------

# 29. Codex 开始工作前必须先做的事情

不要立即修改代码。

第一步先完整阅读：

``` text
项目目录
波长拟合核心
参考点数据结构
LOO
删除影响
模型保存
Model Comparison
GUI
Tests
```

然后先输出一份简短的实施计划，明确：

1.  实际拟合核心在哪里；
2.  `wc4sm_fit_calibration` 的当前输入输出；
3.  LOO 当前如何调用；
4.  当前模型结构体保存哪些字段；
5.  Reference/Peak 数据如何关联；
6.  新功能建议新增哪些文件；
7.  哪些现有文件必须修改；
8.  如何保持旧模型兼容；
9.  测试计划；
10. 分阶段提交计划。

确认方案后再实施。

------------------------------------------------------------------------

# 30. 编程约束

1.  **不要复制实现第二套波长拟合核心。**
2.  优先复用 `wc4sm_fit_calibration` 及现有 helper。
3.  新计算逻辑尽量放在 `src` 独立函数中，不把算法全部塞进 GUI 回调。
4.  GUI 负责输入、显示和状态管理，不承担核心数学计算。
5.  所有自动推荐必须可被用户覆盖。
6.  不自动删除异常谱线。
7.  不把高 LOO 点自动判定为坏点。
8.  不把 Full Reference Model 当作绝对真值。
9.  不把 Fit RMSE 标记为 `Instrument Wavelength Accuracy`。
10. 所有结果必须可以保存、导出和复算。
11. 尽量保持现有数据文件向后兼容。
12. 若必须修改模型结构，加载旧模型时必须给新增字段提供默认值。
13. 不为了本功能进行无关的大规模重构。
14. 如果发现当前架构必须重构才能安全实现，应先解释原因再修改。

------------------------------------------------------------------------

# 31. 科研统计上的重要注意事项

## 31.1 Fit RMSE 不是最终验证指标

特别是：

\[ N=m+1 \]

时 Fit RMSE 可能接近零。

不能据此宣称模型具有极高波长准确度。

## 31.2 LOO 与 Add-One 回答不同问题

``` text
LOO:
这个已有点是否与其余参考点支持的模型一致？

Add-One:
增加哪个新点能够最大程度改善当前定标模型？
```

## 31.3 Full Reference Model 不是 Ground Truth

40点模型可作为高冗余参考模型，但仍然包含：

``` text
峰位测量误差
参考谱线不确定性
模型近似误差
仪器物理误差
```

因此只允许使用：

``` text
Deviation from Full Reference Model
```

## 31.4 波长点不是统计平权样本

后续分析应保留：

``` text
峰质量权重
几何位置价值
应用区域价值
```

这三个概念的扩展空间，但本版本不要未经验证就强行合成为一个总权重。

------------------------------------------------------------------------

# 32. 本次功能的最终工程输出

完成后，WCC4SM 应能够从一组高可信参考谱线出发，系统回答：

### 模型阶次

``` text
What polynomial degree is sufficient?
```

### 数学最小集合

\[ N\_{`\min`{=tex}}\^{math}=m+1 \]

### 工程最小集合

``` text
What is the smallest calibration set that satisfies a specified error requirement?
```

### 推荐集合

``` text
At what calibration-set size does predictive performance enter a practical plateau?
```

### 点位配置

``` text
What geometric distribution of reference lines produces reliable calibration?
```

### 自验证

``` text
Can the unused reliable reference lines verify the calibration model?
```

最终软件功能链应从：

``` text
Wavelength Calibration
```

扩展为：

``` text
Wavelength Calibration
        ↓
Model Optimization
        ↓
Calibration-Set Design
        ↓
Validation
        ↓
Reliability Characterization
```

------------------------------------------------------------------------

# 33. 第一轮实现的验收目标

第一轮不要追求完整 GUI。

只要能够使用当前可靠参考波长数据完成以下计算，即视为第一阶段成功：

``` text
[1] degree = 1:7 模型阶次扫描
[2] 允许 degree=3, N=4 建模
[3] 4点模型不执行非法 LOO
[4] 4点模型可以对剩余参考池进行预测验证
[5] 从4点开始执行 Add-One
[6] 每轮遍历全部剩余候选点
[7] 输出候选排名
[8] 用户确认新增点
[9] 形成 4→5→6→... 的选择路径
[10] 输出 Ncal vs Validation RMSE / P95 / MAX
[11] 全部结果可导出 CSV
[12] 原有定标、LOO 和 Model Comparison 回归测试通过
```

完成这一阶段后，先不要继续大规模扩展。

使用真实40点数据检查：

``` text
推荐阶次是否合理
Add-One 路径是否符合物理直觉
预测误差是否出现平台
端点/内部点的选择行为是否合理
不同 Seed Set 是否显著改变结果
```

确认这些结果后，再进入 Seed Set Exhaustive Validation 和完整 GUI 开发。

------------------------------------------------------------------------

# 34. 交互确认与结果辨识补充

为避免多模型、多轮次残差点重叠后仅靠图例难以辨识，界面补充以下交互规则：

1. 在 Model Comparison 表格中选中模型后，该模型残差点放大、增加按参考波长排序的辅助连线，并在图内显示 ModelID、峰位方法、阶次和残差模式。
2. 在 Seed 逐点替换结果表中选中轮次后，该轮残差点放大、增加按像素排序的辅助连线，并显示轮次和验证 RMSE。
3. 辅助连线只用于辨识当前选中数据，不改变残差统计，也不表示采样过程具有时间顺序。
4. Seed 替换验证不再自动写入 Model Comparison。计算完成后只生成待确认推荐模型，用户点击“Add recommended model to comparison”并确认后才加入模型列表。
5. Point Influence 页恢复“Analyze sample response”入口，用于执行删除单点后的样本响应/影响度分析。
6. Calibration Optimization 与 Point Influence 顶部工具区采用显式网格定位，避免按钮文字遮挡；Seed 结果表上方的空白布局行已移除。
7. 样本响应和 Seed 替换残差使用两个独立图轴，通过“Sample response”和“Seed replacement residuals”子页切换；轮次切换和重新计算前重置 Seed 图轴，避免历史连线、图例或 hold 状态残留。
8. Calibration Optimization 增加 Peak position 选择，Add-One 与 Seed replacement 均通过与最终定标一致的峰位提取逻辑获得坐标，默认使用 FWHM center，不再直接使用整数 DetectionPixel。
9. Add-One 默认 Keep=0，允许路径运行到完整标杆集合；历史表和曲线分别显示 Fit RMSE 与 All-point RMSE。当 Ncal 等于标杆集合大小时，两者必须在数值精度范围内一致，并显示 FullSetRMSEGap。
10. Seed 逐一替换、Seed stability 和推荐模型生成复用同一 Optimization 输入集合、Peak position 与 Degree。替换轮次表同时显示 Fit RMSE 和固定验证池 Validation RMSE；峰位方法或阶次改变时旧 Seed 结果自动失效，避免不同口径结果混用。
11. 新增 Selected Residuals 统一诊断页。选择模型、Add-One轮次、模型阶次、Seed stability 或Seed替换轮次后，诊断页同步显示逐点残差趋势和残差直方图；趋势图叠加5点移动均值，用于辅助识别尚未被拟合消除的低频结构。
12. Selected Residuals 直方图支持 Bins、Auto full、Symmetric、正负3 STD和Manual X范围，配置方式与 Calibration Fit & Residuals 页一致；同时报告N、RMS、Mean、STD、Skew和超额峰度，并随Session保存范围设置。

------------------------------------------------------------------------

**文档版本：v2.0**\
**定位：基于 WCC4SM V0.9.2 现有架构的功能扩展实施说明**\
**当前优先级：先实现可验证的计算核心，再扩展科研分析与 GUI。**

------------------------------------------------------------------------

# 35. 样本删除影响的空间坐标观察

Point Influence 页的样本响应图支持三种横轴：Sample index、Pixel 和
Wavelength。三种显示复用同一次删除单点计算结果，只改变横轴坐标，不改变
Residual、Deleted RMS、Curve change 或 Deletion influence 的定义。

Wavelength 模式采用匹配参考波长，Pixel 模式采用参与拟合的峰像素坐标；两者
可用于识别边界代表点、局部稀疏区代表点和波长聚集区，而 Sample index 继续
用于与表格行快速对应。显示坐标和影响分析阶次随 Session 保存、恢复。

影响分析阶次范围由 1--6 扩展为 1--12。6 阶以上用于敏感性与剩余结构诊断，
不能仅根据影响柱降低或升高决定最终阶次；需要同时检查拟合残差、LOO、残差
趋势/直方图，以及高阶多项式在光谱边界处的杠杆放大和振荡风险。

------------------------------------------------------------------------

# 36. 影响阶次统计、统一纵轴与任意集合替换

## 36.1 统一纵轴比较

Sample response 子页增加 Y axis 设置。Auto 保持每次结果自适应，Manual 允许
输入 Y min 和 Y max。手动范围在切换阶次、样本序号/像素/波长横轴时保持不变，
并随 Session 保存，用于在相同尺度下比较不同多项式阶次的影响强度。

## 36.2 影响阶次扫描

Scan influence 1..k 使用手动设置的 Scan max，对同一匹配样本池自动执行
m=1--k 的删除单点分析。界面允许的统一上限为20；为保证删除任一点后仍可
执行内部 LOO，实际 k 不超过 N-3。软件对每阶全部有限 InfluenceRatio 统计：

- Mean influence；
- RMS influence；
- P95 influence；
- MAX influence。

同时报告完整模型的 Fit/LOO RMSE，以及所有点删除模型的 pooled
Deletion Fit/LOO RMSE。前四种 Influence 统计为无量纲量，误差曲线单位为 nm，
分别放在对数纵轴图中，不能把 RMS influence 解释为 Fit RMSE。

点击统计表中的某一阶，下面的样本影响图立即切换到该阶结果，并继续使用当前
横轴和手动 Y 轴范围。该统计用于描述模型对单点删除的总体敏感程度；它不能
单独代替残差趋势、LOO 和边界振荡检查。

## 36.3 任意已选集合的一换一分析

原 Seed replacement 放宽为 selected-set replacement。Optimization 表中的选中
点构成当前建模集合，每个选中点依次被删除，并遍历所有未选有效点作为替代点。
设选中点数为 K、未选候选数为 C，则总试验数为 K×C，并输出 K 个轮次的最佳
替换结果。K 不再固定为5，但必须满足 K≥degree+1，且 C≥1。

Add-One 仍保留“初始种子集合”的含义；本节只解除一换一替换分析的5点限制。
当全部有效点均被选中时，不存在集合外替换候选，软件会提示至少保留一个未选点。
旧的 SeedIndices 和 BestByRemovedSeed 结果字段继续保留，作为已有调用和Session
的兼容别名；新增 SelectedIndices 和 BestByRemovedPoint 表达一般集合语义。

------------------------------------------------------------------------

# 37. Point Influence 工作区拆分

随着影响阶次扫描和一般集合替换功能增加，Point Influence 页不再让两类任务
共用同一张结果表。页内拆分为两个完整子工作区：

- Sample influence：包含单阶影响计算、1--10阶扫描、影响结果/统计表、横轴和
  统一Y轴设置、样本影响图；
- Set replacement：包含RMSE阈值、验证池、集合替换计算、独立轮次表、替换
  残差图和手动加入Model Comparison入口。

两个工作区的表格和图形对象相互独立。重新运行样本影响分析不会覆盖集合替换
轮次；执行集合替换也不会清除影响阶次统计。Optimization中的集合选择或峰位
方法发生变化时，旧集合替换结果和待加入推荐模型失效，但已完成的样本影响
结果只在校准匹配对本身变化时刷新。

------------------------------------------------------------------------

# 38. 基于影响画像的子样本集设计空间

拟合阶次确定为3以后，样本影响分析不再只是一次绘图，而应固化为与当前匹配
样本池绑定的 Influence profile，并作为子样本集设计的输入。该功能不继续堆叠
在 Point Influence 页，建议新增 Calibration Set Design 工作区。

## 38.1 Influence profile 与排序

每个样本至少保存以下字段：Peak ID、Pixel、Reference wavelength、degree=3下的
InfluenceRatio、Influence rank、Influence percentile、Curve change、Residual、
峰对称性推荐、局部波长密度、是否位于短波/长波边界。

影响强度不能直接等同于样本质量，推荐采用二维分类：

- 高影响且峰质量可靠：Representative anchor，优先保留；
- 高影响但峰质量可疑：Critical review，必须人工复核；
- 中等影响：Coverage support，用于维持局部覆盖；
- 低影响且处于密集波长簇：Replaceable candidate，优先作为替换候选。

表格支持按影响值、排名、波长、局部密度和质量状态排序/筛选。影响画像必须记录
匹配样本池、峰位方法、degree和生成时间；上述输入变化后旧画像标记为失效。

## 38.2 手动子样本集空间

Manual 子页提供两种入口：

1. Top-k辅助：用户输入k，将影响排名前k的可靠样本设为必选点，再由人工从其余
   样本补足目标集合；Top-k不应直接等同于最终子集，因为高影响点可能集中在边界；
2. Experience only：不要求已有影响画像，用户根据峰质量、波长覆盖和经验直接
   勾选，保存为具名候选集合。

每个候选集合保存来源、样本ID、目标K、必选点、人工备注和创建时间，允许复制、
修改和锁定，不直接覆盖当前最终定标模型。

## 38.3 计算机辅助生成空间

Assisted generation 子页建议按以下优先级提供策略：

1. Wavelength-stratified maximin：波长分层后最大化最小间距，确定性强，作为默认；
2. Influence + coverage constrained：保留可靠高影响点，同时约束边界、分段覆盖和
   最大波长空隙；
3. Constrained Monte Carlo：在相同约束下随机生成大量不重复集合，用于探索多个
   近似等价解，而不是无约束随机抽样。

生成参数包括目标K或K范围、候选数、随机种子、必选/禁选点、波长分段数、最大
允许空隙、峰质量阈值。随机种子必须保存以保证结果可复现。

对每个候选集合均采用同一37点标杆池评价，并明确区分 Fit RMSE 与 All-point
Validation RMSE。建议输出：All-point RMSE/P95/MAX、LOO RMS、Influence P95/MAX、
最大波长空隙、边界覆盖、残差趋势指标和计算状态。

## 38.4 排名与比较

候选集合不建议只压缩成单一总分。首先剔除不满足硬约束的集合，再保留RMSE、P95、
MAX、稳定性和覆盖度上的Pareto候选。可提供可调权重总分作为排序辅助，但必须同时
显示原始指标。

Subset comparison 子页显示候选集合表、样本位置分布、全标杆池残差、残差直方图
和影响统计。用户确认后才将某个子样本模型加入Model Comparison；自动生成过程
不得直接修改当前应用模型。

推荐工作流为：

``` text
Degree 3 influence profile
        -> manual / assisted subset generation
        -> fixed 37-point benchmark evaluation
        -> Pareto shortlist
        -> residual and influence review
        -> manual addition to Model Comparison
```

需要同时提示：候选集合是在同一37点池上生成并评价，排名存在选择乐观偏差；最终
确认应使用独立光谱、重复测量或后续批次数据复核，而不能把37点标杆池视为绝对真值。

## 39. Set Design 与分层 Beam Search

新增独立 Set Design 工作区，避免样本影响、集合替换和子集搜索相互覆盖结果。工作区包含：

- 固定三阶模型的样本影响排名、对称性质量、局部波长间距和边界标识；
- Manual、Top-k influence、Maximin coverage、Locked boundary + coverage 及分窗规则生成；
- 在统一全样本池上的 Fit RMSE、All-point RMSE/P95/MAX 和相对全集模型距离；
- 基于 D_RMS 与 D_MAX 双阈值的 ε-cover；
- 可暂停的 Initialize Beam -> Calculate K-1 -> Confirm checked 逐层搜索；
- 候选的 Pending、Accepted、Rejected 状态和跨轮次保留；
- 确认集合发送到 Add-One，以及手动确认后加入 Model Comparison。

Beam 每次只计算一次删除层。计算候选不会改变当前父集合，用户确认后才推进；若只保留一个候选则退化为人工辅助贪心删除，保留多个性能/多样性候选时才保持 Beam 的路径覆盖能力。Beam 批量候选拟合跳过内部 LOO，以降低计算量，但所有候选均使用同一个完整标杆池计算验证残差；加入模型比较时重新执行完整 LOO。

## 40. Set Design 可理解性、持久化与导出

Set Design 左侧增加 Full pool / manual selection 与 Selected subset members 两个子页。选中右侧候选集合时，完整池的 Use 掩码同步更新，成员子页列出该集合实际包含的 Peak ID、像素、波长、Influence、排名、峰质量、局部间距和边界属性。

页面增加 Guide，统一解释 Target K、B perf、B div、eps RMS、eps MAX，以及 Fit RMSE、All-point RMSE/P95/MAX、模型距离、Influence、Quality 和 Cover。推荐以 3+3、5+5、10+10 进行 Beam 宽度敏感性检查，而不是仅按单次最低 RMSE 自动确定最终集合。

Session 新增可选 SetDesign 状态，保存影响档案、规则候选、Beam 节点、当前层与 Pending 候选、父子路径、成员掩码、当前选择和全部参数；旧版 Session 没有该字段时仍按空状态加载。

Export results 同时输出完整 MAT 状态、完整池 CSV、候选指标 CSV、候选成员长表 CSV 和 Beam 层级 CSV。相关详细说明见《WCC4SM_V0.9.2_Set_Design操作与指标说明》。
