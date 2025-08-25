extends Control

@onready var term_rect: TermRect = $TermRect
@onready var root: TermContainerVBox = $TermRoot
@onready var title: TermLabel = $TermRoot/Title

func _ready() -> void:
    title.text = "ASCII Minimal Demo"
    # Force an initial render in-editor too
    term_rect.call_deferred("render")
