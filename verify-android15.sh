#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="outputs"
OUTFILE="${OUTDIR}/adb-output-${TIMESTAMP}.txt"

mkdir -p "${OUTDIR}"

echo "Starting Android 15 verification run at ${TIMESTAMP}" | tee "${OUTFILE}"

ADB=(adb)
if ! command -v "${ADB[0]}" >/dev/null 2>&1; then
  echo "ERROR: adb not found in PATH" | tee -a "${OUTFILE}"
  exit 2
fi

# Basic device check
echo -e "\n-- Device list --" | tee -a "${OUTFILE}"
"${ADB[@]}" devices -l | tee -a "${OUTFILE}"

# Properties we always want to capture (will be printed even if empty)
PROP_LIST=(
  ro.build.display.id
  ro.build.fingerprint
  ro.build.version.incremental
  ro.build.date.utc
  ro.boot.verifiedbootstate
  ro.boot.flash.locked
  ro.boot.veritymode
  partition.system.verified
)

echo -e "\n-- getprop values --" | tee -a "${OUTFILE}"
for p in "${PROP_LIST[@]}"; do
  echo -n "${p}: " | tee -a "${OUTFILE}"
  "${ADB[@]}" shell getprop "${p}" 2>/dev/null | sed -n '1p' | tee -a "${OUTFILE}"
done

# Helper: run a command and log only if it produces non-empty (non-whitespace) output.
log_if_nonempty() {
  local label="$1"
  shift
  # Run the command, capture stdout+stderr; don't allow non-zero to fail the script
  local out
  out="$("$@" 2>&1 || true)"
  # Trim CRs and check for any non-whitespace characters
  if [[ -n "$(printf '%s' "$out" | tr -d '\r' | tr -d '\n' | sed 's/[[:space:]]//g')" ]]; then
    echo -e "\n-- ${label} (unexpected output) --" | tee -a "${OUTFILE}"
    printf '%s\n' "$out" | tee -a "${OUTFILE}"
  else
    # Intentionally silent when there's no meaningful output
    :
  fi
}

log_if_nonempty "which su" "${ADB[@]}" shell which su
log_if_nonempty "mount contains /system" "${ADB[@]}" shell mount \| grep " /system " || true
log_if_nonempty "avbctl verify" "${ADB[@]}" shell avbctl verify
log_if_nonempty "avbctl get-verity" "${ADB[@]}" shell avbctl get-verity
log_if_nonempty "dm-verity dmesg" "${ADB[@]}" shell dmesg \| grep -i verity || true
log_if_nonempty "getprop test-keys/debug" "${ADB[@]}" shell getprop \| grep -E "test-keys|debug" || true

# Also capture SELinux state (printed regardless)
echo -e "\n-- SELinux enforcement state --" | tee -a "${OUTFILE}"
"${ADB[@]}" shell getenforce 2>/dev/null | tee -a "${OUTFILE}"

echo -e "\nCompleted. Output saved to ${OUTFILE}" | tee -a "${OUTFILE}"
