# WCC4SM V0.6.2 需求—设计—测试追踪矩阵

文档版本：V1.0

日期：2026-08-04

## 1. 追踪矩阵

| ID | 需求 | 主要实现 | 自动验证 | 人工验收 |
|---|---|---|---|---|
| R-001 | 读取单列/两列测量光谱 | `wc4sm_read_spectrum_file` | `TestSpectrumPreprocessingModules` | V0.6.2 数据加载 |
| R-002 | 校验坐标单调、有限和最少样本 | `wc4sm_read_spectrum_file` | 预处理模块测试 | 错误文件提示 |
| R-003 | 读取并对齐暗光谱 | `wc4sm_read_dark_spectrum` | 暗光谱对齐/长度测试 | GUI 暗光谱加载 |
| R-004 | 支持暗扣除、人工基线和负值钳位 | `wc4sm_preprocess_spectrum` | 基线、钳位和归一化测试 | Data & Display |
| R-005 | 通过 findpeaks 检测全谱峰 | GUI `detectPeaks` | 数据资产回归特征 | 全谱检测流程 |
| R-006 | 支持弱峰子窗候选搜索 | GUI local-search callbacks | GUI 初始化间接保护 | 子窗人工测试 |
| R-007 | 子窗边界实时显示且不累积 | `drawFull`, tagged guide deletion | GUI 冒烟 | 虚线更新/关闭 |
| R-008 | 计算峰位、FWHM、ERW 和质心 | `wc4sm_analyze_peak` | `TestPeakAnalysis` | Current Peak 审核 |
| R-009 | 峰窗修改后撤销旧确认 | GUI `invalidateConfirmation` | 状态结构回归 | 修改后重新确认 |
| R-010 | 管理内置和外部参考谱线 | GUI reference callbacks | `TestWcc4smDataAssets` | Reference Lines |
| R-011 | 导入/导出参考选择模式 | GUI import/export mode | 主库/模式一致性测试 | 模式往返 |
| R-012 | 建立和管理人工配对 | GUI matching callbacks | 排序和身份测试 | Matching 流程 |
| R-013 | 单调自动扩展峰线匹配 | `orderedSequenceMatch` | 数据/定标回归 | 自动配对审查 |
| R-014 | 多项式拟合并保存自然/归一化形式 | `wc4sm_fit_calibration` | `TestCalibrationModules` | 方程显示 |
| R-015 | 计算拟合残差统计 | `wc4sm_fit_calibration` | 精确/论文回归测试 | Fit & Residuals |
| R-016 | 执行 LOO 和删除影响分析 | `wc4sm_validate_calibration_loo` | 独立 LOO 对照 | Model Validation |
| R-017 | 保存并比较模型历史 | GUI model snapshots | 会话模型往返 | Model Comparison |
| R-018 | 应用模型生成严格递增波长轴 | GUI `validateAndApplyModel` | 定标与性能测试 | Pixel/Wavelength 切换 |
| R-019 | 对外推范围给出确认提示 | GUI model application | 边界逻辑检查 | 外推人工测试 |
| R-020 | 区分全探测器和有效像素序列 | Pixel sequence UI/state | Session metadata tests | 两模式人工测试 |
| R-021 | 拒绝显式模式不匹配模型 | `modelPixelCoordinatesCompatible` | 无效模式验证 | 跨模式拒绝 |
| R-022 | 在 GUI 显示模型模式和域 | fit/model/applied status | GUI 初始化 | V0.6.2 验收 |
| R-023 | 在 MAT/TXT/CSV 导出模式和域 | `exportCurrentModel` | Session round-trip | 导出文件检查 |
| R-024 | 计算校准后性能 | `wc4sm_calculate_calibrated_performance` | `TestCalibratedPerformanceModule` | Calibrated Performance |
| R-025 | 保存完整版本化会话 | `wc4sm_create/save_session` | `TestSessionModules` | SAVE SESSION |
| R-026 | 加载前验证会话结构 | `wc4sm_load/validate_session` | 无关 MAT/无效结构测试 | LOAD SESSION |
| R-027 | 加载失败保留当前状态 | GUI transactional restore | 模块错误测试 | 失败回滚人工测试 |
| R-028 | 保存参考来源和仪器元数据 | session metadata/provenance | provenance round-trip | 保存对话框 |
| R-029 | 将中央图复制为可编辑 figure | `openSelectedTabFigures` | GUI 初始化 | OPEN FIG |
| R-030 | 保持稳定基线可恢复 | Git tags/releases | GitHub commit/tag 核验 | 发布验收 |

## 2. 测试集合

| 测试类 | 主要覆盖 |
|---|---|
| `TestPeakAnalysis` | 峰参数、基线、截断窗、非法坐标和论文回归 |
| `TestCalibrationModules` | 多项式拟合、残差、LOO、身份排序和非法输入 |
| `TestSpectrumPreprocessingModules` | 实测文件、暗光谱、预处理和归一化 |
| `TestCalibratedPerformanceModule` | 波长域宽度、非线性换算和像素间隔 |
| `TestSessionModules` | 会话结构、往返、像素模式和错误文件 |
| `TestWcc4smDataAssets` | 测量/暗数据、NIST 主库和选择模式一致性 |

## 3. 发布准入

稳定发布要求：

1. MATLAB 静态解析无语法错误。
2. 37 项非 GUI 测试全部 Passed，无 Failed/Incomplete。
3. GUI 主窗口初始化通过。
4. 当前版本 GUI 验收步骤完成。
5. 模型导出和会话恢复由操作者验证。
6. GitHub PR 合并，主分支、标签和 Release 指向一致提交。

## 4. 尚未自动化的领域

- 文件选择和保存对话框。
- 谱峰逐项人工审核。
- 参考线物理正确性判断。
- GUI 图形视觉一致性。
- 子窗虚线拖动/更新体验。
- 失败加载后的完整界面视觉回滚。

这些项目必须保留人工验收，直到建立可靠的 MATLAB UI 自动化测试。
