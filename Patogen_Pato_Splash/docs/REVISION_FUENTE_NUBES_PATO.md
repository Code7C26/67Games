# Revisión de fuente, nubes e inflable

Press Start 2P se extrajo sin modificar del ZIP suministrado. Se aplica a los diez textos del mapa y a la interfaz (28 textos y botones comprobados), en múltiplos de 8 px, sin antialiasing ni mipmaps. `splash/assets/press_start_2p.tres` conserva estos ajustes; la TTF original queda al lado.

Las sombras tenían una opacidad del 10% y una forma demasiado difusa. Ahora son dos grupos reconocibles, al 24%, con velocidad de 18 px/s, bordes suaves y movimiento horizontal cíclico. La oscilación vertical está limitada para que no desaparezcan durante partidas largas. La comparación renderizada a 1920×1080 detectó 246.208 píxeles visiblemente oscurecidos y 326.474 píxeles de desplazamiento a los 24 s; ningún píxel del HUD afectado.

Se redibujó `pato_gigante.aseprite` en Aseprite: cabeza compacta, pico de dos planos, ala, costuras y válvula. Conserva 160×144 px, ocho cuadros, escala de escena 1,5× y los 37 colores existentes. Hay tres capas editables. La comparación con el backup registra 9.250 píxeles diferentes en el primer cuadro. Las otras 47 fuentes Aseprite permanecen idénticas.

Prueba actual de ambiente: 54 NPC, render nativo 1920×1080, física 60 Hz, 50 s medidos en RTX 3060 Laptop: 297 FPS medios, p99 de 7,305 ms y máximo de 15,619 ms. Sin penetraciones, objetos flotantes fuera del agua ni cambios de colisiones. La demo arrancó mediante Godot MCP sin errores. Informes: `tests/visual_revision_*.json` y `tests/part3_validation.json`.

Archivos principales: `splash/scenes/PatoSplash.tscn`, `demo/demo.gd`, `splash/scripts/park_ambience.gd`, `splash/shaders/sombras_nubes.gdshader`, `splash/assets/pato_gigante.{aseprite,png,json}`, `splash/assets/{PressStart2P.ttf,press_start_2p.tres}`. Generadores: `tools/art_pato_central.lua`, `tools/visual_revision.gd` y `tools/build_scene.gd`.

Para regenerar todo el arte, ejecutar `art_pato_central.lua` después de las pasadas artísticas anteriores, antes de reconstruir la escena. `tests/ApplyVisualRevision.tscn` permite reaplicar solamente la fuente; `tests/VisualRevision.tscn` comprueba la fuente y las sombras.

Backup anterior a esta revisión: `.work/backups/PatoSplash_fuente_nubes_pato_20261026_105247` en el workspace, con manifiesto SHA256 y ZIP previo. `sources/` no se modificó. La paleta, tile de 32 px, cámara y lógica de NPC/evento no cambiaron en esta revisión.
