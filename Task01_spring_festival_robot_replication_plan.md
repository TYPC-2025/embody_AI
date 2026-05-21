# 春晚舞蹈机器人复刻学习与实现路线

整理时间：2026-05-21

参考文档：

- Datawhale Every-Embodied：`https://github.com/datawhalechina/every-embodied/blob/main/07-%E6%9C%BA%E5%99%A8%E4%BA%BA%E6%93%8D%E4%BD%9C%E3%80%81%E8%BF%90%E5%8A%A8%E6%8E%A7%E5%88%B6/Locomotion/01%E6%98%A5%E6%99%9A%E8%88%9E%E8%B9%88%E6%9C%BA%E5%99%A8%E4%BA%BA%E5%A4%8D%E5%88%BB.md`
- 官方视频教程：`https://www.datawhale.cn/learn/content/258/6228`
- B 站视频教程：`https://www.bilibili.com/video/BV1gBfCBpEEb`

## 1. 先看结论

“春晚舞蹈机器人复刻”不是单纯让机器人播放一个视频，也不是单纯做人体姿态估计。它的本质是：

```text
从人类动作来源中提取人体运动
  -> 转成统一的人体骨架表示
  -> 再把人体动作重定向到机器人身体结构
  -> 最后在可视化或 MuJoCo 中验证机器人动作
```

课程文档给出的核心流程是：

```text
Prompt / Video -> PromptHMR -> SMPL-X -> GMR -> Robot Motion
```

可以拆成五层：

1. 输入层：文本 prompt 或已有舞蹈/武术视频。
2. 人体动作恢复层：PromptHMR 从视频中恢复人体姿态和运动。
3. 人体参数层：SMPL-X 用统一人体模型表示动作。
4. 动作重定向层：GMR 把人类动作映射到机器人。
5. 验证输出层：生成 `robot_motion*.pkl`，再用 Web、viser 或 MuJoCo 可视化。

你现在要学的不是“马上训练一个机器人控制器”，而是先把这条转换链路跑通：

```text
视频或文字动作 -> 人体动作 -> 机器人动作文件 -> 可视化验证
```

## 2. 这个任务到底在复刻什么

复刻春晚机器人，可以有三个层级。

### 层级 1：视觉效果复刻

目标：

```text
让可视化里的机器人看起来像在跳类似动作。
```

特点：

- 不要求真实机器人能稳定执行。
- 不严格考虑电机扭矩、足底接触、地面摩擦。
- 更关注动作形态、节奏、姿态是否相似。

这是课程项目最适合初学者的目标。

### 层级 2：仿真运动复刻

目标：

```text
让机器人动作能在 MuJoCo 或 IsaacSim 等物理仿真中更稳定地播放。
```

特点：

- 要考虑关节限制。
- 要考虑脚底接触。
- 要考虑重心和平衡。
- 要看动作是否会穿模、摔倒、抖动。

这是进阶目标。

### 层级 3：真实机器人复刻

目标：

```text
让真实机器人执行舞蹈或武术动作。
```

特点：

- 需要真实硬件。
- 需要控制频率、动力学约束、安全保护。
- 需要从动作文件进入实际控制器。
- 需要解决摔倒风险。

这是高阶目标，不建议 Task01 阶段直接做。

当前建议目标：

```text
先完成层级 1：从视频或 prompt 生成机器人动作文件，并完成可视化。
```

## 3. 整体目录和组件关系

文档默认工作目录是：

```bash
every-embodied/07-机器人操作、运动控制/Locomotion/video2robot
```

它下面大致会有：

```text
video2robot/
  scripts/
    generate_video.py
    extract_pose.py
    convert_to_robot.py
    visualize.py
  third_party/
    PromptHMR/
    GMR/
  data/
    video_001/
      input video
      extracted pose
      robot_motion.pkl
      robot_motion_track_*.pkl
  envs/
    gmr.yml
    phmr.yml
  web/
    app.py
  patches/
    main.patch
    prompthmr.patch
    gmr.patch
```

核心组件：

| 组件 | 作用 | 可以怎么理解 |
| --- | --- | --- |
| PromptHMR | 从视频恢复人体姿态 | 把视频里的人变成三维人体动作 |
| SMPL-X | 人体参数模型 | 用标准人体骨架/网格表示动作 |
| GMR | General Motion Retargeting | 把人类动作映射到机器人身体 |
| robot_motion.pkl | 机器人动作文件 | 后续可视化或仿真要读的结果 |
| robot-viser | Web 3D 可视化 | 快速看机器人动作对不对 |
| MuJoCo | 物理仿真与录制 | 看机器人动作在物理环境里的效果 |

## 4. 为什么要有两个环境

文档推荐两个 conda 环境：

```text
phmr
gmr
```

### `phmr` 环境

用途：

```text
运行 PromptHMR，负责视频人体姿态恢复。
```

它会涉及：

- 视频读取。
- 人体检测。
- 分割。
- 姿态估计。
- SMPL-X 参数恢复。
- 一些深度学习模型权重。

这个环境通常依赖复杂，容易遇到编译和模型下载问题。

### `gmr` 环境

用途：

```text
运行 GMR，把人体动作重定向到机器人。
```

它会涉及：

- 机器人模型。
- 人体骨架到机器人骨架的映射。
- 关节角约束。
- 机器人动作保存。
- MuJoCo 或 viser 可视化。

这个环境相对更接近机器人运动控制。

为什么不放在一个环境：

1. PromptHMR 和 GMR 依赖不同。
2. PromptHMR 可能需要特定 PyTorch / CUDA / 编译工具。
3. GMR 更关注机器人和仿真依赖。
4. 分开环境可以减少依赖冲突。

自己实现时的思考：

```text
如果一个项目同时包含“视觉大模型”和“机器人仿真控制”，最好分环境管理。
```

## 5. 推荐实现顺序

不要一上来就做 Web UI，也不要直接追求多人多机器人。建议按下面顺序来。

### 第 0 步：确认硬件和系统条件

要先确认：

1. 你是在 Windows 原生、WSL、Linux 服务器还是云平台。
2. 是否有 NVIDIA GPU。
3. CUDA 是否可用。
4. 磁盘空间是否足够。
5. 网络能否访问 GitHub、HuggingFace、PyTorch。

推荐环境：

```text
Linux 或 WSL2 + Ubuntu
有 NVIDIA GPU 更好
至少预留 50GB 磁盘空间
```

这一步的意义：

```text
先判断自己能不能跑 PromptHMR 这种重依赖模型，避免装到一半才发现磁盘、CUDA 或网络不满足。
```

你可以问自己的问题：

- 我的机器有没有 NVIDIA GPU？
- `nvidia-smi` 能不能跑？
- 我的 conda 环境放在哪里？
- 模型权重会下载到哪里？
- 数据和输出视频会占多少空间？
- 如果我的机器没有 GPU，能不能只做 GMR 可视化？

### 第 1 步：克隆主仓库

推荐命令：

```bash
git clone https://github.com/datawhalechina/every-embodied.git
cd every-embodied/07-机器人操作、运动控制/Locomotion/video2robot
```

意义：

```text
拿到课程代码、脚本、环境文件、patch、文档和目录结构。
```

注意：

课程文档建议把 `video2robot` 作为主仓内普通目录维护，不再依赖旧 submodule。这样新同学不需要在多个仓库之间切换。

你可以问：

- 为什么项目不建议继续用旧的 `hope5hope/video2robot`？
- submodule 为什么会增加复刻难度？
- 教程和代码放在一个仓库有什么好处？
- 我应该 fork 课程仓库，还是只 clone 到本地？

### 第 2 步：克隆第三方依赖

进入：

```bash
cd third_party
```

克隆 GMR：

```bash
git clone --depth 1 https://github.com/taeyoun811/GMR.git GMR
```

克隆 PromptHMR：

```bash
git clone --depth 1 https://github.com/taeyoun811/PromptHMR.git PromptHMR
```

意义：

```text
主项目只负责组织流程，真正的人体恢复和动作重定向依赖外部项目。
```

为什么 `--depth 1`：

```text
只拉取最新一层提交，减少下载体积和时间。
```

你可以问：

- GMR 是什么？
- PromptHMR 是什么？
- 为什么主仓库不直接把第三方源码放进去？
- `third_party` 目录适合放什么？
- 如果第三方仓库更新了，是否应该立即跟着更新？
- 版本不固定会带来什么问题？

### 第 3 步：应用 patch

如果课程提供 patch，需要执行：

```bash
git apply patches/main.patch
git -C third_party/PromptHMR apply ../../patches/prompthmr.patch
git -C third_party/GMR apply ../../patches/gmr.patch
```

意义：

```text
patch 是课程为了跑通当前流程对主项目、PromptHMR、GMR 做的适配改动。
```

为什么需要 patch：

1. 第三方项目原始代码可能不完全适配课程流程。
2. 新版 PyTorch/CUDA 可能导致旧代码编译报错。
3. 课程可能新增了多轨迹、多机器人、Web UI、MuJoCo 录制等功能。
4. 有些路径、接口、参数需要统一。

你可以问：

- patch 到底改了哪些文件？
- patch 应该在什么时候应用？
- 如果 patch 冲突怎么办？
- 我怎么查看 patch 内容？
- 为什么不直接提交到第三方仓库？
- patch 和 fork 有什么区别？

建议查看 patch：

```bash
git apply --stat patches/main.patch
git apply --check patches/main.patch
```

含义：

- `--stat` 看 patch 会改哪些文件。
- `--check` 只检查能否应用，不真正修改。

### 第 4 步：创建 `gmr` 环境

推荐一键方式：

```bash
conda env create -f envs/gmr.yml
```

如果环境已存在：

```bash
conda env update -n gmr -f envs/gmr.yml --prune
```

手动方式：

```bash
conda create -n gmr python=3.10 -y
conda activate gmr
pip install -e .
pip install loop-rate-limiters
pip install smplx
pip install imageio
pip install mink
pip install rich
pip install "imageio[ffmpeg]"
```

意义：

```text
搭建机器人动作重定向和可视化环境。
```

这些包大致的作用：

| 包 | 作用 |
| --- | --- |
| `smplx` | 读取/处理 SMPL-X 人体模型 |
| `mink` | 运动学、优化、机器人动作相关工具 |
| `imageio` | 读写图片和视频 |
| `imageio[ffmpeg]` | 支持 mp4 视频导出 |
| `rich` | 更好的终端输出 |
| `loop-rate-limiters` | 控制循环频率 |

你可以问：

- 为什么 GMR 需要 SMPL-X？
- 机器人动作文件里保存的是什么？
- `robot_motion.pkl` 里可能包含哪些字段？
- GMR 是不是控制器？
- Retargeting 和控制有什么区别？
- 机器人动作看起来对了，是否代表真实机器人能执行？

### 第 5 步：创建 `phmr` 环境

推荐一键方式：

```bash
conda env create -f envs/phmr.yml
```

如果环境已存在：

```bash
conda env update -n phmr -f envs/phmr.yml --prune
```

文档中也给了手动方案：

```bash
conda create -n phmr python=3.10 -y
conda activate phmr
cd third_party/PromptHMR
pip install -r requirements.txt
```

之后可能涉及：

- 安装 `chumpy`
- 配置 `PYTHONPATH`
- 安装 `eigen`
- 编译 `droidcalib`
- 编译 `lietorch`
- 安装 `detectron2`
- 安装 `SAM2`
- 安装 `torch-scatter`
- 安装 `xformers`

意义：

```text
搭建从视频中恢复人体三维动作的环境。
```

为什么 `phmr` 更麻烦：

1. 涉及视觉模型。
2. 涉及检测、分割、姿态估计。
3. 涉及 CUDA 编译扩展。
4. 涉及多个第三方项目。
5. 涉及模型权重下载。

你可以问：

- PromptHMR 为什么需要 SAM2？
- `droidcalib` 是做什么的？
- `lietorch` 为什么要编译？
- `detectron2` 用在哪里？
- 为什么 PyTorch 版本会影响编译？
- `torch-scatter` 和 `xformers` 是不是必须？
- 如果我只上传已经处理好的姿态文件，还需要 phmr 吗？

### 第 6 步：准备模型权重

文档推荐方式：

```bash
git-lfs install
git lfs clone https://huggingface.co/Datawhale/spring-festival-wushu-robot-replication-model
```

替代方式：

```bash
cd third_party/PromptHMR
bash scripts/fetch_smplx.sh
bash scripts/fetch_data.sh
```

意义：

```text
PromptHMR 和 SMPL-X 需要预训练权重和人体模型文件，代码本身不包含这些大文件。
```

为什么用 Git LFS：

```text
模型权重很大，普通 Git 不适合管理大文件。
```

你可以问：

- 模型权重和代码有什么区别？
- 为什么 clone 了仓库还不能直接跑？
- HuggingFace 下载失败怎么办？
- 权重应该放在哪里？
- 权重路径是写死的吗？
- SMPL-X 模型是否需要授权？
- 如果权重版本不匹配，会出现什么现象？

### 第 7 步：启动 Web UI

文档给出的稳定方式：

```bash
conda activate phmr
python -m pip install -U fastapi "uvicorn[standard]" jinja2 python-multipart
pkill -f "video2robot/visualization/robot_viser.py"
cd /path/to/video2robot
export VISER_FIXED_PORT=8789
python -m uvicorn web.app:app --host 0.0.0.0 --port 8000
```

访问：

```text
http://localhost:8000
```

意义：

```text
Web UI 把生成视频、上传视频、姿态提取、机器人转换和可视化流程做成界面，降低命令行操作难度。
```

为什么固定 `VISER_FIXED_PORT`：

```text
robot-viser 如果随机开端口，Web iframe 可能连接失败。固定端口能减少 localhost 拒绝连接问题。
```

你可以问：

- Web UI 背后调用了哪些脚本？
- `uvicorn` 是什么？
- `FastAPI` 是什么？
- 为什么要先 `pkill` 旧的 robot-viser？
- `0.0.0.0` 和 `127.0.0.1` 有什么区别？
- `localhost:8000` 打不开时怎么排查？
- iframe 为什么会拒绝连接？

### 第 8 步：文本生成视频

文档中有命令：

```bash
python scripts/generate_video.py \
  --model seedance \
  --action "动作序列：角色向前走四步"
```

意义：

```text
用文本 prompt 生成一个动作视频，作为后续人体姿态恢复的输入。
```

如果你的目标是复刻春晚机器人，可以把 prompt 写成：

```text
一个完整站立的人物在空旷舞台中央表演中国武术动作，动作包括抱拳、弓步、转身、出拳和踢腿。人物全身始终在画面范围内，镜头固定，背景干净，动作连贯，单人表演。
```

Prompt 设计重点：

1. 人物必须全身入镜。
2. 镜头尽量固定。
3. 不要频繁切镜头。
4. 动作不要太快。
5. 尽量单人。
6. 背景不要太复杂。
7. 避免遮挡。

意义：

```text
PromptHMR 需要清楚看到人体。如果视频里人物被遮挡、出画、多人重叠，姿态恢复会明显变差。
```

你可以问：

- 什么样的视频最适合做动作提取？
- 为什么要全身入镜？
- 为什么不建议快速切镜头？
- 多人视频为什么更难？
- 复杂衣服会不会影响姿态估计？
- 侧身、背身、腾空动作会不会更难？

### 第 9 步：从视频提取人体姿态

命令：

```bash
python scripts/extract_pose.py --project data/video_001
```

意义：

```text
把视频中的人物动作提取成可计算的人体姿态表示。
```

这里的 `project` 可以理解为一次实验：

```text
data/video_001/
  输入视频
  中间姿态结果
  可视化结果
  后续机器人动作
```

你可以问：

- `extract_pose.py` 输入是什么？
- 它输出哪些文件？
- 如何判断姿态提取是否成功？
- 如果人物检测错了怎么办？
- 如果视频里有多人怎么办？
- 如果中间某几帧姿态错了，能否手动修？
- 姿态提取失败是视频问题还是模型问题？

### 第 10 步：人体动作转机器人动作

单人基础命令：

```bash
python scripts/convert_to_robot.py --project data/video_001
```

多人轨迹命令：

```bash
python scripts/convert_to_robot.py --project data/video_001 --all-tracks
```

意义：

```text
把人体动作重定向到机器人结构，生成 robot_motion.pkl 或 robot_motion_track_*.pkl。
```

为什么需要重定向：

```text
人和机器人身体结构不一样。人有关节、骨长、自由度，机器人也有关节、连杆、自由度，但两者并不完全对应。
```

例如：

- 人的肩膀自由度和机器人肩关节不同。
- 人的腰部动作机器人未必能做。
- 人能快速转身，机器人可能会失衡。
- 人能自然摆臂，机器人摆臂幅度可能有限。

你可以问：

- 什么是 motion retargeting？
- 人体关节和机器人关节如何对应？
- 什么动作最难映射？
- 为什么有些动作会抖？
- 为什么机器人脚会滑？
- 为什么机器人会穿地？
- 为什么 robot motion 能播放但不一定物理可行？

### 第 11 步：用 robot-viser 可视化

命令：

```bash
python scripts/visualize.py \
  --project data/video_001 \
  --robot-viser
```

多人可视化：

```bash
python scripts/visualize.py \
  --project data/video_001 \
  --robot-viser \
  --robot-all
```

意义：

```text
快速检查机器人动作是否大致正确。
```

你应该看什么：

1. 机器人有没有明显倒置。
2. 左右方向是否反了。
3. 手脚动作是否对应。
4. 动作节奏是否正常。
5. 是否有明显抖动。
6. 是否有身体穿模。
7. 多机器人是否轨迹重叠。

你可以问：

- 可视化正常是否代表动作成功？
- 为什么左右手可能反了？
- 为什么机器人突然跳变？
- 为什么某一段动作很乱？
- 多人轨迹如何区分 track？
- 如何选择主角 track？

### 第 12 步：用 MuJoCo 导出视频

单机器人示例：

```bash
cd third_party/GMR
python scripts/vis_robot_motion.py \
  --robot unitree_g1 \
  --robot_motion_path /path/to/video2robot/data/video_001/robot_motion.pkl \
  --record_video \
  --video_path /path/to/video2robot/data/video_001/mujoco_robot.mp4
```

多机器人示例：

```bash
python scripts/vis_robot_motion_multi.py \
  --robot unitree_g1 \
  --robot_motion_paths \
  /path/to/video2robot/data/video_001/robot_motion_track_1.pkl \
  /path/to/video2robot/data/video_001/robot_motion_track_2.pkl \
  --record_video \
  --max_seconds 10 \
  --camera_azimuth 0 \
  --video_path /path/to/video2robot/data/video_001/mujoco_multi_robot_10s_front.mp4
```

意义：

```text
MuJoCo 提供更接近物理仿真的展示方式，也可以导出 mp4 结果。
```

注意：

```text
这里更像动作回放或仿真展示，不等同于真实机器人闭环控制。
```

你可以问：

- MuJoCo 和 robot-viser 有什么区别？
- MuJoCo 里播放成功是否代表真实机器人能做？
- 为什么视频只有地面看不到机器人？
- 为什么导出视频只有 0 秒？
- 为什么多机器人相机会偏？
- 如何调整相机角度？
- 如何限制视频时长？

## 6. 最小可行复刻路线

如果你从零开始，不建议把所有内容一次性做完。建议按下面的最小路线。

### 路线 A：只看懂流程

适合完全零基础。

完成内容：

1. 阅读文档。
2. 理解 `Prompt / Video -> PromptHMR -> SMPL-X -> GMR -> Robot Motion`。
3. 整理每个模块的输入输出。
4. 不安装环境。

产出：

```text
一份流程图和学习笔记。
```

### 路线 B：只跑 GMR 可视化

适合环境能力一般、不想先处理 PromptHMR。

完成内容：

1. 安装 `gmr` 环境。
2. 使用已有 `robot_motion.pkl`。
3. 跑 robot-viser 或 MuJoCo。

产出：

```text
机器人动作可视化结果。
```

意义：

```text
先理解机器人动作文件和可视化，不被视频姿态提取卡住。
```

### 路线 C：上传已有视频做完整流程

适合有 GPU、愿意处理环境。

完成内容：

1. 安装 `phmr` 环境。
2. 安装 `gmr` 环境。
3. 准备模型权重。
4. 上传单人全身视频。
5. 提取姿态。
6. 转机器人动作。
7. 可视化。

产出：

```text
从视频到机器人动作的完整复刻结果。
```

### 路线 D：文本生成视频再完整复刻

适合想做“从 prompt 到机器人”的完整体验。

完成内容：

1. 写 prompt。
2. 生成动作视频。
3. 提取人体姿态。
4. 转机器人动作。
5. 可视化或 MuJoCo 导出。

产出：

```text
Prompt -> Robot Motion 的完整链路。
```

## 7. 自己实现时应该怎么思考

### 先想输入

你要问：

```text
我的动作来源是什么？
```

可能来源：

1. 自己拍摄视频。
2. 春晚机器人/武术视频片段。
3. 文生视频生成。
4. 已有动作数据。
5. 人体 mocap 数据。

不同输入决定难度：

| 输入 | 难度 | 说明 |
| --- | --- | --- |
| 单人全身固定镜头视频 | 低 | 最适合入门 |
| 多人舞蹈视频 | 中 | 需要 track 选择 |
| 快速武术视频 | 高 | 姿态容易丢失 |
| 文生视频 | 中 | prompt 控制很关键 |
| Mocap 数据 | 中 | 姿态准确但格式转换复杂 |

### 再想中间表示

你要问：

```text
我的人体动作最终变成了什么表示？
```

文档路线中是：

```text
SMPL-X
```

你需要理解：

- SMPL-X 是标准人体模型。
- 它可以表示身体姿态、手部、面部等。
- 机器人不直接理解 SMPL-X，所以还需要 GMR。

### 再想机器人目标

你要问：

```text
我要映射到什么机器人？
```

文档示例是：

```text
unitree_g1
```

你可以扩展：

- Unitree G1
- Unitree H1
- 自定义双足机器人
- 四足机器人
- 机械臂
- 虚拟人形机器人

机器人不同，动作可行性完全不同。

### 再想验证方式

你要问：

```text
我怎么判断复刻成功？
```

可以从低到高判断：

1. 文件生成成功。
2. robot-viser 能打开。
3. 机器人动作和人类动作大致相似。
4. MuJoCo 能导出视频。
5. 动作没有明显穿模或抖动。
6. 动作符合机器人关节限制。
7. 动作在物理仿真中稳定。
8. 动作能迁移到真实机器人。

## 8. 常见问题和排查思路

### 1. 环境装不上

可能原因：

- Python 版本不对。
- PyTorch 版本不对。
- CUDA 版本不对。
- 编译工具缺失。
- 网络下载中断。
- 磁盘空间不足。

排查：

```bash
python --version
conda list | grep torch
nvidia-smi
df -h
```

### 2. GitHub 下载失败

可能原因：

- TLS 握手失败。
- 代理没设置。
- 网络到 GitHub 不稳定。

处理：

```bash
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export ALL_PROXY=http://127.0.0.1:7897
```

### 3. 模型权重下载失败

可能原因：

- HuggingFace 访问问题。
- Git LFS 没安装。
- 权重路径不对。
- 权限或授权问题。

处理：

```bash
git-lfs install
```

并确认权重实际存在。

### 4. 视频姿态提取失败

可能原因：

- 人物不完整。
- 视频分辨率太低。
- 背景复杂。
- 人物被遮挡。
- 多人重叠。
- 镜头切换太快。

处理：

1. 换成单人全身视频。
2. 裁剪视频。
3. 降低动作复杂度。
4. 使用更清晰的视频。
5. 先测试 5 到 10 秒短片。

### 5. 转机器人动作失败

可能原因：

- SMPL-X 输出文件缺失。
- 路径不对。
- track id 不对。
- 机器人模型配置不匹配。
- 某些人体动作无法映射到机器人。

处理：

1. 检查 `data/video_xxx` 下中间文件。
2. 先只转单人。
3. 再开启 `--all-tracks`。
4. 看报错中缺的是文件、字段还是模型。

### 6. 可视化打不开

可能原因：

- 端口被占用。
- robot-viser 旧进程没关。
- Web iframe 端口随机。

处理：

```bash
pkill -f "video2robot/visualization/robot_viser.py"
export VISER_FIXED_PORT=8789
```

### 7. MuJoCo 视频导出失败

可能原因：

- `imageio[ffmpeg]` 没装。
- 视频路径不存在。
- 相机角度不对。
- motion 文件为空或时间太短。

处理：

```bash
pip install -U "imageio[ffmpeg]"
```

并检查：

```bash
ls -lh robot_motion.pkl
```

## 9. 你可以扩展思考的问题清单

下面这些都是你可以继续问的问题。

### 关于输入视频

- 什么样的视频最适合动作复刻？
- 视频需要多少 FPS？
- 视频分辨率越高越好吗？
- 人物必须全身出现吗？
- 如果人物出画怎么办？
- 如果视频里有多人怎么办？
- 如果镜头在运动怎么办？
- 如果背景复杂怎么办？
- 如果人物穿宽松衣服怎么办？
- 如果动作太快怎么办？

### 关于 Prompt

- 如何写一个适合机器人复刻的 prompt？
- Prompt 里为什么要写“全身入镜”？
- Prompt 里为什么要写“镜头固定”？
- Prompt 里为什么要避免“快速剪辑”？
- 如何让生成视频更像武术？
- 如何让动作更适合机器人？
- 如何避免动作过于夸张？
- 如何控制动作节奏？

### 关于 PromptHMR

- PromptHMR 输入是什么？
- PromptHMR 输出是什么？
- 它和普通 2D 姿态估计有什么区别？
- 它为什么要恢复 3D 人体？
- 它如何处理多人？
- 它如何跟踪同一个人？
- 它失败时通常表现为什么？
- 如何查看 PromptHMR 中间结果？

### 关于 SMPL-X

- SMPL-X 是什么？
- SMPL-X 和 SMPL 有什么区别？
- SMPL-X 为什么适合作为中间表示？
- SMPL-X 的 pose 参数是什么？
- shape 参数是什么？
- translation 是什么？
- global orientation 是什么？
- SMPL-X 是否包含手部动作？

### 关于 GMR

- GMR 的输入是什么？
- GMR 的输出是什么？
- 什么是 retargeting？
- 人体动作如何映射到机器人关节？
- 机器人关节自由度少于人体怎么办？
- 机器人腿长和人腿长不同怎么办？
- 机器人不能做某些动作怎么办？
- 映射时如何考虑关节限制？
- 映射时如何保持平衡？

### 关于机器人动作文件

- `robot_motion.pkl` 是什么？
- 里面保存的是关节角还是位姿？
- 每一帧对应什么？
- 帧率是多少？
- 如何读取 pkl 文件？
- 如何修改动作？
- 如何裁剪动作片段？
- 如何拼接两个动作？
- 如何平滑动作？

### 关于可视化

- robot-viser 是什么？
- MuJoCo 是什么？
- 两者区别是什么？
- 可视化里动作对了，为什么真实机器人还可能失败？
- 如何调整机器人颜色？
- 如何调整相机角度？
- 如何导出视频？
- 如何比较人体视频和机器人视频？

### 关于物理约束

- 什么是开环动作？
- 什么是闭环控制？
- 为什么开环动作容易摔？
- 什么是足底接触？
- 什么是地面摩擦？
- 什么是重心？
- 什么是 ZMP？
- 什么是动力学可行性？
- 为什么人类动作不能直接复制给机器人？

### 关于真实机器人

- 真实机器人需要什么接口？
- 如何把 `robot_motion.pkl` 发送给机器人？
- 需要控制频率是多少？
- 如何做安全保护？
- 如何避免摔倒？
- 需要 IMU 反馈吗？
- 需要足底力传感器吗？
- 需要强化学习控制器吗？

### 关于 IsaacSim / Isaac Lab

- 为什么文档提到 IsaacSim？
- IsaacSim 和 MuJoCo 有什么区别？
- IsaacSim 更适合做什么？
- 动作映射和强化学习训练是什么关系？
- 如何用 IsaacSim 提升动作稳定性？
- 什么是 Sim2Real？
- 为什么仿真成功不代表真实成功？

## 10. 适合你的下一步

结合你目前已经完成 Habitat-Sim / Habitat-Lab 的情况，建议下一步不要马上安装 PromptHMR 的完整复杂环境。更稳的顺序是：

1. 先阅读本文件，画出流程图。
2. 在本地创建 `video2robot` 学习目录。
3. 先 clone 主仓库并定位 `Locomotion/video2robot`。
4. 先只研究 `scripts/convert_to_robot.py` 和 `scripts/visualize.py`。
5. 找一个已有的 `robot_motion.pkl` 或课程示例结果，先跑 GMR 可视化。
6. 再安装 `phmr`，处理视频姿态提取。
7. 最后再尝试 Web UI 和文生视频。

原因：

```text
GMR 可视化比 PromptHMR 安装更容易，先理解机器人动作输出端，再回头处理视频输入端，会更符合零基础学习顺序。
```

## 11. 最终可以写进作业的总结

可以这样总结：

```text
春晚舞蹈机器人复刻的核心不是直接让机器人看视频学习，而是将视频或文本生成的视频转换为人体三维动作，再通过 SMPL-X 作为中间人体表示，使用 GMR 将人体动作重定向到 Unitree G1 等机器人模型，最终生成 robot_motion.pkl 并通过 robot-viser 或 MuJoCo 可视化。

整个流程可以拆成输入、人体动作恢复、人体模型表示、机器人动作重定向、仿真验证五个阶段。PromptHMR 主要解决“从视频到人体动作”的问题，GMR 主要解决“从人体动作到机器人动作”的问题。当前复刻更偏开环动作映射和视觉效果验证，若要真正落地到物理机器人，还需要考虑动力学约束、足底接触、重心稳定、闭环控制和 Sim2Real。
```

## 12. 关键命令索引

克隆主仓：

```bash
git clone https://github.com/datawhalechina/every-embodied.git
cd every-embodied/07-机器人操作、运动控制/Locomotion/video2robot
```

克隆第三方：

```bash
cd third_party
git clone --depth 1 https://github.com/taeyoun811/GMR.git GMR
git clone --depth 1 https://github.com/taeyoun811/PromptHMR.git PromptHMR
cd ..
```

应用 patch：

```bash
git apply patches/main.patch
git -C third_party/PromptHMR apply ../../patches/prompthmr.patch
git -C third_party/GMR apply ../../patches/gmr.patch
```

创建环境：

```bash
conda env create -f envs/gmr.yml
conda env create -f envs/phmr.yml
```

环境已存在时更新：

```bash
conda env update -n gmr -f envs/gmr.yml --prune
conda env update -n phmr -f envs/phmr.yml --prune
```

生成视频：

```bash
python scripts/generate_video.py --model seedance --action "动作序列：角色向前走四步"
```

提取姿态：

```bash
python scripts/extract_pose.py --project data/video_001
```

转机器人动作：

```bash
python scripts/convert_to_robot.py --project data/video_001
```

多人轨迹：

```bash
python scripts/convert_to_robot.py --project data/video_001 --all-tracks
```

可视化：

```bash
python scripts/visualize.py --project data/video_001 --robot-viser
```

多人可视化：

```bash
python scripts/visualize.py --project data/video_001 --robot-viser --robot-all
```

启动 Web：

```bash
conda activate phmr
export VISER_FIXED_PORT=8789
python -m uvicorn web.app:app --host 0.0.0.0 --port 8000
```

访问：

```text
http://localhost:8000
```
