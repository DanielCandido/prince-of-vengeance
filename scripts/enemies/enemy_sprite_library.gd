class_name EnemySpriteLibrary
extends RefCounted

static func build(path: String, cell_size: Vector2, movement_name: StringName) -> SpriteFrames:
	var texture: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var names: Array[StringName] = [&"idle", movement_name, &"telegraph", &"attack"]
	var speeds := [2.0, 5.5, 3.0, 7.0]
	for animation_index in range(4):
		var animation := names[animation_index]
		frames.add_animation(animation)
		frames.set_animation_loop(animation, animation_index < 2)
		frames.set_animation_speed(animation, speeds[animation_index])
		for pair_index in range(2):
			var grid_index := animation_index * 2 + pair_index
			if path.contains("swamp_raider") and animation == &"idle":
				grid_index = 0
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2((grid_index % 4) * cell_size.x, (grid_index / 4) * cell_size.y, cell_size.x, cell_size.y)
			frames.add_frame(animation, atlas)
	return frames
