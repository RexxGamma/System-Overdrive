extends CanvasLayer

var in_pause = false
@onready var menu: Control = $Pause_menu
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		
		if in_pause:
			menu.visible = false
			get_tree().paused = false
			in_pause = false
		else:
			
			menu.visible = true
			get_tree().paused = true
			in_pause = true

func _on_resume_pressed() -> void:
	menu.visible = false
	get_tree().paused = false
	in_pause = false

func _on_exit_pressed() -> void:
	menu.visible = false
	get_tree().paused = false
	in_pause = false
	get_tree().change_scene_to_file("res://Main_Menu.tscn")
	queue_free()


func _on_resume_mouse_entered() -> void:
	var t = create_tween()
	t.tween_property($Pause_menu/VBoxContainer/Resume,"scale", Vector2(1.1, 1.1), 0.1)

func _on_exit_mouse_entered() -> void:
	var t = create_tween()
	t.tween_property($Pause_menu/VBoxContainer/Exit,"scale", Vector2(1.1, 1.1), 0.1)


func _on_resume_mouse_exited() -> void:
	var wt = create_tween()
	wt.tween_property($Pause_menu/VBoxContainer/Resume,"scale", Vector2(1, 1), 0.1)

func _on_exit_mouse_exited() -> void:
	var wt = create_tween()
	wt.tween_property($Pause_menu/VBoxContainer/Exit,"scale", Vector2(1, 1), 0.1)
