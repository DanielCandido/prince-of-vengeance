class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal depleted

@export var max_health := 100.0
var current_health := 0.0

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if is_zero_approx(current_health):
		depleted.emit()

func heal(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
