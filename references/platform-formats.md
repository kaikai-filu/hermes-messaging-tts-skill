# Platform Audio Format Reference

## Telegram (当前支持 ✅)

| 属性 | 要求 |
|------|------|
| 容器 | OGG |
| 编解码器 | Opus |
| 采样率 | 48000 Hz |
| 声道 | Mono |
| 码率 | ~48 kbps |
| 交付方式 | `[[audio_as_voice]]` 魔法语法 |

Telegram 语音气泡自动以原生音频组件显示，无需用户点击下载。

## 飞书 (扩展预留)

| 属性 | 要求 |
|------|------|
| 容器 | Silk v3 |
| 编解码器 | Silk |
| 采样率 | 24000 Hz |
| 声道 | Mono |
| 工具 | silk-v3-encoder |

飞书自定义机器人支持通过 `media_id` 发送语音消息，需先上传文件获取 `media_id`。

## 微信 (扩展预留)

| 属性 | 要求 |
|------|------|
| 容器 | AMR 或 Silk |
| 编解码器 | AMR-NB / Silk |
| 采样率 | 8000或16000 Hz |
| 声道 | Mono |

微信的语音消息格式取决于企微或个人微信 bot 的实现差异。

## 转换工具

```bash
# WAV → OGG/Opus (Telegram)
ffmpeg -y -i input.wav -c:a libopus -b:a 48k -ar 48000 -ac 1 output.ogg

# WAV → Silk (飞书/微信 - 需要第三方编码器)
ffmpeg -y -i input.wav -f s16le -ar 24000 -ac 1 temp.pcm
silk-v3-encoder temp.pcm output.silk

# WAV → AMR (微信)
ffmpeg -y -i input.wav -ar 8000 -ac 1 -c:a libamr_nb output.amr
```
