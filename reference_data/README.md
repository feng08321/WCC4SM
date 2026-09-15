# reference_data/ — 参考数据溯源与使用说明

本目录是 WCC4SM 的**参考数据单一事实源**（MATLAB 版与未来 Python 版共享）。
全部文件纳入版本控制；修改须遵守下文"修改政策"。

## 文件清单与角色

| 文件 | 角色 |
|---|---|
| `NIST_ASD_HgAr_20260910.lit` | **当前 NIST ASD Hg-Ar 主库**（326 行） |
| `NIST_ASD_HgAr_20260910_Metadata.md` | 当前主库的溯源元数据 |
| `WCC4SM_NIST_ASD_HgAr_Mode03_20260910.csv` | 当前主库的选择模式 Mode03（仪器族剖面） |
| `NIST_ASD_HgAr_20260729.lit` + `_Metadata.md` + `..._Mode01.csv` | 上一代主库（322 行）及 Mode01，保留用于复现 |
| `WCC4SM_NIST_ASD_HgAr_Mode02_20260817.csv` | 20260729 主库的 Mode02 |
| `Builtin_HgAr_Basic21.lit` | 内置线库：经验筛选 21 线（300–1050 nm 名义仪器） |
| `Builtin_HgAr_Paper24.lit` | 内置线库：论文 Table 1 的 24 条实测峰 |
| `Builtin_HgAr_NIM34.lit` | 内置线库：NIM 证书 GXcl2025-02617 的 34 线 |
| `examples/HgAr_Avantes_Example.lit` | 外部线库格式示例 |

## 主库版本沿革

| 版本 | 行数 | 变更 |
|---|---:|---|
| 20260729 | 322 | 首个定版主库（强线 + 若干弱线补充） |
| **20260910** | **326** | 新增 4 条弱 Hg 线（390.6371 / 567.581 / 612.327 / 671.634 nm），
用于解释现有测试谱的全部定标集合；0 删除、0 修改 |

选择模式（Mode01/02/03）只是从带日期主库中按仪器族筛选可用线，
**不定义独立的波长真值**；每个模式必须使用主库中精确存在的波长值。

## 内置线库与主库的关系

三个 `Builtin_*.lit` 是 GUI 内置的小型工作库（经
`wc4sm_load_builtin_library` 加载），服务于初始映射与快速定标；
NIST 主库是完整参考源。两者角色不同，不要互相覆盖。

## .lit 文件格式

`#` 开头的注释头 + 空白分隔数据列：`wavelength_nm`、相对强度、
可选 `order`（衍射级次，缺省 1）。加载后按 `wavelength×order` 升序。
详见 `docs/WCC4SM_DATA_DICTIONARY.md` §4。

## 修改政策

不要静默修改任何带日期的主库。若 NIST 取值、检索条件或弱线覆盖发生变化，
按 `NIST_ASD_HgAr_20260729_Metadata.md` 中的政策执行：新建带新日期的
主库、元数据、选择模式和差异报告，并保留旧版本以保证可复现。
