extends CharacterBody2D

const BALA_ENEMIGA = preload("res://lazer_beam.tscn")

@export var velocidad: float = 280.0
@export var distancia_ataque: float = 1000.0
var max_lf = 4
var jugador: CharacterBody2D = null
var dmg = 2
var bllt_vel = 250
var aceleración = 500.0
var vector_hacia_jugador
var running = false
var started = false
var puede_apuntar = true
var posicion_local_jugador
var vector_fijo
var cargando = false

func _ready() -> void:
	_find_polygons(self)
	jugador = get_parent().get_node("Character")
	$DestroyThemWithLazers.clear_points()
	$DestroyThemWithLazers.add_point(Vector2.ZERO) # Punto 0 (Origen)
	$DestroyThemWithLazers.add_point(Vector2.ZERO) # Punto 1 (Punta móvil)
	$Timer.one_shot = true 

func _physics_process(delta: float) -> void:
	if not jugador:
		$DestroyThemWithLazers.visible = false
		return
	
	vector_hacia_jugador = jugador.global_position - global_position
	var distancia = vector_hacia_jugador.length()
	var direccion = vector_hacia_jugador.normalized()
	posicion_local_jugador = to_local(jugador.global_position)
	
	# ✅ CORRECCIÓN 1: Solo mover la línea si puede_apuntar es true, y usar el índice 1
	if puede_apuntar:
		$DestroyThemWithLazers.set_point_position(1, posicion_local_jugador)
	
	# ✅ CORRECCIÓN 2: Rotación fija durante la carga
	if !puede_apuntar:
		global_rotation = vector_fijo.angle() # Apunta a la dirección fija
	else:
		global_rotation = direccion.angle()
	
	if distancia > distancia_ataque:
		velocity = direccion * velocidad
		$Trail.emitting = true
		$DestroyThemWithLazers.visible = false
	elif distancia < 610:
		velocity = velocity.move_toward( direccion * -200, aceleración * delta)
		$Trail.emitting = false
	else:
		$DestroyThemWithLazers.visible = true
		velocity = velocity.move_toward(Vector2.ZERO, velocidad * 5 * delta)
		$Trail.emitting = false
		intentar_disparar()
		
	move_and_slide()

func intentar_disparar() -> void:
	# ✅ CORRECCIÓN 3: Usar 'cargando' en lugar de dos timers confusos
	if cargando:
		return
	
	if not $Timer.is_stopped():
		return
	
	cargando = true
	charge_laser()

func charge_laser():
	# Ya no necesitamos verificar timers aquí, 'cargando' lo controla todo
	await get_tree().create_timer(4.5).timeout
	
	puede_apuntar = false
	vector_fijo = vector_hacia_jugador
	
	await get_tree().create_timer(0.5).timeout
	disparar_laser_perron()
	
	# ✅ CORRECCIÓN 4: Restaurar el estado para el siguiente ciclo
	cargando = false
	puede_apuntar = true # La línea vuelve a seguir al jugador
	$Timer.start() # Inicia el cooldown de 5s

func disparar_laser_perron():
	$DestroyThemWithLazers.visible = false
	var new_bullet = BALA_ENEMIGA.instantiate()
	new_bullet.owna = self
	get_parent().add_child(new_bullet)
	
	new_bullet.global_position = global_position
	new_bullet.disparar(vector_fijo, 3000) 
	
	await get_tree().create_timer(0.8).timeout
	$DestroyThemWithLazers.visible = true

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
