extends HBoxContainer

@onready var status_label: Label = $StatusLabel
@onready var time_label: Label = $TimeLabel
@onready var location_label: Label = $LocationLabel
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	# Connect to providers if present (no hard failure if missing in Hop 1)
	set_process(true)
	_try_connect_providers()
	# Also hook SceneTree changes so we connect as soon as providers are added
	get_tree().node_added.connect(Callable(self, "_on_node_added"))

func _process(_delta: float) -> void:
	# Lightweight polling so tests that add providers after _ready still connect
	_try_connect_providers()

func _try_connect_providers() -> void:
	var root := get_tree().get_root()
	var gc: Node = root.find_child("GameClock", true, false)
	if gc and not gc.is_connected("time_changed", Callable(self, "_on_time_changed")):
		gc.connect("time_changed", Callable(self, "_on_time_changed"))
	var ps: Node = root.find_child("PlayerState", true, false)
	if ps:
		if not ps.is_connected("health_changed", Callable(self, "_on_health_changed")):
			ps.connect("health_changed", Callable(self, "_on_health_changed"))
		if not ps.is_connected("status_changed", Callable(self, "_on_status_changed")):
			ps.connect("status_changed", Callable(self, "_on_status_changed"))
	var ls: Node = root.find_child("LocationState", true, false)
	if ls and not ls.is_connected("location_changed", Callable(self, "_on_location_changed")):
		ls.connect("location_changed", Callable(self, "_on_location_changed"))

func _on_node_added(node: Node) -> void:
	if node.name == "GameClock" or node.name == "PlayerState" or node.name == "LocationState":
		_try_connect_providers()

# Public helper for tests to force connections
func connect_providers() -> void:
	_try_connect_providers()

func _on_status_changed(text: String) -> void:
	status_label.text = text

func _on_time_changed(time_str: String) -> void:
	time_label.text = time_str

func _on_location_changed(loc_name: String) -> void:
	location_label.text = loc_name

func _on_health_changed(current: int, max_hp: int) -> void:
	health_label.text = "HP: %d/%d" % [current, max_hp]
