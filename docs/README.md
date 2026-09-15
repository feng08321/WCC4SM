# WCC4SM 文档索引

Markdown 是评审、维护和版本追踪的权威源文件。DOCX/PDF 是按发布需要生成的交付副本。

## V1.0 技术文档基线（Technical Documentation Baseline）

当前软件状态的权威查阅基准，四件套相互引用、与代码同步维护：

| 文档 | 内容 |
|---|---|
| `WCC4SM_ARCHITECTURE.md` | 软件架构、67 个 src 模块地图和数据流 |
| `WCC4SM_METHOD_SPECIFICATION.md` | HDR、Peak D/I/F/C、Calibration、LOO、Gap、Influence、Compatibility 等数学定义 |
| `WCC4SM_DATA_DICTIONARY.md` | 状态结构字段、Peak ID、样本状态枚举、Reference line、Model 字段含义 |
| `WCC4SM_VALIDATION.md` | 145 个测试的验证内容、算法基准案例、已知限制 |

## V1.0 论文服务定版

- `WCC4SM_V1.0_论文服务定版说明.md`：V1.0 启动入口、8×8峰形总览和定版验收说明。

V1.0 延续下列 V0.9.3 算法与操作手册；除 V1.0 定版说明明确列出的界面扩展外，算法定义不因版本号升级而改变。

## V0.9.3 算法与工作流权威文档

建议按下列顺序使用：

| 顺序 | 文档 | 适用对象与用途 |
|---|---|---|
| 1 | WCC4SM_V0.9.3_用户操作与完整工作流程说明_V1.0.md | 操作人员；从导入光谱到峰位交叉验证、模型与子样本设计的完整流程 |
| 2 | WCC4SM_V0.9.3_数据处理算法与统一指标说明_V1.0.md | 数据分析与评审人员；算法公式、残差、峰位失配和结果解释 |
| 3 | WCC4SM_V0.9.3_软件架构与核心模块说明_V1.0.md | 维护与二次开发人员；状态、模块、Session 和导出 |
| 4 | WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md | 测试与发布人员；自动测试、GUI 验收和发布条件 |

专题文档：

- WCC4SM_V0.9.3_波长定标算法数学定义说明_V1.0.md
- WCC4SM_V0.9.3_四种峰位计算算法说明_V1.0.md
- WCC4SM_V0.9.3_Set_Design操作与指标说明.md
- WCC4SM_V0.9.3_发布检查清单.md
- WCC4SM_WINDOWS_EXE_BUILD_V1.md

`WCC4SM_V0.9.2_波长定标优化与可信性自验证功能扩展实施说明_v2.0.md`
保留为功能演进和设计决策记录，不作为 V0.9.3 当前操作依据。

## V0.9 历史基线

以下文档用于追溯 V0.9 架构和发布状态，不代表 V0.9.3 的全部功能：

- WCC4SM_V0.9_软件架构与功能技术说明书_V1.0.md
- WCC4SM_V0.9_软件使用说明书_V1.1.md
- V0_9_PUBLIC_RELEASE_AUDIT.md
- WCC4SM_V0_9_REQUIREMENTS_TRACEABILITY_MATRIX.md
- WCC4SM_V0_9_ACCEPTANCE_REPORT.md

## 支撑规范

- WCC4SM_INPUT_OUTPUT_DATA_FORMATS_V1.md
- WCC4SM_PIXEL_COORDINATE_SPEC_V1.md
- WCC4SM_CALIBRATION_MODEL_FORMAT_V1.md
- WCC4SM_SESSION_FORMAT_V1.md
- WCC4SM_Reference_Data_Model_V0_2F.txt
- TESTING.md
- V0_9_GUI_TEST.md
- V0_9_2_GUI_TEST.md

当支撑规范与 V0.9.3 当前权威文档存在功能覆盖范围差异时，以代码、自动测试和 V0.9.3 文档的共同结论为准，并在下一次规范修订中同步。

## 建议阅读路径

### 新用户

先阅读“用户操作与完整工作流程说明”的标准流程，仅完成峰分析、参考线匹配、三阶拟合和模型保存。熟悉基础流程后，再进入样本影响和 Set Design。

### 数据分析人员

先阅读“数据处理算法与统一指标说明”，特别是 Fit、LOO、All-point 的区别，再使用阶次分析、样本影响、Add-One、逐一替换和子集模型比较。

### 开发维护人员

结合“软件架构与核心模块说明”和 tests 目录修改代码。任何新增计算功能都应同步考虑核心函数、测试、Session、导出、GUI 和四类文档。

## DOCX/PDF 交付

若安装 MATLAB Report Generator，可从项目根目录调用 tools 中的 Markdown 转换脚本生成 DOCX。生成副本后应核对中文字体、表格、公式块、分页和文件链接。

应用当前 Help 窗口列出 docs 下可打开的 PDF；Markdown 是仓库中的权威维护源。若要让 V0.9.3 新手册直接出现在 Help 中，应在发布前生成对应 PDF。原生 Markdown 阅读属于后续界面增强，不作为本次版本冻结条件。

第三方 PDF 仅在许可允许时随软件分发。WCC4SM 的 Apache License 2.0 不会自动重新许可第三方资料。

## 培训材料

正式说明书是术语、文件格式和功能边界的受控依据。面向普通操作人员，可另制作基于真实数据的分步视频或图文教程，但内容不得与已验收的软件版本和本文档体系冲突。
