# 冻结范围核对

对照整批 BENCHMARK-STANDARD.md，不以行数或包装代替实现。

| 原范围 | 实现/证据 |
|---|---|
| 2.2/4.1 ASCII/二进制 | codec/writer；meshio 17 类型双向、struct 大小端/size_t |
| 稀疏编号、实体/物理组 | model；10/33/90、77，多物理组与 parametric fixture |
| 常见一二阶 | ID 1–19；meshio 缺两类型由 struct 验证 |
| NodeData/ElementData | 1/3/9 分量、稀疏子集、多帧与额外 tags |
| 未知段/损失 | ASCII 规范化文本保留；二进制拒绝；变换显式 drop |
| 子集/紧凑编号 | operations，同步字段筛选/改号，不改实体和物理标签 |
| 边界/邻接/连通 | 线性面 incidence 与非流形；全阶共享节点 components |
| 孤立/重复/退化/翻转 | geometry；Double 相对阈值；翻转定义在线性四面体 |
| 三角形/四面体质量体积 | NumPy 80 组、规则单纯形、数值边界 |
| VTK/OBJ/JSON | 真实文件、meshio 回读、体网格外法向 |
| 工程 | 中文 README、公共 API、CLI、MIT、三系统 CI 配置、证据 |

明确子域：拓扑与 VTK/OBJ 是线性单元路径；高阶网格完整保存但不伪造
高阶几何判定。VTK 棱柱按历史 9.3 约定，与当前 nightly 有差异。
不含网格生成器、CAD 逆向、自交检测或完整 Gmsh 扩展语义。
完整限制与资源界限见 README。
