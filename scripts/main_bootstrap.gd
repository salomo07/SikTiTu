extends Node

## Bootstrap lama (main.tscn). Kini mengarah ke Main Menu — bukan langsung forest —
## supaya editor yang masih menganggap main.tscn sebagai scene utama tetap masuk menu.
func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/main/main_menu.tscn")
