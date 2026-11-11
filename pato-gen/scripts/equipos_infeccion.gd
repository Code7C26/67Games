extends RefCounted
## La afiliación es independiente de la clase de mutaciones de cada jugador.
const AZUL := 1
# Alias de las escenas antiguas; el nombre visible del equipo es AZUL.
const CIAN := AZUL
const MAGENTA := 2
const ALFA := 3
const COLOR_AZUL := Color("528dff")
const COLOR_MAGENTA := Color("ef69cd")
const COLOR_ALFA := Color("7dff45")

static func color_equipo(equipo: int) -> Color:
	return COLOR_AZUL if equipo == AZUL else (COLOR_MAGENTA if equipo == MAGENTA else COLOR_ALFA)

static func valido(equipo: int) -> bool:
	return equipo in [CIAN, MAGENTA, ALFA]
