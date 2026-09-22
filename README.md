# MoonGmsh（开发中）

纯 MoonBit 的 MSH 2.2/4.1 网格交换与检查库。本地开发模块，不是已发布包。

当前已实现拥有式模型、ASCII/二进制读写、大小端与 4/8 字节 size_t、
稀疏编号、实体/物理组、NodeData/ElementData、未知文本段和显式损失门禁。
拓扑、几何检查、文件 CLI 与独立 meshio 核验仍在开发，不能据此宣称整项完成。

格式依据：[Gmsh 官方 MSH 手册](https://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format)。
独立实现，不包含 Gmsh 源码。MIT 许可证。
