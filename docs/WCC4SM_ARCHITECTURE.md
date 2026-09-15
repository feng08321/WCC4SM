# WCC4SM_ARCHITECTURE — 软件架构、模块和数据流

版本：V1.0（基线）　对应代码：WCC4SM V1.1（2026-09-15）　维护者：Zheng Feng

> 本文是 WCC4SM 技术文档基线四件套之一（架构），是代码结构的**权威描述**。
> 与 `WCC4SM_V1.0_软件架构与开发流程全景_V1.0.md`（叙事性全景）的关系：本文是
> 精炼的查阅基准，全景文档是补充读物。冲突时以本文和代码为准。

## 1. 系统定位

WCC4SM（Wavelength Characterization and Calibration for Spectrometer）是一个
MATLAB 单文件 GUI 应用 + 无状态算法库，服务于阵列光谱仪波长定标科研：
光谱预处理 → 峰检测与峰位表征 → 参考线匹配 → 波长定标 → 模型验证 →
定标子集设计 → 定标性能分析 → 会话保存/恢复。

- 许可证：Apache-2.0（开源，科研用途）
- 运行环境：MATLAB R2022a+（桌面 GUI）；Windows EXE 由 MATLAB Compiler 打包
- 数据单一事实源：`reference_data/`（MATLAB 与未来 Python 版共享）

## 2. 分层架构

```
┌────────────────────────────────────────────────────────────┐
│ GUI 层   WCC4SM_V1_0.m（主函数 + ~270 个嵌套回调，5359 行） │
│          事件处理、绘图、表格、状态编排（60+ 闭包变量）      │
├────────────────────────────────────────────────────────────┤
│ 算法层   src/  67 个 wc4sm_* 模块（无状态、可独立测试）      │
├────────────────────────────────────────────────────────────┤
│ 数据层   reference_data/（线库、NIST 查询、基准数据）        │
│          test_data/（测试谱，含经典案例 oto_HDR_20260814z） │
├────────────────────────────────────────────────────────────┤
│ 持久化   Session v1.0（.mat，wc4sm_create/validate/save/    │
│          load_session）                                      │
├────────────────────────────────────────────────────────────┤
│ 测试层   tests/  21 个套件、145 个用例（runtests 动态发现）  │
├────────────────────────────────────────────────────────────┤
│ 部署层   tools/build_windows_exe.m → build/                 │
│          WCC4SM_V1.0_Windows_x64/（EXE + 外挂文档/数据）     │
└────────────────────────────────────────────────────────────┘
```

设计原则：算法层**不持有任何 UI 句柄和会话状态**，GUI 只负责编排与显示；
所有跨平台可复用逻辑必须下沉到 `src/`（D1 系列重构已完成此收口）。

## 3. 算法层模块地图（src/，67 个模块）

| 域 | 模块 | 职责 |
|---|---|---|
| 数据 IO 与预处理 (5) | `wc4sm_read_spectrum_file` / `wc4sm_read_dark_spectrum` | 读取测量/暗谱 CSV（单列或 X,Y） |
|  | `wc4sm_preprocess_spectrum` | 暗谱扣除（优先）或人工基线扣除、负值截断、最大值归一化 |
|  | `wc4sm_clean_matrix` | 按列向量化矩阵（输入净化） |
|  | `wc4sm_robust_upper_limit` | 稳健纵轴上限（max / P95） |
| 峰分析 (2) | `wc4sm_analyze_peak` | 局部窗峰位表征：D/I/F/C 四种峰位 + SlopeStability、FWHM、ERW、HDR、峰形分类 |
|  | `wc4sm_calculate_calibrated_performance` | 定标后波长域性能（中心波长、FWHM/ERW 换算 nm） |
| 线库与参考表 (2) | `wc4sm_load_builtin_library` | 加载内置线库（basic21 / paper24 / nim34，数据在 reference_data/*.lit） |
|  | `wc4sm_format_reference_table` | 参考线表格式化（合并实测峰与线库行） |
| 初始映射 (3) | `wc4sm_match_ordered_sequence` | 预测峰位↔参考线的动态规划单调对齐 |
|  | `wc4sm_build_initial_model` | 初始定标的锚点线性拟合核心 |
|  | `wc4sm_evaluate_wavelength_model` | 统一模型求值入口（线性 a·p+b 或归一化多项式） |
| 定标与验证 (4) | `wc4sm_fit_calibration` | 归一化多项式定标拟合（polyfit+mu） |
|  | `wc4sm_validate_calibration_loo` | LOO 留一交叉验证诊断 |
|  | `wc4sm_poly_normalized_to_natural` | 归一化系数→自然幂系数（仅用于方程显示） |
|  | `wc4sm_format_calibration_equation` | 定标方程文本格式化 |
| 模型比较 (1) | `wc4sm_model_distance` | 公共网格上两定标曲线的 RMS/MAX 距离（Compatibility 基础） |
| 峰位定义验证 (2) | `wc4sm_cross_validate_peak_positions` | 4×4 峰位定义交叉验证矩阵（Full fit / LOO） |
|  | `wc4sm_fit_peak_position_difference` | 峰位差（相对 FWHM center）一线性拟合 |
| 影响与阶次分析 (4) | `wc4sm_analyze_point_influence` | 单点删除影响（CurveChange / InfluenceRatio） |
|  | `wc4sm_analyze_influence_orders` | 跨阶次影响统计 + Generalization Gap |
|  | `wc4sm_analyze_model_order` | 模型阶次扫描 |
|  | `wc4sm_build_influence_profile` | 影响剖面组装（供子集设计） |
| 子集设计与优化 (17) | `wc4sm_generate_subset_mask` | 规则集：Manual / Top-k influence / Maximin / Locked boundary / Window 系 |
|  | `wc4sm_partition_subset_windows` | 分窗：等波宽 / 等累积影响 |
|  | `wc4sm_recommend_window_samples` | 窗内推荐（advisory） |
|  | `wc4sm_evaluate_subset` / `wc4sm_batch_evaluate_subsets` | 子集定标质量评估与批量评估 |
|  | `wc4sm_build_epsilon_cover` | ε-cover 候选覆盖 |
|  | `wc4sm_analyze_add_one` / `wc4sm_analyze_add_one_path` | Add-One 单点增益与路径分析 |
|  | `wc4sm_analyze_seed_combinations` / `wc4sm_analyze_seed_stability` / `wc4sm_analyze_seed_replacements` | 种子组合、稳定性、替换分析 |
|  | `wc4sm_initialize_backward_beam` / `wc4sm_backward_beam_step` / `wc4sm_backward_beam_search` / `wc4sm_accept_beam_layer` | 分阶段回溯 Beam Search |
|  | `wc4sm_export_optimization_csv` / `wc4sm_plot_optimization_diagnostics` | 优化历史导出与诊断绘图 |
| 会话持久化 (4) | `wc4sm_create_session` / `wc4sm_validate_session` / `wc4sm_save_session` / `wc4sm_load_session` | Session v1.0 结构创建、校验、保存、加载 |
| 状态构造 (12) | `wc4sm_empty_data` / `_reference` / `_line_library` / `_peaks` / `_local_candidates` / `_peak_dataset` / `_calibration_pairs` / `_mapping_candidates` / `_initial_model` / `_final_model` / `_calibration_models` + `wc4sm_make_calibration_pair` | 全部状态结构的单一构造入口（字段定义见 WCC4SM_DATA_DICTIONARY.md） |
| GUI 展示工具 (11) | `wc4sm_colors` / `wc4sm_style_axes` / `wc4sm_section_label` / `wc4sm_format_value` / `wc4sm_short_name` / `wc4sm_number_or_nan` / `wc4sm_logical_text` / `wc4sm_min_or_nan` / `wc4sm_max_or_nan` / `wc4sm_remove_calibration_pair` / `wc4sm_list_pdf_documents` | 配色、坐标轴样式、数值格式化、PDF 文档枚举等 |

## 4. 主工作流（数据流）

```
光谱 CSV ──► read_spectrum_file ──► D.raw / D.pixel
暗谱 CSV ──► read_dark_spectrum ─► D.dark
              preprocess_spectrum ─► D.corrected / D.normalized
findpeaks（GUI）─────────────────► peaks（P%03d）
analyze_peak（局部窗 ±L/R）──────► peaks.Result / peakDataset
load_builtin_library / 外部 .lit ─► L
build_initial_model ──► provisional ──► evaluate_wavelength_model
match_ordered_sequence（DP 单调对齐）─► calPairs（Auto global）
手动增删/锁定 ──────────────────► calPairs（Manual）
fit_calibration ───────────────► finalModel（+LOO 诊断）
applyModel ────────────────────► D.calibratedWavelength → 波长横轴
cross_validate / influence / subset design / beam search ─► 验证与设计工作区
calculate_calibrated_performance ─► FWHM/ERW（nm）→ Performance 页
create_session → save_session ─► Session v1.0 .mat（完整可恢复）
```

详细操作级流程见全景文档 §5 与用户操作说明。

## 5. 状态管理现状与演进

- 现状：GUI 主函数顶部声明 60+ 个闭包变量（谱数据 D、参考 R、线库 L、
  峰表 peaks、峰数据集 peakDataset、定标对 calPairs、各模型、UI 选中态等），
  被全部嵌套回调隐式共享。字段定义集中在 12 个 `wc4sm_empty_*` 工厂
  （见 WCC4SM_DATA_DICTIONARY.md）。
- 演进（技术债 D2，未实施）：将闭包变量按 5 个域结构分组
  （State.Data / State.Peaks / State.Calibration / State.Design / State.UI），
  使耦合可见、状态可整体快照，并为 Python 版 AppState 奠定映射。
  分组蓝图见 DATA_DICTIONARY §6。

## 6. 入口与遗留版本

| 入口 | 状态 | 用途 |
|---|---|---|
| `WCC4SM_V1_0.m` | **当前**（V1.1 内容） | 全部新工作；打包脚本入口 |
| `WCC4SM_V0_9_3.m` | 冻结快照 | 复现历史工作流 |
| `WCC4SM_V0_9.m` | 冻结快照 | 复现历史工作流 |
| `WCC4SM_V0_9_2.m` | 352 字节转调垫片 | 旧脚本兼容 |

旧入口为完全自包含的历史快照，不随当前版本改动；可通过 git tag
（v0.9 / v0.9.1 / v1.0）检出对应历史。

## 7. 构建与部署

- `tools/build_windows_exe.m`：MATLAB Compiler 打包 `WCC4SM_V1_0.m` →
  `build/WCC4SM_V1.0_Windows_x64/`（EXE + 外挂 `docs/`、`reference_data/`，
  外挂目录保持可替换以便用户补充 PDF 文档和参考数据）。
- 运行时：免费 MATLAB Runtime（MCR），无需 MATLAB 许可证。
- 发布门禁：全量回归 145/145 通过 + GUI 人工验收 → 打版本 tag →
  GitHub Release（附 EXE 与 release notes）。

## 8. 相关文档

- 方法数学定义：`WCC4SM_METHOD_SPECIFICATION.md`
- 字段与状态字典：`WCC4SM_DATA_DICTIONARY.md`
- 测试与验证：`WCC4SM_VALIDATION.md`
- 叙事性全景：`WCC4SM_V1.0_软件架构与开发流程全景_V1.0.md`
- 会话/模型/IO 格式：`WCC4SM_SESSION_FORMAT_V1.md`、
  `WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md`、`WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md`
