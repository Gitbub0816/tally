#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/process_aircraft_assets.sh /path/to/3d-models.zip" >&2
  exit 64
fi

archive="$1"
if [[ ! -f "$archive" ]]; then
  echo "Aircraft archive not found: $archive" >&2
  exit 66
fi

blender_bin="${BLENDER_BIN:-/Applications/Blender.app/Contents/MacOS/Blender}"
if [[ ! -x "$blender_bin" ]]; then
  echo "Blender is not installed. Run: brew install --cask blender" >&2
  exit 69
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
processor="$repo_root/scripts/blender/prepare_aircraft.py"
output_dir="$repo_root/ios/Tally/Resources/AircraftModels"
report_dir="$repo_root/build/aircraft-reports"
working_dir="$(mktemp -d "${TMPDIR:-/tmp}/tally-aircraft.XXXXXX")"
trap 'rm -rf "$working_dir"' EXIT

mkdir -p "$output_dir" "$report_dir"
unzip -q "$archive" -d "$working_dir"

mapfile_path="$working_dir/model-map.tsv"
find "$working_dir" -type f \( -iname '*.fbx' -o -iname '*.glb' \) -not -path '*/__MACOSX/*' -print0 |
  while IFS= read -r -d '' source; do
    basename_without_extension="$(basename "${source%.*}")"
    if [[ "$basename_without_extension" == "AIRBUS A220-300" ]]; then
      asset_name="airbus_a220_300"
    elif [[ "$basename_without_extension" == "airbus_a220-300" ]]; then
      continue
    else
      asset_name="$(printf '%s' "$basename_without_extension" | tr '[:upper:] ' '[:lower:]_' | tr -cd 'a-z0-9_-')"
    fi
    printf '%s\t%s\n' "$asset_name" "$source"
  done > "$mapfile_path"

if [[ ! -s "$mapfile_path" ]]; then
  echo "No FBX or GLB aircraft models were found in the archive." >&2
  exit 65
fi

while IFS=$'\t' read -r asset_name source; do
  echo "Processing $asset_name"
  "$blender_bin" --background --factory-startup --python "$processor" -- \
    --input "$source" \
    --output "$output_dir/$asset_name.usdz" \
    --report "$report_dir/$asset_name.json" \
    --target-faces 80000
done < "$mapfile_path"

bundle="$repo_root/build/tally-aircraft-output.zip"
rm -f "$bundle"
(
  cd "$repo_root"
  zip -qr "$bundle" ios/Tally/Resources/AircraftModels build/aircraft-reports
)

echo
echo "Aircraft processing complete."
echo "USDZ assets: $output_dir"
echo "Audit reports: $report_dir"
echo "Upload this file back to Codex: $bundle"
