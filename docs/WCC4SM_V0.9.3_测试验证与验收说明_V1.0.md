# WCC4SM V0.9.3 测试验证与验收说明 V1.0

## 1. 目的与范围

本文规定 WCC4SM V0.9.3 的自动测试、数值一致性检查、GUI 人工验收、Session/导出验证和发布判定要求。

测试分为三层：

1. 核心算法自动测试；
2. 数据一致性与持久化测试；
3. MATLAB 桌面环境下的 GUI 人工验收。

自动测试通过不能替代 GUI 验收，截图正常也不能替代数值测试。

## 2. 测试环境记录

每次正式验收应记录：

- 操作系统与显示缩放比例；
- MATLAB 版本和必要工具箱；
- WCC4SM 版本、代码提交或发行包日期；
- 测试数据文件与 Session 文件；
- 屏幕分辨率；
- 测试人员和日期。

建议至少覆盖一台普通笔记本分辨率设备和一台大屏设备。

## 3. 自动测试执行

在 MATLAB 中进入项目根目录，执行：

    results = run_wc4sm_tests;

验收时保存 MATLAB 命令窗口摘要。若需要定位单个测试类，可使用：

    results = runtests('tests/TestSubsetDesignModules.m');
    results = runtests('tests/TestWindowPartition.m');
    results = runtests('tests/TestSessionModules.m');
    results = runtests('tests/TestPeakPositionCrossValidation.m');
    results = runtests('tests/TestV093UiSupport.m');

若分别运行多个测试类后再汇总，先将每个 `TestResult` 数组统一转换为列向量。不同测试类包含的测试方法数可能不同，不能直接使用 `[r1; r2; r3]` 拼接行向量：

    r1 = runtests('tests/TestInfluenceOrders.m');
    r2 = runtests('tests/TestOptimizationModules.m');
    r3 = runtests('tests/TestV093UiSupport.m');
    results = [r1(:); r2(:); r3(:)];
    table(results)

这里若只有最后的 `vertcat` 报错，而各测试类均显示“已完成”且没有失败摘要，表示测试已经执行完毕，错误仅来自结果数组的汇总方式。

测试类和测试数量会随版本增加，验收标准以“全部已发现测试通过、无 Failed 和 Incomplete”为准，不在本文固定数量。

## 4. 自动测试覆盖重点

| 测试领域 | 主要检查 |
|---|---|
| 文件输入 | 支持格式、坐标解析、异常输入 |
| 预处理 | 暗信号、基线、负值处理和数据长度 |
| 峰分析 | 峰位置、宽度、质心、边界与警告 |
| 定标模型 | 多项式拟合、归一化参数和预测 |
| LOO 与性能 | 留一残差、统计量和异常样本数 |
| 优化 | Add-One、替换、影响和阶次分析 |
| 子集设计 | 规则生成、评价、距离、cover 和 Beam |
| Session | 构造、验证、保存/加载和新增字段兼容 |
| GUI 支持 | 控件存在、回调连接、关键显示文本和辅助逻辑 |

### 4.1 Set Design 自动检查

TestSubsetDesignModules 应重点覆盖：

- 子集掩码长度、K 和边界条件；
- 全池模型与自身的模型距离为零；
- D_RMS、D_MAX 非负且对称；
- epsilon cover 同时执行 RMS 与 MAX 阈值；
- Initialize Beam 只建立当前层；
- Calculate K-1 只提出一层候选，不自动接受；
- Confirm/accept 后 K 才减少一；
- B perf 与 B div 的保留数不超过可用候选；
- 成员索引、删除点和父节点关系可追溯。

### 4.2 Session 自动检查

TestSessionModules 应覆盖：

- 无 SetDesign 字段的旧 Session 可加载；
- 新 Session 可保存并恢复 SetDesign 参数、候选和 Beam 状态；
- Pending layer 和 Accepted layer 不混淆；
- 非法或缺失关键字段返回受控错误；
- 加载失败不要求调用方接受部分状态。

### 4.3 峰位定义交叉验证自动检查

TestPeakPositionCrossValidation 应覆盖：

- 同定义与跨定义峰位组合均生成矩阵单元格；
- Full fit 与 LOO 均可计算；
- All-method common peaks 的所有单元格使用相同样本；
- Per-pair available peaks 保留每一对可用的训练数据；
- 对角线结果仍按真实模型残差计算，不被错误强制为零；
- Session 往返后交叉验证结果与显示选择保持一致。

## 5. 数值一致性验收

### 5.1 残差口径一致性

使用同一 37 点或当前全池模型检查：

1. 拟合集合等于验证池；
2. 峰位置、阶次、像素模式完全相同；
3. 模型比较页 FitRMSE 与全池验证 AllRMSE 应一致，仅允许浮点舍入差异；
4. 若不一致，先检查是否使用了 LOO、不同峰位置或不同验证池。

该项用于防止 Add-One 或替换末端仍与完整模型出现无依据差异。

### 5.2 LOO 与闭合残差区分

使用较小样本集验证：

- FitRMSE 可以小于 LOORMSE；
- 仅 m+1 个点拟合 m 阶多项式时，FitRMSE 不能作为唯一结论；
- 界面标题、下拉选择和表格列必须明确当前显示 Fit、LOO 或 All-point。

### 5.3 模型距离

- 模型与自身：D_RMS=0、D_MAX=0；
- 交换模型 A/B：结果不变；
- 不同模型：距离非负；
- epsilon cover：只有两个阈值均满足才归为同一邻域。

### 5.4 样本影响

固定三阶并使用同一匹配池：

- 横轴在样本序号、像素、波长间切换时，纵轴数值不改变；
- 手动 Y 轴只改变显示尺度；
- 多阶 mean/RMS/P95/MAX 来自每阶同一 Influence 向量；
- RMS influence 保持无量纲，不能标为 nm 或解释为 FitRMSE；
- 每个删除模型同时具有有限的 Deleted Fit RMSE 和 Deleted LOO RMSE；
- 多阶 DeletionFitRMSE/DeletionLOORMSE 与逐点删除结果按 pooled RMS 公式一致；
- 完整模型阶次扫描默认使用对数纵轴，其他共用图重新绘制时能恢复线性轴；
- 最终拟合、优化、单阶影响和两个扫描上限均允许到 20；
- 当样本数不足时，完整阶次扫描自动限制为 N-2，嵌套去一 LOO 影响扫描自动限制为 N-3；
- 强影响边界点只标识，不自动删除。

## 6. 标准 GUI 工作流验收

### 6.1 数据与峰分析

- [ ] 加载单列或双列光谱，无未捕获错误；
- [ ] 像素模式和 X 解释正确；
- [ ] 暗光谱/人工基线及负值选项可用；
- [ ] 自动寻峰清单与图中标记一致；
- [ ] 子窗口可补充弱峰；
- [ ] 当前峰参数、警告和确认状态正确刷新；
- [ ] 对称性阈值改变后推荐标识更新；
- [ ] 旧 Session 缺少对称性字段时不报错。

### 6.2 参考线、匹配与最终模型

- [ ] 参考主库加载、禁用和选择模式可用；
- [ ] 匹配表与光谱标注对应；
- [ ] 三阶拟合产生模型、残差和模型摘要；
- [ ] 模型可保存到比较页，但优化推荐不会未经确认自动加入；
- [ ] 应用模型后峰参数可切换到波长域；
- [ ] 模型导出包含系数、归一化参数和数据语义。

### 6.3 模型比较与残差显示

- [ ] 点击模型表一行后，仅该模型增加强化连线和提示；
- [ ] 切换另一行时，上一模型恢复普通散点；
- [ ] Fit、LOO、全池残差选择与标题一致；
- [ ] Reset plot scale 恢复自动尺度；
- [ ] 当前选中残差可查看直方图和位置图；
- [ ] 调整直方图 X 轴参数只影响显示范围或分箱，不改变残差数据。

### 6.4 Add-One、替换与样本影响

- [ ] Add-One 使用固定验证池，最终全池结果与完整模型一致；
- [ ] 替换表点击轮次后只强化当前轮次；
- [ ] 重新选择集合并计算时，旧曲线不残留；
- [ ] RMSE 改善未超过阈值时显示“小幅改善/作用接近”，不误报强推荐；
- [ ] 样本影响与替换结果使用不同子 Tab 或独立图形状态；
- [ ] 影响图横轴可切换序号、像素和波长；
- [ ] 阶次上限和 Y 轴手动范围可正常输入。

### 6.5 峰位差与峰位定义交叉验证

- [ ] Peak Position Differences 的左上散点与左下直方图由同一个峰位序列同步切换；
- [ ] 右上直接峰位映射可在不拟合及 1～3 阶之间切换，右下残差直方图同步刷新；
- [ ] Model Validation > Peak-position cross validation 可计算四种峰位的完整矩阵；
- [ ] 矩阵行明确表示 calibration peak position，列明确表示 application peak position；
- [ ] 点击热图或表格单元格后，残差点图、直方图、方向和 N 同步变化；
- [ ] Selected cell 与 Diagonal comparison 显示内容符合名称；
- [ ] Full fit/LOO 和 All-method common peaks/Per-pair available peaks 切换后状态文本与数值更新；
- [ ] Training set 可从全部匹配点、当前最终模型、选中的 Model Comparison 模型和选中的 Set Design 候选读取 Peak ID；
- [ ] 选择 6 点训练集并运行 Full fit 后，界面显示 train N=6、eval N=完整匹配点数，残差图覆盖完整评价池；
- [ ] 相同训练集切换 LOO 后，eval N=6，表示训练集内部留一，而不是全池外部评价；
- [ ] RMSE、Bias、STD、P95、MAX、Slope 的色标和表格数值一致；
- [ ] 普通笔记本窗口宽度下 Matrix metric 和 Pool 控件可见且可读。
- [ ] All metrics 子页同时显示 RMSE、STD、Bias、P95、MAX、Slope 六张热图，选中单元格红框位置一致；
- [ ] Calibration-row residuals 子页显示当前定标行对应四种应用峰位的 2×2 残差图；
- [ ] All histograms 子页按热图相同的 calibration 行/application 列方向显示 4×4 直方图，并使用统一横轴范围；
- [ ] 三个总览子页通过 OPEN FIG 打开时保持原阵列，而不是生成大量独立窗口；

## 7. Set Design GUI 验收

### 7.1 页面可见性

分别在最大化、普通窗口和笔记本分辨率下检查：

- [ ] Target K、B perf、B div、eps RMS、eps MAX 可见；
- [ ] Generate rule set、Initialize Beam、Calculate K-1、Confirm checked 可见；
- [ ] Export results 和 Guide 可见；
- [ ] 表格与坐标轴没有覆盖按钮；
- [ ] 必要时可通过页面内部滚动或自适应排列访问全部操作。

### 7.2 手动与规则子集

- [ ] Refresh pool 后左表与当前有效匹配池一致；
- [ ] 左表 Use 可人工勾选；
- [ ] Target K 与所选成员数量提示清楚；
- [ ] 每种规则可生成候选；
- [ ] 点击右表候选后，“Selected subset members”显示具体 Peak、Pixel、Wavelength、Influence、Rank；
- [ ] 左图选中点与成员表一致；
- [ ] 右图拟合子集和仅验证点区分清楚。

### 7.3 Window Partition

在进入 Beam 前单独检查 Window Partition：

- [ ] Equal wavelength width 使用左闭右开、末窗右端闭合规则；
- [ ] Equal cumulative influence 的 cut index 严格递增且每窗至少一个样本；
- [ ] 窗口表的 N、Weight、Max influence peak、Target weight 和 Deviation 与图一致；
- [ ] 上下图使用相同窗口边界并共享波长横轴；
- [ ] Raw influence / Normalized weight 和累计曲线开关正常；
- [ ] 分窗后没有样本被高亮为已选，也没有生成候选模型；
- [ ] Empty window、Dominant influence sample 和零总 Influence 给出明确状态；
- [ ] Clear Windows 不清除样本池、Beam 或已有候选。

### 7.4 分阶段 Beam

- [ ] Initialize Beam 建立 B000 或当前基线；
- [ ] Calculate K-1 只产生当前 K-1 候选；
- [ ] 未 Confirm 前再次计算不会静默越过当前层；
- [ ] 可勾选多个 Keep 候选；
- [ ] Confirm checked 后接受层记录保留，进入下一 K；
- [ ] Reinitialize 可清除搜索路径并从当前池重新开始；
- [ ] 切换候选时成员表和图形同步更新；
- [ ] Add model to comparison 只在用户点击后执行。

### 7.5 参数解释检查

- [ ] Guide 能解释 Target K、B perf、B div、eps RMS、eps MAX；
- [ ] B perf=1、B div=1 时仍至少保留性能和多样性路径（候选足够时）；
- [ ] eps 很小时 cover 更细，eps 增大时代表模型通常减少；
- [ ] Target K 不满足三阶模型最小点数或覆盖约束时给出提示。

## 8. Session 验收

- [ ] 峰位定义交叉验证结果、池口径、验证方式、指标和选择单元格可保存并恢复；

准备一个已经完成峰匹配、模型比较和 Set Design 的状态：

1. 在 Beam 已 Calculate K-1 但尚未 Confirm 时保存 Session；
2. 关闭程序并重新打开；
3. 加载 Session；
4. 检查光谱、峰、参考线、匹配、模型清单；
5. 检查 Set Design 参数、样本池、候选成员和 Pending Beam 层；
6. 执行 Confirm checked，确认能从恢复位置继续；
7. 再保存并加载，确认 Accepted layers 保留。

加载一个旧版 Session，确认缺少 SetDesign 时以空状态启动高级页面，其他历史数据仍正常。

## 9. 导出验收

### 9.1 模型

- [ ] 导出 MAT 可重新导入；
- [ ] 导入后预测结果与导出前一致；
- [ ] 像素模式、峰位置、阶次、mu 和系数完整；
- [ ] Import & apply 与仅 Import 的状态变化符合按钮含义。

### 9.2 Set Design

点击 Export results 后检查：

- [ ] 主 MAT 文件存在且可 load；
- [ ] pool.csv 行数与样本池一致；
- [ ] candidates.csv 包含当前规则和 Beam 候选；
- [ ] members.csv 可按候选 ID 还原成员；
- [ ] beam_layers.csv 记录每层 K 和状态；
- [ ] beam_nodes.csv 记录节点、父子和保留信息；
- [ ] CSV 中的 K、ID、Deleted、指标与 GUI 当前表一致。

### 9.3 峰位定义交叉验证

- [ ] Export CSV 的行数与有效矩阵组合一致；
- [ ] 每行包含 calibration/application 峰位方向、Validation、Pool、Degree、TrainingSet、EvaluationSet、NTrain 和 NEval；
- [ ] RMSE、Bias、STD、P95、MAX、Slope 与 GUI 表格一致。

## 10. 静态检查

代码交付前执行仓库差异检查：

    git diff --check

同时搜索：

- 未解决的合并标记；
- 临时调试输出；
- 仍显示旧 C(n,5) 为主流程的帮助文字；
- seed、validation RMS 等术语在新界面中的歧义；
- 文档引用的文件名是否实际存在。

静态检查不运行 MATLAB，但能提前发现空白、拼接和文档引用问题。

## 11. 缺陷分级

- 阻断：程序无法启动、Session 破坏、模型结果错误、核心流程无法继续；
- 严重：指标口径不一致、候选成员错误、导出不可复现、主要按钮不可见；
- 一般：局部刷新、选择强化残留、文字不清或需要规避操作；
- 建议：布局、配色、帮助和效率改进，不影响正确结果。

阻断和严重缺陷未关闭时不得作为正式版本发布。

## 12. 发布验收条件

正式发布至少满足：

- 自动测试全部通过；
- 37 点完整模型的残差口径一致性通过；
- 标准 GUI 工作流通过；
- 普通窗口下 Set Design 核心按钮可见；
- 分阶段 Beam、Session 中断恢复和 Set Design 导出通过；
- 峰位定义交叉验证矩阵、单元格残差、两种验证方式和两种样本池通过；
- 用户、算法、架构和测试文档已同步；
- CHANGELOG 记录本版功能与兼容性变化。

## 13. 验收记录模板

| 项目 | 结果 | 证据/备注 |
|---|---|---|
| 自动测试 | Pass/Fail | MATLAB 输出或日志 |
| 数值一致性 | Pass/Fail | 模型 ID、指标截图/导出 |
| 标准 GUI 流程 | Pass/Fail | 数据文件和问题记录 |
| 峰位定义交叉验证 | Pass/Fail | 模式、样本池、矩阵和残差截图/CSV |
| Set Design | Pass/Fail | K、参数、候选 ID |
| Session 恢复 | Pass/Fail | Session 文件名 |
| 导出复现 | Pass/Fail | 导出目录与核对结果 |
| 低分辨率布局 | Pass/Fail | 分辨率和截图 |
| 已知问题 | None/List | 缺陷编号与级别 |
| 最终结论 | Accept/Reject | 验收人、日期 |

## 14. 相关文档

- WCC4SM_V0.9.3_用户操作与完整工作流程说明_V1.0.md
- WCC4SM_V0.9.3_数据处理算法与统一指标说明_V1.0.md
- WCC4SM_V0.9.3_软件架构与核心模块说明_V1.0.md
- WCC4SM_V0.9.3_Set_Design操作与指标说明.md
- docs/TESTING.md 和 docs/V0_9_2_GUI_TEST.md 作为早期测试记录保留。
