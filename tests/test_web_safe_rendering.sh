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
}

global.document = {
  createElement: (tagName) => new FakeElement(tagName),
  createTextNode: (value) => new FakeTextNode(value),
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
NODE

printf '[OK] dashboard values stay literal and non-selectable modules stay hidden\n'
