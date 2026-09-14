# WCC4SM V0.9.3 软件架构与核心模块说明 V1.0

## 1. 文档目的

本文面向软件维护、二次开发和成果移交，说明 WCC4SM V0.9.3 的目录组织、运行状态、GUI 分区、核心模块、数据流、Session 与导出机制。

V0.9.3 的架构目标不是把全部算法写进主界面，而是由主程序维护交互状态，由 src 目录中的函数完成可测试的独立计算。

## 2. 目录结构

| 路径 | 作用 |
|---|---|
| WCC4SM_V0_9_3.m | 当前主程序入口、GUI 创建、回调和跨页面状态协调 |
| WCC4SM_V0_9_2.m | 兼容入口；提示旧入口后转交 WCC4SM_V0_9_3 |
| src/ | 数据读取、峰分析、定标、验证、优化、子集搜索、Session 等核心函数 |
| tests/ | MATLAB 单元测试与界面支持测试 |
| docs/ | 用户、算法、架构、测试和专题设计文档 |
| data/ | 示例或项目数据，具体内容以当前发行包为准 |
| CHANGELOG.md | 版本变化记录 |

主程序依赖 src 中的函数。运行前应将项目根目录和 src 加入 MATLAB 路径，或直接从项目根目录启动。

## 3. 总体分层

### 3.1 交互层

由 WCC4SM_V0_9_3.m 负责：

- 创建窗口、Tab、表格、坐标轴和按钮；
- 接收用户输入并校验基本条件；
- 调用核心算法；
- 把结果写回表格、图形和状态提示；
- 协调页面之间的数据复用；
- 保存和恢复 Session。

### 3.2 计算层

src 中的函数负责：

- 文件解析与坐标解释；
- 光谱预处理；
- 单峰参数计算；
- 波长匹配与多项式拟合；
- LOO、残差和性能统计；
- Add-One、逐一替换和样本影响；
- 规则子集、模型距离、epsilon cover 和 Beam Search。

计算函数应尽量使用显式输入和返回结构体，避免依赖 GUI 控件句柄，从而便于单元测试和批处理复用。

### 3.3 持久化与输出层

该层负责：

- Session 结构构造、验证、保存和加载；
- 模型 MAT 导入导出；
- 优化与 Set Design 表格导出；
- 图形和分析结果的用户保存。

## 4. 主要运行状态

主界面在一次运行中维护以下逻辑对象。实际变量名称可能因回调局部作用域而略有差异，维护时应保持语义一致。

| 状态对象 | 内容 |
|---|---|
| D | 原始光谱、坐标、文件信息和输入解释 |
| R | 预处理结果、显示信号和暗信号信息 |
| peaks | 检测峰清单、窗口、状态及单峰分析结果 |
| peakDataset | 已确认峰参数组成的可匹配数据集 |
| L | 参考谱线主库、活动选择模式和禁用状态 |
| calPairs | 峰与参考波长的匹配关系 |
| models | 模型比较页保存的模型快照 |
| current/final model | 当前拟合或已应用到光谱的定标模型 |
| optimization results | Add-One、替换、阶次和影响分析结果 |
| positionCrossValidation | 峰位定义交叉验证矩阵、组合统计、残差和当前显示选择 |
| SetDesign | 样本池、规则候选、Beam 层、选择和界面设置 |

### 4.1 状态依赖

典型依赖链为：

    光谱 D
      -> 预处理 R
      -> 检测峰 peaks
      -> 峰数据集 peakDataset
      -> 参考线 L 与匹配 calPairs
      -> 定标模型
      -> 验证、影响和子集设计

上游数据发生实质变化时，下游结果可能失效。例如改变像素模式后，应重新检查峰坐标、匹配和模型，不能仅刷新图形。

## 5. GUI 组织

### 5.1 顶部全局区

顶部提供模块选择、打开 FIG、保存 Session、加载 Session和帮助入口，并显示最近一次全局状态。

### 5.2 中央分析区

中央 Tab 承载工作流页面：

- Peak Analysis / Peak Parameter Statistics；
- Wavelength Matching；
- Calibration Fit & Residuals；
- Model Validation（Current model 与 Peak-position cross validation 子页）；
- Model Comparison / Selected Residuals；
- Calibrated Performance；
- Calibration Optimization；
- Point Influence；
- Set Design。

基础页面对应常规定标流程；Optimization、Point Influence 和 Set Design 属于研究与诊断层，新用户不需要在首次操作中全部使用。

### 5.3 右侧操作与数据区

右侧集中放置：

- 数据加载与显示设置；
- 峰检测和当前峰分析；
- 参考谱线；
- 峰清单、峰数据集、匹配与最终拟合操作。

这种布局使光谱、当前峰和主分析图可在切换工作步骤时保持可见。随着高级功能增加，个别页面使用子 Tab 或自适应工具栏避免控件互相覆盖。

### 5.4 自适应布局原则

Set Design 工具栏根据窗口宽度重排参数与按钮。维护时应优先保证核心操作在普通笔记本分辨率下可见：Refresh pool、Target K、Generate rule set、Initialize Beam、Calculate K-1、Confirm checked 和 Export results。

## 6. 核心模块映射

### 6.1 数据输入与预处理

| 功能 | 文件 |
|---|---|
| 光谱读取 | src/wc4sm_read_spectrum_file.m |
| 暗光谱读取 | src/wc4sm_read_dark_spectrum.m |
| 预处理 | src/wc4sm_preprocess_spectrum.m |

读取模块负责格式解析和输入元数据，预处理模块负责暗信号/基线、负值规则和用于后续计算的信号生成。

### 6.2 峰分析

| 功能 | 文件 |
|---|---|
| 单峰参数 | src/wc4sm_analyze_peak.m |
| 峰检测及窗口辅助 | 相关 wc4sm peak/detect 函数与主界面回调 |

峰结果保存在 peak 记录的 Result 中。旧 Session 若缺少后来增加的字段，界面刷新代码应提供缺省值，避免因新字段直接读取而中断。

### 6.3 定标与验证

| 功能 | 文件 |
|---|---|
| 多项式拟合 | src/wc4sm_fit_calibration.m |
| LOO | src/wc4sm_validate_calibration_loo.m |
| 定标性能 | src/wc4sm_calculate_calibrated_performance.m |
| 峰位定义交叉验证 | src/wc4sm_cross_validate_peak_positions.m |
| 阶次分析 | src/wc4sm_analyze_model_order.m |

模型结构除系数外还应包含归一化参数、像素模式、峰位置定义、阶次、样本和指标。模型比较页保存的是快照，应用模型则会改变当前用于波长映射的模型状态，两者语义不同。

### 6.4 优化和样本诊断

| 功能 | 文件 |
|---|---|
| Add-One 单步/路径 | src/wc4sm_analyze_add_one.m、src/wc4sm_analyze_add_one_path.m |
| 样本替换 | src/wc4sm_analyze_seed_replacements.m |
| 旧种子稳定性/组合 | src/wc4sm_analyze_seed_stability.m、src/wc4sm_analyze_seed_combinations.m |
| 单点影响 | src/wc4sm_analyze_point_influence.m |
| 多阶影响 | src/wc4sm_analyze_influence_orders.m |

旧“种子”命名保留在部分文件名中以兼容历史代码，但界面和新文档统一解释为“当前样本集合”或“逐一替换”。

### 6.5 Set Design

| 功能 | 文件 |
|---|---|
| 影响画像 | src/wc4sm_build_influence_profile.m |
| 规则生成 | src/wc4sm_generate_subset_mask.m |
| 只分窗不选点 | src/wc4sm_partition_subset_windows.m |
| 单个/批量子集评价 | src/wc4sm_evaluate_subset.m、src/wc4sm_batch_evaluate_subsets.m |
| 模型距离 | src/wc4sm_model_distance.m |
| epsilon cover | src/wc4sm_build_epsilon_cover.m |
| Beam 初始化 | src/wc4sm_initialize_backward_beam.m |
| 提出 K-1 层 | src/wc4sm_backward_beam_step.m |
| 接受一层 | src/wc4sm_accept_beam_layer.m |
| 完整自动路径接口 | src/wc4sm_backward_beam_search.m |

GUI 默认使用分阶段接口，使每一层的候选先展示、后确认。完整搜索接口保留给批处理或测试使用，不应替代界面的人工审核。

## 7. 页面之间的数据流

### 7.1 从峰到模型

1. 光谱加载后建立 D；
2. 预处理产生 R；
3. 自动或子窗口寻峰建立 peaks；
4. 确认峰参数后写入 peakDataset；
5. 与活动参考线建立 calPairs；
6. 根据指定峰位置和阶次拟合模型；
7. 模型可加入 models 比较，也可应用为当前模型。

### 7.2 从模型到高级分析

影响、Add-One、替换和 Set Design 使用当前有效匹配池。计算前必须刷新样本池，确保峰位置定义、阶次和匹配状态与当前设置一致。

Set Design 中：

- 左表表示样本池及人工 Use 选择；
- 右表表示规则候选或 Beam 候选；
- 成员子表显示右表当前候选具体包含的峰；
- 左图显示覆盖与影响；
- 右图显示当前候选拟合点、验证点和残差。

## 8. 模型比较与选择状态

模型比较页的表格选择只改变当前强化显示对象。切换模型时应恢复上一模型的普通样式，并只为新选择模型增加连线、加粗点和文字提示。

同理，替换轮次表的选择应触发一次完整重绘，而不是不断 hold on 叠加。长期维护应遵循：结果数据保存在状态中，坐标轴只是状态的视图，不把绘图对象本身当作唯一数据源。

## 9. Session 架构

### 9.1 主要函数

- src/wc4sm_create_session.m：从当前状态构造 Session；
- src/wc4sm_validate_session.m：检查结构、版本和关键字段；
- src/wc4sm_save_session.m：写入 MAT；
- src/wc4sm_load_session.m：读取并返回经过验证的 Session。

### 9.2 保存范围

Session 应保存能够复现工作的数据状态，而不仅是当前图形：

- 输入数据与预处理设置；
- 峰、峰参数和排除状态；
- 参考线、选择模式和匹配；
- 定标模型与模型比较清单；
- 峰位定义交叉验证结果及其 Full fit/LOO、公共池/成对池和显示选择；
- 优化分析结果；
- Set Design 样本池、候选、成员、Beam accepted/pending layers、Window Partition 边界和逐样本归属；
- Target K、B perf、B div、eps RMS、eps MAX 等设置。

### 9.3 向后兼容

V0.9.3 新增字段应作为可选字段读取。旧 Session 缺少 SetDesign、PositionCrossValidation 或峰对称性字段时，应建立空的缺省状态，而不是让界面刷新失败。

### 9.4 事务式加载

加载流程应先读取和验证临时 Session，只有全部关键检查通过后才替换当前 GUI 状态。加载失败时保留原状态，避免用户正在进行的工作被部分覆盖。

## 10. 导出架构

### 10.1 模型导出

模型 MAT 用于机器复现，应包含模型公式所需全部参数和数据语义。界面文字或截图不能替代模型文件。

### 10.2 Set Design 导出

Set Design 导出包括主 MAT 和便于审阅的 CSV：

- pool：完整样本池与影响信息；
- windows：分窗汇总、窗口权重、目标偏差和状态；
- window_members：每个样本的归一化权重、累计权重和窗口归属；
- candidates：规则与 Beam 候选摘要；
- members：候选与成员的展开关系；
- beam_layers：各 Beam 层概要；
- beam_nodes：各层节点与状态。

导出应保留 ID、来源、角色、K、删除点、验证指标、覆盖和 Keep/Accepted 状态，确保离开 GUI 后仍可追溯。

### 10.3 峰位定义交叉验证导出

交叉验证 CSV 应按 calibration peak position 与 application peak position 展开每个矩阵单元格，至少保存 Validation、Pool、Degree、N、NTrain、RMSE、Bias、STD、P95、MAX 和 Slope。导出顺序不能替代方向字段；行与列的含义必须显式保留。

## 11. 错误处理原则

- 输入不完整：按钮禁用或给出明确前置条件；
- 数值不可拟合：返回受控错误，不生成半成品模型；
- Session 不兼容：报告缺失或非法字段，保留原状态；
- 表格刷新：对旧数据缺失字段使用缺省显示；
- 自动优化：推荐结果不自动加入模型比较，必须经用户确认；
- 图形选择：切换对象时先恢复基础图层，避免残留强化线。

## 12. 测试边界与可测试性

计算层函数应由 tests 中的单元测试覆盖。GUI 回调中难以自动验证的内容，通过支持函数测试、静态字符串/结构检查和人工界面验收共同保证。

重要数值逻辑不得只存在于匿名回调中。新增算法时，应先形成可独立调用的 src 函数，再由 GUI 包装。

## 13. 扩展建议

新增功能时优先遵循以下顺序：

1. 明确输入、输出和统一指标口径；
2. 在 src 中实现无 GUI 依赖的核心函数；
3. 增加单元测试；
4. 接入 Session 和导出；
5. 最后增加 GUI 控件与可视化；
6. 更新用户、算法、架构和验收文档。

这能防止功能只在界面上“看起来存在”，但无法保存、复现或验证。

## 14. 当前已知限制

- 主界面集中承载完整流程，低分辨率下仍需关注控件自适应和表格可读性；
- 大量候选子集主要为串行计算，极大搜索空间仍会增加运行时间；
- GUI 视觉行为需要 MATLAB 桌面环境人工验收；
- 当前帮助入口以既有可列出的文档格式为主，新 Markdown 文档发布时还需按发行流程转换或纳入帮助索引；
- 历史函数名中仍存在 seed 等旧术语，新开发应使用 set、subset、replacement 等统一语义。

## 15. 文档关系

- 操作流程：WCC4SM_V0.9.3_用户操作与完整工作流程说明_V1.0.md
- 指标与算法：WCC4SM_V0.9.3_数据处理算法与统一指标说明_V1.0.md
- Set Design 专题：WCC4SM_V0.9.3_Set_Design操作与指标说明.md
- 测试验收：WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md
- 旧版架构文档：作为 V0.9 历史基线保留，不再代表 V0.9.3 的完整状态。
