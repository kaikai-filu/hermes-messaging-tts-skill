# Edge TTS (Microsoft) Reference

## 简介

Edge TTS 是 Microsoft 的免费 TTS 服务，通过 `edge-tts` Python 库调用。**免费**、**无需 API Key**、支持 100+ 语言。

## 安装

```bash
pip install edge-tts
```

## 基础用法

```bash
edge-tts --voice zh-CN-XiaoxiaoNeural --text "你好世界" --write-media output.mp3
```

## zh-CN 可用声线

| 声线名 | 音色 | 说明 |
|--------|------|------|
| zh-CN-XiaoxiaoNeural | 女声 | 晓晓，推荐默认，最自然 |
| zh-CN-YunxiNeural | 男声 | 云希 |
| zh-CN-YunyangNeural | 男声 | 云扬 |
| zh-CN-XiaochenNeural | 女声 | 晓辰 |
| zh-CN-XiaohanNeural | 女声 | 晓涵 |
| zh-CN-XiaomengNeural | 女声 | 晓梦 |
| zh-CN-XiaomoNeural | 女声 | 晓墨 |
| zh-CN-XiaoqiuNeural | 女声 | 晓秋 |
| zh-CN-XiaoruiNeural | 女声 | 晓睿 |
| zh-CN-XiaoshuangNeural | 女声 | 晓双 |
| zh-CN-XiaoxuanNeural | 女声 | 晓萱 |
| zh-CN-XiaoyanNeural | 女声 | 晓颜 |
| zh-CN-XiaoyouNeural | 女声 | 晓悠 |
| zh-CN-XiaozhenNeural | 女声 | 晓珍 |
| zh-CN-ZhifanNeural | 男声 | 志凡 |
| zh-CN-ZhinanNeural | 男声 | 志南 |

## 调整语速与音调

```bash
# 语速: +0% ~ +100%
edge-tts --voice zh-CN-XiaoxiaoNeural \
  --rate=+20% \
  --text "稍快一点的语速" \
  --write-media output.mp3

# 音调: -50% ~ +50%
edge-tts --voice zh-CN-XiaoxiaoNeural \
  --pitch=+10Hz \
  --text "高一点的声音" \
  --write-media output.mp3

# SSML 更精确控制
edge-tts --voice zh-CN-XiaoxiaoNeural \
  --text '<speak>你好<break time="500ms"/>世界</speak>' \
  --write-media output.mp3
```

## 优点 vs 缺点

| 优点 | 缺点 |
|------|------|
| 完全免费 | 声音质量不如 MiMo TTS |
| 无需 API Key | 不支持声音克隆 |
| 100+ 语言 | 英文发音偏"微软风格" |
| 语速/音调可调 | 需要安装 Python 包 |
