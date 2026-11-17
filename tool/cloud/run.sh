#!/usr/bin/env bash
set -euo pipefail

# Also sourced by setup.sh so installation and execution share the same paths.
cloud_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cloud_cache="$cloud_root/.fvm/cloud"
export PUB_CACHE="$cloud_cache/pub-cache"
export XDG_CONFIG_HOME="$cloud_cache/config"
export ANALYZER_STATE_LOCATION_OVERRIDE="$cloud_cache/analyzer"
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export CI=true
if [[ -z ${CHROME_EXECUTABLE:-} ]] && command -v chromium >/dev/null; then
  export CHROME_EXECUTABLE
  CHROME_EXECUTABLE=$(command -v chromium)
fi

select_sdk() {
  local target=$1
  case "$target" in
    app)
      cloud_project="$cloud_root"
      cloud_version=3.47.0
      cloud_commit=4cf24164269a5ebf0c16a028a00727d0e77bbb05 ;;
    audio)
      cloud_project="$cloud_root/tool/audio_loop_smoke"
      cloud_version=3.44.9
      cloud_commit=6b182d2c7585eba26d4edce0f97630effd256c33 ;;
    *) echo "Unknown SDK target: $target" >&2; return 1 ;;
  esac
  local declared
  declared=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["flutter"])' "$cloud_project/.fvmrc")
  if [[ $declared != "$cloud_version" ]]; then
    echo "SDK pin mismatch: $cloud_project/.fvmrc ($declared != $cloud_version)" >&2
    return 1
  fi
  cloud_sdk="$cloud_cache/sdks/$cloud_version"
}

verify_sdk() {
  local actual root
  root=$(git -C "$cloud_sdk" rev-parse --show-toplevel)
  actual=$(git -C "$cloud_sdk" rev-parse --verify 'HEAD^{commit}')
  if [[ $root != "$cloud_sdk" || $actual != "$cloud_commit" ]]; then
    echo "SDK mismatch at $cloud_sdk; existing files were preserved." >&2
    return 1
  fi
  if [[ -n $(git -C "$cloud_sdk" status --porcelain --untracked-files=normal) ]]; then
    echo "SDK has local changes at $cloud_sdk; refusing to use or overwrite it." >&2
    return 1
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  target=app
  if [[ ${1:-} == --audio ]]; then target=audio; shift; fi
  if [[ ${1:-} != flutter ]]; then
    echo "Usage: bash tool/cloud/run.sh [--audio] flutter <arguments>" >&2
    exit 2
  fi
  shift
  select_sdk "$target"
  verify_sdk
  export PATH="$cloud_sdk/bin:$PATH"
  cd -- "$cloud_project"
  exec "$cloud_sdk/bin/flutter" "$@"
fi
