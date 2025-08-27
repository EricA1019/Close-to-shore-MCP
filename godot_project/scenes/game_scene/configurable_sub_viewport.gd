extends SubViewportContainer
@export var change_sub_window_size : bool = false
@export var sub_window_size : Vector2i = Vector2i(720, 405)
@export var update_root_size : bool = false
@export var root_node : NodePath

func setup() -> void:
	set_process_unhandled_input(false)
	if change_sub_window_size:
		var sub_viewport := get_viewport().get_viewport()
		if sub_viewport:
			sub_viewport.size = sub_window_size
	if update_root_size and not root_node.is_empty():
		var root := get_node(root_node)
		if root and root is Control:
			# Avoid anchor warnings: defer size change until after ready
			root.set_deferred("size", get_rect().size)

func _ready() -> void:
	setup()

