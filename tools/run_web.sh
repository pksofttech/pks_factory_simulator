#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/web"

PORT="8080"
SKIP_EXPORT=false

for arg in "$@"; do
  case "$arg" in
    --skip-export)
      SKIP_EXPORT=true
      ;;
    -h|--help)
      echo "Usage: $0 [--skip-export] [PORT]"
      echo "  --skip-export   Serve the landing page without running Godot Web export"
      echo "  PORT            HTTP server port (default: 8080)"
      exit 0
      ;;
    *)
      if [[ "$arg" =~ ^[0-9]+$ ]]; then
        PORT="$arg"
      else
        echo "Unknown argument: $arg" >&2
        echo "Usage: $0 [--skip-export] [PORT]" >&2
        exit 1
      fi
      ;;
  esac
done

mkdir -p "${BUILD_DIR}/play" "${BUILD_DIR}/assets/branding"
cp -r "${ROOT_DIR}/site/"* "${BUILD_DIR}/"
cp "${ROOT_DIR}/assets/branding/app_logo.svg" "${BUILD_DIR}/assets/branding/app_logo.svg"

if [[ "${SKIP_EXPORT}" == "false" ]]; then
  if command -v godot >/dev/null 2>&1; then
    echo "Exporting Godot Web build to ${BUILD_DIR}/play/index.html..."
    if ! godot --headless --path "${ROOT_DIR}" --export-release "Web" "${BUILD_DIR}/play/index.html"; then
      echo "Warning: Godot Web export failed." >&2
      echo "Hint: Make sure Godot Web export templates are installed, or re-run with '--skip-export' to preview the landing page." >&2
    fi
  else
    echo "Warning: 'godot' command not found in PATH." >&2
    echo "Hint: Install Godot 4.7.2 + Web export templates, or run with '--skip-export' to preview the landing page." >&2
  fi
fi

echo ""
echo "Serving PKS Factory Simulator:"
echo "  Landing Page:  http://localhost:${PORT}/"
echo "  Web Simulator: http://localhost:${PORT}/play/"
echo ""

exec python3 -m http.server "${PORT}" -d "${BUILD_DIR}"
