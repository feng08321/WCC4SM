# WCC4SM V0.9.3 用户操作与完整工作流程说明 V1.0

文档版本：V1.0  
适用软件：WCC4SM V0.9.3  
编制日期：2026-09-01  
文档属性：用户操作权威说明

## 1. 文档目的

本说明面向首次使用者和需要复现实验过程的操作者，按照真实界面顺序说明从光谱导入、峰确认、参考线匹配、波长定标，到模型诊断、样本影响分析、子集设计和结果导出的完整流程。

软件功能较多，但日常操作不要求使用全部研究工具。建议先完成标准定标流程，再按实际问题进入模型优化与 Set Design。

## 2. 软件用途与边界

WCC4SM 用于：

- 读取线光谱测量数据并进行暗信号或常量基线修正；
- 自动检测谱峰及在局部子窗口中补充极弱峰；
- 计算峰位、FWHM、ERW、质心和峰形质量指标；
- 管理可追溯参考谱线及峰—参考波长配对；
- 拟合波长定标多项式并执行 LOO、残差和样本影响分析；
- 比较、应用和导出多个定标模型；
- 从完整标杆池生成并评价较小的定标子样本集；
- 保存和恢复完整工作 Session。

软件不会自动证明参考线配对正确，也不能用较小拟合残差替代对峰形、像素模式、边界覆盖和独立数据的判断。

## 3. 推荐的两级工作流程

### 3.1 标准定标流程

测量光谱导入  
→ 预处理与显示检查  
→ 自动寻峰和弱峰补充  
→ 单峰分析与人工确认  
→ 参考谱线选择  
→ 建立峰—波长配对  
→ 最终模型拟合  
→ 残差、LOO 和模型比较  
→ 应用与导出模型

### 3.2 研究与优化流程

完整标杆池  
→ 模型阶次比较  
→ 样本影响分析  
→ 峰形质量筛选  
→ 规则子集生成或分层 Beam Search  
→ Add-One / 集合替换验证  
→ 代表模型比较  
→ 独立光谱或重复测量复核

只有在标准流程的数据、配对和完整池已经可信后，才建议进入第二级流程。

## 4. 启动与文件准备

### 4.1 MATLAB 环境

- MATLAB R2022a 或更高版本；
- Signal Processing Toolbox，用于 findpeaks；
- 将完整软件包放在本机可写目录；
- MATLAB Current Folder 设置为软件包根目录；
- 推荐启动命令：WCC4SM_V0_9_3。
- 兼容启动命令：WCC4SM_V0_9_2；该入口会提示版本兼容信息并启动 V0.9.3。

### 4.2 建议准备

- 测量光谱 CSV；
- 与测量条件一致的暗光谱 CSV，可选；
- 参考谱线主库或项目内置 Hg-Ar 参考数据；
- 已有参考线选择模式，可选；
- 仪器编号、型号、操作者、测量时间和参考数据来源；
- 独立或重复测量光谱，用于最终复核。

### 4.3 建议结果目录

每次实验应使用独立目录，至少分为 session、model、peak-data、set-design 和 notes。Session 与导出的 CSV/MAT 应作为同一次分析的配套记录保存。

## 5. 界面区域

### 5.1 顶部

- OPEN FIG：把当前选择的中央图形页弹出为可编辑 MATLAB Figure；
- SAVE SESSION：保存完整分析状态；
- LOAD SESSION：恢复已保存状态；
- HELP：打开帮助和 About；
- 状态文本：显示最近一次成功操作或错误提示。

### 5.2 左侧工作页

- Data & Display：输入解释、像素模式、预处理和显示；
- Peak Detection：全谱寻峰及峰窗参数；
- Current Peak：当前峰参数、警告和确认；
- Reference Lines：参考谱线主库及选择模式。

### 5.3 中央分析页

包括 Peak Analysis、Peak Parameter Statistics、Wavelength Matching、Calibration Fit & Residuals、Model Validation、Model Comparison、Selected Residuals、Calibrated Performance、Calibration Optimization、Point Influence 和 Set Design。

### 5.4 右侧工作页

- Peak List：检测峰清单和峰对称性建议；
- Peak Dataset：已确认峰数据集；
- Matching：峰—参考波长配对；
- Calibration Fit：最终定标模型拟合和导出。

## 6. 导入光谱与坐标解释

### 6.1 Two-column X

加载两列 CSV 前必须确认第一列含义：

- Wavelength (nm)：输入文件第一列是已有波长轴，但软件仍建立独立自然像素序列用于重新定标；
- Pixel index：第一列是像素相关坐标。

该设置只解释输入文件，不能自动判断文件含义。

### 6.2 Pixel sequence

- Full detector sequence：输入覆盖完整探测器像素序列；
- Valid-pixel sequence：输入只包含仪器有效裁剪区。

像素模式是模型身份的一部分。不同模式的模型不能在未核实坐标映射时直接互换。

### 6.3 加载与预处理

1. 在 Data & Display 选择输入解释和像素模式；
2. 点击 Load spectrum CSV；
3. 如有暗光谱，点击 Load dark spectrum；
4. 无暗光谱时可输入 Manual baseline；
5. 根据需要启用 Set negative values to zero；
6. 检查 Corrected、Normalized 和 Raw 信号；
7. 根据强弱峰跨度选择 Linear 或 Log 显示。

预处理的基本关系为：校正信号 = 原始信号 - 暗信号，或原始信号 - 手动常量基线；启用非负截断后将负值设为零。

## 7. 全谱寻峰

在 Peak Detection 中设置：

- Search normalized signal；
- Min peak height；
- Min prominence；
- Min distance；
- Min width 和 Max width；
- 峰窗左右像素数；
- 插值方法和插值倍数。

点击 CONFIRM & DETECT ALL PEAKS 后才执行寻峰。调整参数本身不会自动重新运行，便于操作者先完成参数检查。

寻峰后应检查：

- 强峰是否漏检；
- 噪声是否被误识别；
- 相邻峰是否被错误合并；
- 极弱边界峰是否需要子窗口补充。

## 8. 弱峰子窗口搜索

OPEN SUBWINDOW SEARCH 使用独立的局部归一化和灵敏参数，仅在指定像素窗口产生候选峰。

推荐步骤：

1. 在全谱图确定弱峰大致范围；
2. 设置局部窗口；
3. 降低局部峰高或突出度阈值；
4. 检测候选；
5. 检查候选位置和峰形；
6. 将选中的候选加入 Peak List；
7. 返回标准单峰分析进行确认。

局部候选不会在未确认时直接成为定标样本。

## 9. 单峰分析与确认

从 Peak List 选择峰后，在 Current Peak 点击 Analyze / Refresh。

主要峰位定义：

- Direct peak position：离散采样最大值位置；
- Interpolated peak position：插值曲线局部最大值；
- FWHM center position：半高宽左右交点的中心；
- Centroid position：峰窗内质心；
- Gaussian fit：高斯拟合位置，仅在适用时使用。

其他主要指标：

- FWHM：半高全宽；
- ERW：等效矩形宽度；
- ERW/FWHM：峰形宽度关系；
- Centroid-Center：质心与 FWHM 中心之差；
- Sampling ratio：宽度相对于采样间隔的比例；
- Peak area：基线修正后的峰面积。

确认前应阅读警告区。若窗口内有多峰、基线修正后大量负值、交点不完整或峰形明显偏斜，应调整窗口或标记为需要复核。

CONFIRM PEAK PARAMETERS 保存当前结果；CONFIRM & NEXT 保存并移动到下一峰。

### 9.1 Peak Position Differences

在 Peak Parameter Statistics > Peak Position Differences 中，可比较 Direct peak、Interpolated peak、FWHM center 和 Centroid 四种峰位定义。

- 左上图：所选峰位相对 FWHM center 的差值随中心像素或中心波长的变化；
- 左下图：与左上图同步的差值直方图；
- 右上图：以 FWHM center 为横轴、所选峰位为纵轴的直接映射，可选择不拟合或 1～3 阶拟合；
- 右下图：右上拟合的残差直方图。

图中的差值、拟合和残差使用同一个所选峰位序列。该页用于观察峰形非对称性引起的系统偏移，不等同于定标模型误差。Centroid 描述窗口内能量质心，FWHM center 更接近常用中心定位；两者的差异可随波长呈现结构趋势。

## 10. 峰对称性建议与标杆池

Peak List 中的 Symmetry 使用：

绝对值（Centroid position - FWHM center position）

默认阈值为 0.2 pixel。小于阈值显示 Recommended，否则显示 Review 或 Unavailable。

该标识只描述峰形对称性建议：

- 不代表参考线配对一定正确；
- 不代表该点对模型影响一定较大；
- 不应单独作为删除样本的依据。

完整标杆池应综合峰形、配对可信度、波长覆盖、重复测量和 LOO 结果确定。

## 11. 参考谱线管理

Reference Lines 显示参考主库、强度、衍射级次、局部间距和状态。

- Recommended：在当前分辨率假设下可优先使用；
- Marginal：与相邻线接近，需要结合仪器分辨率判断；
- Unresolved：可能无法由当前仪器分开；
- Disabled：保留在主库中，但从当前选择模式排除；
- Out of range：超出当前分析范围。

参考主库是可追溯来源，选择模式只是从主库中启用或禁用谱线。不要为了获得较小残差而修改参考波长数值。

Use selected line 和 Disable selected line 改变当前选择状态；Import/Export selection mode 用于复用选择模式。

## 12. 峰—参考波长匹配

建议先人工建立约六个分布较广的锚点：

1. 在 Peak Dataset 或 Matching 中确认待配对峰；
2. 在 Reference Lines 选择参考波长；
3. 点击 Pair peak with selected reference line；
4. 对明显可靠的点使用 Lock；
5. 点击 Update model 建立初始模型；
6. 检查 Wavelength Matching 图中的局部对应；
7. 使用 Auto extend 扩展候选配对；
8. 审查置信度后再锁定高置信度配对。

初始模型只用于辅助扩大匹配，不等同于最终定标模型。错误锚点可能使自动扩展整体偏移，因此必须先确认锚点的物理对应关系。

## 13. 最终定标模型

在 Calibration Fit 选择统一的 Peak position 和 Polynomial degree，然后点击 FIT CALIBRATION MODEL。

V0.9.3 的研究结果建议三阶多项式作为当前默认模型阶次，但软件仍允许比较其他阶次。最终模型会保存：

- 归一化多项式系数和自然像素系数；
- 拟合残差；
- LOO 残差；
- 删除影响；
- 像素坐标模式和适用范围；
- 峰位定义、样本 ID 和参考波长。

每次最终拟合都会作为模型快照加入 Model Comparison，便于比较不同样本集、峰位定义或阶次。

## 14. 残差与验证指标

### 14.1 Fit residual

模型在参与拟合样本上的闭合残差。Fit RMSE 通常随模型复杂度增加而下降，不能单独证明泛化能力。

### 14.2 LOO residual

每次去掉一个样本，用剩余点拟合，再预测被删除点。LOO RMSE 和 LOO MAX 用于检查样本外推敏感性。

### 14.3 All-point residual

用某个子集拟合模型，但在固定完整标杆池上计算残差。它是比较不同子集的统一尺度。

### 14.4 P95 与 MAX

- P95：完整池绝对残差的 95% 分位；
- MAX：最大绝对残差。

RMSE 描述总体能量，P95 和 MAX 用于发现高位和最差局部误差。

### 14.5 残差直方图

Selected Residuals 显示当前选中模型、Add-One 轮次、模型阶次或集合替换轮次的残差点图与直方图。直方图用于检查偏置、重尾和异常点；残差随波长的趋势图用于检查尚未被模型解释的结构。

### 14.6 峰位定义交叉验证

在 Model Validation > Peak-position cross validation 中，软件把“用哪一种峰位建立定标模型”和“实际应用时输入哪一种峰位”分开验证。

1. 设置 Degree；
2. Validation 选择 Full fit 或 LOO；
3. Pool 选择 All-method common peaks 或 Per-pair available peaks；
4. Training set 选择建模样本来源；
5. 点击 Run cross validation；
6. 用 Matrix metric 切换 RMSE、Bias、STD、P95、MAX 或 Slope；
7. 点击热图或矩阵表格单元格，查看该“定标峰位 → 应用峰位”组合的残差点图和直方图。

交叉验证页内部提供四个显示子页：

- Detail：保留单指标热图、数值表、可切换残差图和所选单元格直方图；
- All metrics：按 2 行 × 3 列同时显示 RMSE、STD、Bias、P95、MAX、Slope 六张热图；
- Calibration-row residuals：把当前选中的 calibration 行分别应用到四种峰位，按 2 × 2 显示四张残差散点图；
- All histograms：按 4 × 4 显示全部 calibration → application 组合的残差直方图。阵列的行列方向与热图一致，上方为 Centroid 定标行、下方为 Direct 定标行。

All histograms 使用同一组 Bins 和横轴范围，便于直接比较分布宽度、偏置和尾部。点击 All metrics 中任意热图单元格会同步更新当前选中的矩阵行列及 Calibration-row residuals。选择任一总览子页后点击 OPEN FIG，会保持原来的 2×3、2×2 或 4×4 阵列，整体打开为一个可编辑图窗。

Training set 有四种来源：

- All matched pairs：全部有效匹配点；
- Current final model：当前最终定标模型的 Peak ID 集合；
- Selected comparison model：Model Comparison 中当前选中模型的 PairIDs；
- Selected Set Design candidate：Set Design 表格中当前选中候选的成员集合。

若要执行“6 点定标、41 点验证”，先在 Set Design 中选中 K=6 候选（或先生成一个 6 点最终模型），然后回到本页选择相应 Training set，Validation 选 Full fit，再运行。结果标签和 CSV 分别报告 Train N 与 Eval N。Degree=5 的 Full fit 最少需要 6 个训练点，但这只是数学可拟合条件，并不代表模型具有冗余或稳定性。

矩阵的行表示 calibration peak position，列表示 application peak position。对角线表示定标与应用采用同一种峰位；非对角线表示峰位定义失配。

Residuals 的三个选项分别是：

- Selected cell：只显示当前一个“定标峰位 -> 应用峰位”单元格；
- Selected calibration row：固定当前矩阵行的定标峰位，同时显示它应用到四种峰位后的残差曲线；
- Diagonal comparison：比较 Direct->Direct、Interpolated->Interpolated、FWHM center->FWHM center 和 Centroid->Centroid 四条对角线结果。

All-method common peaks 只使用四种峰位都有效的公共样本，因此各单元格可直接公平比较；Per-pair available peaks 对每一对峰位使用该对可用的全部样本，数据利用率较高，但不同单元格的 N 可能不同。正式比较优先使用公共池，再用成对池检查结论是否稳健。

Pool 只决定缺失峰位时各矩阵单元格采用哪些有效样本，不是子样本数量选择器；子样本由 Training set 决定。Full fit 用选定训练集拟合，并在全部匹配评价池上计算残差。LOO 则只对训练集逐点留出，因此它回答训练子集内部泛化稳定性，不等同于“6 点拟合、41 点外部评价”。

计算开始后，Run cross validation 和相关参数控件会暂时禁用，并显示不可取消的进度窗口；计算成功、失败或中断后自动恢复。这用于避免连续点击造成重复计算。

## 15. 模型阶次选择

Calibration Optimization 的 Scan orders 1..k 比较完整样本集合在不同阶次下的 Fit RMSE、Fit MAX、LOO RMSE 和 LOO MAX。最大阶次可手动设置为 1～20，默认扫描到 10；实际扫描上限还必须满足 LOO 所需的 N >= degree+2。Fit RMSE 与 LOO RMSE 曲线默认使用对数纵轴，以便同时观察低阶的大误差和较高阶两条曲线的逐步分离。

判断原则：

1. 低阶模型若残差仍有明显趋势，说明模型结构不足；
2. 阶次增加后 Fit RMSE 下降但 LOO 或影响显著恶化，说明复杂度可能过高；
3. 优先选择残差结构基本消失、LOO 稳定且影响不过度集中的最低阶次；
4. 当前数据研究中三阶模型具有较好的性能、稳定性与解释性平衡；在完整样本充分约束时，四阶和五阶也可能是合理候选；
5. 该结论是基于当前样本池的量化推荐，不是对所有仪器和样本库都唯一成立的必然阶次。

算法口径见《WCC4SM V0.9.3 数据处理算法与统一指标说明 V1.0》。

## 16. Model Comparison

Model Comparison 用于保存和比较模型快照。

主要操作：

- Refresh overlays；
- Import model MAT；
- Export current model；
- Apply selected model；
- Apply current final model；
- Hide/show 或删除选中模型；
- Reset plot scale。

残差显示可在 Fit residual、LOO residual 和 All matched points 等模式间切换。点击模型表中的一行后，该模型会以点和连线强化显示，原强化模型恢复普通样式。

应用模型前应确认像素坐标模式和适用范围一致。应用后，主光谱可在 Pixel 与 Wavelength 轴之间切换。

## 17. Calibrated Performance

应用或拟合模型后，可查看：

- FWHM 和 ERW 随波长变化；
- 波长域峰宽关系；
- FWHM 分布直方图；
- 单像素波长间隔；
- 局部色散与采样比。

该页描述定标后的谱学性能，不等同于定标残差。峰宽和波长误差应分别评价。

### 17.1 峰位差的波长依赖与论文数据导出

Calibrated Performance 内含两个子页。`Peak-position wavelength dependence` 用于论文峰位差图和数据核查：

- 上图汇总当前已完成峰参数分析、且 FWHM center 有效的全部检测峰。横轴是由当前最终模型把 FWHM center 换算得到的波长，纵轴依次显示 `Direct peak - FWHM center`、`Interpolated peak - FWHM center` 和 `Centroid - FWHM center`，单位均为 pixel。由于未匹配峰没有参考波长，上图使用的是定标换算波长；状态栏会报告实际可绘制数量，不会用无效值补足 63 点。
- 下图和右表只使用波长匹配标杆集中 FWHM center 与 Centroid 均有效的公共样本，横轴为参考波长，纵轴为 `Centroid - FWHM center`。当前 41 点标杆数据完整时显示 41 点。
- `Centroid fit` 可选择 No fit 或 1～3 阶拟合。拟合实际调用带中心化和尺度归一化输出的 `polyfit`，图中同时显示归一化变量 `z`、拟合公式、RMSE、R² 和参与拟合的样本数。
- 在表格中取消 `Include` 可将疑似异常点排除出拟合；该点仍以红色叉号保留在图上。重新勾选或点击 `Restore all` 后重新拟合。
- 点击散点或表格行可同步强化相应峰；上图会把该峰的三种差值用竖线连接，便于识别。
- `Export CSV` 导出参考波长、两种峰位、原始差值、是否参与拟合、拟合值和拟合残差。拟合残差符号固定为“观测峰位差减拟合峰位差”。

该子页的上图用于查看全部已分析检测峰的总体行为，下图和表格才是固定匹配标杆集的论文主数据。手动排除只改变拟合样本，不删除原始峰或匹配关系。

## 18. Add-One

Add-One 从人工确认的初始集合开始，每轮加入一个候选点，并始终在固定完整标杆池上评价。

操作：

1. 在 Calibration Optimization 刷新可用样本；
2. 勾选初始集合；
3. 确认三阶模型和峰位定义；
4. 选择完整池或对称性推荐池；
5. 点击 Run Add-One；
6. 查看每轮 Ncal、加入点、All-point RMSE、P95 和 MAX；
7. 点击轮次查看残差点图和直方图。

好的初始集合通常在加入少量样本后就接近完整池性能；较弱初始集合可能在接近末端时才收敛。

## 19. 集合替换验证

Validate selected-set replacements 对当前任意选中集合进行逐点替换：

1. 每轮移除集合中的一个点；
2. 从未选池中遍历替代点；
3. 在固定验证池上选择该轮最佳替代；
4. 报告 Fit RMSE、Validation RMSE、Delta RMSE、P95 和 MAX。

RMSE th 是推荐替换所需的最小 RMSE 改善量。轻微下降只说明两个点的模型作用相近，不应自动推荐替换。

用户审查后才能点击 Add recommended model to comparison；计算过程不会自动修改模型列表。

## 20. 样本影响分析

Point Influence 分为 Sample influence 和 Set replacement 两个独立子页。

Sample influence：

- Analyze sample response：计算当前阶次的删除影响；
- Scan max：手动设置影响扫描最高阶次，范围 1～20，默认 10；
- Scan influence 1..k：统计各阶次 mean、RMS、P95 和 MAX influence，并计算完整模型及点删除模型的 Fit/LOO RMSE；
- Plot X axis：在样本序号、像素和参考波长间切换；
- Y axis：使用自动或固定纵轴比较不同阶次。

Influence 是删除某点前后 LOO RMSE 变化相对于完整模型 LOO RMSE 的比例。高影响表示模型对该点敏感，可能来自边界代表性、波长覆盖或独特局部信息，不等同于异常点或高质量点。

Sample influence 下方包含两个结果子页：

- Per-point influence：显示所选阶次下每个样本的删除影响；
- Across orders 内分为四个结果页：
  - Full Fit vs LOO：保留原有的 Full Fit RMSE 与 Full LOO RMSE 两条曲线，专门观察训练残差与留一残差随级次的分离趋势；
  - Generalization gap：显示 Full LOO RMSE - Full Fit RMSE，以及 Deleted-model LOO RMSE - Deleted-model Fit RMSE。间隙均为正时采用对数纵轴；若出现零或负值则自动采用保留符号的线性纵轴；
  - Deletion stability：显示 Full Fit RMSE、Full LOO RMSE、Deleted-model Fit RMSE 和 Deleted-model LOO RMSE，用于比较全样本模型与逐点删除模型池的稳定性；
  - Influence statistics：显示 mean/RMS/P95/MAX influence，用于观察影响强度分布随级次的变化。

其中 RMS influence 是无量纲影响比的 RMS，不是 Fit RMSE。Deleted-model Fit/LOO 是对同一阶次所有单点删除模型相应 RMSE 的 pooled RMS 汇总，Deleted gap 是这两个 pooled RMSE 的差。泛化间隙增大表示验证误差相对拟合误差进一步分离，可作为过拟合风险增强的证据，但不应脱离残差结构和样本影响统计单独决定阶次。为保证删除后仍能执行 LOO，实际影响扫描满足 N >= degree+3。

分析时应同时查看波长位置、峰形质量、局部聚集和边界角色。

## 21. Set Design

Set Design 从完整标杆池生成定标子集。

### 21.1 规则生成

可选择：

- Manual selection；
- Top-k influence；
- Maximin coverage；
- Locked boundary + coverage；
- Window influence；
- Window quality；
- Window center。

Target K 是子集样本数。Generate rule set 会直接生成 K 点集合。

### 21.2 分层 Beam

Initialize Beam 只建立基线。Calculate K-1 只计算一次删除层；Confirm checked 后才推进。

- B perf：每层保留的性能候选数；
- B div：额外保留的模型多样性候选数；
- eps RMS / eps MAX：模型曲线距离尺度和工程等价分组阈值。

右表每一行代表完整子集模型；Selected subset members 显示该集合实际包含的峰。

推荐先使用 5+5，再以 3+3 和 10+10 做宽度敏感性比较。详细操作见《WCC4SM V0.9.3 Set Design 操作与指标说明》。

### 21.3 Window Partition：只分窗，不选点

Set Design 内部的 Window Partition 是规则型子样本生成的第一阶段。它使用当前完整标杆池、三阶完整模型残差和既有 Deletion Influence，仅生成 K 个候选区域，不生成选样 Mask，不创建候选模型，也不修改当前定标模型。

操作步骤：

1. 在 Subset Search 或 Window Partition 前先执行 Refresh pool；
2. 设置 Target K，即窗口数；
3. 选择 Equal wavelength width 或 Equal cumulative influence；
4. 点击 Generate Windows；
5. 检查窗口表、上方完整模型残差图和下方 Influence 分布图；
6. 使用 Normalized weight / Raw influence 切换下图左轴，使用 Show cumulative curve 控制累计权重右轴；
7. 使用 Clear Windows 只清除分窗结果，不影响样本池、候选或模型。

Equal wavelength width 保留严格等宽边界，因此波长分布不均匀时允许出现 Empty window。Equal cumulative influence 在离散样本间隙中寻找严格递增的 cut index，使各窗口权重接近 1/K；权重大于 1/K 的样本仅标记为 Dominant influence sample，不自动变成 Anchor。

上下两图共享 Reference wavelength 横轴。灰色残差点始终是完整标杆池，第一阶段不会高亮任何“已选样本”。Export results 会额外输出 windows.csv 和 window_members.csv。分窗结果、cut index、逐样本归属和显示设置随 Session 保存。

## 22. Session 保存与恢复

SAVE SESSION 保存：

- 光谱、暗信号和预处理设置；
- 峰列表和确认数据；
- 参考主库及配对；
- 初始、最终、比较和应用模型；
- UI 设置；
- 峰位定义交叉验证的计算结果、峰位池口径和当前显示选择；
- Set Design 影响档案、候选、Beam 路径、Pending 层、成员掩码、Window Partition 边界与逐样本归属及参数；
- 操作者、仪器和参考数据溯源信息。

LOAD SESSION 在验证通过后整体替换当前状态；加载失败时保留原状态。旧版 Session 没有 SetDesign 字段时按空状态兼容加载。

## 23. 导出

主要输出包括：

- Peak Dataset MAT + CSV；
- 初始定标 MAT + CSV；
- 最终模型 MAT、残差 CSV 和方程 TXT；
- Add-One 历史 CSV；
- 峰位定义交叉验证矩阵和逐组合统计 CSV；
- Set Design MAT、完整池、候选、成员和 Beam 路径 CSV；
- 完整 Session MAT。

导出模型和 Session 作用不同：模型文件用于复用定标映射；Session 用于恢复完整分析上下文。

## 24. 新用户标准检查单

1. 输入 X 含义和像素模式是否正确；
2. 暗信号或手动基线是否与测量一致；
3. 自动峰和弱峰是否经过人工检查；
4. 参与定标的峰是否已确认；
5. 参考数据来源和波长介质是否明确；
6. 锚点和自动扩展配对是否逐点复核；
7. 峰位定义在各模型间是否一致；
8. 残差是否还有随波长的趋势；
9. LOO、P95、MAX 和影响是否可接受；
10. 边界点、峰形质量和局部聚集是否合理；
11. 最终模型是否在独立或重复数据上复核；
12. Session、模型和导出表是否一并保存。

## 25. 常见问题

### 25.1 无法切换波长轴

必须先应用有效模型，并且模型输出在整个输入像素范围内有限且单调。

### 25.2 模型被像素模式检查拒绝

确认模型与当前数据都是 Full detector sequence 或都是 Valid-pixel sequence。不要仅修改标签绕过坐标差异。

### 25.3 Set Design 右表看不到具体峰

点击候选行后查看左侧 Selected subset members。Full pool 的 Use 也会同步到候选成员掩码。

### 25.4 Calculate K-1 为什么不自动继续

这是分层确认设计。计算本层不会改变父集合，只有 Confirm checked 后才能进入下一层。

### 25.5 Fit RMSE 很小但 All-point RMSE 较大

Fit RMSE 只评价选中点闭合程度；All-point RMSE 评价同一模型在完整标杆池上的表现。比较子集时应优先看后者。

### 25.6 Influence 高是否应该删除

不能。高 Influence 表示模型依赖该点。边界代表点通常影响较高，应先检查峰质量和物理覆盖。

## 26. 文档关系

- 本文：完整用户操作流程；
- WCC4SM_V0.9.3_Set_Design操作与指标说明：Set Design 专项；
- WCC4SM_V0.9.3_数据处理算法与统一指标说明：算法和公式；
- WCC4SM_V0.9.3_软件架构与核心模块说明：开发维护；
- WCC4SM_V0.9.3_测试验证与验收说明：发布前验证；
- 输入输出、Session、像素坐标和模型格式规范：数据接口专项。
