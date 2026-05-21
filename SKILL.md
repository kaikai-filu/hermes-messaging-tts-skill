---
name: hermes-messaging-tts-skill
description: "Multi-platform TTS voice messaging skill. Use when generating TTS voice messages for Telegram/Feishu/WeChat delivery. Supports Edge TTS (Microsoft), MiMo TTS (preset voices), and MiMo VoiceClone (reference audio cloning). Triggers on: 每次回复配语音 | 用XX的声音说 | 语音气泡 | 克隆声音 | voice message."
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [tts, voice, multi-platform, telegram, feishu, wechat, voice-clone]
    related_skills: [hermes-agent, imessage]
---

# Messaging TTS Skill — Multi-Platform TTS Delivery Skill

## Overview

将 AI Agent 的文字回复自动转换为语音气泡，跨平台（Telegram / 飞书 / 微信）交付。支持多 TTS Provider，通过统一的 Provider 抽象层实现无缝切换。

### 架构

```
文字回复
   │
   ▼
┌──────────────────────────────┐
│   tts.sh (路由分发层)         │
│   根据声线名 → 选 Provider    │
│   ┌─────────────────────┐    │
│   │ load_env.sh 先加载   │    │  ← ⚠️ 必须：路由层和 Provider 层
│   │ .env 统一环境变量    │    │     共享同一个 Key 视图，避免误降级
│   └─────────────────────┘    │
│   ┌─────────────────────┐    │
│   │ check_mimo_key()     │    │  ← 检测 Key → 不存在/401？降级！
│   └─────────────────────┘    │
└──────┬───────────────────────┘
       │
  ┌────┼────────────┐
  ▼    ▼            ▼
Edge  MiMo TTS     MiMo VoiceClone
TTS   (预设声线)    (克隆声线)
(免费,  (需 Key,       (需 Key + 参考音频)
 无 Key)  白桦/茉莉...)  
  │    │            │
  └────┴────────────┘
       │  WAV
       ▼
┌──────────────────────────────┐
│   Platform Adapter           │
│   Telegram → OGG/Opus        │
│   飞书     → Silk v3         │
│   微信     → AMR / Silk      │
└──────────────────────────────┘
       │
       ▼
[[audio_as_voice]] + text
```

## When to Use

**Always trigger when:**
- 每次写回复都要配语音（此用户的硬性要求）
- 用户说「用XX的声音说」— 切换声线
- 用户说「语音气泡 / 语音消息 / voice message」
- 用户说「克隆我的声音 / 用我的声音」
- 用户说「试试别的声线 / 换个声音」

**Don't use for:**
- 纯文件传输（传 MP3/WAV 文件本身，非语音消息）
- 用户明确说「只要文字，不要语音」

## Voice Map (Provider 路由表)

所有声线名统一管理，调用时只认声线名，不关心背后 Provider：

| 声线名 | Provider | 参数 | 用途 |
|--------|----------|------|------|
| `白桦` | MiMo TTS | voice=白桦 | 稳重男声（当前首选） |
| `茉莉` | MiMo TTS | voice=茉莉 | 默认女声 |
| `冰糖` | MiMo TTS | voice=冰糖 | 甜美女声 |
| `苏打` | MiMo TTS | voice=苏打 | 活泼女声 |
| `Mia` | MiMo TTS | voice=Mia | 英文女声 |
| `Chloe` | MiMo TTS | voice=Chloe | 英文女声 |
| `Milo` | MiMo TTS | voice=Milo | 英文男声 |
| `Dean` | MiMo TTS | voice=Dean | 英文男声 |
| `mimo_default` | MiMo TTS | voice=mimo_default | 默认声线 |
| `xiaoxiao` | Edge TTS | zh-CN-XiaoxiaoNeural | 微软晓晓（免费） |
| `yunxi` | Edge TTS | zh-CN-YunxiNeural | 微软云希（男声） |
| `yunyang` | Edge TTS | zh-CN-YunyangNeural | 微软云扬（男声） |
| `克隆` | MiMo VoiceClone | ref=references/my-voice.wav | 克隆声线 |
| `克隆-备用` | MiMo VoiceClone | ref=references/备用.wav | 备用克隆声线 |

**当前默认声线**：`白桦`（稳重男声）

**切换声线方法**：
- 用户说「用冰糖的声音」→ 将当前 voice 变量切为 `冰糖`
- 用户说「用我的声音」→ 将当前 voice 变量切为 `克隆`
- 用户说「用微软的声音」→ 将当前 voice 变量切为 `xiaoxiao`
- 以此类推

## Core Pipeline

### Step 1: 文字分析 + 语音策略

```python
if len(text) < 200:
    tts_text = text  # 逐字朗读，与文字完全一致
elif len(text) < 800:
    tts_text = summarize(text)  # LLM 摘要核心内容再朗读
else:
    tts_text = text  # 超长直接读
```

**规则**：
- 短文字：内容完全匹配
- 中文字（200-800字）：用 LLM 提取 2-3 句摘要作为语音内容，语音与文字「核心一致但不是逐字对应」。用户原文：「文字过长，就摘要性的读一下」
- 长文字（>800字）：直接读，用户原文：「超长，就直接读」

### Step 2: 调用 TTS Provider

统一入口：`scripts/tts.sh`

```bash
# 用法
scripts/tts.sh "要朗读的文字" "茉莉" /tmp/output.wav
```

内部自动路由到对应 Provider 脚本。

### Step 3: 格式转换

根据目标平台将 WAV 转为对应格式：

```bash
# Telegram: OGG/Opus
scripts/to_ogg.sh /tmp/output.wav /tmp/voice.ogg

# 飞书: Silk v3 (扩展预留)
scripts/to_silk.sh /tmp/output.wav /tmp/voice.silk

# 微信: AMR (扩展预留)
scripts/to_amr.sh /tmp/output.wav /tmp/voice.amr
```

### Step 4: 交付

```markdown
文字内容

[[audio_as_voice]]
MEDIA:/tmp/voice.ogg
```

## Platform Audio Format Reference

| 平台 | 原生格式 | 编解码器 | 容器 | 采样率 | 声道 |
|------|---------|---------|------|--------|------|
| Telegram | 语音气泡 | Opus | OGG | 48000 | Mono |
| 飞书 | 语音消息 | Silk v3 | SILK | 24000 | Mono |
| 微信 | 语音消息 | AMR-NB / Silk | AMR/SILK | 8000/24000 | Mono |
| 通用后备 | 文件附件 | MP3 (libmp3lame) | MP3 | 44100 | Mono |

## Provider Details

### Edge TTS (Microsoft)

**特点**：免费，无需 API Key，中文好，内置在 Hermes 中。

```bash
# 通过 Hermes 内置 text_to_speech 工具调用
# 或直接使用 edge-tts CLI:
edge-tts --voice zh-CN-XiaoxiaoNeural --text "你好" --write-media /tmp/edge.wav
```

**脚本位置**：`scripts/providers/edge.sh`

### MiMo TTS (预设声线)

**特点**：需 API Key（从环境变量/`.env`/Hermes config.yaml 逐级读取），中文质量优于 Edge，有声线选择。
通过 `load_env.sh` 统一加载，使 tts.sh 路由层的 Key 检测（`check_mimo_key_available`）与 Provider 脚本读取的 Key 保持一致。

**默认声线**：白桦（稳重男声）

**脚本路径**：`scripts/providers/mimo-tts.sh` — 自动调用，无需手动传 Key。

**API Key 来源**（按优先级）：
1. 环境变量 `MIMO_API_KEY`（可在 `.env` 文件中设置，由 `load_env.sh` 加载）
2. 用户本地 config 中 `mimo-token-plan` provider 的 `api_key`
3. 均未设置 → tts.sh 路由层检测到无 Key，自动降级至 Edge TTS（yunxi 男声），不会报错退出

> **注意**：tts.sh 路由层与 Provider 脚本共用 `load_env.sh` 加载 `.env` 文件。
> 如果路由层加载了 `.env` 但 Provider 没加载（或者反过来），会导致 Key 检测状态不一致，
> 出现「路由认为没 Key 而降级，但实际 Key 存在」的矛盾。
> 这就是为什么 `load_env.sh` 必须在所有 Provider 调用之前加载，且被双方共同 source。

**底层 API 参考（`scripts/providers/mimo-tts.sh` 内部使用）**：

```bash
curl -s -X POST "https://token-plan-cn.xiaomimimo.com/v1/chat/completions" \
  -H "Authorization: Bearer $MIMO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mimo-v2.5-tts",
    "modalities": ["text", "audio"],
    "audio": {"voice": "茉莉", "format": "wav"},
    "messages": [
      {"role": "user", "content": "用语音回复"},
      {"role": "assistant", "content": "要朗读的文字"}
    ]
  }'
```

**输出提取**：
```bash
jq -r '.choices[0].message.audio.data' response.json | base64 -d > output.wav
```

**关键规则**：
- `modalities` 必须为 `["text", "audio"]`
- `audio.voice` 必须指定预设声线名
- Messages 中必须有 `assistant` role 的消息，内容是待朗读文字
- 返回 WAV (PCM 16-bit, mono, 24000 Hz)

**脚本位置**：`scripts/providers/mimo-tts.sh`

### MiMo VoiceClone (克隆声线)

**特点**：用参考音频克隆任意人的声音，最个性化。

**API**：同 MiMo TTS，但 model 为 `mimo-v2.5-tts-voiceclone`

```bash
# 准备参考音频
ffmpeg -y -i reference.mp3 -ar 24000 -ac 1 -t 10 /tmp/ref.wav
REF_B64=$(base64 -i /tmp/ref.wav | tr -d '\n')
VOICE_URL="data:audio/wav;base64,${REF_B64}"

# 调用 API
jq -n --arg voice "$VOICE_URL" '{
    "model": "mimo-v2.5-tts-voiceclone",
    "modalities": ["text", "audio"],
    "audio": {"voice": $voice, "format": "wav"},
    "messages": [
        {"role": "user", "content": "用这个声音说"},
        {"role": "assistant", "content": "要克隆的声音说这段话"}
    ]
}' | curl -s --max-time 120 -X POST \
  "https://token-plan-cn.xiaomimimo.com/v1/chat/completions" \
  -H "Authorization: Bearer $MIMO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- -o /tmp/vc_resp.json
```

**参考音频要求**：
- WAV mono 24kHz
- 5-10 秒清晰人声
- 从用户语音消息提取：`ffmpeg -i voice.ogg -ar 24000 -ac 1 -t 10 ref.wav`

**脚本位置**：`scripts/providers/mimo-voiceclone.sh`

## Text-to-Voice Strategy (详细规则)

### 何时摘要、何时逐字

核心原则：**语音内容必须与文字匹配**。不是「随便读点啥」，而是：

| 场景 | 做法 | 示例 |
|------|------|------|
| 短文字（<200字） | 原样朗读 | 文字：「今天天气不错」→ 语音：「今天天气不错」 |
| 中文字（200-800字） | LLM 提取 2-4 句摘要 | 文字是一段分析 → 语音：「核心发现有三点：第一…第二…第三…」 |
| 长文字（>800字） | 直接通读 | 保持语音与文字的完整一致性 |

**摘要生成方法**：
1. 用 LLM 对文字做摘要（要求：保留核心信息、自然口语化）
2. 生成的摘要作为 TTS 文本
3. **不要**逐字念满 800 字

### 语音与文字的关系

- **短文字**：语音 = 文字（完全一致）
- **中文字**：语音 ≈ 文字核心（摘要版，核心一致）
- **长文字**：语音 = 文字（直接读）

## Common Pitfalls

1. **语音与文字不匹配**：最常见错误。必须生成语音后再写 final text，不要先读旧语音再改文字。

2. **OGG 在 Telegram 上不显示为语音气泡**：检查编解码器。必须是 `Ogg data, Opus audio, mono, 48000 Hz`。用 `file output.ogg` 验证。

3. **MP3 文件附件代替了语音气泡**：Telegram 上 MP3 会被当作文件。必须用 OGG/Opus + `[[audio_as_voice]]` 标签。

4. **MiMo API 403/401**：**自动降级** — MiMo Key 失效后 tts.sh 会自动切换至 Edge TTS (yunxi 男声) 并在语音中提示。无需手动干预。若要排查 Key 本身，见上方「API Key 来源」检查配置。

5. **VoiceClone 返回空语音**：参考音频格式不对。必须是 WAV mono 24kHz，`data:audio/wav;base64,...` 开头。

6. **Edge TTS 中文发音不自然**：用 `zh-CN-XiaoxiaoNeural`（晓晓）中文效果最好，不要用英文声线读中文。

7. **ffmpeg 转换失败**：macOS 上 brew 安装的 ffmpeg 可能有 dylib 链接问题。见 hermes-agent skill 的修复方案。

8. **长文本超时**：VoiceClone 对长文本生成慢（~120s 超时）。超长文本建议分段生成，或用预设 TTS（更快）。

## Provider Selection Logic (脚本 tts.sh)

```bash
# 真实逻辑（scripts/tts.sh）
# 调用前已通过 load_env.sh 加载 .env，路由层与 Provider 层共享同一 Key 视图
function tts_main() {
    local text="$1"
    local voice_name="$2"  # 如 "茉莉" / "克隆" / "xiaoxiao"
    local output="$3"

    # Step 1: check_mimo_key_available 检测 Key 存在性
    #   - 环境变量 → .env → Hermes config.yaml
    #   - 找到 → MIMO_KEY_EXISTS=true
    #   - 未找到 → MIMO_KEY_EXISTS=false

    case "$voice_name" in
        茉莉|冰糖|苏打|白桦|Mia|Chloe|Milo|Dean|mimo_default)
            if [[ "$MIMO_KEY_EXISTS" != "true" ]]; then
                # 无 Key → 直接降级 Edge TTS
                mimo_fallback_to_edge "$text" "$output"
            else
                # 有 Key → 调 MiMo TTS
                set +e  # 临时关闭 set -e，捕获 exit code
                scripts/providers/mimo-tts.sh "$text" "$voice_name" "$output"
                mimo_exit=$?
                set -e
                if [[ $mimo_exit -eq 2 ]]; then
                    # 401/403 → Key 失效 → 降级
                    mimo_fallback_to_edge "$text" "$output"
                fi
            fi ;;
        克隆|克隆-备用)
            # 同上逻辑，只是调 mimo-voiceclone.sh ;;
        xiaoxiao|yunxi|yunyang)
            scripts/providers/edge.sh "$text" "$voice_name" "$output" ;;
        *)
            # 未知声线 → 同白桦分支（调 MiMo，有降级）
            if [[ "$MIMO_KEY_EXISTS" != "true" ]]; then
                mimo_fallback_to_edge "$text" "$output"
            else
                set +e
                scripts/providers/mimo-tts.sh "$text" "茉莉" "$output"
                mimo_exit=$?
                set -e
                if [[ $mimo_exit -eq 2 ]]; then
                    mimo_fallback_to_edge "$text" "$output"
                fi
            fi ;;
    esac
}
```

## Extending (添加新 Provider)

1. 在 `scripts/providers/` 下创建新脚本，统一输入输出：
   - 输入：`"$1" = 文字`, `"$2" = 声线名`, `"$3" = 输出路径`
   - 输出：WAV 文件到 `$3`
2. 在 `tts.sh` 的 case 分支中添加新声线 → 新 Provider 的路由
3. 更新 VOICE MAP 表

## Verification Checklist

- [ ] `scripts/tts.sh "你好世界" "茉莉" /tmp/test.wav` → 生成有效 WAV 文件
- [ ] `scripts/tts.sh "这是一段测试" "克隆" /tmp/test_clone.wav` → 生成克隆声线 WAV
- [ ] `scripts/tts.sh "Hello" "xiaoxiao" /tmp/test_edge.wav` → 生成 Edge TTS WAV
- [ ] `scripts/to_ogg.sh /tmp/test.wav /tmp/test.ogg` → `file test.ogg` 显示 Opus
- [ ] `file /tmp/test.ogg` → "Ogg data, Opus audio, version 0.1, mono, 48000 Hz"
- [ ] ffmpeg 转换无错误

## Related Files

- `SKILL.md` — 本文件
- `scripts/tts.sh` — Provider 路由分发主入口
- `scripts/providers/edge.sh` — Edge TTS Provider
- `scripts/providers/mimo-tts.sh` — MiMo 预设 TTS Provider
- `scripts/providers/mimo-voiceclone.sh` — MiMo VoiceClone Provider
- `scripts/to_ogg.sh` — WAV → OGG/Opus 转换
- `scripts/to_silk.sh` — WAV → Silk 转换（飞书/微信扩展预留）
- `references/provider-map.md` — Provider 配置详情
- `references/platform-format.md` — 各平台音频格式要求
- `templates/format-examples.md` — 各平台交付格式模板
