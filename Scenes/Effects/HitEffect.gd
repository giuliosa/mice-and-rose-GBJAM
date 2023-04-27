extends AnimatedSprite

func _ready():
	connect("animation_finished", self, "_on_animated_finished")
	frame = 0
	play("hit")
	
func _on_animated_finished():
	queue_free()
