# Project Dawn: rules for AI coding sessions

Godot 4 (GDScript only, Compatibility renderer, Web export). NASA Space Apps 2026, 48-hour build.

## Read first, every session
1. `HANDOVER.md`: roles, file ownership, workflow
2. `CONTRACT.md`: the engine ↔ interface API and data shapes (do not change without approval)
3. Last 3 entries of `docs/HANDOFF.md`

## Who you are working for
- **Claude Code = Sufi = ENGINE.** Edit only `engine/`, `tests/`, and the *structure* of `data/*.json`.
- **Codex = Zaliq = INTERFACE.** Edit only `ui/`.
- Never edit `project.godot` or `export_presets.cfg` (Imran owns them). Need an autoload/input action? Open an issue.

## Hard rules
- Never edit files outside your owner's folders. Need something from the other side → `gh issue create --label <engine|ui>`.
- Never change function signatures or JSON shapes in `CONTRACT.md` on your own.
- Engine: pure GDScript, deterministic, no nodes/scenes/UI formatting. UI: no game maths; call `GameEngine` only.
- Do not edit `.tscn` files by hand unless the user asks; build UI nodes in the screen's `.gd` where possible.
- One small feature per session. Show the plan before writing code.
- Engine changes need a test in `tests/run_tests.gd`. Run: `godot --headless --path . -s res://tests/run_tests.gd`
- All numbers are game values unless sourced in `docs/SOURCES.md`. Never invent "real NASA facts".
- End of session: run tests, append to `docs/HANDOFF.md`, commit on a feature branch, push, open a PR ("Closes #N"). Never commit to `main`.
