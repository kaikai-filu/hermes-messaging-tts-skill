# MiMo TTS API Reference

## 基本信息

- **API Base URL**: `https://token-plan-cn.xiaomimimo.com/v1`
- **端点**: `/chat/completions`
- **认证**: Bearer Token (`MIMO_API_KEY`)

## 预设声线 (Preset Voices)

以下是 MiMo TTS 预设声线列表（按音色风格分类）：

| 声线名 | 类型 | 特点 |
|--------|------|------|
| mimo_default | 中性 | 默认声线，通用 |
| 茉莉 | 女声 🏆 | 温柔清晰，推荐作为默认 |
| 冰糖 | 女声 | 甜美活泼 |
| 苏打 | 女声 | 清爽自然 |
| 白桦 | 女声 | 知性沉稳 |
| Mia | 女声 | 英文友好 |
| Chloe | 女声 | 英文友好 |
| Milo | 男声 | 英文友好 |
| Dean | 男声 | 英文友好 |

## Standard TTS 调用

```bash
curl -X POST https://token-plan-cn.xiaomimimo.com/v1/chat/completions \
  -H "Authorization: Bearer $MIMO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mimo-v2.5-tts",
    "modalities": ["text", "audio"],
    "audio": {
      "voice": "茉莉",
      "format": "wav"
    },
    "messages": [
      {"role": "user", "content": "请用语音回复"},
      {"role": "assistant", "content": "要朗读的文字内容"}
    ]
  }'
```

**响应**:
```json
{
  "choices": [{
    "message": {
      "audio": {
        "data": "<base64-encoded-wav>"
      }
    }
  }]
}
```

`audio.data` 是 Base64 编码的 WAV 数据，按自己的需求解码即可。

## VoiceClone 调用

```bash
curl -X POST https://token-plan-cn.xiaomimimo.com/v1/chat/completions \
  -H "Authorization: Bearer $MIMO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mimo-v2.5-tts-voiceclone",
    "modalities": ["text", "audio"],
    "audio": {
      "voice": "data:audio/wav;base64,<参考音频base64数据>",
      "format": "wav"
    },
    "messages": [
      {"role": "user", "content": "用这个声音说"},
      {"role": "assistant", "content": "要朗读的文字内容"}
    ]
  }'
```

### VoiceClone 参考音频要求

| 参数 | 建议值 |
|------|--------|
| 格式 | WAV (PCM) |
| 采样率 | 24 kHz (mono) |
| 时长 | 约 10 秒 (非严格) |
| 声道 | Mono (单声道) |
| 位深 | 16-bit |
| 环境 | 安静，无背景噪音 |

> **录音技巧**: 用手机或麦克风录一段 10-15 秒的说话，语速自然，内容可以是"这是一段用于克隆声音的参考音频，注意保持稳定的音量和清晰度"。保存为 WAV 格式放至 `references/` 目录。

## 环境变量

```
MIMO_API_KEY=<your_api_key>
MIMO_API_BASE=https://token-plan-cn.xiaomimimo.com/v1  # 可选，有默认值
```

API Key 存储在 `~/.hermes/.env` 中。

## 可用模型

| 模型名 | 用途 | 说明 |
|--------|------|------|
| `mimo-v2.5-tts` | 标准 TTS | 预设声线，速度快 |
| `mimo-v2.5-tts-voiceclone` | 声音克隆 | 需要参考音频，速度较慢 |
