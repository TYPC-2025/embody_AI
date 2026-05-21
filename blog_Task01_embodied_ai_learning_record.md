# 从 0 开始整理具身智能 Task01：学习路线、Habitat 环境搭建与 GitHub 项目记录

整理时间：2026-05-21

相关仓库：

- 课程开源仓库：<https://github.com/datawhalechina/every-embodied>
- 我的项目仓库：<https://github.com/TYPC-2025/embody_AI>

## 写在前面

这篇笔记是我开始学习 Datawhale Every-Embodied 具身智能课程 Task01 时整理出来的记录。

刚开始看飞书页面的时候，第一感觉是内容很多，而且入口有点散：有具身智能概述，有机器人控制，有 PID，有 Cartpole，有 Habitat Sim / Habitat Lab，还有春晚机器人复刻、OpenVLA、SmolVLA、Pi0、ETPNav、Isaac、LeRobot 等一堆看起来很有意思但明显更复杂的方向。

如果直接从所有链接里随便点，很容易变成“每个都看了一点，但不知道自己到底完成了什么”。所以我先做了一件事：把 Task01 和后面 Task02 到 Task05 的内容切开，只保留当前阶段真正需要完成的部分。

最后我把 Task01 理解成四条主线：

1. 具身智能概述：先弄清楚具身智能到底在研究什么。
2. 机器人空间基础：理解坐标系、位姿、坐标变换这些机器人学最基础的语言。
3. 控制基础：从 PID 和 Cartpole 入手，理解状态、误差、动作、反馈闭环。
4. 具身导航初步：重点看 Habitat Sim 和 Habitat Lab，完成环境搭建或最小示例验证。

其中，飞书页面里明确写了“具身导航基础（优先完成作业）”。因此我把 Task01 的实践重点放在 Habitat Sim / Habitat Lab 上，其他内容主要作为概念铺垫。

## 一、Task01 到底要学什么

飞书页面里 Task01 的原始描述是：

```text
Task01：具身智能基础与机器人控制，
具身智能概述与发展，
PID 控制算法实现，
机器人运动学基础，
具身导航初步（视频教程）
```

对应内容包括：

- 热门内容：春晚机器人复刻。
- 课程01：具身智能概述。
- 课程02：机器人基础和控制、手眼协调。
- 机器人空间描述与坐标变换。
- Cartpole 建模与控制。
- 具身导航基础。
- Habitat Sim 环境搭建及数据集介绍。
- Habitat Lab 环境搭建及配置。

我把这些内容按优先级重新排了一遍：

| 内容 | 我对它的定位 | 当前优先级 |
| --- | --- | --- |
| 具身智能概述 | 建立大方向，知道自己学的是什么 | 高 |
| 坐标系、位姿、坐标变换 | 机器人学最基本的表达方式 | 高 |
| PID 控制 | 理解反馈控制的入口 | 高 |
| Cartpole | 把控制思想放到一个简单系统里理解 | 高 |
| Habitat Sim | 底层仿真器，负责场景、agent 和传感器 | 最高 |
| Habitat Lab | 任务框架，负责导航任务、数据集、指标和实验流程 | 最高 |
| 春晚机器人复刻 | 很有趣，但更像扩展项目 | 中 |
| OpenVLA / Pi0 / SmolVLA / ETPNav / Isaac / LeRobot | 后续分支内容 | 暂缓 |

这个拆分对我很关键。因为 Task01 不是要把整个具身智能版图全部学完，而是把“概念、空间表达、控制、导航仿真”这几块基础拼起来。

## 二、我对具身智能的第一层理解

具身智能不是单纯让大模型回答问题，也不是单纯做图像识别。它更强调智能体在环境中的行动能力。

我现在对它的理解可以写成一个闭环：

```text
感知环境 -> 理解任务 -> 做出决策 -> 执行动作 -> 接收反馈 -> 修正后续动作
```

这个闭环里，每一步都很重要：

- 感知环境：机器人通过相机、深度相机、IMU、触觉传感器等获得外界信息。
- 理解任务：系统需要知道目标是什么，比如“走到房间门口”或者“拿起桌上的杯子”。
- 做出决策：根据当前状态和目标，决定下一步动作。
- 执行动作：把决策转成移动、转向、夹爪张合、关节转动等动作。
- 接收反馈：动作执行后，环境状态发生变化，机器人需要重新观察。
- 修正后续动作：如果偏离目标，就继续调整。

传统 AI 很多时候面对的是静态输入，例如一张图片、一段文本、一条语音。具身智能面对的是动态环境，动作本身会改变世界，世界的变化又会影响下一步动作。

这也是为什么具身智能离不开机器人、控制、仿真和数据。只理解模型结构不够，还要理解机器人如何表示空间、如何控制运动、如何在环境中验证任务。

## 三、为什么 Task01 要先学坐标系和位姿

刚开始看“机器人空间描述与坐标变换”的时候，容易觉得这部分很数学。但后来我发现，它其实是在解决一个非常朴素的问题：

```text
同一个物体，在不同参考系里应该怎么描述？
```

比如相机看到了一个杯子，杯子在相机坐标系下的位置是一个坐标。但机械臂真正要执行抓取时，它需要知道杯子相对于机械臂基座在哪里，或者相对于末端夹爪在哪里。

这中间就需要坐标变换。

### 1. 坐标系

我把坐标系理解成“观察世界的参考标准”。

常见坐标系包括：

- 世界坐标系：整个环境的全局参考。
- 机器人基座坐标系：以机器人底座为参考。
- 末端执行器坐标系：以机械臂夹爪、吸盘、工具端为参考。
- 相机坐标系：以相机为参考。
- 目标物体坐标系：以被操作的物体为参考。

同一个点，在不同坐标系下的数值通常不同，但它表示的物理位置是同一个。

### 2. 位姿

位姿包含两个部分：

```text
位姿 = 位置 + 姿态
```

位置回答“在哪里”，姿态回答“朝向哪里”。

在二维平面中，位姿可能是：

```text
(x, y, theta)
```

在三维空间中，位置通常是：

```text
(x, y, z)
```

姿态可以用旋转矩阵、欧拉角、四元数等方式表示。

### 3. 齐次变换矩阵

机器人里经常用齐次变换矩阵把旋转和平移合在一起。

一个变换矩阵大致表达的是：

```text
从坐标系 A 到坐标系 B：
既要旋转多少，又要平移多少。
```

它的作用是把一个点从一个坐标系转换到另一个坐标系。

这部分内容和后面的抓取、导航、手眼协调关系都很紧密：

- 抓取任务里，相机看到的目标要转换到机械臂坐标系。
- 导航任务里，agent 的位置要放到地图或场景坐标系中理解。
- 手眼协调里，相机、末端执行器、机器人基座之间必须有稳定的空间关系。

## 四、机器人运动学与 DH 参数的学习记录

我还单独整理了一份机器人运动学与 DH 参数笔记，文件是：

```text
README.md
```

这部分内容的核心问题是：

```text
已知每个关节转了多少，机械臂末端现在在哪里、朝向哪里？
```

这就是正运动学，英文是 Forward Kinematics，简称 FK。

### 1. 正运动学的输入和输出

正运动学的输入是关节变量，输出是末端执行器位姿。

可以写成：

```text
关节角度 / 关节位移 -> 末端执行器位置和姿态
```

二维二连杆机械臂是最容易理解的例子。

假设：

- 第一段连杆长度是 `L1`。
- 第二段连杆长度是 `L2`。
- 第一个关节角度是 `theta1`。
- 第二个关节角度是 `theta2`。

末端位置可以写成：

```text
x = L1*cos(theta1) + L2*cos(theta1 + theta2)
y = L1*sin(theta1) + L2*sin(theta1 + theta2)
```

这两个式子背后的直觉很清楚：

- 第一段连杆先从原点伸出去。
- 第二段连杆不是单独按 `theta2` 旋转，而是在第一段已经旋转 `theta1` 的基础上继续旋转。
- 所以第二段的绝对方向是 `theta1 + theta2`。

### 2. DH 参数在做什么

真实机械臂不是简单的二维二连杆，而是很多关节和连杆组成的三维结构。

DH 参数的作用是用一套统一规则描述相邻连杆坐标系之间的关系。

经典 DH 参数包括四个量：

| 参数 | 含义 |
| --- | --- |
| `theta` | 绕 z 轴旋转的角度 |
| `d` | 沿 z 轴平移的距离 |
| `a` | 沿 x 轴平移的距离 |
| `alpha` | 绕 x 轴旋转的角度 |

每一组 DH 参数都能写成一个相邻坐标系之间的齐次变换矩阵。

多个关节串起来之后，整体位姿就是矩阵连乘：

```text
T_0_n = T_0_1 * T_1_2 * T_2_3 * ... * T_(n-1)_n
```

我的理解是：DH 参数不是为了把问题变复杂，而是为了让机械臂每一段的几何关系都能被统一写进矩阵里。

## 五、控制基础：PID 和 Cartpole

Task01 里还有一块控制基础，其中最重要的是 PID 和 Cartpole。

我对控制的理解是：

```text
控制就是让系统从当前状态逐渐接近目标状态。
```

这里面一定有一个反馈闭环：

```text
设定目标 -> 读取当前状态 -> 计算误差 -> 输出动作 -> 系统状态变化 -> 再次读取状态
```

### 1. PID 的三个部分

PID 包括三项：

| 项 | 含义 | 我的理解 |
| --- | --- | --- |
| P | Proportional，比例项 | 当前误差越大，动作越大 |
| I | Integral，积分项 | 累计历史误差，消除长期偏差 |
| D | Derivative，微分项 | 关注误差变化速度，抑制震荡 |

P 项像是“看到偏差就立刻纠正”。

I 项像是“长期有偏差就继续补偿”。

D 项像是“看到变化太快就提前刹一下”。

PID 真正难的地方不是公式，而是参数调节。比例太小会反应慢，比例太大容易震荡；积分太大容易超调；微分对噪声敏感。

### 2. Cartpole 为什么适合入门

Cartpole 是一个小车上立着一根杆的系统。目标是控制小车左右移动，让杆尽量不倒。

它的状态一般包括：

- 小车位置。
- 小车速度。
- 杆的角度。
- 杆的角速度。

它的动作是：

- 给小车一个向左或向右的力。

它的目标是：

- 杆保持竖直。
- 小车不要偏离太远。

Cartpole 看起来简单，但它把具身智能和机器人控制中很重要的几个词串起来了：

```text
状态、动作、误差、反馈、稳定性
```

后面不管是移动机器人、机械臂还是无人机，本质上都会遇到类似问题：系统现在在哪里，目标在哪里，下一步动作应该怎么输出，动作之后状态会怎么变。

## 六、Habitat Sim 与 Habitat Lab 的区别

Task01 实践部分我优先放在 Habitat 上。

我先把 Habitat Sim 和 Habitat Lab 的关系分清楚：

| 名称 | 定位 | 我的理解 |
| --- | --- | --- |
| Habitat Sim | 底层仿真器 | 负责加载 3D 场景、模拟 agent 移动、提供传感器观测 |
| Habitat Lab | 上层任务框架 | 负责定义导航任务、数据集、配置文件、指标和训练/评估流程 |

如果只看 Habitat Sim，更像是在问：

```text
虚拟环境能不能加载？agent 能不能在里面移动？传感器能不能产生观测？
```

如果看 Habitat Lab，更像是在问：

```text
这个导航任务怎么定义？数据集在哪里？评价指标是什么？实验流程怎么跑？
```

所以我的实践顺序是：

```text
先搭 Habitat Sim -> 再搭 Habitat Lab -> 最后跑 PointNav 最小验证
```

## 七、我的 Habitat 环境信息

我的环境最终整理如下：

| 项目 | 信息 |
| --- | --- |
| Windows 项目目录 | `D:\Projects\Embodied_AI` |
| WSL 发行版 | `Ubuntu 24.04.4 LTS` |
| WSL 版本 | `WSL2` |
| WSL 用户 | `tyros` |
| WSL 工作目录 | `/home/tyros/embodied_ai` |
| Conda 安装位置 | `/home/tyros/miniconda3` |
| Conda 环境名 | `habitat` |
| Python 版本 | `3.9.19` |
| Habitat-Sim 版本 | `0.2.5` |
| Habitat-Sim 源码版本 | `v0.2.5`, commit `c8887c8` |
| Habitat-Lab 版本 | `v0.2.5`, commit `17ec6b3c1` |
| Habitat-Baselines 版本 | `0.2.5` |
| GPU | NVIDIA GeForce RTX 4060 Laptop GPU，WSL 中可识别 |

这里有一个很重要的点：Habitat Sim 和 Habitat Lab 的版本要对齐。

我固定使用：

```text
habitat-sim 0.2.5
habitat-lab v0.2.5
```

这样能减少 API、配置文件和依赖版本不一致带来的问题。

## 八、Habitat Sim 搭建过程

Habitat Sim 部分已经完成基础搭建和无图像传感器示例验证。

### 1. 已完成内容

我完成了这些步骤：

1. 在 WSL Ubuntu 中安装 Miniconda。
2. 创建 `habitat` conda 环境。
3. 安装 `habitat-sim=0.2.5`。
4. 安装 `git-lfs`。
5. 下载 `habitat_test_scenes`。
6. 下载 `habitat_example_objects`。
7. 克隆 `facebookresearch/habitat-sim` 源码，并切换到 `v0.2.5`。
8. 验证 `import habitat_sim` 成功。
9. 在关闭 color sensor 的情况下运行 `example.py`，验证场景加载和 agent 动作。

### 2. 关键路径

数据目录：

```bash
/home/tyros/embodied_ai/data
```

测试场景：

```bash
/home/tyros/embodied_ai/data/scene_datasets/habitat-test-scenes/skokloster-castle.glb
```

示例对象：

```bash
/home/tyros/embodied_ai/data/objects/example_objects
```

Habitat-Sim 源码：

```bash
/home/tyros/embodied_ai/habitat-sim
```

### 3. 验证脚本

我在项目里保留了验证脚本：

```text
scripts/verify_habitat_sim.sh
```

在 PowerShell 中运行：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_sim.sh
```

成功输出里会包含：

```text
habitat_sim import ok
habitat_sim 0.2.5
```

### 4. 运行无渲染示例

当前 WSL 环境中，默认彩色渲染会遇到 EGL/CUDA 设备匹配问题。因此我先关闭 color sensor，验证最基础的场景加载和 agent 动作。

脚本是：

```text
scripts/run_habitat_example_no_render.sh
```

PowerShell 中运行：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/run_habitat_example_no_render.sh
```

成功输出中会出现类似信息：

```text
action move_forward
position [...]
========================= Performance ========================
640 x 480, total time 0.00 s, frame time 0.228 ms (4378.2 FPS)
```

这说明基础仿真链路已经能跑起来。

### 5. 当前遗留问题

默认命令：

```bash
python examples/example.py --scene ~/embodied_ai/data/scene_datasets/habitat-test-scenes/skokloster-castle.glb
```

在当前 WSL 中会报：

```text
Platform::WindowlessEglApplication::tryCreateContext(): unable to find CUDA device 0 among 1 EGL devices in total
WindowlessContext: Unable to create windowless context
```

我的判断是：这不是 Habitat Sim 完全不可用，而是 WSL 下默认 color sensor 的离屏 EGL 渲染与 CUDA/EGL 设备匹配存在兼容问题。

目前阶段的处理方式是：

```text
先关闭 color sensor，完成基础环境验证。
```

Task01 的重点是理解 Habitat 基础链路和完成最小示例。图像渲染问题可以留到后续继续处理，例如改 WSL OpenGL/EGL 链路，或者换原生 Linux / 远程 Linux 服务器。

## 九、Habitat Lab 搭建过程

Habitat Lab 是在 Habitat Sim 基础上继续做的。

### 1. 前置环境

前置环境已经具备：

- WSL：Ubuntu 24.04.4 LTS
- Conda 环境：`habitat`
- Python：`3.9.19`
- Habitat-Sim：`0.2.5`
- Habitat-Sim 测试场景：`skokloster-castle.glb`
- 数据根目录：`/home/tyros/embodied_ai/data`

### 2. Habitat Lab 的目标

我这一步的目标是：

1. 使用 `habitat-lab v0.2.5`，和 `habitat-sim 0.2.5` 保持一致。
2. 安装 `habitat-lab`。
3. 安装 `habitat-baselines`。
4. 下载 PointNav 测试数据集。
5. 跑通一个 PointNav 最小环境验证。
6. 记录所有报错和处理方式。

### 3. 进入环境

PowerShell 中进入 WSL：

```powershell
wsl -d Ubuntu
```

Ubuntu 中激活 conda 环境：

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate habitat
```

我没有重新创建一个环境，而是在已有 `habitat` 环境中继续安装 Habitat Lab。原因是 Habitat Lab 和 Habitat Sim 版本必须匹配，分开环境反而容易出现“Lab 里找不到 Sim”或版本不一致的问题。

### 4. 确认源码版本

源码目录：

```bash
/home/tyros/embodied_ai/habitat-lab
```

检查命令：

```bash
cd ~/embodied_ai/habitat-lab
git status --short --branch
git describe --tags --exact-match
git rev-parse --short HEAD
```

实际结果：

```text
v0.2.5
17ec6b3c1
```

这一步确认了 Habitat Lab 源码版本正确。

### 5. 处理 GitHub TLS 报错

执行：

```bash
git fetch --tags
```

遇到：

```text
fatal: unable to access 'https://github.com/facebookresearch/habitat-lab.git/':
gnutls_handshake() failed: The TLS connection was non-properly terminated.
```

我的判断：

- 这是 WSL 中访问 GitHub 的 TLS/网络中断问题。
- 因为本地仓库已经处在 `v0.2.5`，所以没有继续卡在 `git fetch --tags`。
- 后续访问 GitHub 或 PyPI 时，使用本机代理 `127.0.0.1:7897`。

代理设置：

```bash
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export ALL_PROXY=http://127.0.0.1:7897
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY
export all_proxy=$ALL_PROXY
```

### 6. 安装 pip

最开始执行 `pip install` 时遇到：

```text
No module named pip
```

原因是当前 conda 环境很干净，没有默认安装 pip。

处理命令：

```bash
conda install --override-channels -c conda-forge pip -y
```

这里使用 `conda-forge` 是为了绕开 Anaconda defaults 仓库的 HTTP 429 限流问题。

### 7. 安装 Habitat Lab

在源码根目录执行：

```bash
cd ~/embodied_ai/habitat-lab
python -m pip install -e habitat-lab
```

`-e` 表示 editable/develop 模式安装。

这种方式不会把源码复制一份到 `site-packages`，而是让 Python 直接引用当前源码目录。后面如果阅读或者修改 Habitat Lab 源码，不需要反复重新安装。

安装结果：

```text
Successfully installed habitat-lab-0.2.5
```

关键依赖包括：

- `gym==0.23.0`
- `hydra-core==1.3.2`
- `omegaconf==2.3.0`
- `opencv-python==4.11.0.86`
- `PyYAML==6.0.3`

### 8. 安装 Habitat Baselines

直接安装：

```bash
python -m pip install -e habitat-baselines
```

中间曾经超时，主要原因是 Baselines 会拉取比较大的依赖：

- `torch`
- `torchvision`
- `tensorboard`
- `moviepy`
- `lmdb`
- `webdataset`

因此我改成分步安装。

先安装 PyTorch CPU 版：

```bash
python -m pip install \
  --index-url https://download.pytorch.org/whl/cpu \
  torch==2.2.2 \
  torchvision==0.17.2
```

实际安装结果：

```text
torch 2.2.2+cpu
torchvision 0.17.2+cpu
```

Task01 阶段主要是搭建环境、导入模块、跑通最小 PointNav，不是训练大型强化学习模型，所以 CPU 版 PyTorch 已经够用。

## 十、PointNav 最小验证

Habitat Lab 的一个核心任务是 PointNav。

PointNav 可以理解成：

```text
给 agent 一个目标点，让它从当前位姿移动到目标位置。
```

我这里的目标不是训练一个智能导航模型，而是先确认：

- Habitat Lab 能导入。
- 数据集路径能识别。
- 配置文件能加载。
- 环境能创建。
- 一个最小 episode 能跑起来。

项目里保留的验证脚本是：

```text
scripts/verify_habitat_lab_pointnav.py
```

同时还有：

```text
scripts/verify_habitat_lab_imports.sh
scripts/setup_habitat_lab.sh
scripts/download_habitat_lab_data.sh
```

我把脚本保留下来，是因为环境搭建最怕“当时能跑，过两天忘了怎么跑”。脚本本身就是复现实验的一部分。

## 十一、这次 Habitat 搭建中遇到的问题

### 1. WSL 已经存在

一开始 Windows 中已经有 WSL，`wsl --install` 提示发行版已存在。

处理方式：

```text
直接使用已有 Ubuntu，确认它是 WSL2。
```

### 2. WSL 中没有 conda

WSL 环境最开始没有 conda。

处理方式：

```text
在 WSL 内独立安装 Miniconda 到 /home/tyros/miniconda3。
```

### 3. Anaconda defaults 仓库 HTTP 429

conda 使用 defaults 仓库时遇到 HTTP 429 限流。

处理方式：

```bash
conda install --override-channels -c conda-forge ...
```

后续尽量显式指定 `conda-forge` 和 `aihabitat`。

### 4. `habitat_sim` 导入缺少 OpenGL 库

首次导入 `habitat_sim` 时缺少：

```text
libOpenGL.so.0
```

处理方式：

```text
在 conda 环境中安装 libopengl、libegl、libgl。
```

### 5. 数据下载缺少 Git LFS

下载 Habitat 测试数据时需要 Git LFS。

处理方式：

```bash
git lfs install
```

并安装对应依赖。

### 6. 默认彩色渲染的 EGL/CUDA 问题

默认 color sensor 渲染在 WSL 中遇到 EGL/CUDA 设备匹配问题。

处理方式：

```text
Task01 阶段先关闭 color sensor，完成基础仿真动作验证。
```

这个问题没有被当成 Task01 的阻塞项。因为当前目标是把 Habitat 基础链路跑通，而不是马上拿到高质量渲染图像。

### 7. GitHub 网络连接问题

访问 GitHub 时遇到过：

```text
Recv failure: Connection was reset
```

以及 WSL 中的：

```text
gnutls_handshake() failed
```

处理方式：

```text
使用本机代理 127.0.0.1:7897。
```

## 十二、春晚舞蹈机器人复刻的理解

Task01 页面里还有一个“热门内容：春晚机器人复刻”。我也单独整理了一份路线：

```text
Task01_spring_festival_robot_replication_plan.md
```

这部分很吸引人，但我没有把它作为 Task01 的主线实践。原因是它涉及的视频人体动作恢复、SMPL-X、动作重定向、机器人动作可视化、MuJoCo 等内容更多，比较适合作为后续扩展。

我目前对它的理解是：

```text
视频或文字动作 -> 人体动作 -> 标准人体模型 -> 机器人动作 -> 可视化或仿真验证
```

课程文档里的核心流程是：

```text
Prompt / Video -> PromptHMR -> SMPL-X -> GMR -> Robot Motion
```

拆开来看：

| 组件 | 作用 |
| --- | --- |
| PromptHMR | 从视频或 prompt 中恢复人体姿态 |
| SMPL-X | 用统一人体模型表示动作 |
| GMR | 把人体动作重定向到机器人 |
| robot_motion.pkl | 保存机器人动作结果 |
| robot-viser | Web 3D 可视化 |
| MuJoCo | 物理仿真与动作录制 |

我把春晚机器人复刻分成三个层级：

| 层级 | 目标 | 难度 |
| --- | --- | --- |
| 视觉效果复刻 | 可视化里机器人看起来像在跳类似动作 | 入门 |
| 仿真运动复刻 | 在 MuJoCo / IsaacSim 等物理仿真中稳定播放 | 进阶 |
| 真实机器人复刻 | 让真实机器人执行舞蹈或武术动作 | 高阶 |

Task01 阶段更适合做第一层：先跑通动作转换链路和可视化，不急着追求真实机器人控制。

## 十三、本地项目与 GitHub 上传流程

除了课程学习，我还把当前文件夹整理成了一个 Git 项目，并绑定到了 GitHub 仓库。

本地目录：

```text
D:\Projects\Embodied_AI
```

GitHub 仓库：

```text
https://github.com/TYPC-2025/embody_AI
```

Git 配置：

```text
user.name  = time-yielder-2025
user.email = tangyaowinty@outlook.com
```

远程仓库：

```text
origin https://github.com/TYPC-2025/embody_AI.git
```

分支：

```text
main
```

### 1. `.gitignore`

我增加了 `.gitignore`，主要忽略这些内容：

- Python 缓存。
- 虚拟环境。
- IDE 配置。
- 本地日志。
- 数据集。
- 模型文件。
- 输出目录。
- checkpoints。

这些内容不适合直接提交到 GitHub，尤其是数据集、模型权重和输出文件，很容易让仓库变得巨大。

### 2. 一键上传脚本

我写了一个 PowerShell 脚本：

```text
push_to_github.ps1
```

它的作用是把常用 Git 操作合成一次：

```powershell
git add -A
git commit -m "提交说明"
git push origin main
```

脚本支持自定义提交信息：

```powershell
.\push_to_github.ps1 -Message "Add Task01 blog note"
```

如果没有写提交信息，脚本会自动生成带时间的提交说明。

脚本里还加入了代理检测：

```powershell
$proxyHost = "127.0.0.1"
$proxyPort = 7897
```

如果本机代理可用，它会自动设置：

```powershell
$env:HTTP_PROXY
$env:HTTPS_PROXY
$env:ALL_PROXY
```

这样在 GitHub 直连失败时，上传流程更稳定。

### 3. 为什么没有做“每保存一次就自动上传”

我没有把流程做成“文件一保存就自动 push”。

原因很现实：

- 临时代码可能还不能运行。
- 报错中的中间状态可能不适合提交。
- 自动频繁提交会让 Git 历史变乱。
- 写博客或代码时，经常需要先试错、再整理。

现在的方式是：

```text
写完一段内容 -> 确认状态 -> 手动运行脚本 -> 上传 GitHub
```

这个节奏更适合学习型项目。

## 十四、当前项目文件结构

当前项目里比较重要的文件包括：

```text
D:\Projects\Embodied_AI
  ├─ README.md
  ├─ Task01_learning_plan.md
  ├─ Task01_habitat_sim_setup_record.md
  ├─ Task01_habitat_lab_setup_record.md
  ├─ Task01_spring_festival_robot_replication_plan.md
  ├─ blog_Task01_embodied_ai_learning_record.md
  ├─ push_to_github.ps1
  ├─ main.py
  └─ scripts
      ├─ download_habitat_data.sh
      ├─ download_habitat_lab_data.sh
      ├─ run_habitat_example_no_render.sh
      ├─ setup_habitat_lab.sh
      ├─ verify_habitat_lab_imports.sh
      ├─ verify_habitat_lab_pointnav.py
      └─ verify_habitat_sim.sh
```

每个文件的作用：

| 文件 | 作用 |
| --- | --- |
| `README.md` | 机器人运动学与 DH 参数学习笔记 |
| `Task01_learning_plan.md` | Task01 零基础学习顺序 |
| `Task01_habitat_sim_setup_record.md` | Habitat Sim 搭建记录 |
| `Task01_habitat_lab_setup_record.md` | Habitat Lab 搭建记录 |
| `Task01_spring_festival_robot_replication_plan.md` | 春晚机器人复刻路线 |
| `blog_Task01_embodied_ai_learning_record.md` | 当前这篇博客稿 |
| `push_to_github.ps1` | 一键提交并上传 GitHub |
| `scripts/*.sh` | Habitat 数据下载、安装和验证脚本 |
| `scripts/verify_habitat_lab_pointnav.py` | PointNav 最小验证脚本 |

## 十五、我对 Task01 的阶段性总结

这一阶段最有价值的不是“看了多少链接”，而是把 Task01 的主线理清楚了。

我现在对 Task01 的理解是：

```text
具身智能概念
  -> 机器人空间表达
  -> 控制反馈思想
  -> Habitat 导航仿真环境
```

这四步之间是有关系的：

- 具身智能需要智能体在环境中行动。
- 行动需要描述空间位置和姿态。
- 机器人运动需要控制系统。
- 导航任务需要仿真环境来定义、验证和评估。

Habitat Sim / Habitat Lab 的搭建让我真正接触到了具身导航的工程侧：不是只看概念，而是要处理 Python 版本、conda 环境、源码版本、数据集、依赖安装、渲染后端、GPU/WSL 兼容、GitHub 网络等一堆真实问题。

这也让我更清楚地意识到，具身智能不是单点知识，而是一条链路：

```text
算法 -> 仿真 -> 数据 -> 控制 -> 工程环境 -> 可复现结果
```

## 十六、后续学习计划

Task01 后，我的下一步不是马上跳到所有前沿模型，而是继续按课程节奏推进。

### 1. Task02

Task02 主要补通识基础：

- 视觉感知。
- 深度估计。
- 3D 重建。
- SAM。
- 抓取注意力热图。
- 强化学习基础。
- ManiSkill 或 GenieSim 二选一。

我更倾向于先选一个轻量实践，不同时安装多个仿真环境。

### 2. Task03

Task03 开始分支选择。

目前我比较感兴趣的方向有两个：

1. 导航模型与 VLN。
2. 操作模型与世界模型。

如果延续当前 Habitat 环境，导航分支会更顺。

如果后面转向机械臂操作，MuJoCo、ACT、Pi0、SmolVLA、OpenVLA 这些内容会更重要。

### 3. Task04 和 Task05

Task04 更像是沿一个方向深入，Task05 更像是成果整理。

这也提醒我，学习过程不能只留下“我看过什么”，还要留下：

- 环境配置记录。
- 可复现实验脚本。
- 报错和解决方法。
- 运行截图或输出。
- 对概念的重新表述。
- 后续能继续扩展的路线。

## 十七、目前还没有完全解决的问题

当前还有几个问题没有彻底解决：

1. Habitat Sim 默认 color sensor 在 WSL 中的 EGL/CUDA 匹配问题。
2. 如果后续需要训练模型，CPU 版 PyTorch 明显不够，需要重新规划 CUDA 版 PyTorch。
3. Habitat 的图像渲染、录屏、可视化截图还需要单独处理。
4. 春晚机器人复刻还停留在路线分析阶段，没有正式跑完整 PromptHMR -> GMR 链路。
5. 后续 GitHub 上传如果换网络环境，代理端口可能需要重新确认。

这些问题都不是坏事。它们反而说明当前记录已经进入真实工程环境，而不是只停在概念层。

## 十八、结尾

Task01 对我来说不是一个“看完课程页面”的任务，而是一次把具身智能入门路线拆清楚的过程。

刚开始我看到的是一堆链接：

```text
具身智能概述、PID、Cartpole、Habitat、春晚机器人、OpenVLA、SmolVLA、Pi0、ETPNav...
```

整理之后，它变成了一条更清楚的路线：

```text
先理解具身智能是什么
再理解机器人如何描述空间
再理解控制如何让系统接近目标
最后用 Habitat 进入具身导航仿真实践
```

目前我已经完成了：

- Task01 学习路线整理。
- 机器人运动学与 DH 参数笔记。
- Habitat Sim 基础环境搭建。
- Habitat Sim 无渲染示例验证。
- Habitat Lab 基础安装。
- PointNav 最小验证记录。
- 春晚机器人复刻路线分析。
- 本地项目 GitHub 仓库绑定。
- 一键上传脚本整理。

这一阶段最重要的收获是：面对一个内容很散的学习任务，先把范围切清楚，再把每一步产出留成文件。这样后面继续学 Task02、Task03 时，不会每次都从混乱里重新开始。
