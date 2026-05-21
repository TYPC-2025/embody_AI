# Task01 Habitat-Sim 环境搭建记录

整理时间：2026-05-21

## 环境信息

- Windows 侧项目目录：`D:\Projects\Embodied_AI`
- WSL 发行版：`Ubuntu 24.04.4 LTS`
- WSL 版本：`WSL2`
- WSL 用户：`tyros`
- WSL 工作目录：`/home/tyros/embodied_ai`
- Conda 安装位置：`/home/tyros/miniconda3`
- Conda 环境名：`habitat`
- Python 版本：`3.9.19`
- Habitat-Sim 版本：`0.2.5`
- Habitat-Sim 源码版本：`v0.2.5`, commit `c8887c8`
- GPU：WSL 中可识别 NVIDIA GeForce RTX 4060 Laptop GPU

## 已完成内容

1. 在 WSL Ubuntu 中安装 Miniconda。
2. 创建 `habitat` conda 环境。
3. 安装 `habitat-sim=0.2.5`。
4. 安装 `git-lfs`。
5. 下载 `habitat_test_scenes`。
6. 下载 `habitat_example_objects`。
7. 克隆 `facebookresearch/habitat-sim` 源码，并切换到 `v0.2.5`。
8. 验证 `import habitat_sim` 成功。
9. 验证 `example.py` 在关闭 color sensor 的情况下可以加载场景并运行 agent 动作。

## 关键路径

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

## 以后如何进入环境

在 PowerShell 中进入 Ubuntu：

```powershell
wsl -d Ubuntu
```

在 Ubuntu 中激活环境：

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate habitat
```

## 验证 Habitat-Sim 是否安装成功

在 PowerShell 中运行：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_sim.sh
```

成功输出应包含：

```text
habitat_sim import ok
habitat_sim 0.2.5
```

## 运行基础示例

当前 WSL 环境中，默认彩色渲染会遇到 EGL/CUDA 设备匹配问题。因此当前可稳定运行的验证命令是关闭 color sensor：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/run_habitat_example_no_render.sh
```

成功输出应包含 agent 动作和性能统计，例如：

```text
action move_forward
position [...]
========================= Performance ========================
640 x 480, total time 0.00 s, frame time 0.228 ms (4378.2 FPS)
```

## 当前遗留问题

默认命令：

```bash
python examples/example.py --scene ~/embodied_ai/data/scene_datasets/habitat-test-scenes/skokloster-castle.glb
```

在当前 WSL 中会报：

```text
Platform::WindowlessEglApplication::tryCreateContext(): unable to find CUDA device 0 among 1 EGL devices in total
WindowlessContext: Unable to create windowless context
```

这说明 Habitat-Sim 默认 color sensor 的离屏 EGL 渲染与当前 WSL GPU/EGL 设备匹配还有兼容问题。基础场景加载和仿真动作已经验证成功；如果后续需要图像渲染截图，需要继续处理 WSL 的 OpenGL/EGL/CUDA 渲染链路，或改用原生 Linux/远程 Linux 服务器。

## 本次搭建中遇到的问题

1. Windows 中已有 WSL，`wsl --install` 提示发行版已存在。
   - 处理：使用已有 `Ubuntu`，版本是 WSL2。

2. WSL 中没有 conda。
   - 处理：在 WSL 内安装独立 Miniconda 到 `/home/tyros/miniconda3`。

3. Anaconda defaults 仓库触发 HTTP 429 限流。
   - 处理：后续 conda 命令使用 `--override-channels -c conda-forge -c aihabitat`，避开 defaults。

4. `habitat_sim` 首次导入缺少 `libOpenGL.so.0`。
   - 处理：在 conda 环境中安装 `libopengl libegl libgl`。

5. 数据下载缺少 `git-lfs`。
   - 处理：在 conda 环境中安装 `git-lfs` 并执行 `git lfs install`。

6. 默认彩色渲染遇到 EGL/CUDA 设备匹配问题。
   - 处理：当前先使用 `--disable_color_sensor` 完成基础环境验证。
