// Shared text helper. Lives under cad/lib/ so regen_all.py does not try to
// export it as a printable part (it scans cad/ and cad/calibration/ only).

// Text wrapped around a cylinder, one character at a time.
//
// Flat text engraved into a Ø50-class cylinder does NOT work: the tangent
// plane leaves the material within a few millimetres, so the outer
// characters never break the surface and the label silently reads wrong
// ("45.95" came out as "15.95"). Placing each glyph on its own tangent
// keeps every character the same depth.
//
// Produces solid glyphs meant to be subtracted; the caller positions it in
// Z. The label faces -Y and is centred on that side.
module curved_text(txt, radius, size = 4, depth = 0.8) {
    char_advance = size * 0.62;                       // default-font approximation
    step_angle   = char_advance / (radius * PI / 180);
    for (i = [0 : len(txt) - 1])
        rotate([0, 0, (i - (len(txt) - 1) / 2) * step_angle])
            // Glyphs share a baseline (centring each one individually
            // floats the decimal point to mid-height: "52·95"); the Z
            // offset re-centres the string as a whole.
            translate([0, -(radius - depth), -size * 0.35])
                rotate([90, 0, 0])
                    // +1 so the glyph always exits the surface cleanly
                    linear_extrude(height = depth + 1)
                        text(txt[i], size = size,
                             halign = "center", valign = "baseline");
}
