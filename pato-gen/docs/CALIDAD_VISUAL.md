# Calidad visual de mapas · 28/10/2026

Rama `codex/map-visual-quality`. Sólo se modifica el proyecto principal `pato-gen/`.
Base: `8e829a1`, que conserva por separado la navegación y evacuación anteriores.

## Fase 1 · Contraste y efectos existentes

- `scripts/shopping_effects.gd`: se elimina CanvasModulate; ambient de escenografía 0,64 y viñeta 0,36.
- `lab/scripts/laboratorio_effects.gd`: CanvasModulate blanco, ambient 0,64, viñeta 0,38, glow 0,62, umbral HDR 1,05, emisión 2,35 y luces 0,45–0,60. Las luces usan máscara 2, reservada a escenografía.
- `lab/shaders/scenery_grade.gdshader`: ambient exportable, tintes de sombra (-0,035, 0,025, 0,05) y luces (0,045, 0,02, -0,025), saturación y nubes sobre materiales de escenografía.
- `lab/shaders/floor_readability.gdshader`, ambas viñetas: ambient y fuerza ajustables, preservando el color del vértice y alpha.
- `splash/scripts/park_ambience.gd`: agua 0,65, nubes 0,28, ambient 0,92; sombra aplicada a escenografía y no a huéspedes. Lectura de movimiento reducido mediante `scripts/visual_preferences.gd`.
- Validación y capturas: `tests/capture_maps.gd`, `benchmark_visuals.gd`, `run_visual_checks.py`; resultados generados en `tests/visual_artifacts/` (sin versionar).

Capturas de los tres mapas: `<mapa>_baseline.png` y `<mapa>_phase1.png` en `tests/visual_artifacts/captures/`.

Compromisos: umbral 1,05 en lugar de 0,8 para que el glow no seleccione píxeles blancos de NPCs/HUD; se eleva emisión en equipos. La sombra de nubes ya no es una lámina sobre actores. No se modifican sprites fuente, controles, colisiones, fases ni economía.

Medición base con 65 bots, Mobile/HDR, 1920×1080 y VSync desactivado, RTX 3060 Laptop: Shopping 437,8 FPS; Laboratorio 249,4 FPS; Splash 333,4 FPS. Las mediciones son promedios de 360 cuadros tras 100 de calentamiento; también se guardan percentiles de tiempo por cuadro y llamadas de dibujo.

La fase 4 opcional se omite: hitstop, cámara lenta y retrasar GameOver entrarían en conflicto con conservar los tiempos y fases.

## Fase 2 · Reflejos

`scripts/scenery_finish.gd`, `shaders/prop_reflection.gdshader`, `shaders/glass_glare.gdshader`, `splash/shaders/water_depth.gdshader` y los dos shaders de escenografía/piso. Los tres controladores visuales conectan este acabado sin cambiar lógica de partida.

- Sheen de piso 0,18, velocidad 10 px/s, banda de 65 px cada 900 px, enmascarado por luminancia.
- Reflejos de props: alpha 0,26, compresión vertical 0,34, fade 1,7 y tinte frío; máximo 28 reflejos y 36 vidrios por mapa.
- El fade usa coordenadas del vértice normalizadas al tamaño del frame, no UV del atlas. La onda se limita a la región real del frame para evitar sangrado entre cuadros. Las texturas se actualizan por señal `frame_changed`, sin duplicar cuerpos ni instanciar cada cuadro.
- Vidrio: glare aditivo alpha 0,32, ciclo lento 0,055; región local del cristal y textura alpha del frame conservadas.
- Splash: reflejos recortados dentro de cada pileta, onda de 2 px, caustics 0,16, profundidad 0,24 y espuma 0,50; además brillo en piso mojado y glare en kiosco/vestuarios.
- Movimiento reducido congela el reloj de estos efectos; se conserva su estado estático.

Capturas: `<mapa>_phase2.png`. Shopping y Lab muestran sheen, reflejos de equipos y vidrio; Splash muestra reflejos en agua, brillo de superficie/piso y vidrio. Los reflejos se dibujan debajo de los actores. No se usa captura de pantalla ni un viewport extra para los reflejos, reduciendo coste y evitando reflejar NPCs/HUD.

La segunda pasada de medición de las fases 1–2 quedó cerca de 30 FPS en los tres mapas incluso forzando VSync desactivado y primer plano. Ese resultado queda registrado; no se considera cumplido el objetivo de 60 FPS por inferencia. Se agrega medición de tiempo GPU en la validación final para separar trabajo de render de esperas de presentación.

## Fase 3 · Luz y volumen

`scripts/scenery_finish.gd`, `shaders/scenery_ao.gdshader`, `shaders/floor_light_beams.gdshader` y los controladores visuales de los tres mapas. `scenes/visual/SceneryFinish.tscn` permite ajustar los parámetros en el Inspector; cada controlador exporta `finish_scene`, que puede apuntar a una escena heredada con ajustes particulares para ese mapa.

- Ajuste final de ambient al añadir luz: Shopping 0,60; Lab 0,58; Splash conserva 0,92. Viñetas 0,36/0,38, glow 0,62 y emisión 2,35 se mantienen.
- Lab: seis luces adicionales, cian en Control/criogenia, verde en Cultivo y ámbar en el pasillo. Shopping: seis focos de neón y haces lentos sobre el piso. Splash: sol cálido de energía 0,20 y luz del kiosco.
- Energía local 0,80. Sombras de tres focos principales por mapa interior, máscara 2, alpha 0,32, PCF5 y suavidad 2,0. Splash usa sombra en la luz del kiosco.
- Hasta 72 oclusores estáticos por mapa, derivados de rectángulos físicos existentes. Se crean LightOccluder2D, sin alterar StaticBody2D, CollisionShape2D ni navegación. AO de 18 px de alto y alpha 0,30 bajo paredes y mobiliario.
- Haces aditivos alpha 0,13, sobre el piso y debajo de actores. El reloj se congela con movimiento reducido; también se congela el polvo del Lab. No hay blur de imagen, nuevos assets ni cambios en renderer/escalado/snap.
- Coordenadas y radios de focos, colores, AO, límites de nodos, sol, sheen y reflejos son exportables; los shaders exponen sus parámetros mediante uniforms.

Capturas finales: `<mapa>_phase3.png` y `<mapa>_phase3_reduced.png`. Comparaciones lado a lado en `tests/visual_artifacts/comparisons/`; galería local `tests/visual_artifacts/index.html`.

Compromisos: oclusores rectangulares y tres luces con sombras en interiores para limitar coste; reflejos artísticos de sprites y no SSR/viewport adicional. Se conservan los normal maps existentes; no se crean normal maps nuevos.

## Validación final

- `test_maps.gd`: 61 comprobaciones, sin fallos.
- `test_map_flow.gd`: tres selecciones, tres reinicios y tres regresos al menú, sin fallos.
- `test_match_regressions.gd`: 23 comprobaciones, sin fallos.
- `test_match_ui.gd`: 112 comprobaciones, sin fallos.
- `test_npc_navigation.gd`: pasada final completa de 138 comprobaciones, sin fallos; los 65 NPC se mantuvieron móviles en las seis simulaciones. Dos pasadas intermedias detectaron bloqueos de 10–14 s en Lab/semilla 729. No se relajó el criterio ni se editó la IA. La IA existente usa IDs de instancia en sus intervalos y el orden de recursos/nodos puede cambiar la trayectoria; se conservan los logs de esos fallos, sin presentar la suite como determinista.
- `test_visual_finish.gd`: 84 comprobaciones con movimiento reducido activo/inactivo y cambio de preferencia en ejecución, sin fallos; máscaras, ausencia de cuerpos nuevos, reloj estático y ausencia de instanciación por cuadro.
- `test_actor_lighting.gd`: más de 7.000 muestras de píxeles de huéspedes/jugadores entre los tres mapas; ningún cambio superior a 0,01 RGB al encender/apagar luces. Se congela el escenario para evitar que un actor de ambiente atraviese una muestra.
- `make_visual_report.py`: compara contra `8e829a1` los archivos de gameplay, NPC/readability, perfil y proyecto, normalizando sólo CRLF/LF. Sus contenidos permanecen iguales. No se tocaron assets fuente.

### Rendimiento y limitación de la medición

Se repitió el proyecto base `8e829a1` en una copia de control dentro de `tests/visual_artifacts/`, usando los mismos recursos importados. Tanto esa base como una escena vacía de control dan aproximadamente 30 FPS de presentación en la segunda parte de la sesión, incluso sin VSync ni límite de FPS del motor. La escena vacía usa cero llamadas de dibujo y sólo 0,22 ms GPU p95. Esto demuestra que el límite de presentación observado no proviene de los nuevos efectos; no se atribuye a un ajuste concreto del driver sin evidencia adicional.

| Mapa | GPU p95 base/control | GPU p95 final | GPU p95 final reducido | Draw calls base → final |
| --- | ---: | ---: | ---: | ---: |
| Shopping | 3,33 ms | 4,33 ms | 4,34 ms | 355 → 437 |
| Laboratorio | 5,78 ms | 7,32 ms | 7,32 ms | 1116 → 1143 |
| Splash | 3,25 ms | 3,63 ms | 3,62 ms | 638 → 653 |

El trabajo GPU queda por debajo de 16,67 ms, pero **no se confirma 60 FPS de presentación** en esta sesión. Se reportan ambos datos sin convertir tiempo GPU en FPS de juego. La primera medición sin ese límite dio 249–438 FPS en la base. JSONs, logs de control y mediciones completas se conservan en `tests/visual_artifacts/`. La API de tiempos de render se documenta en [RenderingServer](https://docs.godotengine.org/en/latest/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-gpu).
