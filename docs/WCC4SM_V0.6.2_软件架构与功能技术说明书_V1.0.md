# WCC4SM V0.6.2 软件架构与功能技术说明书

文档版本：V1.0

软件版本：WCC4SM V0.6.2

编制日期：2026-08-04

## 1. 文档目的

本文档说明 WCC4SM V0.6.2 的设计目标、软件结构、核心算法、主要数据
结构、输入输出、会话与模型兼容规则、测试体系及维护边界，用于软件维护、
科研复现、技术审查和后续版本开发。

## 2. 软件概述

WCC4SM（Wavelength Characterization and Calibration for Spectrometer）是
一个 MATLAB 图形化光谱仪波长表征与校准工具。软件面向汞氩等线光谱数据，
完成光谱预处理、峰检测、峰参数分析、参考谱线管理、峰线配对、多项式波长
定标、残差与留一法验证、模型比较、模型应用、校准后性能分析及完整工作会话
恢复。

软件采用“可追溯人工确认 + 数值模块自动计算”的设计原则。自动检测结果不
直接成为最终定标数据，操作者需要检查峰窗、峰形和参考谱线对应关系。

## 3. 运行环境与依赖

- 支持基线：MATLAB R2022a 或更高版本。
- 主界面使用 `uifigure`、`uigridlayout`、`uitabgroup`、`uitable` 和
  `uiaxes`。
- 全谱和子窗峰检测使用 `findpeaks`，需要 Signal Processing Toolbox。
- 当前自动测试的数值模块以 Base MATLAB 为主。
- 支持 Windows 环境；其他 MATLAB 支持的平台需要重新完成 GUI 验收。

启动入口：

```matlab
WCC4SM_V0_6_2
```

回归测试入口：

```matlab
results = run_wc4sm_tests;
```

## 4. 总体架构

软件由一个 GUI 协调层、独立数值模块、数据与参考资产、测试和文档组成。

```text
WCC4SM_V0_6_2.m
├─ GUI 布局与交互状态
├─ 数据加载、峰确认和参考线配对工作流
├─ 模型管理、图形刷新和导出协调
├─ wc4sm_read_spectrum_file
├─ wc4sm_read_dark_spectrum
├─ wc4sm_preprocess_spectrum
├─ wc4sm_analyze_peak
├─ wc4sm_fit_calibration
├─ wc4sm_validate_calibration_loo
├─ wc4sm_calculate_calibrated_performance
└─ wc4sm_create/save/load/validate_session
```

GUI 主程序持有当前会话状态。独立模块不直接修改 GUI，输入通过参数传递，
结果通过结构体返回。这一边界使核心数值行为可以通过非 GUI 测试保护。

## 5. 模块职责

### 5.1 `wc4sm_read_spectrum_file`

- 读取一列或两列数值光谱文件。
- 去除全空数值行和列。
- 校验坐标严格递增、数据有限且样本数不少于 3。
- 生成原始信号、输入坐标、自然像素序列和输入波长字段。

### 5.2 `wc4sm_read_dark_spectrum`

- 读取暗光谱。
- 校验暗光谱长度和坐标与测量光谱一致。
- 为预处理模块提供逐样本暗信号。

### 5.3 `wc4sm_preprocess_spectrum`

- 支持暗光谱扣除或人工常数基线。
- 可将负值钳位为零。
- 生成校正信号和归一化信号。
- 对全非正信号返回稳定的零归一化结果。

### 5.4 `wc4sm_analyze_peak`

- 根据左右像素窗截取单峰。
- 使用端点线性基线隔离峰信号。
- 支持 PCHIP、线性和样条插值。
- 计算直接峰、插值峰、半高宽中心、质心、FWHM、ERW 和相关警告。
- 对截断峰窗、不完整半高点和无效坐标进行显式处理。

### 5.5 `wc4sm_fit_calibration`

- 对峰像素位置与参考波长进行多项式拟合。
- 保存 MATLAB 归一化系数、`Mu`、自然像素系数和可读方程。
- 计算拟合值、残差、均值、STD、RMS 和最大绝对残差。
- 调用 LOO 模块计算预测残差和删除点影响。

### 5.6 `wc4sm_validate_calibration_loo`

- 逐点执行 leave-one-out 重拟合。
- 计算被删除点的独立预测残差。
- 计算删除单点后完整评价域内的最大曲线变化。
- 输出 LOO RMS、LOO 最大绝对值和最大删除影响。

### 5.7 `wc4sm_calculate_calibrated_performance`

- 将峰参数映射到波长域。
- 对非线性模型分别换算左右半高点，避免用单点色散近似 FWHM。
- 计算波长域 FWHM、ERW、峰位差和像素波长间隔统计。

### 5.8 会话模块

- `wc4sm_create_session`：建立版本化会话结构和默认元数据。
- `wc4sm_validate_session`：检查顶层结构、数组一致性、模型和溯源信息。
- `wc4sm_save_session`：验证后保存唯一顶层变量 `WCC4SMSession`。
- `wc4sm_load_session`：加载并验证会话，拒绝无关或结构错误的 MAT。

## 6. GUI 结构

### 6.1 顶部区域

- 图形选择下拉框和 `OPEN FIG`。
- `SAVE SESSION`、`LOAD SESSION`。
- 高对比度工作流状态提示。

### 6.2 左侧控制页

- Data & Display：输入解释、像素模式、暗光谱、显示和弱峰子窗搜索。
- Peak Detection：`findpeaks` 参数和峰分析窗口参数。
- Current Peak：当前峰参数、警告、确认与跳转。
- Reference Lines：参考库、有效状态和选择模式导入导出。

### 6.3 中央图形页

- Peak Analysis
- Peak Parameter Statistics
- Wavelength Matching
- Calibration Fit & Residuals
- Model Validation
- Model Comparison
- Calibrated Performance

### 6.4 右侧工作页

- Peak List
- Peak Dataset
- Matching
- Calibration Fit

## 7. 核心工作流

```text
载入光谱
  → 暗光谱/基线预处理
  → 全谱峰检测
  → 峰窗分析与人工确认
  → 加载/选择参考谱线
  → 建立人工锚点对
  → 初始模型与自动扩展
  → 最终多项式拟合
  → 残差和 LOO 审查
  → 模型比较与应用
  → 校准后性能分析
  → 模型/数据/会话导出
```

任何影响信号、峰窗或像素语义的设置变化都会使相关结果失效或要求重新确认。

## 8. 像素坐标体系

MATLAB 数组下标与定标方程的像素自变量必须区分。数组下标仅用于访问内存，
用户可见的像素序列定义如下。

### 8.1 Full detector sequence

适用于未定标、开放全部探测器像素的仪器。像素 1 表示完整探测器输出的第一
个像素。

### 8.2 Valid-pixel sequence

适用于固件仅输出裁剪后有效像素序列的仪器。像素 1 表示有效序列第一点，不
保证对应物理探测器第一像素。

两种序列可能都从 1 开始，但其物理含义不同。新模型保存：

- `PixelCoordinateMode`
- `PixelFirst`、`PixelLast`、`PixelCount`
- `CalibrationPixelFirst`、`CalibrationPixelLast`

显式模式不一致时，软件拒绝应用模型，不推断偏移量、不静默转换系数。旧模型
缺少字段时按 legacy/unspecified 处理。

## 9. 峰检测与人工确认

全谱检测可选择校正信号或归一化信号，并配置最小高度、突出度、间距和宽度。
检测结果进入 Peak List，默认状态为未审核。

弱峰子窗搜索是补充流程：

- 必须先完成全谱检测。
- 子窗在局部范围重新归一化，可使用更敏感参数。
- 主光谱图显示起止虚线并实时更新。
- 子窗仅产生候选峰，必须人工加入峰列表后分析和确认。

峰窗、插值方法或因子变化会使已有确认失效，防止旧结果进入新模型。

## 10. 参考谱线与配对

软件支持内置 Basic 21、Paper 24、NIM Certificate 34 及外部参考库。
参考线状态依据相邻有效波长间距和参考分辨率分为 Recommended、Marginal 和
Unresolved。

操作者先建立少量人工锚点，初始多项式用于预测其他候选。自动扩展保持像素与
参考波长的单调顺序，并根据容差和置信度生成匹配。自动结果仍应人工审查。

## 11. 最终模型与验证

最终模型可选直接峰、插值峰、FWHM 中心、质心或高斯拟合峰位，支持 1–6 阶
多项式。程序要求至少 `degree + 2` 个有效点。

模型评价同时报告拟合残差与 LOO 指标。拟合 RMS 反映当前点集的拟合程度；
LOO RMS 和删除影响更适合发现过拟合、高影响点及不稳定的局部曲线。

模型应用前检查：

- 模型结构和系数有效。
- 像素坐标模式兼容。
- 评价波长有限且严格递增。
- 数据域超出拟合点范围时给出外推比例提示。

## 12. 会话保存与恢复

会话只包含一个顶层变量 `WCC4SMSession`。保存内容包括光谱、暗光谱、检测峰、
确认快照、参考线、配对、初始/最终/历史/应用模型、UI 设置及溯源元数据。

加载采用事务式恢复：先保存当前内存状态，完整加载和验证新会话，再替换 GUI；
若加载或视图恢复失败，则尽力恢复原状态并显示错误。

缺少推荐溯源信息产生警告；结构错误、数组长度不一致、无效模型或不支持的主
格式版本属于错误。

## 13. 输入输出

主要输入：测量光谱 CSV、暗光谱 CSV、参考线 `.lit/.txt/.csv`、选择模式 CSV、
模型 MAT 和会话 MAT。

主要输出：峰数据 MAT/CSV、初始定标 MAT/CSV、最终模型 MAT/TXT/CSV、参考
选择模式 CSV、完整会话 MAT。详细定义见
`WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md` 和
`WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md`。

## 14. 测试与验收

V0.6.2 基线包含 37 项非 GUI 回归测试，覆盖峰分析、定标、LOO、预处理、会话、
校准后性能和参考数据资产。发布前还执行 MATLAB 静态解析、GUI 初始化冒烟和
操作者完整流程验收。

需求、实现和测试的对应关系见
`WCC4SM_V0_6_2_REQUIREMENTS_TRACEABILITY_MATRIX.md`。

## 15. 已知限制

- GUI 主程序仍较大，部分界面协调逻辑尚未模块化。
- 文件对话框、人工峰审核和可编辑图形主要依赖人工验收。
- Legacy 模型缺少像素模式元数据，追溯能力弱于 V0.6.1 以后模型。
- 当前 Mode01 的 29 条波长均与已确认的日期化 NIST 主库精确一致；更换主库
  或模式时必须新建版本并重新运行数据资产测试。
- 模型不应在未确认设备、像素序列和适用域时跨仪器复用。

## 16. 维护和版本策略

- `main` 只保存已验收稳定版本。
- 稳定发布使用不可变 Git 标签；V0.6.1、V0.6.2 可独立恢复。
- 新功能和修复在独立分支通过 PR 集成。
- `result/`、会话 MAT、日志和本机配置不进入版本控制。
- 修改核心算法前先增加或更新回归测试，禁止仅为通过测试而改期望值。

## 17. 相关文档

- `README.md`
- `CHANGELOG.md`
- `TESTING.md`
- `WCC4SM_SESSION_FORMAT_V1.md`
- `WCC4SM_PIXEL_COORDINATE_SPEC_V1.md`
- `WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md`
- `V0_6_2_GUI_TEST.md`
- `WCC4SM_V0_6_2_ACCEPTANCE_REPORT.md`
