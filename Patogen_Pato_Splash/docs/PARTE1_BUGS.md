# Pato Splash · Parte 1 de 5 · Bugs

## Inspección y backup previos

Se revisaron `project.godot`, `splash/scenes/PatoSplash.tscn`, las escenas de objetos, sus fuentes Aseprite, los `.import`, los generadores, el HUD y la cámara de la demo. Tile actual: **32×32**. Viewport: **1920×1080**, cámara en **(960,540)**, zoom **(1,1)**. Las importaciones ya eran sin pérdida, sin mipmaps y sin límite de tamaño. Los nodos del mapa ya heredaban Nearest; el filtro no era la causa del tamaño de los patos.

Backup de **257 archivos**, incluyendo import settings y un manifiesto SHA256, realizado antes de editar:

`C:/Users/feliv/.codex/.chatgpt-projects/g-p-6ac7d270eca08191830907d9c9abeba3/.work/backups/PatoSplash_parte1_20261026_092838/`

Se utilizaron Aseprite MCP para generar/verificar el raster y Godot MCP para aplicar cambios nativos, abrir el proyecto, ejecutar la prueba y capturar el resultado. No se modificaron archivos de `sources/`.

## Correcciones y decisiones

1. **Agua:** la espuma anterior se dibujaba en una banda compartida de ocho puntos entre las puntas. Se eliminó del sprite de los toboganes. Dos animaciones independientes de caída, ocho cuadros a 10 FPS, nacen en **(317,380)** y **(387,383)** y caen hacia la pileta. Los marcadores `SalidaIzquierda` y `SalidaDerecha` pertenecen al objeto toboganes, de modo que el agua lo acompaña si se mueve. Las fases empiezan separadas cuatro cuadros. Se eligieron sprites para conservar control de los píxeles y la paleta.
2. **Escaleras:** revisadas las cuatro. Se anclaron al borde superior de sus respectivas piletas. La imagen comienza ocho píxeles antes del borde, con los pasamanos por fuera y los peldaños entrando al agua. Posiciones superiores izquierdas: **(472,360), (732,440), (1136,440), (1664,360)**. Siguen siendo decorativas y sin colisión.
3. **Patos:** los dos controlables usaban cuadros de 32×32 a escala 1; la ventana de 1440×810 además los mostraba reducidos al 75 %. Se eligió **escala visual 2×**, cuadros de **64×64** en pantalla, con el apoyo de los pies conservado mediante offset (0,-16). Su cuerpo físico mantiene radio **15,6**. El inflable usa escala visual **1,5×**: cuadro de **240×216**, que cabe dentro de la pileta central. No se redibujaron los patos ni se cambió su paleta.

La ventana inicial pasa a **1920×1080**; la cámara y el HUD conservan su encuadre. Nearest se hace explícito también en la raíz de la demo y en las animaciones de caída. Ningún color nuevo se agregó y el tile permanece en 32×32.

## Archivos de implementación

- `project.godot`: tamaño inicial de ventana.
- `demo/explorer.gd`: escala visual y marcador de los dos patos controlables, conservando su física.
- `demo/demo.gd`: Nearest explícito.
- `splash/scenes/PatoSplash.tscn`: posiciones de las cuatro escaleras e instancias actualizadas.
- `splash/scenes/objetos/toboganes.tscn`: dos marcadores de salida y sus animaciones independientes.
- `splash/scenes/objetos/pato_gigante.tscn`: escala visual del inflable.
- `splash/assets/toboganes.aseprite`, `.png`, `.json`: retirada de la espuma compartida.
- `splash/assets/salida_tobogan.aseprite`, `.png`, `.json`: caída y espuma localizadas; nueva importación PNG.
- `tools/refined_shapes.lua`, `tools/build_art.lua`, `tools/build_slide_water.lua`: generación Aseprite corregida y regeneración selectiva.
- `tools/build_scene.gd`, `tools/prepare.py`, `tools/layout.json`: persistencia de los cambios al regenerar el proyecto.

Soporte añadido: `tests/apply_part1.gd`/`ApplyPart1.tscn`, `tests/part1_bugs.gd`/`Part1Bugs.tscn`, `tests/check_part1_palette.lua` y reportes JSON. La aplicación ya fue ejecutada y es repetible; conserva el baseline original en `tests/part1_baseline_geometry.json`.

## Verificación final

- `tests/part1_validation.json`: **passed=true**, sin fallos. La ejecución de Godot MCP devolvió **errors=[]**, sin warnings.
- **177 nodos** de sprites/pisos comprobados con Nearest.
- Dos animaciones desde las salidas reales, ocho cuadros cada una, 10 FPS y primer píxel en su origen.
- Cuatro escaleras cruzando el borde en las posiciones indicadas.
- Resolución nativa **1920×1080**, cámara fija, zoom 1 y tiles **32×32**.
- Patos controlables de **64×64** y cuadro del inflable de **240×216**. Movimiento comprobado tras el cambio de escala.
- Colisiones activas del entorno idénticas al baseline; radio de ambos jugadores conservado.
- `tests/part1_palette.json`: **0 colores nuevos**, comparado con el backup en Aseprite.
- Captura revisada visualmente: `captures/parte1_1920x1080.png`. Secuencia de ocho detalles: `captures/parte1_salida_00.png` a `07.png`.

Para repetir la comprobación, ejecutar `res://tests/Part1Bugs.tscn` desde Godot. El proyecto sigue siendo la demo explorable de Pato Splash; esta parte no incorpora las mecánicas de infección de la partida principal.
