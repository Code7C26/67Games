# Laboratorio: círculos de luz y acabado de equipos · 28/10/2026

> Actualización 29/10/2026: la ampliación aprobada ya está integrada en la escena de partida. Los valores, la disposición de 28 luces y la validación vigente se documentan en [`lab/expanded/README.md`](../lab/expanded/README.md). El resto de este documento conserva el registro de la fase anterior.

Rama `codex/lab-light-pools`, sobre la integración publicada `01d3cd1`. Esta revisión sustituye los valores anteriores de iluminación del laboratorio. Sólo se modifica `pato-gen/`.

## Resultado y valores ajustables

Se pasa de 24 fuentes poco diferenciadas a **12 círculos de luz**, en cuatro columnas y tres filas, con centro inicial (248,284) y separación (480,208). Se ocultan las luminarias: se ve únicamente su iluminación. La textura radial se comparte y se crea una sola vez al cargar.

Respecto de la primera vista de esta revisión, el diámetro aumenta de 280 a **350 px** y la energía baja de 1,25 a **1,0** (20%). La luz de equipos baja de 1,10 a **0,90**, con alcance de 210 px. Los bordes se desvanecen desde un núcleo radial de 0,32. Ambient de escenografía: **0,34**, frente al 0,50 anterior. Color cenital: (0,78; 0,88; 1,0). Altura para normales: 80.

Todas las luces del laboratorio proyectan sombras PCF5, suavidad 1,5, con oclusión completa de su contribución directa. Se utilizan los polígonos de paredes y equipos existentes; no se añaden cuerpos físicos ni se alteran colisiones o navegación. Las aberturas de las paredes siguen dejando pasar luz. Las fuentes cenitales se comprueban fuera de los volúmenes de los muebles. Se corrigió además el nombre de la capa de paredes (`03_Paredes_y_colisiones`) y se incluyen los polígonos de señalética/arquitectura en el tratamiento de escenografía.

El piso y los equipos reciben brillos especulares de las luces locales reales, sin barridos solares: intensidad **0,10** y **0,14**, respectivamente. Se conservan las normales de los CanvasTexture existentes. Las pantallas visibles de secuenciadores, mesas de operadores, cabinas de cultivo y expendedoras se suman a las fuentes de equipos anteriores. Las vistas posteriores del borde sur siguen sin emitir por la cara delantera.

## Personajes y accesibilidad

La petición actual autoriza que la iluminación afecte también a los NPCs. Se conserva el shader `npc_outline`, sus texturas con padding y los materiales de equipo. El cuerpo recibe ambient **0,70** y respuesta a luz local **0,24**. Los contornos no reciben esa luz. Los valores por defecto del shader permanecen en ambient 1 y respuesta 0 para Shopping y Splash. Se aplican también a NPCs creados después de comenzar la partida, incluidas réplicas, sin modificar su lógica.

HUD y contornos de los jugadores siguen autoiluminados. El cuerpo de los patos conserva su configuración anterior. Movimiento reducido suprime el parpadeo y congela/oculta las partículas. Se mantiene nearest, HDR 2D, escalado entero y snap a píxel.

## Assets

El MCP de Aseprite generó **48 variantes PNG**: 42 equipos/props y seis vistas posteriores. Se mejoran contraste de carcasas, biseles de metal, profundidad del vidrio, bordes de cápsulas, verdes de cultivo, grillas de instrumentos y pequeños detalles de servicio. Los originales de `lab/assets/` y las fuentes `.aseprite` no se guardan ni alteran.

`visuals/lab_upgrade/build_assets.lua` reproduce los derivados mediante Aseprite, con `PATOGEN_ROOT` apuntando al proyecto. Exportaciones en `visuals/lab_upgrade/props/`. Los 48 derivados conservaron exactamente dimensiones y canal alfa; las sustituciones de atlas mantienen regiones, márgenes, duración de frames, velocidad y orden de animación. `lab/scripts/asset_finish.gd` comparte texturas y SpriteFrames en caché. `use_polished_assets` permite desactivar el acabado para comparar.

## Archivos principales

- `lab/scripts/laboratorio_effects.gd`, `lab/scripts/asset_finish.gd`.
- `lab/shaders/local_surface_light.gdshaderinc`, `scenery_grade.gdshader`, `floor_readability.gdshader`.
- `shaders/npc_outline.gdshader`, `scripts/visual_preferences.gd` (consulta segura al salir de un mapa).
- `visuals/lab_upgrade/`, `tests/test_lab_light_pools.gd`, `tests/test_actor_lighting.gd`, `tests/run_visual_checks.py`.

## Validación

- Círculos/oclusión: **14 comprobaciones sin fallos**. La prueba renderiza muestras a ambos lados de una pared real: luminancia 0,10046 con sombra y 0,14416 al desactivar la sombra; ambient sin luz 0,10046. La misma fuente ilumina su propio lado y el HUD conserva sus píxeles.
- Píxeles de actores: Shopping **2.251 muestras, cero cambios**; Lab **2.586 muestras, 1.497 responden a la luz**; Splash **2.309 muestras, cero cambios**. Se excluyen muestras tapadas por props o rótulos comparando contra el color esperado sin iluminación.
- Coherencia: **26 comprobaciones**; acabado visual: **84**; mapas: **61**; regresiones: **23**; interfaz: **112**, todas sin fallos.
- Flujo: tres entradas desde selector, tres reinicios y tres regresos al menú, sin fallos.
- Navegación: **138 comprobaciones sin fallos**, seis combinaciones de mapa/semilla, usando `--headless --fixed-fps 60` para avanzar el mismo tiempo simulado.
- Godot MCP cargó los tres mapas con 65 huéspedes y completó `MCP_LIGHTING_REVIEW_COMPLETE`. Quedan advertencias de estilo y de recursos al cerrar en las suites existentes.
- Los primeros intentos de captura/importación dentro del aislamiento encontraron errores de caché/rutas de Windows. Se repitieron los renders finales fuera del aislamiento, sin esos errores; el directorio temporal del runner se acorta a `pgv`.

### Rendimiento

RTX 3060 Laptop, 1920×1080, Mobile/HDR, 65 NPCs activos, VSync desactivado, 100 cuadros de calentamiento y 360 medidos. Son muestras puntuales, no una garantía de mínimo por cuadro.

| Configuración | FPS promedio | Cuadro p95 | Mayor cuadro | GPU p95 | Draw calls máx. |
| --- | ---: | ---: | ---: | ---: | ---: |
| Antes | 171,3 | 10,90 ms | 15,36 ms | 0,965 ms | 1.111 |
| Después | **184,1** | **9,49 ms** | 12,98 ms | 1,193 ms | 1.121 |
| Después, movimiento reducido | **182,8** | 9,71 ms | **19,46 ms** | 1,194 ms | 1.116 |

Se supera el objetivo de 60 FPS en promedio y p95. La muestra con movimiento reducido tuvo un pico aislado de 19,46 ms (equivalente a unos 51 FPS durante ese cuadro); se registra, sin atribuirlo a una causa no medida.

### Capturas

En `tests/visual_artifacts/captures/`:

- `Laboratorio_pools_before.png`, `Laboratorio_pools_after.png`, `Laboratorio_pools_reduced.png`.
- `Shopping_pools_after.png`, `PatoSplash_pools_after.png` como control de los shaders compartidos.

Comparación lado a lado: `tests/visual_artifacts/comparisons/Laboratorio_pools_compare.png` (antes a la izquierda). Logs y benchmarks usan prefijo `lab-pools` / `pools_`. Los artefactos de validación permanecen ignorados por Git.
