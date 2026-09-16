# WCC4SM V1.0 测试验证与验收说明 V1.0

> 本文是 WCC4SM **V1.0 软件**的当前正式验收文档，取代
> `WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md`（后者作为历史版本保留）。
> 数学定义以 `docs/WCC4SM_METHOD_SPECIFICATION.md` 为准，测试清单与已知
> 限制以 `docs/WCC4SM_VALIDATION.md` 为准，状态字段以
> `docs/WCC4SM_DATA_DICTIONARY.md` 为准——本文不重复这些定义，只规定
> 验证程序与人工验收项。

## 1. 目的与范围

规定 WCC4SM V1.0 的自动测试、数值一致性检查、GUI 人工验收、Session/导出
验证和发布判定要求。验证分三层：

1. 核心算法自动测试（计算回归，CI 可跑）；
2. 数据一致性与持久化测试（计算回归的一部分）；
3. MATLAB 桌面环境下的 GUI 人工验收（含 GUI 冒烟测试）。

自动测试通过不能替代 GUI 验收，截图正常也不能替代数值测试。

## 2. 测试环境记录

每次正式验收应记录：

- 操作系统与显示缩放比例；屏幕分辨率；
- MATLAB 版本和必要工具箱；
- WCC4SM 版本、代码提交哈希或发行包日期；
- 测试数据文件与 Session 文件；
- 测试人员和日期。

建议至少覆盖一台普通笔记本分辨率设备和一台大屏设备。
注意：GUI 验收必须在**有显示的交互式 MATLAB 会话**进行；GUI 冒烟测试在
无头 batch 环境下于部分机器不稳定（见 VALIDATION §4）。

## 3. 自动测试执行

V1.0 起自动测试分两步，分属两个独立 MATLAB 进程：

```
% 第 1 步：计算回归（任意环境，CI 同此），145 用例
addpath('tools','src'); run_regression();

% 第 2 步：GUI 冒烟（交互式会话，有显示），3 用例
addpath('tools','src'); run_gui_smoke();
```

- 计算回归已由 GitHub Actions CI 在每次 push/PR 到 main 时自动运行
  （R2022a，windows-latest）。本地跑一次作为留档；
- 定位单个测试类：`runtests('tests/TestPeakAnalysis.m')` 等；
- 汇总多个 TestResult 数组时先转列向量 `[r1(:); r2(:)]`，避免 vertcat 维度错误；
- 验收标准：两步都"全部通过、无 Failed/Incomplete"，不在本文固定用例数
  （当前 145 计算 + 3 GUI，见 VALIDATION §2）。

## 4. 自动测试覆盖重点

| 测试领域 | 主要检查 |
|---|---|
| 文件输入 | 支持格式、坐标解析、异常输入 |
| 预处理 | 暗信号、基线、负值处理和数据长度 |
| 峰分析 | 峰位置（D/I/F/C）、宽度、质心、边界与警告 |
| 定标模型 | 多项式拟合、归一化参数、预测、LOO |
| 优化 | Add-One、替换、影响、阶次分析 |
| 子集设计 | 规则生成、评价、距离、cover、Beam |
| Session | 构造、验证、保存/加载、新增字段兼容 |
| GUI 支持 | 控件存在、回调连接、关键文本（源码模式） |
| GUI 冒烟 | 真实启动：窗口、核心控件、干净关闭 |

各套件的详细检查点沿用 V0.9.3 文档 §4.1–§4.3（Set Design、Session、
峰位定义交叉验证），此处不重复。

## 5. 数值一致性验收

沿用 V0.9.3 文档 §5（残差口径一致性、LOO 与闭合残差区分、模型距离、
样本影响），数学定义现以 METHOD_SPECIFICATION 为准。核心判定不变：

1. 同一全池模型：模型比较页 FitRMSE 与全池验证 AllRMSE 仅允许浮点舍入差异；
2. FitRMSE 可小于 LOORMSE，但 m+1 点拟合 m 阶时 FitRMSE 不作唯一结论；
3. 模型与自身 D_RMS=D_MAX=0，交换 A/B 不变，ε-cover 需双阈值同时满足；
4. 样本影响横轴切换不改纵轴数值；RMS influence 无量纲；
   完整阶次扫描上限 N−2，嵌套去一 LOO 影响扫描上限 N−3。

## 6. 标准 GUI 工作流验收

数据加载、预处理、自动寻峰、子窗口补充弱峰、参考线匹配、三阶拟合、
模型比较、残差显示、Add-One/替换/样本影响的验收项，沿用 V0.9.3 文档
§6.1–§6.4，全部仍然有效。以下为 **V1.0 新增/变更** 的验收项。

### 6.1 8×8 峰形画廊（V1.0 新增）

- [ ] 画廊以 8×8 网格展示检出峰子窗口，最多 63 个峰，末格留空；
- [ ] 匹配基准峰为蓝描边、未入选为红描边，黄色填充点线；
- [ ] 每个子图标题含 Peak ID 与中心波长（无应用模型时回退为中心像素）；
- [ ] 无逐轴刻度线，画廊随主图 Pixel/Wavelength 轴状态重绘；
- [ ] 批量分析或模型轴切换后画廊自动刷新；
- [ ] OPEN FIG 打开为单个可编辑 8×8 图，不生成大量独立窗口。

### 6.2 Calibrated Performance 子视图（V1.0 新增）

- [ ] 三序列全检出峰差图（D/I/F/C 中选定口径）正常显示；
- [ ] 匹配基准的 Centroid−FWHM-center 差图可叠加 1–3 阶归一化多项式拟合；
- [ ] 点上点击实现跨子图同步高亮，重复点击取消高亮；
- [ ] 每行可逆排除（Show 复选）后两图同步剔除且不改动定标集；
- [ ] 排除状态在 Session 保存/加载后保留；
- [ ] Export CSV 导出与界面一致；OPEN FIG 正常。

### 6.3 论文峰差工作区增强（V1.0 新增）

- [ ] 右侧双表数据集管理器可增删数据集，状态刷新正确；
- [ ] 临时拟合删除可逆，确认删除定标对需二次确认；
- [ ] 从归档参考配对可安全恢复；
- [ ] 上图三个序列开关独立生效；重复点击清除高亮；
- [ ] 下图可切换 outside-set / calibration / temporary-deletion 视图，
      并显示 ±2、±3 残差 STD 带。

### 6.4 峰位定义交叉验证总览（V1.0 新增三页）

- [ ] All metrics 子页 2×3 同显 RMSE/STD/Bias/P95/MAX/Slope 六热图，选中红框一致；
- [ ] Calibration-row residuals 子页 2×2 显示当前定标行四种应用峰位残差；
- [ ] All histograms 子页 4×4 直方图与热图同方向、统一横轴；
- [ ] 三页 OPEN FIG 各保持一个可编辑阵列图。

其余交叉验证验收项（矩阵方向、单元格联动、Full/LOO、两种样本池、
训练集来源、NTrain/NEval 口径、六指标一致性、低分辨率布局）沿用
V0.9.3 文档 §6.5。

### 6.5 第 5 种峰位定义 Gaussian fit（V1.0）

- [ ] Gaussian fit 作为第 5 种峰位定义可在 GUI 选择并正常计算；
- [ ] 拟合失败或 PositionOnly 峰返回 NaN 并被明确标记，不静默报错；
- [ ] Gaussian fit **不**纳入论文 4 定义（D/I/F/C）交叉验证 4×4 矩阵
      （设计如此，见 VALIDATION §4 与 E2 说明）。

## 7. Set Design GUI 验收

沿用 V0.9.3 文档 §7（页面可见性、手动与规则子集、Window Partition、
分阶段 Beam、参数解释），全部仍然有效。

## 8. Session 验收

沿用 V0.9.3 文档 §8，并补充 V1.0 项：

- [ ] 8×8 画廊状态、Calibrated Performance 排除状态可保存并恢复；
- [ ] 论文峰差工作区的数据集管理器内容、临时删除状态可保存并恢复；
- [ ] 交叉验证三总览页的显示选择可保存并恢复；
- [ ] 旧版 Session（缺 V1.0 新增字段）加载不报错，新增字段取空/默认。

## 9. 导出验收

沿用 V0.9.3 文档 §9（模型 MAT、Set Design CSV、交叉验证 CSV），并补充：

- [ ] Calibrated Performance 的 Export CSV 可复现界面数值；
- [ ] 论文峰差工作区导出包含数据集标识与排除标记。

## 10. 静态检查

代码交付前执行：

```
git diff --check
tools/check_src_code_quality.m    % src 模块 checkcode 零告警门禁（C3 起）
```

并搜索：未解决的合并标记、临时调试输出、过时术语、文档引用的文件名是否
实际存在。静态检查不运行 MATLAB，但能提前发现空白、拼接和引用问题。

## 11. 缺陷分级

- 阻断：程序无法启动、Session 破坏、模型结果错误、核心流程无法继续；
- 严重：指标口径不一致、候选成员错误、导出不可复现、主要按钮不可见；
- 一般：局部刷新、选择强化残留、文字不清或需要规避操作；
- 建议：布局、配色、帮助和效率改进，不影响正确结果。

阻断和严重缺陷未关闭时不得作为正式版本发布。

## 12. 发布验收条件

正式发布至少满足：

- 计算回归（CI 与本地）全部通过；
- GUI 冒烟测试在交互会话通过；
- 37 点完整模型的残差口径一致性通过；
- 标准 GUI 工作流（含 V1.0 新增 §6.1–§6.5）通过；
- 普通窗口下 Set Design 核心按钮可见；
- 分阶段 Beam、Session 中断恢复、Set Design 导出通过；
- 交叉验证矩阵、单元格残差、两种验证方式和两种样本池通过；
- 基线四文档（架构/方法/数据字典/验证）与本文已同步；
- CHANGELOG 记录本版功能与兼容性变化。

## 13. 验收记录模板

| 项目 | 结果 | 证据/备注 |
|---|---|---|
| 计算回归（CI/本地） | Pass/Fail | CI 运行链接或 MATLAB 输出 |
| GUI 冒烟 | Pass/Fail | run_gui_smoke 输出 |
| 数值一致性 | Pass/Fail | 模型 ID、指标截图/导出 |
| 标准 GUI 流程 | Pass/Fail | 数据文件和问题记录 |
| V1.0 新增功能（画廊/Calibrated Performance/峰差/总览/Gaussian） | Pass/Fail | 截图/CSV |
| 交叉验证 | Pass/Fail | 模式、样本池、矩阵和残差截图/CSV |
| Set Design | Pass/Fail | K、参数、候选 ID |
| Session 恢复 | Pass/Fail | Session 文件名 |
| 导出复现 | Pass/Fail | 导出目录与核对结果 |
| 低分辨率布局 | Pass/Fail | 分辨率和截图 |
| 已知问题 | None/List | 缺陷编号与级别 |
| 最终结论 | Accept/Reject | 验收人、日期 |

## 14. 相关文档

- `docs/WCC4SM_ARCHITECTURE.md` —— 架构、模块、数据流
- `docs/WCC4SM_METHOD_SPECIFICATION.md` —— 数学定义
- `docs/WCC4SM_DATA_DICTIONARY.md` —— 状态字段与枚举
- `docs/WCC4SM_VALIDATION.md` —— 测试清单、基准、已知限制
- `docs/TESTING.md`、`docs/V0_9_2_GUI_TEST.md` —— 早期测试记录
- `WCC4SM_V0.9.3_测试验证与验收说明_V1.0.md` —— 历史版本（沿用项来源）
