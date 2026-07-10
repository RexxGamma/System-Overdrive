extends CanvasLayer

# Referencia a tu ColorRect
@onready var color_rect = $ColorRect

func _ready():
	
	color_rect.color.a = 0
	color_rect.visible = false
	print("mksdmsdmsdmksmkd")

func fade_to_scene(ruta_escena: String):
	color_rect.visible = true
	
	
	var tween = create_tween()
	
	
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	
	
	await tween.finished
	
	
	get_tree().change_scene_to_file(ruta_escena)
	
	
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color:a", 0.0, 0.5)
	
	await tween_out.finished
	color_rect.visible = false
