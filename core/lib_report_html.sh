#!/usr/bin/env bash
# core/lib_report_html.sh
# @version 0.2.5
set -Eeuo pipefail

_report_html_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to generate HTML reports" >&2
    return 1
  fi
}

_report_html_validate_manifest() {
  local manifest_path="$1"

  if [[ ! -f "$manifest_path" ]]; then
    echo "Manifest introuvable: $manifest_path" >&2
    return 1
  fi

  jq -e 'type == "object" and (.run_id | type == "string") and ((.modules // []) | type == "array")' "$manifest_path" >/dev/null
}

report_html_default_output_path() {
  local manifest_path="$1"
  printf '%s\n' "$(dirname -- "$manifest_path")/report.html"
}

report_html_generate() {
  local manifest_path="$1"
  local output_path="${2:-}"
  local tmp_path

  _report_html_require_jq
  _report_html_validate_manifest "$manifest_path"

  if [[ -z "$output_path" ]]; then
    output_path="$(report_html_default_output_path "$manifest_path")"
  fi

  mkdir -p "$(dirname -- "$output_path")"
  tmp_path="${output_path}.tmp"

  jq -r '
    def h: tostring | @html;
    def status_class($s):
      if $s == "success" then "status-success"
      elif $s == "failed" then "status-failed"
      elif $s == "skipped" then "status-skipped"
      else "status-unknown"
      end;
    def status_label($s):
      if $s == "success" then "Succès"
      elif $s == "failed" then "Échec"
      elif $s == "skipped" then "Ignoré"
      elif $s == "empty" then "Vide"
      else "Inconnu"
      end;
    def yesno($b): if $b then "oui" else "non" end;
    def module_rows:
      if ((.modules // []) | length) == 0 then
        "<tr><td colspan=\"7\">Aucun résultat module enregistré.</td></tr>"
      else
        ((.modules // []) | map(
          "<tr>" +
          "<td><code>" + ((.id // "") | h) + "</code></td>" +
          "<td>" + ((.name // "") | h) + "</td>" +
          "<td><span class=\"badge " + status_class(.status // "unknown") + "\">" + status_label(.status // "unknown") + "</span></td>" +
          "<td>" + ((.rc // "") | h) + "</td>" +
          "<td>" + ((.duration_seconds // 0) | h) + " s</td>" +
          "<td><code>" + ((.output_path // "") | h) + "</code></td>" +
          "<td>" + ((.reason // "") | h) + "</td>" +
          "</tr>"
        ) | join("\n"))
      end;

    "<!doctype html>",
    "<html lang=\"fr\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>Rapport AUDIT-SUITE - " + (.run_id | h) + "</title>",
    "  <style>",
    "    :root { color-scheme: light; font-family: Arial, Helvetica, sans-serif; }",
    "    body { margin: 0; background: #f6f7f9; color: #1f2933; }",
    "    header { background: #111827; color: #fff; padding: 24px 32px; }",
    "    main { padding: 24px 32px; max-width: 1180px; margin: 0 auto; }",
    "    h1, h2 { margin: 0 0 12px; }",
    "    section { background: #fff; border: 1px solid #d9dee7; border-radius: 10px; padding: 18px; margin-bottom: 18px; }",
    "    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; }",
    "    .card { border: 1px solid #e3e7ee; border-radius: 8px; padding: 12px; background: #fbfcfe; }",
    "    .label { color: #52616f; font-size: 12px; text-transform: uppercase; letter-spacing: .04em; }",
    "    .value { font-size: 20px; font-weight: 700; margin-top: 4px; }",
    "    table { width: 100%; border-collapse: collapse; font-size: 14px; }",
    "    th, td { border-bottom: 1px solid #e3e7ee; padding: 9px; text-align: left; vertical-align: top; }",
    "    th { background: #f1f4f8; font-weight: 700; }",
    "    code { font-family: Consolas, Menlo, monospace; font-size: 13px; }",
    "    .badge { display: inline-block; border-radius: 999px; padding: 3px 9px; font-weight: 700; font-size: 12px; }",
    "    .status-success { background: #dcfce7; color: #166534; }",
    "    .status-failed { background: #fee2e2; color: #991b1b; }",
    "    .status-skipped { background: #fef3c7; color: #92400e; }",
    "    .status-unknown { background: #e5e7eb; color: #374151; }",
    "    .notice { border-left: 4px solid #f59e0b; background: #fffbeb; padding: 12px; }",
    "  </style>",
    "</head>",
    "<body>",
    "<header>",
    "  <h1>Rapport AUDIT-SUITE</h1>",
    "  <div>Run <code>" + (.run_id | h) + "</code></div>",
    "</header>",
    "<main>",
    "  <section>",
    "    <h2>Résumé</h2>",
    "    <div class=\"grid\">",
    "      <div class=\"card\"><div class=\"label\">Statut</div><div class=\"value\"><span class=\"badge " + status_class(.summary.status // "unknown") + "\">" + status_label(.summary.status // "unknown") + "</span></div></div>",
    "      <div class=\"card\"><div class=\"label\">Modules</div><div class=\"value\">" + ((.summary.module_count // ((.modules // []) | length)) | h) + "</div></div>",
    "      <div class=\"card\"><div class=\"label\">Succès</div><div class=\"value\">" + ((.summary.success_count // 0) | h) + "</div></div>",
    "      <div class=\"card\"><div class=\"label\">Échecs</div><div class=\"value\">" + ((.summary.failed_count // 0) | h) + "</div></div>",
    "      <div class=\"card\"><div class=\"label\">Ignorés</div><div class=\"value\">" + ((.summary.skipped_count // 0) | h) + "</div></div>",
    "      <div class=\"card\"><div class=\"label\">Durée totale</div><div class=\"value\">" + ((.summary.total_duration_seconds // 0) | h) + " s</div></div>",
    "    </div>",
    "  </section>",
    "  <section>",
    "    <h2>Contexte d'exécution</h2>",
    "    <table>",
    "      <tr><th>Champ</th><th>Valeur</th></tr>",
    "      <tr><td>Date</td><td>" + ((.created_at // "") | h) + "</td></tr>",
    "      <tr><td>Profil</td><td>" + ((.profile // "") | h) + "</td></tr>",
    "      <tr><td>Cibles</td><td><code>" + ((.targets // []) | join(", ") | h) + "</code></td></tr>",
    "      <tr><td>IP publiques autorisées</td><td>" + yesno(.options.allow_public // false) + "</td></tr>",
    "      <tr><td>Sans UDP</td><td>" + yesno(.options.no_udp // false) + "</td></tr>",
    "      <tr><td>Sans Zeek</td><td>" + yesno(.options.no_zeek // false) + "</td></tr>",
    "      <tr><td>Sans Suricata</td><td>" + yesno(.options.no_suricata // false) + "</td></tr>",
    "      <tr><td>Manifest</td><td><code>" + ((.paths.manifest // "") | h) + "</code></td></tr>",
    "      <tr><td>Sortie</td><td><code>" + ((.paths.output // "") | h) + "</code></td></tr>",
    "      <tr><td>Logs</td><td><code>" + ((.paths.logs // "") | h) + "</code></td></tr>",
    "    </table>",
    "  </section>",
    "  <section>",
    "    <h2>Modules</h2>",
    "    <table>",
    "      <tr><th>ID</th><th>Nom</th><th>Statut</th><th>RC</th><th>Durée</th><th>Sortie</th><th>Raison</th></tr>",
    module_rows,
    "    </table>",
    "  </section>",
    "  <section class=\"notice\">",
    "    <strong>Périmètre :</strong> ce rapport doit uniquement concerner un réseau personnel, un lab, un CTF/HTB ou un environnement explicitement autorisé.",
    "  </section>",
    "</main>",
    "</body>",
    "</html>"
  ' "$manifest_path" > "$tmp_path"

  mv "$tmp_path" "$output_path"
  printf '%s\n' "$output_path"
}
