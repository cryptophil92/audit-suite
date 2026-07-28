"""Read the canonical AUDIT-SUITE version and source revision."""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent
VERSION_FILE = REPO_DIR / "VERSION"
SEMVER_PATTERN = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$"
)
COMMIT_PATTERN = re.compile(r"^(?:[0-9A-Fa-f]{7,40}|unknown)$")


def read_version() -> str:
    version = VERSION_FILE.read_text(encoding="utf-8").strip()
    if not SEMVER_PATTERN.fullmatch(version):
        raise RuntimeError(f"Invalid semantic version in {VERSION_FILE}: {version}")
    return version


def resolve_commit() -> str:
    injected_commit = os.environ.get("AUDIT_SUITE_COMMIT", "")
    if injected_commit:
        if not COMMIT_PATTERN.fullmatch(injected_commit):
            raise RuntimeError(f"Invalid AUDIT_SUITE_COMMIT: {injected_commit}")
        return injected_commit

    try:
        result = subprocess.run(
            ["git", "-C", str(REPO_DIR), "rev-parse", "--verify", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (FileNotFoundError, subprocess.SubprocessError):
        return "unknown"

    commit = result.stdout.strip()
    return commit if COMMIT_PATTERN.fullmatch(commit) else "unknown"


APP_VERSION = read_version()
APP_COMMIT = resolve_commit()
