# messaging-tts-skill 🎤

> Hermes Agent skill — 自动为文字回复生成多平台语音气泡

支持 **3 种 TTS 引擎**，适配 **Telegram / 飞书 / 微信** 等平台的原生语音气泡交付。

## ✨ 特性

- **多 TTS 引擎**：Edge TTS（免费）、MiMo TTS（预设声线）、MiMo VoiceClone（声音克隆）
- **多平台**：Telegram（OGG/Opus 语音气泡）、飞书（Silk）、微信（AMR/Silk）
- **声音克隆**：录制 10-15 秒参考音频，即可用你的声音朗读任意文字
- **零配置**：安装即用，API Key 自动从本地 config 读取（不硬编码在仓库中）
- **完全离线转码**：ffmpeg 本地处理，不依赖第三方转码服务

## 📦 安装

### 通过 Hermes CLI（推荐）

```bash
hermes skills install https://raw.githubusercontent.com/kaikai-filu/messaging-tts-skill/main/SKILL.md --force
```

> `--force` 是必要的，因为安全扫描器会将「可执行脚本 + 网络请求」标记为 DANGEROUS。实际代码安全可审计，详见[安全说明](#-安全说明)。

### 手动安装

```bash
# 克隆仓库
git clone https://github.com/kaikai-filu/messaging-tts-skill.git
# 复制到 skills 目录
cp -r messaging-tts-skill ~/.hermes/skills/media/
# 重载技能
/reload-skills
```

## 🔧 依赖

| 依赖 | 用途 | 安装 |
|:---|:---|:---|
| `ffmpeg` | 音频转码（WAV → OGG/Silk/AMR） | `brew install ffmpeg` |
| `edge-tts` | Edge TTS 引擎 | `pip install edge-tts` |
| `jq` | JSON 解析 | `brew install jq` |
| `curl` | API 请求 | macOS 自带 |

### MiMo API Key

使用预设声线（茉莉/冰糖）或声音克隆需要 MiMo API Key。配置方式（二选一）：

```bash
# 方式 1: 环境变量
export MIMO_API_KEY="tp-xxxxx..."

# 方式 2: config.yaml（推荐）
# 在 ~/.hermes/config.yaml 中配置 provider
```

## 🎙️ 可用声线

| 声线名 | 引擎 | 说明 |
|:---|:---|:---|
| `茉莉` (默认) | MiMo TTS | 预设女声，速度快 |
| `冰糖` | MiMo TTS | 另一种预设女声 |
| `克隆` | MiMo VoiceClone | 需要参考音频 |
| `xiaoxiao` | Edge TTS | 微软晓晓（中文女声） |
| `yunxi` | Edge TTS | 微软云希（中文男声） |
| `xiaoyi` | Edge TTS | 微软小伊（情感女声） |

> 完整声线列表见 [SKILL.md](./SKILL.md#声线表)

## 🧬 声音克隆

### 第一步：准备参考音频

```bash
bash scripts/prepare-voice-ref.sh
```

按提示录制 10-15 秒的语音，保存为 `references/voiceref-my-voice.wav`。

**录音要求**：

| 参数 | 建议值 |
|:---|:---|
| 格式 | WAV, mono, 24kHz |
| 时长 | 10-15 秒 |
| 环境 | 安静，无背景噪音 |
| 语速 | 自然，平稳 |

### 第二步：使用克隆声线

```bash
bash scripts/tts.sh "你好，这是我的克隆声音" "克隆" /tmp/output.wav
```

## 🚀 使用方式

### 在 Hermes Agent 中使用

当 skill 安装并启用后，Agent 会自动加载。触发关键词：

- "加语音" / "配语音"
- "用 XX 的声音说"
- "语音气泡 / 语音消息"
- "克隆我的声音 / 用我的声音"
- "试试别的声线 / 换个声音"

### 命令行直接使用

```bash
# 基本使用（默认茉莉声线）
bash scripts/tts.sh "你好世界" "" /tmp/output.wav

# 指定声线
bash scripts/tts.sh "你好世界" "冰糖" /tmp/output.wav

# 声音克隆
bash scripts/tts.sh "你好世界" "克隆" /tmp/output.wav

# 转 Telegram OGG 语音气泡
bash scripts/to_ogg.sh /tmp/output.wav /tmp/output.ogg

# 转飞书 Silk
bash scripts/to_silk.sh /tmp/output.wav /tmp/output.silk
```

## 📱 平台格式

| 平台 | 格式 | 说明 |
|:---|:---|:---|
| Telegram | OGG/Opus | 原生语音气泡，自动内联播放 |
| 飞书 | Silk | 需 Silk 编码器 |
| 微信 | AMR / Silk | 取决于客户端 |

## 🛡️ 安全说明

安装时 Hermes 安全扫描器可能会标记此 skill 为 DANGEROUS，原因：

| 标记 | 误报原因 |
|:---|:---|
| exfiltration | 文档中提及检查 API Key 环境变量（实际是故障排查说明，非数据外传） |
| persistence | 文档中提及 `config.yaml`（实际是说明 API Key 读取路径，不会修改配置文件） |

所有脚本代码均在 [GitHub](https://github.com/kaikai-filu/messaging-tts-skill) 公开，可自由审计：
- ✅ 不收集任何个人信息
- ✅ 不修改配置文件
- ✅ API Key 只在本地读取，仅发送到 MiMo/Edge 官方 API 端点
- ✅ 无后台进程 / 无定时任务

## 📁 项目结构

```
messaging-tts-skill/
├── SKILL.md                        # Hermes skill 主文档
├── README.md                       # 本文件
├── scripts/
│   ├── tts.sh                      # 路由分发（统一入口）
│   ├── prepare-voice-ref.sh        # VoiceClone 参考音频准备
│   ├── to_ogg.sh                   # WAV → OGG/Opus 转码
│   ├── to_silk.sh                  # WAV → Silk 转码
│   └── providers/
│       ├── edge.sh                 # Edge TTS 引擎
│       ├── mimo-tts.sh             # MiMo 预设声线
│       └── mimo-voiceclone.sh      # MiMo 声音克隆
├── references/
│   ├── edge-tts.md                 # Edge TTS 参考
│   ├── mimo-tts-api.md             # MiMo API 参考
│   ├── platform-formats.md         # 平台格式说明
│   └── voiceref-my-voice.wav       # 你的克隆参考音频（占位）
└── templates/
    └── voice-message.md            # 语音消息模板
```

## 📄 License

MIT — 自由使用、修改、分发。
