extends Control

## Game Over Screen

func _ready() -> void:
	pass

func _on_restart_pressed() -> void:
	GameManager.restart_level()

func _on_main_menu_pressed() -> void:
	GameManager.go_to_main_menu()
