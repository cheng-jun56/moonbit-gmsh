# MoonGmsh

纯 MoonBit 的 Gmsh MSH 网格交换、拓扑与几何检查库。核心不调用 Gmsh、
meshio、Python 或 JS 解析器；Node 宿主只处理参数、真实文件和退出码。
本地模块 `localreview/gmsh@0.1.0`，MIT；尚未推送、发布或运行远程 CI。
不是网格生成器，也不把“能读取文件”当成有限元网格质量认证。

## 已实现范围

| 能力 | 范围与边界 |
|---|---|
| MSH 交换 | 2.2 / 4.1；ASCII / 二进制；大小端；4.1 的 4/8 字节 size_t |
| 编号 | 稀疏、乱序节点与单元编号；正整数 ≤ 2,147,483,647，超出明确拒绝 |
| 单元 | Gmsh 类型 1–19，覆盖常见一、二阶单元；连接顺序无损保存 |
| 元数据 | 4.1 实体、包围盒、带符号边界引用、物理组、参数坐标；2.2 额外标签 |
| 数据字段 | 多帧 NodeData / ElementData；1/3/9 分量；稀疏数据；时间与额外头标签 |
| 变换 | 按单元/物理组取子集、清除未使用节点、紧凑编号；同步维护字段关联 |
| 拓扑 | 线性单元面/边邻接、外边界、非流形面；全阶共享节点连通分量 |
| 几何 | 孤立/精确重复节点、重复连接；线性三角形面积/质量、四面体有符号体积/翻转/质量 |
| 导出 | MSH、JSON；线性网格的 geometry-only VTK/OBJ；体网格 OBJ 导出外边界 |

高阶单元完整保存于 MSH；质量报告列入 `unsupported_quality`，不将角点线性化后冒称曲单元合格。
拓扑在选定维度存在高阶单元时明确拒绝。VTK/OBJ 不输出字段、组和实体，存在这些信息时须显式允许损失。

## 立即运行

实测 Moon 0.1.20260920 / moonc 0.10.14+7d59c7ec9、Node 24.11.0。
先安装 MoonBit 与 Node 24，然后在仓库根目录运行：

```sh
moon check --target all
moon test --target js
moon test --target wasm-gc
moon build --target js --release
node tools/gmsh.mjs inspect examples/triangle.msh
node tools/gmsh.mjs quality examples/triangle.msh examples/quality.json
node tools/gmsh.mjs topology examples/triangle.msh
node tools/gmsh.mjs validate examples/triangle.msh examples/strict.json
node tools/gmsh.mjs convert examples/triangle.msh examples/convert.json converted.msh
node tools/gmsh.mjs inspect converted.msh
node tools/gmsh.mjs vtk examples/triangle.msh examples/export.json mesh.vtk
node tools/gmsh.mjs obj examples/triangle.msh examples/export.json mesh.obj
```

示例面积 0.5，节点编号 10/33/90，单元编号 77，物理组 4；
温度字段仅覆盖 10/90 两个节点。不是预置输出，CLI 读取提供的路径。
输出必须不存在；重复运行请换新输出名，不自动覆盖已有文件。

## CLI

```text
node tools/gmsh.mjs COMMAND INPUT [OPTIONS.json] [OUTPUT]
node tools/gmsh.mjs create OPTIONS.json OUTPUT
```

OPTIONS 是 UTF-8 JSON **文件路径**，不是内联 JSON。
可写命令：`copy convert subset physical compact`。报告命令：
`inspect dump validate quality topology components vtk obj`。
未指定 OUTPUT 时报告到 stdout；VTK/OBJ 输出文本，其余输出 JSON。

| 选项 | 用途 |
|---|---|
| `version` | 输出 `"2.2"` / `"4.1"`；默认保持输入版本 |
| `binary`, `little` | 是否二进制、是否小端；默认 false / true |
| `size_width` | 默认 8；仅 4.1 可设 4 |
| `allow_loss` | 默认 false；明确接受目标格式无法表示的已知元数据损失 |
| `drop_unknown` | 默认 false；显式丢弃未知段，才允许变换或跨版本/二进制转换 |
| `tags` | subset 的唯一单元编号数组；保留请求顺序 |
| `dimension`, `group` | physical 的维度与物理组；topology 可用 dimension 指定层级 |
| `tag` | quality 的单元编号 |
| `tolerance` | 退化质量阈值，默认 1e-12，范围 [0,1) |
| `strict` | validate 为 true 时，已支持的几何缺陷同时触发退出码 3 |

退出码：0 成功、2 输入/格式/IO/不支持请求、3 strict 检测到缺陷。
默认 validate 是诊断报告，不以非零码代替结果；
即使 strict 返回 0，`unsupported_quality` 非空也意味着未认证这些单元。
`inverted` 仅对四面体定义；三维三角面没有天然统一的正反参考。

create JSON 顶层包含 `nodes`、`elements`，可带 entities/names/fields/unknown。
坐标是三元数组，element.kind 使用 Gmsh 原始编号：

```json
{"nodes":[{"tag":10,"xyz":[0,0,0]},{"tag":20,"xyz":[1,0,0]}],
 "elements":[{"tag":7,"kind":1,"nodes":[10,20]}],
 "version":"4.1","binary":true}
```

完整字段见 `dump` 输出及公共 `pkg.generated.mbti`。重建 dump 时，
`source_version` 指定模型原版本；`version` 决定写出版本。

## MoonBit API

```mbt
let m = @gmsh.decode(bytes)
let selected = m.subset([77]).compact()
let output = selected.encode(version="4.1", binary=true)
let report = m.diagnostics()
let faces = m.topology().boundary
```

入口 `mesh`、`decode`、`Mesh::encode`；
`nodes/elements/entities/fields/physical_names/unknown_sections` 返回深复制快照。
DTO 可构造，Mesh 内部数组/索引私有。关联先验证，不静默修补坏引用。

## 损失与语义

- 2.2 → 4.1 保留正 elementary ID；无分类单元按维度/物理组分配实体。
  节点归属最高维 incident entity，孤立节点分配点实体；这是推断分类，不是 CAD 重建。
  同一旧实体拥有冲突物理组会拒绝，不私自合并。
- 4.1 → 2.2 无法完整表示实体图、节点归属/参数坐标、多个物理组。
  需 allow_loss；多物理组仅保留第一个，其他上述信息丢弃。
- 2.2 的第三个及以后额外标签在 2.2 保留，写 4.1 需 allow_loss。
- 未知 ASCII 段按不透明文本保留，换行规范化 LF，不是逐字节复刻。
  不能安全解释其中编号，取子集/改号/跨版本前须主动丢弃。
  未知二进制段直接拒绝，不扫描二进制内容猜结束标记。
- 邻接按完整面/边的节点集合；连通分量按共享任意节点。
  topology 默认只检查最高维，避免重复计入已列出的低维边界单元。
- 质量使用归一化 Double 运算和尺度相对阈值，不是精确几何谓词；
  极端病态/近共面场景会受浮点舍入影响，无法表示的面积/体积报错。
  不检查任意网格自交、CAD 一致性或有限元求解适用性。
- VTK 是 legacy ASCII，棱柱顺序按 VTK 9.3 / meshio 5.3.5 转换。
  最新 VTK nightly 的 wedge 约定已有差异；不声称对所有版本验证。
  面向未验证的新宿主，优先 MSH 交换并复核单元朝向。

## 资源与非目标

输入/输出 ≤ 128 MiB；节点/单元/实体/物理名各 ≤ 100 万；
连接及数据数值分别 ≤ 800 万；数据帧/未知段各 ≤ 1024；
文本行 ≤ 1 MiB、数值 token ≤ 128 字节。
4.1 接受 64 位存储宽度，但值坚持跨后端 signed-32 范围。
仅 UTF-8，字符串不支持转义引号/反斜杠和嵌入控制行。
核心 Nodes/Elements/Entities/PhysicalNames 段不允许重复，数据帧可重复。
不支持 4.0、任意高阶/多面体、二进制未知扩展、ElementNodeData 语义、
分区/周期映射求解、网格生成或自动修复；ASCII 扩展仅作不透明段。

## 核验与来源

```sh
python -m pip install -r tools/requirements.txt
python tools/verify-reference.py
node tools/check-cli.mjs
```

本地 JS / Wasm-GC 各 12 组、24 项 CLI 检查、独立 540 个请求 / 1,957 断言。
17 类型 meshio 双向、另 2 类型 struct；稀疏数据/参数坐标/大小端/size_t32
由 struct 验证，80 组几何由 NumPy 对照。详见 docs/TESTING.md 与 evidence/reference.json。
证据绑定源文件 LF 规范化 SHA-256；不是远程 CI 回执。

- [Gmsh 官方格式与节点顺序](https://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format)
- [meshio 5.3.5](https://github.com/nschloe/meshio/tree/v5.3.5)：独立开发参考，非运行依赖。
- [VTK 9.3 wedge](https://github.com/Kitware/VTK/blob/v9.3.0/Common/DataModel/vtkWedge.h)
  与 [当前 nightly](https://vtk.org/doc/nightly/html/classvtkWedge.html)：导出版本边界。

未复制 Gmsh/VTK 实现；验证脚本调用 meshio 转换函数。
AI 辅助开发事实保留在真实 Git 作者中，不伪造身份或凑提交数。
