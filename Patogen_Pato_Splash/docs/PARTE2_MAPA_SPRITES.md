# Parte 2 de 5 · Mapa y sprites

Entrega del 26 de octubre de 2026. Arte creado/editado y exportado con **Aseprite MCP**; escenas, recursos, capturas y ejecución comprobados con **Godot MCP**, Godot 4.7.1.

## Inspección y respaldo

Se revisaron escena, atlas, fuentes, imports, escala del jugador, cámara, HUD, obstáculos y navegación existentes. El tile sigue siendo de **32×32 px**, la cámara fija muestra **1920×1080** y se conserva Nearest. Las salidas de agua independientes, las cuatro escaleras de borde y las escalas de lectura corregidas en la parte 1 se conservaron.

Antes de modificar se copiaron 284 archivos al respaldo local `C:/Users/feliv/.codex/.chatgpt-projects/g-p-6ac7d270eca08191830907d9c9abeba3/.work/backups/PatoSplash_parte2_20261026_094549`. Su `BACKUP_MANIFEST.json` registra los SHA256. No se tocaron archivos de `sources/` ni las referencias originales de `demo/references`.

## Resultado y decisiones

- **383 tiles conectados** en `07_Caminos`, un `TileMapLayer` independiente con atlas de 16 variantes y terreno nativo de conexiones laterales. Veredas principales de unos 96 px, acceso de 160 px y ramales de 64 px. Se evita pintar junto a obstáculos donde no queda margen de paso.
- **Diez canteros de 2×2 tiles** con tierra, borde de ladrillos de cemento y palmera centrada. Cada cantero tiene una sola colisión de 64×64; se desactivó la colisión redundante del tronco. Las posiciones se ajustaron a la cuadrícula dentro del parque.
- **Ocho carteles** de piso mojado/no pisar junto a piletas y toboganes, sin colisión. Toallero, dos dispensadores de entradas, duchas y bancos completan sectores vacíos. El total es de **69 objetos**, además de las piletas, pisos y señalética general.
- Toboganes nuevos con plataforma, escalera, soportes, juntas y rieles; se mantienen las salidas de agua independientes. Balde con aro y remaches, fuente infantil con mosaicos y cortina animada, reposera con estructura tubular, lona y toalla. Se revisó el resto de assets al unificar materiales y colores.
- `pato_parque`: **32 cuadros de 32×32**, cuatro direcciones a 8 FPS, cabeza y pose basadas en el jugador, detalles de alas/chaleco y sus once colores originales. Escala entera 2× en la demo y radio físico de 15,6 px sin cambios.
- **43 fuentes `.aseprite`** guardadas junto a sus PNG y los JSON de animación. Paleta compartida de **37 colores que ya existían** en el proyecto; no se agregaron colores. Las skins de NPC conservan siluetas y alfa, con sus colores unificados: no se afirma que sus píxeles RGB sean idénticos a los anteriores.
- La navegación de demostración prefiere los paseos con peso 0,72 frente a 1 para el suelo libre; puede salir de ellos para evitar congestión. El evento conserva su ciclo, límite de diez visitantes y geometría estable.

La referencia [Water Park Pixel Art Tileset](https://comshadow.itch.io/water-park-pixel-art-tileset) se consultó como orientación para separación de materiales, estructura de toboganes y nivel de detalle. Los dibujos se construyeron en Aseprite; no se importaron ni copiaron sprites del pack.

## Archivos principales

| Área | Archivos creados o modificados |
| --- | --- |
| Mapa y caminos | `splash/scenes/PatoSplash.tscn`, `splash/assets/caminos_32.{aseprite,png,tres}` |
| Canteros y señales | `splash/assets/cantero_palmera.*`, `cartel_piso_mojado.*`, `cartel_no_pisar.*`; prefabs `palmera_cantero.tscn`, `cartel_piso_mojado.tscn`, `cartel_no_pisar.tscn` |
| Equipamiento | `toallero.*`, `entrada_tickets.*` y sus prefabs |
| Arte rehecho | `toboganes.*`, `balde.*`, `fuente_hongo.*`, `reposera.*`, `pato_parque.*` |
| Paleta y resto de arte | `splash/assets/patogen_paleta.gpl`, las 43 fuentes y sus exportaciones unificadas |
| Demo | `demo/explorer.gd`, `demo/routes.gd` |
| Construcción reproducible | `tools/art_part2.lua`, `tools/part2_builder.gd`, `tools/build_scene.gd`, `tools/package.py`, `tests/apply_part2.gd`, `tests/ApplyPart2.tscn` |
| Pruebas | `tests/part2.gd`, `tests/Part2.tscn`, `tests/audit_part2_art.lua`, `tests/art_part2.gd`, `tests/ArtPart2.tscn` y reportes JSON |

## Validación actual

`tests/part2_validation.json`: **passed = true**, sin fallos. Se comprobaron cámara, tamaño de tile, terreno nativo, 383 celdas conectadas, diez canteros, ocho carteles, salidas/escaleras de la parte 1 y 202 nodos con Nearest.

- **54 NPC, 120 segundos simulados**, con paso físico de 1/60 s: **570 viajes completados**, recorrido mínimo de 4953,06 px, cero replanteos por atasco y cero muestras de penetración. Mayor detención temporal: 1,37 s.
- **289 pares de destinos conectados**, también con margen de 36 px. Distancia máxima de un destino al paseo: 22,63 px. Ambos inicios mantienen 736 px al evento en la cuadrícula de prueba.
- Dos impactos a **38,01 y 88,01 s**; máximo de diez visitantes atraídos.
- `tests/part2_palette_check.json`: **43 fuentes**, 37 colores, **2.094.576 píxeles comprobados**, cero píxeles fuera de paleta y cero colores nuevos frente al respaldo. Cero cambios de alfa de NPC; 9384 píxeles de color de cabeza unificados.
- El proyecto abre y la demo ejecuta sin errores ni warnings nuevos observados. Una última pasada visual de color de palmeras no cambió geometría; se repitió la auditoría de paleta y la captura después de ella.

Capturas actuales: `captures/parte2_1920x1080.png`, `captures/parte2_assets.png` y `captures/02_chapuzon.png`. Los informes de partes anteriores son registros históricos.

La entrega sigue siendo el mapa y una demo de circulación; la infección y la IA real de Patogen se integran en el proyecto principal. Estas pruebas de paso y simetría geométrica no sustituyen las partidas de balance con esas mecánicas.
