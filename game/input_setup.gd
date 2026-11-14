extends RefCounted
## Local-multiplayer keyboard controls, created in code at startup.
## Owner: Sufi (gameplay). Change key bindings in BINDINGS only.
##
## Creates: p1_up, p1_down, p1_left, p1_right, p1_interact ... p4_interact
## Usage:   InputSetup.ensure()   (safe to call many times)

const MAX_PLAYERS := 4
const VERBS := ["up", "down", "left", "right", "interact"]

## Physical key positions, so they work the same on QWERTY, Korean, AZERTY...
const BINDINGS := {
	0: {"up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "interact": KEY_E},
	1: {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "interact": KEY_SLASH},
	2: {"up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L, "interact": KEY_O},
	3: {"up": KEY_KP_8, "down": KEY_KP_5, "left": KEY_KP_4, "right": KEY_KP_6, "interact": KEY_KP_0},
}

## Labels for the HUD / tutorial.
const LABELS := {0: "WASD + E", 1: "Arrows + /", 2: "IJKL + O", 3: "Numpad 8456 + 0"}


static func action(player: int, verb: String) -> String:
	return "p%d_%s" % [player + 1, verb]


## Adds any missing actions. Never changes existing ones, so a binding can
## still be overridden in the Input Map if needed.
static func ensure() -> void:
	for p in BINDINGS:
		for verb in VERBS:
			var name := action(p, verb)
			if InputMap.has_action(name):
				continue
			InputMap.add_action(name, 0.2)
			var ev := InputEventKey.new()
			ev.physical_keycode = BINDINGS[p][verb]
			InputMap.action_add_event(name, ev)
