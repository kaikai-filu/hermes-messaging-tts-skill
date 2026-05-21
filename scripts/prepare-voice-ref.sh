#!/usr/bin/env bash
#
# prepare-voice-ref.sh — 录制/准备 VoiceClone 参考音频
#
# 用法:
#   scripts/prepare-voice-ref.sh <source_audio> [voice_name]
#
# 参数:
#   source_audio — 来源音频文件 (WAV/MP3/M4A 等，ffmpeg 能处理的格式)
#   voice_name  — 声线名 (默认: "克隆")
#
# 示例:
#   # 从手机录音文件准备
#   scripts/prepare-voice-ref.sh ~/Downloads/my_voice.m4a "克隆"
#
#   # 从麦克风录制 10 秒 (macOS)
#   scripts/prepare-voice-ref.sh mac:record "克隆"
#
# 输出:
#   references/voiceref-<voice_name>.wav (16-bit mono 24kHz, ~10s)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REFERENCES_DIR="$PROJECT_DIR/references"

main() {
    local source_audio="${1:?Usage: prepare-voice-ref.sh <source_audio> [voice_name]}"
    local voice_name="${2:-克隆}"
    local output="$REFERENCES_DIR/voiceref-${voice_name}.wav"

    mkdir -p "$REFERENCES_DIR"

    # macOS: 通过麦克风录制
    if [[ "$source_audio" == "mac:record" ]]; then
        local rec_file="/tmp/hermes_voice_recording_$$.wav"
        echo "[prepare] Recording via macOS microphone..." >&2
        echo "[prepare] Say 10-15 seconds of natural speech, then Ctrl+C" >&2
        sox -d -r 24000 -c 1 -b 16 "$rec_file" trim 0 15 2>/dev/null || \
            ffmpeg -f avfoundation -i ":0" -ar 24000 -ac 1 -t 10 "$rec_file" 2>/dev/null
        source_audio="$rec_file"
    fi

    if [[ ! -f "$source_audio" ]]; then
        echo "[prepare] ERROR: Source audio not found: $source_audio" >&2
        exit 1
    fi

    # 转为标准格式: WAV mono 24kHz 16-bit，取前 10 秒
    echo "[prepare] Processing: $source_audio → $output" >&2
    ffmpeg -y -i "$source_audio" \
        -ar 24000 -ac 1 -sample_fmt s16 \
        -t 10 \
        "$output" 2>/dev/null

    if [[ ! -s "$output" ]]; then
        echo "[prepare] ERROR: Conversion failed" >&2
        exit 1
    fi

    local duration
    duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$output" 2>/dev/null)
    echo "[prepare] ✅ Voice reference saved: $output" >&2
    echo "[prepare]    Duration: ${duration}s, Size: $(wc -c < "$output") bytes" >&2
    echo "[prepare]    Now ready to use with: scripts/tts.sh \"你好\" \"$voice_name\" /tmp/out.wav" >&2
}

main "$@"
