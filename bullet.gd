extends Area2D
class_name bullet

var damage = 1
var owna
var hittad = false
var cam
var velocidad: float = 800.0
var direccion: Vector2 = Vector2.ZERO
var started = false
var HIT_PARTICLES = preload("res://Hit_Particles.tscn")
var hit_particles_nodmg = preload("res://hitparticles(nodmg).tscn")

@export var radio_defensa: float = 40.0

func _ready() -> void:
	started = true
	area_entered.connect(hit)
	_find_polygons(self)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if owna != null:
		cam = owna.get_node("cam")
	if started:
		cam.apply_shake(20)
		started = false
	global_position += direccion * velocidad * delta

func set_direccion(dir: Vector2) -> void:
	direccion = dir.normalized()
	global_rotation = direccion.angle() 

func hit(area):
	if area == null:
		return
	
	
	if area is enmy_bllt or area is bullet:
		var distancia = global_position.distance_to(area.global_position)
		
		# Solo destruir si están dentro del radio de defensa
		if distancia <= radio_defensa:
			var chispas2 = hit_particles_nodmg.instantiate()
			chispas2.global_position = global_position
			get_tree().current_scene.add_child(chispas2)
			chispas2.emitting = true
			
			queue_free()
			return
	
	if !(area is hurtbox or shiesld):
		return
	
	
	if area is shiesld:
		print("kmsdsjkdksdskkdasakkmsdmkMKASMKMKDMKSD")
		queue_free()
		return
	
	if area is hurtbox:
		if area.owner == owna:
			return
		var chispas = HIT_PARTICLES.instantiate()
		chispas.global_position = global_position
		get_tree().current_scene.add_child(chispas)
		chispas.emitting = true
		
		for i in 10:
			print("why don't????")
			area.receive_damage(damage)
			if owna != null:
				owna.apply_hitstop_forhit()
			queue_free()

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
	
	#Calcular centroide
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

	#Crear un nodo de dibujo dinámico
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
	
	
	wire_node.draw.connect(func():
		var color: Color = poly.color
		var offset_total = poly.offset # Usamos el offset interno del polígono
		
		# 1. CONTORNO EXTERIOR (Fino)
		for i in range(pts.size()):
			var p1 = pts[i] + offset_total
			var p2 = pts[(i + 1) % pts.size()] + offset_total
			wire_node.draw_line(p1, p2, color, 1.25, true)
		
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
