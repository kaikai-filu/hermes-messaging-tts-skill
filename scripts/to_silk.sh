#!/usr/bin/env bash
#
# to_silk.sh — WAV → Silk v3 转换 (飞书/微信语音消息扩展预留)
#
# 飞书语音消息要求 Silk v3 编码。
# 微信语音消息可使用 AMR 或 Silk。
#
# 注意: Silk 编码需要 silk-v3-decoder 工具。
# 安装: https://github.com/kn007/silk-v3-decoder
#
# 用法:
#   scripts/to_silk.sh <input_wav> <output_silk> [platform]
#
# 示例:
#   scripts/to_silk.sh /tmp/voice.wav /tmp/voice.silk feishu
#   scripts/to_silk.sh /tmp/voice.wav /tmp/voice.silk wechat

set -euo pipefail

SILK_ENCODER="${SILK_ENCODER:-silk-v3-encoder}"

main() {
    local input="${1:?Usage: to_silk.sh <input_wav> <output_silk> [platform]}"
    local output="${2:?Usage: to_silk.sh <input_wav> <output_silk> [platform]}"
    local platform="${3:-feishu}"

    if [[ ! -f "$input" ]]; then
        echo "[to_silk] ERROR: Input file not found: $input" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$output")"

    if ! command -v "$SILK_ENCODER" &>/dev/null; then
        echo "[to_silk] ERROR: Silk encoder not found" >&2
        echo "[to_silk] Install: https://github.com/kn007/silk-v3-decoder" >&2
        exit 2  # Exit 2 = 工具未安装，非致命错误
    fi

    echo "[to_silk] Platform: $platform" >&2
    echo "[to_silk] NOTE: Silk conversion requires silk-v3-encoder binary" >&2
    echo "[to_silk] This is an EXTENSION RESERVED script — not yet fully tested" >&2

    # TODO: 实现 Silk 编码
    # silk-v3-encoder 的典型调用:
    #   ffmpeg -i input.wav -f s16le -ar 24000 -ac 1 temp.pcm
    #   silk-v3-encoder temp.pcm output.silk -tencent

    echo "[to_silk] WARNING: Silk encoding not fully implemented yet" >&2
    echo "[to_silk] Copying raw PCM as placeholder..." >&2
    ffmpeg -y -i "$input" -ar 24000 -ac 1 -f s16le "$output" 2>/dev/null

    echo "[to_silk] ✅ $output ($(wc -c < "$output") bytes, placeholder)" >&2
}

main "$@"
