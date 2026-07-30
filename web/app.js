"use strict";

const text = (value, fallback = "-") =>
  value === undefined || value === null || value === "" ? fallback : String(value);

const arrayOf = (value) => (Array.isArray(value) ? value : []);

function clearElement(element) {
  element.replaceChildren();
  return element;
}

function appendTextElement(parent, tagName, value, options = {}) {
  const element = document.createElement(tagName);
  element.textContent = text(value);
  if (options.className) {
    element.className = options.className;
  }
  if (options.colSpan) {
    element.colSpan = options.colSpan;
  }
  parent.appendChild(element);
  return element;
}

function appendTableRow(tbody, values) {
  const row = document.createElement("tr");
  for (const value of values) {
    appendTextElement(row, "td", value);
  }
  tbody.appendChild(row);
  return row;
}

function renderMessageRow(tbody, message, options = {}) {
  clearElement(tbody);
  const row = document.createElement("tr");
  appendTextElement(row, "td", message, {
    className: options.className || "",
    colSpan: options.colSpan || 3,
  });
  tbody.appendChild(row);
}

function renderMessageBlock(container, message, className = "") {
  clearElement(container);
  appendTextElement(container, "p", message, { className });
}

function appendStatusLine(container, label, value) {
  container.appendChild(document.createElement("br"));
  container.appendChild(document.createTextNode(`${label}: ${text(value)}`));
}

const runIdPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;
const reportKinds = new Set(["private", "shareable", "technical"]);
const resultsState = {
  selectedRunId: "",
  requestToken: 0,
};

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}

function numberOf(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function countLabel(value, singular, plural = `${singular}s`) {
  const count = numberOf(value);
  return `${count} ${count === 1 ? singular : plural}`;
}

function profileLabel(value) {
  const labels = {
    fast: "rapide",
    full: "complet",
    stealth: "discret",
  };
  return Object.prototype.hasOwnProperty.call(labels, value)
    ? labels[value]
    : text(value);
}

function severityLabel(value) {
  const labels = {
    informational: "Information",
    low: "Faible",
    medium: "Moyenne",
    high: "Élevée",
    critical: "Critique",
    unknown: "Inconnue",
  };
  return Object.prototype.hasOwnProperty.call(labels, value)
    ? labels[value]
    : text(value, "Inconnue");
}

function statusPresentation(value) {
  const normalized = typeof value === "string" ? value.toLowerCase() : "unknown";
  const known = {
    success: { label: "Réussi", tone: "success" },
    partial: { label: "Partiel", tone: "warning" },
    failed: { label: "Échec", tone: "danger" },
    skipped: { label: "Ignoré", tone: "neutral" },
    empty: { label: "Sans résultat", tone: "neutral" },
    observed: { label: "Observé", tone: "info" },
    potential: { label: "À confirmer", tone: "warning" },
    confirmed: { label: "Confirmé", tone: "danger" },
  };
  return Object.prototype.hasOwnProperty.call(known, normalized)
    ? known[normalized]
    : { label: text(value, "Inconnu"), tone: "neutral" };
}

function formatTimestamp(value) {
  if (typeof value !== "string" || !value) {
    return "Date indisponible";
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return new Intl.DateTimeFormat("fr-FR", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(parsed);
}

function safeLocalReportUrl(value) {
  if (typeof value !== "string" || !value) {
    return "";
  }
  try {
    const base = "http://audit-suite.local";
    const parsed = new URL(value, base);
    const runId = parsed.searchParams.get("run_id") || "";
    const kind = parsed.searchParams.get("kind") || "";
    if (
      parsed.origin !== base ||
      parsed.pathname !== "/api/report" ||
      parsed.hash ||
      !runIdPattern.test(runId) ||
      !reportKinds.has(kind)
    ) {
      return "";
    }
    return `${parsed.pathname}?${new URLSearchParams({ run_id: runId, kind })}`;
  } catch (_error) {
    return "";
  }
}

function sensitivePreviewItems(review) {
  const payload = asObject(review);
  const groups = [
    ["Cibles", payload.targets],
    ["Adresses d’actifs", payload.asset_addresses],
    ["Noms d’hôtes", payload.hostnames],
    ["Chemins de preuve", payload.evidence_paths],
  ];
  return groups.map(([label, source]) => {
    const group = asObject(source);
    return {
      label,
      count: numberOf(group.count),
      values: arrayOf(group.values).map((value) => text(value)),
      truncated: group.truncated === true,
    };
  });
}

function appendStatusBadge(parent, status) {
  const presentation = statusPresentation(status);
  return appendTextElement(parent, "span", presentation.label, {
    className: `status-badge status-${presentation.tone}`,
  });
}

function appendMetric(parent, label, value) {
  const item = document.createElement("div");
  item.className = "metric";
  appendTextElement(item, "dt", label, { className: "metric-label" });
  appendTextElement(item, "dd", value, { className: "metric-value" });
  parent.appendChild(item);
  return item;
}

function renderNotice(message, tone = "info") {
  const notice = clearElement(document.getElementById("results-alert"));
  notice.className = `notice notice-${tone}`;
  appendTextElement(notice, "p", message);
}

function hideNotice() {
  const notice = clearElement(document.getElementById("results-alert"));
  notice.className = "notice is-hidden";
}

async function loadJson(path) {
  const response = await fetch(path, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

function selectedCategories() {
  const mode = document.getElementById("plan-categories-mode").value;
  if (mode === "all") {
    return "all";
  }

  const checked = Array.from(
    document.querySelectorAll("input[name='plan-module']:checked"),
  );
  return checked.map((item) => item.value).join(",");
}

async function loadPlan(event) {
  event.preventDefault();
  const output = document.getElementById("plan-json");
  const params = new URLSearchParams();
  params.set("targets", document.getElementById("plan-targets").value);
  params.set("profile", document.getElementById("plan-profile").value);
  params.set("categories", selectedCategories() || "all");
  params.set(
    "run_id",
    document.getElementById("plan-run-id").value || "WEB_PLAN_PREVIEW",
  );
  if (document.getElementById("plan-no-zeek").checked) {
    params.set("no_zeek", "1");
  }
  if (document.getElementById("plan-no-suricata").checked) {
    params.set("no_suricata", "1");
  }

  try {
    const response = await fetch(`/api/plan?${params.toString()}`, {
      cache: "no-store",
    });
    const payload = await response.json();
    output.textContent = JSON.stringify(payload, null, 2);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
  } catch (error) {
    output.textContent = `Erreur de plan: ${text(error?.message)}`;
  }
}

function selectableModules(payload) {
  return arrayOf(payload?.modules).filter(
    (module) =>
      module &&
      module.selectable !== false &&
      typeof module.name === "string" &&
      module.name.trim() !== "",
  );
}

function renderModuleSelector(modulesPayload) {
  const selector = clearElement(
    document.getElementById("plan-module-selector"),
  );

  for (const module of selectableModules(modulesPayload)) {
    const label = document.createElement("label");
    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.name = "plan-module";
    checkbox.value = module.name;
    checkbox.checked = true;
    label.appendChild(checkbox);

    const displayName = text(module.display_name || module.name);
    const maturity =
      typeof module.maturity === "string" && module.maturity
        ? ` — ${module.maturity}`
        : "";
    label.appendChild(document.createTextNode(`${displayName}${maturity}`));
    selector.appendChild(label);
  }

  if (!selector.children.length) {
    renderMessageBlock(
      selector,
      "Aucun module sélectionnable.",
      "muted",
    );
  }
}

function renderRoutes(routesPayload) {
  const tbody = clearElement(document.getElementById("routes-table"));
  for (const route of arrayOf(routesPayload?.routes)) {
    appendTableRow(tbody, [route?.method, route?.path, route?.type]);
  }

  if (!tbody.children.length) {
    renderMessageRow(tbody, "Aucune route détectée.", {
      className: "muted",
    });
  }
}

function renderStatus(status) {
  const container = clearElement(document.getElementById("status-summary"));
  appendTextElement(container, "span", "Service prêt", {
    className: "status-ok",
  });
  appendStatusLine(
    container,
    "Dossier modules",
    status?.checks?.modules_dir_exists ? "disponible" : "introuvable",
  );
  appendStatusLine(
    container,
    "Index historique",
    status?.checks?.history_index_exists ? "disponible" : "absent",
  );
}

function renderHistoryList(history, latest) {
  const container = clearElement(document.getElementById("history-list"));
  const runs = arrayOf(history?.runs)
    .filter(
      (run) =>
        typeof run?.run_id === "string" && runIdPattern.test(run.run_id),
    )
    .slice()
    .reverse();
  if (!runs.length) {
    appendTextElement(container, "p", "Aucun audit enregistré pour le moment.", {
      className: "empty-state",
    });
    resultsState.selectedRunId = "";
    const detail = clearElement(document.getElementById("run-detail"));
    appendTextElement(detail, "h3", "Historique vide");
    appendTextElement(
      detail,
      "p",
      "L’interface reste disponible. Lancez un audit autorisé depuis le terminal pour faire apparaître ses résultats ici.",
      { className: "muted" },
    );
    return "";
  }

  const availableIds = new Set(
    runs
      .map((run) => (typeof run?.run_id === "string" ? run.run_id : ""))
      .filter((runId) => runIdPattern.test(runId)),
  );
  const latestId =
    typeof latest?.run_id === "string" && availableIds.has(latest.run_id)
      ? latest.run_id
      : "";
  if (!availableIds.has(resultsState.selectedRunId)) {
    resultsState.selectedRunId = latestId || availableIds.values().next().value || "";
  }

  for (const run of runs) {
    const runId = run.run_id;
    const button = document.createElement("button");
    button.type = "button";
    button.className =
      runId === resultsState.selectedRunId
        ? "history-item is-selected"
        : "history-item";
    button.setAttribute(
      "aria-current",
      runId === resultsState.selectedRunId ? "true" : "false",
    );
    button.addEventListener("click", () => {
      resultsState.selectedRunId = runId;
      renderHistoryList(history, latest);
      loadRunDetail(runId);
    });

    const heading = document.createElement("span");
    heading.className = "history-item-heading";
    appendTextElement(heading, "strong", runId);
    appendStatusBadge(heading, run?.status);
    button.appendChild(heading);
    appendTextElement(
      button,
      "span",
      `${formatTimestamp(run?.created_at)} · profil ${profileLabel(run?.profile)}`,
      { className: "history-item-meta" },
    );
    appendTextElement(
      button,
      "span",
      `${countLabel(run?.finding_count, "constat")} · ${countLabel(run?.failed_count, "échec")} · ${countLabel(run?.partial_count, "résultat partiel", "résultats partiels")}`,
      { className: "history-item-meta" },
    );
    container.appendChild(button);
  }
  return resultsState.selectedRunId;
}

function moduleGuidance(module) {
  if (typeof module?.reason === "string" && module.reason) {
    return module.reason;
  }
  const status = String(module?.status || "");
  if (status === "failed") {
    return "Consulter la sortie conservée du module avant une nouvelle tentative.";
  }
  if (status === "partial") {
    return "Les résultats disponibles restent consultables ; vérifier la limite signalée.";
  }
  if (status === "skipped") {
    return "Module non exécuté dans les conditions de cet audit.";
  }
  return "Aucune action nécessaire.";
}

function renderModuleDetails(parent, modules) {
  appendTextElement(parent, "h4", "État des vérifications");
  const entries = arrayOf(modules);
  if (!entries.length) {
    appendTextElement(
      parent,
      "p",
      "Aucun état de module détaillé n’est disponible pour cet audit.",
      { className: "muted" },
    );
    return;
  }

  const wrapper = document.createElement("div");
  wrapper.className = "table-scroll";
  const table = document.createElement("table");
  const caption = appendTextElement(table, "caption", "Résultats des modules");
  caption.className = "visually-hidden";
  const thead = document.createElement("thead");
  const header = document.createElement("tr");
  for (const label of ["Module", "État", "Durée", "Information utile"]) {
    appendTextElement(header, "th", label);
  }
  thead.appendChild(header);
  table.appendChild(thead);
  const tbody = document.createElement("tbody");
  for (const module of entries) {
    const row = document.createElement("tr");
    appendTextElement(row, "td", module?.name || module?.id);
    const statusCell = document.createElement("td");
    appendStatusBadge(statusCell, module?.status);
    row.appendChild(statusCell);
    appendTextElement(
      row,
      "td",
      `${numberOf(module?.duration_seconds)} s`,
    );
    appendTextElement(row, "td", moduleGuidance(module));
    tbody.appendChild(row);
  }
  table.appendChild(tbody);
  wrapper.appendChild(table);
  parent.appendChild(wrapper);
}

function findingAssetLabel(finding) {
  const asset = asObject(finding?.asset);
  const values = [asset.address, asset.hostname].filter(
    (value) => typeof value === "string" && value,
  );
  return values.join(" · ") || text(asset.id);
}

function renderFindings(parent, findings) {
  appendTextElement(parent, "h4", "Constats structurés");
  const entries = arrayOf(findings);
  if (!entries.length) {
    appendTextElement(
      parent,
      "p",
      "Aucun constat structuré n’est associé à cet audit.",
      { className: "muted" },
    );
    return;
  }

  const list = document.createElement("div");
  list.className = "finding-list";
  for (const finding of entries) {
    const card = document.createElement("article");
    card.className = "finding-card";
    const heading = document.createElement("div");
    heading.className = "finding-heading";
    appendTextElement(heading, "h5", finding?.title);
    appendStatusBadge(heading, finding?.validation_status);
    card.appendChild(heading);
    appendTextElement(
      card,
      "p",
      `Niveau ${severityLabel(finding?.severity)} · ${findingAssetLabel(finding)}`,
      { className: "finding-meta" },
    );
    appendTextElement(card, "p", finding?.observation);

    const details = document.createElement("details");
    appendTextElement(details, "summary", "Preuve, impact et remédiation");
    appendTextElement(details, "p", `Impact : ${text(finding?.impact)}`);
    appendTextElement(
      details,
      "p",
      `Action : ${text(finding?.remediation?.action)}`,
    );
    const evidence = arrayOf(finding?.evidence);
    if (evidence.length) {
      const evidenceList = document.createElement("ul");
      for (const item of evidence) {
        appendTextElement(
          evidenceList,
          "li",
          `${text(item?.source)} · ${text(item?.path)}`,
        );
      }
      details.appendChild(evidenceList);
    }
    card.appendChild(details);
    list.appendChild(card);
  }
  parent.appendChild(list);
}

function renderExportReview(parent, payload) {
  appendTextElement(parent, "h4", "Rapports et revue avant export");
  const review = asObject(payload?.export_review);
  appendTextElement(parent, "p", review.notice, {
    className: "notice-inline",
  });

  const preview = document.createElement("details");
  preview.className = "sensitive-preview";
  appendTextElement(preview, "summary", "Prévisualiser les données sensibles");
  const previewGrid = document.createElement("div");
  previewGrid.className = "preview-grid";
  for (const group of sensitivePreviewItems(review)) {
    const block = document.createElement("section");
    appendTextElement(block, "h5", `${group.label} (${group.count})`);
    if (!group.values.length) {
      appendTextElement(block, "p", "Aucune valeur détectée.", {
        className: "muted",
      });
    } else {
      const list = document.createElement("ul");
      for (const value of group.values) {
        appendTextElement(list, "li", value);
      }
      if (group.truncated) {
        appendTextElement(list, "li", "Liste abrégée dans cette prévisualisation.");
      }
      block.appendChild(list);
    }
    previewGrid.appendChild(block);
  }
  preview.appendChild(previewGrid);
  parent.appendChild(preview);

  const confirmation = document.createElement("label");
  confirmation.className = "review-confirmation";
  const checkbox = document.createElement("input");
  checkbox.type = "checkbox";
  checkbox.id = "export-review-confirm";
  confirmation.appendChild(checkbox);
  confirmation.appendChild(
    document.createTextNode(
      "J’ai vérifié les données ci-dessus avant d’ouvrir un rapport.",
    ),
  );
  parent.appendChild(confirmation);

  const reportList = document.createElement("ul");
  reportList.className = "report-list";
  const activatable = [];
  for (const report of arrayOf(payload?.reports)) {
    const item = document.createElement("li");
    const title = document.createElement("div");
    appendTextElement(title, "strong", report?.label || report?.kind);
    appendTextElement(
      title,
      "span",
      report?.sensitivity === "sensitive"
        ? "Données sensibles"
        : "Version anonymisée à relire",
      { className: "report-sensitivity" },
    );
    item.appendChild(title);
    const url = report?.available ? safeLocalReportUrl(report?.url) : "";
    if (url) {
      const link = appendTextElement(item, "a", "Ouvrir le rapport");
      link.className = "report-link is-disabled";
      link.setAttribute("aria-disabled", "true");
      link.tabIndex = -1;
      activatable.push({ link, url });
    } else {
      appendTextElement(item, "span", "Indisponible pour cet audit", {
        className: "muted",
      });
    }
    reportList.appendChild(item);
  }
  if (!reportList.children.length) {
    appendTextElement(reportList, "li", "Aucun rapport référencé.", {
      className: "muted",
    });
  }
  parent.appendChild(reportList);

  checkbox.addEventListener("change", () => {
    for (const entry of activatable) {
      if (checkbox.checked) {
        entry.link.href = entry.url;
        entry.link.target = "_blank";
        entry.link.rel = "noopener noreferrer";
        entry.link.className = "report-link";
        entry.link.removeAttribute("aria-disabled");
        entry.link.tabIndex = 0;
      } else {
        entry.link.removeAttribute("href");
        entry.link.removeAttribute("target");
        entry.link.removeAttribute("rel");
        entry.link.className = "report-link is-disabled";
        entry.link.setAttribute("aria-disabled", "true");
        entry.link.tabIndex = -1;
      }
    }
  });
}

function renderRunDetail(payload) {
  const container = clearElement(document.getElementById("run-detail"));
  if (!payload?.found) {
    appendTextElement(container, "h3", "Audit introuvable");
    appendTextElement(
      container,
      "p",
      "L’entrée n’existe plus dans l’historique. Rechargez la liste pour reprendre depuis l’état réel.",
      { className: "muted" },
    );
    return;
  }

  const run = asObject(payload.run);
  const summary = asObject(run.summary);
  const heading = document.createElement("div");
  heading.className = "run-heading";
  const headingText = document.createElement("div");
  appendTextElement(headingText, "p", "Résultat sélectionné", {
    className: "eyebrow",
  });
  appendTextElement(headingText, "h3", run.run_id || payload.run_id);
  heading.appendChild(headingText);
  appendStatusBadge(heading, summary.status || run.status);
  container.appendChild(heading);

  if (payload.degraded) {
    appendTextElement(
      container,
      "p",
      "Historique dégradé : des lignes illisibles ont été ignorées, mais ce résultat reste consultable.",
      { className: "notice-inline notice-warning" },
    );
  }
  if (payload.detail_source !== "manifest") {
    appendTextElement(
      container,
      "p",
      "Le manifest détaillé n’a pas pu être vérifié. Seules les informations sûres de l’historique sont affichées.",
      { className: "notice-inline notice-warning" },
    );
  }
  if (["partial", "failed"].includes(summary.status || run.status)) {
    appendTextElement(
      container,
      "p",
      "Cet audit est incomplet. Les résultats valides restent disponibles ; consultez chaque module avant de relancer un audit autorisé.",
      { className: "notice-inline notice-warning" },
    );
  }

  const metrics = document.createElement("dl");
  metrics.className = "metrics-grid";
  appendMetric(metrics, "Date", formatTimestamp(run.created_at));
  appendMetric(metrics, "Profil", profileLabel(run.profile));
  appendMetric(
    metrics,
    "Cibles",
    arrayOf(run.targets).length
      ? arrayOf(run.targets).map((value) => text(value)).join(", ")
      : "-",
  );
  appendMetric(
    metrics,
    "Modules",
    numberOf(summary.module_count ?? run.module_count),
  );
  appendMetric(
    metrics,
    "Constats",
    numberOf(summary?.findings?.total_count ?? run.finding_count),
  );
  appendMetric(
    metrics,
    "Durée",
    `${numberOf(summary.total_duration_seconds ?? run.total_duration_seconds)} s`,
  );
  container.appendChild(metrics);

  renderModuleDetails(container, run.modules);
  renderFindings(container, run.findings);
  renderExportReview(container, payload);

  const technical = document.createElement("details");
  technical.className = "technical-json";
  appendTextElement(technical, "summary", "Données techniques JSON");
  appendTextElement(technical, "pre", JSON.stringify(payload, null, 2));
  container.appendChild(technical);
}

async function loadRunDetail(runId) {
  if (!runIdPattern.test(runId)) {
    return;
  }
  const requestToken = ++resultsState.requestToken;
  const container = clearElement(document.getElementById("run-detail"));
  appendTextElement(container, "h3", `Audit ${runId}`);
  appendTextElement(container, "p", "Chargement du détail vérifié...", {
    className: "muted",
  });
  try {
    const payload = await loadJson(`/api/run?run_id=${encodeURIComponent(runId)}`);
    if (requestToken !== resultsState.requestToken) {
      return;
    }
    renderRunDetail(payload);
  } catch (error) {
    if (requestToken !== resultsState.requestToken) {
      return;
    }
    clearElement(container);
    appendTextElement(container, "h3", `Audit ${runId}`);
    appendTextElement(
      container,
      "p",
      `Impossible de charger le détail : ${text(error?.message)}. Utilisez « Réessayer » après avoir vérifié le service local.`,
      { className: "notice-inline notice-danger" },
    );
  }
}

function renderResults(snapshot) {
  const history = asObject(snapshot?.history);
  const latest = asObject(snapshot?.latest)?.latest;
  if (history.degraded || snapshot?.degraded) {
    renderNotice(
      `${numberOf(snapshot?.error_count || history.error_count)} entrée(s) illisible(s) ont été ignorée(s). Les résultats valides restent accessibles.`,
      "warning",
    );
  } else {
    hideNotice();
  }
  const selectedRunId = renderHistoryList(history, latest);
  if (selectedRunId) {
    loadRunDetail(selectedRunId);
  }
}

function render(snapshot) {
  const status = snapshot?.status || {};
  const modules = snapshot?.modules || {};
  const history = snapshot?.history || {};
  const latest = snapshot?.latest || { latest: null };
  const moduleEntries = arrayOf(modules.modules);
  const selectableCount =
    typeof modules.selectable_count === "number"
      ? modules.selectable_count
      : selectableModules(modules).length;

  renderStatus(status);
  document.getElementById("modules-summary").textContent =
    `${countLabel(selectableCount, "module prêt", "modules prêts")} sur ${countLabel(moduleEntries.length, "module recensé", "modules recensés")}`;
  document.getElementById("history-summary").textContent =
    countLabel(history.count, "audit enregistré", "audits enregistrés");

  renderModuleSelector(modules);

  const tbody = clearElement(document.getElementById("modules-table"));
  for (const module of moduleEntries) {
    appendTableRow(tbody, [
      module?.order,
      module?.display_name || module?.name,
      module?.path,
    ]);
  }
  if (!tbody.children.length) {
    renderMessageRow(tbody, "Aucun module détecté.", {
      className: "muted",
    });
  }
  renderResults(snapshot);
}

function refreshDashboard() {
  const retry = document.getElementById("results-retry");
  retry.disabled = true;
  retry.textContent = "Actualisation...";
  return loadJson("/api/snapshot")
    .then(render)
    .catch((error) => {
      document.getElementById("status-summary").textContent =
        `Erreur: ${text(error?.message)}`;
      document.getElementById("modules-summary").textContent = "Indisponible";
      document.getElementById("history-summary").textContent = "Indisponible";
      renderMessageRow(
        document.getElementById("modules-table"),
        "Erreur chargement API.",
      );
      renderMessageBlock(
        document.getElementById("plan-module-selector"),
        "Erreur chargement modules.",
      );
      renderNotice(
        `Impossible de charger les résultats : ${text(error?.message)}. Vérifiez que l’API locale répond puis réessayez.`,
        "danger",
      );
      renderMessageBlock(
        document.getElementById("history-list"),
        "Historique indisponible.",
        "muted",
      );
      renderMessageBlock(
        document.getElementById("run-detail"),
        "Aucun détail chargé.",
        "muted",
      );
    })
    .finally(() => {
      retry.disabled = false;
      retry.textContent = "Réessayer";
    });
}

function startDashboard() {
  document.getElementById("plan-form").addEventListener("submit", loadPlan);
  document
    .getElementById("results-retry")
    .addEventListener("click", refreshDashboard);

  refreshDashboard();

  loadJson("/api/routes")
    .then(renderRoutes)
    .catch((error) => {
      renderMessageRow(
        document.getElementById("routes-table"),
        `Erreur routes API: ${text(error?.message)}`,
      );
    });
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    appendTableRow,
    appendTextElement,
    clearElement,
    renderMessageBlock,
    renderMessageRow,
    renderHistoryList,
    safeLocalReportUrl,
    selectableModules,
    severityLabel,
    sensitivePreviewItems,
    statusPresentation,
    text,
    renderResults,
  };
}

if (typeof document !== "undefined") {
  startDashboard();
}
