extends Area2D
class_name hurtbox
var max_health
var current_health: int = 0
var owner_player = null
var is_invulnerable = false
var is_dead = false

const GAME_OVER_SCENE = preload("res://gameover_ui.tscn")

func receive_damage(value: int):
	max_health = owner.max_lf
	death()
	if $invulnerable_timer.time_left > 0:
		return
	receive_heal(value)
	$invulnerable_timer.start()
	print(owner, " RECEIVED DAMAGE, LIFE IS: ", current_health)
	if !(owner is plaier):
		$hitted2.stop()
		$hitted2.play()
	else:
		$hitted.stop()
		$hitted.play()
	
	var shake_tween = create_tween()
	
	if Engine.time_scale > 0:
		shake_tween.set_speed_scale(1.0 / Engine.time_scale)

	var pos_original = owner.position
	
	shake_tween.tween_property(owner, "position:x", pos_original.x - 8, 0.04)
	shake_tween.tween_property(owner, "position:x", pos_original.x + 6, 0.04)
	shake_tween.tween_property(owner, "position:x", pos_original.x, 0.04)
	print(owner.get_class())
	var poligonos = owner.find_children("*", "Polygon2D", true, false)
	for poly in poligonos:
		if not is_instance_valid(poly): continue
		var borde = Line2D.new()
		owner.add_child(borde)
		borde.points = poly.polygon
		borde.global_transform = poly.global_transform
		borde.width = 4.0
		borde.default_color = Color(1.0, 1.0, 1.0, 1.0)
		borde.closed = true
		borde.z_index = 10
		var timer = get_tree().create_timer(0.08, false, true, false)
		timer.timeout.connect(func(): if is_instance_valid(borde): borde.queue_free())

func heal(value: int):
	receive_heal(-value)

func receive_heal(value):
	current_health += value
	current_health = clamp(current_health, 0, max_health)

func death():
	if is_dead:
		return
	
	if current_health >= max_health:
		is_dead = true
		
		_spawn_disintegration_particles()
		if owner is plaier:
			var game_over = GAME_OVER_SCENE.instantiate()
			get_tree().root.add_child(game_over)
			
			AudioManager.play_sfx("death")
		else:
			AudioManager.play_sfx("death(enemies)")
		owner.queue_free()

func _spawn_disintegration_particles():
	var poligonos = owner.find_children("*", "Polygon2D", true, false)
	var scene_root = get_tree().current_scene
	for poly in poligonos:
		if not is_instance_valid(poly): continue
		_fragmentar_poligono(poly, scene_root)

func _crear_fragmento(pos: Vector2, color: Color, parent: Node, dir_base: Vector2):
	var fragmento = Node2D.new()
	parent.add_child(fragmento)
	fragmento.global_position = pos

	var pixel = Polygon2D.new()
	fragmento.add_child(pixel)

	var num_verts = randi_range(3, 5)
	var verts: Array[Vector2] = []
	for i in num_verts:
		var a = (TAU / num_verts) * i + randf_range(-0.4, 0.4)
		var r = randf_range(1.5, 4.5)
		verts.append(Vector2(cos(a), sin(a)) * r)
	pixel.polygon = PackedVector2Array(verts)
	pixel.color = color

	var angulo_base = dir_base.angle()
	var angulo = angulo_base + randf_range(-PI * 0.6, PI * 0.6)
	var velocidad = randf_range(80.0, 250.0)
	var vel = Vector2(cos(angulo), sin(angulo)) * velocidad

	var duracion = randf_range(0.5, 1.1)

	var tween = fragmento.create_tween()
	tween.set_parallel(true)

	var destino = pos + vel * duracion
	tween.tween_property(fragmento, "global_position", destino, duracion)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var giros = randf_range(-PI * 3, PI * 3)
	tween.tween_property(fragmento, "rotation", fragmento.rotation + giros, duracion)\
		.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(pixel, "color:a", 0.0, duracion * 0.4)\
		.set_delay(duracion * 0.26)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(fragmento, "scale", Vector2(0.3, 0.3), duracion * 0.5)\
		.set_delay(duracion * 0.6)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(fragmento.queue_free)

func _fragmentar_poligono(poly: Polygon2D, parent: Node):
	var cantidad = 10

	var verts_global: Array[Vector2] = []
	for v in poly.polygon:
		verts_global.append(poly.global_transform * v)

	var min_x = verts_global[0].x
	var max_x = verts_global[0].x
	var min_y = verts_global[0].y
	var max_y = verts_global[0].y
	for v in verts_global:
		min_x = min(min_x, v.x)
		max_x = max(max_x, v.x)
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)

	var centro_enemigo = owner.global_position
	var color_base: Color = poly.color

	for i in cantidad:
		var pos = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		var color_variado = color_base.lightened(randf_range(-0.1, 0.2))
		color_variado.a = 1.0

		var dir_base = (pos - centro_enemigo).normalized()
		if dir_base == Vector2.ZERO:
			dir_base = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

		_crear_fragmento(pos, color_variado, parent, dir_base)
