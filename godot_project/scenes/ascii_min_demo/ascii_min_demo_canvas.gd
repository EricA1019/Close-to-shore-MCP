extends Control

@onready var ascii_canvas: Control = $AsciiCanvas
@onready var root: TermContainerVBox = $TermRoot
@onready var title: TermLabel = $TermRoot/Title

func _ready() -> void:
	title.text = "Basic ASCII Room Demo"
	# Force an initial render
	ascii_canvas.call_deferred("render")
