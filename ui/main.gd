extends Control
## Main scene. Owner: Zaliq. PLACEHOLDER: proves GameEngine is wired up.
## Replace with the screen switcher (title → brief → designer → review → report).

func _ready() -> void:
	var label := Label.new()
	var state: Dictionary = GameEngine.get_state()
	var acts: Array = GameEngine.get_acts()
	label.text = "PROJECT DAWN\nEngine connected · %d acts loaded · ozone %d%% · %d credits" % [acts.size(), state["ozone"], state["credits"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
