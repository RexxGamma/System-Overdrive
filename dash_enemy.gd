extends CharacterBody2D

@export var velocidad: float = 280.0
@export var distancia_ataque: float = 330.0
var max_lf = 10
var jugador: CharacterBody2D = null
var dash_dir
var dashing = false
var dash_vel = 600
var icee_d = false
var freno_post_dash = 450
var direccion
enum sts {SEARCH, ATTACK, STOP}
var currnt_sts = sts.SEARCH
var hitted = false
var dmg = 1

func _ready() -> void:
	jugador = get_parent().get_node("Character")
	$Hitbox.owna = self
	_find_polygons(self)

func _physics_process(delta: float) -> void:
	
	look_at(get_global_mouse_position())
	
	if not jugador:
		return
	# 1. Calcular dirección y distancia hacia el jugador
	var vector_hacia_jugador = jugador.global_position - global_position
	var distancia = vector_hacia_jugador.length()
	
	direccion = vector_hacia_jugador.normalized()
	
	global_rotation = direccion.angle()
	
	if velocity.length() > 0:
		$Trail.emitting = true
	else:
		$Trail.emitting = false
	
	if dashing == true:
		velocity = dash_dir * dash_vel
	else:
		currnt_sts = sts.SEARCH
	if icee_d:
		freno_post_dash = 30
	else:
		freno_post_dash = 450
	match currnt_sts:
		sts.SEARCH:
			if distancia > distancia_ataque:
				dash()
			else:
				# Freno suave para que no se detenga en seco de forma irreal
				velocity = velocity.move_toward(Vector2.ZERO, velocidad * 5 * delta)
				$RayCast2D.target_position = global_position.direction_to(jugador.global_position) * 100.0
				
				
				currnt_sts = sts.ATTACK
				dash()
		sts.ATTACK:
			pass
		
		sts.STOP:
			velocity = Vector2.ZERO
	move_and_slide()

func dash():
	if not $Timer.is_stopped():
		return
	
	if currnt_sts == sts.ATTACK:
		dash_dir = $RayCast2D.target_position.normalized()
		dashing = true
		await get_tree().create_timer(0.3).timeout
		icee_d = true
		dashing = false
		await get_tree().create_timer(0.6).timeout
		icee_d = false
		currnt_sts = sts.SEARCH
		$Timer.start()
	
	if currnt_sts == sts.SEARCH:
		dash_dir = direccion
		dashing = true
		await get_tree().create_timer(0.3).timeout
		icee_d = true
		dashing = false
		await get_tree().create_timer(0.6).timeout
		icee_d = false
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
			wire_node.draw_line(p1, p2, Color.WHITE, thickness * 0.4, true)
		
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
