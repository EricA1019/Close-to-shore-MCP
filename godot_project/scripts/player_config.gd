extends Object

## Interface for a single configuration file through [ConfigFile].

const CONFIG_FILE_LOCATION := "user://player_config.cfg"

var config_file : ConfigFile

func _init() -> void:
	load_config_file()

func _save_config_file() -> void:
	var save_error : int = config_file.save(CONFIG_FILE_LOCATION)
	if save_error:
		push_error("save config file failed with error %d" % save_error)

func load_config_file() -> void:
	if config_file != null:
		return
	config_file = ConfigFile.new()
	var load_error : int = config_file.load(CONFIG_FILE_LOCATION)
	if load_error:
		var save_error : int = config_file.save(CONFIG_FILE_LOCATION)
		if save_error:
			push_error("save config file failed with error %d" % save_error)

func set_config(section: String, key: String, value) -> void:
	load_config_file()
	config_file.set_value(section, key, value)
	_save_config_file()

func get_config(section: String, key: String, default = null):
	load_config_file()
	return config_file.get_value(section, key, default)

func has_section(section: String) -> bool:
	load_config_file()
	return config_file.has_section(section)

func has_section_key(section: String, key: String) -> bool:
	load_config_file()
	return config_file.has_section_key(section, key)

func erase_section(section: String) -> void:
	if has_section(section):
		config_file.erase_section(section)
		_save_config_file()

func erase_section_key(section: String, key: String) -> void:
	if has_section_key(section, key):
		config_file.erase_section_key(section, key)
		_save_config_file()

func get_section_keys(section: String) -> PackedStringArray:
	load_config_file()
	if config_file.has_section(section):
		return config_file.get_section_keys(section)
	return PackedStringArray()
