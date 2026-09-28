
extends RefCounted

## PATOGEN MALL V5 — geometría principal del mapa.
## Se utiliza para mantener las posiciones iguales en gráficos y colisiones.
## No duplicar las posiciones de las tiendas en otros scripts.

# Dimensiones generales del mapa
const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 2300.0

# Grosor de las paredes
const WALL_THICKNESS := 24.0

# Capa de colisión utilizada por el jugador
const PLAYER_LAYER := 1

# Posición inicial del jugador
const PLAYER_SPAWN := Vector2(1600,1180)


# Lista de tiendas con sus posiciones, tamaños, puertas y colores
const STORES := [
	{"name":"FASHION", "rect":Rect2(380,250,520,360), "side":"south", "door_width":128.0, "c":Color("#536b83")},
	{"name":"ELECTRONICS", "rect":Rect2(930,220,310,400), "side":"south", "door_width":112.0, "c":Color("#376d80")},
	{"name":"HOME & LIVING", "rect":Rect2(1960,220,300,400), "side":"south", "door_width":112.0, "c":Color("#766756")},
	{"name":"BEAUTY", "rect":Rect2(2300,250,420,360), "side":"south", "door_width":128.0, "c":Color("#805f78")},
	{"name":"CINEMA", "rect":Rect2(2520,720,390,430), "side":"west", "door_width":136.0, "c":Color("#493d60")},
	{"name":"FOOD COURT", "rect":Rect2(280,820,500,470), "side":"east", "door_width":136.0, "c":Color("#7f522e")},
	{"name":"CAFÉ", "rect":Rect2(280,1340,500,300), "side":"east", "door_width":120.0, "c":Color("#6b4d3a")},
	{"name":"ARCADE", "rect":Rect2(2450,1220,460,360), "side":"west", "door_width":136.0, "c":Color("#4d4e78")},
	{"name":"MARKET", "rect":Rect2(2390,1620,520,430), "side":"west", "door_width":144.0, "c":Color("#456a50")},
	{"name":"SPORTS", "rect":Rect2(360,1740,560,340), "side":"north", "door_width":144.0, "c":Color("#3f674f")},
	{"name":"TOYS", "rect":Rect2(990,1760,400,320), "side":"north", "door_width":120.0, "c":Color("#704f6b")},
	{"name":"ENTERTAINMENT", "rect":Rect2(1430,1760,360,320), "side":"north", "door_width":120.0, "c":Color("#4f566e")},
	{"name":"FASHION OUTLET", "rect":Rect2(1810,1760,420,320), "side":"north", "door_width":120.0, "c":Color("#5b6079")}
]


# Zona central elevada del centro comercial
const MEZZANINE := Rect2(1240,430,720,220)

# Escaleras que conectan diferentes zonas del mapa
const STAIR_LEFT := Rect2(1160,650,160,150)
const STAIR_RIGHT := Rect2(1880,650,160,150)


# Zonas donde la temperatura afecta al juego
# "hot" representa calor y "cold" representa frío.
const HOT_COLD_ZONES := [
	{"id":"HOT_FOOD_COURT", "type":"hot", "rect":Rect2(300,850,460,410), "intensity":1.0},
	{"id":"HOT_ARCADE", "type":"hot", "rect":Rect2(2460,1250,430,300), "intensity":0.8},
	{"id":"HOT_ATRIUM", "type":"hot", "rect":Rect2(1260,930,680,360), "intensity":0.55},
	{"id":"COLD_MARKET", "type":"cold", "rect":Rect2(2420,1640,450,370), "intensity":1.0},
	{"id":"COLD_CINEMA", "type":"cold", "rect":Rect2(2535,745,355,385), "intensity":0.65},
	{"id":"COLD_MEZZANINE", "type":"cold", "rect":Rect2(1260,460,680,170), "intensity":0.45}
]


# Posiciones de los bancos ubicados en las zonas públicas
const PUBLIC_BENCHES := [
	Vector2(900,900), Vector2(1120,900), Vector2(2080,900), Vector2(2300,900),
	Vector2(900,1530), Vector2(1120,1530), Vector2(2080,1530), Vector2(2300,1530),
	Vector2(1030,1670), Vector2(2160,1670)
]


# Bancos ubicados alrededor del atrio central
const ATRIUM_BENCHES := [
	Vector2(1370,1050), Vector2(1370,1230), Vector2(1830,1050), Vector2(1830,1230),
	Vector2(1110,1000), Vector2(1110,1280), Vector2(2090,1000), Vector2(2090,1280)
]


# Posiciones de los canteros o espacios con plantas
const PLANTERS := [
	Vector2(980,1020), Vector2(2220,1020), Vector2(980,1260), Vector2(2220,1260),
	Vector2(1290,880), Vector2(1910,880), Vector2(1290,1460), Vector2(1910,1460)
]


# Posiciones de los kioscos del centro comercial
const KIOSKS := [
	Vector2(980,1100), Vector2(2220,1100), 
	Vector2(1210,1450), Vector2(1990,1450)
]
