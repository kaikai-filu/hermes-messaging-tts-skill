#!/usr/bin/env bash
#
# load_env.sh — 加载项目根目录的 .env 文件
# 被 tts.sh（路由层）和各 Provider 脚本共同 source。
# 路由层的 Key 检测 (check_mimo_key_available) 依赖此文件加载 .env，
# 否则会因检测不到 Key 而误降级到 Edge TTS。
#
# 用法:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)/load_env.sh"
#
# 搜索路径:
#   1. 本脚本所在目录的父目录（即项目根目录）下的 .env
#   2. 当前工作目录下的 .env
#
# 优先级: 环境变量 > .env 文件
# 已存在的环境变量不会被 .env 覆盖

load_project_env() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir
    project_dir="$(cd "$script_dir/.." && pwd)"

    local env_file="$project_dir/.env"

    if [[ -f "$env_file" ]]; then
        # 使用 allexport 让所有变量自动导出到子进程
        set -a
        # shellcheck source=/dev/null
        source "$env_file"
        set +a
        echo "[env] ✅ Loaded: $env_file" >&2
        return 0
    fi

    # fallback: 当前目录
    if [[ -f ".env" ]]; then
        set -a
        # shellcheck source=/dev/null
        source ".env"
        set +a
        echo "[env] ✅ Loaded: $(pwd)/.env" >&2
        return 0
    fi

    # 不报错 — .env 是可选的
    return 0
}

load_project_env
