extends "res://scripts/enemies/enemy_base.gd"

## Mongol infantry - charges and attacks at close range.

func _ready() -> void:
	super._ready()
	max_hp = 80
	hp = max_hp
	attack_damage = 15
	chase_speed = 170.0
	attack_range = 40.0
	enemy_color = Color(0.8, 0.15, 0.15)
	_setup_visuals()
