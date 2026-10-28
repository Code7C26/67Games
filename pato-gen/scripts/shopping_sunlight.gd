extends RefCounted
## A floor-cell stencil, derived from the authored tile layers rather than a box.
static func build(host: Node2D) -> ImageTexture:
	var grid: Vector2i = host.get_meta("grid",Vector2i(67,32))
	var tile_size: int = host.get_meta("tile_size",32)
	var image := Image.create(grid.x,grid.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	var floors := host.get_node("Pisos")
	for allowed in [true,false]:
		for layer in floors.get_children():
			if not layer is TileMapLayer: continue
			var common: bool = str(layer.name) in ["Pasillos","Accesos","Atrio"]
			if str(layer.name) == "DesgasteDiscreto" or common != allowed: continue
			for cell in layer.get_used_cells():
				var point: Vector2 = host.to_local(layer.to_global(layer.map_to_local(cell)))
				var pixel := Vector2i((point/float(tile_size)).floor())
				if pixel.x>=0 and pixel.y>=0 and pixel.x<grid.x and pixel.y<grid.y:
					image.set_pixelv(pixel,Color.WHITE if allowed else Color.BLACK)
	return ImageTexture.create_from_image(image)
