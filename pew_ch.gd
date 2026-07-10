extends CharacterBody2D
class_name plaier

const def_speed = 450.0
var SPEED = def_speed
var bullet_scene = preload("res://own_bullet.tscn")
var can_shoot = true
var max_lf = 4
enum st {MOVING, DASHING, KILLED}
var current_st = st.MOVING
var dash_dir
var dashing = false
var dash_vel = 600
var icee_d = false
var freno_post_dash = def_speed
var hitstop_frames
@export var limite_izquierdo: float = -800.0
@export var limite_derecho: float = 2800.0
@export var limite_superior: float = -800.0
@export var limite_inferior: float = 1800.0
@onready var sound = $ShootSFX


func apply_hitstop():
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.05).timeout
	Engine.time_scale = 1.0

func apply_hitstop_forhit():
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.1).timeout
	Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	dash_dir = $RayCast2D.target_position.normalized()
	look_at(get_global_mouse_position())
	if dashing == true:
		velocity = dash_dir * dash_vel
	else:
		current_st = st.MOVING
	
	if icee_d:
		freno_post_dash = 30
	else:
		freno_post_dash = def_speed
	
	# En tu _physics_process o donde calcules el movimiento:
	if velocity.length() > 0:
		$Trail.emitting = true
	else:
		$Trail.emitting = false
	
	var mouse_distance = global_position.distance_to(get_global_mouse_position())
	match current_st:
		st.MOVING:
			if (Input.is_action_pressed("down") or Input.is_action_pressed("up")) and (Input.is_action_pressed("right") or Input.is_action_pressed("left")):
				SPEED = def_speed/1.5
			else:
				SPEED = def_speed
			var dir_x := Input.get_axis("left", "right")
			if dir_x:
				velocity.x = dir_x * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, freno_post_dash)
			var dir_y := Input.get_axis("up", "down")
			if dir_y:
				velocity.y = dir_y * SPEED
			else:
				velocity.y = move_toward(velocity.y, 0, freno_post_dash)
			if Input.is_action_just_pressed("dash") and mouse_distance > 18:
				$RayCast2D.target_position = global_position.direction_to(get_global_mouse_position()) * 100.0
				current_st = st.DASHING
		
		st.DASHING:
			pass
		
		st.KILLED:
			pass
	
	global_position.x = clamp(global_position.x, limite_izquierdo, limite_derecho)
	global_position.y = clamp(global_position.y, limite_superior, limite_inferior)
	
	
	sound.pitch_scale = randf_range(0.7, 1.0)
	sound.volume_db = randf_range(-2, 1)
	
	if Input.is_action_pressed("shoot"):
		intentar_disparar()
	dash()
	move_and_slide()

func intentar_disparar() -> void:
	if not $Timer.is_stopped():
		return
	sound.stop()
	sound.play()
	var new_bullet = bullet_scene.instantiate()
	get_parent().add_child(new_bullet)
	new_bullet.global_position = global_position
	var mouse_dir = Vector2.RIGHT.rotated(rotation)
	new_bullet.set_direccion(mouse_dir)
	new_bullet.owna = self
	
	$ShootParticles.restart()
	$ShootParticles.emitting = true
	$Timer.start() 

func _on_timer_timeout() -> void:
	can_shoot = true

func dash():
	if current_st == st.DASHING:
		
		dashing = true
		await get_tree().create_timer(0.3).timeout
		icee_d = true
		dashing = false
		await get_tree().create_timer(0.6).timeout
		icee_d = false

func _ready() -> void:
	_find_polygons(self)

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
