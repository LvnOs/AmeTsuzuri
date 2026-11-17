#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/run.sh"

for command in git python3 curl unzip xz tar flock; do
  command -v "$command" >/dev/null || { echo "Required command missing: $command" >&2; exit 1; }
done
mkdir -p "$cloud_cache/sdks"
exec 9>"$cloud_cache/setup.lock"
flock -n 9 || { echo 'Another setup is running.' >&2; exit 1; }

for target in app audio; do
  select_sdk "$target"
  if [[ ! -e $cloud_sdk && ! -L $cloud_sdk ]]; then
    # Clone into a unique staging directory; never reset an existing SDK.
    staging=$(mktemp -d "$cloud_cache/sdks/.install-$cloud_version.XXXXXX")
    trap 'rm -rf -- "$staging"' EXIT
    git clone --depth 1 --branch "$cloud_version" https://github.com/flutter/flutter.git "$staging"
    actual=$(git -C "$staging" rev-parse --verify 'HEAD^{commit}')
    [[ $actual == "$cloud_commit" ]] || { echo 'Downloaded SDK commit mismatch.' >&2; exit 1; }
    mv -- "$staging" "$cloud_sdk"
    trap - EXIT
  fi
  verify_sdk
  "$cloud_sdk/bin/flutter" --version
done

# Root analysis includes the independent audio tool, so prepare both packages.
for target in app audio; do
  select_sdk "$target"
  (
    cd -- "$cloud_project"
    "$cloud_sdk/bin/flutter" pub get --enforce-lockfile
  )
done
printf '%s\n' 'Setup complete. Use: bash tool/cloud/run.sh flutter analyze --no-pub'
