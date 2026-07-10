extends Area2D

var damage
var owna
var hittad = false

var velocidad
var direccion: Vector2 = Vector2.ZERO

func _ready():
	area_entered.connect(hit)
	$CollisionShape2D.disabled = true
	visible = false
	$Line2D.points = [Vector2.ZERO, Vector2.ZERO]

func _physics_process(delta: float) -> void:
	if owna == null:
		damage = 1
		velocidad = 250
	else:
		velocidad = owna.bllt_vel
		damage = owna.dmg
	global_position += direccion * velocidad * delta

func set_direccion(dir: Vector2) -> void:
	direccion = dir.normalized()
	global_rotation = direccion.angle() 


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func hit(area):
	
	if !(area is hurtbox or shiesld):
		return
	
	if area is hurtbox:
		if area.owner == owna:
			return
		
		for i in 10:
			area.receive_damage(damage)
			
	
	

func disparar(direccsion: Vector2, longitud: float):
	var dir_normalizada = direccsion.normalized()
	
	var puntos_actuales = $Line2D.points
	if puntos_actuales.size() >= 2:
		puntos_actuales[1] = direccsion * longitud
	
	$Line2D.points = puntos_actuales
	$Line2DWhite2.points = puntos_actuales
	
	var shape = $CollisionShape2D.shape as RectangleShape2D
	# El tamaño X es la longitud total, el Y es el grosor del láser
	shape.size = Vector2(longitud, 20) 
	
	var punto_medio = (dir_normalizada * longitud) / 2.0
	$CollisionShape2D.position = punto_medio
	$CollisionShape2D.rotation = dir_normalizada.angle()
	
	$CollisionShape2D.rotation = direccsion.angle()
	
	$CollisionShape2D.disabled = false
	visible = true
	
	await get_tree().create_timer(0.5).timeout
	if owna != null:
		owna.puede_apuntar = true
	
	# borrar la cuenta
	$CollisionShape2D.disabled = true
	visible = false
	queue_free()
