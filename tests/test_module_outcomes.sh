#!/usr/bin/env bash
# tests/test_module_outcomes.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
RUNNER_LIB="$REPO_DIR/core/lib_runner.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
original_path="$PATH"

mkdir -p "$tmp_root/core" "$tmp_root/modules" "$tmp_root/fakebin" \
  "$tmp_root/output/TEST_OUTCOMES" "$tmp_root/logs/TEST_OUTCOMES" "$tmp_root/tmp"

cp "$REPO_DIR/core/lib_logging.sh" "$tmp_root/core/lib_logging.sh"
for module in \
  10_network_discovery.sh \
  20_portscan_nmap.sh \
  80_zeek.sh \
  81_suricata.sh; do
  cp "$REPO_DIR/modules/$module" "$tmp_root/modules/$module"
done

cat >"$tmp_root/fakebin/nmap" <<'FAKE_NMAP'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -n "${NMAP_CALLS_FILE:-}" ]]; then
  printf '%s\n' "$*" >>"$NMAP_CALLS_FILE"
fi

is_discovery=0
is_udp=0
output_base=""

while (( $# > 0 )); do
  case "$1" in
    -sn)
      is_discovery=1
      ;;
    -sU)
      is_udp=1
      ;;
    -oA)
      shift
      output_base="${1:-}"
      ;;
  esac
  shift || true
done

if [[ -n "$output_base" ]]; then
  mkdir -p "$(dirname -- "$output_base")"
  printf 'synthetic nmap output\n' >"${output_base}.nmap"
fi

if [[ "$is_discovery" == "1" ]]; then
  exit 7
fi
if [[ "$is_udp" == "1" ]]; then
  exit 8
fi
exit 0
FAKE_NMAP

cat >"$tmp_root/fakebin/zeek" <<'FAKE_ZEEK'
#!/usr/bin/env bash
exit 0
FAKE_ZEEK
chmod +x "$tmp_root/fakebin/nmap" "$tmp_root/fakebin/zeek"

capture_file="$tmp_root/results.tsv"

(
  cd "$tmp_root"
  # shellcheck source=../core/lib_runner.sh
  source "$RUNNER_LIB"

  # Invoked indirectly by run_modules through Bash dynamic function lookup.
  # shellcheck disable=SC2317,SC2329
  emit() { :; }
  # shellcheck disable=SC2317,SC2329
  _append_module_result() {
    printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$4" "$5" "${10:-}" "$9" >>"$capture_file"
  }

  RUN_ID="TEST_OUTCOMES"
  RUN_DIR="$tmp_root/output/$RUN_ID"
  LOG_DIR="$tmp_root/logs/$RUN_ID"
  LOG_FILE="$LOG_DIR/combined.log"
  LOG_BUS=""
  TMP_DIR="$tmp_root/tmp"
  TARGETS="192.168.1.0/24"
  PROFILE="fast"
  OPTS_NO_UDP=0
  OPTS_NO_ZEEK=1
  OPTS_NO_SURICATA=1
  export RUN_ID RUN_DIR LOG_DIR LOG_FILE LOG_BUS TMP_DIR TARGETS PROFILE
  export OPTS_NO_UDP OPTS_NO_ZEEK OPTS_NO_SURICATA
  # Separate runner fixture; the PATH change is intentionally local.
  # shellcheck disable=SC2030
  export PATH="$tmp_root/fakebin:$original_path"

  run_modules "10_network_discovery.sh 20_portscan_nmap.sh 80_zeek.sh 81_suricata.sh"
)

grep -Fq $'10_network_discovery\tfailed\t7\tmodule returned rc=7' "$capture_file"
grep -Fq $'20_portscan_nmap\tpartial\t0\toptional UDP scan returned rc=8' "$capture_file"
grep -Fq $'80_zeek\tskipped\t0\tdisabled by option OPTS_NO_ZEEK' "$capture_file"
grep -Fq $'81_suricata\tskipped\t0\tdisabled by option OPTS_NO_SURICATA' "$capture_file"

if [[ ! -f "$tmp_root/output/TEST_OUTCOMES/20_portscan_nmap/fast.nmap" ]]; then
  printf '[FAIL] useful TCP output was not preserved for the partial module\n' >&2
  exit 1
fi
if compgen -G "$tmp_root/tmp/module_outcome.*" >/dev/null; then
  printf '[FAIL] module outcome marker was not cleaned up\n' >&2
  exit 1
fi

fallback_capture="$tmp_root/fallback-results.tsv"
nmap_calls="$tmp_root/nmap-calls.txt"
mkdir -p "$tmp_root/output/TEST_NO_RAW" "$tmp_root/logs/TEST_NO_RAW"

(
  cd "$tmp_root"
  # shellcheck source=../core/lib_runner.sh
  source "$RUNNER_LIB"

  # Invoked indirectly by run_modules through Bash dynamic function lookup.
  # shellcheck disable=SC2317,SC2329
  emit() { :; }
  # shellcheck disable=SC2317,SC2329
  _append_module_result() {
    printf '%s\t%s\t%s\t%s\n' "$1" "$4" "$5" "${10:-}" >>"$fallback_capture"
  }

  RUN_ID="TEST_NO_RAW"
  RUN_DIR="$tmp_root/output/$RUN_ID"
  LOG_DIR="$tmp_root/logs/$RUN_ID"
  LOG_FILE="$LOG_DIR/combined.log"
  LOG_BUS=""
  TMP_DIR="$tmp_root/tmp"
  TARGETS="192.168.1.0/24"
  PROFILE="full"
  OPTS_NO_UDP=0
  AUDIT_RAW_SOCKET_AVAILABLE=0
  NMAP_CALLS_FILE="$nmap_calls"
  export RUN_ID RUN_DIR LOG_DIR LOG_FILE LOG_BUS TMP_DIR TARGETS PROFILE
  export OPTS_NO_UDP AUDIT_RAW_SOCKET_AVAILABLE NMAP_CALLS_FILE
  # Separate runner fixture; the PATH change is intentionally local.
  # shellcheck disable=SC2031
  export PATH="$tmp_root/fakebin:$original_path"

  run_modules "20_portscan_nmap.sh"
)

grep -Fq $'20_portscan_nmap\tpartial\t0\traw socket unavailable: TCP connect fallback; OS detection and UDP skipped' \
  "$fallback_capture"
grep -Fq -- '-sT' "$nmap_calls"
if grep -Eq -- '(^| )-sS( |$)|(^| )-sU( |$)|(^| )-O( |$)' "$nmap_calls"; then
  printf '[FAIL] raw-socket Nmap option used in degraded mode\n' >&2
  exit 1
fi

printf '[OK] module outcome tests passed\n'
