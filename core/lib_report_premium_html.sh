#!/usr/bin/env bash
# core/lib_report_premium_html.sh
# @version 0.2.35
set -Eeuo pipefail

# shellcheck source=lib_findings.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib_findings.sh"

_report_premium_require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to generate premium HTML reports" >&2
    return 1
  fi
}

_report_premium_validate_mode() {
  local mode="$1"

  case "$mode" in
    private|shareable)
      return 0
      ;;
    *)
      echo "Unsupported report mode: $mode" >&2
      return 1
      ;;
  esac
}

report_html_default_output_path() {
  local manifest_path="$1"
  local mode="${2:-private}"
  local filename="report.html"

  _report_premium_validate_mode "$mode"

  if [[ "$mode" == "shareable" ]]; then
    filename="report-shareable.html"
  fi

  printf '%s\n' "$(dirname -- "$manifest_path")/$filename"
}

report_html_generate() {
  local manifest_path="$1"
  local output_path="${2:-}"
  local mode="${3:-private}"
  local tmp_path normalized_path renderer_path

  _report_premium_require_jq
  _report_premium_validate_mode "$mode"
  findings_validate_manifest_file "$manifest_path"

  if [[ -z "$output_path" ]]; then
    output_path="$(report_html_default_output_path "$manifest_path" "$mode")"
  fi

  mkdir -p "$(dirname -- "$output_path")"
  if ! tmp_path="$(mktemp -- "${output_path}.tmp.XXXXXX")"; then
    return 1
  fi
  if ! normalized_path="$(mktemp -- "${output_path}.manifest.tmp.XXXXXX")"; then
    rm -f -- "$tmp_path"
    return 1
  fi
  if ! renderer_path="$(mktemp -- "${output_path}.renderer.tmp.XXXXXX")"; then
    rm -f -- "$tmp_path" "$normalized_path"
    return 1
  fi

  if ! findings_normalize_manifest_file "$manifest_path" > "$normalized_path"; then
    rm -f -- "$normalized_path" "$tmp_path" "$renderer_path"
    return 1
  fi

  if ! cat > "$renderer_path" <<'JQ'
    def h: tostring | @html;

    def status_class($status):
      if $status == "success" then "status-success"
      elif $status == "partial" then "status-partial"
      elif $status == "failed" then "status-failed"
      elif $status == "skipped" then "status-skipped"
      else "status-unknown"
      end;

    def status_label($status):
      if $status == "success" then "Terminé"
      elif $status == "partial" then "Partiel"
      elif $status == "failed" then "Échoué"
      elif $status == "skipped" then "Ignoré"
      elif $status == "empty" then "Vide"
      else "Inconnu"
      end;

    def severity_rank($severity):
      if $severity == "critical" then 6
      elif $severity == "high" then 5
      elif $severity == "medium" then 4
      elif $severity == "low" then 3
      elif $severity == "informational" then 2
      else 1
      end;

    def severity_label($severity):
      if $severity == "critical" then "Critique"
      elif $severity == "high" then "Élevée"
      elif $severity == "medium" then "Moyenne"
      elif $severity == "low" then "Faible"
      elif $severity == "informational" then "Information"
      else "Inconnue"
      end;

    def confidence_rank($confidence):
      if $confidence == "high" then 3
      elif $confidence == "medium" then 2
      else 1
      end;

    def confidence_label($confidence):
      if $confidence == "high" then "Élevée"
      elif $confidence == "medium" then "Moyenne"
      else "Faible"
      end;

    def validation_label($validation):
      if $validation == "observed" then "Observé"
      elif $validation == "potential" then "À confirmer"
      elif $validation == "confirmed" then "Confirmé"
      elif $validation == "false_positive" then "Faux positif"
      elif $validation == "accepted_risk" then "Risque accepté"
      elif $validation == "resolved" then "Résolu"
      else "Inconnu"
      end;

    def type_label($type):
      if $type == "observation" then "Observation"
      elif $type == "potential_vulnerability" then "Vulnérabilité potentielle"
      elif $type == "confirmed_vulnerability" then "Vulnérabilité confirmée"
      else "Information"
      end;

    def priority_rank($priority):
      if $priority == "immediate" then 5
      elif $priority == "short_term" then 4
      elif $priority == "planned" then 3
      elif $priority == "monitor" then 2
      else 1
      end;

    def priority_label($priority):
      if $priority == "immediate" then "Immédiate"
      elif $priority == "short_term" then "Court terme"
      elif $priority == "planned" then "Planifiée"
      elif $priority == "monitor" then "À surveiller"
      else "Aucune action"
      end;

    def effort_label($effort):
      if $effort == "low" then "Faible"
      elif $effort == "medium" then "Moyen"
      elif $effort == "high" then "Élevé"
      else "Inconnu"
      end;

    def yesno($value): if $value then "oui" else "non" end;

    def anonymize_manifest:
      . as $manifest
      | (($manifest.targets // [])
        | to_entries
        | map({
            key: .value,
            value: ("Périmètre " + ((.key + 1) | tostring))
          })
        | from_entries) as $target_aliases
      | (($manifest.findings // [])
        | map(.asset.id)
        | unique
        | to_entries
        | map({
            key: .value,
            value: ("Actif " + ((.key + 1) | tostring))
          })
        | from_entries) as $asset_aliases
      | $manifest
      | .run_id = "RAPPORT_PARTAGEABLE"
      | .targets = (($manifest.targets // []) | map($target_aliases[.] // "Périmètre masqué"))
      | .paths = {
          output: "masqué dans la version partageable",
          logs: "masqué dans la version partageable",
          manifest: "masqué dans la version partageable"
        }
      | .modules = ((.modules // []) | map(
          .output_path = "masqué dans la version partageable"
        ))
      | .findings = ((.findings // []) | map(
          .scope.target = ($target_aliases[.scope.target] // "Périmètre masqué")
          | .asset.id = ($asset_aliases[.asset.id] // "Actif masqué")
          | if (.asset | has("address")) then
              .asset.address = "masquée"
            else
              .
            end
          | if (.asset | has("hostname")) then
              .asset.hostname = "masqué"
            else
              .
            end
          | .evidence = ((.evidence // []) | map(
              .path = "masqué dans la version partageable"
            ))
          | .source.provenance = "Provenance détaillée disponible dans le rapport privé."
        ));

    def sorted_findings:
      (.findings // [])
      | sort_by([
          -(priority_rank(.remediation.priority // "none")),
          -(severity_rank(.severity // "unknown")),
          -(confidence_rank(.confidence // "low")),
          (.id // "")
        ]);

    def indexed_findings:
      sorted_findings | to_entries;

    def finding_anchor($entry):
      "finding-" + (($entry.key + 1) | tostring);

    def service_text($service):
      if $service == null then
        "Aucun service spécifique"
      else
        (($service.transport // "other") | ascii_upcase)
        + "/"
        + (($service.port // "") | tostring)
        + " — "
        + ($service.name // "service")
      end;

    def score_badge($scoring):
      if ($scoring.status // "unscored") == "scored" then
        "<span class=\"badge score-scored\">"
        + (($scoring.score // "") | h)
        + "/"
        + (($scoring.scale // "") | h)
        + "</span>"
      else
        "<span class=\"badge score-unscored\">Non noté</span>"
      end;

    def reference_item:
      if test("^https?://") then
        "<li><a href=\"" + h + "\" rel=\"noreferrer\">" + h + "</a></li>"
      else
        "<li><code>" + h + "</code></li>"
      end;

    def module_rows:
      if ((.modules // []) | length) == 0 then
        "<tr><td colspan=\"7\">Aucun résultat module enregistré.</td></tr>"
      else
        ((.modules // []) | map(
          "<tr>"
          + "<td><code>" + ((.id // "") | h) + "</code></td>"
          + "<td>" + ((.name // "") | h) + "</td>"
          + "<td><span class=\"badge " + status_class(.status // "unknown") + "\">"
          + status_label(.status // "unknown") + "</span></td>"
          + "<td>" + ((.rc // "") | h) + "</td>"
          + "<td>" + ((.duration_seconds // 0) | h) + " s</td>"
          + "<td><code class=\"breakable\">" + ((.output_path // "") | h) + "</code></td>"
          + "<td>" + ((.reason // "") | h) + "</td>"
          + "</tr>"
        ) | join("\n"))
      end;

    def unavailable_modules:
      [(.modules // [])[] | select((.status // "unknown") != "success")] as $items
      | if ($items | length) == 0 then
          "<p class=\"positive\">Toutes les vérifications enregistrées sont terminées.</p>"
        else
          "<ul class=\"compact-list\">"
          + ($items | map(
              "<li><strong>" + ((.name // .id // "Module") | h) + " :</strong> "
              + status_label(.status // "unknown")
              + (
                  if ((.reason // "") | length) > 0 then
                    " — " + (.reason | h)
                  else
                    ""
                  end
                )
              + "</li>"
            ) | join(""))
          + "</ul>"
        end;

    def executive_conclusion:
      if (.summary.status // "unknown") == "failed" then
        "L’audit est incomplet : au moins une vérification a échoué. Les constats restent utiles, mais la couverture doit être complétée."
      elif (.summary.status // "unknown") == "partial" then
        "L’audit est partiel. Les priorités ci-dessous doivent être lues avec les limites de couverture indiquées."
      elif ((.findings // []) | length) == 0 then
        "Aucun constat structuré n’a été produit. Cela ne démontre pas l’absence de faille ; seules les vérifications exécutées et leurs limites sont couvertes."
      else
        "Les constats structurés ci-dessous permettent de prioriser les corrections. La gravité, la confiance et la validation restent volontairement séparées."
      end;

    def executive_priorities:
      (indexed_findings[0:3]) as $items
      | if ($items | length) == 0 then
          "<p class=\"empty-state\">Aucune priorité structurée disponible.</p>"
        else
          "<ol class=\"priority-list\">"
          + ($items | map(
              "<li>"
              + "<a href=\"#" + finding_anchor(.) + "\">" + (.value.title | h) + "</a>"
              + "<span>"
              + severity_label(.value.severity // "unknown")
              + " · confiance "
              + (confidence_label(.value.confidence // "low") | ascii_downcase)
              + " · "
              + priority_label(.value.remediation.priority // "none")
              + "</span>"
              + "</li>"
            ) | join(""))
          + "</ol>"
        end;

    def finding_articles:
      (indexed_findings) as $items
      | if ($items | length) == 0 then
          "<div class=\"empty-state\"><strong>Aucun constat structuré.</strong><p>Cette absence ne signifie pas que le périmètre est sécurisé. Consultez la couverture et les modules indisponibles.</p></div>"
        else
          ($items | map(
            . as $entry
            | .value as $finding
            | "<article class=\"finding severity-" + ($finding.severity // "unknown")
            + "\" id=\"" + finding_anchor($entry) + "\">"
            + "<div class=\"finding-heading\">"
            + "<div><div class=\"eyebrow\">" + (type_label($finding.type // "informational") | h)
            + " · <code>" + (($finding.id // "") | h) + "</code></div>"
            + "<h3>" + (($finding.title // "Constat sans titre") | h) + "</h3></div>"
            + "<div class=\"badge-row\">"
            + "<span class=\"badge severity-" + ($finding.severity // "unknown") + "\">Gravité "
            + severity_label($finding.severity // "unknown") + "</span>"
            + "<span class=\"badge confidence\">Confiance "
            + confidence_label($finding.confidence // "low") + "</span>"
            + "<span class=\"badge validation\">"
            + validation_label($finding.validation_status // "unknown") + "</span>"
            + score_badge($finding.scoring // {status: "unscored"})
            + "</div></div>"
            + "<div class=\"finding-context grid two\">"
            + "<div class=\"card\"><div class=\"label\">Actif</div><div class=\"value-small\">"
            + (($finding.asset.id // "") | h) + "</div>"
            + (
                if (($finding.asset.address // "") | length) > 0 then
                  "<div><code>" + ($finding.asset.address | h) + "</code></div>"
                else
                  ""
                end
              )
            + (
                if (($finding.asset.hostname // "") | length) > 0 then
                  "<div>" + ($finding.asset.hostname | h) + "</div>"
                else
                  ""
                end
              )
            + "</div>"
            + "<div class=\"card\"><div class=\"label\">Service et périmètre</div><div class=\"value-small\">"
            + (service_text($finding.service) | h) + "</div><div><code>"
            + (($finding.scope.target // "") | h) + "</code> · "
            + (
                if ($finding.scope.relation // "direct") == "direct" then
                  "cible directe"
                else
                  "élément dérivé"
                end
              )
            + "</div></div></div>"
            + "<div class=\"narrative grid two\">"
            + "<div><h4>Observation</h4><p>" + (($finding.observation // "") | h) + "</p></div>"
            + "<div><h4>Impact possible</h4><p>" + (($finding.impact // "") | h) + "</p></div>"
            + "</div>"
            + "<details open><summary>Notation et provenance</summary><div class=\"details-body\">"
            + (
                if ($finding.scoring.status // "unscored") == "scored" then
                  "<p><strong>Score :</strong> "
                  + (($finding.scoring.score // "") | h)
                  + "/"
                  + (($finding.scoring.scale // "") | h)
                  + " · <strong>Méthode :</strong> "
                  + (($finding.scoring.method // "") | h)
                  + " "
                  + (($finding.scoring.method_version // "") | h)
                  + "</p>"
                  + (
                      if (($finding.scoring.vector // "") | length) > 0 then
                        "<p><strong>Vecteur :</strong> <code class=\"breakable\">"
                        + ($finding.scoring.vector | h) + "</code></p>"
                      else
                        ""
                      end
                    )
                  + "<p><strong>Justification :</strong> "
                  + (($finding.scoring.rationale // "") | h)
                  + "</p><p><strong>Source du score :</strong> "
                  + (($finding.scoring.source // "") | h) + "</p>"
                else
                  "<p><strong>Non noté :</strong> "
                  + (($finding.scoring.rationale // "Données insuffisantes.") | h)
                  + "</p>"
                end
              )
            + "<p><strong>Module :</strong> <code>" + (($finding.source.module // "") | h) + "</code>"
            + (
                if (($finding.source.tool // "") | length) > 0 then
                  " · <strong>Outil :</strong> " + ($finding.source.tool | h)
                else
                  ""
                end
              )
            + (
                if (($finding.source.tool_version // "") | length) > 0 then
                  " " + ($finding.source.tool_version | h)
                else
                  ""
                end
              )
            + "</p><p><strong>Collecté :</strong> " + (($finding.source.collected_at // "") | h)
            + " · <strong>Provenance :</strong> " + (($finding.source.provenance // "") | h) + "</p>"
            + "</div></details>"
            + "<details open><summary>Preuves référencées</summary><div class=\"details-body\">"
            + "<ul class=\"evidence-list\">"
            + (($finding.evidence // []) | map(
                "<li><strong>" + ((.id // "") | h) + "</strong>"
                + "<span>" + ((.kind // "") | h) + " · source <code>"
                + ((.source // "") | h) + "</code> · "
                + ((.captured_at // "") | h) + "</span>"
                + "<code class=\"breakable\">" + ((.path // "") | h) + "</code>"
                + (
                    if ((.sha256 // "") | length) > 0 then
                      "<span>SHA-256 <code class=\"breakable\">" + (.sha256 | h) + "</code></span>"
                    else
                      ""
                    end
                  )
                + "</li>"
              ) | join(""))
            + "</ul></div></details>"
            + "<section class=\"remediation\"><h4>Remédiation</h4>"
            + "<div class=\"badge-row\"><span class=\"badge action\">"
            + priority_label($finding.remediation.priority // "none")
            + "</span><span class=\"badge effort\">Effort "
            + effort_label($finding.remediation.effort // "unknown") + "</span></div>"
            + "<p class=\"action-text\">" + (($finding.remediation.action // "") | h) + "</p>"
            + "<p><strong>Pourquoi :</strong> " + (($finding.remediation.rationale // "") | h) + "</p>"
            + (
                if (($finding.remediation.prerequisites // []) | length) > 0 then
                  "<p><strong>Prérequis :</strong></p><ul>"
                  + (($finding.remediation.prerequisites // []) | map("<li>" + h + "</li>") | join(""))
                  + "</ul>"
                else
                  ""
                end
              )
            + "<p><strong>Risque du changement :</strong> "
            + (($finding.remediation.change_risk // "") | h) + "</p>"
            + (
                if (($finding.remediation.compensating_control // "") | length) > 0 then
                  "<p><strong>Mesure compensatoire :</strong> "
                  + ($finding.remediation.compensating_control | h) + "</p>"
                else
                  ""
                end
              )
            + "<div class=\"verification\"><strong>Vérifier la correction</strong><p>"
            + (($finding.remediation.verification // "") | h) + "</p></div>"
            + "</section>"
            + "<div class=\"grid two footnotes\">"
            + "<div><h4>Références</h4>"
            + (
                if (($finding.references // []) | length) == 0 then
                  "<p>Aucune référence externe.</p>"
                else
                  "<ul>" + (($finding.references // []) | map(reference_item) | join("")) + "</ul>"
                end
              )
            + "</div><div><h4>Limites et faux positifs possibles</h4>"
            + (
                if (($finding.limitations // []) | length) == 0 then
                  "<p>Aucune limite documentée.</p>"
                else
                  "<ul>" + (($finding.limitations // []) | map("<li>" + h + "</li>") | join("")) + "</ul>"
                end
              )
            + "</div></div></article>"
          ) | join("\n"))
        end;

    def action_group($priority; $title; $description):
      [indexed_findings[] | select((.value.remediation.priority // "none") == $priority)] as $items
      | "<div class=\"action-group\"><h3>" + ($title | h) + "</h3><p>" + ($description | h) + "</p>"
      + (
          if ($items | length) == 0 then
            "<p class=\"empty-state compact\">Aucune action dans cette catégorie.</p>"
          else
            "<ol>" + ($items | map(
              "<li><a href=\"#" + finding_anchor(.) + "\">" + (.value.title | h) + "</a>"
              + "<span>" + (.value.remediation.action | h) + " · effort "
              + (effort_label(.value.remediation.effort // "unknown") | ascii_downcase)
              + "</span></li>"
            ) | join("")) + "</ol>"
          end
        )
      + "</div>";

    def evidence_rows:
      [indexed_findings[] as $entry
        | $entry.value.evidence[]?
        | {
            anchor: finding_anchor($entry),
            finding: $entry.value.title,
            id: .id,
            source: .source,
            path: .path,
            captured_at: .captured_at
          }
      ] as $rows
      | if ($rows | length) == 0 then
          "<tr><td colspan=\"5\">Aucune preuve structurée référencée.</td></tr>"
        else
          ($rows | map(
            "<tr><td><a href=\"#" + .anchor + "\">" + (.finding | h) + "</a></td>"
            + "<td><code>" + (.id | h) + "</code></td>"
            + "<td><code>" + (.source | h) + "</code></td>"
            + "<td><code class=\"breakable\">" + (.path | h) + "</code></td>"
            + "<td>" + (.captured_at | h) + "</td></tr>"
          ) | join(""))
        end;

    (if $report_mode == "shareable" then anonymize_manifest else . end) as $report
    | $report
    | (indexed_findings) as $indexed
    | ((.summary.findings.by_severity.critical // 0) + (.summary.findings.by_severity.high // 0)) as $urgent_count
    | [
      "<!doctype html>",
      "<html lang=\"fr\">",
      "<head>",
      "  <meta charset=\"utf-8\">",
      "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
      "  <meta name=\"robots\" content=\"noindex,nofollow\">",
      "  <title>Rapport Audit Suite — " + (.run_id | h) + "</title>",
      "  <style>",
      "    :root { color-scheme: light dark; --bg:#f3f6fb; --surface:#ffffff; --surface-soft:#f8fafc; --text:#172033; --muted:#526079; --line:#d8e0ec; --brand:#173b66; --brand-soft:#e8f0fb; --focus:#ffb000; --positive:#166534; --warning:#9a4d00; --danger:#9b1c1c; --critical:#7f1d1d; --high:#9a3412; --medium:#92400e; --low:#1d4ed8; --info:#475569; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif; }",
      "    * { box-sizing: border-box; }",
      "    html { scroll-behavior: smooth; }",
      "    body { margin:0; background:var(--bg); color:var(--text); line-height:1.58; }",
      "    a { color:#0b57a4; text-underline-offset:3px; }",
      "    a:hover { text-decoration-thickness:2px; }",
      "    a:focus-visible, summary:focus-visible { outline:3px solid var(--focus); outline-offset:3px; border-radius:3px; }",
      "    .skip-link { position:absolute; left:12px; top:-80px; background:#fff; color:#000; padding:10px 14px; z-index:100; }",
      "    .skip-link:focus { top:12px; }",
      "    header { background:linear-gradient(135deg,#102a49,#1f4f83); color:#fff; padding:34px max(24px,calc((100vw - 1180px)/2)); }",
      "    header h1 { margin:.25rem 0 .35rem; font-size:clamp(1.8rem,4vw,3rem); line-height:1.1; }",
      "    header p { margin:.2rem 0; max-width:760px; color:#e5eef9; }",
      "    .classification { display:inline-flex; gap:8px; align-items:center; padding:5px 10px; border:1px solid rgba(255,255,255,.5); border-radius:999px; font-size:.82rem; font-weight:700; }",
      "    .shareable { background:#dbeafe; color:#163a64; border-color:#93c5fd; }",
      "    nav { background:var(--surface); border-bottom:1px solid var(--line); position:sticky; top:0; z-index:20; }",
      "    nav ul { max-width:1180px; margin:0 auto; padding:10px 24px; display:flex; gap:8px 18px; overflow-x:auto; list-style:none; }",
      "    nav a { white-space:nowrap; font-weight:700; font-size:.92rem; }",
      "    main { max-width:1180px; margin:0 auto; padding:28px 24px 60px; }",
      "    section.report-section { background:var(--surface); border:1px solid var(--line); border-radius:16px; padding:clamp(18px,3vw,30px); margin-bottom:24px; box-shadow:0 8px 28px rgba(27,45,75,.06); }",
      "    h2 { margin:0 0 18px; font-size:clamp(1.35rem,3vw,2rem); line-height:1.2; }",
      "    h3 { margin:.2rem 0 .4rem; line-height:1.25; }",
      "    h4 { margin:1rem 0 .35rem; }",
      "    p { margin:.45rem 0 .85rem; }",
      "    .eyebrow, .label { color:var(--muted); font-size:.78rem; font-weight:800; letter-spacing:.055em; text-transform:uppercase; }",
      "    .grid { display:grid; gap:14px; }",
      "    .grid.summary-grid { grid-template-columns:repeat(auto-fit,minmax(165px,1fr)); }",
      "    .grid.two { grid-template-columns:repeat(2,minmax(0,1fr)); }",
      "    .card { border:1px solid var(--line); border-radius:12px; padding:15px; background:var(--surface-soft); min-width:0; }",
      "    .value { font-size:1.7rem; font-weight:850; margin-top:3px; }",
      "    .value-small { font-size:1.08rem; font-weight:800; margin:.15rem 0; }",
      "    .badge-row { display:flex; flex-wrap:wrap; gap:7px; align-items:center; }",
      "    .badge { display:inline-block; border-radius:999px; padding:4px 10px; font-size:.78rem; font-weight:800; border:1px solid transparent; }",
      "    .status-success { background:#dcfce7; color:#14532d; border-color:#86efac; }",
      "    .status-partial, .status-skipped { background:#fff7d6; color:#713f12; border-color:#facc15; }",
      "    .status-failed { background:#fee2e2; color:#7f1d1d; border-color:#fca5a5; }",
      "    .status-unknown { background:#e2e8f0; color:#334155; border-color:#cbd5e1; }",
      "    .severity-critical { background:#7f1d1d; color:#fff; }",
      "    .severity-high { background:#ffedd5; color:#7c2d12; border-color:#fdba74; }",
      "    .severity-medium { background:#fef3c7; color:#713f12; border-color:#fcd34d; }",
      "    .severity-low { background:#dbeafe; color:#1e3a8a; border-color:#93c5fd; }",
      "    .severity-informational, .severity-unknown { background:#e2e8f0; color:#334155; border-color:#cbd5e1; }",
      "    .confidence, .validation, .effort { background:#eef2ff; color:#3730a3; border-color:#c7d2fe; }",
      "    .score-scored { background:#d1fae5; color:#065f46; border-color:#6ee7b7; }",
      "    .score-unscored { background:#f1f5f9; color:#475569; border-color:#cbd5e1; }",
      "    .action { background:#e0f2fe; color:#075985; border-color:#7dd3fc; }",
      "    .notice { border-left:5px solid #f59e0b; background:#fffbeb; color:#4c2c00; padding:14px 16px; border-radius:8px; margin:14px 0; }",
      "    .privacy { border-left-color:#c2410c; background:#fff1e8; }",
      "    .positive { color:var(--positive); font-weight:700; }",
      "    .priority-list, .action-group ol { padding-left:1.25rem; }",
      "    .priority-list li, .action-group li { margin:.65rem 0; padding-left:.25rem; }",
      "    .priority-list span, .action-group li span { display:block; color:var(--muted); font-size:.9rem; }",
      "    .finding { border:1px solid var(--line); border-left:7px solid var(--info); border-radius:14px; padding:20px; margin:20px 0; background:var(--surface); scroll-margin-top:70px; break-inside:avoid; }",
      "    .finding.severity-critical { border-left-color:var(--critical); color:var(--text); }",
      "    .finding.severity-high { border-left-color:var(--high); color:var(--text); }",
      "    .finding.severity-medium { border-left-color:var(--medium); color:var(--text); }",
      "    .finding.severity-low { border-left-color:var(--low); color:var(--text); }",
      "    .finding-heading { display:flex; justify-content:space-between; align-items:flex-start; gap:18px; margin-bottom:14px; }",
      "    .finding-heading .badge-row { justify-content:flex-end; max-width:48%; }",
      "    .narrative { margin:16px 0 8px; }",
      "    details { border:1px solid var(--line); border-radius:10px; margin:12px 0; background:var(--surface-soft); }",
      "    summary { cursor:pointer; font-weight:800; padding:12px 14px; }",
      "    .details-body { padding:0 14px 14px; }",
      "    .evidence-list { list-style:none; padding:0; }",
      "    .evidence-list li { display:grid; gap:3px; border-top:1px solid var(--line); padding:10px 0; }",
      "    .evidence-list li:first-child { border-top:0; }",
      "    .evidence-list span { color:var(--muted); font-size:.9rem; }",
      "    .remediation { margin-top:16px; padding:16px; border:1px solid #b7d7c2; border-radius:12px; background:#f0fdf4; color:#17351f; }",
      "    .action-text { font-size:1.08rem; font-weight:750; }",
      "    .verification { border-left:4px solid #15803d; padding:8px 12px; margin-top:12px; background:#dcfce7; color:#14532d; }",
      "    .footnotes { margin-top:14px; font-size:.94rem; }",
      "    .action-plan { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:14px; }",
      "    .action-group { border:1px solid var(--line); border-radius:12px; padding:15px; background:var(--surface-soft); }",
      "    .empty-state { padding:14px; border:1px dashed #94a3b8; border-radius:10px; color:var(--muted); background:var(--surface-soft); }",
      "    .empty-state.compact { padding:9px 11px; }",
      "    .table-wrap { overflow-x:auto; margin:12px 0; }",
      "    table { width:100%; border-collapse:collapse; font-size:.9rem; }",
      "    caption { text-align:left; font-weight:800; padding:0 0 8px; }",
      "    th, td { border-bottom:1px solid var(--line); padding:9px; text-align:left; vertical-align:top; }",
      "    th { background:var(--surface-soft); }",
      "    code { font-family:\"SFMono-Regular\",Consolas,\"Liberation Mono\",monospace; font-size:.88em; }",
      "    .breakable { overflow-wrap:anywhere; word-break:break-word; }",
      "    .compact-list { margin:.5rem 0; }",
      "    footer { max-width:1180px; margin:0 auto; padding:0 24px 40px; color:var(--muted); font-size:.88rem; }",
      "    @media (prefers-color-scheme: dark) { :root { --bg:#0f172a; --surface:#172033; --surface-soft:#1e293b; --text:#eef4ff; --muted:#b9c5d8; --line:#3a465c; --brand-soft:#1e3a5f; } a { color:#8ec5ff; } .notice { background:#3b2d0a; color:#ffedb5; } .privacy { background:#402116; color:#ffd8c3; } .remediation { background:#153522; color:#dcfce7; border-color:#2f6f48; } .verification { background:#17492b; color:#dcfce7; } }",
      "    @media (max-width:760px) { nav { position:static; } .grid.two, .action-plan { grid-template-columns:1fr; } .finding-heading { flex-direction:column; } .finding-heading .badge-row { justify-content:flex-start; max-width:none; } main { padding:18px 12px 44px; } header { padding:28px 18px; } section.report-section { border-radius:12px; padding:18px 14px; } .finding { padding:15px 12px; } }",
      "    @media print { @page { size:A4; margin:14mm; } :root { color-scheme:light; --bg:#fff; --surface:#fff; --surface-soft:#fff; --text:#111827; --muted:#475569; --line:#cbd5e1; } body { background:#fff; font-size:10.5pt; } header { background:#fff; color:#111827; border-bottom:2px solid #173b66; padding:0 0 10mm; } header p { color:#334155; } nav, .skip-link { display:none; } main { max-width:none; padding:8mm 0 0; } section.report-section { box-shadow:none; border:0; border-radius:0; padding:0; margin:0 0 10mm; break-before:auto; } section.report-section + section.report-section { break-before:page; } .finding { box-shadow:none; break-inside:avoid; } details { break-inside:avoid; } details > summary { list-style:none; } a { color:#111827; text-decoration:none; } a[href^=\"http\"]::after { content:\" (\" attr(href) \")\"; font-size:8pt; overflow-wrap:anywhere; } .table-wrap { overflow:visible; } footer { padding:0; } }",
      "  </style>",
      "</head>",
      "<body>",
      "<a class=\"skip-link\" href=\"#contenu\">Aller au contenu</a>",
      "<header>",
      "  <span class=\"classification " + (if $report_mode == "shareable" then "shareable" else "" end) + "\">"
      + (if $report_mode == "shareable" then "Version partageable · identifiants masqués" else "Rapport privé · données sensibles" end)
      + "</span>",
      "  <h1>Rapport Audit Suite</h1>",
      "  <p>Audit <code>" + (.run_id | h) + "</code> · " + ((.created_at // "date inconnue") | h) + "</p>",
      "  <p>Synthèse décisionnelle, constats sourcés et plan de remédiation.</p>",
      "</header>",
      "<nav aria-label=\"Sommaire du rapport\"><ul>",
      "  <li><a href=\"#synthese\">Synthèse</a></li>",
      "  <li><a href=\"#couverture\">Couverture</a></li>",
      "  <li><a href=\"#constats\">Constats</a></li>",
      "  <li><a href=\"#plan-action\">Plan d’action</a></li>",
      "  <li><a href=\"#annexe\">Annexe technique</a></li>",
      "</ul></nav>",
      "<main id=\"contenu\">",
      "<section class=\"report-section\" id=\"synthese\" aria-labelledby=\"titre-synthese\">",
      "  <div class=\"eyebrow\">Lecture décisionnelle</div>",
      "  <h2 id=\"titre-synthese\">Résumé exécutif</h2>",
      "  <div class=\"grid summary-grid\">",
      "    <div class=\"card\"><div class=\"label\">Complétude</div><div class=\"value\"><span class=\"badge " + status_class(.summary.status // "unknown") + "\">" + status_label(.summary.status // "unknown") + "</span></div></div>",
      "    <div class=\"card\"><div class=\"label\">Constats</div><div class=\"value\">" + ((.summary.findings.total_count // 0) | h) + "</div></div>",
      "    <div class=\"card\"><div class=\"label\">Critiques ou élevés</div><div class=\"value\">" + ($urgent_count | h) + "</div></div>",
      "    <div class=\"card\"><div class=\"label\">Non notés</div><div class=\"value\">" + ((.summary.findings.unscored_count // 0) | h) + "</div></div>",
      "    <div class=\"card\"><div class=\"label\">Modules partiels</div><div class=\"value\">" + ((.summary.partial_count // 0) | h) + "</div></div>",
      "    <div class=\"card\"><div class=\"label\">Modules échoués</div><div class=\"value\">" + ((.summary.failed_count // 0) | h) + "</div></div>",
      "  </div>",
      "  <div class=\"notice\"><strong>Conclusion prudente :</strong> " + (executive_conclusion | h) + "</div>",
      "  <h3>Priorités</h3>",
      executive_priorities,
      "  <p><strong>Aucune note globale :</strong> le rapport utilise des niveaux, des comptes et des priorités expliquées. Il ne moyenne pas les scores.</p>",
      "</section>",
      "<section class=\"report-section\" id=\"couverture\" aria-labelledby=\"titre-couverture\">",
      "  <div class=\"eyebrow\">Périmètre et limites</div>",
      "  <h2 id=\"titre-couverture\">Couverture de l’audit</h2>",
      "  <div class=\"grid two\">",
      "    <div class=\"card\"><div class=\"label\">Périmètre</div><div class=\"value-small\"><code class=\"breakable\">" + (((.targets // []) | join(", ")) | h) + "</code></div></div>",
      "    <div class=\"card\"><div class=\"label\">Profil</div><div class=\"value-small\">" + ((.profile // "inconnu") | h) + "</div></div>",
      "    <div class=\"card\"><div class=\"label\">Version</div><div class=\"value-small\">" + ((.version // "inconnue") | h) + "</div><div><code class=\"breakable\">" + ((.commit // "inconnu") | h) + "</code></div></div>",
      "    <div class=\"card\"><div class=\"label\">Durée cumulée</div><div class=\"value-small\">" + ((.summary.total_duration_seconds // 0) | h) + " s</div></div>",
      "  </div>",
      "  <h3>Vérifications indisponibles ou incomplètes</h3>",
      unavailable_modules,
      "  <div class=\"notice privacy\"><strong>Données sensibles :</strong> adresses, hôtes, services, vulnérabilités et chemins peuvent révéler l’environnement. Relire le rapport avant tout partage.</div>",
      (
        if $report_mode == "shareable" then
          "  <div class=\"notice\"><strong>Anonymisation appliquée :</strong> les cibles, actifs, chemins et identifiants directs sont masqués. Les textes libres, titres, impacts et recommandations restent à relire manuellement.</div>"
        else
          "  <p><a href=\"#confidentialite\">Voir la checklist avant partage</a>.</p>"
        end
      ),
      "</section>",
      "<section class=\"report-section\" id=\"constats\" aria-labelledby=\"titre-constats\">",
      "  <div class=\"eyebrow\">Lecture technique guidée</div>",
      "  <h2 id=\"titre-constats\">Constats priorisés</h2>",
      "  <p>Ordre : priorité de remédiation, gravité, confiance, puis identifiant stable.</p>",
      finding_articles,
      "</section>",
      "<section class=\"report-section\" id=\"plan-action\" aria-labelledby=\"titre-plan\">",
      "  <div class=\"eyebrow\">Remédiation</div>",
      "  <h2 id=\"titre-plan\">Plan d’action</h2>",
      "  <div class=\"action-plan\">",
      action_group("immediate"; "Actions immédiates"; "Réduire rapidement un risque prioritaire après validation du changement."),
      action_group("short_term"; "Court terme"; "Planifier les corrections importantes avec leurs prérequis."),
      action_group("planned"; "Améliorations planifiées"; "Traiter les évolutions de fond dans un cycle maîtrisé."),
      action_group("monitor"; "Surveillance"; "Confirmer l’évolution et réévaluer lors d’un prochain audit."),
      "  </div>",
      "  <div class=\"notice\"><strong>Suivi :</strong> le statut de traitement et la comparaison détaillée avant/après seront reliés à l’historique dans l’évolution dédiée des vues résultats.</div>",
      "</section>",
      "<section class=\"report-section\" id=\"annexe\" aria-labelledby=\"titre-annexe\">",
      "  <div class=\"eyebrow\">Traçabilité</div>",
      "  <h2 id=\"titre-annexe\">Annexe technique</h2>",
      "  <details open><summary>Modules et états d’exécution</summary><div class=\"details-body table-wrap\">",
      "    <table><caption>Résultats des modules</caption><thead><tr><th scope=\"col\">ID</th><th scope=\"col\">Nom</th><th scope=\"col\">État</th><th scope=\"col\">RC</th><th scope=\"col\">Durée</th><th scope=\"col\">Sortie</th><th scope=\"col\">Raison</th></tr></thead><tbody>",
      module_rows,
      "    </tbody></table>",
      "  </div></details>",
      "  <details open><summary>Index des preuves</summary><div class=\"details-body table-wrap\">",
      "    <table><caption>Preuves référencées par les constats</caption><thead><tr><th scope=\"col\">Constat</th><th scope=\"col\">ID preuve</th><th scope=\"col\">Source</th><th scope=\"col\">Chemin</th><th scope=\"col\">Capture</th></tr></thead><tbody>",
      evidence_rows,
      "    </tbody></table>",
      "  </div></details>",
      "  <details open><summary>Options et chemins</summary><div class=\"details-body table-wrap\">",
      "    <table><caption>Configuration enregistrée</caption><tbody>",
      "      <tr><th scope=\"row\">IP publiques autorisées</th><td>" + yesno(.options.allow_public // false) + "</td></tr>",
      "      <tr><th scope=\"row\">Sans UDP</th><td>" + yesno(.options.no_udp // false) + "</td></tr>",
      "      <tr><th scope=\"row\">Sans Zeek</th><td>" + yesno(.options.no_zeek // false) + "</td></tr>",
      "      <tr><th scope=\"row\">Sans Suricata</th><td>" + yesno(.options.no_suricata // false) + "</td></tr>",
      "      <tr><th scope=\"row\">Manifest</th><td><code class=\"breakable\">" + ((.paths.manifest // "") | h) + "</code></td></tr>",
      "      <tr><th scope=\"row\">Sortie</th><td><code class=\"breakable\">" + ((.paths.output // "") | h) + "</code></td></tr>",
      "      <tr><th scope=\"row\">Logs</th><td><code class=\"breakable\">" + ((.paths.logs // "") | h) + "</code></td></tr>",
      "      <tr><th scope=\"row\">Schéma manifest</th><td><code>" + ((.schema_version // "") | h) + "</code></td></tr>",
      "      <tr><th scope=\"row\">Schéma constats</th><td><code>" + ((.findings_schema_version // "") | h) + "</code></td></tr>",
      "    </tbody></table>",
      "  </div></details>",
      "  <div id=\"confidentialite\"><h3>Checklist avant partage</h3><ul>",
      "    <li>Vérifier les adresses, noms d’hôtes, services et versions.</li>",
      "    <li>Vérifier les preuves, chemins locaux, noms d’utilisateur et extraits de logs.</li>",
      "    <li>Confirmer que les constats et impacts peuvent être communiqués au destinataire.</li>",
      "    <li>Conserver le rapport privé comme source et partager uniquement la copie revue.</li>",
      "  </ul></div>",
      "</section>",
      "</main>",
      "<footer>",
      "  <p>Généré localement par Audit Suite. Ce rapport décrit un périmètre et des vérifications donnés ; il ne constitue pas une garantie d’absence de vulnérabilité.</p>",
      "</footer>",
      "</body>",
      "</html>"
    ]
    | .[]
JQ
  then
    rm -f -- "$normalized_path" "$tmp_path" "$renderer_path"
    return 1
  fi

  if ! jq -r --arg report_mode "$mode" -f "$renderer_path" "$normalized_path" > "$tmp_path"; then
    rm -f -- "$normalized_path" "$tmp_path" "$renderer_path"
    return 1
  fi

  rm -f -- "$normalized_path" "$renderer_path"
  if ! mv "$tmp_path" "$output_path"; then
    rm -f -- "$tmp_path"
    return 1
  fi
  printf '%s\n' "$output_path"
}
