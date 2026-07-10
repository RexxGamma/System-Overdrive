extends CanvasLayer

func _ready() -> void:
	# Sube el layer para estar encima de todo
	layer = 100
	
	$VBoxContainer/Restart.pressed.connect(func():
		print("PRESSED")
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		queue_free()
	)
	
	$VBoxContainer/Menu.pressed.connect(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://Main_Menu.tscn")
		queue_free()
	)
