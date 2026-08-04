# WCC4SM 输入输出数据格式规范

文档版本：V1.0

适用软件：WCC4SM V0.6.2

日期：2026-08-04

## 1. 通用约定

- 文本数值使用 MATLAB `readmatrix`/`writetable` 可解析格式。
- 坐标和信号必须为有限数值。
- 坐标必须严格递增。
- 波长单位为 nm，像素宽度单位为 pixel，信号通常为 AD counts。
- 文件可包含设备文本头；数值区必须能够被 `readmatrix` 识别。
- 输入文件不应依赖历史计算机中的绝对路径。

## 2. 测量光谱

### 2.1 单列格式

```text
intensity
123
127
...
```

单列被解释为强度。V0.6.2 为样本建立从 1 开始的像素序列。

### 2.2 两列像素—强度格式

```text
pixel,intensity
1,123
2,127
...
```

加载前将 `Two-column X` 设为 `Pixel index`。第一列用于输入坐标记录；定标
计算使用软件建立的一基数据序列及所选 Pixel sequence 语义。

### 2.3 两列波长—强度格式

```text
wavelength_nm,intensity
285.34,123
285.76,127
...
```

加载前将 `Two-column X` 设为 `Wavelength (nm)`。输入波长用于显示和记录，
重新定标仍使用明确的像素序列。

### 2.4 光谱内部字段

主要字段包括：

- `raw`
- `dark`, `darkSource`
- `corrected`, `normalized`
- `pixel`
- `inputX`, `inputWavelength`, `xKind`
- `calibratedWavelength`
- `source`
- `PixelCoordinateMode`, `PixelFirst`, `PixelLast`

## 3. 暗光谱

暗光谱支持与测量光谱相同的一列或两列数值形式。要求：

- 有效样本数相同。
- 两列格式的坐标与测量光谱一致。
- 信号有限。

暗光谱不满足对齐条件时必须拒绝，不执行截断、插值或静默补齐。

## 4. 参考谱线主库

支持 `.lit`、`.txt`、`.csv`。数值列含义：

```text
wavelength_nm [, intensity [, order]]
```

- wavelength：必需。
- intensity：可选，缺省时用于显示的权重能力有限。
- order：可选，缺省为 1。

有效参考波长按 `wavelength × order` 参与级次相关匹配。主库来源、权威机构、
空气/真空介质和版本应在会话溯源信息中记录。

## 5. 参考线选择模式 CSV

随软件发布的参考主库、选择模式和对应元数据位于 `reference_data/`，示例参考库
位于 `reference_data/examples/`。选择模式中的 `MasterSource` 使用主库文件名，
不保存机器相关的绝对路径。

导出列：

```text
LineID,Wavelength_nm,Order,MasterSource
```

选择模式表示主库中当前使用的子集，不应被视为独立权威参考库。
`MasterSource` 是溯源文本，不能作为程序寻找主库的绝对路径。

## 6. 峰数据导出

### 6.1 MAT

包含：

- `PeakDataset`
- `Spectrum`

PeakDataset 保存峰 ID、源索引、检测像素、峰位置与宽度参数、确认状态、确认
时间和确认设置。

### 6.2 CSV

用于表格审查，包含峰 ID、像素、参考波长、FWHM、ERW 和状态等摘要。
MAT 是完整结构记录，CSV 是交换和审查视图。

## 7. 初始定标导出

MAT 包含：

- `CalibrationPairs`
- `InitialCalibration`
- `FinalCalibration`
- `CalibrationModels`
- `ReferenceLines`
- `PeakDataset`
- `Spectrum`

配套 CSV 是当前配对表，包含 PeakID、DetectionPixel、ReferenceWavelength、
Order、Mode、Confidence、Locked、Status 和 InitialResidual。

## 8. 最终模型导出

最终模型使用相同文件名前缀生成三种文件。

### 8.1 模型 MAT

包含：

- `CalibrationModel`
- `CalibrationPairs`
- `ReferenceLines`

CalibrationModel 的重要字段：

- `valid`, `PositionMethod`, `Degree`
- `Coefficients`, `Mu`, `NaturalCoefficients`, `Equation`
- `PeakID`, `Pixel`, `ReferenceWavelength`, `FittedWavelength`
- `Residual`, `MeanResidual`, `STD`, `RMS`, `MaxAbsResidual`
- `LOOResidual`, `LOORMS`, `LOOMaxAbs`
- `DeletionMaxCurveChange`, `MaxDeletionInfluence`
- `PixelCoordinateMode`
- `PixelFirst`, `PixelLast`, `PixelCount`
- `CalibrationPixelFirst`, `CalibrationPixelLast`

### 8.2 方程 TXT

必须包含：

- Pixel coordinate mode
- Data pixel domain
- Calibration pixel domain
- 自然像素方程
- 峰位置方法、阶数和点数
- 拟合/LOO/删除影响统计
- 归一化系数、`mu` 和自然像素系数

### 8.3 残差 CSV

列：

```text
PixelMode
DataPixelDomain
CalibrationPixelDomain
PeakID
Pixel
Reference_nm
Fitted_nm
Residual_nm
LOO_residual_nm
Deletion_max_curve_change_nm
```

像素模式和域在每行重复，使 CSV 脱离 MAT 后仍可独立解释。

## 9. 会话 MAT

只允许一个顶层变量：

```text
WCC4SMSession
```

顶层包含应用标识、格式/软件版本、时间戳、Metadata 和 State。State 包括光谱、
峰、参考线、配对、模型和 UI 设置。详细结构和兼容规则见
`docs/WCC4SM_SESSION_FORMAT_V1.md`。

## 10. 隐私和版本控制

会话、模型和原始设备文件可能包含：

- 操作者名称
- 仪器编号和型号
- 测量时间
- 本地路径
- 实验数据

这些文件默认不应提交公开仓库。项目 `.gitignore` 排除 `result/` 和会话输出，
但用户仍需检查其他自定义文件。

## 11. 格式错误处理原则

- 不静默重排非单调坐标。
- 不静默改变像素模式。
- 不自动裁剪长度不一致的暗光谱。
- 不把无关 MAT 当作会话或模型。
- 不因缺少推荐溯源信息破坏可用研究会话，但必须产生警告。
- 结构不一致、无效系数和不支持的主版本必须报错。
