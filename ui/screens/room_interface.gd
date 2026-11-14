extends Control
## Room story interface styled after the supplied pixel-art screen recording.

signal back_requested
signal door_requested(room: Dictionary, entry_side: int)

const FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const ROLE_TEXTURES: Array[Texture2D] = [
	preload("res://ui/art/characters/reference_engineer.png"),
	preload("res://ui/art/characters/reference_scientist.png"),
	preload("res://ui/art/characters/reference_navigator.png"),
	preload("res://ui/art/characters/reference_quartermaster.png")
]
const ROLE_NAMES: Array[String] = ["ENGINEER", "SCIENTIST", "NAVIGATOR", "QUARTERMASTER"]
const ROLE_COLORS: Array[Color] = [Color("ff8a30"), Color("58d8e8"), Color("d65f9c"), Color("f3ca52")]
const MAP_BUTTON := Rect2(1080.0, 614.0, 146.0, 56.0)
const DARK := Color("111327")
const TEXT_COLOR := Color("f1e7c8")
const ORANGE := Color("ff8a30")

var room_data: Dictionary = {}
var connected_rooms: Array[Dictionary] = [{}, {}]
var entry_side := -1
var game_state: Dictionary = {}
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var speaker_role := 0
var info_open := false
var dialogue_open := true
var player_position := Vector2(640.0, 472.0)
var move_target := Vector2.ZERO
var player_facing := Vector2.DOWN
var walk_phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if entry_side == 0:
		player_position = Vector2(190.0, 412.0)
	elif entry_side == 1:
		player_position = Vector2(1090.0, 412.0)
	game_state = GameEngine.get_state()
	speaker_role = _find_speaker_role()
	var room_name: String = str(room_data.get("name", "Station"))
	var purpose: String = str(room_data.get("description", "Explore this station."))
	var assigned_role: String = str(room_data.get("role", "Everyone"))
	dialogue_lines = [
		"We have arrived at %s." % room_name,
		purpose,
		"This station is assigned to: %s." % assigned_role
	]
	GameEngine.state_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	if info_open:
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
	var manual_input := direction != Vector2.ZERO
	if manual_input:
		move_target = Vector2.ZERO
	elif move_target != Vector2.ZERO:
		var target_offset := move_target - player_position
		if target_offset.length() <= 260.0 * delta:
			player_position = move_target
			move_target = Vector2.ZERO
		else:
			direction = target_offset.normalized()
	if direction != Vector2.ZERO:
		player_facing = direction.normalized()
		var candidate := player_position + player_facing * 260.0 * delta
		var dx := (candidate.x - 640.0) / 508.0
		var dy := (candidate.y - 412.0) / 196.0
		if dx * dx + dy * dy < 0.99:
			player_position = candidate
			if move_target != Vector2.ZERO and player_position.distance_to(move_target) < 10.0:
				move_target = Vector2.ZERO
		walk_phase += delta * 10.0
	if _try_use_door():
		return
	queue_redraw()

func _draw() -> void:
	var fit := minf(size.x / 1280.0, size.y / 720.0)
	var offset := (size - Vector2(1280.0, 720.0) * fit) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE * fit)
	_draw_station_backdrop()
	_draw_status_hud()
	_draw_station_set()
	_draw_party()
	_draw_player()
	_draw_room_action()
	if dialogue_open:
		_draw_dialogue()
	if info_open:
		_draw_room_info()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_station_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("101026"), true)
	for star in [Vector2(74, 187), Vector2(202, 251), Vector2(1118, 191), Vector2(1206, 294), Vector2(238, 601), Vector2(1038, 621)]:
		draw_rect(Rect2(star, Vector2(4, 4)), Color("8a9ab7"), true)
	var center := Vector2(640, 412)
	var outer := _ellipse_polygon(center, 548, 235, 80)
	var inner := _ellipse_polygon(center, 529, 216, 80)
	draw_colored_polygon(outer, Color("cbd5e3"))
	draw_colored_polygon(_ellipse_polygon(center, 538, 225, 80), Color("59647f"))
	draw_colored_polygon(inner, Color("1a2038"))
	for y in range(202, 634, 30):
		for x in range(102, 1178, 30):
			var tile_center := Vector2(x + 14, y + 14)
			var dx := (tile_center.x - center.x) / 525.0
			var dy := (tile_center.y - center.y) / 213.0
			if dx * dx + dy * dy <= 0.96:
				var shade := (int(x / 30) + int(y / 30)) % 2
				var tile_color := Color("505d79") if shade == 0 else Color("414d68")
				draw_rect(Rect2(x, y, 28, 28), tile_color, true)
				draw_rect(Rect2(x, y, 28, 28), Color("29334e"), false, 1.0)
	var rim := _ellipse_polygon(center, 544, 231, 80)
	rim.append(rim[0])
	draw_polyline(rim, Color("e2eaf0"), 5.0)
	# Side hatches and destination labels frame the walkable room.
	draw_rect(Rect2(72, 371, 36, 84), Color("17152c"), true)
	draw_rect(Rect2(72, 371, 36, 84), Color("ffb735"), false, 4.0)
	draw_rect(Rect2(1172, 371, 36, 84), Color("17152c"), true)
	draw_rect(Rect2(1172, 371, 36, 84), Color("ffb735"), false, 4.0)
	draw_string(FONT, Vector2(50, 358), "← " + _door_name(0), HORIZONTAL_ALIGNMENT_LEFT, 180, 8, Color("f2e8d0"))
	draw_string(FONT, Vector2(1082, 358), _door_name(1) + " →", HORIZONTAL_ALIGNMENT_LEFT, 154, 8, Color("f2e8d0"))
	var room_name: String = str(room_data.get("name", "CREW QUARTERS")).to_upper()
	draw_rect(Rect2(42, 86, 300, 42), Color("111327"), true)
	draw_rect(Rect2(42, 86, 300, 42), Color("66718d"), false, 3.0)
	draw_string(FONT, Vector2(58, 114), room_name, HORIZONTAL_ALIGNMENT_LEFT, 270, 10, Color("f1e7c8"))

func _ellipse_polygon(center: Vector2, radius_x: float, radius_y: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

func _draw_station_set() -> void:
	var room_id := str(room_data.get("id", "crew_quarters"))
	match room_id:
		"crew_quarters":
			for i in range(4):
				var x := 278.0 + float(i) * 184.0
				draw_rect(Rect2(x, 392, 122, 118), Color("17182d"), true)
				draw_rect(Rect2(x, 392, 122, 118), Color("65718e"), false, 5.0)
				draw_rect(Rect2(x + 14, 408, 92, 78), Color("0c2225"), true)
				draw_rect(Rect2(x + 27, 421, 64, 44), Color("28424a"), true)
				draw_rect(Rect2(x + 34, 428, 50, 5), Color("78a9ad"), true)
		"mission_control":
			_draw_terminal(Vector2(640, 378), Color("23d9df"), "MISSION BOARD")
			_draw_terminal(Vector2(445, 476), Color("ff9c55"), "ENGINEER")
			_draw_terminal(Vector2(835, 476), Color("ffc04a"), "POWER")
		"ozone_lab":
			_draw_terminal(Vector2(490, 400), Color("20bfdc"), "OZONE SENSOR")
			_draw_terminal(Vector2(790, 400), Color("d65f9c"), "SPECTROMETER")
		"engineering_workshop":
			_draw_terminal(Vector2(640, 410), Color("ff9c55"), "VEHICLE BAY")
		_:
			_draw_terminal(Vector2(640, 410), ROLE_COLORS[speaker_role], str(room_data.get("name", "STATION")).to_upper())

func _draw_terminal(center: Vector2, accent: Color, label: String) -> void:
	draw_rect(Rect2(center.x - 76, center.y - 56, 152, 96), Color("17172b"), true)
	draw_rect(Rect2(center.x - 76, center.y - 56, 152, 96), Color("77829a"), false, 4.0)
	draw_rect(Rect2(center.x - 62, center.y - 42, 124, 60), Color("0d2730"), true)
	draw_rect(Rect2(center.x - 51, center.y - 30, 78, 6), accent, true)
	draw_rect(Rect2(center.x - 51, center.y - 16, 48, 5), accent.darkened(0.2), true)
	draw_rect(Rect2(center.x - 16, center.y + 40, 32, 13), Color("59647f"), true)
	draw_string(FONT, Vector2(center.x - 72, center.y + 70), label, HORIZONTAL_ALIGNMENT_CENTER, 144, 6, accent)

func _draw_party() -> void:
	# Keep the other professions in the room itself, as in the reference demo,
	# instead of presenting them in a separate character-selection card.
	var crew_positions: Array[Vector2] = [
		Vector2(354, 348), Vector2(927, 350), Vector2(428, 526), Vector2(856, 526)
	]
	for index in range(ROLE_NAMES.size()):
		if index == speaker_role:
			continue
		var position: Vector2 = crew_positions[index]
		draw_rect(Rect2(position.x - 3, position.y + 42, 42, 7), Color("111327"), true)
		_draw_character(ROLE_TEXTURES[index], position, ROLE_COLORS[index], 2.5)
		draw_rect(Rect2(position.x - 14, position.y + 45, 64, 13), Color("111327"), true)
		draw_string(FONT, Vector2(position.x - 13, position.y + 55), ROLE_NAMES[index], HORIZONTAL_ALIGNMENT_CENTER, 62, 4, ROLE_COLORS[index])

func _draw_player() -> void:
	draw_rect(Rect2(player_position.x - 22, player_position.y + 19, 44, 8), Color("1a1a2d"), true)
	var row := 0
	if player_facing.y < -0.4:
		row = 4
	elif player_facing.x < -0.4:
		row = 2
	elif player_facing.x > 0.4:
		row = 3
	var frame := int(walk_phase) % 4
	var sprite_rect := Rect2(player_position - Vector2(32, 46), Vector2(64, 64))
	draw_texture_rect_region(ROLE_TEXTURES[speaker_role], sprite_rect, Rect2(frame * 16, row * 16, 16, 16), Color.WHITE)
	draw_rect(Rect2(player_position.x - 43, player_position.y + 23, 86, 18), Color("111327"), true)
	draw_string(FONT, Vector2(player_position.x - 41, player_position.y + 36), ROLE_NAMES[speaker_role], HORIZONTAL_ALIGNMENT_CENTER, 82, 5, ROLE_COLORS[speaker_role])

func _draw_room_action() -> void:
	var room_id := str(room_data.get("id", ""))
	var station_position := _station_position(room_id)
	if not dialogue_open and player_position.distance_to(station_position) < 150.0:
		var action := "OPEN MISSION BOARD  E  >>" if room_id == "mission_control" else "OPEN ROOM MISSION  E  >>"
		var prompt := Rect2(390, 614, 500, 56)
		draw_rect(prompt, Color("f5ad28"), true)
		draw_rect(Rect2(prompt.position.x, prompt.end.y - 10, prompt.size.x, 10), Color("be5a2d"), true)
		draw_rect(prompt, Color("ffb735"), false, 3.0)
		draw_string(FONT, Vector2(410, 650), action, HORIZONTAL_ALIGNMENT_CENTER, 460, 10, Color("17152c"))
	draw_string(FONT, Vector2(154, 702), "WASD / ARROWS: WALK  ·  WALK THROUGH A DOOR: NEXT ROOM  ·  SPACE: DIALOGUE", HORIZONTAL_ALIGNMENT_CENTER, 972, 6, Color("bec5d4"))
	_draw_button(MAP_BUTTON, "MAP  <")

func _station_position(room_id: String) -> Vector2:
	match room_id:
		"mission_control": return Vector2(640, 378)
		"ozone_lab": return Vector2(490, 400)
		"engineering_workshop": return Vector2(640, 410)
		"navigation_room": return Vector2(640, 410)
		"comms_room": return Vector2(640, 410)
		"power_supply": return Vector2(640, 410)
		"crew_quarters": return Vector2(640, 410)
		_: return Vector2(640, 410)

func _draw_status_hud() -> void:
	var ozone := int(game_state.get("ozone", 0))
	draw_rect(Rect2(20, 16, 560, 54), Color("111327"), true)
	draw_rect(Rect2(20, 16, 560, 54), Color("58617f"), false, 3.0)
	draw_string(FONT, Vector2(40, 49), "ACT 1  ·  OZONE %d%%" % ozone, HORIZONTAL_ALIGNMENT_LEFT, 260, 10, Color("f3e5bc"))
	draw_rect(Rect2(316, 32, 120, 16), Color("27304a"), true)
	draw_rect(Rect2(320, 36, 1.12 * float(clampi(ozone, 0, 100)), 8), Color("20bfdc"), true)
	draw_string(FONT, Vector2(452, 49), "DAY 1  ·  11:41", HORIZONTAL_ALIGNMENT_LEFT, 118, 7, Color("20bfdc"))
	draw_rect(Rect2(592, 16, 454, 54), Color("151328"), true)
	draw_rect(Rect2(592, 16, 454, 54), Color("ffb735"), false, 3.0)
	draw_string(FONT, Vector2(610, 39), "OPEN MISSION BOARD IN", HORIZONTAL_ALIGNMENT_CENTER, 418, 7, Color("f2e8d0"))
	draw_string(FONT, Vector2(610, 58), "MISSION CONTROL  ⓘ DETAILS", HORIZONTAL_ALIGNMENT_CENTER, 418, 7, Color("ffc04a"))
	for index in range(ROLE_NAMES.size()):
		var rect := Rect2(1054 + index * 54, 20, 46, 44)
		draw_rect(rect, ROLE_COLORS[index], true)
		draw_rect(rect, Color("111327"), false, 2.0)
		if index == speaker_role:
			draw_rect(rect.grow(4), Color("ffdf70"), false, 3.0)
		draw_string(FONT, Vector2(rect.position.x + 7, rect.position.y + 28), ["E", "S", "N", "Q"][index], HORIZONTAL_ALIGNMENT_CENTER, 32, 11, Color("17152c"))

func _draw_room_info() -> void:
	var panel := Rect2(250, 350, 780, 286)
	draw_rect(panel, Color("151328"), true)
	draw_rect(panel, Color("21d9df"), false, 4.0)
	draw_rect(Rect2(panel.position.x + 18, panel.position.y + 16, 294, 30), Color("21d9df"), true)
	draw_string(FONT, panel.position + Vector2(30, 36), "MISSION BRIEF  ·  DRAFT", HORIZONTAL_ALIGNMENT_LEFT, 270, 7, Color("111327"))
	draw_string(FONT, panel.position + Vector2(24, 78), str(room_data.get("name", "STATION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 720, 14, Color("f1e7c8"))
	draw_string(FONT, panel.position + Vector2(24, 108), "ASSIGNED CREW  ·  " + str(room_data.get("role", "Everyone")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 720, 7, Color("ffc04a"))
	draw_string(FONT, panel.position + Vector2(24, 146), "PRIMARY OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, 720, 7, Color("58d8e8"))
	var objective_lines := _wrap_words(str(room_data.get("description", "Mission objective will be added.")), 82)
	var line_y := panel.position.y + 170.0
	for line in objective_lines.slice(0, 2):
		draw_string(FONT, Vector2(panel.position.x + 24, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, 728, 8, Color("f2e8d0"))
		line_y += 20.0
	draw_rect(Rect2(panel.position.x + 24, panel.position.y + 212, panel.size.x - 48, 1), Color("424462"), true)
	draw_string(FONT, panel.position + Vector2(24, 240), "NASA SOURCES / MEASUREMENTS  ·  PENDING YOUR DATA", HORIZONTAL_ALIGNMENT_LEFT, 728, 7, Color("f3ca52"))
	draw_string(FONT, panel.position + Vector2(24, 262), "REQUIREMENTS AND COMPLETION RULES  ·  TO BE ADDED", HORIZONTAL_ALIGNMENT_LEFT, 728, 6, Color("b6c4d2"))
	draw_string(FONT, panel.position + Vector2(24, 280), "DRAFT ONLY  ·  THIS MISSION DOES NOT CHANGE GAME PROGRESS", HORIZONTAL_ALIGNMENT_LEFT, 728, 6, Color("f6757a"))
	draw_string(FONT, panel.position + Vector2(560, 280), "E / SPACE: CLOSE", HORIZONTAL_ALIGNMENT_RIGHT, 190, 6, Color("9aabc8"))

func _draw_environment() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DARK, true)
	# Dark teal bulkhead wall and grated floor, like the supplied gameplay scene.
	draw_rect(Rect2(16, 64, size.x - 32, 386), Color("123d3b"), true)
	for x in range(24, int(size.x - 20), 132):
		draw_rect(Rect2(x, 72, 5, 370), Color("1e5b4d"), true)
		draw_rect(Rect2(x + 12, 72, 66, 7), Color("46506f"), true)
	draw_rect(Rect2(16, 440, size.x - 32, size.y - 456), Color("262c42"), true)
	for x in range(20, int(size.x - 20), 96):
		draw_rect(Rect2(x, 444, 3, size.y - 466), Color("343d56"), true)
	for y in range(468, int(size.y - 18), 58):
		draw_line(Vector2(20, y), Vector2(size.x - 20, y), Color("343d56"), 3.0)
	# Pixel floor lights and small warning lamps.
	for x in range(36, int(size.x - 32), 42):
		var color := Color("57d8e9") if int(x / 42) % 3 == 0 else Color("f3ca52")
		draw_rect(Rect2(x, 458, 4, 4), color, true)
	# Fine scanlines keep the scene in the pixel-art style at larger window sizes.
	for y in range(78, int(size.y - 12), 6):
		draw_line(Vector2(20, y), Vector2(size.x - 20, y), Color(0.04, 0.06, 0.12, 0.12), 1.0)
	draw_rect(Rect2(14, 12, size.x - 28, size.y - 24), Color("5c6580"), false, 3.0)

func _draw_hud() -> void:
	draw_rect(Rect2(22, 20, size.x - 44, 50), DARK, true)
	draw_rect(Rect2(22, 20, size.x - 44, 50), Color("45516d"), false, 2.0)
	draw_string(FONT, Vector2(42, 42), "PROJECT DAWN  /  EARTH", HORIZONTAL_ALIGNMENT_LEFT, 430, 8, Color("b3c0d0"))
	draw_string(FONT, Vector2(42, 60), str(room_data.get("name", "STATION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 610, 10, TEXT_COLOR)
	var ozone := int(game_state.get("ozone", 0))
	var credits := int(game_state.get("credits", 0))
	draw_string(FONT, Vector2(size.x - 420, 51), "OZONE %d%%" % ozone, HORIZONTAL_ALIGNMENT_LEFT, 120, 7, Color("58d8e8"))
	draw_string(FONT, Vector2(size.x - 278, 51), "CREDITS %d" % credits, HORIZONTAL_ALIGNMENT_LEFT, 130, 7, Color("f3ca52"))
	draw_rect(MAP_BUTTON, Color("20213a"), true)
	draw_rect(MAP_BUTTON, Color("f3ca52"), false, 2.0)
	draw_string(FONT, Vector2(MAP_BUTTON.position.x + 8, MAP_BUTTON.position.y + 25), "MAP  <", HORIZONTAL_ALIGNMENT_CENTER, MAP_BUTTON.size.x - 16, 7, TEXT_COLOR)

func _draw_room_monitor() -> void:
	var monitor := Rect2(380, 88, 520, 330)
	draw_rect(monitor, Color("15162b"), true)
	draw_rect(monitor, Color("424462"), false, 12.0)
	draw_rect(monitor.grow(-14), Color("232844"), true)
	for y in range(105, 400, 8):
		draw_line(Vector2(397, y), Vector2(883, y), Color(0.04, 0.06, 0.12, 0.18), 1.0)
	var room_id := str(room_data.get("id", ""))
	match room_id:
		"launch_pad": _draw_rocket_view(monitor)
		"ozone_lab": _draw_scan_view(monitor)
		"engineering_workshop": _draw_build_view(monitor)
		"navigation_room": _draw_trajectory_view(monitor)
		"comms_room": _draw_comms_view(monitor)
		"power_supply": _draw_power_view(monitor)
		"airlock": _draw_airlock_view(monitor)
		"uv_canopy": _draw_shield_view(monitor)
		"med_bay": _draw_med_view(monitor)
		"crew_quarters": _draw_crew_view(monitor)
		"hydroponics": _draw_garden_view(monitor)
		_ : _draw_planet_view(monitor)
	draw_string(FONT, Vector2(monitor.position.x + 22, monitor.end.y - 18), _monitor_caption(room_id), HORIZONTAL_ALIGNMENT_LEFT, monitor.size.x - 44, 6, Color("aebdd3"))

func _draw_planet_view(monitor: Rect2) -> void:
	var center := monitor.get_center() + Vector2(0, -3)
	_draw_orbit(center, 120.0)
	draw_circle(center, 89.0, Color("075697"))
	draw_circle(center + Vector2(-12, -10), 82.0, Color("0c6ca2"))
	draw_rect(Rect2(center + Vector2(-64, -52), Vector2(45, 24)), Color("42a84e"), true)
	draw_rect(Rect2(center + Vector2(9, -3), Vector2(51, 39)), Color("318a46"), true)
	draw_rect(Rect2(center + Vector2(-42, 34), Vector2(23, 20)), Color("4cb456"), true)
	draw_rect(Rect2(center + Vector2(-60, -57), Vector2(28, 5)), TEXT_COLOR, true)

func _draw_orbit(center: Vector2, radius: float) -> void:
	for degree in range(0, 360, 9):
		var angle := deg_to_rad(float(degree))
		var point := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.88)
		draw_rect(Rect2(point, Vector2(5, 5)), Color("ed3549"), true)

func _draw_rocket_view(monitor: Rect2) -> void:
	_draw_stars(monitor)
	var center_x := monitor.get_center().x
	draw_colored_polygon(PackedVector2Array([Vector2(center_x - 36, 304), Vector2(center_x, 202), Vector2(center_x + 36, 304)]), Color("ece1c9"))
	draw_rect(Rect2(center_x - 36, 304, 72, 82), Color("dce4df"), true)
	draw_rect(Rect2(center_x - 36, 330, 72, 17), Color("ef6268"), true)
	draw_rect(Rect2(center_x - 15, 354, 30, 22), Color("60d5e5"), true)
	draw_rect(Rect2(center_x - 50, 370, 15, 40), Color("ff8a30"), true)
	draw_rect(Rect2(center_x + 35, 370, 15, 40), Color("ff8a30"), true)

func _draw_scan_view(monitor: Rect2) -> void:
	var left := monitor.position.x + 76.0
	var base_y := monitor.end.y - 72.0
	draw_line(Vector2(left, base_y), Vector2(monitor.end.x - 58.0, base_y), Color("aebdd3"), 2.0)
	draw_line(Vector2(left, monitor.position.y + 64.0), Vector2(left, base_y), Color("aebdd3"), 2.0)
	for index in range(14):
		var height := 40.0 + float((index * 37) % 130)
		draw_rect(Rect2(left + 20.0 + float(index) * 29.0, base_y - height, 14, height), ROLE_COLORS[1], true)
	draw_string(FONT, Vector2(left + 20, monitor.position.y + 42), "OZONE / UV SCAN", HORIZONTAL_ALIGNMENT_LEFT, 350, 8, Color("58d8e8"))

func _draw_build_view(monitor: Rect2) -> void:
	var cx := monitor.get_center().x
	var cy := monitor.get_center().y + 8.0
	for index in range(5):
		var x := cx - 142.0 + float(index) * 58.0
		draw_rect(Rect2(x, cy - 52, 46, 104), Color("39445a"), true)
		draw_rect(Rect2(x, cy - 52, 46, 104), Color("ff8a30"), false, 2.0)
		draw_rect(Rect2(x + 10, cy - 30, 26, 34), Color("b795ee" if index % 2 == 0 else "58d8e8"), true)
		draw_rect(Rect2(x + 8, cy + 18, 30, 5), Color("d8dbd0"), true)

func _draw_trajectory_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	_draw_orbit(center, 138.0)
	draw_circle(center, 34.0, Color("204977"))
	draw_circle(center, 26.0, Color("3b9d55"))
	for index in range(6):
		var x := monitor.position.x + 66.0 + float(index) * 76.0
		draw_circle(Vector2(x, monitor.position.y + 80.0 + float((index * 23) % 90)), 5.0, Color("f3ca52"))

func _draw_comms_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	for index in range(6):
		draw_arc(center, 24.0 + float(index) * 22.0, PI * 1.16, PI * 1.84, 32, Color("58d8e8"), 4.0)
	draw_rect(Rect2(center.x - 44, center.y - 5, 88, 10), Color("f3ca52"), true)
	draw_circle(center, 12.0, Color("ff8a30"))

func _draw_power_view(monitor: Rect2) -> void:
	for index in range(6):
		var x := monitor.position.x + 72.0 + float(index) * 61.0
		draw_rect(Rect2(x, monitor.position.y + 80, 44, 160), Color("293149"), true)
		draw_rect(Rect2(x, monitor.position.y + 80, 44, 160), Color("f3ca52"), false, 2.0)
		draw_rect(Rect2(x + 9, monitor.position.y + 111, 26, 93), Color("b6d978"), true)
		draw_rect(Rect2(x + 17, monitor.position.y + 98, 10, 15), Color("f3ca52"), true)

func _draw_airlock_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	draw_rect(Rect2(center.x - 86, center.y - 107, 172, 218), Color("0c1820"), true)
	draw_rect(Rect2(center.x - 86, center.y - 107, 172, 218), Color("58d8e8"), false, 4.0)
	draw_rect(Rect2(center.x - 66, center.y - 87, 68, 178), Color("40515c"), true)
	draw_rect(Rect2(center.x + 3, center.y - 87, 44, 178), Color("283b45"), true)
	for index in range(6):
		draw_rect(Rect2(center.x - 56 + float(index) * 24, center.y - 74, 10, 6), Color("f3ca52"), true)

func _draw_shield_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	for index in range(8):
		var x := monitor.position.x + 48.0 + float(index) * 56.0
		draw_rect(Rect2(x, center.y - 76, 8, 150), Color("64718b"), true)
		draw_rect(Rect2(x + 8, center.y - 76, 40, 7), Color("58d8e8"), true)
		draw_rect(Rect2(x + 8, center.y + 67, 40, 7), Color("58d8e8"), true)

func _draw_med_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	draw_rect(Rect2(center.x - 160, center.y - 42, 320, 88), Color("dce4df"), true)
	draw_rect(Rect2(center.x - 146, center.y - 26, 100, 54), Color("70b9d1"), true)
	draw_rect(Rect2(center.x - 4, center.y - 60, 22, 116), Color("ef6268"), true)
	draw_rect(Rect2(center.x - 48, center.y - 12, 110, 22), Color("ef6268"), true)

func _draw_crew_view(monitor: Rect2) -> void:
	var center := monitor.get_center()
	for index in range(4):
		var x := center.x - 152 + float(index) * 92.0
		var role_index := index
		_draw_character(ROLE_TEXTURES[role_index], Vector2(x, center.y - 62), ROLE_COLORS[role_index], 3.5)
		draw_rect(Rect2(x - 8, center.y + 8, 68, 5), ROLE_COLORS[role_index], true)

func _draw_garden_view(monitor: Rect2) -> void:
	for index in range(6):
		var x := monitor.position.x + 66.0 + float(index) * 70.0
		draw_rect(Rect2(x, monitor.end.y - 111, 48, 58), Color("405548"), true)
		draw_rect(Rect2(x + 12, monitor.end.y - 146, 24, 38), Color("70ae66"), true)
		draw_rect(Rect2(x + 22, monitor.end.y - 172, 5, 30), Color("a8ff8b"), true)

func _draw_stars(rect: Rect2) -> void:
	for star in [Vector2(0.12, 0.20), Vector2(0.25, 0.38), Vector2(0.75, 0.17), Vector2(0.84, 0.42), Vector2(0.65, 0.24)]:
		var star_pos: Vector2 = rect.position + Vector2(star.x * rect.size.x, star.y * rect.size.y)
		draw_rect(Rect2(star_pos, Vector2(5, 5)), TEXT_COLOR, true)

func _draw_large_character() -> void:
	var portrait_position := Vector2(88, 356)
	draw_rect(Rect2(portrait_position.x - 18, portrait_position.y - 15, 160, 172), Color("0b1020"), true)
	_draw_character(ROLE_TEXTURES[speaker_role], portrait_position, ROLE_COLORS[speaker_role], 8.0)
	var role_name: String = ROLE_NAMES[speaker_role]
	var label_width := 160.0
	draw_rect(Rect2(portrait_position.x - 5, portrait_position.y - 34, label_width, 26), ROLE_COLORS[speaker_role], true)
	draw_string(FONT, Vector2(portrait_position.x + 4, portrait_position.y - 16), role_name, HORIZONTAL_ALIGNMENT_LEFT, label_width - 14, 7, DARK)

func _draw_crew_sprites() -> void:
	for slot in range(3):
		var role_index := (speaker_role + slot + 1) % ROLE_NAMES.size()
		var position := Vector2(size.x - 246.0 + float(slot) * 74.0, 401.0)
		draw_rect(Rect2(position.x - 5, position.y - 4, 56, 58), Color("101327"), true)
		_draw_character(ROLE_TEXTURES[role_index], position, ROLE_COLORS[role_index], 3.0)

func _draw_dialogue() -> void:
	var panel := Rect2(286, 520, size.x - 315, 158)
	draw_rect(panel, DARK, true)
	draw_rect(panel, Color("f0e4c2"), false, 2.0)
	draw_rect(panel, ORANGE, false, 4.0)
	var role_name: String = ROLE_NAMES[speaker_role]
	var tab_width := maxf(174.0, float(role_name.length()) * 10.0)
	draw_rect(Rect2(panel.position.x + 18, panel.position.y - 18, tab_width, 34), ORANGE, true)
	draw_string(FONT, Vector2(panel.position.x + 28, panel.position.y + 5), role_name, HORIZONTAL_ALIGNMENT_LEFT, tab_width - 20.0, 9, DARK)
	var speaker_label := "CERES" if str(room_data.get("role", "Everyone")) == "Everyone" else role_name
	draw_string(FONT, Vector2(panel.position.x + 28, panel.position.y + 50), speaker_label + ":", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56, 8, Color("b6c4d2"))
	var line_text := "Welcome to this station."
	if dialogue_index < dialogue_lines.size():
		line_text = dialogue_lines[dialogue_index]
	var lines := _wrap_words(line_text, 78)
	var line_y := panel.position.y + 88.0
	for index in range(mini(lines.size(), 2)):
		draw_string(FONT, Vector2(panel.position.x + 28, line_y), lines[index], HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56, 12, TEXT_COLOR)
		line_y += 27.0
	var page_label := "%d / %d" % [mini(dialogue_index + 1, dialogue_lines.size()), dialogue_lines.size()]
	draw_string(FONT, Vector2(panel.end.x - 150, panel.end.y - 16), page_label, HORIZONTAL_ALIGNMENT_RIGHT, 120, 6, Color("97a7b7"))
	draw_string(FONT, Vector2(18, size.y - 5), "SPACE: NEXT LINE   ·   E: USE   ·   ESC: RETURN TO MAP", HORIZONTAL_ALIGNMENT_LEFT, 480, 6, Color("b6c4d2"))

func _draw_character(texture: Texture2D, position: Vector2, tint: Color, scale_factor: float) -> void:
	draw_texture_rect_region(texture, Rect2(position, Vector2(16, 16) * scale_factor), Rect2(0, 0, 16, 16), Color.WHITE)

func _draw_button(rect: Rect2, label: String) -> void:
	draw_rect(rect, Color("20213a"), true)
	draw_rect(rect, Color("f3ca52"), false, 2.0)
	draw_string(FONT, Vector2(rect.position.x + 8, rect.position.y + 25), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 7, TEXT_COLOR)

func _monitor_caption(room_id: String) -> String:
	match room_id:
		"launch_pad": return "FLIGHT SYSTEMS  /  LAUNCH WINDOW"
		"ozone_lab": return "ATMOSPHERIC READINGS  /  UV SPECTRUM"
		"engineering_workshop": return "VEHICLE DESIGN  /  SALVAGED PARTS"
		"navigation_room": return "TRAJECTORY PLOT  /  DESTINATION"
		"comms_room": return "SIGNAL NETWORK  /  DOWNLINK"
		"power_supply": return "BUNKER GRID  /  BATTERY STATUS"
		"airlock": return "SURFACE ACCESS  /  SEAL STATUS"
		"uv_canopy": return "PLATFORM SHIELD  /  SAFE PATH"
		"med_bay": return "CREW HEALTH  /  RECOVERY"
		"crew_quarters": return "HABITAT  /  CREW QUARTERS"
		"hydroponics": return "GROWING BAY  /  FOOD SYSTEMS"
		_: return "EARTH ORBIT  /  MISSION OVERVIEW"

func _wrap_words(text: String, max_chars: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if not line.is_empty() and line.length() + word.length() + 1 > max_chars:
			result.append(line)
			line = word
		else:
			line = word if line.is_empty() else line + " " + word
	if not line.is_empty():
		result.append(line)
	return result

func _find_speaker_role() -> int:
	var assigned_role: String = str(room_data.get("role", "Engineer"))
	for index in range(ROLE_NAMES.size()):
		if ROLE_NAMES[index].capitalize() in assigned_role:
			return index
	return 0

func _on_state_changed(new_state: Dictionary) -> void:
	game_state = new_state.duplicate(true)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point := _canvas_point(event.position)
		if MAP_BUTTON.has_point(point):
			back_requested.emit()
			accept_event()
		elif Rect2(68, 350, 48, 126).has_point(point):
			if not connected_rooms[0].is_empty():
				move_target = Vector2(136.0, 412.0)
			accept_event()
		elif Rect2(1164, 350, 48, 126).has_point(point):
			if not connected_rooms[1].is_empty():
				move_target = Vector2(1144.0, 412.0)
			accept_event()
		elif Rect2(390, 614, 500, 56).has_point(point) and not dialogue_open and _near_station():
			info_open = not info_open
			queue_redraw()
			accept_event()
		else:
			for index in range(ROLE_NAMES.size()):
				if Rect2(1050 + index * 54, 16, 54, 52).has_point(point):
					speaker_role = index
					queue_redraw()
					accept_event()
					return
			if _inside_walk_area(point):
				move_target = point
				accept_event()
				return

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_BACKSPACE:
			if info_open:
				info_open = false
				queue_redraw()
			else:
				back_requested.emit()
			get_viewport().set_input_as_handled()
		elif key_event.physical_keycode == KEY_SPACE:
			if dialogue_open:
				_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif key_event.physical_keycode == KEY_E or key_event.physical_keycode == KEY_ENTER:
			if info_open:
				info_open = false
				queue_redraw()
			elif _at_door():
				_try_use_door()
			elif not dialogue_open and _near_station():
				info_open = true
				queue_redraw()
			get_viewport().set_input_as_handled()
		elif key_event.physical_keycode == KEY_TAB:
			speaker_role = (speaker_role + 1) % ROLE_NAMES.size()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif key_event.physical_keycode >= KEY_1 and key_event.physical_keycode <= KEY_4:
			speaker_role = key_event.physical_keycode - KEY_1
			queue_redraw()
			get_viewport().set_input_as_handled()

func _door_name(index: int) -> String:
	if index < 0 or index >= connected_rooms.size() or connected_rooms[index].is_empty():
		return "SEALED"
	return str(connected_rooms[index].get("name", "NEXT ROOM")).to_upper()

func _at_door() -> bool:
	return player_position.y >= 360.0 and player_position.y <= 460.0 and (player_position.x <= 150.0 or player_position.x >= 1130.0)

func _try_use_door() -> bool:
	if connected_rooms.size() < 2 or not _at_door():
		return false
	if player_position.x <= 150.0 and not connected_rooms[0].is_empty():
		door_requested.emit(connected_rooms[0].duplicate(true), 1)
		return true
	if player_position.x >= 1130.0 and not connected_rooms[1].is_empty():
		door_requested.emit(connected_rooms[1].duplicate(true), 0)
		return true
	return false
func _near_station() -> bool:
	var room_id := str(room_data.get("id", ""))
	return player_position.distance_to(_station_position(room_id)) < 150.0

func _canvas_point(point: Vector2) -> Vector2:
	var fit := minf(size.x / 1280.0, size.y / 720.0)
	var offset := (size - Vector2(1280.0, 720.0) * fit) * 0.5
	return (point - offset) / fit

func _inside_walk_area(point: Vector2) -> bool:
	var dx := (point.x - 640.0) / 508.0
	var dy := (point.y - 412.0) / 196.0
	return dx * dx + dy * dy < 0.99

func _advance_dialogue() -> void:
	if dialogue_index < dialogue_lines.size() - 1:
		dialogue_index += 1
	else:
		dialogue_open = false
	queue_redraw()
