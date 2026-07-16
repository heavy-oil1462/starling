#!/usr/bin/env python3
"""Headless OpenSCAD renderer (no GUI, no X server needed) — nix-based.

Fetches OpenSCAD (+ Mesa software GL for PNG output) from nixpkgs and
renders via EGL surfaceless. Never download binaries manually — everything
comes from the nix store.

Usage:
    scripts/render_scad.py <file.scad> [output.(png|stl|dxf)] [extra openscad args...]

Examples:
    scripts/render_scad.py cad/main_assembly.scad                 # -> cad/main_assembly.png
    scripts/render_scad.py cad/nose.scad stl/nose.stl             # manifold check / export
    scripts/render_scad.py cad/main_assembly.scad top.png --camera=0,0,0,0,0,0,1500 --projection=o

Notes (learned in the PrintTrek project — do not rediscover):
- The sandbox's LD_LIBRARY_PATH=/lib makes nix binaries load the system
  libc and crash. We override it with only the GL libs nix should see.
- PNG rendering needs GL: use Mesa software rendering via
  EGL_PLATFORM=surfaceless (no X/xvfb required).
"""

import os
import subprocess
import sys
from pathlib import Path

_STORE_CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "starling-nix-paths"


def nix_path(attr: str) -> str:
    """Resolve a nixpkgs attribute to its store path (cached across runs)."""
    cache = _STORE_CACHE / attr
    if cache.exists():
        p = cache.read_text().strip()
        if Path(p).exists():
            return p
    out = subprocess.run(
        ["nix", "build", f"nixpkgs#{attr}", "--no-link", "--print-out-paths"],
        check=True, capture_output=True, text=True,
    ).stdout.strip().splitlines()[-1]
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(out)
    return out


def render(scad: str, out: str, extra_args=None) -> subprocess.CompletedProcess:
    """Render one .scad file. Returns the CompletedProcess (check output/stderr)."""
    extra_args = list(extra_args or [])
    openscad = nix_path("openscad-unstable") + "/bin/openscad"

    env = dict(os.environ)
    args = ["--backend", "Manifold"]
    if out.endswith(".png"):
        mesa, glvnd = nix_path("mesa"), nix_path("libglvnd")
        env.update(
            LD_LIBRARY_PATH=f"{glvnd}/lib:{mesa}/lib",
            __EGL_VENDOR_LIBRARY_FILENAMES=f"{mesa}/share/glvnd/egl_vendor.d/50_mesa.json",
            EGL_PLATFORM="surfaceless",
            LIBGL_ALWAYS_SOFTWARE="1",
        )
        if not any(a.startswith("--imgsize") for a in extra_args):
            args += ["--imgsize", "1600,1200"]
        if not any(a.startswith("--camera") for a in extra_args):
            args += ["--viewall", "--autocenter"]
    else:
        # Non-GL outputs: keep nix libs only, the system /lib crashes nix binaries.
        env["LD_LIBRARY_PATH"] = ""

    cmd = [openscad, *args, *extra_args, "-o", out, scad]
    return subprocess.run(cmd, env=env, capture_output=True, text=True)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    scad = argv[1]
    out = argv[2] if len(argv) > 2 and not argv[2].startswith("-") else str(Path(scad).with_suffix(".png"))
    extra = argv[3:] if len(argv) > 2 and not argv[2].startswith("-") else argv[2:]
    proc = render(scad, out, extra)
    sys.stderr.write(proc.stderr)
    if proc.returncode == 0:
        print(f"rendered {scad} -> {out}")
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv))
