extends Control

## Main Menu

func _ready() -> void:
	GameManager.current_state = GameManager.GameState.MENU

func _on_start_pressed() -> void:
	GameManager.start_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
