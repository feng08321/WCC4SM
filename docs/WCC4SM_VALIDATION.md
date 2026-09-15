# WCC4SM_VALIDATION — 测试验证基线

版本：V1.0（基线）　对应代码：WCC4SM V1.1（2026-09-15）

> 本文是 WCC4SM 技术文档基线四件套之四（验证）。说明 145 个测试在验证什么、
> 算法基准案例、覆盖缺口与已知限制。

## 1. 测试体系与运行方式

- 框架：MATLAB `matlab.unittest`（classdef 测试类），`tests/` 目录动态发现；
- 运行：`run_all_tests.m`（项目根）或
  `results = runtests('tests','IncludeSubfolders',true)`；
- 发布门禁：全部已发现测试通过，无 failed / incomplete；最新全量回归
  **2026-09-15，21 个套件 / 145 个用例全部通过**；
- 详细程序见 `docs/TESTING.md`，GUI 人工验收见
  `docs/WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md`。

## 2. 套件清单（21 套件 / 145 用例）

| 套件 | 用例数 | 验证内容 |
|---|---:|---|
| TestAddOnePath | 3 | Add-One 增益路径分析 |
| TestBuiltinLibraries | 5 | 内置线库加载（basic21/paper24/nim34 行数、排序、非法名拒绝） |
| TestCalibratedPerformanceModule | 6 | 定标后波长域性能（FWHM/ERW 换算） |
| TestCalibrationModules | 6 | 定标拟合、LOO、阶次扫描、方程格式化 |
| TestEmptyStateFactories | 12 | 12 个状态工厂字段一致性（数据字典的代码锚点） |
| TestGuiUtilityModules | 11 | GUI 展示工具（配色/格式化/稳健上限/cleanMatrix 等） |
| TestInfluenceOrders | 4 | 跨阶影响统计与 Generalization Gap |
| TestInitialMappingModules | 8 | 序列匹配单调性、初始模型构建、模型求值 |
| TestOptimizationModules | 4 | 优化诊断绘图与 CSV 导出 |
| TestPeakAnalysis | 5 | 峰分析四项定义 + **论文定标回归基准**（见 §3） |
| TestPeakPositionCrossValidation | 6 | 4×4 峰位交叉定义验证（Full/LOO、样本池） |
| TestPeakPositionDifferenceFit | 3 | 峰位差线性拟合 |
| TestSeedReplacements | 4 | 种子替换分析 |
| TestSeedStability | 1 | 种子稳定性 |
| TestSessionModules | 11 | 会话创建/校验/保存/加载往返一致性 |
| TestSpectrumPreprocessingModules | 6 | 预处理（暗谱优先、负值截断、归一化、异常拒绝） |
| TestSubsetDesignModules | 5 | 子集规则生成、ε-cover |
| TestV093UiSupport | 17 | V0.9.3 入口的 UI 支持检查（源码模式匹配） |
| TestV100UiSupport | 17 | V1.0 入口的 UI 支持检查（源码模式匹配） |
| TestWcc4smDataAssets | 5 | 数据资产完整性（reference_data / test_data 存在且可读） |
| TestWindowPartition | 6 | 分窗与窗内推荐 |

## 3. 算法基准案例

### 3.1 论文定标回归（TestPeakAnalysis/paperCalibrationRegression）

- 辅助函数：`tests/test_wc4sm_paper_calibration_case.m`；
- 数据：`test_data/Spectrum_1_8ms_avg50.csv` + `Spectrum_1_dark_8ms_avg50.csv`；
- 基准值：三阶定标 **STD = 0.18339283 nm**（样本标准差），
  Python 移植必须以同一基准在容差内对齐（项目级硬约束）；
- 作用：任何重构（D1 系列、后续 State 分组）的数值回归锚点。

### 3.2 HDR 经典案例

- 数据：`test_data/oto_HDR_20260814z.csv`（已纳入版本控制）；
- 用途：HDR 判据、饱和峰降级（PositionOnly）等分析流程的经典验证案例。

### 3.3 参考数据资产

`reference_data/` 内置线库与 NIST ASD 查询数据（2026-09-10 刷新）是
TestBuiltinLibraries / TestWcc4smDataAssets 的校验对象，也是 MATLAB 与
未来 Python 版的单一事实源。

## 4. 覆盖缺口与已知限制

1. **GUI 交互层无自动化测试**：TestV093UiSupport / TestV100UiSupport
   基于源码模式匹配（检查控件、回调、关键调用存在性），不启动真实界面；
   界面行为依赖人工验收（发布门禁的一部分）。计划补充 GUI 冒烟测试
   （启动/关闭验证）与少量 `matlab.uitest` 用例。
2. **嵌套外部验证未实现**：子集 LOO 只评估训练点逐一留出，不产生
   "训练子集 LOO 后再对外部全池汇总"的指标（见 METHOD_SPECIFICATION §12）。
3. **STD 双定义并存**：定标拟合用样本 STD（分母 N−1），交叉定义验证用
   总体 STD（分母 K）；两者不可混用（详见 METHOD_SPECIFICATION §8/§12）。
4. **环境敏感性**：兆芯（CentaurHauls）CPU 需修补 MATLAB MKL 的
   `blas.spec/lapack.spec` 才能运行数值测试（修复方法见项目记忆/运维记录）；
   CI 与标准 Intel/AMD 环境无此问题。
5. **运行环境要求**：MATLAB R2022a+；EXE 版依赖对应 MCR。
6. **SlopeStability** 为 GUI 第 5 种峰位定义，未纳入论文 4 定义横向比较。

## 5. 变更时的验证要求

- 算法层任何修改：跑全量 145 用例；
- 状态结构字段修改：同步改工厂 + TestEmptyStateFactories + DATA_DICTIONARY；
- 数值口径修改（残差方向、STD 定义、P95 方法等）：必须先改
  METHOD_SPECIFICATION 并评估对基准案例的影响；
- GUI 修改：除回归外，按验收说明做人工抽查。
