#!/usr/bin/env bash
# Prove that API-controlled values use text nodes instead of HTML parsing.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
NODE_COMMAND="${AUDIT_SUITE_NODE:-node}"

if ! command -v "$NODE_COMMAND" >/dev/null 2>&1; then
  printf '[FAIL] Node.js is required for the dashboard rendering test\n' >&2
  exit 127
fi

if grep -ERn \
  'innerHTML|outerHTML|insertAdjacentHTML|document[.]write' \
  "$REPO_DIR/web" \
  --include='*.html' \
  --include='*.js'; then
  printf '[FAIL] forbidden HTML interpretation sink found in dashboard sources\n' >&2
  exit 1
fi

"$NODE_COMMAND" - "$REPO_DIR/web/app.js" <<'NODE'
"use strict";

const assert = require("assert");
const appPath = process.argv[2];
const ui = require(appPath);

class FakeTextNode {
  constructor(value) {
    this.nodeType = 3;
    this.textContent = String(value);
  }
}

class FakeElement {
  constructor(tagName) {
    this.tagName = String(tagName).toUpperCase();
    this.children = [];
    this.className = "";
    this.colSpan = 1;
    this._textContent = "";
    this.attributes = {};
    this.listeners = {};
  }

  appendChild(child) {
    this.children.push(child);
    return child;
  }

  replaceChildren(...children) {
    this.children = [...children];
    this._textContent = "";
  }

  set textContent(value) {
    this._textContent = String(value);
    this.children = [];
  }

  get textContent() {
    return this._textContent;
  }

  setAttribute(name, value) {
    this.attributes[name] = String(value);
  }

  removeAttribute(name) {
    delete this.attributes[name];
  }

  addEventListener(name, listener) {
    this.listeners[name] = listener;
  }
}

const elementsById = {};
global.document = {
  createElement: (tagName) => new FakeElement(tagName),
  createTextNode: (value) => new FakeTextNode(value),
  getElementById: (id) => elementsById[id],
};

const hostile =
  '<img src=x onerror="globalThis.compromised=true">&<script>bad()</script>';
const host = new FakeElement("div");
const cell = ui.appendTextElement(host, "td", hostile);

assert.strictEqual(host.children.length, 1);
assert.strictEqual(cell.tagName, "TD");
assert.strictEqual(cell.textContent, hostile);
assert.strictEqual(cell.children.length, 0);
assert.strictEqual(globalThis.compromised, undefined);

const tbody = new FakeElement("tbody");
const row = ui.appendTableRow(tbody, [hostile, "<b>route</b>", "json&html"]);
assert.strictEqual(tbody.children.length, 1);
assert.strictEqual(row.children.length, 3);
assert.deepStrictEqual(
  row.children.map((item) => item.textContent),
  [hostile, "<b>route</b>", "json&html"],
);
assert.ok(row.children.every((item) => item.children.length === 0));

const messageBody = new FakeElement("tbody");
ui.renderMessageRow(messageBody, `Erreur: ${hostile}`);
assert.strictEqual(messageBody.children[0].children[0].textContent, `Erreur: ${hostile}`);
assert.strictEqual(messageBody.children[0].children[0].children.length, 0);

assert.deepStrictEqual(
  ui.selectableModules({
    modules: [
      { name: "safe", selectable: true },
      { name: "placeholder", selectable: false },
      { name: "", selectable: true },
    ],
  }).map((item) => item.name),
  ["safe"],
);

assert.strictEqual(
  ui.safeLocalReportUrl(
    "/api/report?run_id=AUDIT_SAFE_1&kind=shareable",
  ),
  "/api/report?run_id=AUDIT_SAFE_1&kind=shareable",
);
assert.strictEqual(
  ui.safeLocalReportUrl("javascript:globalThis.compromised=true"),
  "",
);
assert.strictEqual(
  ui.safeLocalReportUrl("/api/report?run_id=../private&kind=private"),
  "",
);
assert.strictEqual(
  ui.safeLocalReportUrl("/api/report?run_id=AUDIT_1&kind=unknown"),
  "",
);
assert.deepStrictEqual(ui.statusPresentation("partial"), {
  label: "Partiel",
  tone: "warning",
});
assert.deepStrictEqual(
  ui.sensitivePreviewItems({
    targets: { count: 1, values: [hostile], truncated: false },
    asset_addresses: { count: 0, values: [] },
    hostnames: { count: 0, values: [] },
    evidence_paths: { count: 0, values: [] },
  })[0],
  {
    label: "Cibles",
    count: 1,
    values: [hostile],
    truncated: false,
  },
);

elementsById["history-list"] = new FakeElement("div");
elementsById["run-detail"] = new FakeElement("article");
elementsById["results-alert"] = new FakeElement("div");
assert.strictEqual(ui.renderHistoryList({ runs: [] }, null), "");
assert.strictEqual(
  elementsById["history-list"].children[0].textContent,
  "Aucun audit enregistré pour le moment.",
);
assert.strictEqual(
  elementsById["run-detail"].children[0].textContent,
  "Historique vide",
);

const selectedRun = ui.renderHistoryList(
  {
    runs: [
      {
        run_id: "AUDIT_SAFE_1",
        created_at: "2026-07-30T10:00:00Z",
        profile: "fast",
        status: "partial",
        finding_count: 2,
        failed_count: 0,
        partial_count: 1,
      },
    ],
  },
  { run_id: "AUDIT_SAFE_1" },
);
assert.strictEqual(selectedRun, "AUDIT_SAFE_1");
assert.strictEqual(elementsById["history-list"].children.length, 1);
assert.strictEqual(
  elementsById["history-list"].children[0].attributes["aria-current"],
  "true",
);

ui.renderResults({
  degraded: true,
  error_count: 2,
  history: { degraded: true, runs: [] },
  latest: { latest: null },
});
assert.strictEqual(
  elementsById["results-alert"].className,
  "notice notice-warning",
);
assert.ok(
  elementsById["results-alert"].children[0].textContent.includes(
    "2 entrée(s) illisible(s)",
  ),
);
NODE

printf '[OK] dashboard values stay literal and non-selectable modules stay hidden\n'
