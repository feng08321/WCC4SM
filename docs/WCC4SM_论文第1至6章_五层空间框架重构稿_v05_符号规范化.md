# 峰位定义依赖的阵列光谱仪波长定标模型选择与精度评估

Peak-Position Definition Dependence in Model Selection and Accuracy Assessment for Wavelength Calibration of Array Spectrometers

> 第1–6章中英文逐节对照五层空间框架重构审阅稿 v0.5（全文符号规范化与符号表补充），2026-09-07。
>
> 本稿整合第1–3章v0.3、第4章v0.2和第5–6章v0.3。摘要、关键词、参考文献、声明和最终图表尚未整合。正文保留作者补充、数据待核和引用待补标记；这些标记不进入投稿终稿。
>
> Integrated bilingual five-space-framework review draft of Chapters 1–6, v0.5 (notation normalization and nomenclature added). It combines Chapters 1–3 v0.3, Chapter 4 v0.2, and Chapters 5–6 v0.3. The abstract, keywords, references, declarations, and final figures remain pending. Author-input, data-check, and citation placeholders are retained for review and will not appear in the submission version.

---
## 1 引言 / 1 Introduction

**中文**

阵列光谱仪通过探测器阵列同时获取一定波段内的光谱信息，无需逐波长机械扫描，因而在太阳光谱辐射测量、环境监测、工业检测及物质光谱分析等领域得到广泛应用。对于基于硅探测器的宽波段光谱仪，数百纳米的光谱范围需要映射到有限数量的像元上。波长覆盖、光谱分辨率与探测器采样间隔相互制约，使波长定标不仅涉及位置与参考波长之间的数值拟合，也涉及谱线位置本身如何被测量和定义。[引用待补R1：阵列光谱仪应用及表征、定标与使用的相关文献。]

扫描单色仪与阵列光谱仪面临的成像约束并不相同。前者在任一工作状态主要通过固定出射狭缝读出选定波长，光学设计可围绕有限的物方—像方位置及扫描条件进行优化；后者则需将较宽波段同时成像于扩展探测器像面，不同波长对应不同的视场位置和衍射条件。对于采用反射镜—平面光栅的Czerny–Turner（CT）类阵列结构，离轴像差、场曲及离焦等残余效应难以在整个宽谱段上同时保持一致，因而单色线响应的宽度、非对称性及能量分布可能表现出波长依赖性。平场校正凹面光栅等设计能够显著改善像差，但不改变宽谱段阵列成像必须同时协调整个像面的基本约束。本文所用宽谱段仪器也对应太阳光谱辐射测量中常见的工程应用条件。[引用待补R1a：扫描单色仪、CT阵列光谱仪及宽谱段像差的权威资料。]

传统波长定标通常从一组已知谱线出发，提取其探测器位置，并建立像素坐标与参考波长之间的映射关系。该过程可简写为


$$
\lambda=f(p),
\tag{1}
$$


其中，$p$通常被作为已经确定的谱线位置。在这一表述中，峰位提取往往被视为拟合之前的数据处理步骤，其定义与后续定标模型之间的关系未被显式区分。

然而，实际仪器并非将单色辐射映射为探测器上的数学点。狭缝、色散与成像光学系统以及像元积分采样共同形成具有有限宽度的谱线响应。在采样点较少或响应不对称时，原始采样最大值、插值峰顶、半高全宽中心和强度质心可能对应不同的位置。前三者分别强调离散最大响应、插值曲线的局部最大响应以及半高区域的几何中点，而质心反映指定窗口内信号的加权位置。因此，这些定义不仅可能具有不同的随机定位波动，也可能对同一谱线形状产生不同的系统性响应。

当谱线近似对称、采样充分且精度要求相对宽松时，上述差异可能小到可以忽略，单一峰位变量仍是有效的工程近似。但在亚像素定标尺度下，特别是谱线轮廓随波长变化的宽波段仪器中，不同峰位定义之间的差异可能进一步表现为不同的经验定标关系。此时，较小的拟合残差并不能单独说明某一定标模型适合所有应用读出方式：采用一种峰位定义建立的模型，在输入另一种峰位定义得到的坐标时，可能产生不同的偏置、散布和波长相关残差。

前期研究已在近极限采样条件下考察了阵列光谱仪的多参数波长表征，讨论了峰位、半高中心与质心之间的差异，以及半高全宽（full width at half maximum，FWHM）与等效矩形宽度（equivalent rectangular width，ERW）的互补含义。这些结果说明，谱线的位置与宽度表征需要结合采样条件及峰形理解，而不宜完全分离。[引用待补R2：作者前篇，*Multi-Parameter Wavelength Characterization of Array Spectrometers Under Near-Limit Sampling Conditions*，Applied Spectroscopy，DOI: 10.1177/00037028261468369。]

在此基础上，本文将问题进一步聚焦到模型选择与精度评价：**当峰位具有定义依赖性时，应如何选择定标所用的峰位定义与模型阶次，又应在什么条件下报告该模型的波长误差？** 与前篇侧重峰参数表征不同，本文关注由峰位定义、模型复杂度和应用读出方式共同决定的定标性能。这里的“模型选择”不仅是多项式阶次选择，还包括用于建立位置—波长关系的峰位定义选择。

为显式描述上述模型自由度，本文将波长定标模型选择组织为五个相互联系的空间：样本空间 $\mathcal{S}$、表征空间 $\mathcal{X}$、函数空间 $\mathcal{F}$、参数空间 $\Theta$ 和模型特性空间 $\mathcal{C}$。其中，$\mathcal{X}$ 将通常被隐含固定的峰位输入扩展为由不同测量算子产生的候选表征；$\mathcal{C}$ 则将拟合残差、留一残差、删除扰动及跨定义残差的统计与二次构造量组织为模型特性坐标，并在候选模型形成、比较和选择过程中持续提供反馈。因此，本文的模型选择并非单独寻找最小拟合误差或某一最优多项式阶次，而是在样本配置、峰位表征和模型复杂度之间进行受性能、泛化、稳定性与兼容性约束的联合比较。该框架是一种面向阵列光谱仪波长定标的方法论组织方式，而非新的普适机器学习理论。

为此，本文以一台宽波段阵列光谱仪的Hg-Ar灯光谱为对象，在人工审查后固定的41条参考谱线上，分别建立直接峰位（Direct peak）、插值峰位（Interpolated peak）、FWHM中心（FWHM center）和质心（Centroid）对应的定标模型。首先通过拟合误差、留一验证及删除样本敏感性考察模型复杂度的影响；随后将定标峰位定义与应用峰位定义分开，构建跨定义评价矩阵，区分同定义条件下的误差与不同定义之间的兼容性；最后以5点和9点模型为代表性稀疏定标案例，在共同参考样本集上比较其表现。

本文旨在形成一套可解释的模型选择与误差报告方式，而不是证明某一种峰位定义是普遍唯一的“真实峰位”。峰窗、插值方法和局部基线处理作为已确认的分析条件予以记录并保持固定，其参数优化不属于本文研究范围。少点样本集用于考察既定案例下的跨定义表现，不开展最优样本选择算法研究。

**English**

Array spectrometers acquire spectral information over a wavelength interval simultaneously, without mechanical scanning from one wavelength to another. They are therefore widely used in solar spectral irradiance measurements, environmental monitoring, industrial inspection, and spectroscopic analysis of materials. In broadband instruments employing silicon detectors, a spectral interval spanning several hundred nanometers must be mapped onto a finite number of detector pixels. Wavelength coverage, spectral resolution, and detector sampling interval are consequently interrelated. Wavelength calibration thus involves not only numerical fitting between position and reference wavelength, but also the measurement and definition of spectral-line position itself. [References to be added R1: applications of array spectrometers and relevant literature on characterization, calibration, and use.]

Scanning monochromators and array spectrometers face different imaging constraints. At a given operating state, a scanning instrument primarily reads a selected wavelength through a fixed exit slit, allowing optimization around a limited set of object–image locations and scanning conditions. An array spectrometer must instead image a broad spectral interval simultaneously onto an extended detector plane, with wavelength-dependent field positions and diffraction conditions. In mirror–plane-grating Czerny–Turner (CT) array configurations, residual off-axis aberrations, field curvature, and defocus cannot generally be held invariant across the entire broad interval, so monochromatic-line width, asymmetry, and energy distribution may vary with wavelength. Flat-field aberration-corrected concave-grating designs can substantially mitigate these effects, but do not remove the fundamental requirement to balance imaging over an extended plane. The broadband instrument investigated here represents conditions relevant to solar spectral-irradiance measurements. [Reference to be added R1a: authoritative sources on scanning monochromators, CT array spectrometers, and broadband aberrations.]

Conventional wavelength calibration generally starts with a set of known spectral lines, extracts their detector positions, and establishes a mapping between pixel coordinate and reference wavelength. This process is commonly written as Eq. (1), λ = f(p), where p is treated as an already determined line position. In this formulation, peak-position extraction is often regarded as a preprocessing step, without explicitly distinguishing its definition from the subsequent calibration model.

In a real instrument, however, monochromatic radiation does not form a mathematical point on the detector. The slit, dispersive and imaging optics, and pixel-integrated sampling together produce a finite-width line response. When sampling is sparse or the response is asymmetric, the maximum original sample, interpolated maximum, FWHM center, and intensity centroid may occupy different positions. The first three emphasize the discrete response maximum, the local maximum of the interpolated response, and the geometric midpoint of the half-maximum region, respectively; the centroid describes an intensity-weighted position within a specified window. These definitions may therefore differ not only in random localization variability, but also in their systematic response to the same line profile.

When spectral lines are approximately symmetric, sufficiently sampled, and subject to relatively modest accuracy requirements, these differences may be negligible, and a single positional variable remains a useful engineering approximation. At subpixel calibration scales, however, particularly in broadband instruments whose line profiles vary with wavelength, differences among peak-position definitions may lead to different empirical calibration relationships. A small fitting residual alone then does not establish that a calibration model is suitable for all application readout methods. A model calibrated using one position definition may produce different bias, dispersion, and wavelength-dependent residuals when supplied with positions obtained using another definition.

Our previous study investigated multi-parameter wavelength characterization of array spectrometers under near-limit sampling conditions. It examined differences among peak, FWHM-center, and centroid positions, together with the complementary meanings of full width at half maximum (FWHM) and equivalent rectangular width (ERW). Those findings indicate that positional and width descriptors should be interpreted jointly with sampling conditions and line shape, rather than in isolation. [Reference to be added R2: the authors’ previous article, “Multi-Parameter Wavelength Characterization of Array Spectrometers Under Near-Limit Sampling Conditions,” Applied Spectroscopy, DOI: 10.1177/00037028261468369.]

Building on that work, the present study focuses on model selection and accuracy assessment: when peak position is definition-dependent, how should the calibration definition and polynomial order be selected, and under what conditions should the wavelength error of the selected model be reported? Unlike the previous emphasis on peak characterization, the present work examines calibration performance as jointly conditioned by peak-position definition, model complexity, and application readout. Here, model selection includes both polynomial-order selection and the choice of position definition used to establish the position–wavelength relationship.

To make these model degrees of freedom explicit, wavelength-calibration model selection is organized here in five interrelated spaces: the sample space $\mathcal{S}$, representation space $\mathcal{X}$, function space $\mathcal{F}$, parameter space $\Theta$, and model characteristic space $\mathcal{C}$. The representation space makes the otherwise implicit choice of peak-position input an explicit model-selection variable, whereas the characteristic space organizes residual statistics and secondary diagnostics derived from fitting, leave-one-out prediction, sample deletion, and cross-definition application. These characteristics provide feedback throughout candidate-model construction, comparison, and selection. Model selection is therefore not reduced to minimizing a fitting residual or choosing a polynomial order in isolation, but is treated as a joint comparison of sample configuration, position representation, and model complexity under performance, generalization, stability, and compatibility constraints. The framework is intended as a methodological formulation for wavelength calibration of array spectrometers rather than as a new general theory of machine learning.

An Hg-Ar lamp spectrum measured with a broadband array spectrometer is used for this purpose. Calibration models are constructed from a fixed set of 41 manually reviewed reference lines using four position definitions: Direct peak, Interpolated peak, FWHM center, and Centroid. The effects of model complexity are first examined using fitting error, leave-one-out validation, and sample-deletion sensitivity. Calibration and application definitions are then separated to construct cross-definition assessment matrices, distinguishing within-definition error from compatibility between definitions. Finally, representative five- and nine-point calibration models are evaluated on the common reference set as sparse-calibration case studies.

The objective is to establish an interpretable approach to model selection and error reporting, rather than to identify one universally unique “true” peak position. Analysis windows, interpolation, and local baseline treatment are recorded as confirmed processing conditions and held fixed; their optimization is outside the scope of this study. The sparse subsets are used to examine cross-definition performance in specified cases, not to investigate optimal sample-selection algorithms.

## 2 实验装置与数据集构建 / 2 Experimental Setup and Dataset Construction

### 2.1 光谱仪与参考光源 / 2.1 Spectrometer and Reference Source

**中文**

实验采用OTO的EE2063S-10-DUVN4阵列光谱仪，具有M型Czerny–Turner光路结构，标称工作波长范围为250–1100 nm。仪器使用Hamamatsu S11850探测器，有效像元数为2048×64，像元尺寸为14 μm×14 μm；光栅刻线密度为500 grooves/mm，闪耀波长为330 nm，入射狭缝宽度为10 μm，标称光谱分辨率为1 nm。上述标称工作范围与后续实际采用的参考谱线覆盖范围分别报告，避免将仪器可输出范围等同于本研究已评价的范围。

波长参考光源采用BHK Hg-Ar灯。测量时将光源置于入射狭缝前，直接耦合获得Hg和Ar的发射光谱。参考波长取自NIST Atomic Spectra Database中的Hg、Ar谱线数据，并根据实测光谱中可识别的弱线补充查询相关记录。参考文件的组织形式兼容已有软件使用的标准谱线文件，但文件格式兼容性不作为参考波长溯源依据。[引用待补R3：NIST ASD版本、访问日期、实际参考波长记录及空气/真空波长口径。]

**English**

Measurements were performed using an OTO EE2063S-10-DUVN4 array spectrometer with an M-type Czerny–Turner optical configuration and a nominal wavelength range of 250–1100 nm. The instrument employs a Hamamatsu S11850 detector with 2048 × 64 effective pixels and a pixel size of 14 μm × 14 μm. It is equipped with a 500 grooves/mm grating blazed at 330 nm, a 10 μm entrance slit, and a nominal spectral resolution of 1 nm. The nominal operating range is reported separately from the actual reference-line coverage used in the analysis, so that the instrument output range is not conflated with the range assessed in this study.

A BHK Hg-Ar lamp served as the wavelength reference source. The lamp was positioned in front of the entrance slit and directly coupled to the spectrometer to acquire Hg and Ar emission spectra. Reference wavelengths were obtained from Hg and Ar records in the NIST Atomic Spectra Database, with additional records retrieved for weak lines identifiable in the measured spectrum. The reference file was organized in a format compatible with standard line files used by existing software; file-format compatibility was not treated as evidence of wavelength traceability. [Reference information to be added R3: NIST ASD version, access date, the actual reference-line records, and the air/vacuum wavelength convention.]

### 2.2 多曝光采集与HDR光谱构建 / 2.2 Multi-Exposure Acquisition and HDR Spectrum Construction

**中文**

Hg-Ar光源在宽波段内具有较大的谱线强度动态范围。单一长积分时间有利于弱线检测，却可能使强线接近饱和；短积分时间能够保留强线响应，但弱线的信噪比较低。为同时获得强线和弱线信息，分别采用10、100和1000 ms三个积分时间采集信号光谱与暗光谱。

对于第$r$档曝光，设积分时间为$t_r$，信号和暗背景的平均光谱分别为$\overline{S_r(p)}$和$\overline{D_r(p)}$，净信号及单位积分时间信号为


$$
N_r(p)=\overline{S_r(p)}-\overline{D_r(p)},\qquad
J_r(p)=\frac{N_r(p)}{t_r}.
\tag{2}
$$


当前实验记录采用每档100帧信号与100帧暗背景分别平均后相减。[事实待核E1：最终稿根据采集记录确认平均帧数；现有主稿写为100帧，早期实验清单仍保留“需确认”标记。]

HDR构建以较长曝光保留弱信号信息，并在长曝光接近饱和的区域使用较短曝光的有效数据。不同曝光在有效重叠区进行相对尺度匹配，再按1000 ms、100 ms、10 ms的层级完成替换。该处理的目的在于形成供后续峰位分析使用的统一光谱，而不是通过多曝光平均人为增密谱线的像素采样。按照现有HDR处理说明，输出像元取自经尺度匹配的一档有效曝光；具体尺度估计、有效区和替换判据应与实际处理记录对应。[事实待核E2：确认本文数据实际采用的HDR模式及参数，必要时列于补充材料，不把程序默认设置直接当作采集事实。]

HDR光谱用于候选峰检测、人工峰形检查以及后续的四定义峰位计算。本文不比较不同HDR重建算法的性能。

**English**

The Hg-Ar source exhibits a large variation in emission-line intensity across the broadband measurement range. A single long integration time facilitates weak-line detection but may bring strong lines close to saturation. A short integration time preserves strong-line responses but provides lower signal-to-noise ratios for weak lines. Signal and dark spectra were therefore acquired at three integration times: 10, 100, and 1000 ms.

For exposure level r, let t_r denote the integration time, and let the averaged signal and dark spectra be S̄_r(p) and D̄_r(p), respectively. The net signal N_r(p) and the signal per unit integration time J_r(p) are defined by Eq. (2): the averaged dark spectrum is subtracted from the averaged signal spectrum, and the resulting net spectrum is divided by t_r.

The current experimental description specifies separate averaging of 100 signal frames and 100 dark frames at each exposure before subtraction. [Verification required E1: confirm the frame counts against acquisition records before finalization. The existing manuscript states 100 frames, whereas the early experimental checklist retains a “to be confirmed” note.]

HDR construction retains weak-signal information from the longer exposure and replaces regions approaching saturation with valid shorter-exposure data. Relative scaling is established in valid overlap regions, followed by hierarchical replacement using the 1000, 100, and 10 ms exposures. This procedure provides a common spectrum for subsequent position analysis; it does not increase the density of detector samples through multi-exposure averaging. According to the existing HDR processing description, each output pixel is taken from one valid, appropriately scaled exposure. The actual scale estimation, validity criteria, and replacement rules must correspond to the processing record. [Verification required E2: confirm the HDR mode and parameters actually used for this dataset; provide them in supplementary material if appropriate. Software defaults must not be substituted for acquisition facts.]

The HDR spectrum was used for candidate-peak detection, manual profile inspection, and subsequent calculation of the four position definitions. Comparing alternative HDR reconstruction algorithms is outside the scope of this study.

### 2.3 参考线匹配与人工审查 / 2.3 Reference-Line Matching and Manual Review

**中文**

原子参考谱线集合并不等同于实际光谱仪能够独立测量的峰集合。受光谱分辨率、响应强度、邻线间隔及仪器线型影响，部分弱线不能形成可独立定位的峰，部分相邻谱线则可能构成混合响应。因此，参考匹配需同时考虑原子波长记录与实测峰的可分辨性。

在HDR光谱上初步检测得到63个候选峰。依据现有实验记录，首先人工匹配6个在波段内具有一定覆盖、峰形较清楚的种子峰，用于建立初始位置—波长关系，并辅助其余谱线匹配。这里的种子对应仅服务于初始识别，与后文用于模型比较的5点或9点定标子集不是同一概念。

随后对候选匹配逐一进行人工审查，结合局部峰形、邻峰干扰、参考线查询、定标残差和LOO诊断结果，剔除存在明显干扰或匹配异常的候选峰。对于部分被LOO提示为异常的位置，进一步查询NIST谱线信息并检查局部响应，以判定是否存在确切的弱邻线干扰。LOO在这一过程中作为诊断线索，而不是根据单一阈值自动删除样本的规则。

经过上述人工确认，最终保留41条谱线作为后续固定分析样本，参考波长覆盖265.3679–1067.3565 nm。完成确认后，各模型使用同一组物理谱线及对应参考波长，不再随模型阶次或峰位定义重新筛选样本。

[作者补充A1：在此补入2–4个典型人工审查案例，说明邻峰干扰、LOO提示与NIST查询之间的对应关系，以及保留或排除的依据。]

[拟Fig.1：HDR实测光谱、候选峰与最终41条参考线的波段分布；不在此展开选样优化流程。]

**English**

The set of atomic reference lines is not identical to the set of peaks that a practical spectrometer can measure independently. Spectral resolution, response intensity, neighboring-line separation, and instrument line shape may prevent some weak lines from forming independently localizable peaks, while adjacent lines may produce blended responses. Reference matching must therefore consider both atomic wavelength records and the resolvability of measured features.

Initial detection on the HDR spectrum identified 63 candidate peaks. According to the existing experimental record, six manually matched seed peaks with relatively clear profiles and coverage across the spectral interval were first used to establish an initial position–wavelength mapping and assist subsequent matching. These seed correspondences served initial identification and should not be confused with the five- or nine-point subsets later used for calibration-model comparison.

Candidate matches were subsequently reviewed individually using local line profiles, neighboring-line interference, reference-line queries, calibration residuals, and LOO diagnostics. Candidates exhibiting evident interference or matching abnormalities were excluded. For some positions flagged by LOO diagnostics, NIST records and the measured local response were examined further to determine whether identifiable weak neighboring lines were present. LOO was thus used as a diagnostic cue, rather than as an automatic sample-deletion rule based on a single threshold.

Following manual confirmation, 41 lines were retained as the fixed analysis set, with reference wavelengths spanning 265.3679–1067.3565 nm. All subsequent models used the same physical lines and reference wavelengths; the sample set was not reselected for different model orders or position definitions.

[Author input A1: add two to four representative review cases showing how neighboring-line interference, LOO indications, and NIST queries informed retention or exclusion decisions.]

[Proposed Fig. 1: the measured HDR spectrum, candidate peaks, and wavelength distribution of the final 41 reference lines. Sample-selection optimization is not developed here.]

### 2.4 逐峰处理条件与固定数据集 / 2.4 Per-Line Processing Conditions and the Fixed Dataset

**中文**

候选峰的分析窗口通常设置为左右各4个原始像素，即包含9个原始采样点，并由人工逐峰确认。在邻峰干扰较明显时，适当调整窗口边界，以保留目标峰的主要响应并限制邻峰进入。最终41条谱线中，40条使用左右各4像素的窗口，P007使用左4、右3像素的窗口。各谱线实际窗口参数随数据保存。

确认后的局部光谱采用端点线性基线和三次样条插值进行处理，每个原始采样间隔细分为20份。原始坐标间隔为1像素时，加密网格间隔为0.05像素。具体峰位运算见第3.2节。插值仅提供数值定位所需的加密表示，不改变仪器的物理光谱分辨率，也不意味着定位精度必然等于网格间隔。

“处理条件固定”是指：对某一条谱线，一旦人工确认窗口及处理参数，其四种峰位定义和后续所有定标分析均使用这组条件；并不要求不同谱线具有完全相同的窗口。设第$n$条谱线的处理参数为$\boldsymbol\theta_n$，其中包含窗口、基线和插值设置，其数据记录表示为


$$
\mathcal D_n=\left\{\lambda_n^{\mathrm{ref}},\ H_n,\
p_{D,n},p_{I,n},p_{F,n},p_{C,n},\boldsymbol\theta_n\right\}.
\tag{3}
$$


四种坐标均来自同一实测局部响应$H_n$。固定数据集记为$\mathcal D=\{\mathcal D_n\}_{n=1}^{41}$。本文分析由WCC4SM V0.9.3中的相关计算模块完成，模型拟合使用MATLAB的`polyfit`与`polyval`。最终复现记录应同时保存软件版本、实际样本ID及参数，避免仅凭图件标题确定分析条件。

**English**

Candidate peaks were generally analyzed using a window extending four original pixels to either side, giving nine original samples, and the windows were confirmed individually by manual inspection. Window boundaries were adjusted when neighboring-line interference was appreciable, retaining the main target response while limiting contributions from adjacent peaks. Of the final 41 lines, 40 used four pixels on each side, while P007 used four pixels on the left and three on the right. The actual window settings were retained with each line record.

Confirmed local spectra were processed using a linear baseline defined by the window endpoints and cubic-spline interpolation, with each original sampling interval divided into 20 subintervals. For original coordinates spaced by one pixel, the resulting grid spacing was 0.05 pixel. The position calculations are specified in Section 3.2. Interpolation provides a refined numerical representation for localization; it does not improve the physical spectral resolution or imply that localization accuracy necessarily equals the grid spacing.

Fixed processing conditions mean that, once the window and parameters of a given line have been confirmed, all four position definitions and subsequent calibration analyses use those conditions. They do not require identical windows for different lines. Let θ_n denote the processing parameters of line n, including window, baseline, and interpolation settings. Its record is expressed by Eq. (3), comprising the reference wavelength, local response, four position coordinates, and processing parameters.

All four coordinates originate from the same measured local response H_n. The fixed dataset is denoted by D = {D_n}, n = 1,…,41. The analyses were implemented in the relevant WCC4SM V0.9.3 modules, with model fitting performed using MATLAB polyfit and polyval. Reproducibility records should retain the software version, actual sample identifiers, and processing parameters rather than relying on figure titles alone to identify analysis conditions.

## 3 峰位定义与定标评价方法 / 3 Peak-Position Definitions and Calibration Assessment Methods


#### 主要符号 / Principal Symbols

为降低多层索引和多空间表述带来的阅读负担，下表汇总全文反复使用的核心数学符号。局部峰形计算中仅在单一小节使用的变量仍在首次出现处定义。

| 类别 | 符号 | 含义 |
|---|---|---|
| Framework | $\mathfrak{M}$ | 五层波长定标建模框架 |
| Framework | $\mathcal{S}$ | Sample space，样本空间 |
| Framework | $\mathcal{X}$ | Representation space，峰位表征空间 |
| Framework | $\mathcal{F}$ | Function space，定标函数空间 |
| Framework | $\Theta$ | Parameter space，模型参数空间 |
| Framework | $\mathcal{C}$ | Model characteristic space，模型特性空间 |
| Sample | $S_K$ | 含 $K$ 条参考谱线的具体定标样本集 |
| Sample | $S_{41}$ | 本文完整41点样本集 |
| Sample | $s_n$ | 第 $n$ 个参考谱线样本 |
| Sample | $S_{-n}$ | 删除第 $n$ 个样本后的集合，$S_{-n}=S_{41}\setminus\{s_n\}$ |
| Representation | $H_n(p)$ | 第 $n$ 条谱线的实测响应轮廓 |
| Representation | $T_k$ | 第 $k$ 种峰位测量算子 |
| Representation | $p_{k,n}$ | 定义 $k$ 下第 $n$ 条谱线的位置 |
| Index | $k$ | 通用峰位定义索引，$k\in\{D,I,F,C\}$ |
| Index | $i$ | 跨定义分析中用于建立定标模型的峰位定义 |
| Index | $j$ | 跨定义分析中应用阶段输入的峰位定义 |
| Index | $m$ | 多项式阶次 |
| Index | $n$ | 参考谱线索引 |
| Index | $q$ | 峰窗内原始探测器采样索引 |
| Index | $l$ | 加密插值网格索引 |
| Model | $f_{k,S_K}^{(m)}$ | 基于定义 $k$、样本集 $S_K$ 的 $m$ 阶定标函数 |
| Model | $\theta,\hat{\theta}_{k,m,S_K}$ | 模型参数及其拟合解，$\theta\in\Theta$ |
| Model | $M$ | 一个具体候选定标模型 |
| Characteristic | $\Phi$ | 候选模型到模型特性空间的映射 |
| Characteristic | $\boldsymbol{\phi}(M)$ | 候选模型 $M$ 的特性向量 |
| Residual | $\lambda_n^{\mathrm{ref}}$ | 第 $n$ 条谱线的参考波长 |
| Residual | $\hat{\lambda}_n$ | 模型预测波长 |
| Residual | $e_{ij,n}^{(m)}$ | 跨定义残差，Reference − Predicted |
| Diagnostic | $G^{(m)}$ | 泛化差，$RMSE_{\mathrm{LOO}}-RMSE_{\mathrm{Fit}}$ |
| Diagnostic | $Q_{k,n}^{(m)}$ | 删除样本后的最大定标曲线变化，单位 nm |
| Diagnostic | $I_{k,n}^{(m)}$ | 删除样本后的相对LOO性能影响，无量纲 |

**索引约定 / Index convention.** $k$ 为一般峰位定义索引；跨定义分析中，$i$ 始终表示用于建立定标模型的峰位定义，$j$ 始终表示应用阶段输入的峰位定义。$D$、$I$、$F$、$C$ 分别表示 Direct、Interpolated、FWHM center 和 Centroid。

#### 缩略语 / Abbreviations

| 缩略语 | 含义 |
|---|---|
| HDR | High dynamic range |
| LOO | Leave-one-out |
| FWHM | Full width at half maximum |
| ILS | Instrument line shape |
| LSF | Line-spread function |
| RMSE | Root-mean-square error |
| P95 | 绝对残差的95百分位数 |
| NIST | National Institute of Standards and Technology |
| ASD | Atomic Spectra Database |


### 3.2 从入射波长到谱线位置 / 3.1 From Incident Wavelength to Spectral-Line Position

**中文**

对于给定入射波长$\lambda$，仪器在探测器上形成有限宽度的响应，可概念性地表示为$H(p;\lambda)$。实际数据是该响应经像元积分与离散采样后的序列；连续符号$H$不意味着实验已经获得无限分辨率的真实线型。

从波长到用于定标的坐标，需要区分两个过程：


$$
\lambda\longrightarrow H(p;\lambda)
\longrightarrow T_k[H;\boldsymbol\theta]
\longrightarrow p_k,
\tag{4}
$$


其中，$T_k$表示第$k$种位置提取算子，$\boldsymbol\theta$为其处理条件。第一个过程涉及仪器的光谱响应及采样，第二个过程从该响应中定义一个代表位置。在有限采样和非对称响应下，第二个过程可以有多个合理但不等价的定义。

本文讨论的定义依赖性是经验定标映射对位置测量定义的依赖，不意味着光栅物理色散关系本身不确定或具有多个真实入射波长。也不以不同峰位之间存在差异为依据，单独识别某一种具体像差；观测差异仍可能受到采样、响应形状及处理条件的共同影响。

**English**

For a given incident wavelength λ, the instrument produces a finite-width detector response, conceptually represented by H(p; λ). The measured data are a sequence obtained after pixel integration and discrete sampling. The continuous notation H does not imply that the experiment recovers a true line profile at unlimited resolution.

Two processes must be distinguished when obtaining a coordinate for calibration: formation of the measured response and extraction of a representative position. Equation (4) expresses the chain from λ to H, through the position operator T_k and its processing conditions θ, to p_k. The first process concerns instrumental response and sampling; the second assigns a position to that response. Under finite sampling and asymmetric responses, several reasonable but non-equivalent definitions may be used for the second process.

Definition dependence in this study refers to the dependence of an empirical calibration mapping on the position-measurement definition. It does not imply that physical grating dispersion is indeterminate or that one incident line has multiple true wavelengths. Differences among measured positions are also not used alone to identify a particular optical aberration: the observed separation may reflect the combined effects of sampling, response shape, and processing conditions.

#### 3.2.1 物理响应、位置定义与数值实现 / Physical Response, Position Definition, and Numerical Implementation

**中文**

有限宽度的单色线响应并不直接提供一个不依赖定义的标量位置。最大值、半高轮廓中心和强度分布中心分别对应不同的响应特征。位置算子因此不仅是拟合前的数值处理，也是将空间分布转化为定标坐标的操作性测量定义。对理想对称、单峰且充分采样的响应，这些位置可以重合；在非对称、有限窗口及离散采样条件下，这种重合不再得到保证。参考谱线的物理波长仍然是同一个量，改变的是代表探测器响应的坐标约定。

位置定义与数值实现需要分开。Direct与Interpolated均属于极大值定位，分别在原始采样网格和样条重构的加密网格上实现；FWHM中心与Centroid则分别使用半高交点几何和强度一阶矩。后三种方法在本程序中共用插值响应，并不意味着三者估计的是同一个位置。插值细化计算网格，可提供亚像素坐标，却不新增独立测量信息，也不提高探测器实际采样率或仪器物理分辨率。

高斯拟合等参数化方法额外引入峰形模型及拟合准则，其中心参数不能一般性地视为样条最大值的等价替代。本文选择四种算子，是为了在固定实现条件下比较具有明确代表意义的位置定义，并非穷尽峰位估计方法，也不声称未纳入的方法与所选方法数学等价。

**English**

A finite-width monochromatic-line response does not directly provide a definition-independent scalar position. Its maximum, half-maximum contour midpoint, and intensity-distribution center represent different features. A position operator is therefore not merely numerical preprocessing: it is an operational measurement definition converting a spatial distribution into a calibration coordinate. These positions can coincide for an ideal symmetric, unimodal, adequately sampled response, but coincidence is not guaranteed with asymmetry, finite windows, and discrete sampling. The physical wavelength remains the same; what changes is the coordinate convention representing the detector response.

Position definition must be separated from numerical implementation. Direct and Interpolated positions both localize a maximum, on the original sample grid and a refined spline-reconstructed grid, respectively. FWHM-center and Centroid positions instead use half-maximum crossing geometry and the first intensity moment. Sharing an interpolated response does not mean that the latter three methods estimate the same position. Interpolation refines the computational grid and permits subpixel coordinates, but adds no independent measurement information and increases neither the acquisition sampling rate nor physical optical resolution.

Parametric methods such as Gaussian fitting additionally impose a profile model and fitting criterion; their center parameters are not generally equivalent to a spline maximum. The four operators compare positions with explicit representative meanings under fixed implementation conditions, without exhausting localization methods or implying mathematical equivalence of excluded methods.

### 3.3 四种峰位的计算定义 / 3.2 Computational Definitions of the Four Positions

**中文**

设第$n$条谱线的原始窗口坐标为$p_{n,q}$，对应信号为$y_{n,q}$。由窗口两端信号建立线性基线$b_n(p)$，原始采样上的净信号为


$$
h_{n,q}=y_{n,q}-b_n(p_{n,q}).
\tag{5}
$$


在加密坐标$\widetilde p_{n,l}$上，程序先对原始信号做三次样条插值，再扣除对应的线性基线，得到


$$
\widetilde h_{n,l}
=\operatorname{spline}(p_{n,q},y_{n,q};\widetilde p_{n,l})
-b_n(\widetilde p_{n,l}).
\tag{6}
$$


以下四种位置定义均在该已确认窗口内计算。

**直接峰位。** Direct取基线校正后原始采样信号的最大值位置：


$$
p_{D,n}=p_{n,q^*},\qquad q^*=\arg\max_q h_{n,q}.
\tag{7}
$$


当采用整数像素索引时，$p_{D,n}$为整数坐标，其定位受离散采样约束。这里的Direct是已确认窗口内净信号的最大值位置，不必与初始寻峰返回的索引完全相同。

**插值峰位。** Interpolated取加密网格上净信号的最大值位置：


$$
p_{I,n}=\widetilde p_{n,l^*},\qquad
l^*=\arg\max_l\widetilde h_{n,l}.
\tag{8}
$$


此定义对应实际程序中的有限网格搜索，而不是对样条函数进行解析极值求解。

**FWHM中心。** 设加密净信号最大值为$h_{n,\max}$，在该最大值两侧寻找最近的半高交点。对于相邻网格点中包围$h_{n,\max}/2$的区间，通过线性插值确定交点$p_{L,n}$与$p_{R,n}$，则


$$
p_{F,n}=\frac{p_{L,n}+p_{R,n}}{2},\qquad
w_{F,n}=p_{R,n}-p_{L,n}.
\tag{9}
$$


$p_{F,n}$是两个半高交点的几何中点，不要求整个谱线关于该点对称。若窗口内不能获得有效的左右交点，该定义的结果不能直接作为有效定标坐标。

**质心。** 将加密净信号的负值截断为零，记$\widetilde h_n^+(p)=\max[\widetilde h_n(p),0]$，在确认窗口$\Omega_n$内计算


$$
p_{C,n}=\frac{\int_{\Omega_n}p\,\widetilde h_n^+(p)\,\mathrm dp}
{\int_{\Omega_n}\widetilde h_n^+(p)\,\mathrm dp}.
\tag{10}
$$


程序使用加密网格上的梯形求积实现式（10）。因此，这里的质心是指定窗口与指定处理条件下的非负信号质心，而不是未经截断、覆盖无限谱域的响应质心。

四种定义分别利用不同的响应特征。直接峰位与插值峰位强调最大响应位置，FWHM中心强调半高区域，质心则综合窗口内非负响应的分布。本文固定其实现和参数后比较下游定标结果，不将峰位定义差异混同为不同窗口或插值设置的比较。

**English**

Let p_n,q denote the original sample coordinates within the confirmed window of line n, with corresponding signals y_n,q. A linear baseline b_n(p) is constructed from the signals at the two window endpoints. The net original samples h_n,q are obtained by baseline subtraction, as specified in Eq. (5).

On the refined coordinates p̃_n,l, the implementation first applies cubic-spline interpolation to the original signal and then subtracts the corresponding linear baseline, producing the net interpolated samples h̃_n,l in Eq. (6). All four positions below are calculated within this confirmed window.

**Direct peak.** The Direct definition selects the original sample coordinate at which the baseline-corrected signal is largest, as given by Eq. (7). When integer pixel indices are used, p_D,n is an integer coordinate and is constrained by discrete sampling. It represents the maximum net original sample within the confirmed window and need not coincide exactly with the index returned during initial peak detection.

**Interpolated peak.** The Interpolated definition selects the coordinate of the maximum net signal on the refined grid, as given by Eq. (8). This is a finite-grid search corresponding to the implemented algorithm, not an analytical extremum calculation on the continuous spline function.

**FWHM center.** Let h_n,max be the maximum net interpolated signal. The nearest half-maximum crossings on either side of this maximum are located by identifying adjacent grid points bracketing h_n,max/2 and linearly interpolating between them. The center p_F,n is the midpoint of the resulting crossings p_L,n and p_R,n, and the FWHM is their separation, as given by Eq. (9). This midpoint does not require the entire profile to be symmetric. If valid crossings on both sides cannot be obtained within the window, the result cannot be used directly as a valid calibration coordinate for this definition.

**Centroid.** Negative net interpolated values are clipped to zero, giving h̃_n⁺(p) = max[h̃_n(p), 0]. The centroid is the first moment of this nonnegative signal divided by its integral over the confirmed window Ω_n, as given by Eq. (10). Both integrals are evaluated by trapezoidal integration on the refined grid. The resulting coordinate is therefore a nonnegative-signal centroid under a specified window and processing convention, rather than the centroid of an untruncated response over an infinite spectral domain.

The four definitions use different response features. Direct and Interpolated positions emphasize the response maximum, the FWHM center emphasizes the half-maximum region, and the Centroid integrates the distribution of nonnegative signal within the window. Their implementations and parameters are held fixed when comparing downstream calibration results, so that differences in position definition are not conflated with comparisons of different windows or interpolation settings.

#### 3.3.1 半高中心与质心的物理解释 / Physical Interpretation of the FWHM Center and Centroid

**中文**

半高中心描述半高水平上峰轮廓的几何中心，并不等同于整个峰的能量中心。若单侧拖尾主要位于半高以下，且未显著改变峰顶高度、半高交点或基线，其对半高中心的直接影响可能小于对质心的影响。这是条件性的特征选择，不是对非对称性或邻峰干扰的普遍免疫。半高全宽也不同于峰面积除以峰高所得的等效矩形宽，本文不将半高中心称为等效矩形中心。

式（10）的质心是强度加权平均位置，满足窗口内的一阶矩平衡：


$$
\int_{\Omega_n}(p-p_{C,n})\widetilde h_n^+(p)\,\mathrm dp=0.
\tag{10a}
$$


平衡的是两侧强度与距离乘积的积分，不是两侧面积。使左右面积相等的位置是中位位置或等面积分割点，属于另一种定义，不是本程序计算的Centroid。拖尾对质心的作用同时取决于强度和距离，因此较低强度的远端拖尾也可能产生可见位移。一阶矩的解释与谱线定位研究中的常用定义一致。[谱线定位方法研究](https://arxiv.org/abs/1809.10295)

质心与半高中心的分离表征整体强度平衡位置相对于半高几何中心的偏移。在固定窗口、基线和插值条件下，它可作为响应非对称性的一个描述量，但非零分离不能唯一归因于光学像差，零分离也不足以证明整个峰形对称。后续典型实测峰用于说明这些区别，不改变本文固定参数的比较范围。

**English**

The FWHM center represents the geometric center of the profile at half maximum, not the energy center of the entire peak. If a one-sided tail lies predominantly below half maximum without substantially changing the peak height, crossings, or baseline, its direct effect on the FWHM center may be smaller than its effect on the centroid. This is conditional feature selectivity, not general immunity to asymmetry or neighboring-line interference. FWHM differs from equivalent rectangular width, defined as peak area divided by peak height; the FWHM center is not termed an equivalent-rectangle center here.

The centroid in Eq. (10) is an intensity-weighted mean satisfying the first-moment balance in Eq. (10a). The balanced quantities are integrals of intensity multiplied by distance, not the two areas. A position dividing the area into equal halves is a median or equal-area bisector, distinct from the implemented Centroid. A tail affects the centroid through both intensity and distance, so even a weak distant tail may produce appreciable displacement. This first-moment interpretation agrees with common spectral-line localization terminology. [Spectral-line localization study](https://arxiv.org/abs/1809.10295)

Centroid–FWHM-center separation describes displacement of the overall intensity-balance position relative to the half-maximum geometric center. Under fixed window, baseline, and interpolation conditions, it can describe response asymmetry. However, nonzero separation does not uniquely identify optical aberration, and zero separation does not establish symmetry of the entire profile. Subsequent measured examples will illustrate these distinctions without extending the study into parameter optimization.

### 3.4 峰位定义依赖及其定标表达 / 3.3 Definition Dependence and Its Calibration Representation

**中文**

第$n$条谱线在定义$i$与$j$之间的位置差为


$$
\Delta p_{ij,n}=p_{i,n}-p_{j,n}.
\tag{11}
$$


其中，$\Delta p_{CF,n}$用于描述质心相对FWHM中心的偏移。该量包含不同算子对响应分布的差异性表征，不能单独等同于纯光学非对称性的唯一度量。将位置差与参考波长联系，可考察其是否存在波长相关结构；其物理解释仍需结合仪器响应和已固定的处理条件。

设定标样本集合为$S$，峰位定义为$k$，多项式阶次为$m$。对应经验模型记为


$$
\widehat\lambda=f_{k,S_{41}}^{(m)}(p_k)
=\sum_{r=0}^{m}a_{r,k,S}z^r,\qquad
z=\frac{p_k-\mu_{k,S}}{\sigma_{k,S}}.
\tag{12}
$$


其中，$\mu_{k,S}$和$\sigma_{k,S}$为本次训练坐标的均值与样本标准差。系数由最小二乘拟合得到，每次改变训练集合时重新计算中心化和缩放参数。

本文的模型条件由$(k,m,S)$共同确定。固定$S$而比较$k$或$m$，分别考察位置定义和模型复杂度的作用；将模型应用于另一种定义得到的坐标，则进一步引入应用定义这一条件。该表述使“使用何种位置建立模型”与“使用何种位置读取波长”能够明确区分。

更一般地，本文可将定标过程写为条件化逆映射


$$
\widehat{\lambda}=f\!\left(T_k[H;\boldsymbol{\theta}];m,\boldsymbol a,S\right),
\tag{12a}
$$


其评价结果进一步取决于应用算子$T_j$及验证方案$V$：


$$
\mathcal E=\mathcal E(T_k,T_j,m,S,V).
\tag{12b}
$$


这里，$T_k$规定观测表示，$m$规定模型空间中的复杂度，$\boldsymbol a$为由样本$S$估计的参数，$V$规定误差的评价方式。因此，定标精度不是一组多项式系数脱离条件后的固有属性，而是观测定义、模型、参数、样本和评价条件共同作用的结果。

**English**

For line n, the separation between definitions i and j is expressed by Eq. (11), Δp_ij,n = p_i,n − p_j,n. In particular, Δp_CF,n describes the centroid displacement relative to the FWHM center. This quantity characterizes the different responses of two operators to the measured profile; it is not, by itself, a unique measure of purely optical asymmetry. Relating positional differences to reference wavelength allows wavelength-dependent structure to be examined, while its physical interpretation must account for instrumental response and the fixed processing conditions.

Let S be the calibration set, k the position definition, and m the polynomial order. The empirical model f_k,S^(m) is expressed in Eq. (12) as a polynomial in the centered and scaled coordinate z. The centering parameter μ_k,S and scale σ_k,S are the mean and sample standard deviation of the training coordinates for that fit. Coefficients are obtained by least squares, and the centering and scaling parameters are recomputed whenever the training set changes.

Model conditions are thus specified jointly by (k, m, S). With S fixed, comparisons across k or m examine position definition and model complexity, respectively. Applying a model to coordinates obtained using another definition introduces an additional application condition. This representation explicitly distinguishes the positions used to construct a model from those used to read out wavelengths.

More generally, Eq. (12a) represents calibration as a conditional inverse mapping. The operator $T_k$ specifies the observational representation, $m$ specifies complexity within the model space, $\boldsymbol a$ contains parameters estimated from sample set $S$, and $\boldsymbol\theta$ records the position-processing conditions. Equation (12b) further makes the assessed error dependent on the application operator $T_j$ and validation procedure $V$. Calibration accuracy is consequently not an intrinsic property of a set of polynomial coefficients detached from its conditions; it is the joint result of observation definition, model, parameters, samples, and assessment procedure.

### 3.5 拟合、留一验证与删除敏感性 / 3.4 Fitting, Leave-One-Out Validation, and Deletion Sensitivity

#### 3.5.1 拟合误差与留一验证 / 3.4.1 Fitting Error and Leave-One-Out Validation

**中文**

对于训练集合$S$中的第$n$条谱线，残差统一定义为参考波长减去预测波长：


$$
e_{k,n}^{\mathrm{fit}}=\lambda_n^{\mathrm{ref}}-f_{k,S_{41}}^{(m)}(p_{k,n}),\qquad
R_{\mathrm{fit}}=\sqrt{\frac{1}{|S|}\sum_{n\in S}(e_{k,n}^{\mathrm{fit}})^2}.
\tag{13}
$$


留一验证每次从训练集合中移除一条物理谱线，使用剩余样本重新拟合，再预测被移除谱线的位置：


$$
e_{k,n}^{\mathrm{LOO}}=\lambda_n^{\mathrm{ref}}-
f_{k,S_{-n}}^{(m)}(p_{k,n}),\qquad
R_{\mathrm{LOO}}=\sqrt{\frac{1}{|S|}\sum_{n\in S}(e_{k,n}^{\mathrm{LOO}})^2}.
\tag{14}
$$


同时记录最大绝对残差，以区分总体均方表现与个别谱线的大误差。拟合与留一误差之间的差值定义为


$$
G=R_{\mathrm{LOO}}-R_{\mathrm{fit}}.
\tag{15}
$$


$G$具有nm单位，不取绝对值，也不归一化。它用于描述两种误差指标的分离程度，而不作为独立的真实应用误差估计。

**English**

For line n in training set S, the residual is consistently defined as reference wavelength minus predicted wavelength. Equation (13) defines the fitting residual and its root-mean-square error R_fit over S.

LOO validation removes one physical line at a time, refits the model using the remaining samples, and predicts the wavelength at the withheld position. Equation (14) defines the corresponding withheld residuals and their aggregate R_LOO. Maximum absolute residuals are also retained to distinguish overall mean-square performance from large errors at individual lines.

The gap G between LOO and fitting RMSE is defined in Eq. (15) as R_LOO − R_fit. It is expressed in nm, without absolute-value transformation or normalization. It describes the separation between the two error measures and is not treated as an independent estimate of actual application error.

#### 3.5.2 删除样本后的曲线变化与相对LOO影响 / 3.4.2 Curve Change and Relative LOO Influence after Sample Deletion

**中文**

删除敏感性采用两个不同指标。第一个指标为删除第$n$条谱线前后，模型在完整分析集合$S_{41}$的原样本坐标上的最大差异：


$$
Q_{k,n}^{(m)}=\max_{r\inS_{41}}
\left|f_{k,S_{41}}^{(m)}(p_{k,r})-
f_{k,S_{-n}}^{(m)}(p_{k,r})\right|.
\tag{16}
$$


在41点阶次分析中，$S=S_{41}$为全部41点。$Q$单位为nm，表示指定离散评价位置上的曲线扰动，不等于整个连续波段上的严格最大变化。

第二个指标比较完整模型的LOO RMSE与删除样本后模型的LOO RMSE：


$$
I_{k,n}^{(m)}=\frac{|R_{\mathrm{LOO}}(S_{41})-R_{\mathrm{LOO}}(S_{-n})|}
{\max[R_{\mathrm{LOO}}(S_{41}),\varepsilon]},
\tag{17}
$$


其中，$\varepsilon$为防止零分母的数值保护量。计算$R_{\mathrm{LOO}}(S_{-n})$需要在删除后的集合上再次执行LOO，因而属于嵌套删除计算。$I$无量纲，反映总体LOO统计量对样本删除的相对敏感性。

阶次扫描中的平均、均方根、P95和最大影响均从$I$计算，而不是从$Q$计算。其中，影响P95采用按升序排列后第$\lceil0.95|S|\rceil$个值。$I$取绝对值后不保留误差改善或恶化的方向，必要时同时报告删除前后的LOO RMSE。由于删除前后评价样本集合也发生变化，较大的$I$不能直接证明某个样本测量错误；较小的$I$也不意味着模型具有较小的绝对误差。

本文在固定41点上扫描1–10次多项式，联合比较拟合、LOO、最大残差和删除敏感性。模型阶次不按单一指标机械确定，也不预先规定三次模型对每种定义均最优。三次作为后续跨定义与少点比较的共同低复杂度条件，其选择依据在结果部分给出。

**English**

Deletion sensitivity is described by two distinct quantities. The first, Q_k,n^(m), is the maximum absolute difference between the full and point-deleted model predictions at the original sample coordinates of the complete analysis set A, as defined in Eq. (16). In the 41-point order analysis, S = A comprises all 41 lines. Q is expressed in nm and measures curve perturbation at specified discrete evaluation positions, not a strict maximum over the entire continuous wavelength interval.

The second quantity, I_k,n^(m), compares the LOO RMSE of the full set with the LOO RMSE calculated after deleting line n, as defined in Eq. (17). The absolute difference is normalized by the full-set LOO RMSE, with ε providing protection against a zero denominator. Calculation of R_LOO(S without n) requires a further LOO analysis within the point-deleted set. This is therefore a nested deletion calculation. I is dimensionless and describes the relative sensitivity of an aggregate LOO statistic to sample deletion.

Mean, RMS, P95, and maximum influence in the order scan are calculated from I, not Q. Influence P95 is the value at rank ceil(0.95|S|) after ascending sorting. Taking the absolute value in I removes information on whether deletion increases or decreases the error; the original and point-deleted LOO RMSE values are therefore reported where necessary. Because deletion also changes the evaluation set, a large I does not by itself establish that a line was measured incorrectly. Conversely, a small I does not imply small absolute model error.

Polynomial orders from 1 to 10 are examined using the fixed 41-line set, considering fitting error, LOO, maximum residuals, and deletion sensitivity jointly. Order selection is not determined mechanically by one metric, and a third-order model is not assumed to be optimal for every definition. Third order is used as a common low-complexity condition in the subsequent cross-definition and sparse-calibration comparisons; its rationale is discussed with the results.

### 3.6 跨定义与共同参考样本集评价 / 3.5 Cross-Definition and Common-Reference-Set Assessment

#### 3.6.1 定标定义与应用定义的分离 / 3.5.1 Separating Calibration and Application Definitions

**中文**

设模型采用定义$i$和训练集合$S$建立，应用时使用定义$j$给出的坐标。在评价集合$E$上，残差为


$$
e_{ij,n}^{(m,S)}=\lambda_n^{\mathrm{ref}}-
f_{i,S}^{(m)}(p_{j,n}),\qquad n\in E.
\tag{18}
$$


取$i,j\in\{D,I,F,C\}$，得到4×4评价矩阵。矩阵行表示定标定义，列表示应用定义；对角元素描述同定义条件下的表现，非对角元素描述跨定义使用时的表现。矩阵一般不对称，也不具有对角元素必然最小的数学性质。

为了使各元素具有相同样本基础，本文采用四种定义均有效的共同物理谱线集合。对于同一训练方案，四个定标模型采用相同谱线ID，仅峰位坐标随定义改变。本文既有跨定义图采用一次拟合后在固定集合上评价的方式（Full fit），应与逐条留出的LOO模式区别。

若采用跨定义LOO，则按同一物理谱线同步删除训练样本，其残差写为


$$
e_{ij,n}^{\mathrm{LOO}}=\lambda_n^{\mathrm{ref}}-
f_{i,S_{-n}}^{(m)}(p_{j,n}),\qquad n\in S.
\tag{19}
$$


式（19）说明LOO所评价的是训练集合中的逐条留出谱线；不能将5点模型的LOO称为对全部41点的留一验证。是否报告该模式的结果，以实际分析记录为准，不将软件支持的功能视为已经实施的实验。

**English**

Suppose a model is constructed using definition i and training set S, but is applied to coordinates obtained using definition j. Equation (18) defines its residuals on evaluation set E as reference wavelength minus the prediction f_i,S^(m)(p_j,n).

For i,j ∈ {D,I,F,C}, these evaluations form a 4 × 4 matrix. Rows indicate the calibration definition and columns the application definition. Diagonal entries describe within-definition performance, while off-diagonal entries describe cross-definition use. The matrix is generally asymmetric, and there is no mathematical requirement that its diagonal entries be minimal.

To provide identical sample support for all entries, the common set of physical lines with valid positions under all four definitions is used. For a given training scheme, the four calibration models use the same line identifiers, with only the position coordinates changing by definition. The existing cross-definition figures use models fitted once and evaluated on a fixed set, referred to as Full fit. This mode must be distinguished from line-by-line LOO evaluation.

In cross-definition LOO, the same physical line is removed from the training set across definitions, and its application coordinate is used for prediction, as specified in Eq. (19). This procedure evaluates withheld lines belonging to the training set; LOO of a five-point model is not LOO validation over all 41 lines. Whether results from this mode are reported must follow the actual analysis record. Availability of a software function is not evidence that the corresponding experiment has been performed.

#### 3.6.2 误差指标与统计口径 / 3.5.2 Error Metrics and Statistical Conventions

**中文**

对任一确定条件下的残差集合$\{e_n\}_{n\in E}$，令$N_E=|E|$，计算


$$
\mathrm{RMSE}=\sqrt{\frac1{N_E}\sum_{n\in E}e_n^2},\qquad
\mathrm{Bias}=\frac1{N_E}\sum_{n\in E}e_n,
\tag{20}
$$



$$
\mathrm{STD}=\sqrt{\frac1{N_E}\sum_{n\in E}(e_n-\mathrm{Bias})^2},\qquad
\mathrm{MAX}=\max_{n\in E}|e_n|.
\tag{21}
$$


跨定义评价的STD采用分母$N_E$，因此满足$\mathrm{RMSE}^2=\mathrm{STD}^2+\mathrm{Bias}^2$。该统计口径不同于软件部分单模型输出中采用$N_E-1$归一化的样本标准差，二者不混用。

P95取绝对残差的95百分位。跨定义模块将排序后绝对残差在位置$1+0.95(N_E-1)$处进行线性插值；其实现与第3.4节影响P95的最近排序值不同。为描述残差的线性波长趋势，进一步拟合


$$
e_n=\alpha\lambda_n^{\mathrm{ref}}+\beta+\eta_n,
\tag{22}
$$


并以$\alpha$作为Slope。波长和残差均以nm计时，其单位可写为nm/nm。Slope仅描述线性趋势，不能代替对非线性残差结构的检查。上述指标分别用于表述总体误差、偏置、散布、尾部误差及波长趋势；不将任何一个指标单独等同于完整的测量不确定度。

**English**

For residuals obtained under specified conditions on E, with N_E = |E|, RMSE and Bias are defined in Eq. (20). The population-normalized STD and maximum absolute residual MAX are defined in Eq. (21).

The cross-definition module uses N_E in the STD denominator, giving RMSE² = STD² + Bias². This differs from the sample standard deviation normalized by N_E − 1 in some individual-model outputs. These conventions are not used interchangeably.

P95 denotes the 95th percentile of absolute residuals. The cross-definition module calculates it by linear interpolation at rank 1 + 0.95(N_E − 1) in the sorted absolute residuals. This implementation differs from the order-statistic convention used for influence P95 in Section 3.4. To describe a linear wavelength trend, residuals are regressed against reference wavelength according to Eq. (22), with α reported as Slope. When residual and wavelength are both expressed in nm, its units may be written as nm/nm.

Slope describes only a linear trend and does not replace inspection of nonlinear residual structure. Together, these metrics characterize overall error, bias, dispersion, tail behavior, and wavelength trend. No individual metric is equated with a complete measurement-uncertainty assessment.

#### 3.6.3 41点与稀疏定标模型的可比评价 / 3.5.3 Comparable Assessment of Full and Sparse Calibration Models

**中文**

完整定标集合记为$S_{41}$，包含41条参考谱线。分别构造$S_{41}=S_{41}$、$S_9\subsetS_{41}$和$S_5\subsetS_{41}$三个训练方案。在固定三次模型条件下，以相同$E=S_{41}$计算式（18）及相应指标，使不同训练方案面向同一组参考对象进行比较。

5点方案代表本研究选取的最小稀疏案例：三次多项式有4个系数，5点完整拟合具有1个残差自由度，LOO每次保留4点，在坐标互异时可确定三次多项式。但这并不保证良好的稳定性，也不能推广为任何仪器定标都充分的最小样本数。9点方案作为10点以内较大样本量的代表，与人工选峰定标的使用习惯相联系；它不是经过全局优化证明的最佳点数。

[作者补充A2：说明5点与9点的具体谱线确认过程及配置理由；本文不展开自动或全局最优选样算法。]

共同41点评价的目的在于保持评价对象一致，提高模型间比较的可解释性。它包含训练点，因此本文将其称为“共同参考样本集评价”，不称为独立外部验证。对于41点模型，对角元素对应其训练集误差；对于5点或9点模型，相应评价同时包含被选中和未被选中的谱线。两类模型比较时必须同时报告训练样本数和评价样本数，避免用统一的矩阵形式掩盖其不同训练条件。

此外，5点与9点集合的变化同时涉及样本数量和波长配置，其结果用于比较具体稀疏定标案例，不能据此将误差变化完全归因于样本数量。41点集合本身也经过人工质量审查，因此本文的评价结论以该数据构建过程和固定处理条件为适用背景，不将条件化LOO或共同集合误差解释为未经筛选谱线、其他仪器或独立测量批次上的普遍精度。

由此，波长误差应在明确条件下报告，即定标定义、应用定义、模型阶次、训练集合和评价方式的共同结果。后续结果章节围绕这些条件展开，并进一步讨论在固定单模型与定义对应多模型两种使用方式下的选择依据。

**English**

Let A denote the complete set of 41 reference lines. Three training schemes are considered: S_41 = A, S_9 ⊂ A, and S_5 ⊂ A. At a fixed polynomial order of three, Eq. (18) and the associated metrics are evaluated on the same set E = A, providing a common reference basis for comparing the training schemes.

The five-point scheme represents the smallest sparse case selected for this study. A cubic polynomial has four coefficients; fitting five points leaves one residual degree of freedom, while each LOO fit retains four points, sufficient to determine a cubic polynomial when the coordinates are distinct. This does not ensure adequate stability and does not establish a universally sufficient minimum sample count for instrument calibration. The nine-point scheme represents a larger case below ten points, reflecting practical manual line-selection habits rather than a globally optimized sample count.

[Author input A2: describe the actual confirmation and configuration rationale for the five- and nine-point subsets. Automatic or globally optimal sample-selection algorithms are outside the scope of this paper.]

Evaluation on the common 41-line set is intended to improve comparability by keeping the evaluation objects unchanged. Because this set includes training lines, the procedure is termed common-reference-set assessment rather than independent external validation. For the 41-point models, diagonal entries correspond to training-set errors; for five- and nine-point models, evaluation includes both selected and unselected lines. Both training and evaluation sample counts must therefore be reported, so that a common matrix format does not obscure the different training conditions.

Furthermore, the five- and nine-point schemes differ in both sample number and wavelength configuration. Their results compare specified sparse-calibration cases and cannot attribute error changes solely to sample count. The complete 41-line set itself has undergone manual quality review. Conclusions are therefore conditional on this dataset-construction process and the fixed processing conditions; neither conditional LOO nor common-set error is interpreted as universal accuracy for unreviewed lines, other instruments, or independent measurement batches.

Wavelength error should consequently be reported under explicit conditions: calibration definition, application definition, model order, training set, and assessment procedure. The following results are organized around these conditions and provide the basis for discussing fixed single-model and definition-specific multi-model use.

## 4 结果 / Results

## 4.1 峰位差异及其波长依赖 / Peak-Position Differences and Their Wavelength Dependence

> **五层框架中的位置 / Role in the five-space framework：** 本节主要考察表征空间 $\mathcal{X}$ 的内部结构，即同一物理谱线经不同 $T_k$ 得到的 $p_{k,n}$ 是否等价，以及 $\Delta p_{ij}(\lambda)$ 是否具有系统性波长依赖。 / This section examines the internal structure of the representation space $\mathcal{X}$, asking whether the positions generated by different $T_k$ are equivalent and whether $\Delta p_{ij}(\lambda)$ exhibits systematic wavelength dependence.

**中文**

在相同41条参考谱线和已固定的逐峰处理条件下，四种定义获得了不同的像素位置。以FWHM中心为参照，Direct、Interpolated和Centroid的位置差范围及均方根值列于表1。这里的差值表示定义之间的位置分离，而不是相对于独立真实位置的定位误差。

**English**

The four definitions yielded different pixel coordinates for the same 41 reference lines under fixed per-line processing conditions. Table 1 summarizes the ranges and root-mean-square values of Direct, Interpolated, and Centroid positions relative to the FWHM center. These differences describe separation between definitions, not localization errors relative to an independently known true position.

**表1 / Table 1. 相对FWHM中心的位置差 / Position differences relative to the FWHM center. N = 41; pixel units.**

| 差值 / Difference | 最小值 / Minimum | 最大值 / Maximum | 均方根 / RMS |
|---|---:|---:|---:|
| Direct − FWHM center | −0.542007 | 0.483011 | 0.294043 |
| Interpolated − FWHM center | −0.187148 | 0.186524 | 0.103439 |
| Centroid − FWHM center | −0.196941 | 0.299384 | 0.146816 |

**中文**

Direct相对FWHM中心的分离幅度最大，差值在正负方向均有分布。该结果与整数采样最大值和亚像素半高中心所描述位置不同相一致，但不能把每一个差值都解释为理想条件下的纯量化误差。由于FWHM中心并非已知的真实峰顶，Direct与其差值也不受一个严格的±0.5像素界限约束。

插值峰位与FWHM中心之间的均方根差值较小，但仍为0.103439像素，表明使用亚像素处理并不会使不同定义自动收敛到同一个位置。质心与FWHM中心的分离具有更明显的波段结构：在500 nm以下的13条谱线中，12条的质心位于FWHM中心的较小像素坐标一侧；在800 nm以上的12条谱线中，全部表现为正偏移。中间波段包含正负交替及局部偏离，因此该变化不应概括为严格单调关系，也不应由这两个描述性分区推导统计显著性。

例如，280.3466 nm处的质心相对FWHM中心偏移约−0.196941像素，而1067.3565 nm处约为+0.299384像素。365.0153 nm处在较短波段中表现出正偏移，说明总体波段结构并不排除个别谱线的不同响应。这些谱线均属于已确认的分析集合，本节不根据位置差重新筛选它们。

上述结果说明，在本仪器和处理条件下，不同峰位定义之间的差异包含波长相关结构，而不仅是围绕同一坐标的无方向散布。该现象与不同算子对有限采样和响应形状的差异性表征相一致；它本身不能单独确定具体像差，也不能建立哪一种位置为绝对物理真值。后续分析因此分别使用各定义建立定标关系，并检验这些关系在自身及其他定义下的表现。

[拟Fig.2：41点峰位差随参考波长的变化；典型单峰图待作者补充。表中保留较多小数仅用于数值核对，不表示相应测量不确定度。]

**English**

Direct positions exhibited the largest separation from the FWHM center, with differences of both signs. This is consistent with the distinct positions represented by an integer-sample maximum and a subpixel half-maximum center, but individual differences cannot all be interpreted as pure quantization error under ideal conditions. Because the FWHM center is not an independently known true maximum, its difference from the Direct position is not subject to a strict ±0.5-pixel bound.

The RMS separation between Interpolated positions and FWHM centers was smaller, but remained 0.103439 pixel, demonstrating that subpixel processing does not automatically make different definitions converge to one coordinate. Centroid–FWHM-center separation showed a more pronounced wavelength structure: 12 of the 13 lines below 500 nm had centroids at smaller pixel coordinates than their FWHM centers, whereas all 12 lines above 800 nm exhibited positive shifts. The intermediate region contained changes of sign and local departures. The pattern should therefore not be described as strictly monotonic, nor should these descriptive wavelength groups be used to infer statistical significance.

For example, the centroid displacement relative to the FWHM center was approximately −0.196941 pixel at 280.3466 nm and +0.299384 pixel at 1067.3565 nm. The line at 365.0153 nm exhibited a positive displacement within the shorter-wavelength region, illustrating that an overall wavelength pattern does not exclude individual departures. These lines remain members of the confirmed analysis set; they were not reselected on the basis of positional differences in this section.

Under the present instrumental and processing conditions, differences among position definitions therefore contain wavelength-related structure, rather than only directionless scatter around one coordinate. This behavior is consistent with different operators responding differently to finite sampling and response shape. It does not, by itself, identify a particular aberration or establish an absolute positional ground truth. The following analyses consequently construct separate calibration relationships for each definition and examine their performance with both matching and alternative application definitions.

[Proposed Fig. 2: position differences for the 41 lines versus reference wavelength; representative single-peak profiles remain to be supplied by the author. The numerical precision in the table facilitates computational checking and does not imply corresponding measurement uncertainty.]

## 4.2 多项式阶次与定标可靠性 / Polynomial Order and Calibration Reliability

> **五层框架中的位置 / Role in the five-space framework：** 本节在函数空间 $\mathcal{F}$ 中改变多项式阶次 $m$，并观察候选模型在特性空间 $\mathcal{C}$ 中的拟合、泛化和样本影响坐标如何变化。 / This section varies polynomial order $m$ in the function space $\mathcal{F}$ and tracks the resulting fitting, generalization, and sample-influence characteristics in $\mathcal{C}$.

### 4.2.1 拟合与LOO的阶次响应 / Order Dependence of Fitting and LOO Errors

**中文**

在固定41点上进行1–10次扫描时，四种定义均从低阶模型到三次模型出现明显误差下降。三次之后，拟合误差和LOO误差的变化不再一致，且不同定义之间存在差别。表2列出三、四、五次的主要指标；完整阶次曲线用于判断表内比较是否代表全扫描最优。

**English**

In the order-1–10 scan on the fixed 41-line set, all four definitions showed a marked error reduction from low-order to cubic models. Beyond third order, fitting and LOO errors did not change in the same way, and their responses differed among definitions. Table 2 presents the principal metrics for orders three, four, and five; the complete order curves establish whether comparisons within this range also identify the minimum over the full scan.

**表2 / Table 2. 固定41点的拟合、LOO及删除敏感性 / Fitting, LOO, and deletion sensitivity for the fixed 41-line set.**

| 定义 / Definition | 阶次 / Order | Fit RMSE (nm) | LOO RMSE (nm) | Mean I (%) | Max I (%) | Max Q (nm) |
|---|---:|---:|---:|---:|---:|---:|
| Direct | 3 | 0.119791 | 0.130976 | 1.187 | 4.256 | 0.050665 |
| Direct | 4 | 0.118755 | 0.132770 | 1.107 | 3.376 | 0.043270 |
| Direct | 5 | 0.118656 | 0.136818 | 1.221 | 5.084 | 0.047970 |
| Interpolated | 3 | 0.041070 | 0.046533 | 1.398 | 7.127 | 0.036308 |
| Interpolated | 4 | 0.036007 | 0.041388 | 1.405 | 7.733 | 0.023971 |
| Interpolated | 5 | 0.034920 | 0.041667 | 1.907 | 18.344 | 0.029129 |
| FWHM center | 3 | 0.025356 | 0.030248 | 1.871 | 12.384 | 0.034756 |
| FWHM center | 4 | 0.017771 | 0.021736 | 2.232 | 34.966 | 0.023018 |
| FWHM center | 5 | 0.017529 | 0.022593 | 2.319 | 35.057 | 0.031629 |
| Centroid | 3 | 0.037357 | 0.044163 | 1.714 | 11.335 | 0.055129 |
| Centroid | 4 | 0.033078 | 0.040055 | 2.428 | 27.116 | 0.046349 |
| Centroid | 5 | 0.030037 | 0.036492 | 1.871 | 24.479 | 0.028024 |

**中文**

Direct的LOO RMSE在三次时达到全扫描最低值0.130976 nm。升至四次、五次时，Fit RMSE仅小幅下降，而LOO RMSE分别增至0.132770和0.136818 nm。因而，对于该定义，继续提高阶次并未改善留出预测表现。

Interpolated的四次LOO RMSE较三次下降约11.06%，五次则比四次略高。完整扫描的最低值出现在六次，为0.040866 nm，比四次低约1.26%。六次的最大相对删除影响也低于四次，因此不能将四次描述为在所有评价指标上占优；其较低复杂度与六次的有限误差改善构成不同选择条件下的取舍。

FWHM中心的四次模型达到全扫描最低LOO RMSE，为0.021736 nm，较三次的0.030248 nm下降约28.14%。五次虽然继续降低拟合误差，但LOO RMSE回升至0.022593 nm。质心的最小LOO RMSE出现在五次，为0.036492 nm，较三次下降约17.37%。这些结果表明，三次之后的误差改善具有定义依赖性，不能把四次或五次模型一概归为不必要的高阶拟合。

在三、四、五次的同定义比较中，FWHM中心的LOO RMSE均低于其他三种定义。但这一结果仅描述本数据集的同定义条件，尚不回答该模型输入其他峰位坐标时的误差。

**English**

For Direct positions, the lowest LOO RMSE over the full scan occurred at third order, at 0.130976 nm. Increasing the order to four or five produced only small decreases in Fit RMSE, while LOO RMSE increased to 0.132770 and 0.136818 nm, respectively. Additional polynomial order therefore did not improve withheld prediction performance for this definition.

For Interpolated positions, fourth-order LOO RMSE was approximately 11.06% below the cubic value, while fifth order was slightly worse than fourth. The minimum over the complete scan occurred at sixth order, at 0.040866 nm, approximately 1.26% below fourth order. Sixth order also had lower maximum relative deletion influence than fourth order. Fourth order consequently cannot be described as superior on every metric; its lower complexity and the limited additional error reduction at sixth order represent a choice dependent on the intended criteria.

For FWHM centers, the fourth-order model achieved the lowest LOO RMSE in the scan, 0.021736 nm, approximately 28.14% below the cubic value of 0.030248 nm. Although fifth order further reduced fitting error, its LOO RMSE increased to 0.022593 nm. For Centroid positions, the minimum LOO RMSE occurred at fifth order, at 0.036492 nm, approximately 17.37% below third order. Error improvements beyond a cubic model were therefore definition-dependent; fourth- and fifth-order fits cannot uniformly be dismissed as unnecessary higher-order fitting.

Among the within-definition comparisons at orders three, four, and five, FWHM centers yielded lower LOO RMSE than the other three definitions. This result concerns within-definition performance on the present dataset and does not yet establish the error obtained when the model is supplied with alternative position coordinates.

[拟Fig.3 / Proposed Fig.3: four-definition Fit/LOO order scans; preserve the complete order range and distinguish the common cubic baseline from each definition’s minimum.]

### 4.2.2 相对影响与绝对扰动并不等价 / Relative Influence and Absolute Perturbation Are Not Equivalent

**中文**

删除分析揭示了均方误差以外的差异。以FWHM中心为例，三次升至四次后，最大相对LOO影响I从12.384%增至34.966%，但最大曲线变化Q由0.034756降至0.023018 nm。与此同时，最大绝对LOO残差从0.084969增至0.095133 nm。四次模型因而同时表现为较低的总体LOO误差、较低的最大离散曲线扰动，以及较高的单点最大残差和最大相对影响，不能简单概括为所有稳定性指标均变好或均变差。

主导影响的谱线也随阶次变化。FWHM三次模型的最大I来自P062（1047.0054 nm）；删除后LOO RMSE由0.030248升至0.033993 nm。四次模型的最大I则来自P003（265.3679 nm），删除后LOO RMSE由0.021736降至0.014136 nm。两者的误差变化方向不同，而I的绝对值形式不保留这一方向。

这些结果用于说明模型对具体样本的依赖，不据此重新判定样本是否有效。删除前后LOO所评价的集合分别为41点和40点，误差降低不能单独证明被删除样本错误。类似地，跨定义比较I时还需注意分母中的完整模型LOO误差不同；Direct具有较小的相对影响，并不意味着它具有更好的绝对定位或定标精度。

**English**

Deletion analysis revealed differences not captured by mean-square error alone. For FWHM centers, increasing the order from three to four raised maximum relative LOO influence I from 12.384% to 34.966%, while reducing maximum curve change Q from 0.034756 to 0.023018 nm. At the same time, the maximum absolute LOO residual increased from 0.084969 to 0.095133 nm. The fourth-order model thus combined lower aggregate LOO error and lower maximum discrete curve perturbation with a larger worst-case withheld residual and larger maximum relative influence. It cannot be characterized simply as improving or worsening every stability measure.

The line dominating relative influence also changed with order. For the cubic FWHM-center model, the largest I was associated with P062 at 1047.0054 nm; its deletion increased LOO RMSE from 0.030248 to 0.033993 nm. For the fourth-order model, the largest I was associated with P003 at 265.3679 nm; its deletion reduced LOO RMSE from 0.021736 to 0.014136 nm. The directions of change differed, but the absolute-value definition of I does not retain that distinction.

These findings characterize model dependence on particular samples and were not used to revise sample validity. The LOO evaluation sets before and after deletion contain 41 and 40 lines, respectively; a reduction in error does not independently establish that the omitted line is incorrect. Comparisons of I across definitions must also account for the different full-model LOO errors in its denominator. The relatively small influence ratios for Direct positions do not imply better absolute localization or calibration accuracy.

[拟Fig.4 / Proposed Fig.4: influence across orders and sample-wise sensitivity; retain I and Q as distinct metrics.]

### 4.2.3 共同三次基线与各定义最优阶次 / A Common Cubic Baseline versus Definition-Specific Optima

**中文**

综合以上结果，三次模型适合作为后续受控比较的共同低复杂度基线：它保留了从一、二次模型到三次的主要误差改善，同时允许在固定阶次下考察峰位定义与训练集合的影响。这一安排不意味着放弃四次、五次或六次模型的潜在价值，也不意味着三次是各定义分别优化后的答案。后续跨定义分析首先固定三次，以避免将阶次差异与应用定义差异混合；实际模型选择再联合精度要求、复杂度和应用读出方式讨论。

**English**

Taken together, these results support a cubic model as a common low-complexity baseline for subsequent controlled comparisons. It retains the principal error reduction from first- and second-order models while allowing position definition and training-set effects to be examined at a fixed order. This choice does not dismiss the potential value of fourth-, fifth-, or sixth-order models, nor does it identify third order as the separately optimized solution for every definition. Cross-definition assessment initially fixes third order to avoid confounding polynomial order with application definition; practical model selection is subsequently discussed in terms of accuracy requirements, complexity, and readout method.

## 4.3 41点三次模型的跨定义表现 / Cross-Definition Performance of the 41-Point Cubic Models

> **五层框架中的位置 / Role in the five-space framework：** 本节研究模型特性空间 $\mathcal{C}$ 中的表征兼容性：用表征 $i$ 建立的模型 $f_i$ 在输入表征 $j$ 的位置 $p_j$ 时产生怎样的误差结构。 / This section examines representation compatibility in $\mathcal{C}$: the error structure obtained when a model $f_i$ calibrated in representation $i$ is applied to positions $p_j$ from representation $j$.

### 4.3.1 同定义误差与跨定义矩阵 / Within-Definition Error and the Cross-Definition Matrix

**中文**

四个三次模型分别由同一41条谱线的四种位置坐标建立，并在全部41条参考线上交叉评价。表3给出RMSE矩阵；训练和评价集合相同，模式为Full fit，因而对角元素为训练集上的同定义误差，不是LOO误差。

**English**

Four cubic models were constructed using the respective position coordinates of the same 41 lines and cross-evaluated on all 41 reference lines. Table 3 presents the RMSE matrix. The training and evaluation sets are identical, and the mode is Full fit. Its diagonal entries are therefore within-definition training errors, not LOO errors.

**表3 / Table 3. Cross-definition RMSE (nm), N_train = N_eval = 41, m = 3. Rows: calibration; columns: application.**

| 定标↓ 应用→ / Calibration↓ Application→ | Direct | Interpolated | FWHM center | Centroid |
|---|---:|---:|---:|---:|
| Direct | 0.119791 | 0.047366 | 0.054920 | 0.102855 |
| Interpolated | 0.122093 | 0.041070 | 0.041094 | 0.091771 |
| FWHM center | 0.129321 | 0.052273 | 0.025356 | 0.066725 |
| Centroid | 0.153406 | 0.093331 | 0.060817 | 0.037357 |

**中文**

对角元素与第4.2节的三次Fit RMSE一致，其中FWHM中心最小，Direct最大。然而，对角值并非在每一行均为最小：Direct模型应用于Interpolated坐标时的误差低于其应用于Direct坐标时的误差。这一例子说明，矩阵不能简单解释为“定义一致必然最优”，而应按具体定标—应用组合比较。

另一方面，对于各固定应用定义，本例表3中的最低RMSE均位于相应的同定义组合。该现象是当前数据和三次条件下的结果，不作为矩阵的一般数学性质。行内比较回答“同一个模型输入不同坐标会怎样”，列内比较回答“读出方法固定后应比较哪些定标模型”，二者应加以区分。

**English**

The diagonal entries agree with the cubic Fit RMSE values in Section 4.2, with the smallest value for FWHM centers and the largest for Direct positions. However, the diagonal is not the minimum in every row: the Direct-calibrated model has lower error when applied to Interpolated coordinates than to Direct coordinates. The matrix therefore cannot be reduced to a claim that matching definitions must always be optimal; specific calibration–application combinations must be compared.

For each fixed application definition, the smallest RMSE in Table 3 does occur at the corresponding within-definition combination. This is a result for the current dataset and cubic models, not a general mathematical property. Row-wise comparisons ask how one model behaves with different coordinate definitions, whereas column-wise comparisons ask which calibration models should be considered for a fixed readout method. These questions must be distinguished.

### 4.3.2 Direct读出下的模型兼容性 / Model Compatibility for Direct Readout

**中文**

当应用端固定使用Direct坐标时，Direct、Interpolated、FWHM中心和Centroid定标模型的RMSE分别为0.119791、0.122093、0.129321和0.153406 nm。FWHM→Direct比Direct→Direct高约0.009530 nm，即约7.96%，二者处于相近量级，但数值并不相等。

因此，这组结果支持考察亚像素定标模型用于Direct读出的可行性，却不能在缺少应用容差的情况下宣称二者精度等效。是否接受约0.009530 nm的RMSE差异，应结合具体误差要求及模型还需支持哪些读出定义确定。反过来，Direct定标模型在FWHM应用下的RMSE为0.054920 nm，明显高于FWHM→FWHM的0.025356 nm，说明保留整数坐标建立模型会限制其在该亚像素读出组合中的表现。

**English**

With Direct coordinates fixed as the application readout, RMSE values for Direct-, Interpolated-, FWHM-center-, and Centroid-calibrated models were 0.119791, 0.122093, 0.129321, and 0.153406 nm, respectively. FWHM→Direct exceeded Direct→Direct by approximately 0.009530 nm, or 7.96%. Their errors were of similar magnitude, but were not numerically equal.

These results motivate considering subpixel-calibrated models for Direct readout, but do not establish accuracy equivalence without an application tolerance. Acceptance of an approximately 0.009530 nm difference in RMSE depends on the error requirement and the other readout definitions the model must support. Conversely, the Direct-calibrated model yielded 0.054920 nm when applied to FWHM-center positions, compared with 0.025356 nm for FWHM→FWHM. Calibration using integer coordinates therefore limited performance for this subpixel application combination.

### 4.3.3 FWHM中心与质心的交叉使用 / Cross-Use of FWHM-Center and Centroid Positions

**中文**

FWHM与质心之间的交叉使用表现出不同于其自身定标的误差结构。FWHM→Centroid的RMSE为0.066725 nm，高于Centroid→Centroid的0.037357 nm；Centroid→FWHM的RMSE为0.060817 nm，高于FWHM→FWHM的0.025356 nm。两个交叉方向分别具有约−0.018866和+0.018864 nm的Bias，其残差对参考波长的线性Slope分别约为−2.096×10⁻⁴和+2.096×10⁻⁴ nm/nm。

这些相反方向的偏置和趋势与第4.1节所见两种位置随波长的相对分离相一致。尽管两个方向的Bias近似相反，其RMSE并不相同，因此这种互换不是一个简单的对称误差关系。FWHM中心和质心描述同一响应中的不同位置特征，分别用它们建立的模型不能不加检验地互换使用。

同定义训练集的Bias接近零，主要是包含常数项的最小二乘拟合对训练残差的约束，不应将其单独作为绝对无偏或物理准确性的证据。跨定义残差则揭示了在改变输入位置算子后出现的偏置和趋势。本文由此区分同定义误差与跨定义兼容性，但不以矩阵判定哪一个算子给出了唯一真实峰位。

[拟Fig.5–6：跨定义矩阵与波长残差。当前数值由固定41点独立计算得到，正式图件版本和完整补充指标仍需后续对应核查。]

**English**

Cross-use of FWHM-center and Centroid positions produced error structures distinct from within-definition calibration. FWHM→Centroid yielded an RMSE of 0.066725 nm, compared with 0.037357 nm for Centroid→Centroid. Centroid→FWHM yielded 0.060817 nm, compared with 0.025356 nm for FWHM→FWHM. The two cross-directions had Bias values of approximately −0.018866 and +0.018864 nm, with linear residual slopes against reference wavelength of approximately −2.096 × 10⁻⁴ and +2.096 × 10⁻⁴ nm/nm, respectively.

These opposing biases and trends are consistent with the wavelength-dependent separation of the two position definitions in Section 4.1. Although the biases are approximately opposite, the RMSE values differ; interchange does not produce a simply symmetric error relationship. FWHM centers and centroids describe different positional features of the same response, and models constructed from them cannot be used interchangeably without assessment.

The near-zero Bias of within-definition training residuals primarily reflects the constraint imposed by least-squares fitting with an intercept. It is not independent evidence of absolute unbiasedness or physical accuracy. Cross-definition residuals instead expose bias and trends introduced when the input position operator changes. The matrix thus distinguishes within-definition error from cross-definition compatibility without identifying a unique true-position operator.

[Proposed Figs. 5–6: cross-definition matrices and wavelength-dependent residuals. The present values were independently calculated from the fixed 41-line inputs; correspondence with final figure versions and the complete supplementary metrics remains to be checked.]

## 4.4 稀疏定标下的跨定义比较 / Cross-Definition Comparison under Sparse Calibration

> **五层框架中的位置 / Role in the five-space framework：** 本节改变样本空间中的 $S_K$，以41点、9点和5点代表性配置考察样本数量与配置变化如何投影到模型特性空间，重点关注共同参考集误差和跨定义兼容性的变化。 / This section varies $S_K$ in the sample space and uses representative 41-, 9-, and 5-point configurations to examine how sample number and configuration are projected into common-set error and cross-definition compatibility in the model characteristic space.

> 编辑状态 / Editorial status: 本节已形成论述框架，但5/9点数值与对应图件尚未完成统一核对。以下显式占位在最终稿中必须补齐，不能将本节视为已完成的定量结果。 / The narrative framework is drafted, but numerical correspondence for the five- and nine-point models has not been fully checked. The explicit placeholders below must be resolved before this section is treated as a completed quantitative result.

### 4.4.1 共同评价集合下的模型对照 / Model Comparison on a Common Evaluation Set

**中文**

为考察较少参考线建立模型时的表现，以5点和9点作为代表性稀疏定标案例，保持三次模型不变，并在共同41条谱线上评价。这里并不将“点数减少”视为唯一变化因素，因为两个子集的波长配置也不同。比较的对象是明确的样本集合，而不是抽象的5点或9点模型总体。

[数据待核D2a：补入41/9/5点模型在共同41点评价下的四定义对角RMSE、必要的MAX，以及明确的训练/评价样本数。]

训练集残差用于说明模型对所选样本的拟合，而共同集合残差用于说明其在统一参考对象上的表现。少点模型即使对训练点拟合较好，也不意味着在全部41点上达到同等误差。因此，本节应以共同集合指标而不是不同大小训练集的Fit RMSE，作为模型间的主要对照。

[作者补充A2：5点、9点的样本确认过程及分布理由，最后补充，不在此展开最优选样。]

**English**

Five- and nine-point models are considered as representative sparse-calibration cases, with polynomial order fixed at three and assessment performed on the common 41-line set. Reduced sample count is not treated as the only changing factor because the subsets also differ in wavelength configuration. The objects of comparison are specified sample sets, not all possible five- or nine-point models.

[Numerical check pending D2a: insert within-definition RMSE values for the four definitions under 41-, nine-, and five-point training, evaluated on the common 41-line set, together with necessary MAX values and explicit training/evaluation counts.]

Training residuals characterize fitting to the selected samples, whereas common-set residuals characterize performance on the same reference objects. A sparse model may fit its training points closely without achieving comparable error over all 41 lines. The principal comparison should therefore use common-set metrics rather than Fit RMSE calculated on training sets of different sizes.

[Author input A2: add the confirmation process and configuration rationale for the five- and nine-point subsets at the final supplementation stage; optimal selection is not developed here.]

### 4.4.2 样本配置与定义兼容性的关系 / Sample Configuration and Definition Compatibility

**中文**

少点模型的跨定义矩阵应与41点基线保持相同的行列定义和评价对象，从而分别判断：同定义误差如何变化，跨定义附加误差如何变化，以及这种变化是否伴随偏置或波长相关残差。仅比较各自最小的RMSE，不能说明定义之间的兼容性关系是否保留。

[数据待核D2b：核对5/9点的Direct应用列及FWHM↔Centroid组合，给出相对41点基线的实际变化；不预设9点必然保持全部性能或5点必然在所有组合上更差。]

本节最终需要区分两个层次：一是当前样本配置是否保留了与41点基线相近的组合关系；二是即使相对关系相近，其绝对误差是否仍满足应用需要。这两个问题不能通过热图色彩相似或训练残差较小直接回答。

[拟Fig.7–8：样本分布、共同集合残差和跨定义矩阵。样本确认细节及定量结果补齐后，再据此完成本节结论，不开展新的选样算法研究。]

**English**

Sparse-model matrices should retain the same row and column definitions and evaluation objects as the 41-point baseline. This allows within-definition error, changes in cross-definition error, and associated bias or wavelength-dependent residuals to be examined separately. Comparing only the smallest RMSE in each case does not establish whether compatibility relationships among definitions are preserved.

[Numerical check pending D2b: verify the Direct-application column and FWHM↔Centroid combinations for the five- and nine-point models, reporting actual changes from the 41-point baseline. Do not assume that nine points preserve every performance measure or that five points are worse for every combination.]

The completed section must distinguish whether a given configuration retains relationships similar to those of the 41-point baseline from whether its absolute errors remain acceptable for the intended application. Neither question can be answered directly from similar heatmap colors or small training residuals.

[Proposed Figs. 7–8: sample configurations, common-set residuals, and cross-definition matrices. Conclusions for this section will be completed after the sample descriptions and numerical checks, without developing a new selection algorithm.]

---

## 5 讨论 / Discussion

### 5.0 从模型特性空间到模型选择 / 5.0 From Model Characteristic Space to Model Selection

**中文**

前述结果可统一理解为不同候选配置在模型特性空间 $\mathcal{C}$ 中的投影。峰位定义改变的是表征空间中的 $T_k$，多项式阶次改变的是函数空间中的 $m$，41点、9点和5点配置改变的是样本空间中的 $S_K$；每一组配置经拟合得到参数解后，均产生相应的性能、泛化、稳定性和兼容性特性。因此，本文所称的模型选择不是


$$
\arg\min RMSE_{\rm Fit},
$$


而是在多个特性坐标共同约束下比较候选模型。较低的Fit RMSE只有在LOO误差、Generalization Gap、删除影响以及应用定义兼容性同时可接受时，才构成支持提高模型复杂度的证据。相反，如果更高阶模型仅降低训练残差，却增加留出误差或样本影响，则其附加自由度不应自动解释为更高的有效定标精度。

这一闭环视角也解释了为什么本文不把三次多项式描述为所有峰位定义下的绝对最优阶次。三次模型在四种定义之间提供了共同的最低充分复杂度，并表现出较好的总体稳健性，因此适合作为跨定义比较的共同基线；对于部分亚像素定义，四次或更高阶次仍可进一步降低某些误差指标，但这种改善需要与泛化、样本影响和应用兼容性共同判断。

**English**

The preceding results can be interpreted as projections of different candidate configurations into the model characteristic space $\mathcal{C}$. Changing the peak-position definition changes $T_k$ in the representation space, changing polynomial order changes $m$ in the function space, and the 41-, 9-, and 5-point configurations change $S_K$ in the sample space. After fitting, each configuration produces a corresponding set of performance, generalization, stability, and compatibility characteristics. Model selection in this study is therefore not equivalent to minimizing $RMSE_{\rm Fit}$ alone. A reduction in fitting error supports increased model complexity only when leave-one-out error, generalization gap, deletion influence, and application-definition compatibility remain acceptable. Conversely, additional degrees of freedom that reduce training residuals while increasing held-out error or sample sensitivity should not automatically be interpreted as improved effective calibration accuracy.

This closed-loop view also explains why the cubic polynomial is not presented as the absolute optimum for every position definition. The cubic model provides a common minimum-sufficient complexity across the four definitions and shows favorable overall robustness, making it a useful common baseline for cross-definition comparison. For some subpixel definitions, fourth- or higher-order models can further reduce selected error measures, but such gains must be interpreted jointly with generalization, sample influence, and application compatibility.



### 5.1 峰位定义与阶次的联合选择 / Joint Selection of Position Definition and Polynomial Order

**中文**

本研究表明，峰位定义的选择不能与定标模型阶次的选择完全分离。四种位置来自同一组实测谱线，但其同定义LOO误差随阶次的变化不同。在1–10次扫描中，Direct、Interpolated、FWHM中心和Centroid的最低LOO RMSE分别出现在三、六、四和五次。因此，将所有定义统一为一个预设阶次有利于受控比较，却不等于完成了各定义的独立优化。

三次作为共同基线的价值在于简约和可比性，而不是普遍最优性。它保留了低阶至三次的主要误差改善，并允许在较少参数的条件下比较不同定义及样本集合。对于本数据集的Direct位置，升阶没有进一步降低LOO误差；对于FWHM中心，四次模型相对三次的LOO改善约28.14%，不能被忽略。对于Centroid，五次达到更低的LOO误差，说明较高阶模型可能有助于描述该定义下的经验位置—波长关系，而非必然仅拟合噪声。但仅凭LOO下降，也不能将增加的多项式项逐项解释为确定的光学像差或真实仪器结构。

模型选择还取决于对“较好”的具体定义。总体RMSE、最大单点误差、曲线扰动和相对删除影响并非同一目标。FWHM四次相对三次具有较低的LOO RMSE和最大Q，但其最大LOO残差和最大I较高。若应用主要关注总体均方表现，四次具有明确的数值优势；若对某些波长的最大误差特别敏感，则还应检查对应谱线和残差分布。不能把这些相反方向的变化压缩为一个未定义的“稳定性更好”或“稳定性更差”。

相对影响I还受到完整模型LOO误差这一分母的影响。Direct的相对影响较低，并不使其较高的绝对误差消失。因而，I适合用于识别模型对样本删除的敏感位置及其随阶次的变化，而不宜脱离绝对误差单独排序模型。对较高影响样本的诊断也应与独立的峰形和参考线证据结合，而不是为了使某个模型指标更小而继续删点。

据此，本文支持按顺序进行选择：首先明确应用读出定义与误差要求；然后在固定数据条件下考察候选定义及阶次的Fit、LOO和极端残差；最后结合删除敏感性及跨定义表现判断是否值得增加复杂度。这是基于多项证据的选择过程，而不是将一种峰位或一个阶次规定为所有仪器的默认最优解。

**English**

The results show that peak-position definition and polynomial order cannot be selected entirely independently. Although the four coordinate sets originate from the same measured lines, their within-definition LOO errors respond differently to polynomial order. Across orders 1–10, the lowest LOO RMSE occurred at orders three, six, four, and five for Direct, Interpolated, FWHM-center, and Centroid positions, respectively. A common prescribed order facilitates controlled comparison, but does not constitute separate optimization of each definition.

The value of a cubic baseline lies in parsimony and comparability, not universal optimality. It retains the principal improvement from lower-order models and permits comparisons among definitions and sample sets with relatively few parameters. For Direct positions in this dataset, increasing order did not further reduce LOO error. For FWHM centers, however, the approximately 28.14% reduction in LOO RMSE from third to fourth order cannot be disregarded. The lower LOO error obtained with fifth-order Centroid calibration likewise indicates that additional flexibility may help describe the empirical position–wavelength relationship for that definition, rather than necessarily fitting only noise. Nevertheless, a decrease in LOO error does not justify assigning individual additional polynomial terms to specific optical aberrations or physical instrument structures.

Model selection also depends on what constitutes better performance. Aggregate RMSE, the largest individual error, curve perturbation, and relative deletion influence are different objectives. Compared with the cubic FWHM-center model, fourth order had lower LOO RMSE and maximum Q, but higher maximum LOO residual and maximum I. Fourth order has a clear numerical advantage when aggregate mean-square performance is the main criterion. Applications particularly sensitive to the largest error at certain wavelengths must additionally examine the corresponding lines and residual distribution. Changes in opposite directions should not be compressed into an undefined claim of better or worse stability.

Relative influence I also depends on the full-model LOO error in its denominator. Smaller relative influence for Direct positions does not remove their larger absolute errors. I is therefore useful for identifying deletion-sensitive samples and changes with order, but should not rank models independently of absolute error. Diagnosis of highly influential samples should be supported by independent profile and reference-line evidence, rather than continued deletion solely to improve a chosen model metric.

These observations support a sequential choice: specify the application readout and error requirements; examine Fit, LOO, and extreme residuals for candidate definitions and orders under fixed data conditions; and then consider deletion sensitivity and cross-definition performance when deciding whether additional complexity is worthwhile. This is an evidence-based selection process, not a prescription of one universally optimal position definition or polynomial order.

#### 5.1.1 波长相关峰形与定义相关定标 / Wavelength-Dependent Profiles and Definition-Dependent Calibration

**中文**

上述阶次差异需要放在谱线响应的形成过程内理解。阵列光谱仪将不同波长同时成像在探测器的不同位置，需要在一定谱段和像面范围内协调成像质量。CT结构中的离轴像差和场曲可使响应宽度及非对称性随波长变化，例如彗差可表现为谱线一侧的展宽。扫描单色仪通过固定出射狭缝读出选定波长，与平面阵列同时覆盖较宽像场面临不同约束。但这不意味着扫描仪始终处于无像差的最佳像位，也不意味着阵列结构不能得到有效校正；最佳校正波长及残余像差取决于具体设计，不能一概规定为谱段中心。[HORIBA光谱仪结构与像差说明](https://www.horiba.com/usa/scientific/technologies/spectrometers-and-monochromators/spectrometers-monochromators-and-spectrographs/)

像差改变的是探测面上的光能空间分布，而不是参考谱线的物理波长。不同算子从该分布提取最大值、半高几何中心或强度一阶矩中心，因此可能对同一波长赋予不同坐标。当响应形状沿谱段系统变化时，定义间位置差也可能包含平滑的波长相关结构。第4章的质心与半高中心分离及交叉应用残差与这一解释相容，但并未独立识别本仪器的像差分量；采样相位、局部谱线混合及固定处理条件也可能参与形成观测结构。

定义间位置差与波长残差之间存在直接联系。固定训练集合和阶次，将定义$i$建立的模型简记为$f_i$，同一谱线的两种输入为$p_i$和$p_j$。采用参考波长减预测波长的约定，有


$$
e_{i\rightarrow j}-e_{i\rightarrow i}
=-[f_i(p_j)-f_i(p_i)]
\approx -f_i'(p_i)(p_j-p_i).
$$


第一项等式是同一模型下的精确关系；近似式要求位置差足够小，使高阶泰勒项可忽略。导数相对于未标准化的物理像素坐标求取，单位为nm/pixel。定义间位移经模型局部位置—波长斜率转换，就成为跨定义残差相对于同定义残差的变化。该关系不是重新拟合后两个模型之间的误差恒等式，也不是独立的像差测量。

亚像素坐标保留了整数像素极大值定位不能充分分辨的细小位置变化。若其中包含平滑的波长相关成分，较高阶模型可能进一步描述该定义下的经验映射。这为部分亚像素定义在三次以上获得LOO改善提供合理解释，但不证明插值创造了新信息，也不证明增加的多项式项就是某个光学像差项。不同阶次最优值属于数据支持的结果，其具体物理成因属于受上述条件限制的解释。

因此，四种算子的比较不是寻找对所有用途都唯一正确的峰位，而是比较同一物理响应的不同操作性位置定义。较小的同定义残差说明该坐标与参考波长之间的映射在当前条件下更容易被所选模型描述，不能单独证明该坐标等于某个独立定义的理想光学像点。

由此，本文的工程意义不是为所有仪器指定一个固定峰位和统一阶次，而是给出可执行的定标模板：先固定响应处理条件和位置算子，再在共同物理样本上选择模型阶次；同时报告拟合、LOO与删除敏感性；最后用与实际读出相对应的应用定义评价模型，必要时保存算子—模型配对关系。该模板把观测、模型、参数、样本和评价五个层次纳入同一流程，但其可迁移性仍需在其他仪器和独立数据中检验。

**English**

The order differences should be interpreted within line-response formation. An array spectrometer images different wavelengths simultaneously at different detector positions, requiring image quality to be balanced across a spectral interval and image field. Off-axis aberrations and field curvature in CT systems can produce wavelength-dependent width and asymmetry; coma can broaden one side of a line. A scanning monochromator uses a fixed exit slit and faces different constraints from a planar array covering a wide field. Neither aberration-free imaging throughout a scan nor an inability to correct array instruments follows from this distinction. The best-corrected wavelength and residual aberrations depend on the design and need not occur at the spectral center. [HORIBA discussion of configurations and aberrations](https://www.horiba.com/usa/scientific/technologies/spectrometers-and-monochromators/spectrometers-monochromators-and-spectrographs/)

Aberrations alter the spatial distribution of optical energy, not the physical reference wavelength. Operators extracting a maximum, half-maximum midpoint, or first intensity moment can consequently assign different coordinates to the same wavelength. Systematic profile variation may produce smooth wavelength-related structure in inter-definition separation. The Centroid–FWHM-center separation and cross-application residuals in Chapter 4 are consistent with this explanation, but do not independently identify instrument aberration components. Sampling phase, local blending, and fixed processing conventions may also contribute.

For a fixed training set and order, let $f_i$ denote the model calibrated using definition $i$, with coordinates $p_i$ and $p_j$ for the same line. Under the reference-minus-predicted convention, the equation above gives the exact residual difference as the negative change in the same calibration function. The first-order approximation requires a sufficiently small separation to neglect higher-order Taylor terms. The derivative is with respect to the unstandardized physical pixel coordinate, in nm/pixel. Inter-definition displacement is thus converted by the local position–wavelength slope into a change from within-definition to cross-definition residual. This is neither an identity comparing separately refitted models nor an independent aberration measurement.

Subpixel coordinates retain small variations that integer-pixel maximum localization cannot fully resolve. If these contain smooth wavelength-related components, higher-order models may better describe the empirical mapping. This plausibly explains LOO improvements above cubic order for some subpixel definitions, but does not establish that interpolation creates information or that an additional polynomial term represents a particular aberration. Preferred orders remain data-supported observations; their detailed physical origin remains an interpretation subject to these qualifications.

The comparison therefore does not seek one uniquely correct peak position for every purpose. It compares operational definitions representing the same physical response. Smaller within-definition residuals indicate closer description of the coordinate–reference-wavelength mapping by the selected model under the assessed conditions, not necessarily coincidence with an independently defined ideal optical image point.

The engineering contribution is consequently not a fixed peak definition and polynomial order prescribed for every instrument, but an executable calibration template: fix response-processing conditions and the position operator; select model order on common physical samples; report fit, LOO, and deletion sensitivity together; and finally assess the model using the application definition corresponding to actual readout, retaining operator–model associations where necessary. The template places observation, model, parameter, sample, and assessment levels in one workflow, while transferability still requires testing on other instruments and independent datasets.

### 5.2 单模型与定义对应多模型的使用策略 / Single-Model and Definition-Specific Multi-Model Use

#### 5.2.1 固定应用与多种读出的区别 / Fixed Applications versus Multiple Readout Definitions

**中文**

跨定义矩阵为模型选择补充了应用维度。对于读出算法固定的系统，应首先比较对应应用列中的候选模型，而不是仅比较各模型的对角误差。对于希望用同一套定标关系支持多种读出定义的系统，则需检查与实际应用相关的多个列，确定各组合是否满足相应要求。未规定用途、容差或权重时，不宜把整行指标任意平均后宣称得到唯一“最佳通用模型”。

在当前三次、41点条件下，各应用列的最小RMSE均位于同定义组合。然而，这只是本组候选模型中的结果，不是定义一致必然最优的数学保证；Direct模型同一行中，应用于Interpolated坐标的误差就低于应用于Direct坐标的误差。按行比较不同输入与按列比较不同定标模型，回答的是不同问题。

FWHM中心三次模型可作为需要兼顾自身亚像素读出与Direct读出的单模型候选。其FWHM→FWHM RMSE为0.025356 nm，FWHM→Direct为0.129321 nm，后者比Direct→Direct的0.119791 nm高约0.009530 nm，或7.96%。这些数值说明其Direct应用误差仍处于相近量级，但是否可接受取决于具体容差。尤其当应用还包括Centroid读出时，该模型的误差增至0.066725 nm，高于Centroid→Centroid的0.037357 nm。因此，不能由其FWHM自身误差较低推导其适用于所有峰位读出。

此外，当前跨定义数值固定为三次，尚不足以证明FWHM三次优于四次或其他阶次的通用兼容性。第4.2节的同定义升阶结果与第4.3节的固定阶次跨定义结果应保持各自的证据边界，不能拼接成“升阶必然降低兼容性”的结论。

**English**

The cross-definition matrix adds the application dimension to model selection. For a system with a fixed readout algorithm, candidate models should first be compared within the corresponding application column, rather than only through their diagonal errors. A system intended to support several readout definitions with one calibration relationship must examine the relevant columns and determine whether each combination meets its requirements. Without specified uses, tolerances, or weights, an arbitrary average of row metrics should not be presented as identifying one best general-purpose model.

For the present cubic models and 41-line set, the minimum RMSE in each application column occurred at the matching-definition combination. This is a result within the current candidate set, not a mathematical guarantee that matching definitions must always be optimal. Within the Direct-calibrated row, for example, error was smaller for Interpolated input than for Direct input. Row-wise comparisons of inputs and column-wise comparisons of calibration models address different questions.

The cubic FWHM-center model is a candidate for single-model use when both FWHM-based subpixel readout and Direct readout are relevant. Its FWHM→FWHM RMSE was 0.025356 nm, while FWHM→Direct was 0.129321 nm. The latter exceeded Direct→Direct, 0.119791 nm, by approximately 0.009530 nm, or 7.96%. These values place its Direct-application error at a similar magnitude, but acceptability depends on the specified tolerance. If Centroid readout is also required, its error increased to 0.066725 nm, compared with 0.037357 nm for Centroid→Centroid. Low within-FWHM error therefore does not establish suitability for every position readout.

Moreover, the current cross-definition results are restricted to cubic models and do not establish superior general compatibility of cubic FWHM calibration over fourth or other orders. Within-definition order effects in Section 4.2 and fixed-order cross-definition results in Section 4.3 have distinct evidential scopes. They cannot be combined into a claim that increasing polynomial order necessarily reduces compatibility.

#### 5.2.2 定义对应多模型的价值与边界 / Value and Boundaries of Definition-Specific Models

**中文**

当应用系统允许保存和调用多套定标关系时，可将各位置算子与相应模型配对。运行时先明确采用何种峰位算法，再调用对应的定标函数，而不是在得到输出后选择使残差最小的模型。对于未知谱线，后者通常还缺少用于判断残差的独立参考波长；这种事后择优也不同于本文所讨论的定义对应策略。

该策略的直接价值在于避免未经评估地跨定义使用。例如，FWHM中心与质心的交叉应用RMSE分别为0.066725和0.060817 nm，高于各自同定义的0.025356和0.037357 nm，且互换方向表现出相反的Bias和Slope。对这两种读出分别使用匹配的模型，因而有助于减少本数据中观测到的定义不匹配误差。这一判断限于已比较条件，不意味着多模型系统自动获得更小的完整测量不确定度。

实际使用中，模型与算子的对应关系还应包含相关处理约定：坐标编号、基线、插值、峰窗规则、模型适用波段及版本。改变位置算法或其处理条件后，原模型的适配性需要重新检查。定义对应多模型是不同测量约定的管理方式，并不需要否定单模型，也不代表为每条未知谱线任意选择不同位置定义。

还需区分谱线位置读出和整幅光谱的波长轴赋值。本研究评价的是参考谱线位置输入定标函数后的误差；它尚未验证在连续或复杂光谱处理中切换整幅波长轴的效果，也未评估重采样、辐射积分或其他下游算法的误差。因此，本文的多模型建议应表述为基于谱线读出定义的应用策略，而非已经验证的所有光谱任务的通用切换方案。

**English**

When an application permits multiple calibration relationships to be stored and used, each position operator can be paired with its corresponding model. The position algorithm is specified first, and the associated calibration function is then applied. This is not post hoc selection of whichever model yields the smallest residual. For an unknown line, the latter would generally lack an independent reference wavelength with which to determine that residual, and it differs from the definition-specific strategy considered here.

The immediate value of this strategy is to avoid unassessed cross-definition use. FWHM-center and Centroid cross-application RMSE values were 0.066725 and 0.060817 nm, exceeding their corresponding within-definition values of 0.025356 and 0.037357 nm, while the exchange directions exhibited opposing Bias and Slope. Matching each of these readouts with its own model can therefore reduce the definition-mismatch errors observed in this dataset. This statement is limited to the assessed conditions and does not imply that a multi-model system automatically has lower total measurement uncertainty.

In practice, the model–operator association should also retain the relevant conventions: coordinate indexing, baseline treatment, interpolation, window rules, applicable wavelength interval, and version. Compatibility with an existing model should be reassessed when the position algorithm or its processing conditions change. Definition-specific models provide a way to manage different measurement conventions; they neither invalidate single-model use nor justify arbitrary choice of a different position definition for each unknown line.

Spectral-line readout must also be distinguished from wavelength-axis assignment for an entire spectrum. This study assesses errors obtained by applying calibration functions to reference-line positions. It has not validated whole-axis switching in continuous or complex spectra, nor evaluated errors in resampling, radiometric integration, or other downstream algorithms. The multi-model proposal is therefore an application strategy tied to spectral-line readout definitions, not an already validated universal switching scheme for all spectroscopic tasks.

### 5.3 精度报告的条件与共同样本评价 / Conditions for Accuracy Reporting and Common-Set Assessment

**中文**

本文结果提示，波长定标“有多准”需要连同测量和评价条件一起回答。至少应明确：定标采用的峰位定义、应用输入的峰位定义、多项式阶次、训练谱线集合、评价集合及评价方式。同一个模型的Fit RMSE、LOO RMSE和跨定义RMSE并不是可以相互替代的精度标签。

例如，FWHM中心三次模型的Fit RMSE为0.025356 nm，LOO RMSE为0.030248 nm，而输入Centroid坐标后的共同41点评价RMSE为0.066725 nm。三者并不矛盾，分别对应训练集拟合、同定义留出预测以及改变应用位置算子后的误差。脱离这些条件只报告其中最小的数值，会使读者误判实际使用时可期待的表现。

对样本集合不同的模型，使用共同参考集合评价具有明确价值：它固定了误差所对应的谱线和波段分布，使比较不再仅依赖各模型各自的训练样本。然而，共同集合包含训练点，因此不能把这种评价改称独立验证。对于41点模型与少点模型，应并列报告训练和评价样本数，并区分共同集合指标与训练集LOO。这样既保留可比性，也避免夸大证据的独立程度。

Bias、STD、P95、MAX与波长残差趋势补充了RMSE的不同方面，但它们共同仍不能替代完整的不确定度预算。参考波长的不确定度、重复采集变化、环境漂移、谱线混合及处理条件变化等来源，需要各自的证据才能量化。这里报告的是特定数据与流程下的观测残差和验证表现，不是对所有输入、波长或未来测量的误差上界。

**English**

The results indicate that an answer to how accurate a wavelength calibration is must include its measurement and assessment conditions. At minimum, reporting should specify the calibration definition, application definition, polynomial order, training-line set, evaluation set, and assessment procedure. Fit RMSE, LOO RMSE, and cross-definition RMSE are not interchangeable accuracy labels for the same model.

For example, the cubic FWHM-center model had a Fit RMSE of 0.025356 nm and an LOO RMSE of 0.030248 nm, while its common-41-line RMSE increased to 0.066725 nm when Centroid coordinates were supplied. These values are not contradictory: they describe training fit, within-definition withheld prediction, and error after changing the application position operator, respectively. Reporting only the smallest value without these conditions would misrepresent the performance to be expected in use.

Evaluating models trained on different sample sets against a common reference set has a clear benefit: it fixes the lines and wavelength distribution to which the errors refer, so comparisons do not depend solely on each model’s own training samples. However, the common set includes training points and must not be relabeled as independent validation. Training and evaluation counts should be reported together for full and sparse models, and common-set metrics distinguished from training-set LOO. This preserves comparability without overstating evidential independence.

Bias, STD, P95, MAX, and wavelength-dependent residual trends complement RMSE, but even collectively they do not constitute a complete uncertainty budget. Contributions from reference-wavelength uncertainty, repeated acquisition, environmental drift, line blending, and processing changes require their own evidence for quantification. The reported quantities are observed residuals and validation performance under specified data and procedures, not error bounds for all inputs, wavelengths, or future measurements.

### 5.4 研究边界与后续工作 / Scope and Further Work

**中文**

本研究的结论建立在一台仪器、一个已处理光谱数据集及人工确认的41条参考线上。它支持该条件下峰位定义、阶次与跨定义表现之间的比较，但不能单独证明其在其他仪器、独立采集批次或不同环境条件下同样成立。独立重复测量和环境稳定性评价可用于检验这些关系的可重复性，而不应由当前一次数据分析代替。

人工审查提高了分析样本的可解释性，但也限定了结论的适用对象。由于谱线确认过程中参考了峰形、NIST查询及LOO诊断，随后在固定41点上的LOO是对已审查数据集的条件化评价，而不是将整个筛选过程置于独立验证之中。本文将通过实际筛选案例说明该环节，不把人工审查隐藏为完全自动的程序步骤，也不将删除敏感性分析作为继续追求低残差的自动删点机制。

峰窗和插值在本文中是明确而固定的处理条件。它们可能影响峰参数，但本文没有开展参数敏感性或优化研究；结论也不声称对任意窗口或插值方法保持不变。对四种位置定义的公平比较依赖于同一谱线内处理条件一致，以及所有下游模型使用同一已确认数据。

5点和9点方案用于服务稀疏定标条件下的四定义比较，并不构成对点数或样本配置的全局优化。样本选择算法、配置稳定性和更系统的少点设计可作为后续独立研究。当前跨定义分析还主要固定于三次；若需要将“分别优化阶次后的多模型”与“固定单模型”做全面比较，应在明确应用条件后补充相应分析，不能从已有三次矩阵直接外推。

[编辑说明：本节只界定少点分析的范围，不陈述尚待4.4数值核查的优劣结果。人工案例补齐后可精简相关说明；这里不新增必须先完成的实验任务。]

**English**

The findings are based on one instrument, one processed spectral dataset, and 41 manually confirmed reference lines. They support comparisons of position definition, order, and cross-definition performance under those conditions, but do not independently establish transferability to other instruments, separate acquisitions, or different environments. Independent repeated measurements and environmental-stability assessment can test reproducibility of these relationships; they cannot be replaced by the present single-dataset analysis.

Manual review improves the interpretability of the analysis set while limiting the population to which conclusions apply. Because line confirmation used profiles, NIST queries, and LOO diagnostics, subsequent LOO on the fixed 41-line set is conditional on that reviewed dataset, not independent validation of the entire selection process. Representative cases will document this stage. Manual review is not presented as a wholly automatic procedure, and deletion sensitivity is not used as a mechanism for continued automatic removal in pursuit of smaller residuals.

Analysis windows and interpolation are explicit, fixed processing conditions in this study. They may affect peak parameters, but parameter sensitivity and optimization have not been investigated here; the conclusions are not claimed to hold for arbitrary windows or interpolation methods. Comparable assessment of the four position definitions depends on consistent processing within each line and use of the same confirmed data in all downstream models.

The five- and nine-point schemes serve cross-definition comparison under sparse calibration and do not constitute global optimization of sample count or configuration. Selection algorithms, configuration stability, and more systematic sparse designs can be addressed in separate work. The current cross-definition analysis is also primarily restricted to third order. A comprehensive comparison of separately order-optimized models against a fixed single model would require additional assessment under explicit application conditions, rather than extrapolation from the existing cubic matrix.

[Editorial note: this section defines the scope of sparse analysis without asserting advantages or disadvantages that await numerical checking in Section 4.4. Relevant wording can be shortened after the manual-review cases are supplied; no new prerequisite experiment is imposed here.]

## 6 结论 / Conclusions

> **框架性结论 / Framework-level conclusion：** 本文将波长定标模型选择显式组织为样本空间 $\mathcal{S}$、表征空间 $\mathcal{X}$、函数空间 $\mathcal{F}$、参数空间 $\Theta$ 和模型特性空间 $\mathcal{C}$。其中，表征空间使峰位定义成为模型选择变量；模型特性空间则将残差及其重采样、删除扰动和跨定义传播所构造的特性量作为模型形成与选择过程中的反馈，而非单纯的事后评价。由此，波长定标模型可在单一通用模型与按定义配置的多模型策略之间，根据实际应用的性能、稳健性和兼容性要求进行选择。 / The proposed formulation explicitly organizes wavelength-calibration model selection into the sample, representation, function, parameter, and model-characteristic spaces. Representation-space selection makes peak-position definition an explicit model-selection variable, while the characteristic space uses residual-derived, resampling-based, deletion-based, and cross-definition characteristics as feedback during model formation and selection rather than solely as post hoc assessment. This formulation supports an engineering choice between a single common model and definition-specific models according to performance, robustness, and compatibility requirements.



**中文**

四种峰位定义的区别既涉及数值实现，也涉及对物理响应代表位置的不同约定：Direct与Interpolated定位极大值，FWHM中心定位半高轮廓的几何中点，Centroid定位窗口内非负净信号的一阶矩中心，而非等面积分割点。它们不应被视为可以无条件互换的坐标。波长相关响应形状为定义间分离及跨定义残差提供了物理解释，但当前结果不单独确定像差来源，也不确立某一算子为唯一真实峰位。

本文基于宽波段阵列光谱仪的41条已确认参考谱线，考察了四种峰位定义对波长定标模型选择与误差评价的影响。Direct、Interpolated、FWHM中心和Centroid即使在同一局部响应及固定处理条件下，也不提供完全相同的位置。质心与FWHM中心的相对分离包含波长相关结构，表明在本研究条件下，峰位定义应作为经验定标关系的一项显式条件，而不能只作为拟合前可任意互换的处理步骤。

阶次扫描显示，不同定义的最小LOO误差出现在不同阶次。FWHM中心四次模型的LOO RMSE为0.021736 nm，较三次降低约28.14%；因此，三次适合作为简约的共同比较基线，但不是各定义的普遍最优解。相对删除影响、绝对曲线变化和最大残差还反映不同的敏感性，模型选择应结合绝对误差、复杂度及样本依赖，而不是依赖单一指标。

固定三次的跨定义矩阵进一步表明，同定义误差不足以描述模型对其他峰位读出的适用性。FWHM中心三次模型的同定义Fit RMSE为0.025356 nm，应用于Centroid位置后为0.066725 nm；FWHM中心与质心互换还产生方向相反的偏置及波长趋势。这些结果支持将定标定义与应用定义分开报告，但不建立某一种定义是唯一物理真实位置的结论。

在工程使用上，固定单模型应根据实际需要支持的读出方式和容差选择；允许多模型时，可将位置算子与相应定标函数配对，减少未经评估的定义不匹配。本文为这两类选择提供了可解释的评价依据，而不宣称一种策略在所有应用中均更优。

总体而言，本文将宽谱段阵列成像形成的波长相关响应、四种位置观测算子和经验定标模型连接为一个条件化逆映射问题。波长定标精度应连同定标与应用峰位定义、模型阶次、训练样本和评价方式共同表述。共同参考样本集评价提高了模型间的可比性，但仍需与训练拟合、LOO及独立验证相区分。本文结论适用于当前仪器、已审查数据集和固定处理条件，为在明确测量约定下选择定标模型及解释其误差提供了依据。

**English**

The four peak definitions differ in numerical implementation and in the representative feature assigned to a physical response: Direct and Interpolated positions localize maxima, the FWHM center locates a half-maximum geometric midpoint, and the Centroid locates the first-moment center of the nonnegative net signal within the window, not an equal-area bisector. They are not unconditionally interchangeable coordinates. Wavelength-dependent response shape offers a physical interpretation of their separation and cross-definition residuals, but the present results neither identify a unique aberration source nor establish one uniquely true position operator.

Using 41 confirmed reference lines measured with a broadband array spectrometer, this study examined how four peak-position definitions affect wavelength-calibration model selection and error assessment. Direct, Interpolated, FWHM-center, and Centroid definitions do not yield identical positions even for the same local responses under fixed processing conditions. Wavelength-related structure in Centroid–FWHM-center separation indicates that, under the investigated conditions, position definition should be treated as an explicit condition of the empirical calibration relationship rather than an arbitrarily interchangeable preprocessing step.

The order scan identified different LOO-error minima for different definitions. Fourth-order FWHM-center calibration achieved an LOO RMSE of 0.021736 nm, approximately 28.14% below the cubic value. A cubic model is therefore a parsimonious common comparison baseline, not a universally optimal order for every definition. Relative deletion influence, absolute curve change, and maximum residuals characterize different sensitivities. Selection should consider absolute error, complexity, and sample dependence jointly rather than rely on one metric.

The cubic cross-definition matrix further demonstrated that within-definition error does not fully describe suitability for alternative position readouts. The cubic FWHM-center model had a within-definition Fit RMSE of 0.025356 nm, increasing to 0.066725 nm when applied to Centroid positions. Exchanging FWHM-center and Centroid definitions also produced opposing biases and wavelength trends. These findings support separate reporting of calibration and application definitions, without identifying one uniquely true physical position definition.

For engineering use, a fixed single model should be chosen according to the readout methods it must support and their tolerances. Where multiple models are permitted, each position operator can be paired with its corresponding calibration function to reduce unassessed definition mismatch. The study provides an interpretable assessment basis for both choices without claiming that one strategy is superior in every application.

Overall, this study connects wavelength-dependent responses formed by broadband array imaging, four position-observation operators, and empirical calibration models as a conditional inverse-mapping problem. Wavelength-calibration accuracy should consequently be reported together with calibration and application position definitions, polynomial order, training samples, and assessment procedure. A common reference set improves comparability among models but must remain distinct from training fit, LOO, and independent validation. The conclusions apply to the present instrument, reviewed dataset, and fixed processing conditions, providing a basis for selecting calibration models and interpreting their errors under explicit measurement conventions.

---

---

## 整合稿待完成事项 / Pending Items for the Integrated Draft

- [框架审阅F1] 核对五层空间术语是否最终采用 Sample / Representation / Function / Parameter / Model Characteristic Space。
- [框架审阅F2] 正式投稿时将3.1中的ASCII概念图重绘为矢量图，不使用Mermaid源图直接投稿。
- [符号审阅F3] 统一位置处理参数与模型参数的符号，避免当前数据记录中的 $\boldsymbol\theta_n$ 与模型参数空间 $\Theta$ 混淆。
- [结构审阅F4] 最终英文单语稿中删除第四章各节的“五层框架中的位置”提示框，将其内容自然融入首段；当前保留是为了重构审阅。


- [作者补充-A1] 2–4个参考峰人工审查案例及窗口调整理由。
- [作者补充-A2 / 数据待核-D2] 5点和9点的最终成员、确认过程及共同41点评价结果。
- [作者确认-A3] 作者、单位、基金、利益冲突及数据/代码可用性声明。
- [引用待补-R] 阵列与扫描光谱仪成像约束、CT像差、峰位方法、NIST参考波长及前篇论文等正式文献。
- [图件待补-F] 按MATLAB出图任务单先完成Fig.3和Fig.6，再统一修订第4章图文。
- 摘要和关键词在正文、图表及5/9点结果稳定后最后撰写。