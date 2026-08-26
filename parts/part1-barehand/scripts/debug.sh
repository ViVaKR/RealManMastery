#!/usr/bin/env zsh

# 사용법:
#   ./scripts/debug.sh                # main 함수에서 브레이크
#   ./scripts/debug.sh Main.S:7        # 특정 라인에서 브레이크
#   ./scripts/debug.sh add_i32         # C# AOT 심볼에서 브레이크

set -euo pipefail

cd "$(dirname "$0")/.."

BREAK_LOCATION="${1:-main}"
BIN_DIR="zig-out/bin"
EXE_PATH="${BIN_DIR}/RealManApp"
DYLIB_PATH="${BIN_DIR}/DotnetLibs.dylib"

# 1. 빌드는 터미널에서 'zig build'로 수동 수행하는 것으로 분리.
# (필요시 아래 주석을 해제하면 자동 빌드 재개)
# echo "==> zig build install"
# zig build install

# 2. macOS LLDB가 C# AOT 동적 라이브러리의 소스 라인/심볼을 제대로 파악하도록 dSYM 생성
if [[ -f "$DYLIB_PATH" ]] && command -v dsymutil >/dev/null 2>&1; then
    echo "==> dsymutil ${DYLIB_PATH}"
    dsymutil "$DYLIB_PATH"
fi

# 3. lldb 실행 (-o "b ..." 를 사용하여 심볼과 파일:라인 방식을 모두 지원)
echo "==> lldb ${EXE_PATH} (break at ${BREAK_LOCATION})"
exec lldb \
    -o "b ${BREAK_LOCATION}" \
    -o "run" \
    "$EXE_PATH"