extends Control
## Playable opening room inspired by the supplied pixel-art bunker reference.

signal map_requested

const FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const CrewSprites = preload("res://ui/components/crew_sprites.gd")
const ROLE_TEXTURES: Array[Texture2D] = [
	preload("res://ui/art/characters/reference_engineer.png"),
	preload("res://ui/art/characters/reference_scientist.png"),
	preload("res://ui/art/characters/reference_navigator.png"),
	preload("res://ui/art/characters/reference_quartermaster.png")
]
const ROLE_NAMES: Array[String] = ["ENGINEER", "SCIENTIST", "NAVIGATOR", "QUARTERMASTER"]
const ROLE_COLORS: Array[Color] = [
	Color("ff9c55"), Color("20bfdc"), Color("d65f9c"), Color("f2cf61")
]
const ROLE_TOOLS: Array[String] = ["WRENCH", "SCANNER", "COMPASS", "CLIPBOARD"]
const MUTED := Color("a9bbb2")
const WALK_RECT := Rect2(280.0, 310.0, 740.0, 310.0)
const MOVE_SPEED := 520.0

var player_position := Vector2(665.0, 510.0)
var walk_target := Vector2.ZERO
var player_facing := Vector2.DOWN
var walk_phase := 0.0
var selected_role := 0
var starting_role := 0
var selected_suit_color := Color("ff9c55")
var selected_gear_color := Color("dce5e9")
var alarm_active := true
var objective_step := 0
var sound_enabled := true
var wake_prompt := true
var periscope_open := false
var crew_following := false
var dialogue_lines: Array = []
var dialogue_index := 0
var state: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	starting_role = selected_role
	state = GameEngine.get_state()
	dialogue_lines = GameEngine.get_dialogue("act1_intro")
	queue_redraw()

func _process(delta: float) -> void:
	if wake_prompt:
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
	if direction.length_squared() > 0.0:
		player_position += direction.normalized() * MOVE_SPEED * delta
		walk_target = Vector2.ZERO
	elif walk_target != Vector2.ZERO:
		var offset: Vector2 = walk_target - player_position
		if offset.length() < MOVE_SPEED * delta:
			player_position = walk_target
			walk_target = Vector2.ZERO
		else:
			player_position += offset.normalized() * MOVE_SPEED * delta
	player_position.x = clampf(player_position.x, WALK_RECT.position.x + 20.0, WALK_RECT.end.x - 20.0)
	player_position.y = clampf(player_position.y, WALK_RECT.position.y + 28.0, WALK_RECT.end.y - 26.0)
	if direction != Vector2.ZERO:
		player_facing = direction.normalized()
	elif walk_target != Vector2.ZERO:
		player_facing = (walk_target - player_position).normalized()
	if direction != Vector2.ZERO or walk_target != Vector2.ZERO:
		walk_phase += delta * 9.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if wake_prompt:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			wake_prompt = false
			queue_redraw()
			get_viewport().set_input_as_handled()
		return
	if periscope_open:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			periscope_open = false
			queue_redraw()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		match key_event.physical_keycode:
			KEY_1: _select_role(0)
			KEY_2: _select_role(1)
			KEY_3: _select_role(2)
			KEY_4: _select_role(3)
			KEY_TAB: _select_role((selected_role + 1) % ROLE_NAMES.size())
			KEY_F: crew_following = not crew_following
			KEY_E: _interact()
			KEY_M:
				objective_step = maxi(objective_step, 3)
				map_requested.emit()
			KEY_P: _open_periscope()
			KEY_SPACE: _advance_dialogue()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(point: Vector2) -> void:
	if point.y < 68.0 and point.x > 1060.0:
		if point.x > 1160.0:
			sound_enabled = not sound_enabled
		else:
			_restart_room()
		queue_redraw()
		return
	for index in range(4):
		var role_rect := Rect2(54.0, 112.0 + float(index) * 38.0, 166.0, 54.0)
		if role_rect.has_point(point):
			_select_role(index)
			return
	if point.y >= WALK_RECT.position.y and point.y <= WALK_RECT.end.y and point.x >= WALK_RECT.position.x and point.x <= WALK_RECT.end.x:
		walk_target = point
		return
	if Rect2(1096, 150, 124, 126).has_point(point):
		objective_step = maxi(objective_step, 3)
		map_requested.emit()
		return
	if Rect2(680, 132, 112, 142).has_point(point):
		_open_periscope()
		return
	if point.x > 910.0 and point.y > 170.0 and point.y < 310.0:
		_interact()
	elif point.y > 604.0:
		_advance_dialogue()

func _select_role(index: int) -> void:
	selected_role = clampi(index, 0, ROLE_NAMES.size() - 1)
	queue_redraw()

func active_suit_color() -> Color:
	return selected_suit_color if selected_role == starting_role else ROLE_COLORS[selected_role]

func _interact() -> void:
	if player_position.distance_to(Vector2(982.0, 276.0)) < 150.0:
		alarm_active = false
		objective_step = maxi(objective_step, 1)
	elif player_position.distance_to(Vector2(1158.0, 210.0)) < 250.0:
		objective_step = maxi(objective_step, 3)
		map_requested.emit()
	elif player_position.distance_to(Vector2(730.0, 276.0)) < 120.0:
		_open_periscope()
	queue_redraw()

func _open_periscope() -> void:
	periscope_open = true
	objective_step = maxi(objective_step, 2)
	queue_redraw()

func _advance_dialogue() -> void:
	if dialogue_index < dialogue_lines.size():
		dialogue_index += 1
	queue_redraw()

func _restart_room() -> void:
	player_position = Vector2(665.0, 510.0)
	walk_target = Vector2.ZERO
	selected_role = starting_role
	alarm_active = true
	dialogue_index = 0
	queue_redraw()

func _draw() -> void:
	if wake_prompt:
		_draw_wake_prompt()
		return
	_draw_room()
	_draw_hud()
	_draw_dialogue()
	if periscope_open:
		_draw_periscope()

func _draw_wake_prompt() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("05050b"), true)
	var panel := Rect2(size * 0.5 - Vector2(275.0, 75.0), Vector2(550.0, 150.0))
	draw_rect(panel, Color("292d50"), true)
	draw_rect(Rect2(panel.position.x, panel.end.y - 8.0, panel.size.x, 8.0), Color("17152c"), true)
	draw_string(FONT, Vector2(panel.position.x + 28, panel.position.y + 58), "CLICK OR PRESS ANY KEY", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 56, 16, Color("f6e7bc"))
	draw_string(FONT, Vector2(panel.position.x + 28, panel.position.y + 100), "TO WAKE UP", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 56, 16, Color("f6e7bc"))
	draw_string(FONT, Vector2(panel.position.x, panel.end.y + 34), "SOMETHING IS BEEPING. SOUND ON.", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 8, Color("9eb3d0"))

func _draw_room() -> void:
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, Color("061710"), true)
	# Outer neon trim and room shell.
	draw_rect(Rect2(18, 16, 1244, 688), Color("58617f"), false, 3.0)
	draw_rect(Rect2(30, 82, 1220, 538), Color("0c2923"), true)
	draw_rect(Rect2(30, 82, 1220, 200), Color("174238"), true)
	draw_rect(Rect2(30, 282, 1220, 338), Color("071a16"), true)
	# Wall panels and floor tiles.
	for x in range(48, 1240, 96):
		draw_rect(Rect2(x, 92, 3, 174), Color("1b574b"), true)
		draw_rect(Rect2(x, 296, 3, 312), Color("123b33"), true)
	for y in range(290, 610, 48):
		for x in range(34, 1240, 48):
			var tile_row := int((y - 290) / 48)
			var tile_column := int((x - 34) / 48)
			var tile_color := Color("09241f") if (tile_row + tile_column) % 2 == 0 else Color("061d19")
			draw_rect(Rect2(x, y, 46, 46), tile_color, true)
	for y in range(318, 610, 48):
		draw_line(Vector2(42, y), Vector2(1238, y), Color("15443b"), 1.0)
	# Screen texture from the video reference; furniture remains crisp above the scanlines.
	for y in range(84, 610, 6):
		draw_line(Vector2(30, y), Vector2(1250, y), Color(0.03, 0.03, 0.08, 0.16), 1.0)
	# Ceiling light bars.
	for x in [300.0, 610.0, 920.0]:
		draw_rect(Rect2(x, 96, 82, 5), Color("a8ff8b"), true)
		draw_rect(Rect2(x + 8, 101, 66, 4), Color("47614b"), true)
	_draw_pods()
	_draw_alarm_console()
	_draw_periscope_device()
	_draw_map_terminal()
	_draw_door()
	_draw_floor_details()
	_draw_player()

func _draw_pods() -> void:
	for index in range(4):
		var y := 126.0 + float(index) * 38.0
		var pod := Rect2(76, y, 132, 32)
		draw_rect(pod, Color("0a1318"), true)
		draw_rect(pod, Color("426266"), false, 2.0)
		draw_rect(Rect2(85, y + 6, 92, 20), Color("1d3035"), true)
		draw_rect(Rect2(92, y + 9, 70, 4), Color("77a9a5"), true)
		draw_rect(Rect2(92, y + 16, 48, 3), Color("3f686b"), true)
		var role_index := index
		_draw_character(ROLE_TEXTURES[role_index], Vector2(182, y + 1), 1.6, ROLE_COLORS[role_index])
		draw_string(FONT, Vector2(76, y + 43), ROLE_NAMES[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ROLE_COLORS[index])
	# Current role highlight panel.
	draw_rect(Rect2(54, 112.0 + float(selected_role) * 38.0, 166, 54), ROLE_COLORS[selected_role], false, 1.5)

func _draw_alarm_console() -> void:
	# Large warning console, like the objective panel in the reference footage.
	draw_rect(Rect2(880, 156, 208, 150), Color("342b35"), true)
	draw_rect(Rect2(880, 156, 208, 150), Color("74718a"), false, 4.0)
	var signal_color := Color("ed352f") if alarm_active else Color("35d74c")
	draw_rect(Rect2(899, 174, 170, 92), signal_color, true)
	draw_rect(Rect2(899, 174, 170, 92), Color("1b1527"), false, 4.0)
	draw_string(FONT, Vector2(940, 250), "!" if alarm_active else "OK", HORIZONTAL_ALIGNMENT_CENTER, 90, 56, Color("fff1d4"))
	draw_rect(Rect2(915, 274, 138, 18), Color("19162a"), true)
	draw_rect(Rect2(924, 279, 34, 7), signal_color, true)
	draw_string(FONT, Vector2(908, 327), "ALARM CONSOLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("c1bfd1"))

func _draw_periscope_device() -> void:
	draw_rect(Rect2(718, 132, 24, 100), Color("718296"), true)
	draw_rect(Rect2(712, 132, 36, 14), Color("bbc5cc"), true)
	draw_rect(Rect2(712, 218, 36, 16), Color("55546d"), true)
	draw_rect(Rect2(700, 234, 60, 12), Color("25263b"), true)
	draw_rect(Rect2(680, 248, 112, 23), Color("081014"), true)
	draw_rect(Rect2(680, 248, 112, 23), Color("f3b735"), false, 2.0)
	draw_string(FONT, Vector2(689, 265), "PERISCOPE  P", HORIZONTAL_ALIGNMENT_LEFT, 98, 6, Color("f2dfae"))
	if objective_step == 1 and not alarm_active:
		draw_rect(Rect2(664, 108, 152, 22), Color("090e16"), true)
		draw_string(FONT, Vector2(670, 123), "E: LOOK OUTSIDE", HORIZONTAL_ALIGNMENT_LEFT, 144, 6, Color("ffb735"))

func _draw_periscope() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("03030a"), true)
	var center := size * 0.5
	draw_circle(center, 258.0, Color("30394d"))
	draw_circle(center, 238.0, Color("281b4f"))
	# Dusk sky and the Martian horizon, composed inside the circular lens.
	draw_rect(Rect2(center.x - 218, center.y - 28, 436, 62), Color("b35b9c"), true)
	draw_rect(Rect2(center.x - 208, center.y + 34, 416, 50), Color("e49c6d"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 210, center.y + 34), Vector2(center.x - 165, center.y + 6),
		Vector2(center.x - 120, center.y + 32), Vector2(center.x - 73, center.y - 4),
		Vector2(center.x - 28, center.y + 34), Vector2(center.x + 30, center.y + 1),
		Vector2(center.x + 78, center.y + 33), Vector2(center.x + 132, center.y - 10),
		Vector2(center.x + 205, center.y + 34)
	]), Color("38204f"))
	draw_circle(center + Vector2(104, -18), 31, Color("f3d18c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - 92, center.y + 52), Vector2(center.x + 92, center.y + 52),
		Vector2(center.x + 38, center.y + 220), Vector2(center.x - 38, center.y + 220)
	]), Color("44275c"))
	for index in range(5):
		var y := center.y + 78.0 + float(index) * 28.0
		draw_rect(Rect2(center.x - 4, y, 8, 13), Color("d88ab0"), true)
	draw_rect(Rect2(center.x - 3, center.y - 220, 6, 26), Color("68f36e"), true)
	draw_rect(Rect2(center.x - 3, center.y + 194, 6, 26), Color("68f36e"), true)
	draw_arc(center, 244.0, 0.0, TAU, 96, Color("68738b"), 9.0)
	draw_string(FONT, Vector2(40, 62), "LOOK OUTSIDE THROUGH THE PERISCOPE", HORIZONTAL_ALIGNMENT_LEFT, 720, 9, Color("f3e5bc"))
	draw_string(FONT, Vector2(440, size.y - 34), "PRESS ANY KEY TO RETURN", HORIZONTAL_ALIGNMENT_CENTER, 400, 7, Color("a9bbb2"))

func _draw_map_terminal() -> void:
	draw_rect(Rect2(1096, 150, 124, 126), Color("080f13"), true)
	draw_rect(Rect2(1096, 150, 124, 126), Color("587477"), false, 3.0)
	draw_rect(Rect2(1105, 160, 106, 86), Color("0e2528"), true)
	# Simple bunker mini-map.
	for room in [Rect2(1113, 169, 32, 22), Rect2(1152, 169, 48, 22), Rect2(1113, 198, 38, 36), Rect2(1158, 198, 42, 36)]:
		draw_rect(room, Color("34524d"), true)
		draw_rect(room, Color("6e9d77"), false, 1.0)
	draw_line(Vector2(1145, 180), Vector2(1152, 180), Color("a8ff8b"), 2.0)
	draw_line(Vector2(1132, 191), Vector2(1132, 198), Color("a8ff8b"), 2.0)
	draw_circle(Vector2(1132, 214), 3, Color("ff6262") if alarm_active else Color("a8ff8b"))
	draw_string(FONT, Vector2(1100, 297), "BUNKER MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9db6ae"))

func _draw_door() -> void:
	# Heavy double bulkhead at the right end of the room.
	draw_rect(Rect2(1160, 350, 78, 192), Color("0c1519"), true)
	draw_rect(Rect2(1160, 350, 78, 192), Color("587477"), false, 3.0)
	draw_rect(Rect2(1168, 360, 29, 172), Color("233337"), true)
	draw_rect(Rect2(1201, 360, 29, 172), Color("233337"), true)
	draw_rect(Rect2(1196, 360, 6, 172), Color("0b1114"), true)
	for y in range(374, 526, 24):
		draw_rect(Rect2(1174, y, 16, 4), Color("d3b957"), true)
		draw_rect(Rect2(1206, y, 16, 4), Color("d3b957"), true)
	draw_circle(Vector2(1199, 347), 5, Color("ff6262") if alarm_active else Color("a8ff8b"))

func _draw_floor_details() -> void:
	# Floor markings, cable channel, and small workbench.
	draw_rect(Rect2(258, 338, 8, 250), Color("28383a"), true)
	draw_rect(Rect2(258, 338, 8, 250), Color("54716a"), false, 1.0)
	draw_rect(Rect2(340, 360, 178, 48), Color("202d30"), true)
	draw_rect(Rect2(340, 360, 178, 48), Color("40595b"), false, 2.0)
	for i in range(5):
		draw_rect(Rect2(354 + i * 30, 370, 19, 5), Color("6e8580"), true)
		draw_rect(Rect2(354 + i * 30, 383, 19, 5), Color("3b5754"), true)
	# Interaction prompt when close to the console.
	if alarm_active and player_position.distance_to(Vector2(982, 276)) < 260.0:
		draw_rect(Rect2(915, 120, 140, 24), Color("0a1114"), true)
		draw_rect(Rect2(915, 120, 140, 24), Color("a8ff8b"), false, 1.0)
		draw_string(FONT, Vector2(923, 137), "E: STOP ALARM", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("a8ff8b"))
	elif objective_step == 2 and player_position.distance_to(Vector2(1158, 210)) < 250.0:
		draw_rect(Rect2(1088, 120, 140, 24), Color("0a1114"), true)
		draw_rect(Rect2(1088, 120, 140, 24), Color("a8ff8b"), false, 1.0)
		draw_string(FONT, Vector2(1097, 137), "E: READ THE MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("a8ff8b"))

func _draw_player() -> void:
	# Animated crew sprite, colored by profession, with the selected suit accents.
	_draw_ellipse(Rect2(player_position.x - 28, player_position.y + 20, 56, 13), Color(0, 0, 0, 0.5))
	var suit_color := active_suit_color()
	var sprite_position := player_position - Vector2(29, 42)
	var source_row := 0
	if player_facing.y < 0.0:
		source_row = 1
	elif player_facing.x < 0.0:
		source_row = 2
	elif player_facing.x > 0.0:
		source_row = 3
	var walking := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D) or walk_target != Vector2.ZERO
	var frame := int(walk_phase) % 4 if walking else 0
	var source := Rect2(frame * 16, source_row * 16, 16, 16)
	var pack_color := selected_gear_color if selected_role == starting_role else CrewSprites.default_pack(selected_role)
	_draw_character(CrewSprites.sprite(selected_role, suit_color, pack_color), sprite_position, 3.6, Color.WHITE, source)
	draw_rect(Rect2(player_position.x - 27, player_position.y + 28, 54, 18), Color("071014"), true)
	draw_string(FONT, Vector2(player_position.x - 23, player_position.y + 41), ROLE_NAMES[selected_role], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, ROLE_COLORS[selected_role])
	if crew_following:
		for index in range(ROLE_NAMES.size()):
			if index == selected_role:
				continue
			var follow_offset := Vector2(float(index - 1) * 28.0, 36.0 + float(index % 2) * 20.0)
			_draw_character(ROLE_TEXTURES[index], player_position + follow_offset - Vector2(10, 16), 1.3, ROLE_COLORS[index])

func _draw_character(texture: Texture2D, position: Vector2, scale_factor: float, tint: Color, source: Rect2 = Rect2(0, 0, 16, 16)) -> void:
	var destination := Rect2(position, Vector2(16, 16) * scale_factor)
	draw_texture_rect_region(texture, destination, source, Color.WHITE)

func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)

func _draw_hud() -> void:
	# Header strip.
	draw_rect(Rect2(30, 16, 1220, 56), Color("091316"), true)
	draw_string(FONT, Vector2(48, 39), "PROJECT DAWN   /   BUNKER 4", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("dce8db"))
	draw_string(FONT, Vector2(48, 59), "ACT 1: FIRST LIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("83a49c"))
	_draw_button(Rect2(1074, 27, 72, 30), "SOUND", sound_enabled)
	_draw_button(Rect2(1156, 27, 78, 30), "RESTART", false)
	for index in range(ROLE_NAMES.size()):
		var role_rect := Rect2(638.0 + float(index) * 48.0, 25.0, 38.0, 30.0)
		draw_rect(role_rect, Color("141527"), true)
		draw_rect(role_rect, ROLE_COLORS[index], false, 2.0 if selected_role == index else 1.0)
		draw_string(FONT, role_rect.position + Vector2(10, 21), ["E", "S", "N", "Q"][index], HORIZONTAL_ALIGNMENT_LEFT, 20, 8, ROLE_COLORS[index])
	# Objective card.
	draw_rect(Rect2(290, 96, 330, 54), Color("081215"), true)
	draw_rect(Rect2(290, 96, 330, 54), Color("a8ff8b"), false, 2.0)
	draw_string(FONT, Vector2(306, 118), "OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("91ba9b"))
	var objective := "TURN OFF THE ALARM" if objective_step == 0 else "LOOK THROUGH PERISCOPE" if objective_step == 1 else "CHECK THE BUNKER MAP" if objective_step == 2 else "EXPLORE THE BUNKER"
	draw_string(FONT, Vector2(306, 138), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("f0eedc"))
	# Engine-owned state is displayed without inventing a second source.
	state = GameEngine.get_state()
	var ozone: int = int(state.get("ozone", 0))
	var credits: int = int(state.get("credits", 0))
	draw_string(FONT, Vector2(850, 58), "OZONE %d%%" % ozone, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("78d7ef"))
	draw_string(FONT, Vector2(970, 58), "CREDITS %d" % credits, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f2cf61"))
	# Role selector and instructions.
	draw_string(FONT, Vector2(54, 100), "CREW / 1-4 TO SELECT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a8ff8b"))
	draw_string(FONT, Vector2(50, 535), "ROLE: " + ROLE_NAMES[selected_role] + "  /  " + ROLE_TOOLS[selected_role], HORIZONTAL_ALIGNMENT_LEFT, 540, 7, ROLE_COLORS[selected_role])

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	var color := Color("a8ff8b") if active else Color("45605e")
	draw_rect(rect, Color("101e20"), true)
	draw_rect(rect, color, false, 1.5)
	draw_string(FONT, Vector2(rect.position.x + 5, rect.position.y + 19), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, 6, Color("dce8db"))

func _draw_dialogue() -> void:
	var panel := Rect2(30, 536, 1220, 142)
	draw_rect(panel, Color("17152c"), true)
	draw_rect(panel, Color("20d9df"), false, 3.0)
	var line_text := "Welcome back, crew. The bunker alarm is active."
	var speaker := "CERES"
	if dialogue_index < dialogue_lines.size():
		var line: Dictionary = dialogue_lines[dialogue_index]
		speaker = str(line.get("speaker", "ceres")).to_upper()
		line_text = str(line.get("text", line_text))
	var speaker_color := Color("20d9df") if speaker == "CERES" else ROLE_COLORS[selected_role]
	draw_rect(Rect2(48, 518, 150, 34), speaker_color, true)
	draw_string(FONT, Vector2(60, 541), speaker, HORIZONTAL_ALIGNMENT_LEFT, 130, 9, Color("17152c"))
	draw_string(FONT, Vector2(62, 601), line_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 124, 12, Color("f3e5bc"))
	draw_string(FONT, Vector2(panel.end.x - 230, panel.end.y - 18), "SPACE / CLICK: CONTINUE", HORIZONTAL_ALIGNMENT_RIGHT, 210, 6, Color("a9bbb2"))
	draw_rect(Rect2(0, 684, size.x, 36), Color("17152c"), true)
	draw_string(FONT, Vector2(48, 709), "WASD WALK · CLICK FLOOR · E USE · SPACE DIALOGUE · TAB ROLE · F FOLLOW · M MAP", HORIZONTAL_ALIGNMENT_LEFT, size.x - 320.0, 6, MUTED)
