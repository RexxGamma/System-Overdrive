extends Node2D

var puntos = []
var cantidad_puntos = 40
var velocidad = 0.5

var puntos_por_celda = 12
var celda_tamano = 1024

var cache_celdas = {}

var redraw_timer = 0.0
var redraw_interval = 0.2

func _ready():
	randomize()

	for i in range(cantidad_puntos):
		puntos.append(
			Vector2(
				randf_range(0, 1920),
				randf_range(0, 1080)
			)
		)

func _process(delta):
	for i in range(puntos.size()):
		puntos[i] += Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * velocidad

		puntos[i].x = clamp(puntos[i].x, 0, 1920)
		puntos[i].y = clamp(puntos[i].y, 0, 1080)

	redraw_timer += delta

	if redraw_timer >= redraw_interval:
		redraw_timer = 0.0
		queue_redraw()

func _draw():
	var cam_pos = get_global_transform_with_canvas().origin * -1

	var celda_x = int(cam_pos.x / celda_tamano)
	var celda_y = int(cam_pos.y / celda_tamano)

	for x in range(celda_x - 2, celda_x + 3):
		for y in range(celda_y - 2, celda_y + 3):
			dibujar_celda(x, y)

func obtener_celda(cx, cy):
	var key = Vector2i(cx, cy)

	if cache_celdas.has(key):
		return cache_celdas[key]

	seed(cx * 1000 + cy)

	var puntos_celda = []
	var lineas = []

	for i in range(puntos_por_celda):
		puntos_celda.append(
			Vector2(
				cx * celda_tamano + randf_range(0, celda_tamano),
				cy * celda_tamano + randf_range(0, celda_tamano)
			)
		)

	var distancia_max_sq = 450 * 450

	for i in range(puntos_celda.size()):
		for j in range(i + 1, puntos_celda.size()):
			if puntos_celda[i].distance_squared_to(puntos_celda[j]) < distancia_max_sq:
				lineas.append([puntos_celda[i], puntos_celda[j]])

	var datos = {
		"puntos": puntos_celda,
		"lineas": lineas
	}

	cache_celdas[key] = datos
	return datos

func dibujar_celda(cx, cy):
	var datos = obtener_celda(cx, cy)

	for linea in datos.lineas:
		draw_line(
			linea[0],
			linea[1],
			Color(0.276, 0.092, 0.46, 0.682),
			0.5
		)

	for pos in datos.puntos:
		draw_circle(pos, 1.5, Color(0.6, 0.4, 0.9, 0.8))

		draw_circle(
			pos,
			1.5,
			Color(0.4, 0.0, 1.0, 1.0)
		)
