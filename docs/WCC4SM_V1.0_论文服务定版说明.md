# WCC4SM V1.0 论文服务定版说明

## 1. 启动入口

在 MATLAB 当前目录切换到软件包根目录后运行：

```matlab
WCC4SM_V1_0
```

V0.9.3 入口继续保留，用于复现旧流程；论文定稿和后续数据输出统一使用 V1.0。

## 2. 8×8峰形总览

为保证64个子窗的绘图区尺寸一致，子图不显示横纵轴刻度及刻度数字，仅保留坐标框和峰形点线。每个有效子窗标题显示 `Peak ID | 中心波长 nm`；尚未选择有效应用模型时退回显示 `Peak ID | 中心像素 px`。蓝色标题/轮廓表示当前标杆定标峰，红色表示未选入定标集的峰。

位置：`Peak Analysis > 8x8 peak-shape gallery`。

操作顺序：

1. 导入光谱并执行峰检测；
2. 点击 `BATCH PRE-ANALYSIS (PREVIEW ONLY)`，为全部检测峰生成子窗分析结果；
3. 进入 `8x8 peak-shape gallery`，或点击 `Refresh gallery`；
4. 未应用定标模型时，横轴为自然像素坐标；应用模型后可使用主界面的 `X Axis` 按钮在 Pixel 和 Wavelength 间切换；
5. 点击主工具栏 `OPEN FIG`，把整个8×8阵列作为一个可编辑 MATLAB Figure 打开。

每个子图只显示当前峰子窗的基线校正净信号点线图，不叠加 Direct、Interpolated、FWHM center、Centroid、FWHM 或 ERW 参数标记。黄色实心点保持数据可见性，轮廓线颜色表示集合状态：

- 蓝色：该 Peak ID 存在于当前有效波长匹配标杆集中；
- 红色：未进入当前匹配标杆集，包括被排除或尚未匹配的检测峰。

当前数据为63峰时，P001～P063依次占据前63格，第64格留空。若检测峰不是63个，界面按实际峰数绘制，最多显示64个，并在状态栏报告已分析和检测数量。

## 3. 与论文数据图的关系

8×8图用于全局检查峰形、峰窗和异常结构，不代替41点标杆集合的定量图。论文峰位差数据仍在 `Calibrated Performance > Peak-position wavelength dependence` 中生成和导出。

### 3.1 峰位差数据集管理

上方全峰图可勾选 `Calibration set only`，只显示当前定标样本集中的峰，用于和下方趋势拟合图进行同样本对照。下方 `Fit series` 可在 Direct、Interpolated 和 Centroid 相对 FWHM center 的三种峰位差之间切换；所选差值独立执行 No fit 或 1--3 阶拟合，并同步更新散点、拟合线、标准差辅助线、状态文字、右侧定标样本表和 CSV 导出。

全峰表第一列 `Show` 用于人工判定分析数据有效性。取消勾选后，该峰仍保留在全峰表中，并显示为 `Analysis excluded`，但不再绘入上方全峰峰位差图，也不作为下方趋势图的灰色背景样本。该操作只影响论文峰位差分析视图，不删除原始寻峰结果、不改变参考谱线状态，也不改变当前定标样本集及其拟合结果；需要改变定标拟合时，应使用下方定标样本表的 `Fit` 与确认删除流程。

代码返回 `NaN` 导致的自动无效峰与人工判定无效峰属于两类状态：前者不会进入全峰有效表，后者保留记录并可随时重新勾选恢复。饱和峰、截断峰或虽返回有限数值但峰位参数不可信的峰，应通过 `Show` 人工排除。

刷新峰位差页面后，右侧自动切换到 `Peak-difference dataset`：

- `All valid analyzed peaks` 表对应上图，列出所有峰参数有效的检测峰，并用 `Calibration`、`Temporary delete`、`Removed / archived` 和 `Unmatched` 标记集合状态。
- 只有保留了真实参考波长配对历史的 `Removed / archived` 峰可以通过 `CONFIRM ADD SELECTED TO CALIBRATION SET` 重新加入。`Unmatched` 峰必须先到 Wavelength Matching 完成参考谱线匹配，不能用模型估计波长反向构造定标点。
- `Current calibration peaks` 表对应下图。取消 `Fit` 只产生暂定删除，点以叉号显示且不参与趋势拟合；`Restore temporary` 可以恢复。
- `CONFIRM DELETE` 把所有暂定删除点正式移出当前定标集，同时保存其参考波长配对历史。确认后这些点从定标表消失，并在图上变为灰色菱形。

上图的 Direct、Interpolated 和 Centroid 三种差值可以独立显示或隐藏；Centroid 差值统一使用圆点。重复点击同一点可取消强化，也可以点击 `Clear highlight`。

下图同时表示三个层次：灰色菱形为当前定标集之外的有效峰，彩色圆点为参与拟合的当前定标峰，叉号为本轮暂定删除峰。拟合曲线附近同时绘制基于当前拟合残差标准差的正负2倍和正负3倍辅助线。已有真实参考配对的峰使用参考波长；从未匹配的灰色峰仅使用当前模型换算波长作背景显示。

## 4. 定版验收

发布前至少执行：

```matlab
results = run_wc4sm_tests;
assertSuccess(results)
```

并人工确认63峰数据下：宫格顺序正确、第64格为空、41个匹配峰显示为蓝色、其余峰显示为红色，以及应用模型后的波长轴切换和整页 `OPEN FIG` 正常。
