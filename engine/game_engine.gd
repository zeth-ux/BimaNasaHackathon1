extends Node
## GameEngine autoload: the ONLY API the UI calls. See CONTRACT.md.
## Owner: Sufi (engine). STUB v0: content comes from data/*.json, but
## check_design / run_mission return FAKE results so the UI can be built now.
## Replace the fakes with checks.gd / simulate.gd / report.gd step by step.

signal state_changed(state: Dictionary)

var _data := {}        # "acts", "missions", "parts", "launchers", "dialogue", "real_missions"
var _state := {}


func _ready() -> void:
	_load_data()
	new_game()


# ---------------------------------------------------------------- setup / state

func new_game() -> void:
	_state = {
		"act": "act1",
		"completed": [],
		"optionals_done": [],
		"ozone": 10,
		"credits": 300,
		"unlocked_parts": _ids_where(_data.get("parts", []), "unlocked_at_start"),
		"unlocked_launchers": _ids_where(_data.get("launchers", []), "unlocked_at_start"),
		"fuel_hints": {},
		"ending": "",
	}
	state_changed.emit(_state.duplicate(true))


func get_state() -> Dictionary:
	return _state.duplicate(true)


# ---------------------------------------------------------------- content

func get_acts() -> Array:
	return _data.get("acts", []).duplicate(true)


func get_mission(mission_id: String) -> Dictionary:
	for m in _data.get("missions", []):
		if m["id"] == mission_id:
			return m.duplicate(true)
	push_warning("GameEngine: unknown mission " + mission_id)
	return {}


func get_available_missions() -> Array:
	var out := []
	for m in _data.get("missions", []):
		if m["id"] in _state["completed"]:
			continue
		var is_ready := true
		for req in m.get("unlock_after", []):
			if not (req in _state["completed"]):
				is_ready = false
		if is_ready:
			out.append(m.duplicate(true))
	return out


func get_parts(_mission_id: String) -> Array:
	var out := []
	for p in _data.get("parts", []):
		if p["id"] in _state["unlocked_parts"]:
			out.append(p.duplicate(true))
	return out


func get_launchers(_mission_id: String) -> Array:
	var out := []
	for l in _data.get("launchers", []):
		if l["id"] in _state["unlocked_launchers"]:
			out.append(l.duplicate(true))
	return out


func get_dialogue(key: String) -> Array:
	return _data.get("dialogue", {}).get(key, []).duplicate(true)


# ---------------------------------------------------------------- core loop (FAKE for now)

func check_design(mission_id: String, design: Dictionary) -> Dictionary:
	# FAKE: totals are summed for real; issues are placeholders.
	var totals := {"mass_kg": 0.0, "cost": 0, "power_gen_w": 0.0, "power_use_w": 0.0,
		"battery_wh": 0.0, "battery_needed_wh": 0.0, "data_mb_day": 0.0, "downlink_mb_day": 0.0}
	for pid in design.get("parts", []):
		var p := _find(_data.get("parts", []), pid)
		if p.is_empty():
			continue
		totals["mass_kg"] += p["mass_kg"]
		totals["cost"] += p["cost"]
		if p["power_w"] > 0:
			totals["power_gen_w"] += p["power_w"]
		else:
			totals["power_use_w"] += -p["power_w"]
		totals["battery_wh"] += p["battery_wh"]
		totals["data_mb_day"] += p["data_mb_day"]
		totals["downlink_mb_day"] += p["downlink_mb_day"]
	var mission := get_mission(mission_id)
	totals["battery_needed_wh"] = totals["power_use_w"] * mission.get("eclipse_minutes", 0) / 60.0
	var issues := []
	if design.get("parts", []).is_empty():
		issues.append({"id": "empty", "severity": "blocker", "role": "engineer",
			"message": "No parts selected.", "fix": "Add a frame, a computer and an instrument."})
	for role in ["engineer", "scientist", "navigator", "quartermaster"]:
		if not design.get("signoffs", {}).get(role, false):
			issues.append({"id": "signoff_" + role, "severity": "blocker", "role": role,
				"message": role.capitalize() + " has not signed off.", "fix": "Review your area and sign off."})
	var ok := true
	for i in issues:
		if i["severity"] == "blocker":
			ok = false
	return {"ok": ok, "totals": totals,
		"limits": {"mass_kg": 50, "cost": mission.get("budget", 0)}, "issues": issues}


func run_mission(mission_id: String, design: Dictionary) -> Dictionary:
	var check := check_design(mission_id, design)
	if not check["ok"]:
		return {"outcome": "blocked", "score": 0, "requirement_results": [], "why_lines": ["Fix the blockers first."],
			"fuel_feedback": null, "rewards_applied": {}, "real_mission": {}, "next_dialogue": ""}
	var mission := get_mission(mission_id)
	# FAKE: every requirement passes.
	var reqs := []
	for r in mission.get("requirements", []):
		reqs.append({"id": r["id"], "label": r["label"], "passed": true, "detail": "(stub) passed"})
	_complete(mission)
	return {"outcome": "success", "score": 750, "requirement_results": reqs,
		"why_lines": ["(stub) Real explanations come from report.gd."],
		"fuel_feedback": null, "rewards_applied": mission.get("rewards", {}),
		"real_mission": _data.get("real_missions", {}).get(mission.get("real_mission", ""), {}),
		"next_dialogue": mission.get("success_dialogue", "")}


func make_choice(mission_id: String, choice_id: String) -> Dictionary:
	var mission := get_mission(mission_id)
	var dlg := ""
	var choices = mission.get("choices", [])
	if choices == null:
		choices = []
	for c in choices:
		if c["id"] == choice_id:
			dlg = c["result_dialogue"]
	_complete(mission)
	return {"outcome": "success", "score": 0, "requirement_results": [], "why_lines": [],
		"fuel_feedback": null, "rewards_applied": mission.get("rewards", {}), "real_mission": {},
		"next_dialogue": dlg}


# ---------------------------------------------------------------- internals

func _complete(mission: Dictionary) -> void:
	if mission.is_empty() or mission["id"] in _state["completed"]:
		return
	_state["completed"].append(mission["id"])
	var rw: Dictionary = mission.get("rewards", {})
	_state["ozone"] = min(100, _state["ozone"] + rw.get("ozone", 0))
	_state["credits"] += rw.get("credits", 0)
	for pid in rw.get("unlock_parts", []):
		if not (pid in _state["unlocked_parts"]):
			_state["unlocked_parts"].append(pid)
	state_changed.emit(_state.duplicate(true))


func _load_data() -> void:
	for fname in ["acts", "missions", "parts", "launchers", "dialogue", "real_missions"]:
		var path := "res://data/%s.json" % fname
		if not FileAccess.file_exists(path):
			push_error("GameEngine: missing " + path)
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed == null:
			push_error("GameEngine: invalid JSON in " + path)
			continue
		_data[fname] = parsed


func _find(list: Array, id: String) -> Dictionary:
	for item in list:
		if item["id"] == id:
			return item
	return {}


func _ids_where(list: Array, flag: String) -> Array:
	var out := []
	for item in list:
		if item.get(flag, false):
			out.append(item["id"])
	return out
