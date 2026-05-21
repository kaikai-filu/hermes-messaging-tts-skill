#!/usr/bin/env bash
#
# tts.sh — Voice Provider Router
# 统一入口：根据声线名自动路由到对应 Provider
#
# 用法:
#   scripts/tts.sh <text> <voice_name> <output_wav>
#
# 示例:
#   scripts/tts.sh "你好世界" "茉莉" /tmp/out.wav
#   scripts/tts.sh "用克隆声音" "克隆" /tmp/out.wav
#   scripts/tts.sh "Hello" "xiaoxiao" /tmp/out.wav
#
# 返回值:
#   0 = 成功
#   1 = 失败（Provider 不可用、参数错误等）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
PROVIDER_DIR="$SCRIPT_DIR/providers"

# ====== Load .env (if exists) ======
source "$SCRIPT_DIR/load_env.sh"

# ====== Default Config ======
DEFAULT_VOICE="${DEFAULT_VOICE:-茉莉}"

# ====== Help ======
show_help() {
    cat <<EOF
用法: tts.sh <text> <voice_name> <output_wav>

声线列表 (Voice Map):
  MiMo TTS (预设):   茉莉, 冰糖, 苏打, 白桦, Mia, Chloe, Milo, Dean, mimo_default
  VoiceClone (克隆):  克隆, 克隆-备用 (需先准备参考音频)
  Edge TTS (微软):    xiaoxiao, yunxi, yunyang (免费，无需 Key)

环境变量:
  MIMO_API_KEY   — MiMo API Key (MiMo TTS / VoiceClone 必需)
                    也可在项目根目录创建 .env 文件（参见 .env.example）
  MIMO_API_BASE  — MiMo API Base URL (可选，有默认值)
  TEMP_DIR       — 临时目录 (可选，默认 /tmp/hermes-voice)
  DEFAULT_VOICE  — 默认声线 (可选，默认 茉莉)
EOF
}

# ====== Router ======
route_tts() {
    local text="$1"
    local voice="$2"
    local output="$3"

    # 根据声线名确定 Provider 并调用
    case "$voice" in
        茉莉|冰糖|苏打|白桦|Mia|Chloe|Milo|Dean|mimo_default)
            echo "[tts] → MiMo TTS: $voice" >&2
            bash "$PROVIDER_DIR/mimo-tts.sh" "$text" "$voice" "$output"
            ;;

        克隆|克隆-备用)
            echo "[tts] → VoiceClone: $voice" >&2
            bash "$PROVIDER_DIR/mimo-voiceclone.sh" "$text" "$voice" "$output"
            ;;

        xiaoxiao|yunxi|yunyang|xiaochen|xiaohan|xiaomeng|xiaomo|xiaoqiu|xiaorui|xiaoshuang|xiaoxuan|xiaoyan|xiaoyou|xiaozhen|zhifan|zhinan)
            echo "[tts] → Edge TTS: $voice" >&2
            bash "$PROVIDER_DIR/edge.sh" "$text" "$voice" "$output"
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            echo "[tts] WARNING: Unknown voice '$voice', falling back to '$DEFAULT_VOICE'" >&2
            bash "$PROVIDER_DIR/mimo-tts.sh" "$text" "$DEFAULT_VOICE" "$output"
            ;;
    esac
}

# ====== Main ======
main() {
    if [[ $# -lt 3 ]]; then
        echo "[tts] ERROR: Missing arguments" >&2
        show_help >&2
        exit 1
    fi

    local text="$1"
    local voice="${2:-$DEFAULT_VOICE}"
    local output="$3"

    # 创建输出目录
    mkdir -p "$(dirname "$output")"
    # 确保临时目录存在
    mkdir -p "${TEMP_DIR:-/tmp/hermes-voice}"

    route_tts "$text" "$voice" "$output"

    # 最终验证
    if [[ -s "$output" ]]; then
        local wav_info
        wav_info=$(file "$output" 2>/dev/null || echo "unknown")
        echo "[tts] ✅ Success: $voice → $output" >&2
        echo "[tts]    Format: $wav_info" >&2
    else
        echo "[tts] ❌ Failed: output file empty or missing" >&2
        exit 1
    fi
}

main "$@"
