extends CanvasLayer

# Referencia a tu ColorRect
@onready var color_rect = $ColorRect

func _ready():
	# Asegúrate de que al iniciar esté invisible
	color_rect.color.a = 0
	color_rect.visible = false
	print("mksdmsdmsdmksmkd")

func fade_to_scene(ruta_escena: String):
	color_rect.visible = true
	
	# Creamos un nuevo Tween cada vez que lo necesitamos
	var tween = create_tween()
	
	# Animamos el alpha a 1 (negro)
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	
	# Esperamos a que termine la animación
	await tween.finished
	
	# Cambiamos la escena
	get_tree().change_scene_to_file(ruta_escena)
	
	# Creamos otro para volver a la transparencia
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "color:a", 0.0, 0.5)
	
	await tween_out.finished
	color_rect.visible = false
