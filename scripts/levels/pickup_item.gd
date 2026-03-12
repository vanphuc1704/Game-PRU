extends Area2D

## Pickup item - interactable object that can be picked up by the player.

signal picked_up

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 16
	collision_mask = 0

func interact(_player: Node2D) -> void:
	picked_up.emit()
	queue_free()
