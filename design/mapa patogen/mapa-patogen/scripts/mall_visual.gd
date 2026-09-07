extends Node2D
## PATOGEN MALL V5 — polished shopping-centre presentation.
## Visual geometry is read from the same canonical file as collision.

const Layout = preload("res://scripts/mall_layout.gd")

const MAP_W := Layout.MAP_WIDTH
const MAP_H := Layout.MAP_HEIGHT
const WALL := Layout.WALL_THICKNESS

var shell := Rect2(205, 125, 2790, 2050)
var main_hub := Rect2(780, 820, 1670, 650)
var north_gallery := Rect2(760, 700, 1680, 120)
var south_gallery := Rect2(320, 1590, 2120, 150)
var central_avenue := Rect2(1450, 760, 300, 1000)
var mezzanine: Rect2 = Layout.MEZZANINE
var stair_left: Rect2 = Layout.STAIR_LEFT
var stair_right: Rect2 = Layout.STAIR_RIGHT
var stores: Array = Layout.STORES

var t: float = 0.0
var pulse: float = 0.0
var shoppers: Array = []

func _ready() -> void:
	_seed_shoppers()
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	pulse = (sin(t * 2.0) + 1.0) * 0.5
	for s in shoppers:
		var pos: Vector2 = s["pos"]
		var route: Array = s["route"]
		var target: Vector2 = route[s["target"]]
		if pos.distance_to(target) < 30.0:
			s["target"] = (int(s["target"]) + 1) % route.size()
			target = route[s["target"]]
		var desired := pos.direction_to(target) * float(s["speed"])
		s["vel"] = Vector2(s["vel"]).lerp(desired, min(delta * 3.2, 1.0))
		pos += Vector2(s["vel"]) * delta
		s["pos"] = pos
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-100,-100,MAP_W+200,MAP_H+200), Color("#071018"))
	draw_rect(shell.grow(26), Color(0.01,0.02,0.03,0.72))
	draw_rect(shell, Color("#1b2934"))
	_draw_parking_service()
	_draw_floor_network()
	_draw_outer_shell()
	_draw_avenues()
	_draw_stores()
	_draw_store_details()
	_draw_store_contents()
	_draw_atrium()
	_draw_mezzanine()
	_draw_hot_cold_zones()
	_draw_furniture()
	_draw_entrances()
	_draw_shoppers()
	_draw_wayfinding()

func _draw_floor_network() -> void:
	draw_rect(Rect2(shell.position + Vector2(24,24), shell.size - Vector2(48,48)), Color("#2a3944"))
	draw_rect(north_gallery.grow(18), Color("#314651"))
	draw_rect(main_hub.grow(22), Color("#324650"))
	draw_rect(south_gallery.grow(18), Color("#314651"))
	draw_rect(central_avenue.grow(18), Color("#334851"))

	draw_rect(north_gallery, Color("#90a6b0"))
	draw_rect(main_hub, Color("#8ca2ad"))
	draw_rect(south_gallery, Color("#899fa9"))
	draw_rect(central_avenue, Color("#8299a5"))

	# Floor tile rhythm.
	for x in range(800, 2440, 80):
		draw_line(Vector2(x, 840), Vector2(x, 1460), Color(0.95,0.98,1.0,0.10), 1.5)
	for y in range(860, 1460, 80):
		draw_line(Vector2(820, y), Vector2(2410, y), Color(0.10,0.15,0.18,0.11), 1.5)
	for x in range(1470, 1740, 72):
		draw_line(Vector2(x, 760), Vector2(x, 1760), Color(0.95,0.98,1.0,0.08), 2.0)

	# Primary traffic lane edges.
	draw_line(Vector2(820,820), Vector2(2410,820), Color("#d6e3e7"), 5.0)
	draw_line(Vector2(820,1470), Vector2(2410,1470), Color("#718892"), 5.0)
	draw_line(Vector2(1450,760), Vector2(1450,1760), Color("#d6e3e7"), 5.0)
	draw_line(Vector2(1750,760), Vector2(1750,1760), Color("#718892"), 5.0)

func _draw_outer_shell() -> void:
	var wall_c := Color("#637781")
	var cap_c := Color("#a2b3b9")
	var segments := [
		Rect2(205,113,415,24), Rect2(760,113,660,24), Rect2(1560,113,900,24), Rect2(2580,113,415,24),
		Rect2(205,2163,415,24), Rect2(760,2163,660,24), Rect2(1560,2163,900,24), Rect2(2580,2163,415,24),
		Rect2(193,125,24,915), Rect2(193,1200,24,975), Rect2(2983,125,24,915), Rect2(2983,1200,24,975)
	]
	for r in segments:
		draw_rect(r, wall_c)
		draw_rect(r.grow(-4), cap_c)

func _draw_stores() -> void:
	for s in stores:
		var r: Rect2 = s["rect"]
		var c: Color = s["c"]
		draw_rect(r.grow(14), Color(0.01,0.02,0.03,0.54))
		draw_rect(r, Color(c.r*0.54,c.g*0.54,c.b*0.54))
		draw_rect(r.grow(-10), Color(c.r*0.78,c.g*0.78,c.b*0.78,0.96))
		_draw_store_front(r, str(s["side"]), float(s["door_width"]))

func _draw_store_front(r: Rect2, side: String, door_w: float) -> void:
	var glass := Color(0.72,0.86,0.89,0.64)
	var frame := Color("#9cabb1")
	match side:
		"south":
			draw_rect(Rect2(r.position, Vector2(r.size.x,18)), frame)
			_draw_horizontal_front(r.position.x, r.end.x, r.end.y-18, door_w)
		"north":
			draw_rect(Rect2(r.position.x,r.end.y-18,r.size.x,18), frame)
			_draw_horizontal_front(r.position.x, r.end.x, r.position.y, door_w)
		"east":
			draw_rect(Rect2(r.end.x-18,r.position.y,18,r.size.y), frame)
			_draw_vertical_front(r.position.y, r.end.y, r.end.x-18, door_w, glass)
		"west":
			draw_rect(Rect2(r.position.x,r.position.y,18,r.size.y), frame)
			_draw_vertical_front(r.position.y, r.end.y, r.position.x, door_w, glass)

func _draw_horizontal_front(a: float, b: float, fixed: float, door_w: float) -> void:
	var centre := (a+b)*0.5
	var half := door_w*0.5
	draw_rect(Rect2(a,fixed,maxf(0.0,centre-half-a),16), Color(0.72,0.86,0.89,0.64))
	draw_rect(Rect2(centre+half,fixed,maxf(0.0,b-centre-half),16), Color(0.72,0.86,0.89,0.64))
	for x in range(int(a)+28,int(b)-10,44):
		if abs(float(x)-centre)>half+4:
			draw_line(Vector2(x,fixed+2),Vector2(x,fixed+14),Color(0.95,0.99,1.0,0.40),2)
	_draw_door(Vector2(centre,fixed+8),door_w,true)

func _draw_vertical_front(a: float,b: float,fixed: float,door_w: float,_glass: Color) -> void:
	var centre := (a+b)*0.5
	var half := door_w*0.5
	draw_rect(Rect2(fixed,a,16,maxf(0.0,centre-half-a)), Color(0.72,0.86,0.89,0.64))
	draw_rect(Rect2(fixed,centre+half,16,maxf(0.0,b-centre-half)), Color(0.72,0.86,0.89,0.64))
	for y in range(int(a)+28,int(b)-10,44):
		if abs(float(y)-centre)>half+4:
			draw_line(Vector2(fixed+2,y),Vector2(fixed+14,y),Color(0.95,0.99,1.0,0.40),2)
	_draw_door(Vector2(fixed+8,centre),door_w,false)

func _draw_door(p:Vector2,w:float,horizontal:bool) -> void:
	var frame:=Color("#d8e7e9")
	if horizontal:
		draw_rect(Rect2(p.x-w*0.5,p.y-8,w,16),frame)
		draw_line(Vector2(p.x,p.y-7),Vector2(p.x,p.y+7),Color("#56717c"),2)
	else:
		draw_rect(Rect2(p.x-8,p.y-w*0.5,16,w),frame)
		draw_line(Vector2(p.x-7,p.y),Vector2(p.x+7,p.y),Color("#56717c"),2)

func _draw_store_details() -> void:
	var font:=ThemeDB.fallback_font
	for s in stores:
		var r:Rect2=s["rect"]
		var name:=str(s["name"])
		var side:=str(s["side"])
		match side:
			"south":
				draw_rect(Rect2(r.position.x+28,r.position.y+28,r.size.x-56,46),Color(0.04,0.07,0.09,0.92))
				draw_string(font,Vector2(r.position.x+42,r.position.y+59),name,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f4e5bb"))
			"north":
				draw_rect(Rect2(r.position.x+28,r.end.y-74,r.size.x-56,46),Color(0.04,0.07,0.09,0.92))
				draw_string(font,Vector2(r.position.x+42,r.end.y-44),name,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f4e5bb"))
			"east":
				draw_rect(Rect2(r.end.x-82,r.position.y+26,58,r.size.y-52),Color(0.04,0.07,0.09,0.92))
				draw_string(font,Vector2(r.end.x-76,r.position.y+40),name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f4e5bb"))
			"west":
				draw_rect(Rect2(r.position.x+24,r.position.y+26,64,r.size.y-52),Color(0.04,0.07,0.09,0.92))
				draw_string(font,Vector2(r.position.x+34,r.position.y+40),name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f4e5bb"))

	# Store-specific dressing.
	# Cinema
	var cinema:=Rect2(2520,720,390,430)
	draw_rect(Rect2(2580,770,270,58),Color("#201a2c"))
	for x in range(2600,2840,32):
		draw_circle(Vector2(x,788),5,Color("#edc15e"))
	draw_string(font,Vector2(2640,812),"CINEMA",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#f1d27a"))
	for i in range(3):
		draw_rect(Rect2(2590+i*92,910,68,54),Color("#29233b"))
		draw_rect(Rect2(2598+i*92,918,52,34),Color(0.52,0.63,0.80,0.25))

	# Arcade
	for y in [1280,1430]:
		for x in range(2500,2860,76):
			draw_rect(Rect2(x,y,48,30),Color("#25283e"))
			draw_rect(Rect2(x+7,y+5,34,16),Color(0.40,0.62,0.91,0.30))

	# Market aisles
	for x in range(2470,2850,76):
		draw_rect(Rect2(x,1660,48,300),Color(0.12,0.19,0.16,0.88))
		for y in range(1685,1930,52):
			draw_rect(Rect2(x+6,y,36,18),Color(0.60,0.72,0.60,0.20))
	# Cafe tables
	for p in [Vector2(390,1420),Vector2(550,1420),Vector2(390,1560),Vector2(550,1560)]:
		draw_circle(p,18,Color("#3f2e24"))
		draw_circle(p,12,Color("#a57b5d"))
	# Sports merchandising
	for x in [480,650,820]:
		draw_rect(Rect2(x,1910,82,34),Color("#263a2e"))
		draw_circle(Vector2(x+41,1995),23,Color(0.77,0.83,0.77,0.28))

func _draw_store_contents() -> void:
	# Additional interior dressing: kept stylized and readable from the gameplay camera.
	# These are decorative only and do not add collisions.

	# FASHION — clothing racks + mannequins.
	for x in [470, 650, 790]:
		draw_rect(Rect2(x,340,18,190),Color(0.12,0.15,0.18,0.82))
		draw_rect(Rect2(x-16,350,50,12),Color(0.68,0.73,0.76,0.78))
		for yy in range(372,510,34):
			draw_line(Vector2(x-8,yy),Vector2(x+28,yy),Color(0.82,0.86,0.88,0.34),3)
	for p in [Vector2(560,300),Vector2(780,300)]:
		draw_circle(p,13,Color(0.86,0.72,0.58,0.95))
		draw_rect(Rect2(p.x-13,p.y+10,26,48),Color(0.45,0.58,0.72,0.9))

	# ELECTRONICS — wall displays + product plinths.
	for x in [990, 1100, 1210]:
		draw_rect(Rect2(x,300,88,52),Color(0.06,0.08,0.10,0.95))
		draw_rect(Rect2(x+8,308,72,36),Color(0.40,0.60,0.72,0.38))
		draw_line(Vector2(x+44,352),Vector2(x+44,370),Color(0.62,0.69,0.72,0.55),3)
	for x in [980,1080,1180]:
		draw_rect(Rect2(x,470,64,34),Color(0.18,0.25,0.30,0.92))
		draw_circle(Vector2(x+32,468),12,Color(0.58,0.68,0.72,0.38))

	# HOME & LIVING — sofa, coffee table and floor lamps.
	draw_rect(Rect2(2010,330,150,70),Color(0.35,0.29,0.23,0.95))
	draw_rect(Rect2(2022,316,126,28),Color(0.47,0.40,0.32,0.95))
	draw_rect(Rect2(2060,420,70,46),Color(0.26,0.22,0.18,0.95))
	draw_circle(Vector2(2040,455),22,Color(0.43,0.35,0.28,0.92))
	draw_circle(Vector2(2210,350),10,Color(0.71,0.62,0.46,0.95))
	draw_line(Vector2(2210,360),Vector2(2210,450),Color(0.45,0.42,0.38,0.9),4)

	# BEAUTY — mirrors, counters and product bottles.
	for x in [2370,2480,2590]:
		draw_rect(Rect2(x,330,70,92),Color(0.72,0.80,0.83,0.25))
		draw_rect(Rect2(x+8,338,54,76),Color(0.80,0.88,0.90,0.12))
		draw_rect(Rect2(x-6,445,82,28),Color(0.24,0.20,0.25,0.92))
		for bx in [x+10,x+28,x+46,x+64]:
			draw_rect(Rect2(bx,431,8,14),Color(0.78,0.66,0.48,0.85))

	# FOOD COURT — service counters and small tables.
	draw_rect(Rect2(350,900,180,58),Color(0.28,0.20,0.14,0.96))
	draw_rect(Rect2(540,900,170,58),Color(0.34,0.23,0.15,0.96))
	for x in [390, 500, 610, 710]:
		draw_circle(Vector2(x,1075),20,Color(0.34,0.24,0.18,0.95))
		draw_circle(Vector2(x,1075),14,Color(0.69,0.49,0.32,0.8))

	# TOYS — shelves + toy display island.
	for y in [1840,1940,2040]:
		draw_rect(Rect2(1020,y,330,16),Color(0.28,0.18,0.24,0.92))
		for x in range(1040,1330,52):
			draw_rect(Rect2(x,y-30,30,24),Color(0.62,0.46,0.61,0.62))
	draw_rect(Rect2(1110,1870,150,92),Color(0.28,0.35,0.46,0.95))
	draw_circle(Vector2(1185,1818),28,Color(0.78,0.57,0.30,0.88))

	# ENTERTAINMENT — console kiosks and lounge seats.
	for x in [1490,1600,1710]:
		draw_rect(Rect2(x,1875,72,48),Color(0.18,0.20,0.28,0.95))
		draw_rect(Rect2(x+8,1883,56,24),Color(0.45,0.57,0.70,0.32))
	for p in [Vector2(1510,1990),Vector2(1690,1990)]:
		draw_circle(p,24,Color(0.28,0.24,0.34,0.95))
		draw_circle(p,18,Color(0.48,0.40,0.50,0.75))

	# FASHION OUTLET — denser racks and a central sale table.
	for x in [1860,1990,2120]:
		draw_rect(Rect2(x,1830,18,190),Color(0.16,0.17,0.22,0.9))
		draw_rect(Rect2(x-14,1840,46,10),Color(0.68,0.70,0.76,0.72))
		draw_rect(Rect2(1950,1985,130,46),Color(0.22,0.24,0.30,0.92))
	draw_string(ThemeDB.fallback_font,Vector2(1968,2015),"SALE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e8d16e"))

func _draw_avenues() -> void:
	# Wide service-free entry approaches.
	draw_rect(Rect2(790,1280,90,300),Color("#90a6b0"))
	draw_rect(Rect2(2350,700,100,900),Color("#90a6b0"))
	draw_rect(Rect2(790,1590,100,150),Color("#90a6b0"))
	_draw_stairs(stair_left)
	_draw_stairs(stair_right)
	# East service-free feeder keeps Cinema/Arcade/Market door approaches clear.
	draw_line(Vector2(2445,700), Vector2(2445,2080), Color("#d1dfe3"), 4.0)
	draw_line(Vector2(2518,700), Vector2(2518,2080), Color("#728892"), 4.0)
	# Directional floor bands.
	draw_rect(Rect2(800,802,1600,18),Color("#d5e2e6"))
	draw_rect(Rect2(800,1472,1600,18),Color("#758c96"))

func _draw_stairs(r:Rect2) -> void:
	draw_rect(r.grow(12),Color(0.03,0.05,0.07,0.55))
	draw_rect(r,Color("#40515b"))
	for y in range(int(r.position.y+15),int(r.end.y-8),18):
		draw_line(Vector2(r.position.x+16,y),Vector2(r.end.x-16,y),Color("#90a2a9"),2)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(34,88),"MEZZANINE ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.9,0.94,0.94,0.72))

func _draw_atrium() -> void:
	var c:=Vector2(1600,1140)
	draw_rect(Rect2(1050,900,1100,480),Color(0.75,0.87,0.90,0.10))
	# Inset seating bay / carpet.
	draw_rect(Rect2(1220,930,760,420),Color(0.55,0.70,0.74,0.13))
	draw_circle(c,118,Color("#1b2d35"))
	draw_circle(c,94,Color("#4c8995"))
	draw_arc(c,92+pulse*5,0,TAU,64,Color(0.80,0.96,0.98,0.68),5)
	draw_circle(c,50,Color("#3c7280"))
	for ang in [0.0,PI*0.5,PI,PI*1.5]:
		var p:=c+Vector2(cos(ang),sin(ang))*190
		draw_circle(p,26,Color("#60777e"))
		draw_circle(p,20,Color("#8c9da2"))

func _draw_mezzanine() -> void:
	draw_rect(mezzanine.grow(18),Color(0.02,0.04,0.06,0.72))
	draw_rect(mezzanine,Color("#3f5863"))
	draw_rect(mezzanine.grow(-10),Color("#536f79"))
	# Glass balustrade.
	draw_line(Vector2(mezzanine.position.x,mezzanine.end.y),Vector2(stair_left.position.x,mezzanine.end.y),Color("#d0e1e4"),5)
	draw_line(Vector2(stair_left.end.x,mezzanine.end.y),Vector2(stair_right.position.x,mezzanine.end.y),Color("#d0e1e4"),5)
	draw_line(Vector2(stair_right.end.x,mezzanine.end.y),Vector2(mezzanine.end.x,mezzanine.end.y),Color("#d0e1e4"),5)
	for x in range(int(mezzanine.position.x+30),int(mezzanine.end.x),70):
		draw_line(Vector2(x,mezzanine.end.y-26),Vector2(x,mezzanine.end.y),Color(0.85,0.94,0.95,0.42),2)
	draw_string(ThemeDB.fallback_font,Vector2(1470,560),"MEZZANINE • QUIET GALLERY",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#edf0df"))

func _draw_hot_cold_zones() -> void:
	var hot_alpha: float = 0.055 + pulse * 0.03
	var cold_alpha: float = 0.055 + (1.0 - pulse) * 0.03
	var hot_centres:=[Vector2(530,1040),Vector2(2670,1400),Vector2(1600,1140)]
	for i in range(hot_centres.size()):
		var p:Vector2=hot_centres[i]
		var radius:=145.0 if i<2 else 220.0
		draw_circle(p,radius,Color(1.0,0.30,0.08,hot_alpha))
		draw_arc(p,radius-14+pulse*7,0,TAU,56,Color(1.0,0.54,0.22,0.23),3)
	var cold_centres:=[Vector2(2610,1810),Vector2(2715,935),Vector2(1600,535)]
	for i in range(cold_centres.size()):
		var p:Vector2=cold_centres[i]
		var radius:=150.0 if i<2 else 260.0
		draw_circle(p,radius,Color(0.12,0.68,0.92,cold_alpha))
		draw_arc(p,radius-18+(1.0-pulse)*7,0,TAU,56,Color(0.44,0.88,1.0,0.24),3)
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(400,1100),"HOT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(1.0,0.70,0.40,0.72))
	draw_string(font,Vector2(2600,1740),"COLD",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.68,0.91,1.0,0.72))

func _draw_furniture() -> void:
	for p in Layout.PUBLIC_BENCHES:
		_draw_bench(p)
	for p in Layout.PLANTERS:
		_draw_planter(p)

func _draw_bench(p:Vector2) -> void:
	draw_rect(Rect2(p-Vector2(50,12),Vector2(100,24)),Color("#65757b"))
	draw_line(p+Vector2(-35,12),p+Vector2(-35,22),Color("#39474d"),4)
	draw_line(p+Vector2(35,12),p+Vector2(35,22),Color("#39474d"),4)

func _draw_planter(p:Vector2) -> void:
	draw_rect(Rect2(p-Vector2(20,14),Vector2(40,28)),Color("#6a5546"))
	draw_circle(p+Vector2(0,-18),25,Color("#3d7852"))
	draw_circle(p+Vector2(-8,-27),10,Color("#70b66a"))
	draw_circle(p+Vector2(9,-24),9,Color("#79bd71"))

func _draw_entrances() -> void:
	var entries := [
		{"p":Vector2(690,125),"w":140.0,"h":true,"lab":"NORTH"},
		{"p":Vector2(1490,125),"w":140.0,"h":true,"lab":"NORTH"},
		{"p":Vector2(2520,125),"w":140.0,"h":true,"lab":"NORTH"},
		{"p":Vector2(690,2175),"w":140.0,"h":true,"lab":"SOUTH"},
		{"p":Vector2(1490,2175),"w":140.0,"h":true,"lab":"SOUTH"},
		{"p":Vector2(2520,2175),"w":140.0,"h":true,"lab":"SOUTH"},
		{"p":Vector2(205,1120),"w":90.0,"h":false,"lab":"WEST"},
		{"p":Vector2(2995,1120),"w":90.0,"h":false,"lab":"EAST"}
	]
	for e in entries:
		var p:Vector2 = e["p"]
		var w:float=e["w"]
		if e["h"]:
			draw_rect(Rect2(p-Vector2(w*0.5,16),Vector2(w,32)),Color("#cfdee2"))
			draw_line(Vector2(p.x-w*0.35,p.y),Vector2(p.x+w*0.35,p.y),Color("#6d8893"),4)
		else:
			draw_rect(Rect2(p-Vector2(16,w*0.5),Vector2(32,w)),Color("#cfdee2"))
			draw_line(Vector2(p.x,p.y-w*0.35),Vector2(p.x,p.y+w*0.35),Color("#6d8893"),4)

func _draw_wayfinding() -> void:
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(1385,190),"PATOGEN MALL",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("#f3d36b"))
	draw_string(font,Vector2(1370,217),"SHOPPING • FOOD • CINEMA • ENTERTAINMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.81,0.88,0.91,0.64))
	# Directional signs around the key decision points.
	for sign in [
		{"p":Vector2(1350,790),"a":"← WEST","b":"EAST →"},
		{"p":Vector2(1500,1510),"a":"↑ NORTH","b":"SOUTH ↓"},
		{"p":Vector2(2360,1320),"a":"ARCADE ↑","b":"MARKET ↓"},
		{"p":Vector2(800,1310),"a":"FOOD COURT ↑","b":"CAFÉ ↓"}
	]:
		draw_rect(Rect2(sign["p"]-Vector2(8,22),Vector2(180,46)),Color(0.04,0.07,0.09,0.78))
		draw_string(font,sign["p"]+Vector2(4,-2),sign["a"],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#dfeceb"))
		draw_string(font,sign["p"]+Vector2(92,-2),sign["b"],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#dfeceb"))

func _draw_parking_service() -> void:
	draw_rect(Rect2(110,360,95,360),Color("#202c34"))
	for y in range(390,690,50):
		draw_line(Vector2(125,y),Vector2(190,y),Color(0.86,0.9,0.92,0.18),3)
	draw_rect(Rect2(2995,1450,105,520),Color("#202c34"))
	for y in range(1480,1940,50):
		draw_line(Vector2(3010,y),Vector2(3075,y),Color(0.86,0.9,0.92,0.18),3)
	draw_rect(Rect2(2550,1980,340,160),Color("#202b32"))
	for x in range(2580,2880,70):
		draw_rect(Rect2(x,2010,46,78),Color("#65737a"))
	draw_string(ThemeDB.fallback_font,Vector2(2620,2115),"LOADING / STAFF",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(0.85,0.9,0.92,0.55))

func _draw_shoppers() -> void:
	for s in shoppers:
		var p:Vector2=s["pos"]
		draw_circle(p+Vector2(4,6),7,Color(0.02,0.04,0.05,0.30))
		draw_circle(p,6,Color("#e6c768"))
		draw_circle(p+Vector2(0,-3),2,Color("#f5f6ec"))

func _seed_shoppers() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=468046
	var routes: Array = [
		[Vector2(900,860),Vector2(1300,860),Vector2(1600,860),Vector2(2000,860),Vector2(2410,860)],
		[Vector2(860,1140),Vector2(1100,1140),Vector2(1600,1140),Vector2(2080,1140),Vector2(2410,1140)],
		[Vector2(1600,820),Vector2(1600,1000),Vector2(1600,1320),Vector2(1600,1540),Vector2(1600,1680)],
		[Vector2(900,1660),Vector2(1200,1660),Vector2(1600,1660),Vector2(2000,1660),Vector2(2320,1660)],
		[Vector2(1110,700),Vector2(1320,560),Vector2(1600,560),Vector2(1880,560),Vector2(2080,700)]
	]
	for i in range(28):
		var route:Array=routes[i%routes.size()]
		var idx:=rng.randi_range(0,route.size()-1)
		var p:Vector2=route[idx]+Vector2(rng.randf_range(-14,14),rng.randf_range(-14,14))
		shoppers.append({"pos":p,"vel":Vector2.ZERO,"route":route,"target":idx,"speed":rng.randf_range(34.0,52.0)})
