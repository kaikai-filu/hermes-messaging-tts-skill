#!/usr/bin/env bash
#
# to_ogg.sh — WAV → OGG/Opus 转换 (Telegram 语音气泡专用)
#
# Telegram 语音气泡要求:
#   - 容器: OGG
#   - 编解码器: Opus
#   - 采样率: 48000 Hz
#   - 声道: Mono
#
# 用法:
#   scripts/to_ogg.sh <input_wav> <output_ogg>
#
# 示例:
#   scripts/to_ogg.sh /tmp/voice.wav /tmp/voice.ogg
#   file /tmp/voice.ogg
#   → Ogg data, Opus audio, version 0.1, mono, 48000 Hz

set -euo pipefail

main() {
    local input="${1:?Usage: to_ogg.sh <input_wav> <output_ogg>}"
    local output="${2:?Usage: to_ogg.sh <input_wav> <output_ogg>}"

    if [[ ! -f "$input" ]]; then
        echo "[to_ogg] ERROR: Input file not found: $input" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$output")"

    # WAV → OGG/Opus
    # -c:a libopus: Opus 编解码器
    # -b:a 48k: 48 kbps (语音良好音质)
    # -ar 48000: 48kHz 采样率 (Telegram 标准)
    # -ac 1: 单声道
    ffmpeg -y -i "$input" \
        -c:a libopus \
        -b:a 48k \
        -ar 48000 \
        -ac 1 \
        "$output" 2>/dev/null

    # 验证
    if [[ ! -s "$output" ]]; then
        echo "[to_ogg] ERROR: Conversion failed" >&2
        exit 1
    fi

    local file_info
    file_info=$(file "$output")
    echo "[to_ogg] ✅ $output" >&2
    echo "[to_ogg]    $file_info" >&2

    # 检查是否为正确的 Opus 格式
    if ! echo "$file_info" | grep -qi "opus"; then
        echo "[to_ogg] WARNING: Output may not be Opus format" >&2
    fi
}

main "$@"
