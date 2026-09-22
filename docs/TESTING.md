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
```

12 组核心测试按缺陷机制组织：payload 首字节为换行值、大小端/size_t、
深复制、未知段/截断、字段改号、共享面、翻转、规则单纯形、非流形、
CRLF、极小非零面积、分类冲突。all-target check 不等于所有后端运行测试。
24 项 CLI 检查使用临时真实文件，覆盖输入/输出、创建、筛选/改号、
坏参数、禁止覆盖与 strict 退出码；只清理脚本自建临时目录。

独立脚本 540 请求 / 1,957 断言：

- meshio 17 类型 × 2 版本 × ASCII/二进制，双向比坐标、连接、物理名、字段。
- wedge15/pyramid13 缺于 meshio CellBlock 注册表，由 Python struct 生成并检查写出字节。
- 稀疏编号、多物理组、参数坐标、多帧时间、额外 tags、张量、大小端、size_t32/64；
  参数节点/稀疏二进制数据不受 meshio 完整支持，另用独立结构对照。
- NumPy 三角形/四面体 80 组；线性体单元外法向；VTK/OBJ 回读。
- 坏类型、重复/缺失引用、非有限值、溢出编号、截断、损失门禁。
- 81 节点/128 三角形与 4,225 节点/8,192 三角形合成场景，
  核对总面积/边界条数；计时含 JSON/宿主通信，不代表工业吞吐量。

meshio 5.3.5 ASCII 数据使用 numpy scalar repr，NumPy 2 默认产生非法 MSH
token np.float64(...)。生成阶段使用 NumPy legacy="1.25" 打印选项；
未放宽 MoonBit 解析器接受非法 token。VTK 棱柱回读采用 9.3 / meshio 约定。

evidence/reference.json 记录 *.mbt、moon 配置及脚本 LF 规范化 SHA-256，
避免 Windows checkout 换行假差异；交付包另有原始字节 SHA-256。
计时/平台为证据生成时本机快照，不是远程 CI。
