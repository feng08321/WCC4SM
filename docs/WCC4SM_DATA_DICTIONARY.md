# WCC4SM_DATA_DICTIONARY — 数据字典（状态、字段与编码值）

版本：V1.0（基线）　对应代码：WCC4SM V1.1（2026-09-15）

> 本文是 WCC4SM 技术文档基线四件套之三（数据字典）。全部状态结构由
> `src/wc4sm_empty_*.m` / `wc4sm_make_calibration_pair.m` 单一构造，
> 本文与之一一对应；改字段必须先改工厂并更新本文。

## 1. 核心状态结构（12 个工厂定义）

### 1.1 `wc4sm_empty_data` — 光谱数据 D

| 字段 | 类型 | 含义 |
|---|---|---|
| `raw` | 列向量 | 原始测量谱（AD counts） |
| `dark` | 列向量 | 暗谱 |
| `darkSource` | char | 暗谱来源文件名 |
| `corrected` | 列向量 | 暗谱/基线扣除并截断负值后的谱 |
| `normalized` | 列向量 | 最大值归一化谱（峰检测/显示用） |
| `pixel` | 列向量 | 像素坐标轴（可能非 1..N，见像素坐标规范文档） |
| `inputX` | 列向量 | 输入文件自带的横轴（若有） |
| `inputWavelength` | 列向量 | 输入文件自带的波长轴（若有） |
| `calibratedWavelength` | 列向量 | 应用定标模型后的波长轴 |
| `xKind` | char | 横轴类型标识（`'Pixel'` 等） |
| `source` | char | 数据来源文件名 |
| `PixelCoordinateMode` | char | 像素坐标模式（如 `'Legacy natural pixel sequence'`） |
| `PixelFirst` / `PixelLast` | double | 有效像素范围 |

### 1.2 `wc4sm_empty_reference` — 外部参考谱 R

`x`、`y`（坐标与强度）、`source`、`loaded`。

### 1.3 `wc4sm_empty_line_library` — 线库 L

| 字段 | 含义 |
|---|---|
| `wavelength` | 基态波长（nm） |
| `intensity` | 相对强度 |
| `order` | 衍射级次（缺省 1） |
| `effective` | 有效波长 = `wavelength .* order` |
| `enabled` | 启用掩码 |
| `source` / `loaded` | 来源描述 / 是否已加载 |

### 1.4 `wc4sm_empty_peaks` — 检出峰表 peaks

`ID`（`P%03d`）、`Index`（数据索引）、`Pixel`、`InputX`、`Height`、
`Prominence`、`Width`、`Status`（枚举见 §3）、`Result`（峰分析结果结构）。

### 1.5 `wc4sm_empty_local_candidates` — 局部候选峰

`Index`、`Pixel`、`InputX`、`Height`、`Prominence`、`Width`。

### 1.6 `wc4sm_empty_peak_dataset` — 峰分析数据集 peakDataset

`PeakID`、`PeakIndex`、`Pixel`、`InputX`、`ReferenceWavelength`、`Source`、
`WindowPixel` / `WindowADCounts` / `WindowCorrected`（窗数据）、
`AnalysisResult`、`FindPeakHeight` / `FindPeakProminence` / `FindPeakWidth`
（检测时快照）、`Status`、`Confirmed`、`ConfirmedAt`、`ConfirmedSettings`。

### 1.7 `wc4sm_empty_calibration_pairs` + `wc4sm_make_calibration_pair` — 定标对 calPairs

| 字段 | 含义 |
|---|---|
| `PeakID` / `PeakIndex` / `DetectionPixel` | 关联峰及其检测像素 |
| `ReferenceIndex` / `ReferenceWavelength` | 匹配参考线（0 / NaN 表示未匹配） |
| `Order` | 衍射级次 |
| `Mode` | `'Auto global'`（序列匹配生成）/ `'Manual'`（人工添加） |
| `Confidence` | 匹配置信度 0–1（公式见 METHOD_SPECIFICATION §7；未匹配为 0，人工对为 NaN） |
| `Locked` | 是否锁定（锁定对不参与自动重匹配） |
| `Status` | 枚举见 §3 |

### 1.8 `wc4sm_empty_mapping_candidates` — 初始映射候选

`a`、`b`（线性系数）、`RMS`、`ReferenceIndices`、`ReferenceWavelengths`。

### 1.9 `wc4sm_empty_initial_model` — 初始模型 provisional

`valid`、`Degree`、`Coefficients`、`Mu`（`[0 1]`）、`a`、`b`。

### 1.10 `wc4sm_empty_final_model` — 最终定标模型

`valid`、`PositionMethod`、`Degree`、`Coefficients`、`Mu`、`S`、
`NaturalCoefficients`（仅显示用）、`Equation`、`PeakID`、`Pixel`、
`ReferenceWavelength`、`FittedWavelength`、`Residual`、`MeanResidual`、
`STD`、`RMS`、`MaxAbsResidual`、`LOOResidual`、`DeletionMaxCurveChange`、
`LOORMS`、`LOOMaxAbs`、`MaxDeletionInfluence`。

### 1.11 `wc4sm_empty_calibration_models` — 模型库 calibrationModels

`ModelID`（`M%03d`）、`CreatedAt`、`PairCount`、`PositionMethod`、
`Degree`、`PairIDs`、`Model`、`Visible`。

## 2. ID 与编码规则

| 对象 | 规则 | 示例 |
|---|---|---|
| 峰 | `P%03d`（检出顺序） | `P007` |
| 模型 | `M%03d`（模型库顺序） | `M003` |
| 分窗 | `W%d` | `W3` |
| 子集候选 | `CandidateID` 字符串 + `CoverID`（ε-cover 归属） | — |

## 3. 状态枚举值

**peaks.Status**：`Unreviewed`（未分析）→ `Analyzed - unconfirmed` /
`Position only - unconfirmed`（多峰窗位置级）→ `Confirmed` /
`Confirmed - PositionOnly`；异常分支：`Analysis failed`、`Excluded`
（可逆排除）、`Modified - unconfirmed`（参数改动后失效）。

**peakDataset.Status**：与峰表同步，另有 `MultiPeak - position only`
（多峰结果记录）。

**calPairs.Status**：`Unmatched`（未匹配）/ `High confidence` /
`Review` / `Low confidence`（自动匹配三级，阈值见 METHOD_SPEC §7）/
`Manual locked` / `Locked` / `Unlocked` / `Auto locked`。

**PeakShapeStatus**：`SinglePeak` / `MultiPeak`；可用性 `usability`：
`Full` 等（饱和/多峰降级为 PositionOnly）。

## 4. 文件格式索引

| 格式 | 说明 | 权威文档 |
|---|---|---|
| Session `.mat` | 完整会话快照（FormatVersion 1.0） | `WCC4SM_SESSION_FORMAT_V1.md` |
| 定标模型 | 字段与显示方程约定 | `WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md` |
| 光谱/暗谱 CSV | 单列或 X,Y 两列 | `WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md` |
| 线库 `.lit` | `#` 注释头 + 空白分隔列：`wavelength_nm`、相对强度、可选 `order`（缺省 1）；按 `wavelength×order` 升序 | 本文件与 `wc4sm_load_builtin_library` |
| 像素坐标 | 非 1..N 像素序列规范 | `WCC4SM_PIXEL_COORDINATE_SPEC_V1.md` |

## 5. GUI 闭包变量 → State 五域映射蓝图（技术债 D2，未实施）

现状为 60+ 个独立闭包变量被 ~270 个嵌套回调隐式共享。规划分组：

| 域 | 收编变量（现状名） |
|---|---|
| `State.Data` | `D`、`R`、`L`、`Lbasic`、`Lpaper`、`Lnim`、`Lexternal` |
| `State.Peaks` | `peaks`、`peakDataset`、`localCandidates`、`selectedLocalCandidate`、`localSearchWindow`、`symmetryThresholdPx` |
| `State.Calibration` | `calPairs`、`provisional`、`finalModel`、`appliedModel`、`appliedModelName`、`calibrationModels`、`referenceResolutionNm` |
| `State.Design` | `optimizationPath/Stability/Order`、`influenceResult`、`influenceOrderStats`、`seedComboResult`、`subsetDesignProfile`、`subsetBeamState`、`subsetDesignCandidates`、`subsetWindowPartition`、`windowInfluenceDegree`、`windowSelectedMask`、`positionCrossResult`、`paper*` 系列 |
| `State.UI` | 各 `selected*Row`、`mainAxisMode`、`matchingAxisMode`、`influenceViewMode`、`optimizationViewMode`、`C`（配色）、路径、`sessionMetadata`、`currentSessionPath` 等 |

实施时每域一个批次，独立提交 + 全量回归；字段语义以 §1–§3 为准。
