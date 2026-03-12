extends Control

## Victory Screen

func _ready() -> void:
	pass

func _on_main_menu_pressed() -> void:
	GameManager.go_to_main_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()
