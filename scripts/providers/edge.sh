#!/usr/bin/env bash
#
# Edge TTS Provider (Microsoft)
# 输入: $1 = text, $2 = voice_name, $3 = output_wav_path
# 输出: WAV 文件到 $3
#
# Edge TTS 是免费内置方案，无需 API Key。
# 通过 edge-tts CLI 调用。
#
# 可用声线 (zh-CN):
#   xiaoxiao  — 晓晓 (女声, 推荐)
#   yunxi     — 云希 (男声)
#   yunyang   — 云扬 (男声)
#   xiaochen  — 晓辰 (女声)
#   xiaohan   — 晓涵 (女声)
#   xiaomeng  — 晓梦 (女声)
#   xiaomo    — 晓墨 (女声)
#   xiaoqiu   — 晓秋 (女声)
#   xiaorui   — 晓睿 (女声)
#   xiaoshuang — 晓双 (女声)
#   xiaoxuan  — 晓萱 (女声)
#   xiaoyan   — 晓颜 (女声)
#   xiaoyou   — 晓悠 (女声)
#   xiaozhen  — 晓珍 (女声)
#   zhifan    — 志凡 (男声)
#   zhinan    — 志南 (男声)
#
# 注意: macOS 默认 bash 3.2 不支持关联数组，
# 使用 case 语句替代。

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ====== Config ======
TEMP_DIR="${TEMP_DIR:-/tmp/hermes-voice}"

# ====== Voice mapping ======
# 将 skill 中的声线名映射到 edge-tts 实际 voice 名
map_voice() {
    local name="$1"
    case "$name" in
        xiaoxiao)   echo "zh-CN-XiaoxiaoNeural" ;;
        yunxi)      echo "zh-CN-YunxiNeural" ;;
        yunyang)    echo "zh-CN-YunyangNeural" ;;
        xiaochen)   echo "zh-CN-XiaochenNeural" ;;
        xiaohan)    echo "zh-CN-XiaohanNeural" ;;
        xiaomeng)   echo "zh-CN-XiaomengNeural" ;;
        xiaomo)     echo "zh-CN-XiaomoNeural" ;;
        xiaoqiu)    echo "zh-CN-XiaoqiuNeural" ;;
        xiaorui)    echo "zh-CN-XiaoruiNeural" ;;
        xiaoshuang) echo "zh-CN-XiaoshuangNeural" ;;
        xiaoxuan)   echo "zh-CN-XiaoxuanNeural" ;;
        xiaoyan)    echo "zh-CN-XiaoyanNeural" ;;
        xiaoyou)    echo "zh-CN-XiaoyouNeural" ;;
        xiaozhen)   echo "zh-CN-XiaozhenNeural" ;;
        zhifan)     echo "zh-CN-ZhifanNeural" ;;
        zhinan)     echo "zh-CN-ZhinanNeural" ;;
        *)          echo "zh-CN-XiaoxiaoNeural" ;;
    esac
}

main() {
    local text="${1:?Usage: edge.sh <text> <voice_name> <output_wav>}"
    local voice_name="${2:-xiaoxiao}"
    local output="${3:?Output path required}"

    local edge_voice
    edge_voice="$(map_voice "$voice_name")"

    mkdir -p "$TEMP_DIR"
    local tmp_mp3="$TEMP_DIR/edge_$$.mp3"

    echo "[edge] Voice: $edge_voice" >&2

    if ! command -v edge-tts &>/dev/null; then
        echo "[edge] ERROR: edge-tts not found. Install: pip install edge-tts" >&2
        exit 1
    fi

    edge-tts --voice "$edge_voice" --text "$text" --write-media "$tmp_mp3" 2>/dev/null

    if [[ ! -f "$tmp_mp3" ]]; then
        echo "[edge] ERROR: edge-tts produced no output" >&2
        exit 1
    fi

    ffmpeg -y -i "$tmp_mp3" -acodec pcm_s16le -ar 24000 -ac 1 "$output" 2>/dev/null

    rm -f "$tmp_mp3"

    echo "[edge] Done → $output" >&2
}

main "$@"
