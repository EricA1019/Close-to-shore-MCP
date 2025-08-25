class_name AsciiCanvasCell
extends RefCounted

## Data structure for a single ASCII cell containing character and colors.

var character: String = " "
var fg_color: Color = Color.WHITE
var bg_color: Color = Color.BLACK

func _init(ch: String = " ", fg: Color = Color.WHITE, bg: Color = Color.BLACK) -> void:
	character = ch
	fg_color = fg
	bg_color = bg

func equals(other: AsciiCanvasCell) -> bool:
	if not other:
		return false
	return character == other.character and fg_color == other.fg_color and bg_color == other.bg_color

func get_character_id() -> int:
	if character.is_empty():
		return 32  # Space
	return character.unicode_at(0)
