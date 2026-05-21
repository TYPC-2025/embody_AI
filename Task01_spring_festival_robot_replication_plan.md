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

## 13. WSL 实操版：按顺序具体怎么做

这一节按你当前情况写：

```text
你已经在 WSL 中有 conda，并且已有一个 habitat 环境。
```

但要注意：

```text
不要直接把春晚机器人复刻相关依赖全部装进 habitat 环境。
```

原因：

1. `habitat` 环境现在已经承担 Habitat-Sim / Habitat-Lab。
2. PromptHMR 和 GMR 依赖很多，尤其是 PyTorch、CUDA、编译扩展、人体模型、可视化依赖。
3. 如果全部装进 `habitat`，很容易把已经跑通的 Habitat 环境破坏。
4. 更稳的做法是保留 `habitat`，另外创建 `gmr` 和 `phmr`。

所以推荐环境关系是：

```text
habitat：保留给 Habitat-Sim / Habitat-Lab
gmr：用于人体动作 -> 机器人动作
phmr：用于视频 -> 人体动作
```

### 第 1 步：进入 WSL 并设置代理

PowerShell：

```powershell
wsl -d Ubuntu
```

进入 Ubuntu 后：

```bash
source ~/miniconda3/etc/profile.d/conda.sh
```

如果访问 GitHub / HuggingFace / PyPI 不稳定，设置代理：

```bash
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export ALL_PROXY=http://127.0.0.1:7897
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY
export all_proxy=$ALL_PROXY
```

意义：

```text
你之前已经遇到过 GitHub TLS 握手失败。先设置代理，可以减少 git clone、pip install、模型下载失败。
```

检查：

```bash
git --version
conda --version
python --version
nvidia-smi
```

如果 `nvidia-smi` 能看到 RTX 4060，说明 WSL 可以识别 GPU。

### 第 2 步：创建专门的项目目录

建议不要放在 `/mnt/d/...` 下运行重依赖代码，而是放在 WSL 原生目录：

```bash
mkdir -p ~/embodied_ai/locomotion
cd ~/embodied_ai/locomotion
```

意义：

```text
WSL 原生 Linux 路径对软链接、编译、文件权限、大量小文件更稳定。Windows 盘挂载路径 /mnt/d 适合存文档，不适合放复杂深度学习工程。
```

### 第 3 步：克隆 Every-Embodied 主仓库

```bash
git clone https://github.com/datawhalechina/every-embodied.git
cd every-embodied/07-机器人操作、运动控制/Locomotion/video2robot
```

如果 GitHub 报 TLS 错误，使用：

```bash
git -c http.proxy=http://127.0.0.1:7897 \
    -c https.proxy=http://127.0.0.1:7897 \
    clone https://github.com/datawhalechina/every-embodied.git
```

意义：

```text
主仓库提供课程组织好的脚本、patch、环境文件和 Web UI。先拿主仓库，后面才知道要调用哪些第三方代码。
```

检查当前位置：

```bash
pwd
ls
```

你应该在类似路径：

```text
/home/tyros/embodied_ai/locomotion/every-embodied/07-机器人操作、运动控制/Locomotion/video2robot
```

### 第 4 步：查看项目结构

```bash
find . -maxdepth 2 -type d | sort
ls scripts
ls envs
ls patches
```

意义：

```text
先看目录结构，知道脚本、环境文件、patch、第三方依赖分别在哪里。不要在不知道目录含义时直接运行命令。
```

重点目录：

```text
scripts：主流程脚本
envs：conda 环境文件
patches：课程适配补丁
third_party：第三方项目
data：输入视频、中间结果、机器人动作输出
web：Web UI
```

### 第 5 步：克隆第三方依赖

```bash
mkdir -p third_party
cd third_party
git clone --depth 1 https://github.com/taeyoun811/GMR.git GMR
git clone --depth 1 https://github.com/taeyoun811/PromptHMR.git PromptHMR
cd ..
```

如果失败，用代理版：

```bash
git -c http.proxy=http://127.0.0.1:7897 \
    -c https.proxy=http://127.0.0.1:7897 \
    clone --depth 1 https://github.com/taeyoun811/GMR.git GMR

git -c http.proxy=http://127.0.0.1:7897 \
    -c https.proxy=http://127.0.0.1:7897 \
    clone --depth 1 https://github.com/taeyoun811/PromptHMR.git PromptHMR
```

意义：

```text
PromptHMR 负责从视频恢复人体动作；GMR 负责把人体动作重定向到机器人。主项目只是把二者串成一条流水线。
```

检查：

```bash
ls third_party
```

期望：

```text
GMR
PromptHMR
```

### 第 6 步：应用 patch

先检查 patch 是否能应用：

```bash
git apply --check patches/main.patch
git -C third_party/PromptHMR apply --check ../../patches/prompthmr.patch
git -C third_party/GMR apply --check ../../patches/gmr.patch
```

如果检查通过，再真正应用：

```bash
git apply patches/main.patch
git -C third_party/PromptHMR apply ../../patches/prompthmr.patch
git -C third_party/GMR apply ../../patches/gmr.patch
```

意义：

```text
patch 是课程为了让 PromptHMR、GMR 和 video2robot 当前流程协同工作做的适配。先 --check 可以避免应用到一半失败。
```

检查 patch 改了什么：

```bash
git apply --stat patches/main.patch
git -C third_party/PromptHMR diff --stat
git -C third_party/GMR diff --stat
```

### 第 7 步：先创建 gmr 环境

建议先做 `gmr`，不要先做 `phmr`。

原因：

```text
gmr 负责机器人动作重定向和可视化，依赖相对少。先跑输出端，更容易建立信心；PromptHMR 环境更复杂，后面再做。
```

创建：

```bash
conda env create -f envs/gmr.yml
```

如果环境已存在：

```bash
conda env update -n gmr -f envs/gmr.yml --prune
```

激活：

```bash
conda activate gmr
```

检查：

```bash
python --version
pip list | grep -E "smplx|mujoco|viser|mink"
```

意义：

```text
gmr 环境用于运行 convert_to_robot.py、visualize.py 和 GMR 相关脚本。
```

### 第 8 步：验证 GMR 基础可导入

在 `video2robot` 根目录下：

```bash
conda activate gmr
python - <<'PY'
import sys
print("python", sys.version)
try:
    import smplx
    print("smplx ok")
except Exception as e:
    print("smplx failed:", e)

try:
    import mujoco
    print("mujoco ok")
except Exception as e:
    print("mujoco failed:", e)
PY
```

意义：

```text
先验证核心包是否可导入。不要等到完整流程跑失败时才发现基础包没装好。
```

### 第 9 步：准备一个最小测试动作

初学阶段不要直接处理长视频。建议先找课程示例输出或一个很短的动作项目：

```text
data/video_001/
```

如果没有现成的 `robot_motion.pkl`，这一阶段先只完成环境验证，不强行跑可视化。

意义：

```text
复刻链路很长，要分段验证。GMR 可视化验证需要机器人动作文件，机器人动作文件来自 convert_to_robot.py，而 convert_to_robot.py 又依赖 PromptHMR 的人体动作输出。
```

你可以采用两条路线：

```text
路线 1：先找已有 robot_motion.pkl，直接验证 GMR 可视化。
路线 2：先搭 PromptHMR，自己从视频生成 robot_motion.pkl。
```

### 第 10 步：创建 phmr 环境

在 `video2robot` 根目录：

```bash
conda env create -f envs/phmr.yml
```

如果环境已存在：

```bash
conda env update -n phmr -f envs/phmr.yml --prune
```

激活：

```bash
conda activate phmr
```

意义：

```text
phmr 环境用于从视频恢复人体动作。它依赖更复杂，放在独立环境中可以避免污染 gmr 和 habitat。
```

检查：

```bash
python --version
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
```

如果 `torch.cuda.is_available()` 是 `False`：

```text
不一定代表完全不能跑，但 PromptHMR 会很慢，部分 CUDA 扩展可能不可用。后续要根据报错处理。
```

### 第 11 步：安装 PromptHMR 依赖

```bash
conda activate phmr
cd third_party/PromptHMR
pip install -r requirements.txt
```

根据文档和实际报错，可能还要安装：

```bash
pip install chumpy
pip install "git+https://github.com/facebookresearch/detectron2.git"
pip install xformers
pip install torch-scatter
```

注意：

```text
这些依赖可能和 CUDA / PyTorch 版本强相关。如果安装失败，不要盲目换所有版本，先保存完整报错。
```

意义：

```text
PromptHMR 不是普通 Python 包，它包含人体检测、分割、视频姿态恢复、相机估计等多个模块。
```

### 第 12 步：准备 SMPL-X 和模型权重

推荐优先用课程给出的模型仓库：

```bash
git-lfs install
git lfs clone https://huggingface.co/Datawhale/spring-festival-wushu-robot-replication-model
```

如果使用 PromptHMR 自带脚本：

```bash
cd third_party/PromptHMR
bash scripts/fetch_smplx.sh
bash scripts/fetch_data.sh
```

意义：

```text
代码只是算法流程，真正的模型参数、人体模型文件、检测权重都需要额外下载。没有权重，视频姿态恢复无法运行。
```

检查：

```bash
find . -iname "*smpl*" | head
find . -iname "*.pth" -o -iname "*.pt" -o -iname "*.ckpt" | head
```

### 第 13 步：准备输入视频

建议先准备一个 5 到 10 秒短视频，满足：

```text
单人
全身
固定镜头
背景简单
动作不太快
人物不要出画
```

放到项目目录：

```bash
mkdir -p data/video_001
```

再把视频放入：

```text
data/video_001/input.mp4
```

意义：

```text
先用短视频验证全链路，成功后再换成长视频或复杂舞蹈。
```

### 第 14 步：从视频提取人体姿态

```bash
conda activate phmr
cd /path/to/video2robot
python scripts/extract_pose.py --project data/video_001
```

意义：

```text
这一步把 input.mp4 中的人体动作恢复成 SMPL-X 或相关中间表示。后面的 GMR 不直接读视频，而是读这一步的结果。
```

检查：

```bash
find data/video_001 -maxdepth 3 -type f | sort
```

你要关注：

```text
是否生成了人体姿态结果
是否生成了可视化结果
是否有报错日志
```

### 第 15 步：人体动作转机器人动作

```bash
conda activate gmr
cd /path/to/video2robot
python scripts/convert_to_robot.py --project data/video_001
```

多人轨迹：

```bash
python scripts/convert_to_robot.py --project data/video_001 --all-tracks
```

意义：

```text
这一步把人体动作映射到机器人模型，输出 robot_motion.pkl。
```

检查：

```bash
ls -lh data/video_001/*robot_motion*.pkl
```

期望：

```text
robot_motion.pkl
```

或者多人轨迹：

```text
robot_motion_track_1.pkl
robot_motion_track_2.pkl
...
```

### 第 16 步：robot-viser 可视化

```bash
conda activate gmr
cd /path/to/video2robot
export VISER_FIXED_PORT=8789
python scripts/visualize.py --project data/video_001 --robot-viser
```

浏览器访问输出地址，通常类似：

```text
http://localhost:8789
```

意义：

```text
快速看机器人动作是否像人类动作，优先检查动作方向、节奏、左右手脚是否对应。
```

### 第 17 步：MuJoCo 导出视频

```bash
conda activate gmr
cd third_party/GMR
python scripts/vis_robot_motion.py \
  --robot unitree_g1 \
  --robot_motion_path /path/to/video2robot/data/video_001/robot_motion.pkl \
  --record_video \
  --video_path /path/to/video2robot/data/video_001/mujoco_robot.mp4
```

意义：

```text
MuJoCo 视频可以作为最终展示材料，比浏览器临时可视化更适合提交作业。
```

检查：

```bash
ls -lh /path/to/video2robot/data/video_001/mujoco_robot.mp4
```

### 第 18 步：启动 Web UI

Web UI 更适合你已经把环境跑通之后再用。

```bash
conda activate phmr
cd /path/to/video2robot
python -m pip install -U fastapi "uvicorn[standard]" jinja2 python-multipart
pkill -f "video2robot/visualization/robot_viser.py" || true
export VISER_FIXED_PORT=8789
python -m uvicorn web.app:app --host 0.0.0.0 --port 8000
```

Windows 浏览器访问：

```text
http://localhost:8000
```

意义：

```text
Web UI 把生成视频、上传视频、姿态提取、机器人转换、可视化封装到页面里，适合演示和重复操作。
```

### 第 19 步：最终整理结果

建议输出目录结构：

```text
data/video_001/
  input.mp4
  pose result files
  robot_motion.pkl
  mujoco_robot.mp4
  notes.md
```

建议作业记录：

```text
1. 输入视频来源
2. Prompt 或视频说明
3. PromptHMR 提取结果
4. GMR 转换结果
5. robot-viser / MuJoCo 截图
6. 遇到的问题
7. 后续改进方向
```

## 14. 扩展问题答案速查

### 关于输入视频

**什么样的视频最适合动作复刻？**

单人、全身、固定镜头、背景简单、无遮挡、动作速度适中的视频最适合。因为姿态恢复模型需要连续看到完整人体。

**视频需要多少 FPS？**

通常 24 到 30 FPS 足够。FPS 太低会丢动作细节，FPS 太高会增加处理时间和数据量。

**视频分辨率越高越好吗？**

不是。清晰即可。过高分辨率会增加计算量，且不一定提升姿态恢复质量。一般 720p 或 1080p 更合适。

**人物必须全身出现吗？**

最好必须。脚、手、头、躯干缺失会导致 SMPL-X 拟合不准，后续机器人动作会抖动或错误。

**如果人物出画怎么办？**

先裁剪视频，只保留人物完整出现的片段。出画严重时不要强行复刻，因为中间姿态会断。

**如果视频里有多人怎么办？**

先做单人。多人需要跟踪每个人的 track，后续还要选择主角或使用 `--all-tracks`，复杂度更高。

**如果镜头在运动怎么办？**

镜头运动会增加相机估计难度，导致人体运动和相机运动混在一起。初学阶段尽量用固定镜头。

**如果背景复杂怎么办？**

背景复杂会影响人体检测和分割。可以换视频、裁剪画面、提高人物占比，或者选择背景更干净的片段。

**如果人物穿宽松衣服怎么办？**

宽松衣服会遮挡身体轮廓，姿态估计可能不准。紧身或轮廓清晰的衣服更适合。

**如果动作太快怎么办？**

可以选更慢片段，或先降低目标难度。快速踢腿、旋转、腾空动作最容易出现姿态跳变。

### 关于 Prompt

**如何写一个适合机器人复刻的 prompt？**

写清楚“单人、全身、固定镜头、背景简单、动作连贯、动作不要太快”。例如：“一个完整站立的人物在空旷舞台中央表演中国武术动作，镜头固定，全身入镜，动作连贯。”

**Prompt 里为什么要写全身入镜？**

因为姿态恢复需要看到全身关节。缺脚会影响步态，缺手会影响上肢动作。

**Prompt 里为什么要写镜头固定？**

固定镜头能减少相机运动干扰，让模型更容易判断人体真实运动。

**Prompt 里为什么要避免快速剪辑？**

快速剪辑会破坏动作连续性，PromptHMR 难以稳定跟踪同一个人。

**如何让生成视频更像武术？**

在 prompt 中加入“抱拳、弓步、转身、出拳、踢腿、收势”等具体动作词，而不是只写“跳舞”。

**如何让动作更适合机器人？**

避免大幅腾空、快速旋转、劈叉、极限下腰。选择重心变化小、双脚交替稳定支撑的动作。

**如何避免动作过于夸张？**

加入“动作稳健、节奏中等、幅度适中、无夸张变形”等限制。

**如何控制动作节奏？**

描述“慢速、分解动作、每个动作停顿半秒、节奏清晰”。生成视频仍不完全可控，需要多试几次。

### 关于 PromptHMR

**PromptHMR 输入是什么？**

输入通常是视频或视频帧序列，以及相关 prompt / 配置。它的目标是从视频中恢复人体三维姿态。

**PromptHMR 输出是什么？**

输出是人体三维动作的中间表示，通常包含 SMPL-X 参数、人体位姿、轨迹或可视化结果。

**它和普通 2D 姿态估计有什么区别？**

2D 姿态估计只给图像平面上的关键点；PromptHMR 要恢复三维人体姿态，更适合后续映射到机器人。

**它为什么要恢复 3D 人体？**

机器人运动发生在三维空间。只有 2D 点无法可靠表示身体朝向、深度、转身、步态等信息。

**它如何处理多人？**

通常需要检测和跟踪不同人物，给每个人分配 track。多人场景比单人更容易错跟、漏跟或交换身份。

**它失败时通常表现为什么？**

人体骨架跳变、左右手脚反、身体扭曲、某些帧丢失、人物轨迹突然漂移。

**如何查看 PromptHMR 中间结果？**

查看 `data/video_xxx` 下生成的可视化视频、姿态文件、日志和中间输出目录。

### 关于 SMPL-X

**SMPL-X 是什么？**

SMPL-X 是参数化人体模型，用少量参数表示人体形状、姿态、手部和面部等信息。

**SMPL-X 和 SMPL 有什么区别？**

SMPL 主要表示身体；SMPL-X 扩展了手部和面部表达，人体表达能力更强。

**SMPL-X 为什么适合作为中间表示？**

它是统一标准人体模型，可以把不同视频中的人体动作转成同一种可计算格式。

**SMPL-X 的 pose 参数是什么？**

pose 参数描述各个关节的旋转，也就是人体当前姿态。

**shape 参数是什么？**

shape 参数描述人体体型差异，例如高矮胖瘦。

**translation 是什么？**

translation 是人体整体在三维空间中的平移位置。

**global orientation 是什么？**

global orientation 是人体整体朝向，例如面向前方、左转或右转。

**SMPL-X 是否包含手部动作？**

包含手部参数，但具体能否稳定恢复取决于输入视频清晰度和模型能力。

### 关于 GMR

**GMR 的输入是什么？**

输入是人体动作表示，通常来自 SMPL-X 或相关中间文件。

**GMR 的输出是什么？**

输出是机器人动作文件，例如 `robot_motion.pkl`，用于可视化或仿真。

**什么是 retargeting？**

Retargeting 是把一个身体结构上的动作迁移到另一个身体结构上。例如从人迁移到机器人。

**人体动作如何映射到机器人关节？**

需要建立人体关节和机器人关节之间的对应关系，再通过优化或运动学约束求机器人关节角。

**机器人关节自由度少于人体怎么办？**

只能近似。保留关键动作语义，舍弃机器人无法表达的细节。

**机器人腿长和人腿长不同怎么办？**

需要尺度归一化和姿态重映射，不能直接复制人类关节位置。

**机器人不能做某些动作怎么办？**

需要限制关节角、降低动作幅度、平滑动作，或换成机器人可执行的近似动作。

**映射时如何考虑关节限制？**

在优化中加入关节上下限，防止输出超过机器人机械结构允许范围。

**映射时如何保持平衡？**

视觉复刻阶段不一定保证平衡。物理可行阶段需要考虑重心、足底接触、支撑面和闭环控制。

### 关于机器人动作文件

**`robot_motion.pkl` 是什么？**

它是 Python pickle 文件，保存机器人动作数据，通常包含每一帧的机器人关节状态、根位姿或相关轨迹。

**里面保存的是关节角还是位姿？**

通常会包含关节角，也可能包含根节点位置、朝向、帧率等元数据，具体要用脚本读取确认。

**每一帧对应什么？**

每一帧对应一个时间点的机器人状态。

**帧率是多少？**

取决于输入视频和处理脚本。需要从文件元数据或生成脚本参数中确认。

**如何读取 pkl 文件？**

可以用 Python：

```python
import pickle
with open("robot_motion.pkl", "rb") as f:
    data = pickle.load(f)
print(type(data))
print(data.keys() if hasattr(data, "keys") else None)
```

**如何修改动作？**

先读取 pkl，找到关节角数组，再做裁剪、平滑、缩放或替换。修改前必须备份原文件。

**如何裁剪动作片段？**

按帧索引截取数组，例如保留第 100 到 300 帧。具体字段名要先检查 pkl 结构。

**如何拼接两个动作？**

把两个动作数组按时间维拼接，并在连接处做平滑过渡，避免突然跳变。

**如何平滑动作？**

可以对关节角序列做滑动平均、低通滤波或样条平滑。

### 关于可视化

**robot-viser 是什么？**

robot-viser 是 Web 3D 可视化工具，用来在浏览器中查看机器人动作。

**MuJoCo 是什么？**

MuJoCo 是物理仿真引擎，可以模拟机器人、关节、碰撞和地面接触。

**两者区别是什么？**

robot-viser 更轻量，适合快速看动作；MuJoCo 更接近物理仿真，适合录制和检查物理表现。

**可视化里动作对了，为什么真实机器人还可能失败？**

因为可视化可能没有完整考虑电机力矩、控制延迟、地面摩擦、足底接触和稳定性。

**如何调整机器人颜色？**

通常要修改可视化脚本或机器人模型材质配置。

**如何调整相机角度？**

MuJoCo 脚本通常有 `--camera_azimuth` 等参数；robot-viser 可在浏览器中拖动视角。

**如何导出视频？**

MuJoCo 脚本使用 `--record_video --video_path output.mp4`。

**如何比较人体视频和机器人视频？**

把人体原视频和机器人导出视频并排播放，比较节奏、手脚方向、关键姿态和整体轨迹。

### 关于物理约束

**什么是开环动作？**

开环动作是不根据实时反馈修正的动作播放。给定动作序列后直接执行。

**什么是闭环控制？**

闭环控制会根据传感器反馈不断修正动作，例如根据 IMU 调整姿态。

**为什么开环动作容易摔？**

因为真实环境有扰动、摩擦变化和模型误差，固定动作无法自动纠正偏差。

**什么是足底接触？**

足底接触指机器人脚与地面的接触状态，包括是否接触、接触点和接触力。

**什么是地面摩擦？**

地面摩擦决定脚是否会打滑。摩擦不足时，动作看起来对也可能滑倒。

**什么是重心？**

重心是身体质量的合成位置。双足机器人需要让重心和支撑区域关系合理。

**什么是 ZMP？**

ZMP 是零力矩点，用于分析双足机器人动态稳定性。

**什么是动力学可行性？**

动力学可行表示动作不仅几何上能摆出来，还能在力、扭矩、接触和稳定性上真实执行。

**为什么人类动作不能直接复制给机器人？**

因为人体和机器人结构、质量分布、关节自由度、驱动能力、平衡方式都不同。

### 关于真实机器人

**真实机器人需要什么接口？**

需要底层控制接口，例如关节位置控制、速度控制、力矩控制或厂商 SDK。

**如何把 `robot_motion.pkl` 发送给机器人？**

需要把 pkl 中的关节轨迹转换成机器人控制器可接受的命令格式，并按固定频率发送。

**需要控制频率是多少？**

取决于机器人平台，常见可能是 50Hz、100Hz、200Hz 或更高。

**如何做安全保护？**

限制关节角、速度、力矩；设置急停；先低速小幅测试；远离人和障碍物。

**如何避免摔倒？**

需要稳定控制器、IMU 反馈、足底接触判断、动作平滑和物理可行性检查。

**需要 IMU 反馈吗？**

真实双足机器人通常需要 IMU 反馈来判断身体姿态并修正平衡。

**需要足底力传感器吗？**

如果要精确控制步态和接触，足底力传感器很有帮助，但是否有取决于硬件。

**需要强化学习控制器吗？**

不一定。简单动作可以用传统控制；复杂动态动作通常需要学习型控制器或优化控制。

### 关于 IsaacSim / Isaac Lab

**为什么文档提到 IsaacSim？**

IsaacSim 是更完整的机器人仿真平台，适合高保真视觉、物理和大规模训练。

**IsaacSim 和 MuJoCo 有什么区别？**

MuJoCo 轻量、动力学仿真强；IsaacSim 更重，图形和机器人生态更完整。

**IsaacSim 更适合做什么？**

适合复杂场景、视觉传感器、合成数据、GPU 并行仿真和机器人学习。

**动作映射和强化学习训练是什么关系？**

动作映射给出参考动作；强化学习可以训练控制器，让机器人更稳定地跟踪这些动作。

**如何用 IsaacSim 提升动作稳定性？**

可以在 IsaacSim 中训练 tracking policy，让机器人在扰动下仍能跟随参考动作。

**什么是 Sim2Real？**

Sim2Real 是从仿真迁移到真实机器人。目标是在仿真训练的策略能在真实世界工作。

**为什么仿真成功不代表真实成功？**

真实世界有模型误差、传感器噪声、控制延迟、摩擦差异和硬件限制。
