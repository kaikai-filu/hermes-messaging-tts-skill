#!/usr/bin/env bash
#
# MiMo VoiceClone Provider (克隆声线)
# 输入: $1 = text, $2 = voice_name, $3 = output_wav_path
# 输出: WAV 文件到 $3
#
# 依赖: MIMO_API_KEY 环境变量（或项目根目录下的 .env 文件）
# 参考音频: 通过 voice_name 在配置中查找对应的参考音频路径
#
# 使用说明:
#   先准备参考音频 → scripts/tts.sh "文字" "克隆" /tmp/output.wav
#   或直接: scripts/providers/mimo-voiceclone.sh "文字" "克隆" /tmp/output.wav

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ====== Load .env (if exists) ======
source "$PROJECT_DIR/scripts/load_env.sh"

# ====== Config ======
API_BASE="${MIMO_API_BASE:-https://token-plan-cn.xiaomimimo.com/v1}"
TEMP_DIR="${TEMP_DIR:-/tmp/hermes-voice}"
REQUEST_TIMEOUT=120  # VoiceClone 请求较慢

# ====== Voice → Reference Audio Mapping ======
# 在这个数组中注册克隆声线：voice_name=path_to_reference_audio
# 第一次使用前需要录制参考音频
declare -A REF_AUDIO_MAP=(
    ["克隆"]="$PROJECT_DIR/references/voiceref-my-voice.wav"
    ["克隆-备用"]="$PROJECT_DIR/references/voiceref-backup.wav"
)

main() {
    local text="${1:?Usage: mimo-voiceclone.sh <text> <voice_name> <output_wav>}"
    local voice_name="${2:-克隆}"
    local output="${3:?Output path required}"

    mkdir -p "$TEMP_DIR"

    # 检查 API Key
    if [[ -z "${MIMO_API_KEY:-}" ]]; then
        echo "[mimo-voiceclone] ERROR: MIMO_API_KEY not set" >&2
        echo "[mimo-voiceclone]   Set via: export MIMO_API_KEY=..., or create .env in project root" >&2
        echo "[mimo-voiceclone]   See .env.example for reference" >&2
        exit 1
    fi

    # 查找参考音频路径
    local ref_audio="${REF_AUDIO_MAP[$voice_name]:-}"
    if [[ -z "$ref_audio" || ! -f "$ref_audio" ]]; then
        echo "[mimo-voiceclone] ERROR: Reference audio for '$voice_name' not found at: $ref_audio" >&2
        echo "[mimo-voiceclone]   Available voices: ${!REF_AUDIO_MAP[*]}" >&2
        echo "[mimo-voiceclone]   Run: scripts/scripts/prepare-voice-ref.sh to set up" >&2
        exit 1
    fi

    echo "[mimo-voiceclone] Voice: $voice_name, Ref: $ref_audio" >&2

    # Step 1: 将参考音频转为 WAV mono 24kHz（如不是该格式）
    local processed_ref="$TEMP_DIR/vc_ref_$$.wav"
    ffmpeg -y -i "$ref_audio" -ar 24000 -ac 1 -t 10 "$processed_ref" 2>/dev/null

    # Step 2: Base64 编码为 DataURL
    local b64_data
    b64_data=$(base64 -i "$processed_ref" | tr -d '\n')
    local voice_url="data:audio/wav;base64,${b64_data}"

    # Step 3: 调用 VoiceClone API
    local req_file="$TEMP_DIR/vc_req_$$.json"
    local resp_file="$TEMP_DIR/vc_resp_$$.json"

    jq -n \
        --arg voice "$voice_url" \
        --arg text "$text" \
        '{
            model: "mimo-v2.5-tts-voiceclone",
            modalities: ["text", "audio"],
            audio: {voice: $voice, format: "wav"},
            messages: [
                {role: "user", content: "用这个声音说"},
                {role: "assistant", content: $text}
            ]
        }' > "$req_file"

    # 调用 VoiceClone API，捕获 HTTP 状态码
    local http_code
    http_code=$(curl -s --max-time "$REQUEST_TIMEOUT" \
        -X POST "$API_BASE/chat/completions" \
        -H "Authorization: Bearer $MIMO_API_KEY" \
        -H "Content-Type: application/json" \
        -d @"$req_file" \
        -o "$resp_file" \
        -w "%{http_code}") || true

    # 检查 HTTP 状态 + API 错误
    if [[ "$http_code" -ge 400 ]] || jq -e '.error' "$resp_file" &>/dev/null; then
        local err_msg
        err_msg=$(jq -r '.error.message // .error // empty' "$resp_file" 2>/dev/null)
        echo "[mimo-voiceclone] ⚠️ API Error (HTTP $http_code): ${err_msg:-unknown}" >&2
        rm -f "$req_file" "$resp_file" "$processed_ref"
        # Exit code 2 = auth error → 告诉 tts.sh 降级到 Edge TTS
        if [[ "$http_code" -eq 401 || "$http_code" -eq 403 ]]; then
            echo "[mimo-voiceclone]    ↳ API Key invalid/expired — tts.sh will fallback to Edge TTS" >&2
            exit 2
        fi
        exit 1
    fi

    # 提取 base64 WAV
    local resp_b64
    resp_b64=$(jq -r '.choices[0].message.audio.data // empty' "$resp_file")
    if [[ -z "$resp_b64" ]]; then
        echo "[mimo-voiceclone] ERROR: No audio data in response" >&2
        jq '.' "$resp_file" >&2
        rm -f "$req_file" "$resp_file" "$processed_ref"
        exit 1
    fi

    # 解码为 WAV
    echo "$resp_b64" | base64 -d > "$output"

    # 验证
    if [[ ! -s "$output" ]]; then
        echo "[mimo-voiceclone] ERROR: Output file is empty" >&2
        rm -f "$req_file" "$resp_file" "$processed_ref"
        exit 1
    fi

    # 清理
    rm -f "$req_file" "$resp_file" "$processed_ref"

    echo "[mimo-voiceclone] Done → $output ($(wc -c < "$output") bytes)" >&2
}

main "$@"
