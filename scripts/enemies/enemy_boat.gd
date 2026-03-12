extends "res://scripts/enemies/enemy_base.gd"

## Boat-based enemy for river combat.

@export var shoot_range_boat: float = 200.0
var arrow_scene: PackedScene = preload("res://scenes/player/arrow.tscn")

func _ready() -> void:
	super._ready()
	max_hp = 70
	hp = max_hp
	attack_damage = 12
	speed = 80.0
	chase_speed = 120.0
	attack_range = shoot_range_boat
	attack_cooldown = 2.0
	enemy_color = Color(0.6, 0.2, 0.3)
	_setup_visuals()
	# Make boat-shaped
	var img = Image.create(40, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.25, 0.1))
	# Enemy on boat
	for x in range(14, 26):
		for y in range(4, 16):
			img.set_pixel(x, y, enemy_color)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex

func _perform_attack() -> void:
	can_attack = false
	attack_timer.start(attack_cooldown)
	if player_ref and is_instance_valid(player_ref):
		var dir = (player_ref.global_position - global_position).normalized()
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position + dir * 20
		arrow.direction = dir
		arrow.damage = attack_damage
		arrow.shooter = self
		get_tree().current_scene.add_child(arrow)
