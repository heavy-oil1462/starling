# Supervisor notes

How the podium team works on this repository. Written and kept by the
supervisor.

## Team

- One worker by default. Most changes touch `design_params.scad` and the
  regenerated artifacts, so parallel pull requests conflict in `stl/` and
  `main_assembly.png`. Run a second worker only on work that does not
  touch CAD (docs, scripts, ArduPilot config).
- Remove a worker once it has had no issue for about an hour.

## Cutting issues

- One part or one gate per issue. Name the .scad files, the
  `design_params.scad` names involved, and the gate script that must pass.
- Acceptance criteria must be checkable: a gate passes (`regen_all.py
  --check`, `wing_check.py`, `throw_check.py`), a named render shows X,
  only the expected STLs change.
- If a change adds a shared dimension, a new part, or a new gate, the
  issue says where it lives. Write an ADR in `docs/adr` when the change
  alters an interface between parts.

## Review

- Check the diff of `stl/`: only parts whose source changed may change.
- Look at the rendered PNGs (`openscad-review` skill). Don't approve CAD
  from the source alone.
- Watch for shadowed shared names, magic numbers that should derive from
  `design_params.scad`, and parts that would need supports.

## Lessons

- 2026-10-30: first podium session. The pre-podium history (PRs #1–#11)
  was the owner working directly. PR #11 (Hoerner wingtip) was closed
  unmerged on 2026-10-26. Ask before reopening that idea.
