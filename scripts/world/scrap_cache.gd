class_name ScrapCache
extends Area2D

@export var amount := 40
@export var cache_id := "swamp_secret_cache_01"

func _ready() -> void:
	if cache_id in GameState.collected_caches:
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if body.has_method("play_pickup_animation"):
		body.play_pickup_animation()
	GameState.collect_cache(cache_id, amount)
	monitoring = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
