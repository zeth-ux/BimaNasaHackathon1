extends RefCounted
## The world is a grid of screen-sized rooms (Isaac / early Zelda style).
## Owner: Sufi (gameplay). Used by maps and by the room camera (step 4).
##
## Room (0,0) covers world pixels x 0..320, y 0..180. Room (1,0) is to its right.
## 320x180 is exactly 16:9: one room fills the screen at zoom 4 (1280x720).

const ROOM_SIZE := Vector2(320, 180)


## Which room a world position is in.
static func room_of(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / ROOM_SIZE.x), floori(world_pos.y / ROOM_SIZE.y))


## The world rectangle of a room.
static func room_rect(room: Vector2i) -> Rect2:
	return Rect2(Vector2(room) * ROOM_SIZE, ROOM_SIZE)


## Centre of a room (where its camera looks).
static func room_center(room: Vector2i) -> Vector2:
	return room_rect(room).get_center()