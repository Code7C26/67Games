extends Control
var aperture:=Rect2(12,68,1896,790)
const FONT=preload("res://Fuentes/press-start-2p.ttf")
const DARK=Color("0b1721")
const STEEL=Color("243c4b")
const EDGE=Color("587681")
const TEAL=Color("6bd1ce")

func _draw() -> void:
	# Four opaque pieces with a real hole: the map never gets a full-screen overlay.
	draw_rect(Rect2(0,0,size.x,aperture.position.y),DARK)
	draw_rect(Rect2(0,aperture.end.y,size.x,size.y-aperture.end.y),DARK)
	draw_rect(Rect2(0,aperture.position.y,aperture.position.x,aperture.size.y),STEEL)
	draw_rect(Rect2(aperture.end.x,aperture.position.y,size.x-aperture.end.x,aperture.size.y),STEEL)
	draw_rect(aperture.grow(3),EDGE,false,3)
	for y in [64.0,aperture.end.y+4,size.y-3]:
		draw_line(Vector2(0,y),Vector2(size.x,y),EDGE,2)
	for x in range(14,int(size.x),32):
		draw_rect(Rect2(x,62,16,2),TEAL.darkened(0.55))
	for x in [aperture.position.x-10,aperture.end.x+8]:
		draw_line(Vector2(x,80),Vector2(x,aperture.end.y-12),Color("101f2b"),4)
		for y in range(86,int(aperture.end.y)-10,64):
			draw_rect(Rect2(x-2,y,4,4),Color("88a5ad"))
	if aperture.position.x>130:
		_side_console(14,aperture.position.x-30,false)
		_side_console(aperture.end.x+16,size.x-aperture.end.x-30,true)
	draw_string(FONT,Vector2(548,32),"AV-07",HORIZONTAL_ALIGNMENT_LEFT,-1,14,TEAL)
	draw_string(FONT,Vector2(size.x-734,30),"MUESTRA",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("aab9be"))

func _side_console(x: float,width: float,right: bool) -> void:
	var panel:=Rect2(x,106,width,132)
	draw_rect(panel,Color("102a33"))
	draw_rect(panel,EDGE,false,2)
	draw_string(FONT,Vector2(x+12,130),"AV-07" if not right else "CULTIVO",HORIZONTAL_ALIGNMENT_LEFT,-1,12,TEAL)
	for i in 5:
		var y:=151.0+i*14
		draw_rect(Rect2(x+12,y,4,4),Color("9bd6a0"))
		draw_line(Vector2(x+24,y+2),Vector2(x+width-12,y+2),Color("31505b"),2)
		draw_line(Vector2(x+24,y+2),Vector2(x+24+(width-40)*(0.4+0.09*i),y+2),Color("678f94"),2)
	# Inset service panels echo the laboratory cabinetry in the references.
	for i in 3:
		var y:=296.0+i*142
		draw_rect(Rect2(x,y,width,114),Color("334f5b"))
		draw_rect(Rect2(x+4,y+4,width-8,106),Color("1b303d"))
		draw_line(Vector2(x+12,y+14),Vector2(x+width-12,y+14),EDGE,2)
		for row in 4:
			draw_line(Vector2(x+14,y+36+row*14),Vector2(x+width-14,y+36+row*14),Color("2b4753"),3)
		draw_rect(Rect2(x+width-20,y+92,5,5),Color("c2b37c"))
