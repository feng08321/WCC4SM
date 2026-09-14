# WCC4SM V0.9.3 发布检查清单

发布日期候选：2026-09-01  
本次范围：MATLAB 源码、测试、Markdown 文档和版本标识。Windows EXE 构建不在本次范围内。

## 1. 版本与入口

- [ ] 从工程根目录执行 WCC4SM_V0_9_3，主窗口和 About 显示 V0.9.3；
- [ ] 执行 WCC4SM_V0_9_2，出现兼容提示并正常启动 V0.9.3；
- [ ] README、CHANGELOG 和 docs/README 指向 V0.9.3 权威手册；
- [ ] V0.9.2 扩展实施说明只作为历史设计记录。

## 2. 自动测试

在 MATLAB R2022a 或更高版本的工程根目录执行：

    clear classes
    rehash path
    results = run_wc4sm_tests;

验收条件：

- [ ] 所有已发现测试 Passed；
- [ ] Failed 为 0；
- [ ] Incomplete 为 0；
- [ ] 保存测试日期、MATLAB 版本和结果摘要。

重点测试类：

    runtests('tests/TestPeakPositionCrossValidation.m')
    runtests('tests/TestSessionModules.m')
    runtests('tests/TestV093UiSupport.m')

## 3. GUI 人工验收

- [ ] Peak Position Differences 的差值散点和直方图同步切换；
- [ ] 峰位映射的 None/degree 1/2/3 与残差直方图同步；
- [ ] 峰位交叉验证矩阵的行是定标峰位、列是应用峰位；
- [ ] Full fit/LOO 均能计算；
- [ ] All-method common peaks 与 Per-pair available peaks 均能切换；
- [ ] Training set 的四种来源均可解析；用 K=6 候选做 Full fit 时显示 train N=6、eval N=完整匹配点数；
- [ ] 点击热图和表格单元格均能刷新残差图与直方图；
- [ ] Matrix metric 的 RMSE/Bias/STD/P95/MAX/Slope 与表格一致；
- [ ] 六指标热图、当前定标行 2×2 残差图和 4×4 全组合直方图均完整显示，OPEN FIG 保持阵列；
- [ ] Session 保存后可恢复交叉验证、影响分析和 Set Design 状态；
- [ ] 交叉验证 CSV 和 Set Design 导出可离开 GUI 独立审阅；
- [ ] 普通笔记本窗口宽度下关键按钮、Pool 和 Matrix metric 可见。

## 4. Git 发布前检查

建议在提交前执行：

    git status --short
    git diff --check
    git diff --stat

- [ ] 确认新增 src、tests 和 V0.9.3 文档均被纳入；
- [ ] 确认 result、Session、临时图片和本机路径未被纳入；
- [ ] 确认不存在冲突标记、调试输出和无意的大文件；
- [ ] 审阅 WCC4SM_V0_9_2.m 仅为兼容包装器；
- [ ] 创建发布提交后再创建 v0.9.3 标签；
- [ ] 推送分支和标签后核对 GitHub 文件列表与 CHANGELOG。

## 5. 冻结结论

满足以上条件后，V0.9.3 可作为当前稳定源码版本冻结。EXE 构建、原生 Markdown 帮助阅读和更大样本库的性能优化进入后续版本，不阻塞本次源码发布。
