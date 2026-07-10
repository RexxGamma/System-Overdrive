extends CharacterBody2D

const BALA_ENEMIGA = preload("res://enemy_bullet.tscn")

@export var velocidad: float = 280.0
@export var distancia_ataque: float = 330.0
var max_lf = 1
var aceleración = 200.0
var rott_speed = 2.0
var bllt_vel = 120
var jugador: CharacterBody2D = null
var vector_hacia_jugador
var bullet_dir: Vector2
var direccion_fija : Vector2 = Vector2.ZERO
var enemy_pos
var vector_mirada
var dmg = 1

func _ready() -> void:
	jugador = get_parent().get_node("Character")
	_find_polygons(self)
	

func _physics_process(delta: float) -> void:
	
	if not jugador:
		return
	vector_mirada = Vector2.RIGHT.rotated(global_rotation)
	vector_hacia_jugador = jugador.global_position - global_position
	bullet_dir = vector_hacia_jugador.normalized()
	var distancia = vector_hacia_jugador.length()
	var direccion = vector_hacia_jugador.normalized()
	var diferencia_angular = vector_mirada.angle_to(direccion)
	
	var rott_destinysds = direccion.angle()
	var angle_diff = vector_mirada.angle_to(vector_hacia_jugador)
	#print(angle_diff)
	# 2. Rotar para mirar siempre al jugador (frente hacia la derecha en el editor)
	global_rotation = rotate_toward(global_rotation, rott_destinysds, rott_speed * delta)
	if distancia <= 144:
		rott_speed = 1.8
		bllt_vel = 300
	elif distancia > distancia_ataque:
		bllt_vel = 600
		rott_speed = rott_speed * 3
	
	if velocity.length() > 0:
		$Trail.emitting = true
	else:
		$Trail.emitting = false
	
	if distancia <= distancia_ataque and abs(angle_diff) < 1.0:
		
		intentar_disparar(bullet_dir)
	if distancia > distancia_ataque:
		velocity = direccion * velocidad
	elif distancia < 310:
		velocity = velocity.move_toward( direccion * -150, aceleración * delta)
	else:
		# Freno suave para que no se detenga en seco de forma irreal
		velocity = velocity.move_toward(Vector2.ZERO, velocidad * 5 * delta)
	move_and_slide()

func intentar_disparar(dir_disparo: Vector2) -> void:
	if not $Timer.is_stopped():
		return
		
	var new_bullet = BALA_ENEMIGA.instantiate()
	new_bullet.owna = self
	get_parent().add_child(new_bullet)
	
	# Spawnea un poco al frente de la nave enemiga
	new_bullet.global_position = global_position + dir_disparo * 15
	print(dir_disparo)
	new_bullet.set_direccion(dir_disparo)
	
	
	new_bullet.velocidad = bllt_vel 
	direccion_fija = Vector2.ZERO
	print("Lsllkslkslkddskdslkdlkalsklkaslklkkldslkalk")
	$Timer.start()

func _find_polygons(node: Node) -> void:
	if node == null:
		return
		
	for child in node.get_children():
		if child is Polygon2D:
			var pts = child.polygon
			if not pts.is_empty():
				_create_runtime_wireframe(child)
		else:
			_find_polygons(child)

func _create_runtime_wireframe(poly: Polygon2D) -> void:
	var pts := poly.polygon
	
	# --- Calcular centroide ---
	var area := 0.0
	var cx := 0.0
	var cy := 0.0
	for i in range(pts.size()):
		var j := (i + 1) % pts.size()
		var cross := pts[i].x * pts[j].y - pts[j].x * pts[i].y
		area += cross
		cx += (pts[i].x + pts[j].x) * cross
		cy += (pts[i].y + pts[j].y) * cross
	area *= 0.5
	if area == 0.0:
		return
	var centro_local := Vector2(cx / (6.0 * area), cy / (6.0 * area))

	# --- Crear un nodo de dibujo dinámico ---
	var wire_node := Node2D.new()
	wire_node.name = poly.name + "_RuntimeWire"
	
	# Lo ponemos como hermano del polígono (al mismo nivel)
	poly.get_parent().add_child(wire_node)
	
	# Le copiamos exactamente la posición y transformaciones del polígono original
	wire_node.position = poly.position
	wire_node.rotation = poly.rotation
	wire_node.scale = poly.scale
	
	# Forzamos un Z Index alto para que NADA en el juego lo tape (capas de fondo, etc.)
	wire_node.z_index = 50
	
	# Conectamos el evento de dibujo de Godot dinámicamente usando una función Lambda
	wire_node.draw.connect(func():
		var color: Color = poly.color
		var offset_total = poly.offset # Usamos el offset interno del polígono
		var thickness = 1.25
		
		# 1. CONTORNO EXTERIOR (Fino)
		for i in range(pts.size()):
			var p1 = pts[i] + offset_total
			var p2 = pts[(i + 1) % pts.size()] + offset_total
			wire_node.draw_line(p1, p2, color, 1.25, true)
		
		for i in range(pts.size()):
			var p1 = pts[i] 
			var p2 = pts[(i + 1) % pts.size()]
			wire_node.draw_line(p1, p2, Color.WHITE, thickness * 0.5, true)
		
		# 2. ANDAMIOS INTERNES
		var centro_final = centro_local + offset_total
		for i in range(pts.size()):
			if pts.size() > 4 and i % 2 != 0:
				continue
			var p_vertice = pts[i] + offset_total
			wire_node.draw_line(centro_final, p_vertice, color, 0.75, true)
	)
	
	# Ocultamos el polígono original de forma segura
	poly.visible = false
