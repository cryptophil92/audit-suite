#!/usr/bin/env bash
# tests/test_report_html.sh
# Tests pour core/lib_report_html.sh et bin/report_html.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=../core/lib_report_html.sh
source "core/lib_report_html.sh"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

manifest_path="$TMP_ROOT/manifest.json"
report_path="$TMP_ROOT/report.html"
default_report_path="$TMP_ROOT/default/report.html"
premium_manifest_path="$TMP_ROOT/premium-manifest.json"
premium_report_path="$TMP_ROOT/premium-report.html"
shareable_report_path="$TMP_ROOT/premium-report-shareable.html"
mkdir -p "$TMP_ROOT/default"

cat > "$manifest_path" <<'JSON'
{
  "schema_version": "1.1.0",
  "kind": "audit-suite.manifest",
  "run_id": "AUDIT_HTML_TEST",
  "created_at": "2026-07-01T00:00:00+00:00",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "options": {
    "no_udp": false,
    "no_zeek": true,
    "no_suricata": true,
    "allow_public": false
  },
  "paths": {
    "output": "output/AUDIT_HTML_TEST",
    "logs": "logs/AUDIT_HTML_TEST",
    "manifest": "output/AUDIT_HTML_TEST/manifest.json"
  },
  "summary": {
    "module_count": 3,
    "success_count": 1,
    "partial_count": 1,
    "failed_count": 1,
    "skipped_count": 0,
    "total_duration_seconds": 7,
    "status": "failed"
  },
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "status": "success",
      "rc": 0,
      "duration_seconds": 2,
      "output_path": "output/AUDIT_HTML_TEST/10_network_discovery",
      "reason": ""
    },
    {
      "id": "20_portscan_nmap",
      "name": "Portscan Nmap",
      "path": "modules/20_portscan_nmap.sh",
      "status": "partial",
      "rc": 0,
      "duration_seconds": 2,
      "output_path": "output/AUDIT_HTML_TEST/20_portscan_nmap",
      "reason": "optional UDP scan returned rc=8"
    },
    {
      "id": "xss_test",
      "name": "<script>alert('x')</script>",
      "path": "modules/xss_test.sh",
      "status": "failed",
      "rc": 1,
      "duration_seconds": 5,
      "output_path": "output/AUDIT_HTML_TEST/xss_test",
      "reason": "module returned rc=1 <unsafe>"
    }
  ]
}
JSON

# Le manifest premium réutilise exclusivement la fixture synthétique du contrat
# et inverse volontairement les constats pour tester le tri du rapport.
jq \
  --arg output_path "$TMP_ROOT/output/AUDIT_HTML_PREMIUM" '
    .run_id = "AUDIT_HTML_PREMIUM"
    | .targets = ["192.0.2.0/24"]
    | .paths = {
        output: $output_path,
        logs: ($output_path + "/logs"),
        manifest: ($output_path + "/manifest.json")
      }
    | .summary.module_count = 3
    | .summary.success_count = 1
    | .summary.partial_count = 1
    | .summary.failed_count = 1
    | .summary.skipped_count = 0
    | .summary.total_duration_seconds = 9
    | .summary.status = "failed"
    | .modules = [
        {
          id: "10_network_discovery",
          name: "Découverte réseau",
          path: "modules/10_network_discovery.sh",
          status: "success",
          rc: 0,
          duration_seconds: 2,
          output_path: ($output_path + "/10_network_discovery"),
          reason: ""
        },
        {
          id: "20_portscan_nmap",
          name: "Portscan Nmap",
          path: "modules/20_portscan_nmap.sh",
          status: "partial",
          rc: 0,
          duration_seconds: 2,
          output_path: ($output_path + "/20_portscan_nmap"),
          reason: "optional UDP scan returned rc=8"
        },
        {
          id: "xss_test",
          name: "<script>alert(\"module\")</script>",
          path: "modules/xss_test.sh",
          status: "failed",
          rc: 1,
          duration_seconds: 5,
          output_path: ($output_path + "/xss_test"),
          reason: "module returned rc=1 <unsafe>"
        }
      ]
    | .findings |= reverse
  ' tests/fixtures/findings/manifest-1.2.0.json > "$premium_manifest_path"

report_html_generate "$manifest_path" "$report_path" >/dev/null

[[ -f "$report_path" ]]
grep -q '<!doctype html>' "$report_path"
grep -q 'Rapport Audit Suite' "$report_path"
grep -q 'AUDIT_HTML_TEST' "$report_path"
grep -q 'status-failed' "$report_path"
grep -q 'status-partial' "$report_path"
grep -q 'Modules partiels' "$report_path"
grep -q 'xss_test' "$report_path"
grep -q '&lt;script&gt;alert' "$report_path"
grep -q 'module returned rc=1 &lt;unsafe&gt;' "$report_path"
if grep -q '<script>alert' "$report_path"; then
  echo 'Raw script tag found in generated report' >&2
  exit 1
fi

report_html_generate "$premium_manifest_path" "$premium_report_path" >/dev/null
report_html_generate "$premium_manifest_path" "$shareable_report_path" "shareable" >/dev/null

grep -q '<html lang="fr">' "$premium_report_path"
grep -q 'aria-label="Sommaire du rapport"' "$premium_report_path"
grep -q 'id="synthese"' "$premium_report_path"
grep -q 'id="couverture"' "$premium_report_path"
grep -q 'id="constats"' "$premium_report_path"
grep -q 'id="plan-action"' "$premium_report_path"
grep -q 'id="annexe"' "$premium_report_path"
grep -q '<caption>Résultats des modules</caption>' "$premium_report_path"
grep -q 'scope="col"' "$premium_report_path"
grep -q 'Rapport privé · données sensibles' "$premium_report_path"
grep -q 'Aucune note globale' "$premium_report_path"
grep -q 'Protocole TLS ancien potentiellement accepté' "$premium_report_path"
grep -q 'Bannière de service synthétique &lt;à examiner&gt;' "$premium_report_path"
grep -q 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N' "$premium_report_path"
grep -q 'Non noté' "$premium_report_path"
grep -q 'Vérifier la correction' "$premium_report_path"
grep -q 'synthetic-tls-check.json' "$premium_report_path"
grep -q '&lt;script&gt;alert' "$premium_report_path"
grep -q 'module returned rc=1 &lt;unsafe&gt;' "$premium_report_path"
if grep -q '<script>alert' "$premium_report_path"; then
  echo 'Raw script tag found in premium report' >&2
  exit 1
fi

medium_offset="$(grep -bo 'Protocole TLS ancien potentiellement accepté' "$premium_report_path" | head -n 1 | cut -d: -f1)"
informational_offset="$(grep -bo 'Bannière de service synthétique' "$premium_report_path" | head -n 1 | cut -d: -f1)"
if (( medium_offset >= informational_offset )); then
  echo 'Premium findings were not sorted by priority and severity' >&2
  exit 1
fi

grep -q 'Version partageable · identifiants masqués' "$shareable_report_path"
grep -q 'RAPPORT_PARTAGEABLE' "$shareable_report_path"
grep -q 'Périmètre 1' "$shareable_report_path"
grep -q 'Actif 1' "$shareable_report_path"
grep -q 'masqué dans la version partageable' "$shareable_report_path"
if grep -q '192\.0\.2\.' "$shareable_report_path"; then
  echo 'Raw target address found in shareable report' >&2
  exit 1
fi
if grep -q 'web-01\.example\.invalid' "$shareable_report_path"; then
  echo 'Raw hostname found in shareable report' >&2
  exit 1
fi
if grep -q 'synthetic-tls-check\.json' "$shareable_report_path"; then
  echo 'Raw evidence path found in shareable report' >&2
  exit 1
fi
if grep -q "$TMP_ROOT/output" "$shareable_report_path"; then
  echo 'Raw output path found in shareable report' >&2
  exit 1
fi

cp "$manifest_path" "$TMP_ROOT/default/manifest.json"
bash bin/report_html.sh "$TMP_ROOT/default/manifest.json" >/dev/null
[[ -f "$default_report_path" ]]

bash bin/report_html.sh "$manifest_path" "$TMP_ROOT/cli-report.html" >/dev/null
[[ -f "$TMP_ROOT/cli-report.html" ]]

bash bin/report_html.sh --shareable "$premium_manifest_path" "$TMP_ROOT/cli-shareable.html" >/dev/null
[[ -f "$TMP_ROOT/cli-shareable.html" ]]

cp "$manifest_path" "$TMP_ROOT/technical-manifest.json"
bash bin/report_html.sh --technical "$TMP_ROOT/technical-manifest.json" >/dev/null
[[ -f "$TMP_ROOT/report-technical.html" ]]
grep -q 'Rapport AUDIT-SUITE' "$TMP_ROOT/report-technical.html"

if find "$TMP_ROOT" -type f \( -name '*.manifest.tmp' -o -name '*.renderer.tmp' -o -name '*.html.tmp' \) | grep -q .; then
  echo 'Temporary premium report files were not cleaned up' >&2
  exit 1
fi

printf '[OK] HTML report tests passed\n'
