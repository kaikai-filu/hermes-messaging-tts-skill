#!/usr/bin/env bash
#
# tts.sh — Voice Provider Router
# 统一入口：根据声线名自动路由到对应 Provider
# 内建降级逻辑：MiMo Key 不存在/失效 → 自动切 Edge TTS + 语音提示
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
#
# 降级行为:
#   MiMo Key 未配置 / 已失效 → 自动使用 Edge TTS (yunxi 男声)，
#   并在原文前插入语音提示 "MiMo 语音引擎未配置 API Key..."

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
PROVIDER_DIR="$SCRIPT_DIR/providers"

# ====== Load .env (if exists) ======
source "$SCRIPT_DIR/load_env.sh"

# ====== Default Config ======
DEFAULT_VOICE="${DEFAULT_VOICE:-茉莉}"

# ====== Fallback Config ======
# 当 MiMo 不可用时自动降级到 Edge TTS
FALLBACK_EDGE_VOICE="yunxi"                          # Edge TTS 稳重男声（对标白桦）
FALLBACK_PROMPT="注意：MiMo 语音引擎未配置 API Key 或已失效，已自动切换至 Edge TTS 免费语音引擎。"

# ====== MiMo Key Availability Check ======
# 检测 MIMO_API_KEY 是否可用（不实际调用 API）
check_mimo_key_available() {
    # 优先级 1: 环境变量（含 .env 加载后的）
    if [[ -n "${MIMO_API_KEY:-}" ]]; then
        return 0
    fi
    # 优先级 2: Hermes config.yaml
    local config_file="${HERMES_HOME:-$HOME/.hermes}/config.yaml"
    if [[ -f "$config_file" ]]; then
        local key
        key=$(grep -A5 'name: mimo-token-plan' "$config_file" | grep 'api_key:' | head -1 | sed 's/.*api_key: *//')
        if [[ -n "$key" ]]; then
            return 0
        fi
    fi
    return 1
}

# ====== Fallback to Edge TTS ======
# 在原文前插入语音提示，用 Edge TTS 男声输出
mimo_fallback_to_edge() {
    local text="$1"
    local original_voice="$2"
    local output="$3"

    echo "[tts] ⚠️ MiMo unavailable (API Key missing/invalid), falling back to Edge TTS: $FALLBACK_EDGE_VOICE" >&2
    echo "[tts]    Originally requested voice: $original_voice" >&2

    local prompt_text="${FALLBACK_PROMPT}${text}"
    bash "$PROVIDER_DIR/edge.sh" "$prompt_text" "$FALLBACK_EDGE_VOICE" "$output"
    return $?
}

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

降级行为:
  MiMo API Key 不存在/失效 → 自动使用 Edge TTS (yunxi 男声)，
  并在音频前附加语音提示
EOF
}

# ====== Router ======
route_tts() {
    local text="$1"
    local voice="$2"
    local output="$3"

    case "$voice" in
        # ── MiMo TTS 预设声线 ──
        茉莉|冰糖|苏打|白桦|Mia|Chloe|Milo|Dean|mimo_default)
            if check_mimo_key_available; then
                echo "[tts] → MiMo TTS: $voice" >&2
                set +e
                bash "$PROVIDER_DIR/mimo-tts.sh" "$text" "$voice" "$output"
                local ec=$?
                set -e
                if [[ $ec -eq 2 ]]; then
                    # Auth error (401/403): Key exists but expired/invalid
                    mimo_fallback_to_edge "$text" "$voice" "$output"
                elif [[ $ec -ne 0 ]]; then
                    return $ec
                fi
            else
                # Key not configured at all
                mimo_fallback_to_edge "$text" "$voice" "$output"
            fi
            ;;

        # ── VoiceClone ──
        克隆|克隆-备用)
            if check_mimo_key_available; then
                echo "[tts] → VoiceClone: $voice" >&2
                set +e
                bash "$PROVIDER_DIR/mimo-voiceclone.sh" "$text" "$voice" "$output"
                local ec=$?
                set -e
                if [[ $ec -eq 2 ]]; then
                    mimo_fallback_to_edge "$text" "$voice" "$output"
                elif [[ $ec -ne 0 ]]; then
                    return $ec
                fi
            else
                mimo_fallback_to_edge "$text" "$voice" "$output"
            fi
            ;;

        # ── Edge TTS 免费声线（无需 Key）──
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
            if check_mimo_key_available; then
                set +e
                bash "$PROVIDER_DIR/mimo-tts.sh" "$text" "$DEFAULT_VOICE" "$output"
                local ec=$?
                set -e
                if [[ $ec -eq 2 ]]; then
                    mimo_fallback_to_edge "$text" "$DEFAULT_VOICE" "$output"
                elif [[ $ec -ne 0 ]]; then
                    return $ec
                fi
            else
                mimo_fallback_to_edge "$text" "$DEFAULT_VOICE" "$output"
            fi
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
