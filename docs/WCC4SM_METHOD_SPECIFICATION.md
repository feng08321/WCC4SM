# WCC4SM_METHOD_SPECIFICATION — 算法方法数学定义基线

版本：V1.0（基线）　对应代码：WCC4SM V1.1（2026-09-15）

> 本文是 WCC4SM 技术文档基线四件套之二（方法规范），汇总全部算法的**数学定义、
> 源码依据与默认参数**。更详细的分节推导（含"特别注意"条目）见
> `WCC4SM_V0.9.3_波长定标算法数学定义说明_V1.0.md` 与
> `WCC4SM_V0.9.3_四种峰位计算算法说明_V1.0.md`；冲突时以代码为准。

## 1. 符号约定

| 符号 | 含义 |
|---|---|
| \(p_n\) | 第 n 个定标点的像素坐标（峰位） |
| \(\lambda_n\) | 第 n 条参考谱线的波长（nm） |
| \(m\) | 定标多项式阶次 |
| \(N\) | 定标点数量 |
| \(f^{(m)}\) / \(\hat\lambda(p)\) | 定标模型（像素→波长映射） |
| \(e_n=\lambda_n-\hat\lambda_n\) | 残差（参考 − 预测，全局统一，见 §15） |

## 2. 光谱预处理（`wc4sm_preprocess_spectrum`）

暗谱扣除**优先**于人工基线（与 V0.5.1 行为一致）：

\[
y^{corr}_i=
\begin{cases}
y^{raw}_i-y^{dark}_i,&\text{有暗谱}\\
y^{raw}_i-b_{\text{manual}},&\text{否则}
\end{cases}
\qquad
y^{corr}_i\leftarrow\max(y^{corr}_i,0)
\]

归一化：\(y^{norm}_i=y^{corr}_i/\max(y^{corr})\)（仅当最大值 \(>0\)）。
输入少于 3 个有限点、暗谱长度不匹配均抛错。

## 3. 峰检测（GUI 内联，`findpeaks`）

- 在 `D.normalized` 上执行 `findpeaks`，最小峰高/间距由用户控件给定；
- Min prominence 可设为 `'Adaptive'`：以 `wc4sm_robust_upper_limit`
  估计的稳健上限自动换算；
- 检出峰编号为 `P001, P002, ...`（`P%03d`）。

## 4. HDR 判据（`wc4sm_analyze_peak` 内）

HDR = 峰窗内信号最大值 / 均值。三态语义（用于 `PeakShapeStatus` 与可用性）：

| 状态 | 判据（概念） |
|---|---|
| 推荐窗 | HDR 超过阈值且谷底低于 \(0.5\times\) 推荐窗均值 |
| 需要窗 | 谷底低于均值 |
| 保护窗 | 全部元素高于 HDR 均值 |

HDR 用于识别饱和/削顶风险；饱和峰只允许位置级使用（PositionOnly）。

## 5. 峰位定义（`wc4sm_analyze_peak`）

峰窗 \(i\in[i_c-L,\ i_c+R]\)，\(i_c\) 为最近原始采样点；局部基线为窗端点线性
\(b(x)\)，净信号 \(s_i=y_i-b(x_i)\)；插值网格 \(n_{dense}=(n_w-1)F+1\)。

| 定义 | 缩写 | 公式 |
|---|---|---|
| Direct（原始最大点） | D | \(x_D=x_{\arg\max_i s_i}\) |
| Interpolated（插值最大点） | I | \(x_I=\xi_{\arg\max_j S_j}\) |
| FWHM center（半高中心） | F | \(x_F=(x_{h,L}+x_{h,R})/2\)，半高交点线性求交 |
| Centroid（非负净信号一阶矩） | C | \(x_C=\dfrac{\int xS^+(x)dx}{\int S^+(x)dx}\)，\(S^+=\max(S,0)\)，`trapz` 积分 |
| SlopeStability（斜率稳定点，GUI 第 5 种） | S | 对窗内位置-信号斜率的稳健定位（详见峰位算法说明文档） |

- GUI 默认：\(L=R=5\)，PCHIP，插值因子 \(F=20\)；
- **论文实际参数：±4 pixel（9 原始点）、cubic spline、\(F=20\)**；
- 论文横向比较用 4 种（D/I/F/C）；SlopeStability 是 GUI 扩展，
  差异说明见 `WCC4SM_V0.9.3_四种峰位计算算法说明_V1.0.md`；
- 多峰窗口用相邻实测谷底限制插值搜索，并标记 `PositionOnly`。

## 6. 峰位差拟合（`wc4sm_fit_peak_position_difference`，V1.0）

以 FWHM center 为基准，其余定义与其差值对参考波长作一阶多项式拟合，
用于检验峰位差随波长的线性漂移；残差方向为"观测 − 拟合"，单位 pixel。

## 7. 初始映射（`wc4sm_build_initial_model` + `wc4sm_match_ordered_sequence`）

1. 初始模型：选定锚点后作线性拟合 \(\lambda\approx a\cdot p+b\)
   （模型结构 `{valid,Degree,Coefficients,Mu,a,b}`，求值统一走
   `wc4sm_evaluate_wavelength_model`）；
2. 序列匹配：预测峰位序列与候选参考线做**动态规划单调对齐**——匹配必须
   保持顺序，两侧均允许跳过；容差 `tol` 内才接受匹配；
3. 匹配置信度（GUI 内联，Auto global）：

\[
\text{base}=\max\!\left(0,1-\frac{d}{tol}\right),\qquad
\text{separation}=\min\!\left(1,\max\!\left(0,\frac{d_2-d_1}{tol}\right)\right)
\]

\[
\text{conf}=0.7\,\text{base}+0.3\,\text{separation}
\]

其中 \(d\) 为预测波长与匹配参考线距离，\(d_1,d_2\) 为参考池中最近与
次近距离。分级：`conf ≥ 阈值` → High confidence；`≥ 0.4` → Review；
否则 Low confidence。

## 8. 波长定标多项式（`wc4sm_fit_calibration`）

MATLAB `polyfit` 在**归一化自变量**上拟合：

\[
z_n=\frac{p_n-\mu_1}{\mu_2},\quad
\mu_1=\operatorname{mean}(p),\ \mu_2=\operatorname{std}(p),\quad
\hat\lambda(p)=\sum_{k=0}^{m}c_k z^{m-k}.
\]

- 要求 \(N\ge m+1\)，\(m\le 20\)；GUI 默认 \(m=3\)；
- 展示用自然幂系数由 `wc4sm_poly_normalized_to_natural` 代数换算，
  **高精度重算必须用 `Coefficients+Mu`**；
- `Fit residual`：\(e_{\text{fit},n}=\lambda_n-\hat\lambda_n\)，
  \(\mathrm{RMSE}_{fit}=\sqrt{\frac1N\sum e^2}\)；
- `STD=std(residual)` 为**样本**标准差（分母 \(N-1\)），
  与交叉定义验证的总体标准差不同（§12）。

## 9. LOO 留一验证（`wc4sm_validate_calibration_loo`）

要求 \(N\ge m+2\)。每折删除第 n 点重拟合（**每折重算 \(\mu\)**）：

\[
e_{\mathrm{LOO},n}=\lambda_n-f_{-n}^{(m)}(p_n),\qquad
\mathrm{RMSE}_{LOO}=\sqrt{\tfrac1N\sum e_{\mathrm{LOO},n}^2},\qquad
\mathrm{MAX}_{LOO}=\max_n|e_{\mathrm{LOO},n}|.
\]

同时输出每折删除模型与完整模型在评估像素上的最大曲线变化
（`DeletionMaxCurveChange`）。批量子集搜索可设 `SkipLOO` 跳过。

## 10. Generalization Gap（`wc4sm_analyze_influence_orders`）

带符号差，不取绝对值：

\[
G^{(m)}=\mathrm{RMSE}_{LOO}^{(m)}-\mathrm{RMSE}_{fit}^{(m)}.
\]

Gap 可为零或负；GUI 仅在全为正时用对数纵轴。代码未定义 Gap 阈值或
自动选阶判据。

## 11. Deletion Influence（`wc4sm_analyze_point_influence`，要求 \(N\ge m+3\)）

两种**不同**的删除影响量，不可混称：

| 量 | 定义 | 出现位置 |
|---|---|---|
| \(Q_n=\max_{p_r\in\mathcal P}\lvert f^{(m)}(p_r)-f_{-n}^{(m)}(p_r)\rvert\) | 曲线最大变化（nm），比较网格=完整输入像素 | Model Validation 页 "Max curve change" |
| \(I_n=\dfrac{\lvert R-R_{-n}\rvert}{\max(R,\varepsilon)}\)，\(R=\mathrm{RMSE}_{LOO}(f^{(m)})\) | 无量纲相对 LOO-RMSE 变化 | Point Influence 页 "Influence"、子集设计排序 |

跨阶统计用 \(I_n\)：Mean / RMS / P95（**最近秩次**，不插值）/ MAX。
样本分类阈值：`HighInfluenceFactor=2`，`RedundantFactor=0.25`；
候选异常点判据 \(|e_n|>\max(3R,\ \mathrm{median}|e|+3\,\mathrm{std}|e|)\)。
**未采用**杠杆值、Cook 距离或系数变化定义。

## 12. 峰位交叉定义验证（`wc4sm_cross_validate_peak_positions`，V1.0）

\(X\in\mathbb R^{N\times4}\)：每行一条匹配谱线，每列一种峰位定义（D/I/F/C）。
矩阵方向：**行=Calibration definition，列=Application definition**。

- Full fit：\(e_{ab,n}=\lambda_n-f_a^{(m)}(x_{n,b})\)；
- LOO：删除整条物理谱线的训练行，用其余行重建 \(f_{a,-n}^{(m)}\)（每折重算
  \(\mu\)），再代入该谱线的应用定义位置 \(x_{n,b}\)；
- 样本池：Common intersection（全部定义有限，默认/论文建议）或
  Pairwise available（逐单元格成对，横比时必须同时报告各格 \(N\)）；
- 单元格指标（残差有限值，共 \(K\) 个）：

\[
\mathrm{RMSE}=\sqrt{\tfrac1K\sum e_n^2},\quad
\mathrm{Bias}=\tfrac1K\sum e_n,\quad
\mathrm{STD}=\sqrt{\tfrac1K\sum(e_n-\mathrm{Bias})^2}\ (\text{总体}),
\]

\[
\mathrm{MAX}=\max_n|e_n|,\quad
\mathrm{P95}\ (\text{对 }|e|\text{ 升序，}r=1+0.95(K-1)\text{ 线性插值}),\quad
\mathrm{Slope}:\ e_n=\alpha\lambda_n+\beta\text{ 的 }\alpha.
\]

Slope 表示残差随参考波长的线性漂移（nm/nm），**不是** \(d\lambda/dp\)，
也不是多项式一阶系数；代码只保存斜率。
注意：本模块 STD 为总体（分母 \(K\)），与 §8 的样本 STD（分母 \(N-1\)）不同。

## 13. Compatibility / 模型距离（`wc4sm_model_distance`）

两定标模型在公共网格（默认双方像素范围并集上 200 点）求值：

\[
\mathrm{RMS}=\sqrt{\operatorname{mean}\big(f_A(p)-f_B(p)\big)^2},\qquad
\mathrm{MAX}=\max_p|f_A(p)-f_B(p)|.
\]

GUI 中 Compatibility 判定 = 模型距离不超过给定阈值。

## 14. 子集设计（Set Design）

规则集（`wc4sm_generate_subset_mask`）：Manual / Top-k influence /
Maximin coverage / Locked boundary + coverage / Window influence /
quality / center。Maximin 每步：

\[
n^*=\arg\max_{n\notin S}\ \min_{s\in S}|\lambda_n-\lambda_s|.
\]

分窗（`wc4sm_partition_subset_windows`）：等波宽 / 等累积影响
（累计归一化 Influence 接近 \(j/K\) 的严格递增切点）；窗内推荐为 advisory，
不静默确认。另有 ε-cover 覆盖与分阶段回溯 Beam Search（模型空间逐层删除，
`wc4sm_backward_beam_search` 系列），详见
`WCC4SM_V0.9.3_Set_Design操作与指标说明.md`。

## 15. 定标后性能（`wc4sm_calculate_calibrated_performance`）

对已确认峰结果，将像素域量经定标模型换算到波长域：
中心波长 \(\hat\lambda(x_F)\)、\(\mathrm{FWHM}_{nm}\)、\(\mathrm{ERW}_{nm}\)，
并按波长段统计分辨率指标（Performance 工作区）。

## 16. 残差符号约定（全局）

所有定标/验证/优化/子集/交叉定义模块统一：

\[
\boxed{\ e=\lambda_{\text{reference}}-\lambda_{\text{predicted}}\ }
\]

已逐项审计 V0.9.3 起全部模块，无反向残差。RMSE/STD/P95/MAX 不受符号影响，
Bias、MeanResidual、残差曲线与 Slope 受影响；论文统一声明此方向。
