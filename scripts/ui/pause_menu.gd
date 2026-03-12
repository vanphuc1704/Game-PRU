extends Control

## Pause Menu - Resume, Restart, Main Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_pressed() -> void:
	GameManager.resume_game()
	queue_free()

func _on_restart_pressed() -> void:
	GameManager.resume_game()
	GameManager.restart_level()
	queue_free()

func _on_main_menu_pressed() -> void:
	GameManager.resume_game()
	GameManager.go_to_main_menu()
	queue_free()
