extends Node2D

const SHADOW_SCENE := preload("res://scenes/enemies/vengeance_shadow.tscn")
var _active_shadow: VengeanceShadow
var _playtest_elapsed := 0.0
var _playtest_hits := 0
var _playtest_damage_received := 0.0
var _playtest_parries := 0
var _playtest_deaths := 0
var _playtest_checkpoints := 0
var _playtest_recoveries := 0
var _playtest_completed := false
var _telemetry_refresh_left := 0.0

@onready var player: KaelenController = $Kaelen
@onready var enemy: TrainingEnemy = $TrainingEnemy
@onready var health_bar: ProgressBar = $HUD/Margin/Panel/VBox/HealthBar
@onready var will_bar: ProgressBar = $HUD/Margin/Panel/VBox/WillBar
@onready var enemy_bar: ProgressBar = $HUD/Margin/Panel/VBox/EnemyBar
@onready var status_label: Label = $HUD/Margin/Panel/VBox/Status
@onready var telemetry_label: Label = $HUD/Margin/Panel/VBox/Telemetry

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.will_changed.connect(_on_will_changed)
	player.combat_state_changed.connect(func(label: String) -> void: status_label.text = "ESTADO: " + label)
	enemy.health_changed.connect(_on_enemy_health_changed)
	player.attack_hitbox.hit_landed.connect(_spawn_impact)
	player.attack_hitbox.hit_landed.connect(func(_position: Vector2, _type: StringName) -> void: _playtest_hits += 1)
	player.damage_received.connect(func(amount: float) -> void: _playtest_damage_received += amount)
	player.parry_succeeded.connect(func() -> void: _playtest_parries += 1)
	enemy.attack_hitbox.hit_landed.connect(_spawn_impact)
	GameState.scrap_changed.connect(_on_scrap_changed)
	GameState.death_registered.connect(_on_death_registered)
	GameState.resources_recovered.connect(_on_resources_recovered)
	GameState.checkpoint_changed.connect(func(_position: Vector2) -> void: _playtest_checkpoints += 1)
	for relic: BuilderRelic in get_tree().get_nodes_in_group("builder_relics"): relic.lore_requested.connect(_show_lore)
	_on_health_changed(player.health.current_health, player.health.max_health)
	_on_will_changed(player.will, player.max_will)
	_on_enemy_health_changed(enemy.health.current_health, enemy.health.max_health)
	_on_scrap_changed(GameState.scrap)
	if GameState.has_active_shadow: _spawn_shadow(GameState.death_position)
	_update_telemetry_label()

func _process(delta: float) -> void:
	if _playtest_completed: return
	_playtest_elapsed += delta; _telemetry_refresh_left -= delta
	if _telemetry_refresh_left <= 0.0: _telemetry_refresh_left = 0.25; _update_telemetry_label()

func _on_health_changed(current: float, maximum: float) -> void: health_bar.max_value = maximum; health_bar.value = current
func _on_will_changed(current: float, maximum: float) -> void: will_bar.max_value = maximum; will_bar.value = current
func _on_enemy_health_changed(current: float, maximum: float) -> void: enemy_bar.max_value = maximum; enemy_bar.value = current

func _spawn_impact(at: Vector2, attack_type: StringName) -> void:
	var flash := PointLight2D.new()
	var gradient := Gradient.new(); gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new(); texture.gradient = gradient; texture.width = 64; texture.height = 64; texture.fill = GradientTexture2D.FILL_RADIAL
	flash.texture = texture; flash.color = Color(1.0, 0.28, 0.12) if attack_type == &"heavy" else Color(0.3, 0.75, 1.0); flash.energy = 2.5
	add_child(flash); flash.global_position = at
	var tween := create_tween(); tween.tween_property(flash, "energy", 0.0, 0.14); tween.tween_callback(flash.queue_free)

func _on_scrap_changed(current: int) -> void: $HUD/Margin/Panel/VBox/ScrapLabel.text = "SUCATA DOS CONSTRUTORES: %d" % current
func _on_death_registered(position: Vector2, _lost_scrap: int) -> void: _playtest_deaths += 1; _spawn_shadow(position)
func _on_resources_recovered() -> void: _playtest_recoveries += 1; player.refresh_will_limit()

func _spawn_shadow(position: Vector2) -> void:
	if is_instance_valid(_active_shadow): _active_shadow.queue_free()
	_active_shadow = SHADOW_SCENE.instantiate(); add_child(_active_shadow); _active_shadow.global_position = position

func _show_lore(title: String, description: String) -> void:
	$HUD/LorePanel.visible = true; $HUD/LorePanel/Margin/VBox/Title.text = title; $HUD/LorePanel/Margin/VBox/Description.text = description; _complete_playtest()

func _update_telemetry_label() -> void:
	var minutes := int(_playtest_elapsed) / 60; var seconds := int(_playtest_elapsed) % 60
	telemetry_label.text = "PLAYTEST %02d:%02d | ACERTOS %d | DANO %.0f | PARRIES %d | MORTES %d | FOGUEIRAS %d | SOMBRAS %d" % [minutes, seconds, _playtest_hits, _playtest_damage_received, _playtest_parries, _playtest_deaths, _playtest_checkpoints, _playtest_recoveries]

func _complete_playtest() -> void:
	if _playtest_completed: return
	_playtest_completed = true; _update_telemetry_label(); telemetry_label.text += " | CONCLUÍDO"
	var file := FileAccess.open("user://playtest_last.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(_build_playtest_summary(), "  "))

func _build_playtest_summary() -> Dictionary:
	return {"duration_seconds": snappedf(_playtest_elapsed, 0.01), "target_duration_seconds": [600, 900], "hits_landed": _playtest_hits, "damage_received": snappedf(_playtest_damage_received, 0.01), "parries": _playtest_parries, "deaths": _playtest_deaths, "checkpoints_activated": _playtest_checkpoints, "shadows_recovered": _playtest_recoveries, "completed": _playtest_completed}

func _unhandled_input(event: InputEvent) -> void:
	if $HUD/LorePanel.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		$HUD/LorePanel.visible = false; get_viewport().set_input_as_handled()
