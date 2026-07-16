#!/usr/bin/env python3
"""Python-side access to cad/design_params.scad — the single source of truth.

OpenSCAD consumes the file directly (every part includes it); Python tools
import this module, which parses the same file, so CAD and analysis can
never drift apart. Values: numbers, booleans, and flat vectors ([a, b]).

Override precedence (highest first):
  1. environment variable, UPPERCASE of the name (SERVO_HORN_R=12 ...)
  2. the value in cad/design_params.scad

Usage:
    from design_params import PARAMS
    horn = PARAMS["servo_horn_r"]
"""

import os
import re
from pathlib import Path

_SCAD = Path(__file__).resolve().parent.parent / "cad" / "design_params.scad"


def _parse(text):
    s = text.strip()
    if s.lower() in ("true", "false"):
        return s.lower() == "true"
    if s.startswith("[") and s.endswith("]"):
        return [_parse(part) for part in s[1:-1].split(",")]
    return float(s) if "." in s else int(s)


def load():
    params = {}
    for m in re.finditer(r"(?m)^\s*(\w+)\s*=\s*([^;]+?)\s*;", _SCAD.read_text()):
        try:
            params[m.group(1)] = _parse(m.group(2))
        except ValueError:
            raise ValueError(
                f"design_params.scad: unsupported value {m.group(2)!r} for "
                f"{m.group(1)!r} — keep the file to numbers/booleans/vectors")
    for name in params:
        env = os.environ.get(name.upper())
        if env is not None:
            params[name] = _parse(env)
    return params


PARAMS = load()

if __name__ == "__main__":
    for k, v in PARAMS.items():
        print(f"{k} = {v}")
