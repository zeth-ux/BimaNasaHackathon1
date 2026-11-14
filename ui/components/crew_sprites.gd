extends RefCounted
class_name CrewSprites
## Runtime recoloring for the exact walk-cycle sprites embedded in the supplied HTML.

const SHEETS: Array[Texture2D] = [
	preload("res://ui/art/characters/reference_engineer.png"),
	preload("res://ui/art/characters/reference_scientist.png"),
	preload("res://ui/art/characters/reference_navigator.png"),
	preload("res://ui/art/characters/reference_quartermaster.png")
]
const BODY_BASE: Array[Color] = [Color("f77622"), Color("0099db"), Color("3a4466"), Color("feae34")]
const PACK_BASE: Array[Color] = [Color("c0cbdc"), Color("c0cbdc"), Color("feae34"), Color("e43b44")]
static var _cache: Dictionary = {}

static func default_body(role: int) -> Color:
	return BODY_BASE[clampi(role, 0, BODY_BASE.size() - 1)]

static func default_pack(role: int) -> Color:
	return PACK_BASE[clampi(role, 0, PACK_BASE.size() - 1)]

static func sprite(role: int, body: Color, pack: Color) -> Texture2D:
	var index := clampi(role, 0, SHEETS.size() - 1)
	if body.is_equal_approx(BODY_BASE[index]) and pack.is_equal_approx(PACK_BASE[index]):
		return SHEETS[index]
	var key := "%d:%s:%s" % [index, body.to_html(false), pack.to_html(false)]
	if _cache.has(key):
		return _cache[key]
	var image := SHEETS[index].get_image().duplicate()
	var old_body := BODY_BASE[index]
	var body_dark := _shade(old_body, 0.66)
	var body_light := _shade(old_body, 1.3)
	var new_dark := _shade(body, 0.66)
	var new_light := _shade(body, 1.3)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.is_equal_approx(old_body):
				image.set_pixel(x, y, body)
			elif pixel.is_equal_approx(body_dark):
				image.set_pixel(x, y, new_dark)
			elif pixel.is_equal_approx(body_light):
				image.set_pixel(x, y, new_light)
			elif pixel.is_equal_approx(PACK_BASE[index]):
				image.set_pixel(x, y, pack)
	var result := ImageTexture.create_from_image(image)
	_cache[key] = result
	return result

static func _shade(color: Color, factor: float) -> Color:
	if factor <= 1.0:
		return Color(color.r * factor, color.g * factor, color.b * factor, color.a)
	return Color(
		color.r + (1.0 - color.r) * (factor - 1.0),
		color.g + (1.0 - color.g) * (factor - 1.0),
		color.b + (1.0 - color.b) * (factor - 1.0),
		color.a
	)
