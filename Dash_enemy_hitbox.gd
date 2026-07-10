extends Area2D
var damage = 1
var owna

@export var velocidad: float = 250.0 
var direccion: Vector2 = Vector2.ZERO

func _ready() -> void:
	area_entered.connect(hit)
	

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta

func set_direccion(dir: Vector2) -> void:
	direccion = dir.normalized()
	global_rotation = direccion.angle() 


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func hit(area): 
	if !(area is hurtbox or shiesld):
		return
	
	if area is shiesld:
		queue_free()
	
	if area is hurtbox:
		if area.owner == owna:
			return
		
		for i in 10:
			owna.hitted = true
			area.receive_damage(damage)
			owna.hitted = false
