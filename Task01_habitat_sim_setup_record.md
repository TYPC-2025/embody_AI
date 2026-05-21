# Task01 Habitat-Sim / Habitat-Lab 环境搭建记录

整理时间：2026-05-21

参考文档：

- Habitat-Sim 环境搭建及数据集介绍：`https://github.com/datawhalechina/every-embodied/blob/main/08-%E5%85%B7%E8%BA%AB%E5%AF%BC%E8%88%AA%E5%8F%8AVLN/02%E4%BB%BF%E7%9C%9F%E7%8E%AF%E5%A2%83%E5%9F%BA%E7%A1%80/habitat%E5%AF%BC%E8%88%AA%E7%8E%AF%E5%A2%83/habitat_sim%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA%E5%8F%8A%E6%95%B0%E6%8D%AE%E9%9B%86%E4%BB%8B%E7%BB%8D.md`
- Habitat-Lab 环境搭建及配置：`https://github.com/datawhalechina/every-embodied/blob/main/08-%E5%85%B7%E8%BA%AB%E5%AF%BC%E8%88%AA%E5%8F%8AVLN/02%E4%BB%BF%E7%9C%9F%E7%8E%AF%E5%A2%83%E5%9F%BA%E7%A1%80/habitat%E5%AF%BC%E8%88%AA%E7%8E%AF%E5%A2%83/habitat_lab%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA%E5%8F%8A%E9%85%8D%E7%BD%AE.md`

本文档分成两部分：

1. Habitat-Sim：已经完成基础搭建和无图像传感器示例验证。
2. Habitat-Lab：已经完成基础安装、PointNav 测试数据下载和最小 PointNav 环境验证。完整记录见 `Task01_habitat_lab_setup_record.md`。

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
- Habitat-Lab 版本：`v0.2.5`, commit `17ec6b3c1`
- Habitat-Baselines 版本：`0.2.5`
- GPU：WSL 中可识别 NVIDIA GeForce RTX 4060 Laptop GPU

## Habitat-Sim 已完成内容

1. 在 WSL Ubuntu 中安装 Miniconda。
2. 创建 `habitat` conda 环境。
3. 安装 `habitat-sim=0.2.5`。
4. 安装 `git-lfs`。
5. 下载 `habitat_test_scenes`。
6. 下载 `habitat_example_objects`。
7. 克隆 `facebookresearch/habitat-sim` 源码，并切换到 `v0.2.5`。
8. 验证 `import habitat_sim` 成功。
9. 验证 `example.py` 在关闭 color sensor 的情况下可以加载场景并运行 agent 动作。

## Habitat-Sim 关键路径

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

Habitat-Lab 计划源码目录：

```bash
/home/tyros/embodied_ai/habitat-lab
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

## 下一阶段：Habitat-Lab 搭建目标

Habitat-Sim 更偏底层仿真器，负责加载 3D 场景、模拟 agent 行动、提供传感器观测。Habitat-Lab 更偏任务和实验框架，负责定义导航任务、数据集、指标、配置文件和训练/评估流程。

下一阶段不是重新搭环境，而是在当前已经可用的 `habitat` conda 环境里继续安装 `Habitat-Lab 0.2.5`。版本需要和当前 `Habitat-Sim 0.2.5` 对齐，避免 API 或配置文件不兼容。

目标是完成：

1. 克隆 `facebookresearch/habitat-lab` 源码，并切换到 `v0.2.5`。
2. 安装 `habitat-lab`。
3. 安装 `habitat-baselines`。
4. 建立 `habitat-lab/data -> ~/embodied_ai/data` 软链接，复用已有数据目录。
5. 下载 `habitat_test_pointnav_dataset`。
6. 跑通一个 PointNav 最小验证脚本。
7. 理解 PointNav YAML 配置中数据集、环境、模拟器、agent、task、measurement 的作用。

## Habitat-Lab 推荐执行顺序

### 1. 进入 WSL 和 conda 环境

PowerShell 中进入 Ubuntu：

```powershell
wsl -d Ubuntu
```

Ubuntu 中激活环境：

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate habitat
```

确认当前环境：

```bash
python --version
python -c "import habitat_sim; print(habitat_sim.__version__)"
```

期望结果：

```text
Python 3.9.19
0.2.5
```

### 2. 克隆 Habitat-Lab 0.2.5

```bash
cd ~/embodied_ai
git clone --branch v0.2.5 https://github.com/facebookresearch/habitat-lab.git
cd habitat-lab
```

如果目录已经存在，则使用：

```bash
cd ~/embodied_ai/habitat-lab
git fetch --tags
git checkout v0.2.5
```

确认版本：

```bash
git describe --tags --exact-match
git rev-parse --short HEAD
```

### 3. 安装 Habitat-Lab

在 `~/embodied_ai/habitat-lab` 目录下执行：

```bash
pip install -e habitat-lab
```

验证：

```bash
python -c "import habitat; print('habitat import ok')"
```

如果输出：

```text
habitat import ok
```

说明 `habitat-lab` 基础包可导入。

### 4. 安装 Habitat-Baselines

```bash
pip install -e habitat-baselines
```

验证：

```bash
python -c "import habitat_baselines; print('habitat_baselines import ok')"
```

`habitat-baselines` 主要用于强化学习、模仿学习、训练脚本和 baseline 算法。Task01 不一定需要训练模型，但按文档装上更完整。

### 5. 复用已有数据目录

前面 Habitat-Sim 的数据已经放在：

```bash
/home/tyros/embodied_ai/data
```

Habitat-Lab 默认经常从当前仓库的 `data/` 目录读取数据。为了避免重复下载和路径混乱，建议建立软链接：

```bash
cd ~/embodied_ai/habitat-lab
ln -sfn ~/embodied_ai/data data
```

检查：

```bash
ls -l data
ls data/scene_datasets/habitat-test-scenes/
```

期望能看到：

```text
skokloster-castle.glb
```

### 6. 下载 PointNav 测试数据集

当前已经有：

```text
habitat_test_scenes
habitat_example_objects
```

Habitat-Lab PointNav 还需要：

```text
habitat_test_pointnav_dataset
```

执行：

```bash
cd ~/embodied_ai/habitat-lab
python -m habitat_sim.utils.datasets_download \
  --uids habitat_test_pointnav_dataset \
  --data-path data/
```

检查数据：

```bash
ls data/datasets/pointnav/habitat-test-scenes/v1/
find data/datasets/pointnav/habitat-test-scenes/v1 -maxdepth 3 -type f | head
```

期望能看到类似：

```text
train/
val/
```

以及：

```text
train/train.json.gz
val/val.json.gz
```

### 7. 查找 PointNav 配置文件

在 `~/embodied_ai/habitat-lab` 中执行：

```bash
find habitat-lab -name "*pointnav*test*.yaml"
find habitat-lab -name "pointnav*.yaml" | head
```

重点关注类似：

```text
habitat-lab/habitat/config/benchmark/nav/pointnav/pointnav_habitat_test.yaml
```

如果配置文件位置和文档不完全一致，以实际 `find` 结果为准。

### 8. 编写最小 PointNav 验证脚本

建议在 Windows 项目目录中新增：

```text
D:\Projects\Embodied_AI\scripts\verify_habitat_lab_pointnav.py
```

初始脚本逻辑：

```python
import habitat
from habitat.config.default import get_config

config = get_config(
    "benchmark/nav/pointnav/pointnav_habitat_test.yaml"
)

env = habitat.Env(config=config)
obs = env.reset()

print("observation keys:", obs.keys())
print("action space:", env.action_space)

for i in range(5):
    obs = env.step("MOVE_FORWARD")
    print("step", i, "episode_over:", env.episode_over)

env.close()
```

运行方式：

```bash
cd ~/embodied_ai/habitat-lab
python /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_lab_pointnav.py
```

成功标准：

```text
能够创建 env
能够 reset
能够打印 observation keys
能够打印 action space
能够 step 若干次
能够 close
```

## Habitat-Lab 配置文件理解

Habitat-Lab 的核心不是单纯安装，而是理解 YAML 配置如何描述一个具身导航任务。

整体链路：

```text
YAML 配置
  -> Habitat-Lab 解析配置
  -> 创建 Dataset
  -> 创建 Simulator
  -> 创建 Task
  -> env.reset()
  -> env.step(action)
  -> 返回 observation / reward / done / metrics
```

### 1. `habitat.dataset`

作用：控制使用什么数据集、哪个 split、场景目录和 episode 文件路径。

常见字段：

```yaml
habitat:
  dataset:
    type: PointNav-v1
    split: train
    scenes_dir: data/scene_datasets
    data_path: data/datasets/pointnav/habitat-test-scenes/v1/{split}/{split}.json.gz
```

需要理解：

- `type`：任务数据集类型。
- `split`：使用 `train`、`val` 还是 `test`。
- `scenes_dir`：3D 场景所在目录。
- `data_path`：PointNav episode 文件路径。

### 2. `habitat.environment`

作用：控制一个 episode 的运行限制。

常见字段：

```yaml
habitat:
  environment:
    max_episode_steps: 500
```

含义：一个 episode 最多执行多少步，超过后任务结束。

### 3. `habitat.simulator`

作用：控制底层 Habitat-Sim 模拟器。

常见字段：

```yaml
habitat:
  simulator:
    type: Sim-v0
    forward_step_size: 0.25
    turn_angle: 10
```

需要理解：

- `type`：使用的模拟器类型。
- `forward_step_size`：`MOVE_FORWARD` 前进一步多少米。
- `turn_angle`：`TURN_LEFT` / `TURN_RIGHT` 每次转多少度。

### 4. `habitat.simulator.agents`

作用：控制智能体身体参数和仿真传感器。

常见字段：

```yaml
habitat:
  simulator:
    agents:
      main_agent:
        height: 1.5
        radius: 0.1
        sim_sensors:
          rgb_sensor:
            width: 256
            height: 256
          depth_sensor:
            width: 256
            height: 256
```

需要理解：

- `height`：agent 高度。
- `radius`：agent 碰撞半径。
- `rgb_sensor`：彩色图像传感器。
- `depth_sensor`：深度图传感器。

当前本机 WSL 对默认彩色渲染存在 EGL/CUDA 设备匹配问题，因此后续验证时可能需要先关闭 RGB/Depth 传感器，只保留任务传感器完成最小 PointNav 验证。

### 5. `habitat.task`

作用：控制任务类型、奖励、成功条件。

常见字段：

```yaml
habitat:
  task:
    type: Nav-v0
    reward_measure: distance_to_goal_reward
    success_measure: spl
    success_reward: 2.5
    slack_reward: -0.01
    end_on_success: true
```

需要理解：

- `type`：导航任务类型。
- `reward_measure`：奖励来自哪个 measurement。
- `success_measure`：用哪个指标判断成功。
- `success_reward`：成功奖励。
- `slack_reward`：每走一步的惩罚。
- `end_on_success`：成功后是否结束 episode。

### 6. `habitat.task.measurements`

作用：控制评估指标。

常见指标：

```text
distance_to_goal
success
spl
num_steps
distance_to_goal_reward
```

Task01 阶段重点理解：

- `success`：是否成功到达目标。
- `spl`：Success weighted by Path Length，综合成功率和路径效率。
- `distance_to_goal`：当前离目标还有多远。
- `num_steps`：当前 episode 已走步数。

## Habitat-Lab 验证标准

建议按三层验证：

### 1. 安装验证

```bash
python -c "import habitat; import habitat_baselines; import habitat_sim; print('ok')"
```

成功标准：

```text
ok
```

### 2. 数据验证

```bash
ls data/scene_datasets/habitat-test-scenes/
ls data/datasets/pointnav/habitat-test-scenes/v1/
```

成功标准：

```text
能看到 skokloster-castle.glb
能看到 train / val 或对应 json.gz 文件
```

### 3. 环境运行验证

```bash
python /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_lab_pointnav.py
```

成功标准：

```text
能够创建 Habitat Env
能够 reset
能够 step
能够 close
```

## 可能遇到的问题和处理思路

1. `habitat_sim` 和 `habitat_lab` 版本不匹配。
   - 处理：两者都固定使用 `v0.2.5` / `0.2.5`。

2. `pip install -e habitat-baselines` 依赖较多，安装慢。
   - 处理：先确保 `habitat-lab` 可导入，再安装 baselines。

3. 配置文件路径找不到。
   - 处理：使用 `find habitat-lab -name "*pointnav*.yaml"` 确认真实路径。

4. 数据集路径找不到。
   - 处理：确认 `~/embodied_ai/habitat-lab/data` 是否正确软链接到 `~/embodied_ai/data`。

5. RGB/Depth 渲染触发 EGL/CUDA 错误。
   - 处理：先做无图像传感器的最小 PointNav 验证。Task01 的重点是理解 Lab 配置和导航环境链路，不必一开始解决 WSL 图像渲染。

6. `defaults` 仓库触发 Anaconda HTTP 429 限流。
   - 处理：conda 命令优先使用 `--override-channels -c conda-forge -c aihabitat`。

## 后续真正实现时的文件计划

如果继续实际搭建 Habitat-Lab，建议新增：

```text
scripts/verify_habitat_lab_pointnav.py
scripts/setup_habitat_lab.sh
scripts/download_habitat_lab_data.sh
Task01_habitat_lab_setup_record.md
```

其中：

- `verify_habitat_lab_pointnav.py`：最小 PointNav 环境验证。
- `setup_habitat_lab.sh`：安装 `habitat-lab` 和 `habitat-baselines`。
- `download_habitat_lab_data.sh`：下载 PointNav 测试数据。
- `Task01_habitat_lab_setup_record.md`：记录实际安装命令、结果和踩坑。

也可以继续把 Habitat-Lab 的实际执行结果合并进当前文件，使 Task01 环境搭建记录保持在同一份文档中。
