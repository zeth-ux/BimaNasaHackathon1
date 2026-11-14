extends Camera2D
## Isaac / early Zelda camera: shows exactly one room, and slides to the next
## room when its player walks through a door. Owner: Sufi (gameplay).
##
## Usage: var cam = RoomCamera.new(); cam.target = some_player; add_child(cam)
## One RoomCamera per player (split screen comes in step 5).

const RoomGrid := preload("res://game/world/room_grid.gd")

@export var slide_time := 0.35          ## seconds for the room-to-room slide
@export var freeze_during_slide := true ## stop the player while the screen slides (Zelda feel)
@export var switch_margin := 4.0        ## pixels past the doorway before switching (no flicker)

var target: Node2D:
	set(value):
		target = value
		if target and is_inside_tree():
			_snap_to(RoomGrid.room_of(target.global_position))

var current_room := Vector2i.ZERO
var _tween: Tween
