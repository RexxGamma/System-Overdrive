extends CharacterBody2D

const BALA_ENEMIGA = preload("res://enemy_bullet.tscn")

@export var velocidad: float = 400.0
@export var margen_derecho: float = 150.0
@export var velocidad_maxima: float = 700.0
@export var suavizado: float = 4.0
@export var amplitud_tambaleo: float = 100.0
@export var frecuencia_tambaleo: float = 3.0

var max_lf = 6
var jugador: CharacterBody2D = null
var dmg = 1
var bllt_vel = 500
var camara: Camera2D
var target_y: float
var tiempo_oscilacion: float = 0.0
var vector_hacia_jugador: Vector2

func _ready() -> void:
	jugador = get_parent().get_node("Character")
	camara = get_viewport().get_camera_2d()
	target_y = global_position.y
	_find_polygons(self)

func apply_hitstop(frames):
	var hitstop_frames = frames
	print("FRAMES ASJDJSJFJ", hitstop_frames)
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	await get_tree().create_timer(frames).timeout
	process_mode = Node.PROCESS_MODE_INHERIT

func _physics_process(delta: float) -> void:
	# 1. FIJAR EN X (Acompañar a la pantalla)
	if camara:
		var centro_camara = camara.global_position
		var mitad_ancho_pantalla = get_viewport_rect().size.x / 2.0
		global_position.x = centro_camara.x + mitad_ancho_pantalla - margen_derecho
	else:
		global_position.x = get_viewport_rect().size.x - margen_derecho

	
	if jugador:
		tiempo_oscilacion += delta * frecuencia_tambaleo
		
		# target_y = posición Y del jugador + oscilación sinusoidal
		var offset_tambaleo = sin(tiempo_oscilacion) * amplitud_tambaleo
		target_y = jugador.global_position.y + offset_tambaleo
		
		

	# 3. MOVIMIENTO EN Y CON INERCIA
	var dir = sign(target_y - global_position.y)
	var velocidad_deseada = dir * velocidad_maxima
	velocity.y = lerp(velocity.y, velocidad_deseada, suavizado * delta)
	
	move_and_slide()

	# 4. ROTACIÓN Y DISPARO
	if jugador != null:
		vector_hacia_jugador = jugador.global_position - global_position
		var distancia = vector_hacia_jugador.length()
		var direccion = vector_hacia_jugador.normalized()
		
		global_rotation = direccion.angle()
		intentar_disparar(direccion)

func intentar_disparar(dir_disparo: Vector2) -> void:
	if not $Timer.is_stopped():
		return
		
	var new_bullet = BALA_ENEMIGA.instantiate()
	new_bullet.owna = self
	get_parent().add_child(new_bullet)
	
	new_bullet.global_position = global_position + dir_disparo * 15
	new_bullet.set_direccion(dir_disparo)
	new_bullet.velocidad = 400.0 
	
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
			wire_node.draw_line(p1, p2, Color.WHITE, thickness * 0.34, true)
		
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
