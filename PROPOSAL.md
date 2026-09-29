# MoonGmsh：保留来源与物理标签的网格边界交付

本地模块 `cheng-jun56/gmsh@0.2.0`，拟替换因用途过窄而停用的 POP3 选题。公开仓库：https://github.com/cheng-jun56/moonbit-gmsh。 本地交付版 0.2.1 仅补全已存在公开仓库的包元数据地址，算法未改；尚未推送或发布，公开版仍为 0.2.0。

## 使用任务与实现

面向在 MoonBit 内编写网格导入、前后处理和可视化准备代码的开发者，处理 MSH 2.2/4.1 文件，提供公共数据模型、拓扑/边界提取、节点与父单元来源、显式标签/稀疏字段保留、损失报告及受控导出。典型任务是检查导入网格的边界标签是否符合调用方要求，定位遗漏面，再把原始tag和来源一起交给下游。AI生成的转换脚本仍需可检查的标准语义、来源和失败边界；本库为这一任务提供可重复调用的核心，不以AI时代作为创新口号。

## 与成熟工具的关系

Gmsh、meshio、[meshio++](https://github.com/loumalouomega/meshioplusplus) 和 [Gmsh Wasm](https://www.npmjs.com/package/@loumalouomega/gmsh-wasm) 已覆盖通用交换、表面提取或父单元信息；这些不是本项目首创。MoonBit 增量是可组合的数据/API、无外部解析器的运行核心和显式标签/损失契约。定向 Mooncakes 检索未见同范围包，不作为生态空白证明；不宣称全格式替代或性能优胜。

## 可复现的网格交付

公开 Gmsh 教程生成四种输入，共 404 节点、726 三角形、80 条边界、10 条未标注边界，实际 Gmsh/meshio 独立对照。公共 `Boundary::coverage` 区分边界组和区域组，返回遗漏位置而不猜测物理条件。文件消费者见 [PUBLIC-TUTORIAL](docs/PUBLIC-TUTORIAL.md)，纯 MoonBit 消费者见 `examples/extract_boundary`；参考工具只用于验证。

仅线性选定维度支持边界处理，高阶交换与高阶质量认证分开；不保证扭曲网格外法向。没有工程客户、生产采用或求解正确性证据；教程不是实际工程项目。申请范围不包括CAD、网格生成和有限元求解器。

**公开状态（2026-09-29 核对）**：GitHub [公开仓库](https://github.com/cheng-jun56/moonbit-gmsh)、[Mooncakes 0.2.0](https://mooncakes.io/docs/cheng-jun56/gmsh@0.2.0) 已可访问；[CI 成功记录](https://github.com/cheng-jun56/moonbit-gmsh/actions/runs/36561957897) 对应 `97224fd4f014`。本次材料更新尚未推送；该远端 CI 对应所列公开提交。报名表一致性及赛事审核结果尚未核实。
