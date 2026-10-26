extends Sprite2D

# A sprite cycling through a few frames, like the waves of a lagoon.

var frames: Array[Texture2D] = []
var fps := 2.0
var time := 0.0


func setup(textures: Array[Texture2D], frames_per_second: float) -> void:
	frames = textures
	fps = frames_per_second
	centered = false
	texture = frames[0]


func _process(delta: float) -> void:
	time += delta
	texture = frames[int(time * fps) % frames.size()]
