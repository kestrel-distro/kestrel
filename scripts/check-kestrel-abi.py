#!/usr/bin/env python3
"""Check that every copy of the Kestrel hint ABI agrees.

The hint is duplicated by design: the kernel patch, libkestrel-hint, the three
app forks and the Firefox patch each carry the struct, the flag and the hint
values, because none of them can depend on a shared build artifact. A silent
drift between them produces a scheduler that matches nothing, so this script
checks the constants, the struct layout and the class tables against the
canonical copies.

Run from the kestrel repo. Sibling checkouts (../kernel, ../hyprland, ...) are
checked when present; set KESTREL_ABI_REQUIRE=1 to make a missing sibling an
error (CI does this). The Zen/Firefox patch is checked when
../zen-browser/kestrel/firefox-kestrel-hint.patch exists.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SIB = Path(os.environ.get("KESTREL_ABI_SIBLINGS", ROOT.parent))
REQUIRE = os.environ.get("KESTREL_ABI_REQUIRE") == "1"

FLAG = "1ULL << 40"
FLAG_NOSPACE = "1<<40"
KEEP_POLICY = "0x08"
KEEP_PARAMS = "0x10"
MAX_HINT = 1024
HINT_VALUES = {
    1: "desktop",
    2: "term",
    3: "browser-active",
    4: "browser-background",
    5: "game",
}

failures: list[str] = []
skips: list[str] = []


def fail(msg: str) -> None:
    failures.append(msg)


def read(path: Path) -> str | None:
    if not path.is_file():
        return None
    return path.read_text(errors="replace")


def need(path: Path, label: str) -> str | None:
    text = read(path)
    if text is None:
        if REQUIRE:
            fail(f"{label}: missing file {path}")
        else:
            skips.append(f"{label}: {path} not present")
    return text


def check_contains(text: str | None, label: str, needle: str, where: str) -> None:
    if text is None:
        return
    if needle not in text:
        fail(f"{label}: {where} does not contain {needle!r}")


def check_regex(text: str | None, label: str, pattern: str, where: str) -> None:
    if text is None:
        return
    if not re.search(pattern, text, re.MULTILINE):
        fail(f"{label}: {where} does not match /{pattern}/")


def check_c_constants(text: str | None, label: str) -> None:
    """The C/C++ copies spell the flag and keep bits differently."""
    if text is None:
        return
    check_regex(text, label, r"(?:KESTREL_HINT_FLAG|FLAG)\s*(?:=|\s)\s*\(?\s*1ULL?\s*<<\s*40", "hint flag")
    check_regex(text, label, r"(?:KESTREL_SCHED_FLAG_KEEP_POLICY|KEEP_POLICY)\s*(?:=|\s)\s*\(?\s*0x08ULL?", "keep-policy")
    check_regex(text, label, r"(?:KESTREL_SCHED_FLAG_KEEP_PARAMS|KEEP_PARAMS)\s*(?:=|\s)\s*\(?\s*0x10ULL?", "keep-params")
    check_regex(text, label, r"sched_ext_hint\s*;", "sched_ext_hint member")


def check_struct_layout() -> None:
    header = ROOT / "install/helpers/libkestrel-hint/kestrel_hint.h"
    if not header.is_file():
        fail("lib: missing kestrel_hint.h")
        return
    probe = r"""
#include <stddef.h>
#include <stdio.h>
#include "kestrel_hint.h"
int main(void) {
    printf("%zu %zu %zu\n",
        sizeof(struct kestrel_sched_attr),
        offsetof(struct kestrel_sched_attr, sched_ext_hint),
        offsetof(struct kestrel_sched_attr, sched_util_max));
    return 0;
}
"""
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "probe.c"
        out = Path(tmp) / "probe"
        src.write_text(probe)
        cc = os.environ.get("CC", "cc")
        proc = subprocess.run(
            [cc, "-std=gnu11", "-I", str(header.parent), str(src), "-o", str(out)],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            fail(f"lib: layout probe failed to compile: {proc.stderr.strip()}")
            return
        run = subprocess.run([str(out)], capture_output=True, text=True)
        if run.returncode != 0:
            fail(f"lib: layout probe failed: {run.stderr.strip()}")
            return
        size, hint_off, util_off = (int(v) for v in run.stdout.split())
        if size != 64:
            fail(f"lib: sizeof(sched_attr) is {size}, expected 64")
        if hint_off != 56:
            fail(f"lib: offsetof(sched_ext_hint) is {hint_off}, expected 56")
        if util_off != 52:
            fail(f"lib: offsetof(sched_util_max) is {util_off}, expected 52")


def check_layers() -> None:
    path = SIB / "scx/scheds/rust/scx_kestrel/kestrel-layers.json"
    text = need(path, "layers")
    if text is None:
        return
    try:
        layers = json.loads(text)
    except json.JSONDecodeError as exc:
        fail(f"layers: invalid JSON: {exc}")
        return

    found: dict[int, str] = {}
    cgroups: set[str] = set()
    for layer in layers:
        for block in layer.get("matches", []):
            for match in block:
                if "KestrelHint" in match:
                    found[match["KestrelHint"]] = layer.get("name", "?")
                if "CgroupContains" in match:
                    cgroups.add(match["CgroupContains"])
    if set(found) != set(HINT_VALUES):
        fail(f"layers: hint values {sorted(found)} != expected {sorted(HINT_VALUES)}")
    for value, label in HINT_VALUES.items():
        if found.get(value) != f"kestrel-{label}":
            fail(f"layers: hint {value} maps to {found.get(value)!r}, expected kestrel-{label}")

    units = ROOT / "default/systemd/user"
    for cgroup in sorted(cgroups):
        top = cgroup.split("/")[0]
        unit = top if top.endswith(".slice") else f"{top}.slice"
        if not (units / unit).is_file():
            fail(f"layers: cgroup {cgroup!r} has no unit {unit}")


def check_docs() -> None:
    text = need(SIB / "docs/03-kernel.md", "docs")
    if text is None:
        return
    for needle in ("SCHED_FLAG_KESTREL_HINT", "1ULL << 40", "SCHED_KESTREL_HINT_MAX", "1024"):
        check_contains(text, "docs", needle, "ABI table")
    check_regex(text, "docs", r"1 desktop, 2 term, 3 browser active, 4 browser\s*\n?background, 5 game", "hint value table")


def check_broker() -> None:
    text = need(ROOT / "bin/kestrel-broker", "broker")
    if text is None:
        return
    check_regex(text, "broker", r"\*foot\*\)\s*echo\s+term", "foot class")
    check_regex(text, "broker", r"\*zen\*[^)]*\*firefox\*\)\s*echo\s+browser", "browser class")
    for sub in ("active", "background"):
        check_contains(text, "broker", f'class_dir browser)/{sub}', "browser buckets")


def main() -> int:
    lib = need(ROOT / "install/helpers/libkestrel-hint/kestrel_hint.h", "lib")
    check_contains(lib, "lib", "KESTREL_HINT_MAX 1024u", "hint max")
    check_c_constants(lib, "lib")
    check_regex(lib, "lib", r"sched_ext_hint\s*;\s*\n\};", "struct tail")

    kernel = need(SIB / "kernel/packaging/local/kestrel/0001-kestrel-sched-hint.patch", "kernel")
    for needle in ("SCHED_FLAG_KESTREL_HINT", "(1ULL << 40)", "SCHED_KESTREL_HINT_MAX", "1024",
                   "scx_bpf_task_hint", "BTF_ID_FLAGS(func, scx_bpf_task_hint"):
        check_contains(kernel, "kernel", needle, "patch")

    hypr = need(SIB / "hyprland/src/kestrel/KestrelHint.hpp", "hyprland")
    check_c_constants(hypr, "hyprland")
    check_contains(read(SIB / "hyprland/src/main.cpp"), "hyprland", "setProcess(1)", "startup hint")

    qs = need(SIB / "quickshell/src/kestrel/KestrelHint.hpp", "quickshell")
    check_c_constants(qs, "quickshell")
    check_contains(read(SIB / "quickshell/src/launch/main.cpp"), "quickshell", "setProcess(1)", "startup hint")

    foot = need(SIB / "foot/kestrel_hint.h", "foot")
    check_c_constants(foot, "foot")
    for src in ("main.c", "client.c", "render.c", "spawn.c"):
        check_contains(read(SIB / "foot" / src), "foot", "kestrel_hint_set(0, 2)", src)

    zen = SIB / "zen-browser/kestrel/firefox-kestrel-hint.patch"
    zen_text = read(zen)
    if zen_text is None:
        if REQUIRE:
            fail(f"zen: missing {zen}")
        else:
            skips.append(f"zen: {zen} not present")
    else:
        for needle in ("kFlag = 1ULL << 40", "kKeepPolicy = 0x08ULL", "kKeepParams = 0x10ULL",
                       "sched_ext_hint", ">= hal::PROCESS_PRIORITY_FOREGROUND ? 3u : 4u"):
            check_contains(zen_text, "zen", needle, "patch")

    check_struct_layout()
    check_layers()
    check_docs()
    check_broker()

    for skip in skips:
        print(f"skip: {skip}")
    for failure in failures:
        print(f"FAIL: {failure}")
    if failures:
        print(f"\n{len(failures)} ABI check(s) failed")
        return 1
    print("kestrel hint ABI: all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
