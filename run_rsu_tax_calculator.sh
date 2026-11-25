#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python_bin="${PYTHON:-python3}"

if [[ "$(uname -s)" == "Linux" && -x /arm/tools/setup/bin/mrun && -z "${ARM_RSU_MRUN_ACTIVE:-}" ]]; then
    # Arm Linux hosts provide Python/Tk through mrun. Other Unix-like systems,
    # including macOS, should use the local Python.
    export ARM_RSU_MRUN_ACTIVE=1
    exec /arm/tools/setup/bin/mrun +arm/cluster +tct/tk/8.6.5 +swdev +python/python/3.14.4 "$0" "$@"
fi

if ! command -v "$python_bin" >/dev/null 2>&1; then
    echo "Could not find Python executable '$python_bin'. Install Python 3.10+ with Tkinter." >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    set -- --gui
fi

if [[ " $* " == *" --gui "* ]]; then
    if ! "$python_bin" - <<'PY' >/dev/null 2>&1
import tkinter
PY
    then
        echo "Python Tkinter is required for the GUI. Install Python 3.10+ with Tkinter support." >&2
        exit 1
    fi
fi

cd "$script_dir"
exec "$python_bin" rsu_tax_calculator.py "$@"
