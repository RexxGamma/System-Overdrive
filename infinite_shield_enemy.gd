extends Area2D
class_name shiesld
var max_health = 9999999999999999999
var current_health:int = -10005
var owner_player = null
var is_invulnerable = false

func receive_damage(value:int):
	receive_heal(value)
	print(owner ," RECEIVED DAMAGE IN SHIELD") 
	
	if owner_player and owner_player.has_method("check_phase_change"):
		
		owner_player.check_phase_change(current_health)
		

func heal(value:int):
	receive_heal(-value) 

func receive_heal(value):
	current_health += value
	current_health = clamp(current_health, 0, max_health)
