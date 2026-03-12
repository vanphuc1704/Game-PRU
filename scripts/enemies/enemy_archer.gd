extends "res://scripts/enemies/enemy_base.gd"

## Mongol archer - stops at range and shoots arrows.

@export var shoot_range: float = 180.0
@export var arrow_speed: float = 350.0

var arrow_scene: PackedScene = preload("res://scenes/player/arrow.tscn")

func _ready() -> void:
	super._ready()
	attack_range = shoot_range
	attack_cooldown = 1.5
	enemy_color = Color(0.7, 0.3, 0.1)
	_setup_visuals()

func _perform_attack() -> void:
	can_attack = false
	attack_timer.start(attack_cooldown)
	if player_ref and is_instance_valid(player_ref):
		var dir = (player_ref.global_position - global_position).normalized()
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position + dir * 16
		arrow.direction = dir
		arrow.damage = attack_damage
		arrow.shooter = self
		get_tree().current_scene.add_child(arrow)
	sprite.modulate = Color(1, 0.7, 0.3)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)
