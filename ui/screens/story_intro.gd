extends Control
## Pixel-art Act 1 story card shown between the title screen and wake-up room.

signal continue_requested

const FONT = preload("res://ui/fonts/PressStart2P-Regular.ttf")
const CrewSprites = preload("res://ui/components/crew_sprites.gd")
const ROLE_COLORS: Array[Color] = [Color("ff8d35"), Color("00bde9"), Color("db61a0"), Color("ffc04a")]
const ROLE_NAMES: Array[String] = ["ENGINEER", "SCIENTIST", "NAVIGATOR", "QUARTERMASTER"]
const ROLE_WORK: Array[String] = ["BUILDS · DRILLS", "INSTRUMENTS · ICE", "LAUNCHES · FUEL", "POWER · CARGO"]
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const NEXT_BUTTON := Rect2(1080.0, 626.0, 142.0, 44.0)
const SKIP_BUTTON := Rect2(916.0, 626.0, 146.0, 44.0)
const NIGHT := Color("111026")
const GOLD := Color("ffb735")
const CREAM := Color("f3e5bc")

var scale_factor := 1.0
var scale_offset := Vector2.ZERO
var story_lines: Array = []
var story_index := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	story_lines = GameEngine.get_dialogue("act1_intro")
	queue_redraw()

func _draw() -> void:
	scale_factor = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	scale_offset = (size - DESIGN_SIZE * scale_factor) * 0.5
	draw_set_transform(scale_offset, 0.0, Vector2.ONE * scale_factor)
	_draw_space_scene()
	_draw_story_panel()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_space_scene() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), NIGHT, true)
	for star in [Vector2(74, 104), Vector2(180, 213), Vector2(292, 78), Vector2(441, 176), Vector2(572, 84), Vector2(696, 202), Vector2(843, 92), Vector2(988, 197), Vector2(1140, 104), Vector2(1212, 264), Vector2(266, 330), Vector2(1060, 356)]:
		draw_rect(Rect2(star, Vector2(4, 4)), Color("cdd5ed"), true)
	draw_rect(Rect2(32, 30, 1216, 58), Color("17152c"), true)
	draw_rect(Rect2(32, 30, 1216, 58), Color("58617f"), false, 3.0)
	draw_string(FONT, Vector2(56, 68), "7  ·  YOUR CREW", HORIZONTAL_ALIGNMENT_LEFT, 500, 15, Color("ffe064"))
	draw_string(FONT, Vector2(124, 124), "FOUR SCIENTISTS. ONE MISSION TO BRING HUMANITY HOME.", HORIZONTAL_ALIGNMENT_LEFT, 1032, 9, Color("c0cbdc"))
	for index in range(ROLE_NAMES.size()):
		var column_x := 168.0 + float(index) * 240.0
		var center := Vector2(column_x + 72.0, 282.0)
		draw_rect(Rect2(column_x, 156, 144, 8), ROLE_COLORS[index], true)
		draw_rect(Rect2(column_x + 14, 178, 116, 146), Color("1c1a32"), true)
		draw_rect(Rect2(column_x + 14, 178, 116, 146), Color("414363"), false, 2.0)
		var sprite := CrewSprites.sprite(index, ROLE_COLORS[index], CrewSprites.default_pack(index))
		draw_texture_rect_region(sprite, Rect2(center - Vector2(44, 64), Vector2(88, 88)), Rect2(0, 0, 16, 16), Color.WHITE)
		draw_rect(Rect2(column_x + 5, 344, 134, 36), Color("17152c"), true)
		draw_rect(Rect2(column_x + 5, 344, 134, 36), ROLE_COLORS[index], false, 2.0)
		draw_string(FONT, Vector2(column_x + 8, 367), ROLE_NAMES[index], HORIZONTAL_ALIGNMENT_CENTER, 128, 7, Color("f3e5bc"))
		draw_string(FONT, Vector2(column_x - 10, 406), ROLE_WORK[index], HORIZONTAL_ALIGNMENT_CENTER, 164, 6, Color("a9a5bf"))
	draw_string(FONT, Vector2(54, 468), "BUNKER 4  /  ACT 1: FIRST LIGHT", HORIZONTAL_ALIGNMENT_LEFT, 800, 8, Color("9aabc8"))

func _draw_story_panel() -> void:
	var panel := Rect2(36, 500, 1208, 190)
	draw_rect(panel, Color("151328"), true)
	draw_rect(panel, GOLD, false, 4.0)
	for index in range(8):
		var color := Color("ffda62") if index <= story_index + 3 else Color("343957")
		draw_rect(Rect2(58 + index * 24, 520, 17, 7), color, true)
	var entry: Dictionary = story_lines[mini(story_index, maxi(story_lines.size() - 1, 0))] if not story_lines.is_empty() else {"speaker": "narrator", "text": "Bunker 4 is humanity's last safe home. The mission begins now."}
	var heading := "1  ·  THE SKY GOES DARK" if story_index == 0 else "2  ·  CERES AWAKENS"
	draw_string(FONT, Vector2(60, 558), heading, HORIZONTAL_ALIGNMENT_LEFT, 820, 12, Color("ffdf70"))
	var text := str(entry.get("text", ""))
	var wrapped := _wrap_words(text, 78)
	var line_y := 593.0
	for line in wrapped:
		draw_string(FONT, Vector2(60, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, 1120, 11, CREAM)
		line_y += 22.0
	_draw_button(SKIP_BUTTON, "SKIP INTRO")
	_draw_button(NEXT_BUTTON, "WAKE UP  >>")
	draw_string(FONT, Vector2(60, 674), "ENTER / SPACE: CONTINUE", HORIZONTAL_ALIGNMENT_LEFT, 360, 6, Color("9aabc8"))

func _draw_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color("2a2d4a"), true)
	draw_rect(rect, GOLD, false, 2.0)
	draw_string(FONT, Vector2(rect.position.x + 8, rect.position.y + 27), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 7, CREAM)

func _wrap_words(text: String, max_chars: int) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if not line.is_empty() and line.length() + word.length() + 1 > max_chars:
			lines.append(line)
			line = word
		else:
			line = word if line.is_empty() else line + " " + word
	if not line.is_empty():
		lines.append(line)
	return lines

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point := (get_global_mouse_position() - scale_offset) / scale_factor
		if SKIP_BUTTON.has_point(point):
			continue_requested.emit()
		elif NEXT_BUTTON.has_point(point):
			_advance_story()
		else:
			_advance_story()
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE:
			_advance_story()
			accept_event()

func _advance_story() -> void:
	if story_index < story_lines.size() - 1:
		story_index += 1
		queue_redraw()
	else:
		continue_requested.emit()
