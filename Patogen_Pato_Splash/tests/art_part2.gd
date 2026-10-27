extends Node
var display: Node2D
var view: SubViewport
var animated: Array[AnimatedSprite2D]=[]
func text_(txt: String,pos: Vector2,size_: int=23) -> void:
	var label:=Label.new();label.text=txt;label.position=pos;label.add_theme_font_override("font",load("res://splash/assets/Pixel-Regular.ttf"));label.add_theme_font_size_override("font_size",size_);label.add_theme_color_override("font_color",Color("fff6de"));display.add_child(label)
func sprite_(asset: String,size_: Vector2i,count: int,pos: Vector2,scale_: float) -> void:
	var sprite:=AnimatedSprite2D.new();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.position=pos;sprite.scale=Vector2.ONE*scale_;var frames:=SpriteFrames.new();frames.set_animation_speed("default",8)
	var texture: Texture2D=load("res://splash/assets/"+asset+".png")
	for f in count:
		var atlas:=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2(f*size_.x,0,size_.x,size_.y);frames.add_frame("default",atlas)
	sprite.sprite_frames=frames;sprite.play();display.add_child(sprite);animated.append(sprite)
func _ready() -> void:
	view=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	display=Node2D.new();display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;view.add_child(display)
	var background:=ColorRect.new();background.size=Vector2(1920,1080);background.color=Color("28343c");display.add_child(background)
	text_("PATO SPLASH / PARTE 2",Vector2(36,20),35);text_("ARTE ORIGINAL / 37 COLORES COMPARTIDOS / 32 PX",Vector2(36,65),19)
	var labels: Array=["TOBOGANES / BARANDAS / SOPORTES","BALDE / EMBLEMA DEL PARQUE","FUENTE INFANTIL / MOSAICOS","REPOSERAS / LONA / ESTRUCTURA","PATO DEL PARQUE / CUATRO DIRECCIONES","CANTEROS / CARTELES / EQUIPAMIENTO"]
	for i in 6:
		var x:=20+(i%3)*632;var y:=112+floori(float(i)/3.0)*474
		var card:=ColorRect.new();card.position=Vector2(x,y);card.size=Vector2(612,450);card.color=Color("3b5d76");display.add_child(card);text_(labels[i],Vector2(x+15,y+16),18)
	sprite_("toboganes",Vector2i(272,240),8,Vector2(320,350),1.5)
	sprite_("balde",Vector2i(112,96),1,Vector2(952,345),3)
	sprite_("fuente_hongo",Vector2i(128,128),8,Vector2(1584,350),2.5)
	sprite_("reposera",Vector2i(40,80),1,Vector2(320,824),4)
	for i in 4:
		var duck:=AnimatedSprite2D.new();duck.sprite_frames=load("res://splash/assets/pato_parque.tres");duck.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;duck.scale=Vector2(3,3);duck.position=Vector2(754+i*130,800);duck.play(["Abajo","Arriba","Derecha","Izquierda"][i]);display.add_child(duck);animated.append(duck)
	text_("32 CUADROS / MISMA PALETA DEL JUGADOR",Vector2(678,932),17)
	sprite_("cantero_palmera",Vector2i(64,64),1,Vector2(1450,808),2.5)
	sprite_("cartel_piso_mojado",Vector2i(32,48),1,Vector2(1642,776),3)
	sprite_("cartel_no_pisar",Vector2i(32,48),1,Vector2(1770,776),3)
	text_("64 x 64 / 2 x 2 TILES",Vector2(1364,932),17)
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/parte2_assets.png")
	print("PART2_ART_CAPTURE_OK")
	get_tree().quit()
