# Task01 Habitat-Lab 环境搭建记录

整理时间：2026-05-21

## 1. 本次目标

本次是在已经搭好的 Habitat-Sim 基础上，继续完成 Habitat-Lab 环境搭建。

前置环境已经具备：

- WSL：Ubuntu 24.04.4 LTS
- Conda 环境：`habitat`
- Python：`3.9.19`
- Habitat-Sim：`0.2.5`
- Habitat-Sim 测试场景：`skokloster-castle.glb`
- 数据根目录：`/home/tyros/embodied_ai/data`

本次 Habitat-Lab 的目标：

1. 使用 `habitat-lab v0.2.5`，和 `habitat-sim 0.2.5` 保持版本一致。
2. 安装 `habitat-lab`。
3. 安装 `habitat-baselines`。
4. 下载 PointNav 测试数据集。
5. 跑通一个 PointNav 最小环境验证。
6. 记录每一步做了什么、为什么这么做、遇到了什么问题。

## 2. 进入已有环境

PowerShell 中进入 WSL：

```powershell
wsl -d Ubuntu
```

Ubuntu 中激活 conda 环境：

```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate habitat
```

解释：

- `source ~/miniconda3/etc/profile.d/conda.sh` 用于让当前 shell 识别 `conda activate`。
- `conda activate habitat` 进入前面为 Habitat-Sim 创建的环境。
- Habitat-Lab 不需要重新建环境，应该和 Habitat-Sim 使用同一个环境，避免版本不一致。

## 3. 确认 Habitat-Lab 源码版本

当前源码目录：

```bash
/home/tyros/embodied_ai/habitat-lab
```

检查版本：

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

解释：

- `v0.2.5` 表示当前 Habitat-Lab 源码版本正确。
- `17ec6b3c1` 是当前源码 commit。
- 课程文档要求 Habitat-Lab 和 Habitat-Sim 版本对应，因此这里固定使用 `v0.2.5`。

## 4. 处理 GitHub TLS 报错

你执行：

```bash
git fetch --tags
```

遇到：

```text
fatal: unable to access 'https://github.com/facebookresearch/habitat-lab.git/':
gnutls_handshake() failed: The TLS connection was non-properly terminated.
```

判断：

- 这属于 WSL 中访问 GitHub 时的 TLS/网络连接中断问题。
- 因为本地仓库已经在 `v0.2.5`，所以这次不需要继续卡在 `git fetch --tags`。
- 后续需要访问 GitHub 或 PyPI 时，使用本机代理 `127.0.0.1:7897`。

可用代理设置：

```bash
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export ALL_PROXY=http://127.0.0.1:7897
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY
export all_proxy=$ALL_PROXY
```

如果后续确实需要重新拉 GitHub，可以这样做：

```bash
cd ~/embodied_ai/habitat-lab
git -c http.proxy=http://127.0.0.1:7897 \
    -c https.proxy=http://127.0.0.1:7897 \
    fetch --tags
```

## 5. 安装 pip

最开始执行 `pip install` 时报：

```text
No module named pip
```

原因：

- 当前 `habitat` conda 环境是用 conda 创建的干净环境，里面没有默认安装 pip。

处理：

```bash
conda install --override-channels -c conda-forge pip -y
```

解释：

- 使用 `conda-forge` 是为了避开 Anaconda defaults 仓库的 429 限流问题。
- 安装 pip 后，才能执行 `python -m pip install ...`。

## 6. 安装 Habitat-Lab

在源码根目录执行：

```bash
cd ~/embodied_ai/habitat-lab
python -m pip install -e habitat-lab
```

解释：

- `-e` 是 editable/develop 模式安装。
- 这种安装方式不会复制一份源码到 site-packages，而是让 Python 直接引用当前源码目录。
- 后续如果阅读或修改 Habitat-Lab 源码，不需要重新安装。

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

## 7. 安装 Habitat-Baselines

直接执行：

```bash
python -m pip install -e habitat-baselines
```

曾经超时，原因是它会拉取大型依赖，尤其是：

- `torch`
- `torchvision`
- `tensorboard`
- `moviepy`
- `lmdb`
- `webdataset`

因此改成分步安装。

### 7.1 安装 PyTorch CPU 版

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

解释：

- 这里使用 CPU 版 PyTorch，目的是先保证 Habitat-Baselines 能导入。
- Task01 阶段重点是搭建环境和跑通 PointNav，不需要马上训练大模型。
- 如果后续要训练强化学习模型，再考虑 CUDA 版 PyTorch。

### 7.2 安装其它 Baselines 依赖

```bash
python -m pip install \
  "protobuf==3.20.1" \
  "tensorboard==2.8.0" \
  "moviepy>=1.0.1" \
  "lmdb>=0.98" \
  "webdataset==0.1.40" \
  "ifcfg" \
  "faster-fifo>=1.4.2" \
  "threadpoolctl>=3.1.0"
```

解释：

- `protobuf==3.20.1` 是 Habitat-Baselines 指定版本。
- `tensorboard==2.8.0` 用于训练日志可视化。
- `moviepy` 用于视频生成。
- `lmdb`、`webdataset` 用于数据读取。
- `ifcfg` 常用于分布式训练时读取网络接口。
- `faster-fifo`、`threadpoolctl` 是 RL/并行相关依赖。

### 7.3 以 no-deps 模式安装 Baselines

```bash
cd ~/embodied_ai/habitat-lab
python -m pip install -e habitat-baselines --no-deps
```

解释：

- 前面已经手动安装过依赖。
- `--no-deps` 可以避免 pip 再次重新解析和下载大型依赖。
- 这样更稳定，也更容易定位安装问题。

安装结果：

```text
Successfully installed habitat-baselines-0.2.5
```

## 8. 安装脚本

本次整理了安装脚本：

```text
D:\Projects\Embodied_AI\scripts\setup_habitat_lab.sh
```

运行方式：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/setup_habitat_lab.sh
```

脚本作用：

1. 激活 `habitat` conda 环境。
2. 设置代理。
3. 安装 `habitat-lab`。
4. 安装 Habitat-Baselines 所需依赖。
5. 安装 `habitat-baselines`。

## 9. 建立数据软链接

已有数据目录：

```bash
/home/tyros/embodied_ai/data
```

Habitat-Lab 源码目录：

```bash
/home/tyros/embodied_ai/habitat-lab
```

建立软链接：

```bash
cd ~/embodied_ai/habitat-lab
ln -sfn ~/embodied_ai/data data
```

实际结果：

```text
data -> /home/tyros/embodied_ai/data
```

解释：

- Habitat-Lab 的配置文件默认会从当前项目的 `data/` 目录读取数据。
- 软链接可以复用已有 Habitat-Sim 数据。
- 这样不用重复下载场景，也能让配置文件中的相对路径正常工作。

## 10. 下载 PointNav 测试数据集

运行脚本：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/download_habitat_lab_data.sh
```

脚本内部执行的核心命令：

```bash
python -m habitat_sim.utils.datasets_download \
  --uids habitat_test_pointnav_dataset \
  --data-path data/
```

实际结果：

```text
Dataset (habitat_test_pointnav_dataset) successfully downloaded.
Source: '/home/tyros/embodied_ai/data/versioned_data/habitat_test_pointnav_dataset_1.0'
Symlink: '/home/tyros/embodied_ai/data/datasets/pointnav/habitat-test-scenes'
```

下载后的关键文件：

```text
data/datasets/pointnav/habitat-test-scenes/v1/train/train.json.gz
data/datasets/pointnav/habitat-test-scenes/v1/val/val.json.gz
data/datasets/pointnav/habitat-test-scenes/v1/test/test.json.gz
```

解释：

- Habitat-Sim 只负责场景仿真。
- Habitat-Lab 的 PointNav 任务还需要 episode 数据。
- `train.json.gz`、`val.json.gz`、`test.json.gz` 里面记录了起点、目标点、场景等任务信息。

## 11. PointNav 配置文件

实际找到的 PointNav 配置：

```text
habitat-lab/habitat/config/benchmark/nav/pointnav/pointnav_base.yaml
habitat-lab/habitat/config/benchmark/nav/pointnav/pointnav_habitat_test.yaml
habitat-lab/habitat/config/habitat/task/pointnav.yaml
habitat-lab/habitat/config/habitat/dataset/pointnav/habitat_test.yaml
```

`pointnav_habitat_test.yaml` 的核心逻辑：

```yaml
defaults:
  - pointnav_base
  - /habitat/dataset/pointnav: habitat_test
  - _self_

habitat:
  environment:
    max_episode_steps: 500
  simulator:
    agents:
      main_agent:
        sim_sensors:
          rgb_sensor:
            width: 256
            height: 256
          depth_sensor:
            width: 256
            height: 256
```

解释：

- `pointnav_base` 提供 PointNav 基础任务配置。
- `/habitat/dataset/pointnav: habitat_test` 指定使用测试场景数据集。
- `rgb_sensor` 和 `depth_sensor` 默认会启用图像渲染。
- 当前 WSL 环境里默认图像渲染有 EGL/CUDA 设备匹配问题，所以最小验证脚本里临时关闭了图像传感器。

## 12. 最小 PointNav 验证脚本

脚本路径：

```text
D:\Projects\Embodied_AI\scripts\verify_habitat_lab_pointnav.py
```

运行方式：

```bash
cd ~/embodied_ai/habitat-lab
python /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_lab_pointnav.py
```

PowerShell 一行命令：

```powershell
wsl -d Ubuntu -- bash -lc 'source ~/miniconda3/etc/profile.d/conda.sh && conda activate habitat && cd ~/embodied_ai/habitat-lab && python /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_lab_pointnav.py'
```

脚本做了什么：

1. 读取 `benchmark/nav/pointnav/pointnav_habitat_test.yaml`。
2. 设置最大 episode 步数为 10。
3. 关闭 `rgb_sensor` 和 `depth_sensor`，避免 WSL 离屏渲染问题。
4. 创建 `habitat.Env`。
5. 执行 `env.reset()`。
6. 打印 observation keys。
7. 打印 action space。
8. 执行 `move_forward / turn_left / move_forward / turn_right / stop`。
9. 打印 `distance_to_goal / success / spl`。
10. 关闭环境。

实际成功输出：

```text
Environment creation successful
Observation keys: ['pointgoal_with_gps_compass']
Action space: ActionSpace(move_forward:EmptySpace(), stop:EmptySpace(), turn_left:EmptySpace(), turn_right:EmptySpace())
Current episode id: 0
Current scene id: data/scene_datasets/habitat-test-scenes/skokloster-castle.glb
step=0, action=move_forward, episode_over=False, distance_to_goal=6.554908752441406, success=0.0, spl=0.0
step=1, action=turn_left, episode_over=False, distance_to_goal=6.554908752441406, success=0.0, spl=0.0
step=2, action=move_forward, episode_over=False, distance_to_goal=6.796191215515137, success=0.0, spl=0.0
step=3, action=turn_right, episode_over=False, distance_to_goal=6.796191215515137, success=0.0, spl=0.0
step=4, action=stop, episode_over=True, distance_to_goal=6.796191215515137, success=0.0, spl=0.0
PointNav verification finished
```

说明：

- `Environment creation successful`：Habitat-Lab 环境创建成功。
- `Observation keys: ['pointgoal_with_gps_compass']`：任务传感器可用。
- `ActionSpace(...)`：动作空间正常，包括前进、停止、左转、右转。
- `Current scene id` 指向 `skokloster-castle.glb`：场景路径正确。
- `distance_to_goal / success / spl` 能输出：评估指标正常。

## 13. 导入验证脚本

脚本路径：

```text
D:\Projects\Embodied_AI\scripts\verify_habitat_lab_imports.sh
```

运行方式：

```powershell
wsl -d Ubuntu -- bash /mnt/d/Projects/Embodied_AI/scripts/verify_habitat_lab_imports.sh
```

实际成功输出：

```text
habitat import ok
habitat_baselines import ok
habitat_sim 0.2.5
torch 2.2.2+cpu
torchvision 0.17.2+cpu
```

说明：

- `habitat`：Habitat-Lab 本体可用。
- `habitat_baselines`：Baselines 可用。
- `habitat_sim`：底层仿真器可用。
- `torch / torchvision`：Baselines 所需深度学习基础依赖可用。

## 14. 当前仍存在的限制

默认 RGB/Depth 图像渲染仍可能报：

```text
Platform::WindowlessEglApplication::tryCreateContext():
unable to find CUDA device 0 among 1 EGL devices in total
WindowlessContext: Unable to create windowless context
```

原因：

- 当前 WSL 可以识别 RTX 4060 Laptop GPU。
- 但 Habitat-Sim 的离屏 EGL 渲染和 WSL 的 CUDA/EGL 设备映射仍有兼容问题。

当前处理：

- Task01 阶段先关闭 `rgb_sensor` 和 `depth_sensor`。
- 保留 `pointgoal_with_gps_compass` 任务传感器。
- 先验证 Habitat-Lab 配置、数据集、任务、动作和指标链路。

后续如果需要图像渲染，可继续尝试：

1. 原生 Ubuntu Linux 环境。
2. 远程 Linux GPU 服务器。
3. 进一步配置 WSLg / EGL / CUDA 图形链路。
4. 改用可显示窗口的 viewer 或软件渲染方案。

## 15. 最终完成情况

本次 Habitat-Lab 搭建已经完成核心验证：

1. `habitat-lab v0.2.5` 已安装。
2. `habitat-baselines v0.2.5` 已安装。
3. `torch 2.2.2+cpu` 已安装。
4. `torchvision 0.17.2+cpu` 已安装。
5. `habitat_test_pointnav_dataset` 已下载。
6. `data` 软链接已建立。
7. PointNav 配置文件已定位。
8. PointNav 最小环境已跑通。
9. `env.reset()` 成功。
10. `env.step()` 成功。
11. `distance_to_goal / success / spl` 指标成功输出。

结论：

```text
Habitat-Lab 基础环境已可用于 Task01 的 PointNav 入门验证。
```

当前不建议立刻进入强化学习训练。下一步更合理的是先阅读 PointNav 配置文件，理解 dataset、simulator、task、measurements 之间的关系，然后再决定是否进入 Habitat-Baselines 训练流程。
