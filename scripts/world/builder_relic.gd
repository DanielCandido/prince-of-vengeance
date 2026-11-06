class_name BuilderRelic
extends Area2D

signal lore_requested(title: String, description: String)

@export var relic_id := "black_glass_lens"
@export var title := "Lente de Vidro Negro"
@export_multiline var description := "Um retângulo de metal e vidro escuro. Dizem que os Construtores olhavam para estas lâminas para conversar com espíritos distantes. A superfície trincada devolve a Kaelen apenas o próprio rosto."
var _player_nearby := false
var _already_read := false

func _ready() -> void:
	add_to_group("builder_relics")
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"): _player_nearby = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"): _player_nearby = false
	)

func _process(_delta: float) -> void:
	if _player_nearby and not _already_read and Input.is_action_just_pressed("interact"):
		_already_read = true
		var player := get_tree().get_first_node_in_group("player")
		if player != null and player.has_method("play_pickup_animation"):
			player.play_pickup_animation()
		GameState.discover_relic(relic_id)
		lore_requested.emit(title, description)
