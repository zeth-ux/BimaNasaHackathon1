# Project Dawn

**Design real space missions. Heal the sky. Bring humanity home.**

A space mission design game for the **2026 NASA Space Apps Challenge** · Challenge: **Space Mission Design Game** · Seoul, 14–15 November 2026

| | |
|---|---|
| ▶ **Play in your browser** | _itch.io link (added at submission)_ |
| 🎬 **Demo video** | _link (added at submission)_ |
| 🛠 **Engine** | Godot 4 (GDScript), web export |
| 👥 **Players** | 1–4 (solo or local co-op) |

---

## The problem

Space missions are a chain of trade-offs. A better instrument adds mass, power use, data and cost. More mass needs more fuel. Farther worlds get less sunlight. Students usually learn these topics one at a time (an orbit lesson, a rocket lesson, a budget lesson) and rarely get to make the whole set of linked decisions themselves. As the challenge puts it, students "rarely get to experiment with an entire mission from concept to operation."

## Our solution

Project Dawn puts players in charge of a whole mission team. Every objective in the story is a **design brief with real requirements**. Players build a spacecraft, pass a readiness review, launch, and get a report that explains **why** the mission succeeded or failed. Then they redesign and try again.

There is never one perfect answer. A cheap design and an expensive one can both succeed, for different reasons, and a design can launch but still fall short of its science goals.

---

## The story

A gamma-ray burst from a distant dying star damages Earth's ozone layer, and deadly ultraviolet light floods the surface. *(This is based on a real scientific hypothesis: some researchers have proposed that a burst like this damaged the ozone layer about 440 million years ago and contributed to the Ordovician mass extinction.)*

Humanity survives underground in scattered bunkers. In **Bunker 4**, four scientists start **Project Dawn**: protect Earth from space while the ozone layer heals itself, and help every bunker survive until people can walk outside again.

They are guided by **CERES**, the bunker's mission-control AI, named after the dwarf planet visited by NASA's real Dawn spacecraft.

**Theme:** every technology built for the rocket becomes a gift to the people in the bunkers, just as NASA "spinoffs" improve everyday life on Earth.

| Act | Title | World | Big objective |
|---|---|---|---|
| 1 | First Light | Earth | Learn how bad the sky really is |
| 2 | Water Above Us | Moon | Find fuel beyond Earth |
| 3 | The Moon Factory | Moon | Build the shield |
| 4 | The Red Teacher | Mars | Learn to live under a broken sky |
| 5 | Dawn | Mars → Earth | Bring humanity back to the surface |

Ten optional **"Helping Humanity"** missions (communication relays, a space-weather satellite, farming and disaster-watch satellites, planetary defense and more) reuse the technology from the main story to help the bunkers. How many the team completes decides the ending: **Quiet Dawn**, **Rising Dawn** or **Golden Dawn**.

---

## How to play

1. **Read the brief.** Each objective comes with a story and 3–5 requirements, e.g. *"Carry a UV sensor · Stay powered through 36 minutes of Earth's shadow · Send home at least 5 MB per day · Stay within 200 credits."*
2. **Design the spacecraft.** Pick a frame, computer, instruments, power, batteries, radio and launcher. Live bars show mass, cost, power, battery energy and data.
3. **Pass the Readiness Review.** CERES lists every problem with the real numbers and a suggested fix: *"Battery too small: needs 2.7 Wh for 36 min of shadow, has 1.5 Wh."* Each of the four roles must sign off before launch.
4. **Launch.** For trips to the Moon and Mars, the Navigator sets the fuel load. The exact amount needed is hidden and shown only as a range that narrows with every attempt.
5. **Read the Mission Report.** Each requirement is marked met or missed, with the reason, a score, and the **real NASA mission** your design is closest to.
6. **Redesign or continue.** Fix one thing and fly again, or move on with the story.

### The four roles

| Role | Decides | NASA mission segment |
|---|---|---|
| **Engineer** | Spacecraft parts, structure, total mass | Space segment |
| **Scientist** | Instruments and research | User segment |
| **Navigator** | Trajectory, fuel, launch window | Launch segment |
| **Quartermaster** | Budget, power, resources, the bunker network | Ground segment |

In **solo mode** one player runs all four roles. In **co-op (2–4 players)** each player owns a role, and all of them must sign off before every launch, as real mission teams do in a readiness review.

### Controls

| Action | Mouse / keyboard |
|---|---|
| Select a part, button or option | Left click |
| Advance dialogue | Click or Space |
| Back | Esc |

---

## What players learn

| In the game | Real concept |
|---|---|
| Mass vs. launcher capacity and fuel | The rocket equation and the delta-v budget |
| Battery through Earth's shadow or the lunar night | Power vs. energy; eclipses |
| Data generated vs. radio link | Data volume vs. downlink capacity |
| Solar output falling at farther worlds | The inverse-square law of sunlight |
| Readiness review and role sign-off | NASA's gated mission reviews |
| Flyby → orbiter → lander → outpost | How NASA explored the Moon and Mars, step by step |
| Fuel range narrowing after each attempt | Estimation and iteration in mission design |

---

## NASA data and resources

The game follows NASA's own mission design process from the challenge resources:

- **Design and Develop Science Missions** (NASA SmallSat webinar): the four mission segments become the four player roles; "begin with the end in mind" shapes every brief.
- **JPL Concept Maturity Levels**: the scouting trips move a world from a rough idea to a point design.
- **CubeSat 101** (NASA CubeSat Launch Initiative) and the **Goddard Mission Design Lab**: the readiness review and role sign-off before every launch.
- **NASA Webb "Build It Yourself"**: each report matches your design to a real NASA mission.
- **State-of-the-Art of Small Spacecraft Technology** (NASA): reference values for spacecraft parts.

**Real NASA science and missions in the story:**

| Story element | Real basis |
|---|---|
| Ozone damage from a gamma-ray burst | Ordovician extinction hypothesis |
| The ozone layer heals once the cause stops | Montreal Protocol recovery: projected around 2040, around 2066 over Antarctica |
| Smartphone CubeSat | NASA PhoneSat; CubeSat Launch Initiative |
| Water ice for rocket fuel | Ice in permanently shadowed craters near the lunar south pole |
| Asteroid deflection | NASA DART (2022) |
| How Mars lost its atmosphere | NASA MAVEN |
| Oxygen from Martian air | MOXIE on the Perseverance rover |
| Dust storm danger to solar power | Opportunity rover, ended by a 2018 dust storm |
| The Mars methane mystery | Methane spikes measured by Curiosity |

Full source list with links: [`docs/SOURCES.md`](docs/SOURCES.md).

### Honesty note

All costs, masses, power values, limits and scores are **simplified game values** unless `docs/SOURCES.md` lists a real reference for them. The **space UV shield is game fiction**, inspired by real proposals for space sunshades; no such network exists. Everything else in the story is grounded in real science and real NASA missions.

---

## Run it locally

1. Install **Godot 4.7** (standard edition, not .NET).
2. Clone this repository.
3. Open Godot → **Import** → select `project.godot`.
4. Press **F5** to play.

Run the engine tests:

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

### Web build

Project → Export → **Web** preset (Thread Support **off**) → export to `build/web/` → zip the folder contents → upload to itch.io as an HTML game.

---

## Project structure

```
engine/   game logic: checks, simulation, reports, game state (GameEngine autoload)
ui/       all screens and UI components
data/     acts, missions, parts, launchers, dialogue, real NASA missions (JSON)
assets/   art, UI, audio, fonts (credits in assets/CREDITS.md)
tests/    headless engine tests
docs/     story, sources, developer handoff log
```

Developers: start with [`HANDOVER.md`](HANDOVER.md) and [`CONTRACT.md`](CONTRACT.md).

---

## Team

| Member | Role |
|---|---|
| **Imran** | Team lead, integration, deployment |
| **Sufi** | Engine developer (game logic and simulation) |
| **Zaliq** | Interface developer (screens and UI) |
| **Wam** | Story writer |
| **Dino** | Research and NASA data |
| **Wafi** | Visuals, art and video |

---

## Use of AI

We used AI coding assistants (Claude Code and Codex) to help write and debug code, under rules in `CLAUDE.md` / `AGENTS.md`: every change was reviewed and tested by a team member before merging. AI was also used for planning and brainstorming. All story concepts, game design decisions and NASA fact-checking were done by the team. Any AI-generated images are marked with a visible "AI-generated" label. _(Final details to be confirmed at submission.)_

## Credits and license

- Third-party assets and their licenses: [`assets/CREDITS.md`](assets/CREDITS.md)
- Code license: MIT _(to be confirmed before submission)_
- Project Dawn is a fan-made educational project for NASA Space Apps and is not endorsed by NASA.