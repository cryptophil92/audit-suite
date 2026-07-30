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
  appendTextElement(container, "span", "JSON chargé", {
    className: "status-ok",
  });
  appendStatusLine(
    container,
    "Modules dir",
    status?.checks?.modules_dir_exists,
  );
  appendStatusLine(
    container,
    "History index",
    status?.checks?.history_index_exists,
  );
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
    `${selectableCount} module(s) sélectionnable(s) sur ${moduleEntries.length}`;
  document.getElementById("history-summary").textContent =
    `${Number(history.count) || 0} run(s) historisé(s)`;

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

  document.getElementById("latest-json").textContent = JSON.stringify(
    latest.latest,
    null,
    2,
  );
}

function startDashboard() {
  document.getElementById("plan-form").addEventListener("submit", loadPlan);

  loadJson("/api/snapshot")
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
      document.getElementById("latest-json").textContent = "null";
    });

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
    selectableModules,
    text,
  };
}

if (typeof document !== "undefined") {
  startDashboard();
}
