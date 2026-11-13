#!/usr/bin/env sh
# Builds Juno and installs it so `juno` works from any terminal.
set -e

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"

if ! command -v zig >/dev/null 2>&1; then
    echo "error: zig is not installed (Juno needs Zig 0.16.0 or later)" >&2
    exit 1
fi

cd "$(dirname "$0")"
echo "Building Juno..."
zig build -Doptimize=ReleaseFast --prefix "$PREFIX"
echo "Installed juno to $BIN_DIR/juno"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        case "$SHELL" in
            */zsh)  RC="$HOME/.zshrc" ;;
            */bash) RC="$HOME/.bashrc" ;;
            *)      RC="$HOME/.profile" ;;
        esac
        if ! grep -qs "$BIN_DIR" "$RC"; then
            printf '\n# Juno editor\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$RC"
            echo "Added $BIN_DIR to PATH in $RC"
        fi
        echo "Restart your terminal or run: source $RC"
        ;;
esac
