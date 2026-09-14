# WCC4SM论文 MATLAB出图任务单 v01

日期：2026-09-06。用途：作者操作MATLAB生成图件，助手核对科学内容与图文衔接。此文档不是已完成图件，也不代表期刊最终格式要求。

## 0. 执行顺序与版本约定

推荐顺序：Fig.3 → Fig.6 → Fig.4 → Fig.5 → Fig.7/8 → Fig.1/2。第一批只做Fig.3、Fig.6预览，先确认内容，不必一次完成全部图。

本单采用最近讨论中的图号，替代早期《第一步图组取舍》的编号。早期“峰位差/阶次/影响/矩阵/残差”的Fig.2/3/4/5/6，分别对应本单Fig.3/4/5/6(a)/6(b–c)。最终编号可调整；原素材文件名不改。Fig.1–2可以合并，Fig.8可以并入Fig.7，不为凑8组增加图片。

- 项目：C:/Ddisk/spectralsoftpj/WCC4spectrometer/WCC4SM_V0_9_3_package20260903a
- 现有图素材：项目内paper2wavelengthcalibration/fig，以下文件前缀是定位线索，不是其数据已核定的保证。
- 当前分析基线Session：result/WCC4SM_sessionpeakfind63fit41seed5heat.mat。
- 第1–3章、第5–6章使用双语v02；第4章仍为双语v01，待图件确定后统一衔接。
- 不重新调整峰窗、基线、插值或筛选41点。作者确认过的分析参数保持固定。
- 若Session、模型或导出值与下列核对点不符，保留当前文件，记录差异并先反馈，不通过修改图上数字来“对齐”。

## 1. 所有图共同遵守的规则

### 数据与统计

1. 主分析固定为同一41条谱线，参考波长约265.3679–1067.3565 nm；只有数据构建概览可显示全部63个检出峰。
2. 四种定义固定顺序：Direct、Interpolated、FWHM center、Centroid。四种定义改变坐标，不改变物理谱线成员。
3. 残差符号统一：Reference − Prediction，单位nm；位置差单位pixel。
4. 跨定义矩阵：行=Calibration definition，列=Application definition。不能反置。
5. 跨定义图用完整训练集合拟合后的模型，评价集合为共同41点，不用各模型自己的训练残差替代。它包含训练点，不标为Independent validation。
6. 阶次图的LOO是同定义留一重拟合结果，不与上述共同集合RMSE混用。
7. 不要求本轮重新做峰窗/插值参数敏感性或选样优化。5/9点结果尚未完整核定，不预填优劣结论。

### 版式与导出（内部出图建议，非已核实期刊规定）

- 图内用英文；整图不放长标题，用(a)、(b)…标记子图，解释放图注。
- 方法配色全篇固定，可用蓝Direct、橙Interpolated、绿FWHM center、紫Centroid，并结合不同符号，避免只依赖颜色。
- 比较同一量时统一坐标范围或色限；不同量不强行共用色条。不截断极端点；局部放大必须保留全范围主图。
- 细网格或无网格，保留零基线；不保留软件界面按钮、工具栏、选择红框和冗长自动图例。
- 先交PNG预览（约1600–2400像素宽即可），内容通过后保留可编辑FIG，另导出矢量PDF。若期刊后续要求TIFF再转换，不提前花时间。
- 建议文件名：F03_peak_definitions_preview.png、F03_peak_definitions.fig、F03_peak_definitions.pdf。其他图依此命名。
- 每组同时交一个小型MAT或CSV数据文件及简短说明：Session名、谱线ID、模型阶次、训练/评价集合、残差符号。无需导出整个工作区。
- 某些MATLAB版本的导出功能不同，可用自己熟悉的导出方式；本单不要求升级MATLAB或安装新工具。

## 2. Fig.3：峰位定义及波长相关分离【第一优先】

**对应正文：3.1–3.3、4.1；目标：同一响应上不同代表位置，以及这种差异随波长的结构。**

### 建议2×2布局

(a) 一个相对对称且无明显邻峰干扰的有效峰。
(b) 一个存在可辨拖尾/非对称性的有效峰。
(c) 41点三种位置相对FWHM中心的偏移。
(d) 41点Centroid − FWHM center的单独分布，突出方向与波长结构。

### MATLAB操作内容

(a)(b)优先从最终41点选峰，记录ID和参考波长；不必等待63→41人工排除案例。若尚未选定，先做(c)(d)，不要虚构峰形示例。

- 原始扣基线采样画实心点；实际三次样条加密结果画细实线。
- 标出Direct、Interpolated、FWHM center、Centroid的竖线/符号；重合时用上方短标记或局部放大，不人为移开位置。
- 标出半高水平及左右交点；半高中心为交点中点。
- 横轴可用“Position relative to FWHM center (pixel)”以利比较，必须对所有坐标减去同一个该峰FWHM中心。
- 纵轴“Baseline-corrected signal (normalized)”；按各峰净信号最大值归一化。允许显示原始净信号的负值；说明质心计算只使用非负部分，不要将绘图平滑曲线悄悄替换成另一种插值。
- 显示完整已确认峰窗；必要的放大不能隐藏窗口及尾部。
- 不画“质心两侧等面积”的阴影。若用阴影，只表示积分窗口内非负信号，不能暗示等面积性质。

(c)横轴“Reference wavelength (nm)”，纵轴“Position difference relative to FWHM center (pixel)”：
Direct − FWHM center、Interpolated − FWHM center、Centroid − FWHM center。
用散点，零线；可加细连接线作为视觉引导，但不加未经分析的拟合趋势。

(d)同一41点的Centroid − FWHM center，保持符号。它不是新增数据，也不是统计显著性检验；若(c)已经清楚，可删除(d)，改成三面板图。

### 核对点

- 不直接使用现有63峰的fig04-peakposition-differences/fig04-ppd-hist冒充41点。
- 41点Direct − FWHM中心范围约−0.542007至0.483011 pixel。
- Interpolated − FWHM中心约−0.187148至0.186524 pixel。
- Centroid − FWHM中心约−0.196941至0.299384 pixel。
- 不强求所有短波同号或全谱单调；保留例外点。

### 图注草稿

中文：四种峰位定义及其波长相关分离。(a,b) 已确认谱线的局部响应、原始采样、样条插值及四种位置标记；半高中心由半高交点确定，质心由指定窗口内非负净信号的一阶矩确定。(c,d) 固定41条参考谱线的位置差，符号为所示定义减去FWHM中心。曲线或连线仅用于引导观察。案例ID与波长待实际选定后填入。

English: Four peak-position definitions and their wavelength-dependent separation. (a,b) Local responses of confirmed lines, original samples, spline interpolation, and the four position markers. The FWHM center is the midpoint of the half-maximum crossings; the centroid is the first-moment center of the nonnegative net signal within the specified window. (c,d) Position differences for the fixed 41-line set, expressed as the indicated definition minus the FWHM center. Connecting lines, where present, guide the eye. Insert the actual example IDs and wavelengths before finalization.

## 3. Fig.6：41点跨定义误差与残差结构【第一优先】

**对应正文：4.3、5.1.1–5.2；目标：定标定义与应用定义不能未经评价就互换。**

### 推荐三个面板

(a) 4×4 RMSE热图。
(b) 应用定义固定FWHM center：比较FWHM→FWHM与Centroid→FWHM。
(c) 应用定义固定Centroid：比较Centroid→Centroid与FWHM→Centroid。

先不将六种统计量全部塞入主图。完整16组合及其他指标留数据文件或补充图。

### MATLAB操作内容

- 全部固定41点训练、三次模型、共同41点评价。
- (a)行列顺序均为Direct、Interpolated、FWHM center、Centroid，格内标RMSE，建议4位小数，单位nm；色条“RMSE (nm)”，非负顺序色图，自0起。
- (b)(c)横轴Reference wavelength (nm)，纵轴Residual (nm)；共同横纵范围，零线，按参考波长排序后画点/细线。
- 曲线颜色按“定标定义”固定。图例用“FWHM → FWHM”等清晰标签，箭头永远为定标→应用。
- 这两个应用面板是预先指定的一对双向交换，目的是说明定义间结构，不宣称穷尽所有组合；(a)保留全部组合。
- 如空间允许可加Bias热图为(d)，使用以0为中心的对称发散色限；否则保留在数值附件。
- 原素材线索：fig14-6heatof41pfitd3及fig14中rawresidual文件。旧图如不匹配下表，应核查模型/Session，不原样使用。

### RMSE核对矩阵（nm）

| Calibration \ Application | Direct | Interpolated | FWHM center | Centroid |
|---|---:|---:|---:|---:|
| Direct | 0.119791 | 0.047366 | 0.054920 | 0.102855 |
| Interpolated | 0.122093 | 0.041070 | 0.041094 | 0.091771 |
| FWHM center | 0.129321 | 0.052273 | 0.025356 | 0.066725 |
| Centroid | 0.153406 | 0.093331 | 0.060817 | 0.037357 |

此表来自当前固定41点输入的独立计算，是核对点，不是要求人工覆盖MATLAB结果。保留导出精度，不只交四舍五入图中文字。

### 图注草稿

中文：固定三次模型在共同41条参考谱线上的跨定义评价。(a) 行为定标定义，列为应用定义的RMSE矩阵。(b,c) 分别以FWHM中心和质心作为应用坐标，展示同定义基线及双向交换的残差。残差为参考波长减预测波长。所有模型使用41条谱线拟合，该评价并非独立测试集验证。

English: Cross-definition assessment of cubic models on the common 41-line reference set. (a) RMSE matrix with calibration definitions in rows and application definitions in columns. (b,c) Within-definition baselines and reciprocal cross-application residuals for FWHM-center and Centroid readouts, respectively. Residuals are reference minus predicted wavelength. All models were fitted using the 41 lines; this assessment is not independent test-set validation.

## 4. Fig.4：四种定义的阶次选择【第二批】

**对应正文：4.2、5.1。素材：fig08-scanorder41sample-*。**

- 2×2面板，顺序Direct、Interpolated、FWHM center、Centroid。
- 每个面板两条曲线：Fit RMSE实线、LOO RMSE虚线，配不同点型；横轴Polynomial order，显示1–10整数。
- 纵轴RMSE (nm)，建议四面板共用对数纵轴，完整保留1次的大误差和高阶的小差异；若3–6次区分不清，加统一规则的局部线性放大，不截掉全扫描结果。
- 用符号标注该面板最低LOO的位置；不是最低Fit。不得统一标三次为最优。
- 相同41点、同定义LOO、不重新筛线。

核对：四定义在1–10次内LOO最小值依次位于3、6、4、5次。三次LOO依次约0.130976、0.046533、0.030248、0.044163 nm；FWHM四次约0.021736 nm，Centroid五次约0.036492 nm。若曲线不符，先检查数据源。

图注中文：固定41条参考谱线的拟合与同定义LOO RMSE随多项式阶次的变化。各面板使用同一谱线集合和固定位置计算条件；标记表示扫描范围内的最低LOO RMSE。

Caption: Fit and within-definition LOO RMSE versus polynomial order for the fixed 41-line set. All panels use the same physical lines and fixed position-processing conditions. Markers identify the lowest LOO RMSE within the scanned range.

## 5. Fig.5：样本删除敏感性【第二批】

**对应正文：4.2、5.1。素材：fig09；先核对指标，不直接依赖“Deletion influence”标题。**

为突出与阶次结果的联系，建议先做聚焦FWHM中心的2×2图；其他定义全量放补充材料，不把它说成四定义普遍结论。

- (a) 四定义平均相对删除影响I随阶次1–10变化。
- (b) 四定义最大相对删除影响I随阶次1–10变化。
- (c) FWHM中心三次与四次的逐点I，横轴参考波长。
- (d) 同样两模型的逐点Q，横轴参考波长。

定义（先确认程序输出对应这些量）：

I_n = |LOO_full − LOO_deleted,n| / LOO_full，无量纲；删除后模型及其LOO均重新计算，样本池由41变为40。
Q_n = max over original 41 coordinates |prediction_full − prediction_deleted,n|，单位nm。不是在整个连续波段取最大。

I默认画原始比值，不画百分数；若选百分数，所有I乘100且轴标统一写%。Q不能标成影响百分比。逐点图不做累计归一化，不按影响大小重排横轴。

三次/四次FWHM最大I约0.123836/0.349657；最大Q约0.034756/0.023018 nm。两者方向不同是需要保留的结果，不通过换色限隐藏。若逐点Q未方便导出，先交(a)–(c)并注明缺项，不以残差或另一种影响指标代替。

图注中文：样本删除敏感性及其阶次依赖。(a,b) 四定义平均和最大相对LOO变化I。(c,d) FWHM中心三次与四次模型的逐点I和曲线变化Q。Q在原41点坐标上评价。高I表示删除敏感性，不自动代表谱线异常。

Caption: Sample-deletion sensitivity and its order dependence. (a,b) Mean and maximum relative LOO change I for the four definitions. (c,d) Per-line I and curve change Q for cubic and fourth-order FWHM-center models. Q is evaluated at the original 41 coordinates. A high I indicates deletion sensitivity, not automatic evidence of an invalid line.

## 6. Fig.7：少点模型的四定义比较【数据确认后】

**对应正文：4.4；素材：fig13、fig15、fig14的热图。**

- 先确认唯一一套5点ID和9点ID；不要求5点一定包含于9点，但必须记录实际关系。
- 四种定义各自使用同一套物理5点/9点。阶次全部固定三次。
- 2×3布局，列依次N=5、N=9、N=41；上排4×4 RMSE，下排4×4 Bias。
- 同一指标跨三列统一色限；Bias关于零对称。各格数字保留一致小数位。
- 所有矩阵共同41点评价，不能将5点模型只在5点上算RMSE。
- 41点列应与Fig.6一致。导出三套完整矩阵和样本ID，不预填5/9点数字。
- 五点三次完整拟合有1个残差自由度，LOO剩4点仅足以识别三次模型；不要在图注写“五点保证稳定”。

图注中文：三次模型在5、9和41条训练谱线条件下的跨定义评价。各列均在共同41条参考谱线上评价；上排为RMSE，下排为Bias。每种训练规模内，四定义采用相同物理谱线。同一指标使用统一色限。

Caption: Cross-definition assessment of cubic models trained on 5, 9, or 41 lines. All columns are evaluated on the common 41-line reference set. The upper and lower rows show RMSE and Bias, respectively. The four definitions share the same physical training lines at each sample count. Color limits are shared within each metric.

## 7. Fig.8：少点样本分布及残差【备选，可并图】

**对应正文：4.4；素材：fig10-9pointssel、fig11-5pointssel、fig12-fitcompare。**

- (a)三条水平带显示41/9/5点参考波长位置，稀疏点用明显标记；无需绘制分窗推荐界面。
- (b)固定FWHM中心、三次，比较5/9/41训练模型在共同41点上的残差，横轴参考波长、纵轴Reference − Prediction (nm)。
- 图例清楚标训练点数，不混入41点五次曲线。
- 与Fig.7必须使用完全相同的5/9点ID。
- 若第7图已有充分信息，可将(a)作为Fig.7小面板，把(b)转补充材料；不重复绘制三张等价曲线图。

图注中文：稀疏训练样本的波长分布及共同集合残差。(a)41、9、5点集合的位置。(b)固定FWHM中心和三次模型条件下，在共同41点上的残差。样本配置为本文案例，不代表最优选样。

Caption: Wavelength distribution of sparse training sets and common-set residuals. (a) Positions of the 41-, 9-, and 5-line sets. (b) Residuals on the common 41-line set for cubic FWHM-center models. The selected configurations are study cases, not globally optimized designs.

## 8. Fig.1–2：概览与人工案例【最后，避免阻塞】

Fig.1：测量与分析流程。可用简单框图：Hg–Ar采集 → HDR光谱 → 检出63峰 → 人工审查确认41峰 → 四位置算子 → 阶次/删除分析与跨定义评价。四种定义并列；5/9点作为固定41点中的训练子集分支。无可用真实光路图时不画臆测光路、不做新仿真。也可并入Fig.2。

图注中文：从光谱采集和谱线审查到四定义定标评价的分析流程。
Caption: Analysis workflow from spectral acquisition and line review to four-definition calibration assessment.

Fig.2：一幅HDR全谱区分检出63峰与最终41峰；另预留2–4个作者确认的人工筛选案例，展示邻峰、峰窗及参考线证据。63/41应能区分，避免标63个拥挤文字。拒绝案例允许来自未进入41点的峰，必须说明，不能混入主分析统计。作者案例确定前先不制作空白成品图。

图注中文：光谱数据与参考谱线集合的构建。全谱显示检出峰和保留谱线；局部案例展示人工审查依据。具体案例ID、处理窗口和保留/排除理由在作者确认后补齐。
Caption: Construction of the spectral dataset and reference-line set. The full spectrum distinguishes detected peaks from retained lines; local examples document manual review. Example IDs, windows, and retention or exclusion reasons will be completed after author confirmation.

## 9. 每批交回时的最小清单

- [ ] 图内数据是规定集合、阶次、定义及评价方式。
- [ ] PNG预览可读，无界面截图边框；不必先做最终字体微调。
- [ ] 可编辑FIG及相应数据已保存。
- [ ] 附Session名、示例峰ID或5/9点ID、与核对值是否一致。
- [ ] 所有偏差注明原因或标为待查，没有手工改数。
- [ ] 不能方便导出的面板直接说明，不扩展任务寻找替代指标。

助手收到第一批后：先检查Fig.3物理标记和Fig.6矩阵方向/残差符号，再检查图注与第4章衔接。不重新扫描全部FIG、不提前排整篇论文。摘要仍留最后。

