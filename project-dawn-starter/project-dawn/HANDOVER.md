# Project Dawn: Handover for Sufi and Zaliq

NASA Space Apps Challenge 2026 · Space Mission Design Game · Godot 4 · 14–15 Nov

Read this once, fully, before your first prompt. Then point your AI at `CLAUDE.md` (Sufi) or `AGENTS.md` (Zaliq) and `CONTRACT.md`.

---

## 1. The team

| Person | Role | AI tool | Owns | Never touches |
|---|---|---|---|---|
| **Sufi** | Engine developer | Claude Code | `engine/`, `tests/`, the *format* of `data/*.json` | `ui/`, any `.tscn`, `project.godot` |
| **Zaliq** | Interface developer | Codex | `ui/` (all scenes + their scripts), `ui/theme/` | `engine/`, `tests/`, `project.godot` |
| **Imran** | Lead, integrator, deployer | Claude (reviews) | `project.godot`, `export_presets.cfg`, `README.md`, merges, itch.io | — |
| **Wam** | Story writer | — | *Content* of `data/missions.json` text fields, `data/dialogue.json`, `docs/STORY.md` | code |
| **Dino** | Research / NASA data | — | *Values* in `data/parts.json`, `data/real_missions.json`, `docs/SOURCES.md` | code |
| **Wafi** | Visuals, art, video | — | `assets/`, `assets/CREDITS.md`, style guide | code |

**Golden rule: Sufi and Zaliq never edit the same file.** If you need something from the other side, open a GitHub issue (see §6).

---

## 2. What we are building

A Godot 4 web game. Four scientists (Engineer, Scientist, Navigator, Quartermaster) and the AI tutor **CERES** run Project Dawn: repair Earth's damaged ozone layer across 5 acts on Earth, the Moon and Mars, plus 10 optional "Helping Humanity" missions. Full story: `docs/STORY.md`.

**The core loop (every playable objective uses it):**

```
Mission brief (story + requirements)
  → Vehicle Designer (pick parts, launcher, fuel)
  → Readiness Review (CERES lists issues; each role signs off)
  → Launch / trip
  → Mission Report (requirements met?, WHY, real NASA mission match)
  → story continues, or redesign and retry
```

Everything is **data-driven**: acts, missions, parts, requirements and dialogue live in `data/*.json`. Adding a mission = adding JSON, not code. That is how we keep the full story without writing a new system per act.

### Build priority (the story stays whole; we build in this order)

| Priority | Content | Done by |
|---|---|---|
| **P0** | Core loop + Act 1 (1.1 launch site choice, 1.2 ozone CubeSat) | Sat ~19:00 |
| **P0** | Act 2 (Moon scouting trips with fuel guess, outpost landing) | Sat night |
| **P1** | Optional A (Bunker Link), D (Storm Watch): same designer, new briefs | Sun 10:00 |
| **P1** | Acts 3–5 as playable briefs where possible, otherwise story screens | Sun 12:00 freeze |
| **P2** | Remaining optionals, endings polish | Only if time |

The game must be **playable end to end at every merge**. If a mission isn't built yet, its act plays as a story screen and moves on.

---

## 3. Repo structure

```
project-dawn/
├── HANDOVER.md            ← this file
├── CLAUDE.md              ← rules Claude Code reads (Sufi)
├── AGENTS.md              ← same rules for Codex (Zaliq)
├── CONTRACT.md            ← engine ↔ interface agreement (sacred)
├── README.md              ← Imran (public project page)
├── .gitignore
├── project.godot          ← Imran only
├── export_presets.cfg     ← Imran only (Web preset, Thread Support OFF)
│
├── engine/                ← SUFI
│   ├── game_engine.gd     ← autoload "GameEngine": the ONLY API the UI calls
│   ├── data_loader.gd     ← reads data/*.json
│   ├── checks.gd          ← readiness review rules
│   ├── simulate.gd        ← launch / trip outcome, fuel guess
│   ├── report.gd          ← score, why-lines, real mission match
│   └── game_state.gd      ← acts, progress, ozone meter, credits, ending
│
├── ui/                    ← ZALIQ
│   ├── main.tscn          ← main scene, switches screens
│   ├── main.gd
│   ├── screens/
│   │   ├── title.tscn / .gd
│   │   ├── mission_select.tscn / .gd     (act map + available missions)
│   │   ├── story.tscn / .gd              (dialogue box + portrait + background)
│   │   ├── brief.tscn / .gd              (objective + requirements)
│   │   ├── designer.tscn / .gd           (parts, launcher, fuel slider, live bars)
│   │   ├── review.tscn / .gd             (issues + 4 role sign-offs + Launch)
│   │   ├── launch.tscn / .gd             (short launch/trip animation)
│   │   ├── report.tscn / .gd             (result, why, NASA match)
│   │   └── ending.tscn / .gd
│   ├── components/        (resource_bar, part_card, issue_row, dialogue_box, ozone_meter)
│   └── theme/             (dawn_theme.tres, fonts from assets/)
│
├── data/                  ← format: SUFI · content: WAM / DINO
│   ├── acts.json
│   ├── missions.json
│   ├── parts.json
│   ├── launchers.json
│   ├── dialogue.json
│   └── real_missions.json
│
├── assets/                ← WAFI
│   ├── art/  ui/  audio/  fonts/
│   └── CREDITS.md
│
├── tests/                 ← SUFI
│   └── run_tests.gd
│
└── docs/
    ├── STORY.md           ← WAM
    ├── SOURCES.md         ← DINO
    └── HANDOFF.md         ← session log between Sufi and Zaliq
```

---

## 4. Sufi: Engine (Claude Code)

**You own:** `engine/`, `tests/`, and the shape of every JSON file in `data/`.
**You never:** create or edit `.tscn` files, touch `ui/`, or edit `project.godot` (ask Imran for autoload changes).

**Your first tasks, in order:**
1. **10:15–10:45 · Stub engine, push fast.** `engine/game_engine.gd` already returns fake results matching `CONTRACT.md`. Make sure it runs, then push so Zaliq can build against it. Imran registers it as autoload `GameEngine`.
2. **Data loading.** `data_loader.gd` reads the 6 JSON files; `get_parts()`, `get_mission()`, `get_acts()` return real data.
3. **Readiness checks** (`checks.gd`): budget, launcher capacity, power balance, battery through eclipse/night, required part categories, downlink, radiation, role sign-off. Every issue has `message` with real numbers and a `fix`.
4. **Simulation + report** (`simulate.gd`, `report.gd`): requirement results, why-lines, score, real mission match.
5. **Fuel guess** for trips (Act 2+): hidden `fuel_needed_kg`, range narrows after each attempt.
6. **Game state** (`game_state.gd`): act progress, unlocks, ozone meter, credits, optionals done, ending.
7. **Tests** in `tests/run_tests.gd` for every rule. Run: `godot --headless --path . -s res://tests/run_tests.gd`

**Rules:** deterministic (same design → same result). Engine is pure GDScript (`RefCounted` classes + the autoload); no nodes, no scenes, no UI text formatting beyond the strings in results.

---

## 5. Zaliq: Interface (Codex)

**You own:** everything in `ui/`.
**You never:** do game maths (no mass/power/score calculations in UI; ask the engine), edit `engine/`, `tests/` or `project.godot`.

**Your first tasks, in order:**
1. **10:15–10:45 · With Imran:** confirm the Godot project opens, `main.tscn` runs, Web export works on itch.io with an empty screen.
2. **Screens against the fake engine**, in this order, following Imran/Wafi's wireframes: `title` → `brief` → `designer` → `review` → `report`. Then `story`, `mission_select`, `launch`, `ending`.
3. **Designer:** part list grouped by category, selected parts, launcher picker, fuel slider (trips only), live resource bars from `GameEngine.check_design()` (call it on every change).
4. **Review:** list `issues` (blocker red, warning amber, info grey) with fix text; 4 role sign-off buttons; Launch disabled while any blocker or missing sign-off.
5. **Report:** outcome banner, each requirement ✓/✗ with detail, why-lines, real NASA mission card, buttons Redesign / Continue.
6. **Story screen:** plays a dialogue sequence by key from `GameEngine.get_dialogue(key)`.
7. Apply Wafi's theme once the style guide lands (~11:30).

**Rules:** call only the functions in `CONTRACT.md`. Prefer building UI nodes in code inside each screen's `.gd`; keep `.tscn` files small. Every status uses icon + text, not colour only. Test with F5 and once per sprint with Run in Browser.

---

## 6. How the two of you work together

**The two AIs never talk directly. They talk through the repo.**

| Channel | Use |
|---|---|
| `CONTRACT.md` | The agreed functions and data shapes. Changes need both of you + Imran to agree (1 min chat), then Sufi updates it in a PR. |
| `docs/HANDOFF.md` | End of every session: what you changed, what the other side must know. Start of every session: read the last 3 entries. |
| GitHub Issues | Requests to the other side. Label `engine` or `ui`. Never edit their files to "help". |

### Session start prompt (paste every time)
> Pull the latest main. Read CLAUDE.md (or AGENTS.md), CONTRACT.md, HANDOVER.md §4/§5 for my role, and the last 3 entries of docs/HANDOFF.md. Run `gh issue list --label engine` (Sufi) / `--label ui` (Zaliq). Summarise what changed and what is being asked of me. Then wait.

### Task prompt pattern
> Work on issue #N: <one small feature>. Only edit <my folders>. Show me the plan before writing code. When done, <run tests / tell me what to check with F5>.

### Need something from the other side
> Don't change their code. Open a GitHub issue with label `<engine|ui>` describing exactly the function/field and shape I need.

### Session end prompt
> Run the tests. Add an entry to docs/HANDOFF.md (done / for the other side / open questions). Commit, push this branch, open a PR with a clear description and "Closes #N".

### Git rules
- Never commit to `main`. One branch per task: `engine/battery-check`, `ui/review-screen`.
- Pull `main` before every session.
- Small PRs. Imran merges at every sync: **engine first, then ui**.
- Merge conflict → fix together with Imran on one screen. Don't let the AI resolve it alone.
- Commit after every working feature so a bad AI session can be undone with `git checkout .`.
- New AI chat per task; if the AI goes wrong twice, reset and give a smaller task.

---

## 7. Rhythm for the weekend

| Time | Sync | Expected state |
|---|---|---|
| 10:15 | Kick-off done | Stub engine pushed, Godot project + web export tested |
| 13:00 | Sync 1 | Designer + review screens show fake data; data loader real |
| 16:00 | Sync 2 | Real checks in review screen |
| 19:00 | Sync 3 | **Act 1 playable end to end** |
| 22:00 | Sync 4 | Act 2 trips + fuel guess working |
| 01:00 | Sync 5 | Act 2 complete → sleep shifts |
| 09:00 Sun | Sync 6 | Optionals A + D, story screens for Acts 3–5 |
| 12:00 Sun | **Feature freeze** | Bugs and polish only |
| ~17:00 Sun | Final build | Imran uploads, tags `v-final` |

Every sync: 10 min, play the merged build on the TV, each says done / next / blocked, Imran picks next issues.

---

## 8. Definition of done (for any task)

- Works in the merged build (F5), not only on your branch
- No errors in the Godot output panel
- Tests pass (engine)
- HANDOFF.md entry written
- Merged by Imran
