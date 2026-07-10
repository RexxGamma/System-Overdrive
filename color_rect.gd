extends TextureRect

@onready var viewport = $"../SubViewportContainer/SubViewport"  # ajusta el path

func _ready():
	var vt = ViewportTexture.new()
	vt.viewport_path = viewport.get_path()
	vt.resource_local_to_scene = true
	texture = vt
