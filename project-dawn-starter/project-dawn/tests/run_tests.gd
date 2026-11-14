extends SceneTree
## Engine tests. Owner: Sufi.
## Run: godot --headless --path . -s res://tests/run_tests.gd

var _fails := 0
var _passes := 0

func _init() -> void:
	var eng = load("res://engine/game_engine.gd").new()
	eng._ready()

	_check(eng.get_acts().size() == 5, "5 acts load")
	_check(not eng.get_mission("m1_2_ozone_cubesat").is_empty(), "mission m1_2 loads")
	_check(eng.get_mission("does_not_exist").is_empty(), "unknown mission returns empty")
	_check(eng.get_parts("m1_2_ozone_cubesat").size() > 0, "starting parts unlocked")

	var empty: Dictionary = eng.check_design("m1_2_ozone_cubesat", {"parts": [], "signoffs": {}})
	_check(not empty["ok"], "empty design is blocked")

	var design := {
		"parts": ["frame_1u", "phone_computer", "uv_sensor", "solar_body", "battery_medium", "radio_uhf"],
		"launcher": "rideshare_small", "fuel_kg": 0,
		"signoffs": {"engineer": true, "scientist": true, "navigator": true, "quartermaster": true}}
	var check: Dictionary = eng.check_design("m1_2_ozone_cubesat", design)
	_check(is_equal_approx(check["totals"]["mass_kg"], 1.2), "mass totals 1.2 kg")

	eng.make_choice("m1_1_launch_site", "site_bunker")
	var result: Dictionary = eng.run_mission("m1_2_ozone_cubesat", design)
	_check(result["outcome"] == "success", "valid design launches (stub)")
	_check(eng.get_state()["ozone"] == 15, "ozone meter rises by reward")

	print("\n%d passed, %d failed" % [_passes, _fails])
	eng.free()
	quit(1 if _fails > 0 else 0)

func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("  PASS  " + label)
	else:
		_fails += 1
		print("  FAIL  " + label)
