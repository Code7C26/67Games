# Gran chapuzón · giro de 360° y coronas de agua

Revisión vigente del evento de parte 4. El pato gira una vuelta completa durante el disparo y reparte el agua por el parque. Se mantiene erguido: Aseprite aporta 16 vistas de la misma figura, con anclas de pico y cabeza para los emisores. Después recupera su animación ambiental.

## Distribución y cantidad de agua

- Ocho sectores alrededor del centro, normalizados al rectángulo del parque. Cada uno recibe tres impactos, separados en tres bandas de distancia: **24 impactos por evento**.
- Se seleccionan puntos de piso libre, separados entre sí y alejados de obstáculos y bordes. La selección no consulta equipo, infección ni posición de los NPCs. La geometría y las rutas permanecen fijas.
- La atracción ya no convoca visitantes al centro (`max_attracted_visitors = 0`). Siguen sus recorridos normales y reaccionan si un impacto los alcanza.
- El chorro baja de 360 a **96 partículas simultáneas configuradas**, el géiser de 80 a **24** y las burbujas de 36 a **16**. Con la nueva vida de 0,8 s, el chorro emite aproximadamente un tercio de las gotas anteriores durante el disparo. El géiser dura 0,30 s.
- `CPUParticles2D` usa coordenadas globales. La velocidad inicial se calcula desde el pico hasta cada destino, con gravedad de 600 px/s² y vida de 0,8 s. La variación es pequeña para conservar la correspondencia visual entre gotas e impactos. Cada impacto se programa con ese mismo tiempo de vuelo.

El reparto es igual en cantidad de impactos por sector. El alcance sobre los personajes depende de dónde estén y de su estrategia; esta comprobación no sustituye pruebas de balance con las habilidades del juego completo.

## Arte y estados

`pato_giro`: 16 cuadros de 160×144 px. `splash_corona`: cuatro cuadros de 64×48 px, a 0,12 s por cuadro. La corona tiene centro hueco, paredes celestes y una cresta blanca escalonada; se inspira en la imagen suministrada, sin copiar sus píxeles. Se dibuja desde su base para conservar la perspectiva del piso.

Ambos recursos conservan `.aseprite`, PNG y JSON. Se emplean los mismos 37 colores, tiles de 32 px y filtro Nearest. Las 55 fuentes Aseprite anteriores permanecen intactas: ahora hay 57.

La secuencia conserva 1,5 s de aviso, 1,5 s de disparo y 1 s de cierre, silbato, HUD rojo y sacudida configurable. Los charcos se secan en 10 s, con opacidad 0,24. El radio de empapado es 52 px; dura 6 s y mantiene ambas reacciones de correr/cubrirse. La infección sigue en **Neutro** por defecto; los hooks Limpiar/Propagar emiten una sola exposición por actor y evento.

## Parámetros e integración

En `09_GranChapuzon`: `particle_amount`, `water_gravity`, `droplet_lifetime`, `impacts_per_sector`, `wet_radius`, `puddle_dry_seconds`, `puddle_opacity`, `shake_intensity`, `shake_duration` y `stream_shake_intensity`. La vuelta es siempre de 360° y su velocidad depende de `splash_seconds` en la raíz del mapa. Los antiguos parámetros de abanico y velocidad fija fueron sustituidos por el giro y el cálculo de trayectoria.

`ParqueMojado` es un `Area2D` que cubre el parque, sin colisión sólida. Consulta capa 2 y grupo `splash_visitors`. Se conserva la API de señales de `splash_event.gd`; ver `INTEGRACION.md`.

## Verificación

`tests/Giro360.tscn` ejecutó siete vueltas completas con 54 NPCs y render a 1920×1080. Resultado: **168 impactos, 21 en cada sector, ninguno rechazado**, las 16 vistas del pato observadas y rotación completa. Se verificaron pausa, secado, recuperación del pato, HUD, burbujas, géiser, reacciones y hooks de infección sin duplicados.

En una NVIDIA GeForce RTX 3060 Laptop GPU, física a 60 Hz y render sin límite: **326,45 FPS medios durante el evento**, p99 6,982 ms, máximo 8,21 ms; ningún cuadro del evento superó 16,667 ms. Son mediciones de este equipo, no una garantía para otros. Máximo observado: ocho coronas y 48 charcos simultáneos, con pools fijos de 64.

Sin errores ni warnings en el log de esta ejecución. Se compararon 106 nodos de geometría sólida y los prefabs sin diferencias. Configuración del proyecto, fuente Press Start 2P, paleta y patos controlables conservados.

Informes: `tests/giro360_validation.json`, `giro360_art.json`, `giro360_preservation.json` y `giro360_debug.json`. Vista animada: `captures/giro360_chapuzon.gif`. Capturas nativas: `giro360_aviso.png`, `giro360_disparo.png`, `giro360_impacto.png` y `giro360_charcos.png`.

## Archivos y regeneración

- Nuevos: assets `pato_giro` y `splash_corona`, `pato_giro_anchors.json`, `tools/art_giro360.lua`, `tools/check_giro360_preservation.py`, pruebas y capturas Giro360, este documento.
- Modificados: `splash/scripts/duck_cannon.gd`, `splash/scenes/PatoSplash.tscn`, `demo/demo.gd`, `tools/part4_builder.gd`, `tools/package.py`, `.gitignore` y documentación.
- Decisiones: giro erguido con 16 vistas; tres impactos por sector; agua más escasa; ningún llamado de NPCs al centro; infección neutra; colisiones intactas.

Para regenerar esta revisión, ejecutar `tools/art_giro360.lua` en Aseprite con `--script-param base=<ruta-absoluta-del-proyecto-con-barra-final>`. Esperar la importación de los PNG en Godot y ejecutar `tests/ApplyPart4.tscn`. En una regeneración completa, el orden de arte termina con `art_pato_central.lua`, `art_part4.lua` y **`art_giro360.lua`**; luego se ejecuta `tools/build_scene.gd`. Para validar usar `tests/Giro360.tscn`; para capturar, `tests/CaptureGiro360.tscn`. Las pruebas Part4 son históricas y esperan el abanico anterior.

Backup previo: `.work/backups/PatoSplash_giro360_20261026_145250`, fuera del proyecto generado, con manifiesto SHA256 y el ZIP anterior. `sources/` no se modificó.
