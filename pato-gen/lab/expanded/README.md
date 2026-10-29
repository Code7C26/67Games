# Laboratorio AV-07 ampliado

La propuesta visual aprobada está integrada en `scenes/Laboratorio.tscn`, la escena que abre el selector y que se conserva al reiniciar una partida. La antigua entrada `previews/lab_proposal/LabProposal.tscn` instancia este mismo mapa, sin duplicar la ampliación.

## Contenido

- Área de 1.888 × 1.024 px: se añaden 224 px al sur, con lavado, preparación, reactivos e insumos. Cuatro puertas de 96–128 px conectan las salas con el sector anterior; las mesadas dejan espacio transitable por delante y detrás.
- Paredes, umbrales, señalización, mesadas con instrumental, centrífuga, tubos, pileta, dispensadores, conductos con manómetros, rejillas, bandejas de cables y contenedores de muestras. Los detalles pequeños no agregan colisiones ni actores infectables.
- Incubadoras de 96 × 112 px con ocho frames: puerta de vidrio, bandejas de Petri, temperatura, controles, bisagras y manija. Las tres unidades de Cultivo emiten blanco frío/UV, color `(0.86, 0.83, 1.0)`, sin la antigua emisión verde.
- 28 luces en los puntos de la captura marcada aprobada. `ceiling_points`, `marked_light_diameter` (280 px) y `marked_light_energy` (0.78) son ajustables desde el inspector. Las luminarias no se dibujan; se ve su iluminación y su respuesta en el entorno.
- Las luces del techo usan la máscara 4 de las 36 paredes; las de equipos conservan la máscara 2 de paredes y mobiliario. Así una fuente sobre una mesada ilumina su superficie sin quedar atrapada en la huella de ese mismo mueble. Se conservan normales, brillos y sombras de contacto.
- Emisión selectiva de pantallas y tiras: energía 2.15, opacidad 0.58. Glow 0.65 y umbral 0.90. Los tubos de criogenia conservan el detalle del vidrio.
- Consola alrededor del HUD compartido, sin cubrir el área jugable. El juego ya no muestra la etiqueta de muestra. La miniatura del selector se obtiene de la escena integrada.
- Movimiento reducido congela incubadoras, parpadeo y partículas según las preferencias existentes. No se cambian fases de 3/120 s, controles, cepas ni economía. Los cuerpos de NPC responden a la iluminación y los bordes de equipo/HUD conservan su lectura.

`map.gd` construye la geometría antes de preparar la navegación compartida. `effects.gd` extiende los efectos existentes del laboratorio; `hud.gd` extiende el HUD real. No hay dependencias de producción hacia la carpeta de muestras ni se modifican los sprites originales.

## Fuentes y reproducción

Los PNG derivados conservan fuentes `.aseprite` editables. Ejecutar `draw_assets.lua` mediante Aseprite MCP con `PATOGEN_ROOT` apuntando al proyecto; después ejecutar `draw_room_details.lua`. Ambos guardan en `lab/expanded/assets/`. Filtro nearest y sin mipmaps.

Para mostrar todas las salas a la vez, la cámara ajusta el mapa a la franja disponible. Los NPC quedan algo más pequeños que en el laboratorio anterior; las placas laterales completan el espacio y el HUD conserva su tamaño. Es la composición de la muestra aprobada.

## Validación

`tests/capture_lab_expansion.gd` carga la escena de producción y verifica las 28 luces (error máximo de 0.42 px respecto de la captura marcada), las 36 paredes, las tres incubadoras UV, cuatro rutas hasta detrás de las mesadas, 181 destinos transitables en la ampliación, las fases y el marco del HUD sin etiqueta de muestra.

Guarda `tests/visual_artifacts/captures/Laboratorio_integrado_full.png` o `Laboratorio_integrado_reduced.png`. El argumento `reduced` activa movimiento reducido; `benchmark` mide 360 cuadros con 65 NPCs activos tras 100 de calentamiento. `update-selector` actualiza la miniatura del laboratorio desde esta captura.

Las comprobaciones de integración también incluyen `test_maps.gd`, `test_map_flow.gd`, `test_npc_navigation.gd`, `test_match_regressions.gd`, `test_match_ui.gd`, `test_visual_finish.gd`, `test_lighting_coherence.gd` y la prueba renderizada de filtrado de luz a través de paredes `test_lab_light_pools.gd`.

### Resultado de integración · 29/10/2026

- Mapas: 61 comprobaciones; flujo real: tres selecciones, tres reinicios y tres vueltas al menú; regresiones: 23; HUD: 112; navegación: 138; acabado visual: 84; coherencia: 26; iluminación renderizada: 15. Cero fallos funcionales. Navegación mantiene los 65 NPCs móviles en las tres semillas de laboratorio y Splash; máximo de inmovilidad observado: 4 s, sin salidas de los límites.
- Capturas normal y con movimiento reducido: cuatro conexiones y 181 destinos en la ampliación. La prueba por píxeles confirma que una pared elimina la contribución directa de la luz y que el HUD no cambia. En Mobile, el receptor necesita también el bit de sombras: escenografía con máscara 6 y cuerpos con máscara 5; las fuentes de equipos usan 3 y las cenitales 4. No cambia la máscara que permite recibir iluminación (3 en las fuentes). Los bordes permanecen autoiluminados.
- Prueba de píxeles de actores: Shopping 2.278 muestras, cero cambios; laboratorio 1.747 muestras, 972 con respuesta a luces; Splash 2.318 muestras, cero cambios. Cero fallos.
- En esta sesión el control vacío dio **30,01 FPS** y el laboratorio **29,79 FPS**, con 65 NPCs y 1920×1080 Mobile/HDR en RTX 3060 Laptop. El mismo techo de presentación aparece sin objetos ni llamadas de dibujo; no permite confirmar 60 FPS. En el laboratorio se midieron p95 de GPU **10,19 ms**, CPU de render **6,76 ms** y 1.259 llamadas máximas. No se cambian ajustes del sistema para eludir ese límite. Los 173,6 FPS de la muestra anterior no se presentan como resultado de esta integración.
- El proceso de navegación headless termina con código 0 y 138 comprobaciones correctas; Godot imprime avisos de recursos/RID pendientes al cerrar, que el envoltorio estricto marca como error. La prueba de flujo debe ejecutarse con renderizado y tiempo real: acelerar su reloj puede agotar el tiempo de carga antes de que termine el hilo de recursos. No se alteró la carga del juego para adaptar la prueba.
