# Template: Hermes Agent → Telegram Voice Message
#
# 在 Hermes Agent 中嵌入语音回复的模板。
# Agent 回复的最后附上 [[audio_as_voice]] 和 [[text_to_speech]] 语法。
# 参考现有 hermes-messaging-tts-skill 的 "Execution" 部分。
#
# ─── 用法 ───
# 1. 在 SKILL.md 的 execution 部分包含以下模板
# 2. Agent 自动在每次回复时调用 TTS
# ──────────

# ==============================================
# Template 1: SKILL.md "Execution" 部分 (嵌入已有 skill)
# ==============================================
#
# ## Execution
#
# 1. 当你需要回复语音消息时（默认），先调用 tts.sh 生成语音文件
#    bash <SKILL_DIR>/scripts/tts.sh "朗读文字" "茉莉" /tmp/hermes_voice.wav
#
# 2. 转码为 OGG/Opus (Telegram)
#    bash <SKILL_DIR>/scripts/to_ogg.sh /tmp/hermes_voice.wav /tmp/hermes_voice.ogg
#
# 3. 在回复中附上语音文件
#    ```
#    回复的文字内容
#
#    MEDIA:/tmp/hermes_voice.ogg
#    ```

# ==============================================
# Template 2: 单步 TTS 调用 (shell 版)
# ==============================================
#
# ```bash
# # 文字 → WAV → OGG → Telegram 语音气泡
# SKILL_DIR="/Users/yzy/workAround/hermes-area/hermes-messaging-tts-skill"
# TEXT="要朗读的内容"
# VOICE="茉莉"    # 可选: 茉莉, 冰糖, 克隆, xiaoxiao...
#
# # Step 1: TTS 生成
# bash "$SKILL_DIR/scripts/tts.sh" "$TEXT" "$VOICE" /tmp/hermes_voice.wav
#
# # Step 2: 转 OGG
# bash "$SKILL_DIR/scripts/to_ogg.sh" /tmp/hermes_voice.wav /tmp/hermes_voice.ogg
#
# # Step 3: 删除临时 WAV
# rm -f /tmp/hermes_voice.wav
#
# # Step 4: 输出给 Telegram
# echo "MEDIA:/tmp/hermes_voice.ogg"
# ```

# ==============================================
# Template 3: 使用 Hermes 内置 text_to_speech 工具
# ==============================================
#
# 如果 Hermes Agent 已配置正确的 TTS Provider：
#
# 1. 用 text_to_speech 工具生成
#    text_to_speech(text="要朗读的文字", output_path="/tmp/hermes_voice.ogg")
#
# 2. 在回复中包含 MEDIA: 路径
#    文字内容
#
#    MEDIA:/tmp/hermes_voice.ogg

# ==============================================
# Template 4: 多平台适配 (扩展)
# ==============================================
#
# ```python
# import subprocess
# import platform as pf
#
# SKILL_DIR = "/Users/yzy/workAround/hermes-area/voice-messaging"
# text = "要朗读的文字"
# voice = "茉莉"
# platform = "telegram"  # or "feishu", "wechat"
#
# # Step 1: TTS
# subprocess.run(["bash", f"{SKILL_DIR}/scripts/tts.sh", text, voice, "/tmp/voice.wav"])
#
# # Step 2: 平台适配
# if platform == "telegram":
#     subprocess.run(["bash", f"{SKILL_DIR}/scripts/to_ogg.sh", "/tmp/voice.wav", "/tmp/voice.ogg"])
#     output = "/tmp/voice.ogg"
# elif platform == "feishu":
#     subprocess.run(["bash", f"{SKILL_DIR}/scripts/to_silk.sh", "/tmp/voice.wav", "/tmp/voice.silk", "feishu"])
#     output = "/tmp/voice.silk"
# else:
#     output = "/tmp/voice.wav"
#
# print(f"MEDIA:{output}")
# ```
