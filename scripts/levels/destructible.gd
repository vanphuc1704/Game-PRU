extends StaticBody2D

## Destructible object (training dummies, archery targets, etc.)

var hp: int = 20

func _ready() -> void:
	add_to_group("destructible")
	if has_meta("hp"):
		hp = get_meta("hp")

func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	# Flash
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(10, 10, 10)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			$Sprite2D.modulate = Color(1, 1, 1)
	if hp <= 0:
		# Destruction effect
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)
		await get_tree().create_timer(0.3).timeout
		queue_free()
