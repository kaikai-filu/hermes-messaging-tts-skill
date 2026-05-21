#!/usr/bin/env bash
#
# MiMo TTS Provider (Preset Voices)
# 输入: $1 = text, $2 = voice_name, $3 = output_wav_path
# 输出: WAV 文件到 $3
#
# 通过 MiMo 的 chat/completions API 生成 TTS。
# API Key 优先从环境变量获取，否则从 Hermes config.yaml 读取。
#
# 可用声线 (预设):
#   茉莉, 冰糖, 苏打, 白桦, Mia, Chloe, Milo, Dean, mimo_default

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ====== Load .env (if exists) ======
source "$PROJECT_DIR/scripts/load_env.sh"

# ====== Config ======
API_BASE="${MIMO_API_BASE:-https://token-plan-cn.xiaomimimo.com/v1}"
TEMP_DIR="${TEMP_DIR:-/tmp/hermes-voice}"
REQUEST_TIMEOUT=60

# ====== API Key Resolution ======
resolve_api_key() {
    # 优先级 1: 环境变量（含 .env 加载后的）
    if [[ -n "${MIMO_API_KEY:-}" ]]; then
        echo "$MIMO_API_KEY"
        return
    fi
    # 优先级 2: Hermes config.yaml（Hermes Agent 环境）
    local config_file="${HERMES_HOME:-$HOME/.hermes}/config.yaml"
    if [[ -f "$config_file" ]]; then
        local key
        key=$(grep -A5 'name: mimo-token-plan' "$config_file" | grep 'api_key:' | head -1 | sed 's/.*api_key: *//')
        if [[ -n "$key" ]]; then
            echo "$key"
            return
        fi
    fi
    echo ""
}

# ====== Available preset voices ======
VALID_VOICES=("茉莉" "冰糖" "苏打" "白桦" "Mia" "Chloe" "Milo" "Dean" "mimo_default")

validate_voice() {
    local name="$1"
    for v in "${VALID_VOICES[@]}"; do
        if [[ "$v" == "$name" ]]; then
            return 0
        fi
    done
    return 1
}

main() {
    local text="${1:?Usage: mimo-tts.sh <text> <voice_name> <output_wav>}"
    local voice_name="${2:-茉莉}"
    local output="${3:?Output path required}"

    local api_key
    api_key="$(resolve_api_key)"
    if [[ -z "$api_key" ]]; then
        echo "[mimo-tts] ERROR: MIMO_API_KEY not set" >&2
        echo "[mimo-tts]   Set via: export MIMO_API_KEY=..., or create .env in project root" >&2
        echo "[mimo-tts]   See .env.example for reference" >&2
        exit 1
    fi

    if ! validate_voice "$voice_name"; then
        echo "[mimo-tts] WARNING: Unknown voice '$voice_name', using default" >&2
        voice_name="茉莉"
    fi

    echo "[mimo-tts] Voice: $voice_name" >&2

    mkdir -p "$TEMP_DIR"
    local req_file="$TEMP_DIR/mimo_req_$$.json"
    local resp_file="$TEMP_DIR/mimo_resp_$$.json"

    jq -n \
        --arg voice "$voice_name" \
        --arg text "$text" \
        '{
            model: "mimo-v2.5-tts",
            modalities: ["text", "audio"],
            audio: {voice: $voice, format: "wav"},
            messages: [
                {role: "user", content: "请用语音回复"},
                {role: "assistant", content: $text}
            ]
        }' > "$req_file"

    # 调用 MiMo API，捕获 HTTP 状态码
    local http_code
    http_code=$(curl -s --max-time "$REQUEST_TIMEOUT" \
        -X POST "$API_BASE/chat/completions" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d @"$req_file" \
        -o "$resp_file" \
        -w "%{http_code}") || true

    # 检查 HTTP 状态 + API 错误
    local err_msg
    err_msg=$(jq -r '.error.message // empty' "$resp_file" 2>/dev/null)

    if [[ "$http_code" -ge 400 || -n "$err_msg" ]]; then
        echo "[mimo-tts] ⚠️ API Error (HTTP $http_code): ${err_msg:-unknown}" >&2
        rm -f "$req_file" "$resp_file"
        # Exit code 2 = auth error → 告诉 tts.sh 降级到 Edge TTS
        if [[ "$http_code" -eq 401 || "$http_code" -eq 403 ]]; then
            echo "[mimo-tts]    ↳ API Key invalid/expired — tts.sh will fallback to Edge TTS" >&2
            exit 2
        fi
        exit 1
    fi

    # 提取 base64 WAV
    local audio_b64
    audio_b64=$(jq -r '.choices[0].message.audio.data // empty' "$resp_file" 2>/dev/null)
    if [[ -z "$audio_b64" ]]; then
        echo "[mimo-tts] ERROR: No audio data in response" >&2
        jq '.' "$resp_file" 2>/dev/null | head -10 >&2
        rm -f "$req_file" "$resp_file"
        exit 1
    fi

    echo "$audio_b64" | base64 -d > "$output"

    rm -f "$req_file" "$resp_file"

    echo "[mimo-tts] Done → $output" >&2
}

main "$@"
