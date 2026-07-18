# Wing stations — trim once, replicate by the numbers

The movable wing exists to re-trim CG per payload, but only the FIRST
airframe of a configuration needs to move. The workflow:

1. **Trim** on the clamping adapter (`cad/wing_adapter.scad` — tooling,
   lives in the kit box). Fit the payload, slide the wing, glide-test,
   repeat. The M3 clamp makes every guess reversible.
2. **Record** the winning station in the table below. If it's the
   configuration currently being built, also set `wing_station` in
   `cad/design_params.scad` so the assembly render matches reality.
3. **Replicate**: every later airframe of that configuration flies the
   hardware-free `cad/wing_adapter_glue.scad`. Mark the fresh tube, slide
   the adapter to the mark, tack it with hot-glue fillets at both rims
   (each rim has a chamfered glue seat).

Fillets at the rims only — never glue in the bore. Rim tacks cut free
cleanly, so a bad guess or a spent tube gives the printed adapter back;
bore glue makes the adapter consumable.

## Marking a fresh tube

Stations are measured from the **motor face**, but a tape measure works
from the tube's rear end. The tube seats `tail_tube_stop` deep against the
tail sleeve's internal rim, so:

```
mark = wing_station − tail_tube_stop     (mm, from the REAR end of the tube)
```

The adapter's **aft edge** sits on the mark. With the current defaults:
300 − 54 = **246 mm**.

## Documented stations

| Payload | Mass (g) | `wing_station` (mm from motor face) | Mark (mm from rear tube end) | Notes |
|---|---|---|---|---|
| _none yet — trim the bare airframe first_ | | 300 (untrimmed default) | 246 | |
