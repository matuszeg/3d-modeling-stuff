# Bambu Studio templates

- `reference_p2s_project.3mf`: a 3-plate project saved by Bambu Studio
  02.08.02 for the P2S (the Bambu account ID removed). It's the ground truth
  for the file format: `tools/bambu_project.py` copies its layout, and
  `tools/check_bambu_project.py` compares generated projects against it.
- `p2s_project_settings.config`: `Metadata/project_settings.config` from that
  project: P2S 0.4 nozzle, 0.20mm Standard, Textured PEI plate, filaments
  1-4 = PLA, PLA, PETG, ABS. Every generated project starts from it, so it
  opens with these profiles selected.

If Bambu Studio updates and starts refusing generated projects, save a fresh
small multi-plate project from it, replace both files with the new one (strip
the `DesignerUserId` line from `3D/3dmodel.model`), and regenerate.

Lessons from getting this right:
- Without `Metadata/project_settings.config` Bambu Studio says the file is
  invalid and loads only the geometry.
- Plates sit in a grid: `ceil(sqrt(n))`-ish columns, `bed * 1.2` apart, later
  rows toward -y. A part belongs to a plate through `<plate><model_instance>`
  in `model_settings.config` and must also physically sit on that plate.
- Per-object settings (e.g. `brim_type`) go as `<metadata key=... value=...>`
  on the `<object>` in `model_settings.config`.
- Settings changed from the preset are listed in
  `different_settings_to_system[0]` (process).
