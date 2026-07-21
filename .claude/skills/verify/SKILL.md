---
name: verify
description: Read-only commit gate for Starling. Renders every part and the assembly to a temp dir and byte-compares against the committed STLs and main_assembly.png, after the param and throw gates. Use when about to commit, before opening a PR, or when asked whether the repo is consistent. Never skip it because "only docs changed" if any .scad or scripts/ file is in the diff.
---

# Verify

```bash
python3 scripts/regen_all.py --check
```

Read-only: nothing in the working tree is touched. CI runs exactly this
command (.github/workflows/verify.yml, no-nix via the OpenSCAD snapshot
AppImage and $OPENSCAD). Every line must be `[ok]` and the exit code 0
before committing.

Note: the sandbox's GitHub token lacks the `workflow` scope, so agents
cannot push .github/workflows/ files — commit workflow changes locally and
have the user push the branch.

What it checks, in order:

1. `check_params.py` — no file shadows a design_params.scad name
2. `throw_check.py` — control throw, slot length, prop clearance
3. every printable part renders warning-free with manifold status NoError,
   AND the fresh render is byte-identical to the committed `stl/<name>.stl`
4. `main_assembly.png` byte-matches a fresh assembly render (this is the
   README image — a stale one ships a wrong picture of the airframe)
5. no orphaned files in `stl/` that lack a source part

## When it fails

- `[STALE]` — a source changed but the committed artifact was not
  regenerated. Fix: `python3 scripts/regen_all.py` (the regen-outputs
  skill) and commit the refreshed artifacts in the same change as the
  source edit. Never hand-edit an artifact to make it match.
- `[STALE] ... has no source part` — a part was deleted or renamed but its
  STL stayed behind. Delete the STL (or restore the part).
- `[FAIL]` with warnings or a geometry status — the part itself is broken;
  see the openscad-review skill. This is a modeling error, not a staleness
  error.
- Param/throw gate failures — shared-dimension or control-geometry
  violations; fix the value in `cad/design_params.scad`, never a local copy
  and never the gate's threshold.

## Notes

- Renders are byte-deterministic only within one OpenSCAD build. A full
  regen records the build's version in stl/openscad_version.txt, and
  --check compares bytes only when the running version matches; otherwise
  it prints a [note] and self-skips the byte comparison while every other
  check still runs. This is what lets CI use the latest snapshot AppImage
  instead of the pinned nix binary.
- If verify starts flagging artifacts that look identical, suspect a
  changed nixpkgs pin or a locally built OpenSCAD slipping past the
  version match, not the comparison — do not loosen it to a perceptual
  diff without checking the recorded version first.
- Running without nix anywhere: set OPENSCAD=/path/to/openscad and all
  scripts use that binary as-is (this is how CI works). The scripts are
  stdlib-only Python, so no pip install is needed either.
