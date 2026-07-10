extends Node2D

@onready var sfx_player = $SfxPlayer 

func play_sfx(sonido_nombre: String):
	sfx_player.stream = load("res://" + sonido_nombre + ".wav")
	sfx_player.play()
