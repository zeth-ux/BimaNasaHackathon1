extends Control
## First Earth-map prototype. Movement/room selection lives in the UI;
## mission state is read from GameEngine.

signal room_requested(room: Dictionary)
signal back_requested

const BACKDROP := Color("#17152c")
const INK := Color("#17172a")
const PANEL := Color("#211e39")
const OUTLINE := Color("#ffb735")
const PATH := Color("#403852")
const PAPER := Color("#f4dfb1")
const MUTED := Color("#b8b0c1")
const ENGINEER := Color("#f2944d")
const SCIENTIST := Color("#70c9dc")
const NAVIGATOR := Color("#d65f9c")
const QUARTERMASTER := Color("#edcf61")
const ALARM := Color("#ef7478")
const PIXEL_FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const ROLE_TEXTURES: Array[Texture2D] = [
	preload("res://ui/art/characters/reference_engineer.png"),
	preload("res://ui/art/characters/reference_scientist.png"),
	preload("res://ui/art/characters/reference_navigator.png"),
	preload("res://ui/art/characters/reference_quartermaster.png")
]
const PlayerScene = preload("res://game/player/player.tscn")
const MOVE_SPEED := 600.0
const WALKWAY_RADIUS := 14.0
const STORY_MENU_SIZE := Vector2(860.0, 520.0)

const ROOMS := [
	{"id": "launch_pad", "name": "Launch Pad", "code": "L", "tier": "CRITICAL", "role": "Everyone", "shape": "rectangle", "color": PAPER, "p": Vector2(0.165, 0.245), "s": Vector2(0.018, 0.054), "zone": "surface", "description": "The exposed pad for sounding rockets and the first CubeSat launch."},
	{"id": "uv_canopy", "name": "UV Canopy", "code": "U", "tier": "OPTIONAL", "role": "Optional B", "shape": "rectangle", "color": Color("#27374d"), "p": Vector2(0.38, 0.245), "s": Vector2(0.018, 0.054), "zone": "surface", "optional": true, "description": "A safe path across the surface, unlocked by the Platform Shield objective."},
	{"id": "airlock", "name": "Airlock", "code": "A", "tier": "SUPPORT", "role": "Everyone", "shape": "rectangle", "color": PAPER, "p": Vector2(0.51, 0.345), "s": Vector2(0.018, 0.054), "zone": "surface", "description": "The only doorway between Bunker 4 and the UV-exposed surface."},
	{"id": "ozone_lab", "name": "Ozone Lab", "code": "O", "tier": "CORE", "role": "Scientist", "shape": "rectangle", "color": SCIENTIST, "p": Vector2(0.17, 0.48), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Study the ozone damage and track the meter as the sky heals."},
	{"id": "mission_control", "name": "Mission Control", "code": "M", "tier": "CRITICAL", "role": "Everyone", "shape": "rectangle", "color": PAPER, "p": Vector2(0.51, 0.64), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Choose an objective, review the team design, and see mission results."},
	{"id": "comms_room", "name": "Comms Room", "code": "C", "tier": "CORE", "role": "Quartermaster", "shape": "rectangle", "color": QUARTERMASTER, "p": Vector2(0.85, 0.47), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Keep the radio link working and reconnect the scattered bunkers."},
	{"id": "engineering_workshop", "name": "Engineering Workshop", "code": "E", "tier": "CORE", "role": "Engineer", "shape": "rectangle", "color": ENGINEER, "p": Vector2(0.14, 0.65), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Build the vehicle from salvaged parts and keep its mass within the launcher limit."},
	{"id": "navigation_room", "name": "Navigation Room", "code": "N", "tier": "CORE", "role": "Navigator", "shape": "rectangle", "color": NAVIGATOR, "p": Vector2(0.855, 0.65), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Choose the launcher, destination, trajectory, and fuel load."},
	{"id": "hydroponics", "name": "Hydroponics", "code": "H", "tier": "OPTIONAL", "role": "Optional H", "shape": "rectangle", "color": Color("#27374d"), "p": Vector2(0.13, 0.90), "s": Vector2(0.018, 0.054), "zone": "bunker", "optional": true, "description": "An optional greenhouse project that helps the bunkers grow food again."},
	{"id": "med_bay", "name": "Med Bay", "code": "B", "tier": "SUPPORT", "role": "Everyone", "shape": "rectangle", "color": PAPER, "p": Vector2(0.32, 0.90), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "A safe place to recover when a surface trip runs out of time."},
	{"id": "crew_quarters", "name": "Crew Quarters", "code": "Q", "tier": "SUPPORT", "role": "Everyone", "shape": "rectangle", "color": PAPER, "p": Vector2(0.50, 0.90), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "The crew's home underground. Start here and replay story scenes."},
	{"id": "power_supply", "name": "Power and Supply", "code": "P", "tier": "CORE", "role": "Quartermaster", "shape": "rectangle", "color": QUARTERMASTER, "p": Vector2(0.86, 0.90), "s": Vector2(0.018, 0.054), "zone": "bunker", "description": "Manage power, batteries, credits, and resources for the bunker network."}
]

const LINKS := [
	["launch_pad", "uv_canopy"], ["uv_canopy", "airlock"], ["launch_pad", "airlock"],
	["airlock", "mission_control"], ["ozone_lab", "mission_control"],
	["mission_control", "comms_room"], ["ozone_lab", "engineering_workshop"],
	["engineering_workshop", "mission_control"], ["mission_control", "navigation_room"],
	["comms_room", "navigation_room"], ["engineering_workshop", "med_bay"],
	["med_bay", "crew_quarters"], ["crew_quarters", "power_supply"],
	["navigation_room", "power_supply"], ["engineering_workshop", "hydroponics"]
]

var selected_room_id := "crew_quarters"
var current_room_id := "crew_quarters"
var selected_role := 0
var starting_role := 0
var selected_suit_color := Color("ff9c55")
var crew_following := false
var avatar_room_id := "crew_quarters"
var auto_enter_room_id := ""
var avatar_position := Vector2.ZERO
var player_entity: CharacterBody2D
var room_lookup: Dictionary = {}
var game_state: Dictionary = {}
var available_missions: Array = []
var walk_phase := 0.0
var travel_targets: Array[Vector2] = []
var menu_open := false
var menu_tab := "STORY"
var story_dialogue: Array = []
var story_outline: Array[String] = []
var story_index := 0
var current_act: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for room in ROOMS:
		room_lookup[room["id"]] = room
	game_state = GameEngine.get_state()
	available_missions = GameEngine.get_available_missions()
	_refresh_story_data()
	GameEngine.state_changed.connect(_on_state_changed)
	avatar_position = _room_center(room_lookup[current_room_id])
	var player_node := PlayerScene.instantiate() as CharacterBody2D
	player_entity = player_node
	player_entity.set("player_index", 0)
	player_entity.set("max_speed", MOVE_SPEED)
	player_entity.set("acceleration", 2400.0)
	player_entity.position = avatar_position
	player_entity.set("player_index", selected_role)
	player_entity.visible = false
	player_entity.set_physics_process(false)
	add_child(player_entity)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if room_lookup.has(current_room_id):
			avatar_position = _room_center(room_lookup[current_room_id])
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	_draw_map()
	_draw_header()
	if menu_open:
		_draw_story_menu()

func _draw_header() -> void:
	var panel := Color("17152b")
	var left := Rect2(12, 12, 272, 70)
	draw_rect(left, panel, true)
	draw_rect(left, Color("5a6988"), false, 2.0)
	draw_string(PIXEL_FONT, Vector2(24, 34), "PROJECT DAWN  /  EARTH", HORIZONTAL_ALIGNMENT_LEFT, 250, 10, Color("c0cbdc"))
	draw_string(PIXEL_FONT, Vector2(24, 61), "BUNKER 4  ·  ACT 1", HORIZONTAL_ALIGNMENT_LEFT, 250, 13, Color("ead4aa"))
	var objective := Rect2(304, 12, maxf(size.x - 736.0, 300.0), 52)
	draw_rect(objective, panel, true)
	draw_rect(objective, Color("feae34"), false, 2.0)
	draw_string(PIXEL_FONT, Vector2(318, 31), "CURRENT OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, objective.size.x - 24.0, 8, Color("feae34"))
	draw_string(PIXEL_FONT, Vector2(318, 51), "OPEN THE BOARD IN MISSION CONTROL", HORIZONTAL_ALIGNMENT_LEFT, objective.size.x - 24.0, 9, Color("ffffff"))
	var ozone := int(game_state.get("ozone", 0))
	var credits := int(game_state.get("credits", 0))
	var stat_x := size.x - 420.0
	draw_rect(Rect2(stat_x, 12, 118, 52), panel, true)
	draw_rect(Rect2(stat_x, 12, 118, 52), Color("0099db"), false, 2.0)
	draw_string(PIXEL_FONT, Vector2(stat_x + 10.0, 43), "OZONE %d%%" % ozone, HORIZONTAL_ALIGNMENT_LEFT, 98, 8, Color("2ce8f5"))
	draw_rect(Rect2(stat_x + 130.0, 12, 112, 52), panel, true)
	draw_rect(Rect2(stat_x + 130.0, 12, 112, 52), Color("feae34"), false, 2.0)
	draw_string(PIXEL_FONT, Vector2(stat_x + 140.0, 43), "CREDITS %d" % credits, HORIZONTAL_ALIGNMENT_LEFT, 96, 7, Color("fee761"))
	var menu_rect := _menu_button_rect()
	draw_rect(menu_rect, Color("262b44"), true)
	draw_rect(menu_rect, Color("feae34"), false, 2.0)
	draw_string(PIXEL_FONT, menu_rect.position + Vector2(4, 24), "M  MENU", HORIZONTAL_ALIGNMENT_CENTER, menu_rect.size.x - 8, 7, Color("ead4aa"))
	for index in range(ROLE_TEXTURES.size()):
		var rect := Rect2(size.x - 244 + index * 52, 78, 42, 38)
		draw_rect(rect, Color("181425"), true)
		draw_rect(rect, [ENGINEER, SCIENTIST, NAVIGATOR, QUARTERMASTER][index], false, 2.0)
		if index == selected_role:
			draw_rect(rect.grow(3), Color("fee761"), false, 2.0)
		draw_string(PIXEL_FONT, Vector2(rect.position.x, rect.position.y + 25), ["E", "S", "N", "Q"][index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 11, Color("ffffff"))


func _draw_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("17152b"), true)
	# Flat surface deck and underground corridor grid, matching the connected-node reference.
	var surface := Rect2(24.0, 118.0, size.x - 48.0, 116.0)
	var bunker := Rect2(16.0, 260.0, size.x - 32.0, size.y - 278.0)
	draw_rect(surface, Color("402a35"), true)
	draw_rect(Rect2(surface.position.x, surface.position.y, surface.size.x, 12.0), Color("b86f50"), true)
	for x in range(32, int(size.x), 22):
		var seed := (x * 17) % 31
		draw_rect(Rect2(float(x), 150.0 + float(seed), 8.0, 3.0), Color("733e39"), true)
	draw_rect(bunker, Color("262b44"), true)
	draw_rect(bunker, Color("5a6988"), false, 3.0)
	for y in range(270, int(size.y - 18.0), 12):
		draw_rect(Rect2(20.0, float(y), size.x - 40.0, 5.0), Color("333653"), true)
	draw_string(PIXEL_FONT, Vector2(104.0, 168.0), "SURFACE  ·  UV ZONE", HORIZONTAL_ALIGNMENT_LEFT, 320.0, 10, Color("f6757a"))
	draw_string(PIXEL_FONT, Vector2(60.0, 286.0), "BUNKER 4  ·  UNDERGROUND", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 10, Color("c0cbdc"))
	for link in LINKS:
		var a := _room_center(room_lookup[link[0]])
		var b := _room_center(room_lookup[link[1]])
		draw_line(a, b, Color("17152b"), 20.0, true)
		draw_line(a, b, Color("5a6988"), 11.0, true)
		var count := maxi(1, int(a.distance_to(b) / 22.0))
		for step in range(count + 1):
			var point := a.lerp(b, float(step) / float(count))
			draw_rect(Rect2(point - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color("3a4466"), true)
	for room in ROOMS:
		_draw_room(room)
	_draw_avatar()
	for room in ROOMS:
		_draw_room_label(room)
	draw_string(PIXEL_FONT, Vector2(24.0, size.y - 18.0), "WASD / ARROWS: WALK  ·  CLICK: MOVE  ·  WALK INTO A ROOM: ENTER  ·  TAB: SWITCH CREW  ·  F: FOLLOW", HORIZONTAL_ALIGNMENT_LEFT, size.x - 280.0, 8, Color("ead4aa"))

func _menu_button_rect() -> Rect2:
	return Rect2(size.x - 244.0, 124.0, 112.0, 38.0)

func _return_button_rect() -> Rect2:
	return Rect2(22.0, 86.0, 112.0, 38.0)

func _story_menu_rect() -> Rect2:
	var panel_size := Vector2(minf(STORY_MENU_SIZE.x, size.x - 32.0), minf(STORY_MENU_SIZE.y, size.y - 40.0))
	return Rect2((size - panel_size) * 0.5, panel_size)

func _draw_story_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.06, 0.78), true)
	var panel := _story_menu_rect()
	draw_rect(panel, Color("111327"), true)
	draw_rect(panel.grow(-8.0), Color("211e39"), true)
	draw_rect(panel, Color("68f36e"), false, 4.0)
	draw_rect(Rect2(panel.position.x + 4, panel.position.y + 4, panel.size.x - 8, 46), Color("172a32"), true)
	draw_string(PIXEL_FONT, panel.position + Vector2(26, 32), "BUNKER 4  /  STORY MENU", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 110, 9, PAPER)
	var close_rect := Rect2(panel.end.x - 46, panel.position.y + 10, 30, 30)
	draw_rect(close_rect, Color("25243e"), true)
	draw_rect(close_rect, Color("ef7478"), false, 2.0)
	draw_string(PIXEL_FONT, close_rect.position + Vector2(9, 21), "X", HORIZONTAL_ALIGNMENT_LEFT, 16, 8, PAPER)
	_draw_menu_tab(_story_tab_rect(panel), "STORY", menu_tab == "STORY")
	_draw_menu_tab(_objectives_tab_rect(panel), "OBJECTIVES", menu_tab == "OBJECTIVES")
	if menu_tab == "STORY":
		_draw_story_content(panel)
	else:
		_draw_objectives_content(panel)
	draw_string(PIXEL_FONT, Vector2(panel.position.x + 24, panel.end.y - 16), "M / ESC: CLOSE    SPACE / ENTER: NEXT STORY LINE", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 48, 6, MUTED)

func _story_tab_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position.x + 24, panel.position.y + 60, 150, 38)

func _objectives_tab_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position.x + 184, panel.position.y + 60, 214, 38)

func _draw_menu_tab(rect: Rect2, label: String, selected: bool) -> void:
	var fill := Color("68f36e") if selected else Color("172a32")
	var text_color := Color("111327") if selected else PAPER
	draw_rect(rect, fill, true)
	draw_rect(rect, Color("68f36e"), false, 2.0)
	draw_string(PIXEL_FONT, rect.position + Vector2(12, 24), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 24, 7, text_color)

func _draw_story_content(panel: Rect2) -> void:
	var content := Rect2(panel.position.x + 24, panel.position.y + 112, panel.size.x - 48, panel.size.y - 174)
	draw_rect(content, Color("15172e"), true)
	draw_rect(content, Color("3b4460"), false, 2.0)
	var act_number := int(current_act.get("number", 1))
	var act_title := str(current_act.get("title", "First Light"))
	var world := str(current_act.get("world", "earth")).to_upper()
	draw_string(PIXEL_FONT, content.position + Vector2(24, 36), "ACT %d  /  %s" % [act_number, world], HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 8, Color("68f36e"))
	draw_string(PIXEL_FONT, content.position + Vector2(24, 74), act_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 15, PAPER)
	var objective := str(current_act.get("big_objective", "Continue the Project Dawn mission."))
	var objective_lines := _wrap_words(objective, 64)
	var objective_y := content.position.y + 106.0
	for index in range(mini(objective_lines.size(), 2)):
		draw_string(PIXEL_FONT, Vector2(content.position.x + 24, objective_y), objective_lines[index], HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 8, Color("f3ca52"))
		objective_y += 20.0
	draw_rect(Rect2(content.position.x + 24, content.position.y + 153, content.size.x - 48, 2), Color("3b4460"), true)
	if story_dialogue.is_empty():
		var outline_y := content.position.y + 192.0
		for outline in story_outline.slice(0, 3):
			var outline_lines := _wrap_words(str(outline), 72)
			for outline_line in outline_lines.slice(0, 2):
				draw_string(PIXEL_FONT, Vector2(content.position.x + 24, outline_y), str(outline_line), HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 7, PAPER)
				outline_y += 21.0
		if story_outline.is_empty():
			draw_string(PIXEL_FONT, Vector2(content.position.x + 24, outline_y), "STORY DETAILS WILL APPEAR WHEN MISSION DATA IS READY.", HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 6, MUTED)
		return
	var line: Dictionary = story_dialogue[story_index]
	var speaker := str(line.get("speaker", "narrator")).to_upper()
	var speaker_color := Color("68f36e") if speaker == "CERES" else _role_color(speaker.capitalize())
	draw_rect(Rect2(content.position.x + 24, content.position.y + 174, 176, 30), speaker_color, true)
	draw_string(PIXEL_FONT, Vector2(content.position.x + 34, content.position.y + 194), speaker, HORIZONTAL_ALIGNMENT_LEFT, 156, 7, Color("111327"))
	var dialogue_text := str(line.get("text", ""))
	var dialogue_lines_wrapped := _wrap_words(dialogue_text, 72)
	var dialogue_y := content.position.y + 234.0
	for index in range(mini(dialogue_lines_wrapped.size(), 3)):
		draw_string(PIXEL_FONT, Vector2(content.position.x + 24, dialogue_y), dialogue_lines_wrapped[index], HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 9, PAPER)
		dialogue_y += 24.0
	draw_string(PIXEL_FONT, Vector2(content.end.x - 150, content.end.y - 18), "%d / %d" % [story_index + 1, story_dialogue.size()], HORIZONTAL_ALIGNMENT_RIGHT, 122, 6, MUTED)

func _draw_objectives_content(panel: Rect2) -> void:
	var content := Rect2(panel.position.x + 24, panel.position.y + 112, panel.size.x - 48, panel.size.y - 174)
	draw_rect(content, Color("15172e"), true)
	draw_rect(content, Color("3b4460"), false, 2.0)
	var act_title := str(current_act.get("title", "First Light"))
	var objective := str(current_act.get("big_objective", "Continue the Project Dawn mission."))
	draw_string(PIXEL_FONT, content.position + Vector2(24, 34), "CURRENT ACT  /  " + act_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 8, Color("68f36e"))
	var objective_lines := _wrap_words(objective, 70)
	var y := content.position.y + 72.0
	for index in range(mini(objective_lines.size(), 2)):
		draw_string(PIXEL_FONT, Vector2(content.position.x + 24, y), objective_lines[index], HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 8, PAPER)
		y += 22.0
	y += 18.0
	draw_string(PIXEL_FONT, Vector2(content.position.x + 24, y), "AVAILABLE OBJECTIVES", HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 8, Color("f3ca52"))
	y += 34.0
	if available_missions.is_empty():
		draw_string(PIXEL_FONT, Vector2(content.position.x + 24, y), "NO OBJECTIVES ARE AVAILABLE RIGHT NOW.", HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 7, MUTED)
		return
	for mission_value in available_missions.slice(0, 5):
		var mission: Dictionary = mission_value
		var title := str(mission.get("title", "Mission")).to_upper()
		draw_string(PIXEL_FONT, Vector2(content.position.x + 24, y), "> " + title, HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 48, 7, PAPER)
		y += 20.0
		var summary := str(mission.get("summary", ""))
		for summary_line in _wrap_words(summary, 76).slice(0, 2):
			draw_string(PIXEL_FONT, Vector2(content.position.x + 42, y), str(summary_line), HORIZONTAL_ALIGNMENT_LEFT, content.size.x - 66, 6, MUTED)
			y += 17.0
		y += 12.0

func _refresh_story_data() -> void:
	var act_id := str(game_state.get("act", "act1"))
	var acts: Array = GameEngine.get_acts()
	current_act.clear()
	for act_value in acts:
		var act: Dictionary = act_value
		if str(act.get("id", "")) == act_id:
			current_act = act
			break
	if current_act.is_empty() and not acts.is_empty():
		current_act = acts[0]
	var dialogue_key := str(current_act.get("intro_dialogue", ""))
	if dialogue_key.is_empty() and act_id == "act1":
		dialogue_key = "act1_intro"
	story_dialogue.clear()
	if not dialogue_key.is_empty():
		story_dialogue = GameEngine.get_dialogue(dialogue_key)
	story_outline.clear()
	for mission_id in current_act.get("missions", []):
		var mission_entry: Dictionary = GameEngine.get_mission(str(mission_id))
		if mission_entry.is_empty():
			continue
		var mission_title := str(mission_entry.get("title", "Mission"))
		var mission_summary := str(mission_entry.get("summary", ""))
		story_outline.append(mission_title + ": " + mission_summary)
	if story_dialogue.is_empty():
		for mission_id in current_act.get("missions", []):
			var briefing_mission: Dictionary = GameEngine.get_mission(str(mission_id))
			var brief_key := str(briefing_mission.get("brief_dialogue", ""))
			if not brief_key.is_empty():
				story_dialogue.append_array(GameEngine.get_dialogue(brief_key))
	story_index = clampi(story_index, 0, maxi(story_dialogue.size() - 1, 0))

func _advance_story() -> void:
	if not story_dialogue.is_empty() and story_index < story_dialogue.size() - 1:
		story_index += 1
	queue_redraw()
func _draw_room(room: Dictionary) -> void:
	var rect := _room_rect(room)
	var center := rect.get_center()
	var locked := bool(room.get("optional", false)) and not bool(room.get("unlocked", false))
	var post_color := Color("5a6988") if not locked else Color("8b9bb4")
	# Narrow doorway post, blue code plate and small dark footing, as in the reference map.
	draw_rect(Rect2(center.x - 7.0, center.y - 17.0, 14.0, 42.0), Color("17152b"), true)
	draw_rect(Rect2(center.x - 5.0, center.y - 15.0, 10.0, 36.0), post_color, true)
	if locked:
		_draw_dashed_polyline(PackedVector2Array([Vector2(center.x - 11, center.y - 19), Vector2(center.x + 11, center.y - 19), Vector2(center.x + 11, center.y + 23), Vector2(center.x - 11, center.y + 23), Vector2(center.x - 11, center.y - 19)]), Color("8b9bb4"), 2.0, 4.0, 3.0)
	var badge := Rect2(center.x - 8.0, center.y - 15.0, 16.0, 14.0)
	draw_rect(badge, Color("14558a"), true)
	draw_string(PIXEL_FONT, Vector2(badge.position.x, badge.position.y + 11.0), str(room.get("code", "•")), HORIZONTAL_ALIGNMENT_CENTER, 16.0, 7, Color.WHITE)
	if str(room["id"]) == current_room_id:
		draw_rect(Rect2(center.x - 12.0, center.y - 23.0, 24.0, 2.0), Color("fee761"), true)


func _draw_room_label(room: Dictionary) -> void:
	var center := _room_center(room)
	var label := str(room["name"]).to_upper()
	var label_y := center.y - 26.0
	if str(room["zone"]) == "surface":
		label_y = center.y + 32.0
	if str(room["id"]) in ["mission_control", "crew_quarters"]:
		label_y = center.y - 29.0
	var color := Color("c0cbdc") if bool(room.get("optional", false)) else Color("ead4aa")
	draw_string(PIXEL_FONT, Vector2(center.x - 90.0, label_y), label, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 6, color)
	if bool(room.get("optional", false)):
		draw_string(PIXEL_FONT, Vector2(center.x - 50.0, label_y + 12.0), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 5, Color("8b9bb4"))

func _draw_avatar() -> void:
	# Keep the chosen profession and suit visible while walking around the map.
	var facing: Vector2 = player_entity.get("facing")
	var source_row := 0
	if facing.y < 0.0:
		source_row = 1
	elif facing.x < 0.0:
		source_row = 2
	elif facing.x > 0.0:
		source_row = 3
	var moving: bool = player_entity.get("is_moving")
	var source_column := int(walk_phase) % 4 if moving else 0
	var source := Rect2(source_column * 16, source_row * 16, 16, 16)
	var suit_color := _active_suit_color()
	var avatar_texture := CrewSprites.sprite(selected_role, suit_color, CrewSprites.default_pack(selected_role))
	draw_rect(Rect2(avatar_position + Vector2(-20, 18), Vector2(40, 10)), Color(0.05, 0.04, 0.08, 0.7))
	draw_texture_rect_region(avatar_texture, Rect2(avatar_position + Vector2(-27, -34), Vector2(54, 54)), source, Color.WHITE)
	if crew_following:
		for index in range(ROLE_TEXTURES.size()):
			if index == selected_role:
				continue
			var follower_pos := avatar_position + Vector2(float(index - 1) * 30.0, 34.0 + float(index % 2) * 16.0)
			draw_texture_rect_region(ROLE_TEXTURES[index], Rect2(follower_pos - Vector2(14, 18), Vector2(28, 28)), Rect2(0, 0, 16, 16), Color.WHITE)
	draw_rect(Rect2(avatar_position + Vector2(-20, -34), Vector2(40, 14)), PANEL, true)
	draw_rect(Rect2(avatar_position + Vector2(-20, -34), Vector2(40, 14)), OUTLINE, false, 1.0)
	draw_string(PIXEL_FONT, avatar_position + Vector2(-20, -24), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 40, 6, INK)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not menu_open and _return_button_rect().has_point(event.position):
			back_requested.emit()
			accept_event()
			return
		if menu_open:
			var panel := _story_menu_rect()
			var close_rect := Rect2(panel.end.x - 46, panel.position.y + 10, 30, 30)
			if close_rect.has_point(event.position) or not panel.has_point(event.position):
				menu_open = false
				player_entity.set("can_move", true)
			elif _story_tab_rect(panel).has_point(event.position):
				menu_tab = "STORY"
			elif _objectives_tab_rect(panel).has_point(event.position):
				menu_tab = "OBJECTIVES"
			elif menu_tab == "STORY" and event.position.y > panel.position.y + 205:
				_advance_story()
			queue_redraw()
			accept_event()
			return
		if _menu_button_rect().has_point(event.position):
			menu_open = true
			player_entity.set("can_move", false)
			menu_tab = "STORY"
			queue_redraw()
			accept_event()
			return
		for room in ROOMS:
			if event.position.distance_to(_room_center(room)) <= 25.0:
				selected_room_id = str(room["id"])
				_start_walk_to(selected_room_id)
				queue_redraw()
				accept_event()
				return
		if _is_walkable(event.position):
			travel_targets.clear()
			travel_targets.append(event.position)
			auto_enter_room_id = ""
			for room in ROOMS:
				if Geometry2D.is_point_in_polygon(event.position, _room_polygon(room["shape"], _room_rect(room))):
					auto_enter_room_id = str(room["id"])
					break
			queue_redraw()
			accept_event()
			return

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if menu_open:
			if key_event.physical_keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_M:
				menu_open = false
				player_entity.set("can_move", true)
				queue_redraw()
			elif key_event.physical_keycode == KEY_SPACE or key_event.physical_keycode == KEY_ENTER:
				if menu_tab == "STORY":
					_advance_story()
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_ENTER:
			for room in ROOMS:
				if avatar_position.distance_to(_room_center(room)) <= 30.0:
					room_requested.emit(room.duplicate(true))
					get_viewport().set_input_as_handled()
					return
		if key_event.physical_keycode == KEY_ESCAPE:
			back_requested.emit()
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_M:
			menu_open = true
			player_entity.set("can_move", false)
			menu_tab = "STORY"
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_TAB:
			_select_role((selected_role + 1) % ROLE_TEXTURES.size())
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode >= KEY_1 and key_event.physical_keycode <= KEY_4:
			_select_role(key_event.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if key_event.physical_keycode == KEY_F:
			crew_following = not crew_following
			queue_redraw()
			get_viewport().set_input_as_handled()
			return

func _process(delta: float) -> void:
	if menu_open:
		return
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction != Vector2.ZERO:
		travel_targets.clear()
		auto_enter_room_id = ""
	elif not travel_targets.is_empty():
		var target: Vector2 = travel_targets[0]
		var offset: Vector2 = target - avatar_position
		direction = offset.normalized()
	else:
		player_entity.call("step", Vector2.ZERO, delta)
		var coast: Vector2 = player_entity.velocity * delta
		if coast.length_squared() <= 1.0:
			return
		var coast_candidate := avatar_position + coast
		if _is_walkable(coast_candidate):
			avatar_position = coast_candidate
		else:
			player_entity.velocity = Vector2.ZERO
		player_entity.position = avatar_position
		walk_phase += delta * 10.0
		_update_current_room()
		queue_redraw()
		return

	direction = direction.normalized()
	player_entity.call("step", direction, delta)
	var movement: Vector2 = player_entity.velocity * delta
	if not travel_targets.is_empty() and (travel_targets[0] - avatar_position).length() <= movement.length():
		avatar_position = travel_targets[0]
		travel_targets.pop_front()
	else:
		var candidate := avatar_position + movement
		if _is_walkable(candidate):
			avatar_position = candidate
		else:
			player_entity.velocity = Vector2.ZERO
	player_entity.position = avatar_position
	walk_phase += delta * 10.0
	_update_current_room()
	queue_redraw()

func _select_role(index: int) -> void:
	selected_role = clampi(index, 0, ROLE_TEXTURES.size() - 1)
	player_entity.set("player_index", selected_role)
	queue_redraw()

func _start_walk_to(target_room_id: String) -> void:
	travel_targets.clear()
	auto_enter_room_id = target_room_id
	if target_room_id == current_room_id:
		avatar_position = _room_center(room_lookup[target_room_id])
		player_entity.position = avatar_position
		return
	var queue: Array[String] = [current_room_id]
	var parents: Dictionary = {current_room_id: ""}
	var found := false
	while not queue.is_empty() and not found:
		var room_id: String = queue.pop_front()
		for connection in LINKS:
			var from_id: String = str(connection[0])
			var to_id: String = str(connection[1])
			var next_id := ""
			if from_id == room_id:
				next_id = to_id
			elif to_id == room_id:
				next_id = from_id
			if next_id.is_empty() or parents.has(next_id):
				continue
			parents[next_id] = room_id
			queue.append(next_id)
			if next_id == target_room_id:
				found = true
				break
	if not found:
		return
	var room_path: Array[String] = []
	var cursor := target_room_id
	while cursor != current_room_id:
		room_path.push_front(cursor)
		cursor = str(parents.get(cursor, current_room_id))
	travel_targets.append(_room_center(room_lookup[current_room_id]))
	for room_id in room_path:
		travel_targets.append(_room_center(room_lookup[room_id]))


func get_room_doors(room_id: String) -> Array[Dictionary]:
	var doors: Array[Dictionary] = [{}, {}]
	if not room_lookup.has(room_id):
		return doors
	var current: Dictionary = room_lookup[room_id]
	var candidates: Array[Dictionary] = []
	for link in LINKS:
		var other_id := ""
		if str(link[0]) == room_id:
			other_id = str(link[1])
		elif str(link[1]) == room_id:
			other_id = str(link[0])
		if not other_id.is_empty() and room_lookup.has(other_id):
			candidates.append(room_lookup[other_id])
	# Choose the nearest connected destination on each side, matching the room's two hatches.
	var left_distance := INF
	var right_distance := INF
	for candidate in candidates:
		var dx: float = float(candidate["p"].x) - float(current["p"].x)
		var distance: float = float(candidate["p"].distance_to(current["p"]))
		if dx < -0.005 and distance < left_distance:
			left_distance = distance
			doors[0] = candidate.duplicate(true)
		elif dx > 0.005 and distance < right_distance:
			right_distance = distance
			doors[1] = candidate.duplicate(true)
	# If all links run mostly vertically, still expose an available exit on one hatch.
	for candidate in candidates:
		if doors[0].is_empty():
			doors[0] = candidate.duplicate(true)
		elif doors[1].is_empty() and str(candidate["id"]) != str(doors[0].get("id", "")):
			doors[1] = candidate.duplicate(true)
	return doors

func _is_walkable(point: Vector2) -> bool:
	if not _map_rect().grow(-12.0).has_point(point):
		return false
	for room in ROOMS:
		if point.distance_to(_room_center(room)) <= 25.0:
			return true
	for link in LINKS:
		var a := _room_center(room_lookup[link[0]])
		var b := _room_center(room_lookup[link[1]])
		if _distance_to_segment(point, a, b) <= WALKWAY_RADIUS:
			return true
	return false

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared == 0.0:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)

func _update_current_room() -> void:
	avatar_room_id = ""
	for room in ROOMS:
		if avatar_position.distance_to(_room_center(room)) <= 26.0:
			var room_id := str(room["id"])
			current_room_id = room_id
			selected_room_id = room_id
			avatar_room_id = room_id
			return

func _active_suit_color() -> Color:
	if selected_role == starting_role:
		return selected_suit_color
	return [ENGINEER, SCIENTIST, NAVIGATOR, QUARTERMASTER][selected_role]

func _on_state_changed(state: Dictionary) -> void:
	game_state = state.duplicate(true)
	available_missions = GameEngine.get_available_missions()
	_refresh_story_data()
	queue_redraw()

func _map_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)

func _room_rect(room: Dictionary) -> Rect2:
	var map := _map_rect()
	var center: Vector2 = map.position + Vector2(room["p"].x * map.size.x, room["p"].y * map.size.y)
	var room_size: Vector2 = Vector2(room["s"].x * map.size.x, room["s"].y * map.size.y)
	return Rect2(center - room_size * 0.5, room_size)

func _room_center(room: Dictionary) -> Vector2:
	return _room_rect(room).get_center()

func _room_polygon(shape: String, rect: Rect2) -> PackedVector2Array:
	var p := PackedVector2Array()
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	match shape:
		"circle", "oval":
			for i in range(28):
				var angle := TAU * float(i) / 28.0
				p.append(rect.get_center() + Vector2(cos(angle) * w * 0.5, sin(angle) * h * 0.5))
		"octagon":
			p = PackedVector2Array([Vector2(x + w * 0.28, y), Vector2(x + w * 0.72, y), Vector2(x + w, y + h * 0.28), Vector2(x + w, y + h * 0.72), Vector2(x + w * 0.72, y + h), Vector2(x + w * 0.28, y + h), Vector2(x, y + h * 0.72), Vector2(x, y + h * 0.28)])
		"trapezoid":
			p = PackedVector2Array([Vector2(x + w * 0.18, y), Vector2(x + w * 0.82, y), Vector2(x + w, y + h), Vector2(x, y + h)])
		"hexagon":
			p = PackedVector2Array([Vector2(x + w * 0.25, y), Vector2(x + w * 0.75, y), Vector2(x + w, y + h * 0.5), Vector2(x + w * 0.75, y + h), Vector2(x + w * 0.25, y + h), Vector2(x, y + h * 0.5)])
		_:
			p = PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])
	return p

func _draw_dashed_polyline(points: PackedVector2Array, color: Color, width: float, dash: float, gap: float) -> void:
	for i in range(points.size()):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[(i + 1) % points.size()]
		var segment := finish - start
		var length := segment.length()
		if length == 0.0:
			continue
		var direction := segment / length
		var offset := 0.0
		while offset < length:
			var end_offset: float = min(offset + dash, length)
			draw_line(start + direction * offset, start + direction * end_offset, color, width, true)
			offset += dash + gap

func _wrap_words(text: String, max_chars: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if line.length() > 0 and line.length() + word.length() + 1 > max_chars:
			result.append(line)
			line = word
		else:
			line = word if line.is_empty() else line + " " + word
	if not line.is_empty():
		result.append(line)
	return result

func _role_color(role: String) -> Color:
	if "Engineer" in role:
		return ENGINEER
	if "Scientist" in role:
		return SCIENTIST
	if "Navigator" in role:
		return NAVIGATOR
	if "Quartermaster" in role:
		return QUARTERMASTER
	return MUTED
