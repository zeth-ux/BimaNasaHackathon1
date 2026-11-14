# CONTRACT: Engine ↔ Interface

**This file is the agreement between Sufi (engine) and Zaliq (interface).**
Change it only after both agree with Imran. Sufi edits it in a PR and logs the change in `docs/HANDOFF.md`.

All numbers in data files are **game values** unless `source` points to a real reference in `docs/SOURCES.md`.

---

## 1. The API (autoload `GameEngine`, file `engine/game_engine.gd`)

The interface calls **only** these. All take/return plain `Dictionary` / `Array` / `String` / `int` / `float`.

```gdscript
# --- setup / state ---
func new_game() -> void
func get_state() -> Dictionary                 # §3.1
signal state_changed(state: Dictionary)

# --- content ---
func get_acts() -> Array                        # [Act] §2.1, with per-mission status
func get_mission(mission_id: String) -> Dictionary   # Mission §2.2
func get_available_missions() -> Array          # [Mission] the player can start now
func get_parts(mission_id: String) -> Array     # [Part] §2.3 unlocked AND allowed for this mission
func get_launchers(mission_id: String) -> Array # [Launcher] §2.4
func get_dialogue(key: String) -> Array         # [Line] §2.5

# --- core loop ---
func check_design(mission_id: String, design: Dictionary) -> Dictionary  # CheckResult §3.2
func run_mission(mission_id: String, design: Dictionary) -> Dictionary   # MissionResult §3.3
# run_mission updates game state itself when the mission succeeds, then emits state_changed.
# If check_design has any blocker, run_mission returns outcome "blocked" and changes nothing.

# --- story choices (e.g. Act 1.1 launch site) ---
func make_choice(mission_id: String, choice_id: String) -> Dictionary   # MissionResult §3.3
```

### Design (what the UI sends)

```json
{
  "parts": ["frame_1u", "phone_computer", "uv_sensor", "solar_body", "battery_small", "radio_uhf"],
  "launcher": "rideshare_small",
  "fuel_kg": 0,
  "signoffs": { "engineer": true, "scientist": true, "navigator": true, "quartermaster": true }
}
```
- `parts`: part ids; the same id may appear more than once (e.g. 2 batteries).
- `fuel_kg`: only used when the mission has `fuel` (trips). 0 otherwise.
- `signoffs`: UI sets these from the Review screen buttons. Missing sign-off = blocker.

---

## 2. Data files (`data/*.json`), format owned by Sufi

### 2.1 `acts.json`
```json
[
  { "id": "act1", "number": 1, "title": "First Light", "world": "earth",
    "big_objective": "Learn how bad the sky really is.",
    "intro_dialogue": "act1_intro", "outro_dialogue": "act1_outro",
    "missions": ["m1_1_launch_site", "m1_2_ozone_cubesat"],
    "optionals": ["opt_a_bunker_link", "opt_b_platform_shield"] }
]
```

### 2.2 `missions.json`
```json
[
  {
    "id": "m1_2_ozone_cubesat",
    "act": "act1",
    "objective_ref": "1.2",
    "kind": "design",                         // "design" | "choice" | "story"
    "optional": false,
    "title": "Launch the first CubeSat",
    "world": "earth",
    "stage": "satellite",                     // satellite | flyby | orbiter | lander | rover | outpost
    "brief_dialogue": "m1_2_brief",
    "summary": "Build a tiny satellite from salvaged parts and map the ozone damage.",
    "unlock_after": ["m1_1_launch_site"],
    "budget": 200,
    "eclipse_minutes": 36,                    // longest dark period the battery must cover
    "sunlight_factor": 1.0,                   // multiplies solar output at the target
    "radiation": "low",                       // low | medium | high
    "required_categories": ["structure", "computer", "instrument", "power", "battery", "comms"],
    "requirements": [
      { "id": "uv",       "type": "has_part_tag", "tag": "uv",       "label": "Carry a UV sensor" },
      { "id": "eclipse",  "type": "battery_eclipse",                  "label": "Stay powered through 36 min of Earth's shadow" },
      { "id": "downlink", "type": "min_downlink", "value": 5,        "label": "Send home at least 5 MB per day" },
      { "id": "budget",   "type": "within_budget",                    "label": "Stay within 200 credits" }
    ],
    "fuel": null,                             // trips: { "needed_kg": 313, "hint_min": 200, "hint_max": 450 }
    "choices": null,                          // kind "choice": [{ "id": "...", "label": "...", "result_dialogue": "..." }]
    "rewards": { "ozone": 5, "credits": 150, "unlock_parts": ["radio_sband"], "unlock_optionals": ["opt_a_bunker_link"] },
    "success_dialogue": "m1_2_success",
    "fail_dialogue": "m1_2_fail",
    "real_mission": "phonesat"
  }
]
```
Requirement `type` values the engine supports (Sufi may add more, log them here):
`has_part_tag` · `has_category` · `battery_eclipse` · `power_positive` · `min_downlink` · `within_budget` · `within_launcher` · `radiation_ok` · `fuel_enough` · `min_science`

### 2.3 `parts.json`
```json
[
  { "id": "uv_sensor", "name": "UV spectrometer", "category": "instrument", "tags": ["uv", "science"],
    "mass_kg": 0.4, "power_w": -2.0, "cost": 40,
    "battery_wh": 0, "downlink_mb_day": 0, "data_mb_day": 3, "science": 20,
    "radiation_tolerance": "low", "unlocked_at_start": true,
    "why": "Measures how much ultraviolet light reaches the instrument.",
    "real_ref": "Ozone instruments on NASA's Aura satellite", "source": "SOURCES.md#aura" }
]
```
- `power_w`: positive = produces (solar, RTG), negative = consumes. Solar output is multiplied by the mission's `sunlight_factor`.
- Categories: `structure` · `computer` · `instrument` · `power` · `battery` · `comms` · `propulsion` · `landing` · `protection` · `special`

### 2.4 `launchers.json`
```json
[ { "id": "rideshare_small", "name": "Salvaged rideshare", "capacity_kg": 50, "cost": 60, "worlds": ["earth"], "unlocked_at_start": true } ]
```

### 2.5 `dialogue.json`
```json
{
  "m1_2_brief": [
    { "speaker": "ceres", "text": "The sky is burning blue. We need numbers, not guesses." },
    { "speaker": "scientist", "text": "A UV sensor on a CubeSat would map the damage in days." }
  ]
}
```
Speakers: `ceres` · `engineer` · `scientist` · `navigator` · `quartermaster` · `narrator`. Portrait file = `assets/art/portrait_<speaker>.png`.

### 2.6 `real_missions.json`
```json
{ "phonesat": { "name": "NASA PhoneSat", "year": "2013", "fact": "Flew an off-the-shelf smartphone as the spacecraft's computer.", "url": "https://www.nasa.gov/..." } }
```

---

## 3. Return shapes

### 3.1 State (`get_state()`)
```json
{
  "act": "act1",
  "completed": ["m1_1_launch_site"],
  "optionals_done": [],
  "ozone": 12,                     // 0–100 meter
  "credits": 350,
  "unlocked_parts": ["..."],
  "unlocked_launchers": ["..."],
  "fuel_hints": { "m2_1_flyby": { "min": 260, "max": 380, "attempts": 1 } },
  "ending": ""                     // "" until the game ends: "quiet" | "rising" | "golden"
}
```

### 3.2 CheckResult (`check_design()`), call on every designer change
```json
{
  "ok": false,                                  // true = no blockers
  "totals":  { "mass_kg": 3.1, "cost": 185, "power_gen_w": 6.0, "power_use_w": 4.5,
               "battery_wh": 10, "battery_needed_wh": 2.7, "data_mb_day": 3, "downlink_mb_day": 8 },
  "limits":  { "mass_kg": 50, "cost": 200 },
  "issues": [
    { "id": "eclipse", "severity": "blocker",   // "blocker" | "warning" | "info"
      "role": "engineer",                       // engineer | scientist | navigator | quartermaster
      "message": "Battery too small: needs 2.7 Wh for 36 min of shadow, has 1.5 Wh.",
      "fix": "Add the medium battery or remove the camera." }
  ]
}
```

### 3.3 MissionResult (`run_mission()`, `make_choice()`)
```json
{
  "outcome": "success",                         // "success" | "partial" | "failed" | "blocked"
  "score": 820,                                 // 0–1000
  "requirement_results": [
    { "id": "eclipse", "label": "Stay powered through 36 min of Earth's shadow", "passed": true,
      "detail": "Battery 10 Wh vs 2.7 Wh needed (270% margin)." }
  ],
  "why_lines": [
    "Your solar panel produced 6 W against 4.5 W used, so the battery recharged every orbit.",
    "A 5 MB/day link was enough for the UV map."
  ],
  "fuel_feedback": null,                        // trips: { "status": "too_little|close|too_much", "new_min": 280, "new_max": 340 }
  "rewards_applied": { "ozone": 5, "credits": 150, "unlocked": ["radio_sband"] },
  "real_mission": { "name": "NASA PhoneSat", "fact": "...", "url": "..." },
  "next_dialogue": "m1_2_success"
}
```

---

## 4. Rules both sides follow

- UI never calculates game numbers; it displays what the engine returns.
- Engine never formats UI (no colours, no BBCode); it returns plain strings.
- Every user-visible number comes with its unit in the string or field name.
- Same design + same state → same result (no unseeded randomness).
- Unknown id → engine returns an empty Dictionary/Array and prints a warning; never crashes.

## 5. Change log
| Date / time | Change | By |
|---|---|---|
| 14 Nov 10:15 | v1 | Imran |
