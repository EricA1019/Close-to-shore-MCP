extends HBoxContainer

@onready var status_label: Label = $StatusLabel
@onready var time_label: Label = $TimeLabel
@onready var location_label: Label = $LocationLabel
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	print("[TopStatus] _ready")
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
	if gc:
		# Connect to new time_changed signal (int)
		if not gc.is_connected("time_changed", Callable(self, "_on_time_changed_int")):
			print("[TopStatus] Connecting GameClock (new signal)")
			gc.connect("time_changed", Callable(self, "_on_time_changed_int"))
			# Initialize with current time if provider exposes it
			if gc.has_method("current_time"):
				var cur_time = int(gc.call("current_time"))
				_on_time_changed_int(cur_time)
		# Also connect to legacy signal for backward compatibility
		if not gc.is_connected("time_changed_str", Callable(self, "_on_time_changed")):
			print("[TopStatus] Connecting GameClock (legacy signal)")
			gc.connect("time_changed_str", Callable(self, "_on_time_changed"))
	
	# Connect to StatusSystem
	var ss: Node = root.find_child("StatusSystem", true, false)
	if ss and not ss.is_connected("status_changed", Callable(self, "_on_status_system_changed")):
		print("[TopStatus] Connecting StatusSystem")
		ss.connect("status_changed", Callable(self, "_on_status_system_changed"))
		# Initialize status label from current statuses if available
		_on_status_system_changed("E-001")
	
	var ps: Node = root.find_child("PlayerState", true, false)
	if ps:
		if not ps.is_connected("health_changed", Callable(self, "_on_health_changed")):
			print("[TopStatus] Connecting PlayerState health")
			ps.connect("health_changed", Callable(self, "_on_health_changed"))
			# Initialize with current health if provider exposes getters
			var has_cur := ps.has_method("get_current_health")
			var has_max := ps.has_method("get_max_health")
			if has_cur and has_max:
				var cur_hp = int(ps.call("get_current_health"))
				var max_hp = int(ps.call("get_max_health"))
				_on_health_changed(cur_hp, max_hp)
		if not ps.is_connected("status_changed", Callable(self, "_on_status_changed")):
			print("[TopStatus] Connecting PlayerState status")
			ps.connect("status_changed", Callable(self, "_on_status_changed"))
	var ls: Node = root.find_child("LocationState", true, false)
	if ls and not ls.is_connected("location_changed", Callable(self, "_on_location_changed")):
		print("[TopStatus] Connecting LocationState")
		ls.connect("location_changed", Callable(self, "_on_location_changed"))
		# Initialize from current value if available
		if ls.has_method("get_location"):
			var cur: String = String(ls.call("get_location"))
			if typeof(cur) == TYPE_STRING and cur != "":
				_on_location_changed(cur)

func _on_node_added(node: Node) -> void:
	if node.name == "GameClock" or node.name == "PlayerState" or node.name == "LocationState" or node.name == "StatusSystem":
		_try_connect_providers()

# Public helper for tests to force connections
func connect_providers() -> void:
	_try_connect_providers()

func _on_status_changed(text: String) -> void:
	print("[TopStatus] status_changed:", text)
	status_label.text = text

func _on_time_changed(time_str: String) -> void:
	print("[TopStatus] time_changed:", time_str)
	time_label.text = time_str

# New handler for GameClock time_changed signal (int)
func _on_time_changed_int(seconds_total: int) -> void:
	print("[TopStatus] time_changed_int:", seconds_total)
	var time_str = GameClock.format_time(seconds_total)
	time_label.text = time_str

# Handler for StatusSystem status_changed signal
func _on_status_system_changed(entity_id: String) -> void:
	print("[TopStatus] status_system_changed for entity:", entity_id)
	# For now, show active statuses for the player entity (E-001)
	if entity_id == "E-001":
		var ids: Array[String] = StatusSystem.get_statuses(entity_id)
		var names: Array[String] = []
		for sid in ids:
			var sres: StatusResource = EntityLoader.get_status(sid)
			if sres:
				names.append(sres.name)
			else:
				names.append(sid)
		var status_text = "Status: None"
		if names.size() > 0:
			status_text = "Status: " + ", ".join(names)
		status_label.text = status_text

func _on_location_changed(loc_name: String) -> void:
	print("[TopStatus] location_changed:", loc_name)
	location_label.text = loc_name

func _on_health_changed(current: int, max_hp: int) -> void:
	print("[TopStatus] health_changed:", current, "/", max_hp)
	health_label.text = "HP: %d/%d" % [current, max_hp]
