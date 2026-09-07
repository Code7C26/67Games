# PATOGEN MALL V5 — integración con el proyecto del equipo

## Qué escena deben usar
Para integrar el mapa dentro del proyecto que ya contiene las mecánicas, sprites y personajes del equipo, usar:

`res://PatogenMall_MapOnly.tscn`

Es una escena Node2D autocontenida: no crea jugador, bots ni HUD. El script `mall_main.gd` crea en runtime las colisiones del mall y las zonas de condición.

## Fuente única del layout
`mall_main.gd` contiene las posiciones de locales, puertas, atrio, mobiliario, escalones y zonas hot/cold.
`mall_visual.gd` usa exactamente esas mismas posiciones para dibujar el shopping.

No agreguen otra capa de colisiones para estos elementos en el proyecto destino: eso puede volver a generar hitboxes fantasma.

## Puertas
Todas las fachadas usan huecos reales de colisión. Los accesos de Cinema, Arcade, Market y Café están alineados con sus puertas visuales. Sports tiene una entrada norte de 144 px y un corredor amplio de aproximación.

## Segundo piso / mezzanine
Hay una mezzanine central al norte del atrio, con dos escaleras anchas en `NavigationMarkers/MezzanineLeft` y `NavigationMarkers/MezzanineRight`. Las barandas colisionan; el tramo de escaleras queda libre para caminar.

## Zonas de Patogen
Las zonas se crean bajo `GameplayZones` y pertenecen al grupo:

`patogen_condition_zone`

Cada `Area2D` tiene metadata:
- `zone_id`
- `zone_type` = `hot` o `cold`
- `intensity`

No bloquean al jugador (capa 0) y detectan cuerpos de la capa 1.

Zonas principales:
- HOT: Food Court, Arcade y Atrium.
- COLD: Market, Cinema y Mezzanine.

## Integración del jugador
La escena standalone incluye un jugador placeholder únicamente para comprobar colisiones. El proyecto del equipo debe conservar su propio `CharacterBody2D`, sprite, animaciones y mecánicas.

Asegúrense de que el personaje use la capa de colisión 1 o ajusten `PLAYER_LAYER` en `mall_main.gd`.

## IA
El V5 deja `NavigationMarkers` estables para que el sistema de IA del equipo se conecte más adelante. No se incluye IA de bots en esta versión: primero queda cerrado layout + personaje + colisiones + zonas.
