extends Node2D
class_name WaveManager

# Señales para la UI o el jugador
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal game_over()

@export var enemy_1_scene: PackedScene
@export var enemy_2_scene: PackedScene
@export var enemy_3_scene: PackedScene
@export var enemy_4_scene: PackedScene
@export var enemy_5_scene: PackedScene
@export var enemy_6_scene: PackedScene
@export var enemy_7_scene: PackedScene  
@export var enemy_8_scene: PackedScene 

# Variables de estado
var current_wave: int = 0
var enemies_alive: int = 0
var is_wave_active: bool = false
var is_player_alive: bool = true

# Configuración de oleadas (Puedes añadir todas las que quieras)
var waves_data: Array = [
	# --- FASE 1: Introducción progresiva (Oleadas 1-8) ---
	# Oleada 1: Calentamiento
	[{"type": "enemy_1", "count": 2}],
	# Oleada 2: Aparece el segundo enemigo
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}],
	# Oleada 3
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}],
	# Oleada 4
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_4", "count": 1}],
	# Oleada 5: Aparece el quinto enemigo
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_4", "count": 1}, {"type": "enemy_5", "count": 1}],
	# Oleada 6
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_4", "count": 1}, {"type": "enemy_5", "count": 1}, {"type": "enemy_6", "count": 1}],
	# Oleada 7
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_4", "count": 1}, {"type": "enemy_5", "count": 1}, {"type": "enemy_6", "count": 1}, {"type": "enemy_7", "count": 1}],
	# Oleada 8: Ya están los 8 enemigos en juego
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_4", "count": 1}, {"type": "enemy_5", "count": 1}, {"type": "enemy_6", "count": 1}, {"type": "enemy_7", "count": 1}, {"type": "enemy_8", "count": 1}],

	# --- FASE 2: Transición y eliminación de enemigos fáciles (Oleadas 9-12) ---
	# Oleada 9: Se elimina el Enemy 4
	[{"type": "enemy_1", "count": 2}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 1}, {"type": "enemy_7", "count": 1}, {"type": "enemy_8", "count": 2}],
	# Oleada 10: Suben los difíciles
	[{"type": "enemy_1", "count": 1}, {"type": "enemy_2", "count": 1}, {"type": "enemy_3", "count": 1}, {"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 2}, {"type": "enemy_7", "count": 1}, {"type": "enemy_8", "count": 3}],
	# Oleada 11: Se elimina el Enemy 3
	[{"type": "enemy_1", "count": 1}, {"type": "enemy_2", "count": 1}, {"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 2}, {"type": "enemy_7", "count": 2}, {"type": "enemy_8", "count": 4}],
	# Oleada 12: Solo queda 1 Enemy 1. Ya están todos los difíciles.
	[{"type": "enemy_1", "count": 1}, {"type": "enemy_2", "count": 1}, {"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 2}, {"type": "enemy_7", "count": 2}, {"type": "enemy_8", "count": 5}],

	# --- FASE 3: Eliminación total de fáciles y ritmo controlado (Oleadas 13-16) ---
	# Oleada 13: Se elimina el Enemy 1
	[{"type": "enemy_2", "count": 1}, {"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 2}, {"type": "enemy_7", "count": 2}, {"type": "enemy_8", "count": 7}],
	# Oleada 14: Se elimina el Enemy 2
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 2}, {"type": "enemy_7", "count": 3}, {"type": "enemy_8", "count": 8}],
	# Oleada 15: Se elimina el Enemy 3 (ya no había, pero por si acaso) y sube dificultad
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 3}, {"type": "enemy_7", "count": 3}, {"type": "enemy_8", "count": 8}],
	# Oleada 16: Se elimina el Enemy 4 (ya no había). Solo quedan los 4 enemigos difíciles.
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 3}, {"type": "enemy_7", "count": 4}, {"type": "enemy_8", "count": 8}],

	# --- FASE 4: Endgame (Solo enemigos difíciles, ritmo lento) (Oleadas 17-30) ---
	# Oleada 17
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 3}, {"type": "enemy_7", "count": 4}, {"type": "enemy_8", "count": 9}],
	# Oleada 18
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 3}, {"type": "enemy_7", "count": 4}, {"type": "enemy_8", "count": 10}],
	# Oleada 19
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 3}, {"type": "enemy_7", "count": 5}, {"type": "enemy_8", "count": 10}],
	# Oleada 20
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 4}, {"type": "enemy_7", "count": 5}, {"type": "enemy_8", "count": 10}],
	# Oleada 21
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 4}, {"type": "enemy_7", "count": 5}, {"type": "enemy_8", "count": 11}],
	# Oleada 22
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 4}, {"type": "enemy_7", "count": 6}, {"type": "enemy_8", "count": 11}],
	# Oleada 23
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 5}, {"type": "enemy_7", "count": 6}, {"type": "enemy_8", "count": 11}],
	# Oleada 24
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 5}, {"type": "enemy_7", "count": 6}, {"type": "enemy_8", "count": 12}],
	# Oleada 25
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 5}, {"type": "enemy_7", "count": 7}, {"type": "enemy_8", "count": 12}],
	# Oleada 26
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 6}, {"type": "enemy_7", "count": 7}, {"type": "enemy_8", "count": 12}],
	# Oleada 27
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 6}, {"type": "enemy_7", "count": 7}, {"type": "enemy_8", "count": 13}],
	# Oleada 28
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 6}, {"type": "enemy_7", "count": 8}, {"type": "enemy_8", "count": 13}],
	# Oleada 29
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 7}, {"type": "enemy_7", "count": 8}, {"type": "enemy_8", "count": 13}],
	# Oleada 30: Final
	[{"type": "enemy_5", "count": 2}, {"type": "enemy_6", "count": 7}, {"type": "enemy_7", "count": 8}, {"type": "enemy_8", "count": 14}]
]

func _ready() -> void:
	# Inicia la primera oleada después de un pequeño retraso
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func start_next_wave() -> void:
	if not is_player_alive:
		return

	# Si se acaban las oleadas predefinidas, genera una infinita con más dificultad
	if current_wave >= waves_data.size():
		generate_infinite_wave()
		return

	is_wave_active = true
	current_wave += 1
	wave_started.emit(current_wave)
	
	print("¡OLEADA ", current_wave, " INICIADA!")

	var wave_config = waves_data[current_wave - 1]
	
	# Spawnea los enemigos con un pequeño retraso entre cada uno para que no sea tan brusco
	for enemy_data in wave_config:
		var scene_to_spawn = get_scene_by_name(enemy_data["type"])
		for i in enemy_data["count"]:
			await get_tree().create_timer(0.8).timeout # Retraso entre spawns
			spawn_enemy(scene_to_spawn)

func spawn_enemy(scene: PackedScene) -> void:
	if not is_player_alive or scene == null:
		return

	var enemy = scene.instantiate()
	enemy.position = get_safe_spawn_position()
	get_parent().add_child(enemy) # Se añade a la escena principal
	enemies_alive += 1

	# Detecta cuando el enemigo muere (se elimina del árbol de nodos)
	enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	
	if enemies_alive <= 0 and is_wave_active:
		is_wave_active = false
		wave_cleared.emit(current_wave)
		print("¡OLEADA ", current_wave, " COMPLETADA!")
		
		# 🛡️ BLINDAJE 1: Si el nodo ya fue eliminado o la escena cambió, salir de la función.
		if not is_inside_tree():
			return
			
		await get_tree().create_timer(3.0).timeout
		
		# ️ BLINDAJE 2: Verificar de nuevo por si el jugador murió durante los 3 segundos de espera
		if not is_inside_tree() or not is_player_alive:
			return
			
		start_next_wave()

func get_safe_spawn_position() -> Vector2:
	# Spawnea fuera de la pantalla, lejos del jugador
	var viewport_size = get_viewport_rect().size
	var player_pos = get_parent().get_node("Character").global_position # Ajusta el nombre de tu jugador
	var margin = 100.0
	var spawn_pos = Vector2.ZERO
	
	# Intenta encontrar una posición fuera de la pantalla lejos del jugador
	for i in 10:
		var side = randi() % 4
		match side:
			0: spawn_pos = Vector2(randf_range(0, viewport_size.x), -margin)
			1: spawn_pos = Vector2(viewport_size.x + margin, randf_range(0, viewport_size.y))
			2: spawn_pos = Vector2(randf_range(0, viewport_size.x), viewport_size.y + margin)
			3: spawn_pos = Vector2(-margin, randf_range(0, viewport_size.y))
			
		# Si está lejos del jugador, usa esta posición
		if spawn_pos.distance_to(player_pos) > 400:
			return spawn_pos
			
	return spawn_pos # Si no, devuelve la última generada

func get_scene_by_name(name: String) -> PackedScene:
	match name:
		"enemy_1": return enemy_1_scene
		"enemy_2": return enemy_2_scene
		"enemy_3": return enemy_3_scene
		"enemy_4": return enemy_4_scene
		"enemy_5": return enemy_5_scene
		"enemy_6": return enemy_6_scene
		"enemy_7": return enemy_7_scene
		"enemy_8": return enemy_8_scene
	return null

func generate_infinite_wave() -> void:
	# Genera oleadas infinitas aumentando la cantidad de enemigos
	var base_count = 3 + current_wave
	waves_data.append([
		{"type": "enemy_1", "count": base_count},
		{"type": "enemy_2", "count": base_count},
		{"type": "enemy_3", "count": base_count}
	])
	start_next_wave()

# Llama a esta función cuando el jugador muera
func player_died() -> void:
	is_player_alive = false
	is_wave_active = false
	game_over.emit()
