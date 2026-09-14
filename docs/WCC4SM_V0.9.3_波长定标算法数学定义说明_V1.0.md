# WCC4SM V0.9.3 波长定标算法数学定义说明 V1.0

## 1. 文档范围、符号和源码依据

本文面向论文 Methods 章节，逐项还原 WCC4SM V0.9.3 当前源代码中的数学定义，不以一般理论补充代码中不存在的算法。

主要源码：

- `src/wc4sm_fit_calibration.m`：多项式拟合与 Fit 指标；
- `src/wc4sm_validate_calibration_loo.m`：标准 LOO 与删除曲线变化；
- `src/wc4sm_analyze_model_order.m`：模型阶次扫描；
- `src/wc4sm_analyze_point_influence.m`：逐点删除影响；
- `src/wc4sm_analyze_influence_orders.m`：多阶影响统计；
- `src/wc4sm_analyze_peak.m`：四种非参数峰位；
- `src/wc4sm_cross_validate_peak_positions.m`：峰位定义交叉验证；
- `src/wc4sm_generate_subset_mask.m`、`src/wc4sm_partition_subset_windows.m`、`src/wc4sm_recommend_window_samples.m`：规则选点、分窗和推荐；
- `WCC4SM_V0_9_3.m`：GUI 参数、数据组装及上述函数的调用。

统一符号：

- \(N\)：样本数；
- \(m\)：多项式阶次；
- \(p_n\)：第 \(n\) 个定标峰位坐标，通常为像素；
- \(\lambda_n\)：第 \(n\) 条谱线的参考波长，单位 nm；
- \(\hat\lambda_n\)：模型预测波长；
- 所有波长定标残差均采用 \(e_n=\lambda_n-\hat\lambda_n\)。

---

## 2. Polynomial calibration fitting

### ① 源代码文件/函数

- `src/wc4sm_fit_calibration.m`：`wc4sm_fit_calibration`
- 自然幂系数转换：同文件局部函数 `normalizedToNaturalPolynomial`
- 阶次扫描：`src/wc4sm_analyze_model_order.m`

### ② 输入

`wc4sm_fit_calibration(pixel,wavelength,degree,evaluationPixels,positionMethod,peakIDs,options)`：

- `pixel`：定标自变量 \(p_n\)；
- `wavelength`：参考波长 \(\lambda_n\)；
- `degree`：多项式阶次 \(m\)；
- `evaluationPixels`：供删除曲线变化比较使用的坐标；为空时取训练 `pixel`；
- `positionMethod`、`peakIDs`：峰位定义和样本标识；
- `options.SkipLOO`：批量搜索时可跳过 LOO。

输入点先按 `pixel` 升序排序，参考波长和 Peak ID 同步重排。像素必须有限且互不重复。

### ③ 处理步骤

1. 检查样本数满足 \(N\ge m+1\)，且 \(m\le20\)。
2. 调用

   `[coefficients,S,mu] = polyfit(pixel,wavelength,degree)`

3. 使用同一组归一化参数预测训练点：

   `fitted = polyval(coefficients,pixel,[],mu)`

4. 计算参考值减预测值的 Fit residual。
5. 若 \(N\ge m+2\) 且未设置 `SkipLOO`，调用标准 LOO。
6. 将归一化变量上的系数换算为原始像素自然幂系数，仅用于方程显示；实际预测仍使用 `coefficients` 和 `mu`。

### ④ 数学公式

MATLAB `polyfit` 返回

\[
z_n=\frac{p_n-\mu_1}{\mu_2},
\]

其中 \(\mu_1=\operatorname{mean}(p)\)，\(\mu_2=\operatorname{std}(p)\)。代码实际拟合

\[
\hat\lambda(p)=c_0z^m+c_1z^{m-1}+\cdots+c_m.
\]

计算调用为

\[
\hat\lambda_n=\operatorname{polyval}(\mathbf c,p_n,[],\boldsymbol\mu).
\]

Fit residual：

\[
e_{\mathrm{fit},n}=\lambda_n-\hat\lambda_n.
\]

Fit RMSE：

\[
\mathrm{RMSE}_{\mathrm{fit}}
=\sqrt{\frac{1}{N}\sum_{n=1}^{N}e_{\mathrm{fit},n}^{2}}.
\]

### ⑤ 输出指标

`FittedWavelength`、`Residual`、`MeanResidual`、`STD`、`RMS`、`MaxAbsResidual`、`Coefficients`、`Mu`、`NaturalCoefficients`、`LOOResidual`、`LOORMS`、`LOOMaxAbs` 和 `DeletionMaxCurveChange`。

这里 `STD=std(residual)` 使用 MATLAB 默认样本标准差，即分母为 \(N-1\)；这与交叉定义验证中的总体标准差定义不同。

### ⑥ 默认参数

- 核心函数允许 \(m=0\ldots20\)；
- GUI 的最终定标、优化、影响和交叉验证阶次控件为 \(m=1\ldots20\)，默认 \(m=3\)；
- 阶次扫描默认 \(1\ldots10\)；
- `evaluationPixels` 为空时取训练像素；
- 默认执行 LOO。

### ⑦ 论文当前实际参数

- 论文当前采用的多项式阶次应由实际运行记录填写；若采用当前讨论结论，则为 \(m=3\)。
- 峰窗 ±4 pixel 和 cubic spline 属于峰位提取参数，见第 6 节，不改变本节 `polyfit/polyval` 的实现。

### ⑧ 特别注意

- 代码确实使用中心化和尺度归一化，不是直接在原始大像素值上求自然幂系数。
- 展示方程的自然幂系数由归一化多项式代数换算得到；不能拿显示时的舍入字符串代替 `Coefficients+Mu` 做高精度重算。
- `S` 被保存，但当前代码没有从 `S` 计算系数置信区间。

---

## 3. Leave-One-Out validation

### ① 源代码文件/函数

- `src/wc4sm_validate_calibration_loo.m`：`wc4sm_validate_calibration_loo`
- 调用入口：`src/wc4sm_fit_calibration.m`

### ② 输入

完整训练集 \(\{(p_n,\lambda_n)\}_{n=1}^{N}\)、阶次 \(m\)、完整模型系数与归一化参数，以及 `evaluationPixels`。

### ③ 处理步骤

对每个 \(n=1,\ldots,N\)：

1. 删除第 \(n\) 个样本；
2. 对其余 \(N-1\) 点重新调用 `polyfit`，每一折都重新得到自己的 \(\mathbf c_{-n}\) 和 \(\boldsymbol\mu_{-n}\)；
3. 在被删除点的原峰位 \(p_n\) 上调用 `polyval(c,p_n,[],mu)`；
4. 以参考波长减预测波长得到该点 LOO residual；
5. 另在全部 `evaluationPixels` 上比较完整模型与该删除模型的曲线。

LOO 至少要求 \(N\ge m+2\)。

### ④ 数学公式

令由除第 \(n\) 点外的数据拟合的模型为 \(f_{-n}^{(m)}\)，则

\[
e_{\mathrm{LOO},n}
=\lambda_n-f_{-n}^{(m)}(p_n).
\]

\[
\mathrm{RMSE}_{\mathrm{LOO}}
=\sqrt{\frac{1}{N}\sum_{n=1}^{N}e_{\mathrm{LOO},n}^{2}}.
\]

同时：

\[
\mathrm{MAX}_{\mathrm{LOO}}=\max_n|e_{\mathrm{LOO},n}|.
\]

### ⑤ 输出指标

`LOOResidual`、`LOORMS`、`LOOMaxAbs`、每次删除的 `DeletionMaxCurveChange` 和其最大值 `MaxDeletionInfluence`。

### ⑥ 默认参数

正常定标默认执行 LOO；仅当 `SkipLOO=true` 的批量子集搜索明确要求时跳过。

### ⑦ 论文当前实际参数

LOO 使用与相应定标模型相同的阶次和峰位定义。若论文模型为三阶，则每折均重新拟合三阶模型。

### ⑧ 特别注意

- 每折的中心化参数 \(\mu_{-n}\) 都重新计算，不复用完整模型的 \(\mu\)。
- 标准 LOO 只预测被删除的训练样本，不是用独立外部数据集验证。
- 子集交叉定义 LOO 的评估范围还有额外限制，见第 8 节。

---

## 4. Generalization Gap

### ① 源代码文件/函数

`src/wc4sm_analyze_influence_orders.m`：`wc4sm_analyze_influence_orders`

### ② 输入

同一阶次下的 Fit RMSE 和 LOO RMSE。

### ③ 处理步骤

代码直接作带符号减法，不取绝对值，也不作比值归一化。

### ④ 数学公式

完整样本模型：

\[
G_{\mathrm{full}}^{(m)}
=\mathrm{RMSE}_{\mathrm{LOO}}^{(m)}
-\mathrm{RMSE}_{\mathrm{fit}}^{(m)}.
\]

逐点删除模型池：

\[
G_{\mathrm{del}}^{(m)}
=\mathrm{RMSE}_{\mathrm{del,LOO}}^{(m)}
-\mathrm{RMSE}_{\mathrm{del,fit}}^{(m)}.
\]

结论：当前代码的 Generalization Gap 确实是 `LOO RMSE - Fit RMSE`。

### ⑤ 输出指标

`FullGeneralizationGap`、`DeletionGeneralizationGap`，单位 nm。

### ⑥ 默认参数

影响阶次扫描默认 \(m=1\ldots10\)。

### ⑦ 论文当前实际参数

论文若报告三阶模型，应引用 \(G_{\mathrm{full}}^{(3)}\)；若展示阶次选择，则按实际扫描范围报告。

### ⑧ 特别注意

Gap 可以为零或负数。GUI 只有在所有 Gap 均为正时使用对数纵轴，否则自动使用保留符号的线性纵轴。代码未定义 Gap 阈值或自动最优阶次判据。

---

## 5. Deletion Influence

### ① 源代码文件/函数

- `src/wc4sm_analyze_point_influence.m`
- `src/wc4sm_analyze_influence_orders.m`
- 标准 LOO 中的曲线变化：`src/wc4sm_validate_calibration_loo.m`

### ② 输入

完整定标点 \((p_n,\lambda_n)\)、阶次 \(m\)。点影响函数要求 \(N\ge m+3\)，从而删除一个点后的 \(N-1\) 点模型仍能执行内部 LOO。

### ③ 处理步骤

1. 用全部 \(N\) 点拟合完整模型 \(f^{(m)}\)，并得到其 \(\mathrm{RMSE}_{\mathrm{LOO}}\)。
2. 对每个样本 \(n\)，删除它，用剩余 \(N-1\) 点拟合模型 \(f_{-n}^{(m)}\)。
3. 删除模型的 `evaluationPixels` 明确传入完整输入像素向量 \((p_1,\ldots,p_N)\)。
4. 计算两种不同的删除量：
   - `CurveChange`：完整曲线与删除曲线在完整输入像素向量上的最大绝对差；
   - `InfluenceRatio`：完整模型 LOO RMSE 与删除模型内部 LOO RMSE 的相对变化。
5. 多阶统计使用所有有限的 `InfluenceRatio`，而不是使用 `CurveChange`。

源码还计算

`deleted = wavelength - polyval(deletedModel,...)`

即删除模型在完整点池上的残差向量，但该局部变量当前没有写入结果，也没有参与 `InfluenceRatio`。

### ④ 数学公式

比较网格就是完整输入像素 \(\mathcal P=\{p_r\}_{r=1}^{N}\)，不是连续波长网格：

\[
Q_n
=\max_{p_r\in\mathcal P}
\left|f^{(m)}(p_r)-f_{-n}^{(m)}(p_r)\right|.
\]

代码字段为 `CurveChange`，单位 nm。

令

\[
R=\mathrm{RMSE}_{\mathrm{LOO}}(f^{(m)}),\qquad
R_{-n}=\mathrm{RMSE}_{\mathrm{LOO}}(f_{-n}^{(m)}),
\]

则 GUI 中的单点 Deletion Influence 为

\[
I_n
=\frac{|R-R_{-n}|}{\max(R,\varepsilon_{mach})}.
\]

它是无量纲相对 LOO-RMSE 变化，不是 \(Q_n\)。

对该阶次全部有限 \(I_n\)，设数量为 \(K\)：

\[
\overline I=\frac{1}{K}\sum_{n=1}^{K}I_n,
\]

\[
I_{\mathrm{RMS}}
=\sqrt{\frac{1}{K}\sum_{n=1}^{K}I_n^2},
\]

\[
I_{\mathrm{MAX}}=\max_n I_n.
\]

P95 的实际实现为先升序排列，再取

\[
I_{\mathrm{P95}}=I_{(\lceil0.95K\rceil)}.
\]

此处不做分位点线性插值。

删除模型池的 RMSE 汇总为

\[
\mathrm{RMSE}_{\mathrm{del,fit}}
=\sqrt{\frac{1}{N}\sum_{n=1}^{N}
\left(\mathrm{RMSE}_{\mathrm{fit},-n}\right)^2},
\]

\[
\mathrm{RMSE}_{\mathrm{del,LOO}}
=\sqrt{\frac{1}{N}\sum_{n=1}^{N}
\left(\mathrm{RMSE}_{\mathrm{LOO},-n}\right)^2}.
\]

### ⑤ 输出指标

逐点输出：`Residual`、`DeletedRMS`、`DeletedLOORMSE`、`CurveChange`、`InfluenceRatio`、分类与建议。跨阶次输出 Mean/RMS/P95/MAX Influence、完整与删除池 Fit/LOO RMSE 和两种 Gap。

### ⑥ 默认参数

- 默认阶次 \(m=3\)，扫描上限默认 10，统一允许上限 20；
- `HighInfluenceFactor=2`；
- `RedundantFactor=0.25`；
- 候选异常点条件：

\[
|e_n|>\max\left(3R,\operatorname{median}(|e|)
+3\operatorname{std}(|e|)\right).
\]

### ⑦ 论文当前实际参数

若论文以三阶完整样本模型分析稳定性，应报告 \(m=3\) 的 \(I_n\) 和/或 \(Q_n\)，并明确二者名称和单位；不能统称为同一个 Influence。

### ⑧ 特别注意

- Model Validation 页中的 “Max curve change” 对应 \(Q_n\)；
- Point Influence 页表格中的 “Influence” 对应 \(I_n\)；
- `DeletedRMS` 是删除后模型在其剩余训练点上的 Fit RMSE；
- `DeletedLOORMSE` 是删除后样本池内部再次 LOO 的 RMSE；
- 代码未将 Influence 定义为杠杆值、Cook's distance 或系数变化。

---

## 6. 四种 Peak Position

### ① 源代码文件/函数

- 核心：`src/wc4sm_analyze_peak.m`
- GUI 调用及多峰限制：`WCC4SM_V0_9_3.m` 中 `analyzeSelected`、`analyzeAll`、`classifyPeakWindow`

### ② 输入

严格递增坐标 \(x_i\)、预处理信号 \(y_i\)、近似峰位、左右窗口点数、插值方法、插值因子和局部基线模式。

### ③ 处理步骤

1. 找到距离近似峰位最近的原始采样点 \(i_c\)。
2. 截取 \([i_c-L,i_c+R]\) 并限制在数据边界内。
3. GUI 在已经去除全局人工基线的 `D.corrected` 上，再使用峰窗两端点形成局部线性基线。
4. 对原始强度插值；局部基线始终线性插值。
5. 分别计算原始最大点、插值最大点、半高交点中心和非负净信号一阶矩。

### ④ 数学公式

窗口：

\[
i_L=\max(1,i_c-L),\qquad i_R=\min(N,i_c+R).
\]

线性局部基线与净信号：

\[
b(x)=y_L+(y_R-y_L)\frac{x-x_L}{x_R-x_L},
\qquad s_i=y_i-b(x_i).
\]

若窗口含 \(n_w\) 个原始点，插值因子为 \(F\)：

\[
n_{dense}=(n_w-1)F+1,
\qquad S_j=Y(\xi_j)-b(\xi_j).
\]

直接峰位：

\[
x_D=x_{\arg\max_i s_i}.
\]

插值峰位：

\[
x_I=\xi_{\arg\max_j S_j}.
\]

半高值 \(h=\max(S)/2\)。包围半高值的两个相邻点之间采用线性求交：

\[
x_h=x_1+(h-z_1)\frac{x_2-x_1}{z_2-z_1}.
\]

得到左右交点后：

\[
x_F=\frac{x_{h,L}+x_{h,R}}{2},
\qquad \mathrm{FWHM}=x_{h,R}-x_{h,L}.
\]

质心先截去负净信号：

\[
S_j^+=\max(S_j,0),
\]

再由 `trapz` 在加密网格积分：

\[
x_C=
\frac{\int_{x_L}^{x_R}xS^+(x)\,dx}
{\int_{x_L}^{x_R}S^+(x)\,dx}.
\]

### ⑤ 输出指标

`DirectPeakX`、`InterpolatedPeakX`、`CenterX`、`CentroidX`，以及 FWHM、峰面积、ERW 和相对 FWHM center 的峰位差。

### ⑥ GUI 默认参数

- Left pixels = 5，Right pixels = 5；
- 插值 = PCHIP；
- 插值因子 = 20；
- 局部基线 = 两端点线性基线。

### ⑦ 论文当前实际参数

根据本论文当前明确指定的参数：

- 峰窗为中心点左右各 4 pixel，即 ±4 pixel；
- 在不触及光谱数据边界时，这对应“中心点 + 左侧 4 点 + 右侧 4 点”，共 9 个原始采样点；
- 插值采用 cubic spline，对应 GUI 的 `Spline (research)` 和代码的 `method='spline'`；
- 若插值因子未另行修改，则仍为 GUI 默认 \(F=20\)；若论文实验使用其他因子，应以 Session/实验记录替换本句，当前请求没有给出其他数值；
- 局部基线仍为峰窗端点线性基线，除非实际实验代码另有修改。

### ⑧ 特别注意

- “cubic spline”在本实现中具体是 MATLAB `interp1(...,'spline')`；
- FWHM 的最终交点是在插值网格相邻点间再次线性求交；
- 质心积分使用插值净信号的非负部分，不使用负值；
- 多峰窗口会用相邻实测谷底限制插值峰位搜索，并标记 `PositionOnly`；
- 论文参数 ±4/spline 不是 V0.9.3 GUI 默认值，必须在 Methods 中明确区分。

---

## 7. Cross-definition validation

### ① 源代码文件/函数

- `src/wc4sm_cross_validate_peak_positions.m`
- GUI 数据组装：`WCC4SM_V0_9_3.m` 中 `runPositionCrossValidation`、`positionCrossTrainingSelection`、`pairPeakPosition`

### ② 输入

- \(X\in\mathbb R^{N\times4}\)：每行同一条匹配谱线，每列依次为 Direct、Interpolated、FWHM center、Centroid；
- 参考波长 \(\lambda_n\)；
- 峰位方法名称、阶次 \(m\)；
- `ValidationMode`：Full fit 或 LOO；
- `PoolMode`：Common intersection 或 Pairwise available；
- 训练和评估样本掩码。

GUI 可把训练集设为全部匹配点、当前最终模型、选中的比较模型或选中的 Set Design 候选；评估掩码在 GUI 中固定为全部匹配点。

### ③ 处理步骤

令行 \(a\) 表示 Calibration definition，列 \(b\) 表示 Application definition。

Full fit：

1. 用训练掩码中峰位定义 \(a\) 的位置 \(x_{n,a}\) 与 \(\lambda_n\) 拟合一次 \(m\) 阶模型 \(f_a^{(m)}\)；
2. 对每个应用定义 \(b\)，把 \(x_{n,b}\) 代入同一个 \(f_a^{(m)}\)；
3. 在相应有效评估样本上计算残差和指标。

LOO：

1. 逐个遍历定义 \(a\) 的训练行 \(n\)；
2. 删除同一条物理谱线的整行训练样本 \((x_{n,a},\lambda_n)\)；
3. 用其余训练行重新拟合 \(f_{a,-n}^{(m)}\)，每折重新计算 `mu`；
4. 将被删除谱线在所有应用定义下的位置 \((x_{n,1},\ldots,x_{n,4})\) 分别代入该折模型；
5. 因而非对角 LOO 仍删除第 \(n\) 条物理谱线，但预测输入是该谱线的应用峰位 \(x_{n,b}\)。

### ④ 数学公式

Full fit：

\[
e_{ab,n}^{(m),\mathrm{full}}
=\lambda_n-f_a^{(m)}(x_{n,b}).
\]

LOO：

\[
e_{ab,n}^{(m),\mathrm{LOO}}
=\lambda_n-f_{a,-n}^{(m)}(x_{n,b}).
\]

其中 \(f_{a,-n}^{(m)}\) 只用除第 \(n\) 条谱线外、满足训练池规则的 definition \(a\) 数据重建。

### ⑤ 输出指标

每个 \((a,b)\) 单元格输出残差向量、Bias、RMSE、STD、P95、MAX、Slope、`NTrain`、`N` 和有效谱线索引。

### ⑥ 默认参数

- 阶次默认 \(m=3\)，范围 1–20；
- Validation 默认 LOO；
- Pool 默认 Common intersection；
- Training set 默认 All matched pairs；
- Evaluation set 为 All matched pairs。

### ⑦ 论文当前实际参数

论文应明确写出所采用的阶次、Full fit/LOO、样本池和训练来源。若用 6 点子集训练并考察 41 点：

- Full fit 模式可用 6 点建模、在全部有效 41 点上评价；
- LOO 模式的当前代码只评价这 6 个训练点的逐一留出结果，不会在 41 点上产生“每折外部全池 LOO”指标。

### ⑧ 特别注意

- 矩阵方向为“行 = Calibration definition，列 = Application definition”；
- 对角线是同定义训练与应用，非对角线量化峰位定义失配；
- 当前代码没有定义“训练子集 LOO 后再对全部外部 41 点汇总”的嵌套外部验证；
- LOO 模式要求每种训练定义至少 \(m+2\) 个有效训练点。

---

## 8. Cross-definition metrics

### ① 源代码文件/函数

`src/wc4sm_cross_validate_peak_positions.m`

### ② 输入

某矩阵单元格的全部有限残差 \(e_n=\lambda_n-\hat\lambda_n\) 及其参考波长 \(\lambda_n\)，有效数量为 \(K\)。

### ③ 处理步骤

先删除非有限残差，再计算六项指标。Slope 通过 `polyfit(referenceWavelength,residual,1)` 获得。

### ④ 数学公式

\[
\mathrm{RMSE}=\sqrt{\frac1K\sum_{n=1}^{K}e_n^2},
\qquad
\mathrm{Bias}=\frac1K\sum_{n=1}^{K}e_n.
\]

交叉定义模块使用总体标准差：

\[
\mathrm{STD}
=\sqrt{\frac1K\sum_{n=1}^{K}(e_n-\mathrm{Bias})^2}.
\]

\[
\mathrm{MAX}=\max_n|e_n|.
\]

P95 对 \(|e_n|\) 升序排列。令

\[
r=1+0.95(K-1),\quad l=\lfloor r\rfloor,\quad h=\lceil r\rceil,
\]

则

\[
\mathrm{P95}=
\begin{cases}
|e|_{(l)},&l=h,\\
|e|_{(l)}+(r-l)(|e|_{(h)}-|e|_{(l)}),&l\ne h.
\end{cases}
\]

Slope 拟合：

\[
e_n=\alpha\lambda_n+\beta,
\qquad \mathrm{Slope}=\alpha.
\]

### ⑤ 输出指标

`RMSE`、`Bias`、`STD`、`P95`、`MAX`、`Slope`。

### ⑥ 默认参数

GUI 默认矩阵显示 RMSE；其他指标由下拉框切换，但同一次计算结果已包含全部指标。

### ⑦ 论文当前实际参数

指标不依赖峰窗参数，但依赖所选峰位、阶次、Validation mode、Pool mode 和训练样本集，论文表格必须同时注明这些条件。

### ⑧ 特别注意

- Slope 的横轴是参考波长 \(\lambda\)，纵轴是带符号残差 \(e\)；
- 单位为 nm/nm，数值上无量纲；
- 它表示残差随参考波长的线性漂移趋势，不是 \(d\lambda/dp\)，也不是定标多项式的一阶系数；
- 代码只保存斜率，不输出截距 \(\beta\)；
- 本模块 P95 使用线性插值；Influence P95 使用最近阶次位置，两者实现不同。

---

## 9. Sample pool

### ① 源代码文件/函数

`src/wc4sm_cross_validate_peak_positions.m`

### ② 输入

峰位矩阵 \(X\)、有限参考波长掩码、TrainingMask 和 EvaluationMask。

### ③ 处理步骤

Common intersection：

- 构造 \(M_{common}=isfinite(\lambda)\land all(isfinite(X),2)\)；
- 所有矩阵单元格的训练集均使用 `TrainingMask & M_common`；
- 所有单元格的评估集均使用 `EvaluationMask & M_common`。

Pairwise available：

- 对 Calibration definition \(a\)，训练集为 `TrainingMask & isfinite(lambda) & isfinite(X(:,a))`；
- 对单元格 \((a,b)\)，评估集还要求 \(x_{n,a}\) 与 \(x_{n,b}\) 同时有限；
- LOO 模式再把评估集限制到该行训练集。

### ④ 数学公式

公共池：

\[
\mathcal C=
\{n:\lambda_n\text{有限且}\forall j,\ x_{n,j}\text{有限}\}.
\]

成对评估池：

\[
\mathcal P_{ab}
=\{n:\lambda_n,x_{n,a},x_{n,b}\text{均有限}\}.
\]

### ⑤ 输出指标

`CommonTrainN`、`CommonN`、每个单元格的 `NTrain`、`N` 和 `ValidIndex`。

### ⑥ 默认参数

默认 Common intersection，GUI 标为 “All-method common peaks (recommended)”。

### ⑦ 论文当前实际参数

论文横向比较四种峰位时建议报告 Common intersection；若另报告 Pairwise available，必须同时报告每个单元格的 \(N\)。

### ⑧ 特别注意

- 无效或 NaN 峰位不做填补、不做插值替代，直接通过掩码排除；
- Pairwise available 的不同单元格可能使用不同样本数量，不能忽略 \(N\) 直接横比；
- Full fit 的训练池只依赖 Calibration definition \(a\)，应用定义 \(b\) 的 NaN 只影响该单元格评估；
- LOO 只对训练池中的谱线生成预测。

---

## 10. Residual sign convention

### ① 源代码文件/函数

已逐项检查：

- `src/wc4sm_fit_calibration.m`
- `src/wc4sm_validate_calibration_loo.m`
- `src/wc4sm_analyze_point_influence.m`
- `src/wc4sm_cross_validate_peak_positions.m`
- `src/wc4sm_analyze_model_order.m`
- `src/wc4sm_evaluate_subset.m`
- `src/wc4sm_analyze_add_one.m`
- `src/wc4sm_analyze_add_one_path.m`
- `src/wc4sm_analyze_seed_combinations.m`
- `src/wc4sm_analyze_seed_replacements.m`
- `WCC4SM_V0_9_3.m` 的模型比较与峰位关系拟合残差。

### ② 输入

参考值和相应模型预测值。

### ③ 处理步骤

上述波长定标、验证、优化、子集和交叉定义模块均直接执行“参考波长减预测波长”。

### ④ 数学公式

\[
e=\lambda_{reference}-\lambda_{predicted}.
\]

峰位关系图自身的拟合残差为

\[
e_{position}=y_{observed}-y_{fitted},
\]

方向同样是观测量减拟合量，但单位可以是 pixel，而不是定标波长残差。

### ⑤ 输出指标

所有带符号 Bias、MeanResidual、Residual 曲线和 Slope 均受该方向影响；RMSE、STD、P95、MAX 不因整体反号而改变。

### ⑥ 默认参数

当前代码没有残差方向切换参数。

### ⑦ 论文当前实际参数

论文应统一声明：“残差定义为参考波长减去模型预测波长”。

### ⑧ 特别注意

在本次审计覆盖的当前 V0.9.3 模块中，没有发现采用 `predicted wavelength - reference wavelength` 的波长残差。图轴有时写作 “Reference − fitted”，与源码一致。

---

## 11. Calibration-point selection

### ① 源代码文件/函数

- 规则集合：`src/wc4sm_generate_subset_mask.m`
- 分窗：`src/wc4sm_partition_subset_windows.m`
- 窗内推荐：`src/wc4sm_recommend_window_samples.m`
- GUI 入口：`WCC4SM_V0_9_3.m` 的 Set Design 和 Calibration Optimization

### ② 输入

目标样本数 Target K、完整候选池、波长、Influence、Quality、锁定/禁止掩码、人工掩码，以及所选规则。

### ③ 处理步骤

当前规则生成器支持：

1. Manual selection：完全采用 GUI 人工勾选，数量必须等于 K；
2. Top-k influence：按 Influence 降序，随后按 Quality 降序和波长升序确定次序；
3. Maximin coverage：从最接近波长中位数的点开始，迭代选择与已选集合最小波长距离最大的点；
4. Locked boundary + coverage：先锁定最短和最长波长，再执行 maximin；
5. Window influence / quality / center：按波长排序后等数量分组，每组分别选 Influence 最大、Quality 最大或最接近组内平均波长的点。

另有 Window Partition：

- Equal wavelength width：只产生等波长宽度窗口；
- Equal cumulative influence：寻找使累计归一化 Influence 接近 \(j/K\) 的严格递增切点；
- 分窗本身不产生子样本 Mask；
- `wc4sm_recommend_window_samples` 的窗内推荐只是 advisory，不会静默确认样本。

Backward Beam Search 是另一条模型空间逐层删除路径，不等同于固定 K 的唯一推荐算法。

### ④ 数学公式

Top-k 使用当前代码中的无量纲 \(I_n\) 排序。

Maximin 每步选择

\[
n^*=\arg\max_{n\notin S}\min_{s\in S}|\lambda_n-\lambda_s|.
\]

窗内推荐分数为

\[
Score_n=
\frac{I_n/\overline I_{window}}
{1+\max(d_n/d_{threshold},0)},
\]

其中 \(d_n=|x_{centroid}-x_{FWHMcenter}|\)，默认 \(d_{threshold}=0.2\) pixel。

### ⑤ 输出指标

候选 Mask、选中索引/Peak ID、Source、Target K、Influence、Quality、覆盖范围、全池残差和模型距离等。

### ⑥ 默认参数

- Set Design Target K 默认 10，允许 4–100；
- Set Design 模式默认 Top-k influence；
- Window Partition 的 K 默认 6；
- 窗内推荐默认 Influence 至少高于窗内均值 25%，或对称距离不超过 0.2 pixel；每窗最多推荐 3 点。

### ⑦ 论文当前实际参数

当前源代码没有预置或硬编码“9点推荐集”和“5点推荐集”，也没有仅凭样本数即可判断其来源的规则。若论文中的 9 点、5 点集合来自 GUI 操作，应以实际保存/导出的：

- Peak ID 列表；
- Candidate ID；
- Source/Method；
- Target K；
- Locked/Manual 状态；
- Session 或导出 CSV

作为 Methods 的依据。

如果现有 9 点或 5 点只是人工勾选，则必须写“人工选择/GUI 选择”；如果来自某个 Set Design 候选，则应写该候选记录的实际 `Source`。当前没有提供具体集合记录，因此本文不能判定它们实际来自哪种规则。

### ⑧ 特别注意

- “recommended”可能只是峰质量或窗内排序建议，不等于软件自动确定的唯一最优定标集；
- Window Partition 只划分区域，不自动选点；
- 不能从“K=9”或“K=5”反推出 Top-k、分窗、累计影响或 Beam；
- 代码没有定义自动选择最终最佳 K 的统计准则。

---

## 12. 论文公式速查表

| 符号/指标 | 可直接用于 Methods 的代码一致公式 |
|---|---|
| 归一化像素 | \(z_n=(p_n-\mu_1)/\mu_2\) |
| \(m\) 阶定标模型 | \(\hat\lambda(p)=c_0z^m+c_1z^{m-1}+\cdots+c_m\) |
| Fit residual | \(e_{fit,n}=\lambda_n-f^{(m)}(p_n)\) |
| Fit RMSE | \(\mathrm{RMSE}_{fit}=\sqrt{N^{-1}\sum_n e_{fit,n}^2}\) |
| LOO residual | \(e_{LOO,n}=\lambda_n-f_{-n}^{(m)}(p_n)\) |
| LOO RMSE | \(\mathrm{RMSE}_{LOO}=\sqrt{N^{-1}\sum_n e_{LOO,n}^2}\) |
| Generalization Gap | \(G=\mathrm{RMSE}_{LOO}-\mathrm{RMSE}_{fit}\) |
| 删除曲线变化 | \(Q_n=\max_{p_r\in\mathcal P}|f^{(m)}(p_r)-f_{-n}^{(m)}(p_r)|\) |
| Deletion Influence | \(I_n=|R-R_{-n}|/\max(R,\varepsilon_{mach})\)，其中 \(R=\mathrm{RMSE}_{LOO}\) |
| Mean Influence | \(\overline I=K^{-1}\sum_n I_n\) |
| RMS Influence | \(I_{RMS}=\sqrt{K^{-1}\sum_nI_n^2}\) |
| P95 Influence | \(I_{(\lceil0.95K\rceil)}\) |
| MAX Influence | \(\max_n I_n\) |
| Direct peak | \(x_D=x_{\arg\max_i[y_i-b(x_i)]}\) |
| Interpolated peak | \(x_I=\xi_{\arg\max_j S_j}\) |
| FWHM center | \(x_F=(x_{h,L}+x_{h,R})/2\)，\(h=\max(S)/2\) |
| Centroid | \(x_C=\int xS^+(x)dx/\int S^+(x)dx\)，\(S^+=\max(S,0)\) |
| Cross-definition Full residual | \(e_{ab,n}^{(m),full}=\lambda_n-f_a^{(m)}(x_{n,b})\) |
| Cross-definition LOO residual | \(e_{ab,n}^{(m),LOO}=\lambda_n-f_{a,-n}^{(m)}(x_{n,b})\) |
| Cross RMSE | \(\sqrt{K^{-1}\sum_ne_n^2}\) |
| Cross Bias | \(K^{-1}\sum_ne_n\) |
| Cross STD | \(\sqrt{K^{-1}\sum_n(e_n-\overline e)^2}\) |
| Cross MAX | \(\max_n|e_n|\) |
| Cross Slope | \(e_n=\alpha\lambda_n+\beta\)，Slope \(=\alpha\), nm/nm |
| Maximin 选点 | \(n^*=\arg\max_{n\notin S}\min_{s\in S}|\lambda_n-\lambda_s|\) |

## 13. 当前代码未定义的内容

为避免论文中过度解释，以下内容在当前代码中未定义：

- 基于 AIC、BIC、显著性检验或固定 Gap 阈值的自动最优阶次；
- Cook's distance、帽子矩阵杠杆值或参数协方差形式的 Influence；
- 固定的 9 点或 5 点标准推荐集合；
- 自动选择最终最佳样本数 K；
- 子集 LOO 每折重建后再对完整外部池评价的嵌套指标；
- Slope 的显著性、置信区间或截距输出；
- 对 NaN 峰位的插补算法；
- 由 `polyfit` 返回的 `S` 进一步计算的参数不确定度。
