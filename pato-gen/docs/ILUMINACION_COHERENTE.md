# Revisión de fuentes de luz · 28/10/2026

Rama `codex/lighting-coherence`, sobre `7b84c5d`. Cambios únicamente en el proyecto principal.

## Shopping

Se eliminan los reflejos de props y los barridos diagonales sobre arcade, vitrinas y demás muebles. Se conservan los focos de luz artificial propios de neones/equipos.

La luz cenital y el sheen de piso usan una máscara generada a partir de las celdas de `Pisos/Pasillos`, `Accesos` y `Atrio`. Las celdas de locales y cine se restan expresamente. El borde se atenúa en 10 px dentro de la zona permitida, evitando el recorte brusco anterior. Deriva de la luz: 0,5 px/s. No se modifica ninguna capa de tiles, paso ni colisión.

Archivos: `scripts/shopping_sunlight.gd`, `shaders/sunlight_mask.gdshaderinc`, `shaders/floor_light_beams.gdshader`, `lab/shaders/floor_readability.gdshader` y `scripts/scenery_finish.gd`.

## Laboratorio

No hay bandas de sol, sheen móvil ni glare genérico. La iluminación general procede de 24 fuentes artificiales en una retícula de 288×192 px, desde (176,208). Sólo se dibuja su efecto sobre el entorno: las luminarias del techo están ocultas por defecto (`show_ceiling_fixtures=false`). Energía 0,30 y diámetro 370 px, con tono blanco frío. Las tres luces principales de la primera fila proyectan sombras; las demás mantienen el coste bajo.

Cada luminaria tiene un pequeño parpadeo independiente: caída máxima del 18%, ventana de 0,35 s, cada 24–30,8 s según la luminaria. Con movimiento reducido queda constante.

Los equipos con pantallas o tubos visibles emiten luz local hacia su frente. Los equipos del borde sur muestran vistas posteriores de servicio: rejillas, carcasas y conductos, sin pantallas brillando a través de la espalda. Se interpreta “mirando al jugador” como orientación hacia la cámara compartida; la luz no persigue a uno de los dos jugadores.

Se crearon con el MCP de Aseprite seis variantes posteriores: muro de monitores, consola de Control, tanque de Síntesis, cámara de descontaminación, locker hazmat y estantería de contenedores. Se aplican a los equipos con base en y≥780. No se invierten sprites verticalmente, no se mueven equipos y no cambian sus huellas. Emisión de equipos: 1,85; energía de luz 0,42 y alcance 176 px. Ambient 0,50 y glow 0,52.

Archivos: `lab/scripts/laboratorio_effects.gd` y fuentes/exportaciones nuevas en `visuals/lighting_coherence/`. Los assets originales de `lab/assets/` no se modificaron.

## Partículas

`scripts/ambient_particles.gd` crea 3–4 emisores fijos por mapa, con 10 motas por emisor, vida de 9 s y deriva de 2,25–5 px/s. Polvo cálido en plaza/pasillos, partículas frías y discretas en Lab, y polen/motas cerca de agua y palmeras en Splash. Se dibujan detrás de los actores, se reciclan y se ocultan/congelan con movimiento reducido. La textura de 8×8 y la luminaria de 32×12 fueron creadas con Aseprite MCP. Se retiró también el brillo de la fachada de madera de vestuarios; el vidrio del kiosco y los reflejos del agua permanecen.

## Validación

- Godot MCP: `tests/LightingReview.tscn` cargó Shopping, Lab y Splash con 65 huéspedes cada uno y emitió `MCP_LIGHTING_REVIEW_COMPLETE`. Sin errores de ejecución; quedan advertencias de estilo de GDScript ya existentes.
- `test_lighting_coherence.gd`: 26 comprobaciones, incluyendo máscara solar, ausencia de luz en locales/cine, orientación, retícula invisible, parpadeo y partículas con movimiento reducido.
- `test_visual_finish.gd`: 84 comprobaciones sin fallos. Se actualizó el criterio anterior de “tres reflejos en todos los mapas” para verificar la nueva petición: sin reflejos genéricos interiores y con agua exterior conservada.
- `test_actor_lighting.gd`: 7.212 muestras de píxeles de actores, sin variaciones superiores a 0,01 RGB al encender/apagar las luces. Contornos, padding y sombras de los huéspedes conservados.
- Mapas: 61 comprobaciones sin fallos. Selector/reinicio/menú: sin fallos. Regresiones: 23 sin fallos. Interfaz: 112 sin fallos.
- Navegación: pasada final completa de 138 comprobaciones sin fallos, máximo de inmovilidad observado de 4 s. Una pasada intermedia registró 28 s junto al borde sur de Splash; se conserva el log y no se tocó la IA ni se relajó el criterio, siguiendo el alcance visual.

### Rendimiento

1920×1080, Mobile/HDR, RTX 3060 Laptop, VSync desactivado, 65 huéspedes activos, 100 cuadros de calentamiento y 360 de medición:

| Mapa | FPS promedio | Tiempo de cuadro p95 | Tiempo GPU p95 | Draw calls máximas |
| --- | ---: | ---: | ---: | ---: |
| Shopping | 282,3 | 5,36 ms | 0,54 ms | 396 |
| Laboratorio | 218,7 | 9,33 ms | 0,98 ms | 1111 |
| Splash | 213,2 | 8,37 ms | 0,54 ms | 653 |

En esta pasada ya no apareció el límite de presentación a 30 FPS de la sesión anterior. Se superaron los 60 FPS en los tres mapas durante la muestra. La medición de Lab se repitió con las luminarias ocultas: el mayor cuadro fue 13,88 ms. No se atribuye el cambio de límite a un ajuste concreto del sistema.

Capturas y logs: `tests/visual_artifacts/`, prefijo `coherence`. Se incluyen capturas con movimiento reducido. Comparaciones: `comparisons/<mapa>_coherence.png`.
