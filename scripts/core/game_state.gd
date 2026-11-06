extends Node

signal scrap_changed(current: int)
signal checkpoint_changed(position: Vector2)
signal death_registered(position: Vector2, lost_scrap: int)
signal resources_recovered

var scrap := 0
var lost_scrap := 0
var checkpoint_position := Vector2(360.0, 500.0)
var will_locked := false
var has_active_shadow := false
var death_position := Vector2.ZERO
var collected_caches: Array[String] = []
var discovered_relics: Array[String] = []
const SAVE_PATH := "user://prince_of_vengeance_save.json"

func _ready() -> void:
	load_game()

func add_scrap(amount: int) -> void:
	scrap += maxi(amount, 0)
	scrap_changed.emit(scrap)

func activate_checkpoint(position: Vector2) -> void:
	checkpoint_position = position
	checkpoint_changed.emit(position)
	save_game()

func register_death(position: Vector2) -> void:
	lost_scrap = scrap
	scrap = 0
	will_locked = true
	has_active_shadow = true
	death_position = position
	scrap_changed.emit(scrap)
	death_registered.emit(position, lost_scrap)
	save_game()

func recover_resources() -> void:
	scrap += lost_scrap
	lost_scrap = 0
	will_locked = false
	has_active_shadow = false
	scrap_changed.emit(scrap)
	resources_recovered.emit()
	save_game()

func collect_cache(cache_id: String, amount: int) -> void:
	if cache_id in collected_caches: return
	collected_caches.append(cache_id)
	add_scrap(amount)
	save_game()

func discover_relic(relic_id: String) -> void:
	if relic_id not in discovered_relics:
		discovered_relics.append(relic_id)
		save_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Não foi possível salvar o progresso: %s" % FileAccess.get_open_error())
		return
	var data := {
		"version": 1,
		"scrap": scrap,
		"checkpoint": [checkpoint_position.x, checkpoint_position.y],
		"will_locked": will_locked,
		"lost_scrap": lost_scrap,
		"has_active_shadow": has_active_shadow,
		"death_position": [death_position.x, death_position.y],
		"collected_caches": collected_caches,
		"discovered_relics": discovered_relics,
	}
	file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	var data: Dictionary = parsed
	scrap = int(data.get("scrap", 0))
	will_locked = bool(data.get("will_locked", false))
	lost_scrap = int(data.get("lost_scrap", 0))
	has_active_shadow = bool(data.get("has_active_shadow", false))
	collected_caches.assign(data.get("collected_caches", []))
	discovered_relics.assign(data.get("discovered_relics", []))
	var saved_position: Array = data.get("checkpoint", [])
	if saved_position.size() == 2:
		checkpoint_position = Vector2(float(saved_position[0]), float(saved_position[1]))
	var saved_death: Array = data.get("death_position", [])
	if saved_death.size() == 2:
		death_position = Vector2(float(saved_death[0]), float(saved_death[1]))
