# WCC4SM V0.9.3 数据处理算法与统一指标说明 V1.0

## 1. 文档目的

本文统一说明 WCC4SM V0.9.3 从光谱预处理、峰参数提取、波长定标和峰位定义交叉验证，到样本影响分析、子样本集生成与 Beam Search 的计算口径。

本文重点回答三个问题：

1. 每个指标究竟使用哪些样本、怎样计算；
2. 不同页面中名称相近的残差能否直接比较；
3. 高级优化功能给出的结果应怎样解释，而不应怎样解释。

界面操作请参见《WCC4SM V0.9.3 用户操作与完整工作流程说明 V1.0》。

## 2. 坐标、数据对象与符号

### 2.1 坐标定义

- 输入 X：数据文件第一列的坐标。
- 自然像素坐标 p：按用户选择的像素序列模式换算后的探测器位置。
- 参考波长 lambda：参考谱线或人工匹配给出的已知波长，单位 nm。
- 拟合波长 lambda_hat：定标模型根据像素位置计算的波长。
- 波长残差 e：参考波长减拟合波长，即 e = lambda - lambda_hat，单位 nm。

像素模式必须在一个项目内保持一致。改变“完整探测器序列/裁剪序列”等解释方式，会改变模型自变量，已有模型不能直接沿用。

### 2.2 样本集合

- 检测峰集合：自动寻峰和子窗口补峰产生的全部峰。
- 匹配集合：已经与参考波长建立对应关系的峰。
- 拟合集合：某次多项式拟合实际使用的样本。
- 验证池：用于统一计算候选模型残差的固定样本集合。
- 全池或标杆池：当前分析阶段定义的全部有效匹配样本，通常作为固定验证池。
- 子样本集：从全池中选出、实际用于拟合某个候选模型的样本。

“拟合集合”和“验证池”必须明确区分。两个模型只有在相同验证池、相同峰位置定义、相同像素模式下计算的指标才适合直接比较。

## 3. 光谱预处理

### 3.1 暗信号与人工基线

若加载了暗光谱，软件先将暗信号映射到测量光谱坐标，再执行逐点扣除。若未加载暗光谱，则可使用人工常数基线。

预处理信号可概括为：

    y_corrected = y_raw - y_dark_or_baseline

勾选“负值置零”后：

    y_nonnegative = max(y_corrected, 0)

负值置零会影响峰面积、质心和弱峰形状。进行精细峰形分析时，应确认暗信号或基线设置合理，不能仅依赖置零掩盖过度扣除。

### 3.2 显示归一化

归一化主要用于显示和相对峰检测。它不改变像素位置，但可能影响以幅值阈值定义的检测结果。线性或对数 Y 轴只是显示方式，不改变底层数据。

## 4. 峰检测与峰参数

### 4.1 自动寻峰与子窗口补峰

自动寻峰适合批量提取显著峰；子窗口搜索用于处理全谱搜索遗漏的极弱峰、边缘峰或局部复杂峰。补峰后仍需人工检查峰形、窗口和背景。

### 4.2 峰位置定义

- Direct：离散采样中的直接峰顶位置。
- Interpolated：局部插值后得到的峰顶位置。
- FWHM center：半高宽左右交点的中点。
- Centroid：选定峰窗口内按信号强度加权的质心。

定标模型必须记录所用峰位置定义。不同定义产生的像素位置存在系统差异，不应混入同一模型而不加说明。

### 4.3 峰宽、等效宽度与采样比

- FWHM：半高全宽。
- ERW：等效矩形宽度，反映峰面积与峰高的综合关系。
- ERW - FWHM、ERW/FWHM：用于辅助判断峰翼和峰形差异。
- Sampling ratio：特征宽度相对于采样间隔的比值，用于判断峰是否得到足够采样。

这些指标用于峰质量判断，不直接等价于定标残差。

### 4.4 对称性推荐

软件以质心位置与 FWHM 中心位置之差的绝对值作为对称性指标：

    symmetry_delta = abs(CentroidX - CenterX)

当 symmetry_delta 小于用户阈值时，可标记为推荐；超过阈值时进入复核。默认阈值可设为 0.2 像素。

该标识表示峰形对称性较好，不表示该点一定具有高建模价值。它应与匹配可信度、波长覆盖、样本影响和边界代表性共同使用。

### 4.5 峰位差与峰位映射

设 FWHM center 为中心峰位 x_c，其他峰位定义为 x_j。峰位差为：

    delta_j = x_j - x_c

delta_j 随像素或波长的变化用于描述峰形与像差导致的系统性定位偏移。它不是参考波长残差。软件还拟合峰位定义之间的直接映射：

    x_j = g_j(x_c) + epsilon_j

其中 g_j 可选择 1～3 阶多项式，epsilon_j 的直方图用于检查映射后仍未解释的偏移结构。Centroid 是能量质心；FWHM center 是半高交点中心。用 Centroid 定标可能吸收一部分能量分布偏移，而中心定位更接近常用的谱峰间隔判别，两者应根据应用目的选择。

## 5. 波长定标模型

### 5.1 多项式模型

软件使用像素到波长的多项式映射。为改善数值条件，MATLAB 拟合可采用归一化自变量：

    z = (p - mu1) / mu2
    lambda_hat = c0 + c1*z + ... + cm*z^m

模型导出时必须同时保存多项式系数、mu1、mu2、像素模式、峰位置定义和拟合阶次。

### 5.2 阶次与自由度

m 阶多项式至少需要 m+1 个互异像素点。刚好使用 m+1 个点时，闭合拟合残差可能非常小，但模型缺少冗余约束，不能据此判断泛化能力。

三阶模型被当前项目选为主要阶次，是基于残差结构、LOO、样本影响强度和模型复杂度的综合判断，而不是只看拟合 RMS 最小。

### 5.3 泛化间隙

对同一阶次的同一模型，定义带符号的泛化间隙：

    GeneralizationGap = LOORMSE - FitRMSE

单位为 nm。正值表示 LOO 验证误差高于拟合集合上的闭合误差；随阶次持续增大，表示训练误差与留一验证误差逐渐分离，可作为过拟合风险增强的证据。软件同时计算：

- Full-set gap：完整样本模型的 FullLOORMSE - FullFitRMSE；
- Point-deleted pool gap：同阶次逐点删除模型池的 pooled DeletionLOORMSE - pooled DeletionFitRMSE。

间隙均为正时曲线采用对数纵轴，以同时观察低阶大误差和 3 次以后的细微分离；出现零或负值时自动改用线性纵轴并保留符号。泛化间隙应结合残差结构、LOO 绝对水平及 influence 统计解释，不能单独作为阶次选择规则。

## 6. 残差指标的统一口径

### 6.1 拟合残差

拟合残差只在拟合集合上计算：

    e_i = lambda_i - lambda_hat_i
    FitRMSE = sqrt(mean(e_i^2))

同时使用：

- STD：残差标准差；
- P95：绝对残差的第 95 百分位；
- MAX：最大绝对残差。

FitRMSE 描述模型对参与拟合数据的闭合程度，通常偏乐观。

### 6.2 留一验证 LOO

对拟合集合中的每个样本 i：

1. 删除样本 i；
2. 用其余样本重新拟合；
3. 预测被删除样本；
4. 汇总所有留一预测残差。

LOORMSE 比 FitRMSE 更能反映单点依赖和模型稳定性。高阶模型在小样本下可能出现很小的 FitRMSE，却有很大的 LOORMSE 或 LOO MAX。

### 6.3 固定全池验证残差

候选子样本集拟合完成后，在固定验证池全部样本上重新计算预测残差：

    AllRMSE = sqrt(mean(e_pool^2))
    AllP95 = percentile(abs(e_pool), 95)
    AllMAX = max(abs(e_pool))

这是 Add-One、样本替换和 Set Design 的主要比较口径。所有候选模型使用同一验证池，才能避免“样本越少、只在自身样本上验证”造成的假性改善。

当拟合集合等于验证池，且峰位置、阶次和像素模式完全一致时，FitRMSE 与 AllRMSE 应一致或仅有数值舍入差异。这也是重要的一致性验收项。

### 6.4 指标选择原则

- 比较闭合拟合：看 FitRMSE。
- 比较点删除后的预测稳定性：看 LOO 指标。
- 比较不同子样本模型：优先看同一固定池上的 AllRMSE、AllP95、AllMAX。
- 判断残差是否仍有趋势：看残差随波长/像素的散点或增强连线。
- 判断误差分布和尾部：看直方图、P95、MAX。

单个指标不能代替完整诊断。低 RMSE 不保证无趋势，也不保证边界误差受控。

### 6.5 峰位定义交叉验证与失配矩阵

设 a 为建立定标模型所用峰位，b 为实际应用输入峰位，参考波长为 lambda_i。其残差定义为：

    r_(a->b,i) = lambda_i - f_a(x_(b,i))

矩阵行是 calibration peak position a，列是 application peak position b。对角线 a=b 表示峰位定义匹配；非对角线 a!=b 量化“用一种峰位定标、用另一种峰位应用”造成的实际失配误差。

Validation 有两种口径：

- Full fit：用选定训练池拟合一次，并在独立评价池的相应应用峰位上计算残差；因此支持 K 点建模、N 点评价；
- LOO：只在训练池内逐点删除参考样本，每次重新拟合 a 定义模型，再用 b 定义峰位预测被删点。

训练池由 Peak ID 显式选择，可来自全部匹配点、当前最终模型、Model Comparison 当前模型或 Set Design 当前候选。评价池固定为当前全部匹配点。Full fit 的最少训练点数为 degree+1；LOO 因留出一个点后仍需可拟合，最少为 degree+2。结果必须同时报告 NTrain 与 NEval。

Pool 有两种口径：

- All-method common peaks：四种峰位均有效的公共交集，所有矩阵单元格使用相同样本，适合横向比较；
- Per-pair available peaks：每个 a->b 组合使用该组合可用的全部样本，适合最大化数据利用率，但必须同时报告 N。

每个单元格计算 RMSE、Bias、STD、P95、MAX 和残差随参考波长的一次趋势斜率 Slope。Bias 反映整体偏移，Slope 反映残留波长趋势；它们不能由 RMSE 单独替代。对角线不保证误差为零，因为它仍包含定标模型误差和 LOO 泛化误差。

计算实现按矩阵行复用定标模型：Full fit 对每种 calibration peak position 只拟合一次；LOO 对每种 calibration peak position 的每个留出样本只拟合一次，再把同一模型分别应用到各列峰位。四种峰位时，完整可用数据的定标拟合次数由 Full fit 的 16 次降为 4 次，LOO 由约 4 x 4 x N 次降为约 4 x N 次。该优化只消除重复拟合，不改变样本池、残差方向或矩阵统计口径。

## 7. 模型阶次与残差结构

阶次扫描应同时观察：

- FitRMSE 是否继续显著下降；
- LOORMSE 和 LOO MAX 是否恶化；
- 残差图是否仍存在单调、弯曲或分段聚集结构；
- 直方图是否明显偏斜、重尾或多峰；
- 样本影响均值、RMS、P95、MAX 是否随阶次异常放大。

完整集合阶次扫描的 FitRMSE 与 LOORMSE 使用对数纵轴显示。软件阶次输入统一允许 1～20，但成对 Fit/LOO 扫描的实际最高阶次为 min(用户上限, N-2)。20 是界面研究范围，不代表高阶模型自动可靠。

残差直方图用于查看分布形态，但不能独立识别残差随波长的趋势。直方图与残差位置图需要配合解释。

## 8. 样本影响分析

### 8.1 删除影响

对每个匹配样本删除一次并重新拟合。软件计算：

- Residual：完整模型中该点的残差；
- Deleted Fit RMSE：删除该点后模型在其拟合集合上的闭合 RMSE；
- Deleted LOO RMSE：删除该点后模型内部再次执行 LOO 得到的 RMSE；
- Curve change：完整模型与删除模型在公共像素网格上的最大曲线差；
- Influence：LOO RMS 的相对变化强度。

当前影响定义为：

    Influence_i = abs(LOORMSE_full - LOORMSE_without_i) / max(LOORMSE_full, machine_epsilon)

Curve change 定义为公共像素网格上两个模型预测波长差的最大绝对值。

### 8.2 分类提示

当前实现可使用以下经验阈值：

- Influence >= 2：高影响；
- Influence <= 0.25：冗余倾向；
- 大残差：结合基线阈值及 abs residual 的中位数与标准差识别候选异常点。

分类是筛查提示，不是自动删除命令。边界点、稀疏波段代表点天然可能是强影响点，删除它们反而可能破坏覆盖。

### 8.3 多阶统计

对 m=1...k 可汇总 Influence 的 mean、RMS、P95、MAX。在对数纵轴下比较，可观察模型复杂度增加是否导致对少数点的依赖增强。RMS influence 是无量纲 InfluenceRatio 向量的 RMS，不是波长拟合 RMSE。

对每一阶 m，软件还汇总所有单点删除模型的误差：

    DeletionFitRMSE(m) = sqrt(mean_j(FitRMSE(m,-j)^2))
    DeletionLOORMSE(m) = sqrt(mean_j(LOORMSE(m,-j)^2))

这两个量的单位均为 nm，可与同阶完整模型的 FullFitRMSE 和 FullLOORMSE 配对查看。它们描述“删除任一点后模型总体处于什么误差水平”，不对应某个单独样本。

因为每个点删除模型还要再次进行 LOO，多阶影响扫描必须满足 N >= m+3。因此实际最高阶次为 min(用户上限, N-3)，界面用户上限统一为 20。

## 9. Add-One 与逐一替换

### 9.1 Add-One

从人工确认的初始集合出发，每轮把一个候选样本加入拟合集合。每个候选都在固定全池上计算 AllRMSE、AllP95 和 AllMAX，再选择本轮最合适的点。

好的初始集合通常能用较少新增样本快速接近全池模型性能。曲线接近末端才下降，表示初始集合覆盖或位置代表性不足。

### 9.2 任意集合逐一替换

逐一替换不再局限于“5 点种子”。对当前集合中的每个点，遍历池外候选，比较替换前后固定验证池指标。

    DeltaRMSE = RMSE_candidate - RMSE_baseline

DeltaRMSE < 0 表示候选较好，但只有改善超过用户设定阈值才应推荐替换。小幅下降更适合解释为两个样本作用接近，而不是明确优劣。

## 10. 子样本集评价

### 10.1 Window Partition

Window Partition 是选点前的空间划分，不产生 calibration subset。输入样本按参考波长排序，复用三阶模型的完整集合残差与 Deletion Influence。

等波长宽度模式使用：

    DeltaLambda = (lambda_max - lambda_min) / K
    W_j = [b_(j-1), b_j), j < K
    W_K = [b_(K-1), lambda_max]

边界左闭右开，最后一窗右端闭合。理论边界不因空窗而移动。

等累计 Influence 模式使用：

    w_i = I_i / sum(I)
    F_i = sum_(r=1)^i w_r
    q_j = j / K

在满足 1 <= c_1 < ... < c_(K-1) < N 且每窗至少一个样本的条件下，确定性选择 cut index，使：

    sum_j abs(F_(c_j) - q_j)

最小。累计误差在数值容差内相同时，优先选择相邻参考波长间距总和更大的切法，减少切开天然密集谱线簇的倾向。显示边界为相邻样本波长中点，但真实归属始终由 cut index 决定。

若单样本 w_i > 1/K，仅记录 Dominant influence sample，不自动设置 Anchor。若 sum(I) 接近零，则等累计 Influence 分窗返回受控错误。分窗结果记录窗口权重、目标偏差、最大影响样本、空窗、重复波长切分提示及逐样本窗口归属。

### 10.2 子集评价记录

每个子样本集至少记录：

- K：拟合样本数；
- FitRMSE；
- AllRMSE、AllP95、AllMAX；
- 覆盖比例；
- 最大波长间隔；
- 短波端和长波端边界是否被覆盖；
- 样本成员、来源、生成规则与状态。

覆盖比例高并不保证局部间隔合理，因此需同时检查最大波长间隔和边界锁定。

## 11. 模型距离与 epsilon 覆盖

两个候选模型在公共像素网格上比较：

    delta_j = lambda_hat_A(p_j) - lambda_hat_B(p_j)
    D_RMS = sqrt(mean(delta_j^2))
    D_MAX = max(abs(delta_j))

若同时满足：

    D_RMS <= eps_RMS
    D_MAX <= eps_MAX

则认为两个模型在给定容差下属于同一覆盖邻域。epsilon cover 用少量代表模型描述候选空间，避免只因样本组合不同而保留大量几乎相同的模型。

eps_RMS 控制整体曲线差异，eps_MAX 控制局部最坏差异。两者必须同时使用。

## 12. 规则子集生成

Set Design 提供确定性规则生成，而不是依赖大规模蒙特卡洛：

- Top-k influence：优先选影响强的样本；
- Maximum coverage：强调波长范围与间隔覆盖；
- Locked boundary + coverage：锁定边界代表点后补充覆盖；
- Window influence：按波长窗口兼顾局部代表性与影响；
- Window center：优先选择各窗口中心附近的代表点；
- Manual：由用户勾选生成经验子集。

规则集用于产生有解释性的起点。它不是“自动最优答案”，仍需在统一验证池上评价。

## 13. 分阶段 Backward Beam Search

### 13.1 基本过程

Backward Beam 从当前 K 个样本的已接受集合出发，只提出删除一个样本得到的 K-1 候选：

1. Initialize Beam：建立当前层基线；
2. Calculate K-1：生成并评价所有单点删除候选；
3. 用户查看表格、成员和残差图；
4. Confirm checked：确认保留的候选，进入下一层；
5. 重复上述过程，直到目标 K。

计算不会自动一路删到目标 K。每层都保留人工确认点，便于在性能、覆盖和解释性之间做判断。

### 13.2 B perf 与 B div

- B perf：按 AllRMSE、AllP95、AllMAX 的顺序保留性能最好的候选数量。
- B div：在性能候选之外，按模型曲线差异保留具有代表性的多样候选数量。

多样候选采用最大最小策略。候选相对已选模型的差异可归一化为：

    novelty = max(D_RMS/eps_RMS, D_MAX/eps_MAX)

B perf 防止丢失数值性能最好的路径；B div 防止所有路径过早聚集到几乎相同的模型区域。

### 13.3 快速评价与最终确认

Beam 层内候选为了提高速度，可跳过每个候选的完整 LOO，但固定全池验证始终计算。候选真正加入模型比较时，应重新完整拟合并计算 LOO 指标。

## 14. 结果解释的边界

- 强影响不等于坏点，可能代表边界或稀疏波段。
- 低影响不等于可随意删除，多个相邻点可能共同承担约束。
- 对称性推荐不等于定标价值高。
- FitRMSE 最低不等于泛化最好。
- 高阶模型残差更低不等于模型更可信。
- Beam 保留状态表示搜索路径被接受，不等于最终物理模型已经确认。

最终选择应同时满足残差、稳定性、覆盖、峰质量和物理可解释性要求。

## 15. 算法与源文件对应

| 功能 | 主要源文件 |
|---|---|
| 光谱预处理 | src/wc4sm_preprocess_spectrum.m |
| 峰参数分析 | src/wc4sm_analyze_peak.m |
| 多项式定标 | src/wc4sm_fit_calibration.m |
| LOO 验证 | src/wc4sm_validate_calibration_loo.m |
| 定标性能 | src/wc4sm_calculate_calibrated_performance.m |
| 峰位定义交叉验证 | src/wc4sm_cross_validate_peak_positions.m |
| 阶次分析 | src/wc4sm_analyze_model_order.m |
| 多阶影响统计 | src/wc4sm_analyze_influence_orders.m |
| 单点影响 | src/wc4sm_analyze_point_influence.m |
| Add-One | src/wc4sm_analyze_add_one.m、src/wc4sm_analyze_add_one_path.m |
| 逐一替换 | src/wc4sm_analyze_seed_replacements.m |
| 子集评价 | src/wc4sm_evaluate_subset.m、src/wc4sm_batch_evaluate_subsets.m |
| 模型距离与覆盖 | src/wc4sm_model_distance.m、src/wc4sm_build_epsilon_cover.m |
| 规则子集 | src/wc4sm_generate_subset_mask.m |
| 分阶段 Beam | src/wc4sm_initialize_backward_beam.m、src/wc4sm_backward_beam_step.m、src/wc4sm_accept_beam_layer.m |

## 16. 推荐的统一报告字段

每次正式分析建议至少记录：数据文件、像素模式、峰位置定义、拟合阶次、拟合集合 ID、验证池 ID、FitRMSE、LOORMSE、LOO MAX、AllRMSE、AllP95、AllMAX、覆盖比例、最大间隔、边界状态、模型系数和归一化参数。

若执行峰位定义交叉验证，还应记录 Validation、Pool、calibration peak position、application peak position、N、NTrain、RMSE、Bias、STD、P95、MAX 和 Slope。非对角单元格的结果必须连同方向 a->b 一起报告，不能只写一个 RMSE 数值。

只有报告字段完整，模型比较、Session 复现和跨计算机移交才具有可追溯性。
