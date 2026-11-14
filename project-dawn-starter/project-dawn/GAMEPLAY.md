# Project Dawn: Gameplay & Game Flow

How the game actually plays, built on Wam's storyline (`docs/STORY.md`, v2).
Audience: Sufi (engine), Zaliq (interface), Wam (content), Dino (values).
All numbers here are **starting game values** for balance; Dino replaces any that should be real.

---

## 1. One sentence

Every objective in the story is a **launch**: the team reads a brief, designs a vehicle, passes a readiness review, flies it through whatever space throws at it, and reads a report that explains why it worked. Then the story moves on.

---

## 2. Game flow

```
TITLE
  └─► NEW GAME: players (1–4) pick roles
        └─► STORY (Act intro, CERES + scientists)
              └─► MISSION CONTROL (hub)  ◄──────────────────────────────┐
                    │  ozone meter · credits · act · mission board          │
                    ├─► pick a main objective or an unlocked optional       │
                    ▼                                                       │
                  BRIEF  (story lines + requirements + conditions)          │
                    ▼                                                       │
                  DESIGNER  (parts · launcher · fuel · live resource bars)  │
                    ▼                                                       │
                  READINESS REVIEW  (CERES issues · 4 role GO/NO-GO)        │
                    │  blocker? ──► back to DESIGNER                        │
                    ▼  all GO                                               │
                  FLIGHT  (phases · event card if the act has a disaster)   │
                    ▼                                                       │
                  REPORT  (requirements ✓/✗ · why · score · NASA match)     │
                    ├─► Redesign ──► DESIGNER (design kept)                 │
                    └─► Continue ──► STORY (success lines) ─────────────────┘
                                         │ both main objectives of an act done
                                         ▼
                                   ACT OUTRO → next act … Act 5 done → ENDING
```

---

## 3. Screens

| # | Screen | Purpose | Main elements |
|---|---|---|---|
| S1 | Title | Start | Logo, New game, Continue, Judge mode (unlock all acts) |
| S2 | Crew setup | Assign roles | 1–4 player slots; each claims Engineer / Scientist / Navigator / Quartermaster; solo = one player all roles |
| S3 | Story | Narrative | Background art, speaker portrait, dialogue box, Next / Skip |
| S4 | Mission Control (hub) | Choose what to do | Ozone meter, credits, act banner, mission board (main + optional cards), CERES tip |
| S5 | Brief | Understand the goal | Objective, destination, conditions (eclipse/night, sunlight, radiation), requirements checklist, budget, "Start design" |
| S6 | Designer | Make trade-offs | Role tabs → part catalog; vehicle slots; launcher picker; fuel slider (trips); live resource bars; requirement preview |
| S7 | Readiness Review | Gate before launch | CERES issue list (blocker/warning/info, numbers + fix); 4 role cards GO/NO-GO; Launch button |
| S8 | Flight | Payoff + events | Phase track (Liftoff → Stage separation → Cruise → Arrival/Landing); live gauges; event card pauses flight |
| S9 | Report | Learning | Outcome banner, score, requirements ✓/✗ with detail, why-lines, fuel feedback, NASA mission match, rewards, Redesign / Continue |
| S10 | Ending | Close the story | Quiet / Rising / Golden Dawn by optionals completed; final stats |

---

## 4. The four roles

Every part category and every review check belongs to one role. In co-op only that role's player edits its tab and signs its GO. In solo, one player does all four.

| Role | Designer tab (owns) | Guards | Review sign-off checks |
|---|---|---|---|
| **Engineer** | Structure, propulsion stage, landing gear, protection (heat shield, radiation shelter) | Mass | Mass vs launcher; required hardware present; heat shield / shelter where needed |
| **Scientist** | Instruments | Science | Required instruments present; science target met |
| **Navigator** | Launcher, destination, **fuel load** | Fuel / trajectory | Launcher reaches destination; fuel within range |
| **Quartermaster** | Power, batteries, radio, budget | Power, energy, data, money | Power positive; battery covers the dark period; downlink ≥ data; cost ≤ budget |

Co-op twist: each role also has a **secret priority** shown only to them at the brief (e.g. Quartermaster: "finish with ≥ 20% budget left"; Scientist: "fly 2 instruments"). Meeting all four gives the Teamwork bonus.

---

## 5. Core mechanics

### 5.1 Resources (live bars in the Designer)

| Resource | Shown as | Rule |
|---|---|---|
| Mass | total kg / launcher capacity kg | Over = blocker |
| Budget | credits spent / mission budget | Over = blocker |
| Power | generated W / used W | Used > generated = blocker. Solar × `sunlight_factor` (Earth/Moon 1.0, Mars 0.43) |
| Energy | battery Wh / needed Wh | needed = power used × dark minutes ÷ 60. Short = blocker |
| Data | data MB/day / downlink MB/day | Data > downlink = warning; science scaled by downlink ÷ data |
| Fuel (trips only) | fuel kg vs hidden need | See 5.2 |
| Radiation | part tolerance vs destination | Too low = warning, becomes damage in a storm event |

### 5.2 Fuel guess (Navigator)

Trips to the Moon and Mars hide the exact fuel needed (`fuel_needed_kg`, grows with vehicle mass). The Navigator sees a range that narrows.

- **Too little:** mission fails at the step it runs out (e.g. "reached lunar orbit, could not land"). Partial data returns; range narrows (lower bound = what you carried).
- **Within 10%:** bonus score "Efficient trajectory".
- **Too much:** extra fuel adds mass and cost; may exceed the launcher.

Teaches the rocket equation by feel: carrying more fuel makes the vehicle heavier, which needs more fuel.

### 5.3 Event cards (the act's disaster)

Some missions pause mid-flight with a card: a short situation, 2–3 choices, each with a visible trade-off. The result is deterministic given the design (e.g. radiation-tolerant parts survive "continue").

| Act | Event | Choices | Design that saves you |
|---|---|---|---|
| 1 | UV storm | Safe mode (lose 1 day of data) · Continue (computer reset unless shielded) | Radiation-tolerant computer |
| 2 | Solar particle storm | Shelter crew systems (power drain) · Continue | Radiation shelter + battery margin |
| 3 | Asteroid detected | Ignore (unlock optional G as urgent) · Track it (costs science time) | — (story trigger) |
| 4 | Global dust storm | Hibernate (lose sols) · Keep working (battery drains) | Big battery or RTG |

### 5.4 Requirements and outcome

Each mission lists 3–5 requirements. After flight:
- **Success:** all requirements met
- **Partial:** launched and arrived, but ≥ 1 science requirement missed (story continues, lower score)
- **Failed:** vehicle lost or a critical requirement missed (redesign to continue)

### 5.5 Score (0–1000, shown in the report)

| Part | Points |
|---|---|
| Requirements met | 500 |
| Margins (10–30% spare mass, power, energy) | 150 |
| Budget left | 150 |
| Science returned | 100 |
| Fuel accuracy (trips) / event handled well | 100 |

### 5.6 Progression

- **Credits:** each success pays credits; budgets grow by act.
- **Unlocks ("spinoffs"):** each main objective unlocks parts *and* the optionals listed in the story. The hub shows what each new part makes possible.
- **Ozone meter (0–100%):** starts 8%. Acts 1–2 objectives +4 each (measuring, not fixing); shield launches (3.2, 5.2) +25 / +35; optionals +2 each. Reaching the end of 5.2 always opens the doors; the meter's final value shows on the ending screen.
- **Launch sites:** Earth spaceport (Acts 1–2) → Moon port unlocked by 3.1 (much lower fuel needs) → Mars surface for 5.1.

### 5.7 Endings

Count optionals completed: 0–3 Quiet Dawn · 4–7 Rising Dawn · 8–10 Golden Dawn.

---

## 6. Mission by mission

Format: **what you launch · key trade-off · requirements · event · teaches · NASA match · unlocks**

### Act 1: First Light (Earth)

**1.1 Launch a sounding rocket** *(tutorial; one role at a time, CERES walks through each tab)*
- Vehicle: small rocket body + solid motor + UV sensor + recovery parachute or radio.
- Trade-off: heavier payload → lower top altitude; Navigator picks propellant to reach ≥ 100 km.
- Requirements: reach ≥ 100 km · carry UV sensor · return data (parachute recovery or radio).
- Teaches: mass vs fuel, suborbital vs orbital.
- NASA match: NASA Sounding Rocket Program. Unlocks: CubeSat parts, optional **B Platform Shield**.

**1.2 Launch the first CubeSat into orbit**
- Vehicle: 1U/3U frame + phone computer + UV spectrometer + solar + battery + radio, on a rideshare.
- Trade-off: battery vs mass; radio power vs downlink.
- Requirements: UV sensor · survive 36 min of Earth's shadow each orbit · downlink ≥ 5 MB/day · cost ≤ budget.
- Event: UV storm.
- Teaches: power vs energy, eclipse, data vs downlink.
- NASA match: PhoneSat. Unlocks: S-band radio, optional **A Bunker Link**. **Ozone meter starts.**

*Act 1 outro (story turn): "Then don't build it here. Build it where leaving is easy."*

### Act 2: Water Above Us (Moon)

**2.1 Launch the Moon scouts**: three linked trips; each success reveals the next step.
| Trip | Vehicle | Requirement highlights | Reveals |
|---|---|---|---|
| Flyby | Small probe, camera | Reach the Moon (fuel guess starts) | Rough fuel range, south pole location |
| Orbiter | Probe + thermal/neutron instrument | Enter lunar orbit; detect cold traps | Where ice is (shadowed craters) |
| Lander | Lander + legs + battery | Land softly; survive local night | Rim vs crater floor conditions |
- Teaches: staged exploration, delta-v, why landers are heavy. NASA match: LRO / LCROSS. Unlocks: outpost parts.

**2.2 Launch the outpost lander**
- Vehicle: heaviest yet: lander + ice drill + ice splitter + power + shelter, on the bigger launcher.
- Choice in Designer: landing site **sunlit rim** (solar works, ice nearby) vs **crater floor** (ice right there, no sunlight → power blocker unless RTG).
- Requirements: land the drill and splitter · power positive at the site · radiation shelter.
- Event: solar particle storm.
- Teaches: site selection, in-situ resource use, radiation without air or magnetic field.
- NASA match: ice in permanently shadowed craters; ISRU plans. Unlocks: Moon fuel, optionals **C Water for All**, **D Storm Watch**.

### Act 3: The Moon Port (Moon)

**3.1 First launch from the Moon**
- Vehicle: small test rocket launched **from the lunar surface** to lunar orbit using Moon-made fuel.
- Report shows the comparison: "The same trip from Earth would need about N× more fuel."
- Requirements: reach lunar orbit · use Moon fuel · within budget.
- Teaches: gravity and delta-v; why launch sites matter.
- Unlocks: Moon port as a launch site; optional **G Planetary Defense**.

**3.2 Launch the first shield satellites**
- Vehicle: shield satellite design, launched from the Moon port toward the point between the Sun and Earth. Players choose **how many** satellites (cost × count) vs coverage %.
- Requirements: coverage ≥ 30% · each satellite power-positive and radiation-tolerant · within budget.
- Event: asteroid detected (story trigger for G).
- Teaches: constellations, the Sun–Earth line, trading count vs capability.
- Fiction note shown in the report: the shield is game fiction inspired by real sunshade proposals. Unlocks: optionals **E Harvest Eye**, **F Disaster Watch**. **Ozone meter +25.**

*Act 3 outro: "Earth's sky now looks like Mars's sky… Let's learn from it."*

### Act 4: The Red Teacher (Mars)

**4.1 Launch the Mars scouts**: flyby → orbiter → lander, as in 2.1, with Mars rules:
- Sunlight × 0.43 (bigger panels); entry needs a **heat shield**; lander battery must cover a ~12-hour night; info card on radio delay (minutes each way).
- NASA match: MAVEN (atmosphere loss). Unlocks: greenhouse parts, optional **J Mars Mystery**.

**4.2 Launch the greenhouse lander**
- Vehicle: lander + heat shield + UV-filtering dome + oxygen maker (MOXIE-style) + power.
- Requirements: land safely · keep crops powered through the night · produce oxygen.
- Event: global dust storm (solar drops to near zero for several sols).
- NASA match: MOXIE; Opportunity 2018. Unlocks: optional **H Greenhouse for Every Bunker**.

### Act 5: Dawn (Mars → Earth)

**5.1 Launch home from Mars**
- Vehicle: Mars ascent rocket fuelled on site, carrying seeds and samples. Fuel guess again, now with Mars gravity.
- Requirements: reach Mars orbit · cargo mass ≥ target · survive the trip home.
- Unlocks: optional **I Pathfinder**.

**5.2 Launch the final shield satellites**
- As 3.2 at larger scale (coverage ≥ 80%) from the Moon port, with every upgrade unlocked.
- Success → final story → **Ending** by optionals completed. **Ozone meter +35.**

---

## 7. Optional objectives (same designer, new briefs)

| # | What you launch | Key requirement | Unlocked by |
|---|---|---|---|
| A Bunker Link | Comms relay satellite(s) | Downlink + coverage of all bunkers | 1.2 |
| B Platform Shield | UV canopy (one-choice mission) | Spend credits/material | 1.1 |
| C Water for All | Ice-cleaning kit delivery (choice) | Spend Moon resources | 2.2 |
| D Storm Watch | Space-weather satellite | Particle sensor + radiation-tolerant parts | 2.2 |
| E Harvest Eye | Farming/weather satellite | Camera + sun-synchronous orbit | 3.2 |
| F Disaster Watch | Disaster-detection satellite | Radar or thermal camera + fast downlink | 3.2 |
| G Planetary Defense | DART-style impactor | Impactor mass × speed; fuel guess; deadline | 3.1 |
| H Greenhouse for Every Bunker | Design delivery to Earth (choice) | — | 4.2 |
| I Pathfinder | Navigation satellite constellation | Number of satellites × coverage | 5.1 |
| J Mars Mystery | Methane investigation lander | Spectrometer + **sterilization** choice → honest "inconclusive" or contamination result | 4.1 |

Choice missions (B, C, H) use the `choice` mission kind: one decision screen, no designer.

---

## 8. Build order (all of the above lives in data; build the systems once)

| Order | Systems | Content that becomes playable |
|---|---|---|
| 1 | Hub, Brief, Designer, Review, Report, Story screens · resources 5.1 · score | 1.1, 1.2 |
| 2 | Fuel guess 5.2 · multi-trip missions · event cards 5.3 | 2.1, 2.2, optional D |
| 3 | Launch-site switch · satellite count (constellations) | 3.1, 3.2, A, E, F, G, I |
| 4 | Sunlight factor, heat shield, night length (already data-driven) | 4.1, 4.2, 5.1, 5.2, J |
| 5 | Choice missions, ending screen, judge mode | B, C, H, endings |

Anything not yet built plays as a story screen so the game always runs from title to ending.
