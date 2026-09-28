# MoonGmsh：MoonBit 内的网格边界交换与标签交付检查

拟替换旧 POP3 申报。换题、公开仓库和正式链接待团队办理；本地 `localreview/gmsh@0.2.0`。本页不代表已获准换题或通过初审。

面向在 MoonBit 内编写网格导入、前后处理和可视化准备代码的开发者，处理 MSH 2.2/4.1 文件，提供公共数据模型、拓扑/边界提取、节点与父单元来源、显式标签/稀疏字段保留、损失报告及受控导出。典型任务是检查导入网格的边界标签是否符合调用方要求，定位遗漏面，再把原始tag和来源一起交给下游。AI生成的转换脚本仍需可检查的标准语义、来源和失败边界；本库为这一任务提供可重复调用的核心，不以AI时代作为创新口号。

已有 Gmsh、meshio、[meshio++](https://github.com/loumalouomega/meshioplusplus) 和 [Gmsh Wasm](https://www.npmjs.com/package/@loumalouomega/gmsh-wasm)；通用交换、表面提取和父单元信息不是本项目独有。定向Mooncakes检索没有发现同范围直接包，不能证明不存在。差异限于 MoonBit 可组合数据/API、无外部解析器的运行时和明确的标签/损失契约；不宣称算法原创、全格式替代或性能优胜。成熟格式移植及标准工程工作流是申请价值，最终由赛事裁量。

实证是公开 Gmsh 教程生成的四种输入，404节点、726三角形、80条边界、10条未标注，实际 Gmsh/meshio 独立对照；新增公共 `Boundary::coverage` 区分边界与区域组，返回定位信息，不猜物理条件。可直接运行的文件消费者见 `docs/PUBLIC-TUTORIAL.md`，纯MoonBit消费者见 `examples/extract_boundary`。源码、回执和工具链固定；参考工具只用于开发验证。

仅线性选定维度支持边界处理，高阶交换与高阶质量认证分开；不保证扭曲网格外法向。没有工程客户、生产采用或求解正确性证据；教程不是实际工程项目。申请范围不包括CAD、网格生成和有限元求解器。

**验收复现与交付状态（2026-09-28 本地）**：以 moonc 0.10.14+7d59c7ec9 通过检查、JS/Wasm-GC 测试、构建、最小样例和离线 `moon package`；正式仓库、换题资格、远端 CI 和 Mooncakes 首发待办理。命令与能力边界见 [README](README.md)，自动检查见 [CI](.github/workflows/ci.yml)；本地通过不代表赛事审核通过。
