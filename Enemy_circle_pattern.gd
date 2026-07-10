extends CharacterBody2D

# Cargamos la escena de la bala roja
const BALA_ENEMIGA = preload("res://enemy_bullet.tscn")
var max_lf = 5
var dmg = 1
var bllt_vel = 250

var angulo_actual: float = 0.0
@export var velocidad_giro: float = 20.0 # Grados que rota el cañón en cada disparo

func _ready() -> void:
	$Timer.start()
	$Timer.timeout.connect(_on_timer_timeout)
	$hurtbox.owner_player = self
	_find_polygons(self)
	

func _physics_process(delta: float) -> void:
	if $Timer.time_left <= 0:
		$Timer.start()

func _on_timer_timeout() -> void:
	var nueva_bala = BALA_ENEMIGA.instantiate()
	nueva_bala.owna = self
	get_parent().add_child(nueva_bala)
	
	# 2. Posicionarla en el centro de la torreta
	nueva_bala.global_position = global_position
	
	# 3. Convertir el ángulo actual a un vector de dirección
	var dir = Vector2.RIGHT.rotated(deg_to_rad(angulo_actual))
	nueva_bala.set_direccion(dir)
	
	# 4. Hacer avanzar el ángulo para el siguiente frame
	angulo_actual += velocidad_giro
	
	# Resetear el ángulo al dar la vuelta completa para evitar números gigantes en memoria
	if angulo_actual >= 360.0:
		angulo_actual = 0.0

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
