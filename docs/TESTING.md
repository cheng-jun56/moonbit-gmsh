# 可复现核验

Windows 11，Moon 0.1.20260920 / moonc 0.10.14+7d59c7ec9，
Node 24.11.0，Python 3.14.4，meshio 5.3.5 / NumPy 2.5.3。
CI 配置 Linux/Windows/macOS 核心与 Linux 参考验证，尚未远端执行。

```sh
moon fmt --check
moon check --target all
moon test --target js
moon test --target wasm-gc
moon build --target js --release
moon info
node tools/check-cli.mjs
python -m pip install -r tools/requirements.txt
python tools/verify-reference.py
python tools/verify-boundary.py
moon run examples/extract_boundary --target js
moon run examples/extract_boundary --target wasm-gc
```

14 组核心测试按缺陷机制组织：payload 首字节为换行值、大小端/size_t、
深复制、未知段/截断、字段改号、共享面、翻转、规则单纯形、非流形、
CRLF、极小非零面积、分类冲突，以及中间乘积下溢导致的长薄四面体零体积、
长边微小分量被丢失导致的三角形零面积。all-target check 不等于所有后端运行测试。
24 项 CLI 检查使用临时真实文件，覆盖输入/输出、创建、筛选/改号、
坏参数、禁止覆盖与 strict 退出码；只清理脚本自建临时目录。

独立脚本 586 请求 / 2,053 断言：

- meshio 17 类型 × 2 版本 × ASCII/二进制，双向比坐标、连接、物理名、字段。
- wedge15/pyramid13 缺于 meshio CellBlock 注册表，由 Python struct 生成并检查写出字节。
- 稀疏编号、多物理组、参数坐标、多帧时间、额外 tags、张量、大小端、size_t32/64；
  参数节点/稀疏二进制数据不受 meshio 完整支持，另用独立结构对照。
- NumPy 三角形/四面体 80 组；线性体单元外法向；VTK/OBJ 回读。
- 100 位 Decimal 独立计算 11 种尺度组合的四面体体积/质量，分别检查正负朝向，
  并检查长边含微小分量的三角形。覆盖可表示的极端值、次正规数及不可表示时明确拒绝。
  例如轴长 `1e150, 1e-50, 1e-50` 的体积约 `1.666666666666667e49`，不能报零。
  本修复保护指数范围，不承诺解决任意近共面相消或提供精确朝向谓词。
- 坏类型、重复/缺失引用、非有限值、溢出编号、截断、损失门禁。
- 81 节点/128 三角形与 4,225 节点/8,192 三角形合成场景，
  核对总面积/边界条数；计时含 JSON/宿主通信，不代表工业吞吐量。

meshio 5.3.5 ASCII 数据使用 numpy scalar repr，NumPy 2 默认产生非法 MSH
token np.float64(...)。生成阶段使用 NumPy legacy="1.25" 打印选项；
未放宽 MoonBit 解析器接受非法 token。VTK 棱柱回读采用 9.3 / meshio 约定。

evidence/reference.json 记录 *.mbt、moon 配置及脚本 LF 规范化 SHA-256，
避免 Windows checkout 换行假差异；交付包另有原始字节 SHA-256。
计时/平台为证据生成时本机快照，不是远程 CI。

## 2026-09-22 边界增强

新增6组公开API测试块（全套20组）：来源/稀疏编号、显式边界属性和字段、
空闭环/额度、歧义/非流形/高阶、分类损失、未知段。严格all-target和两运行后端
与新增纯MoonBit示例均记录在当前 evidence/boundary-20260922.json。
独立脚本使用几何支持平面/直线，不复制本库面表；meshio双向，轻量ASCII解析最大tag，
真实CLI及最终OBJ/VTK下游回读。详细范围/计数见 boundary-reference.json。
已有参考也在变更后运行，回执另存 boundary-baseline-reference.json；reference.json保留历史。
公开接口、文档和示例纳入当前LF规范化源码散列，而不是只对核心文件抽样。
