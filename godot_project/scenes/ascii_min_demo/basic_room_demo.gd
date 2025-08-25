extends Control

@onready var ascii_canvas: Control = $AsciiCanvas
@onready var room_root: TermContainerVBox = $TermRoot
@onready var basic_room: TermElement = $TermRoot/BasicRoom

func _ready() -> void:
	print("[BasicRoomDemo] Setting up room scene")
	# Force an initial render
	ascii_canvas.call_deferred("render")
	print("[BasicRoomDemo] Room should be visible!")
