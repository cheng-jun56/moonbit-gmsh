# 来源、验证工具与样例

本库自身采用根目录MIT LICENSE。按格式独立编写MoonBit核心，
不调用或复制Gmsh/VTK网格实现，不把meshio包装成本库核心。

| 外部来源 | 角色 | 许可证或使用边界 |
|---|---|---|
| [Gmsh格式规范](https://gmsh.info/doc/texinfo/gmsh.html#MSH-file-format) | MSH布局、单元编号与节点顺序 | 链接规范，不收录手册或Gmsh源码 |
| [VTK 9.3 wedge说明](https://github.com/Kitware/VTK/blob/v9.3.0/Common/DataModel/vtkWedge.h) | legacy VTK棱柱顺序核对 | 仅参考排列约定，无复制C++实现 |
| [meshio](https://github.com/nschloe/meshio/blob/main/LICENSE.txt) | 5.3.5 独立读写、格式转换函数调用 | MIT；仅开发验证 |
| [NumPy](https://github.com/numpy/numpy/blob/main/LICENSE.txt) | 2.5.3 几何参考计算 | BSD-3-Clause；仅开发验证 |

2026-09-22核对meshio/NumPy上游许可文本；版本见tools/requirements.txt。
源码包不分发这些依赖及其二进制环境。若以后打包开发环境，保留原发行包完整许可与版权文件；
本表不把外部手册、参考代码或工具改授本项目MIT，也不是完整传递依赖清单。

examples/triangle.msh为本项目自建三角形/温度样例。网格、物理组、字段和基准
此前均由项目测试/验证脚本合成。0.2.0新增公开Gmsh教程生成文件，见PUBLIC-TUTORIAL.md。
Decimal极端几何参考使用Python标准库。AI辅助开发与所有真实作者保留。

边界参考新增NumPy支持平面/直线枚举，未复制MoonBit面表；纯MoonBit四面体示例
及所有边界fixture均为自建合成数据。meshio最大tag稠密分配限制在BOUNDARY.md明确披露。

0.2.0：examples/public/t1.geo 是未修改的Gmsh教程，GPL-2.0-or-later；同目录GMSH-LICENSE.txt保留上游许可（取自实际安装的Gmsh4.15.2发行包）。四份MSH由该教程生成，来源与哈希见SOURCE.json。该第三方教程不改授本项目MIT。Gmsh4.15.2仅用于开发生成/独立读回，未分发运行库；Python参考依赖的许可保留在各自发行包。
