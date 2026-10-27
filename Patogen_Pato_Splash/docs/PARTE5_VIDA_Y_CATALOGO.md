# Parte 5 · Vida del parque y catálogo

La escena principal incorpora una sola instancia nueva: `10_VidaParque`, de `splash/scenes/VidaParque.tscn`. No se movieron edificios, piletas, tiles ni colisiones. Se conservan el giro de 360°, la fuente Press Start 2P, las nubes y las animaciones anteriores.

## Rutinas

Diez personajes con estación propia: dos guardavidas en las sillas, tres bañistas sobre reposeras, dos chicos que intercambian una pelota, personal de limpieza, fotógrafo y vendedor. Los guardavidas recorren el entorno con binoculares y silban ante un cuerpo que corre dentro de su radio; el aviso tiene cooldown. Los bañistas cambian de postura, se aplican protector o leen. El limpiador alterna trapeado y cartel temporal; el fotógrafo produce un flash pequeño y ocasional.

Otros seis personajes atienden los ciclos de servicio: dos clientes reciben helado y se retiran; dos entran y salen de los vestuarios con apertura sincronizada de las hojas de madera; dos bajan por `Path2D`/`PathFollow2D`, generan coronas de splash, nadan hacia la escalera y salen dejando huellas. Son transiciones visuales de ambiente: la fachada de vestuarios continúa siendo sólida para los jugadores.

Población total: 54 visitantes originales + 10 estacionarios + 6 de servicios/toboganes = **70 NPCs**, además de los dos patos controlables. Los nuevos personajes no añaden cuerpos sólidos. Cuatro pequeños espacios de descanso se reservan sólo en la navegación de la demo, fuera de los pasos principales, para que los visitantes no atraviesen los actores estacionarios.

## Infección e integración

Esta entrega no contiene el contagio completo de Patogen. El controlador recibe estados del sistema real mediante:

```gdscript
var vida = mapa.get_node("10_VidaParque")
vida.configure_navigation(mi_sistema_de_rutas) # Callable: (Vector2, Vector2) -> PackedVector2Array
vida.set_infection_state(actor, true) # actualizar también al curarse
# Alternativa: lector del estado real, sin duplicar datos.
vida.infection_reader = func(actor): return mi_infeccion.esta_infectado(actor)
```

Los actores observados están en `splash_visitors` o `park_watch_targets`, o fueron registrados con `set_infection_state`. Las referencias débiles se limpian al desaparecer el actor. La señal `stationary_reacted(actor, reaction, focus)` permite conectar audio, IA o HUD del juego real. Este controlador no infecta ni cura automáticamente a nadie, y conserva neutro el hook del chapuzón.

Cada actor estacionario expone `infection_radius`, `threshold_mode` (distancia o porcentaje local), `infected_fraction`, `minimum_infected`, `reaction_kind`, `reaction_seconds` y `flee_speed`. Valores iniciales: 176 px, 25% local y al menos un infectado. Se consulta cada 0,3 s.

Tres reacciones: **huir** por una ruta hacia el destino seguro más alejado del foco y volver al puesto, **cubrirse** con animación e indicador, o **avisar** con indicador y gesto de silbato en guardavidas. No se repite la reacción durante el cooldown. Sin un proveedor de rutas, la variante de huida usa cubrirse como respuesta segura.

**I** activa/desactiva una simulación explícita de infección en la demo, con indicadores sobre los visitantes. No altera el juego real. **E** adelanta el chapuzón y **Espacio** pausa también acciones, trayectos y efectos. Los jugadores forman parte de los objetivos que vigilan los guardavidas.

## Ambiente adicional

Atardecer gradual durante seis minutos, con tinte máximo del 10% limitado al mapa; tres libélulas; brillo suave del logo del piso; huellas que se secan en cinco segundos. El pool de huellas es fijo (96), no crece. El Inspector expone duración/intensidad del atardecer, brillo, secado, ciclos de fotografía, servicio, vestuario y tobogán, radio y cooldown del silbato.

## Catálogo completo

Abrir **`res://scenes/asset_showcase.tscn`** y pulsar F6. Incluye **75 fuentes visuales** de las partes 1–5, agrupadas y etiquetadas. Rueda/WASD recorren el catálogo, botón central arrastra, −/+ cambia zoom e Inicio vuelve arriba. Las animaciones de varias direcciones cambian cada cuatro segundos.

Los elementos son nodos reales guardados en la escena, editables y copiables. Cada tarjeta tiene `Vista`, metadata de fuente/exportación y, cuando existe, ruta de prefab. Los prefabs de acciones están en `splash/scenes/actores`; el conjunto funcional está en `VidaParque.tscn`. Los prefabs de mobiliario anteriores conservan sus rutas. El manifiesto es `tests/showcase_manifest.json`.

## Archivos y conservación

- 18 nuevos sprites, cada uno con `.aseprite`, PNG, JSON y SpriteFrames: guardia, silbato, tres reposeras, niño con pelota, pelota, limpieza, fotógrafo, flash, heladero, helado, pasajero de tobogán, alerta, cubrirse, huella, libélula y puerta.
- Nuevos: `stationary_npc.gd`, `park_life.gd`, `asset_showcase.gd`, `VidaParque.tscn`, prefabs de actores, `scenes/asset_showcase.tscn`, generador `art_part5.lua`, builder y pruebas Part5.
- Modificados: `PatoSplash.tscn` (instancia nueva), `demo/demo.gd` (adaptación y prueba), `demo/routes.gd` (reservas), generador completo, empaquetado y documentación.
- Las 57 fuentes anteriores, la paleta de 37 colores, tiles de 32 px y filtro Nearest se conservan. Backup previo en `.work/backups/PatoSplash_parte5_20261026_151011`, fuera del proyecto generado, con manifiesto SHA256 y ZIP anterior. `sources/` permanece intacto.

## Regeneración y pruebas

Ejecutar `tools/art_part5.lua` por Aseprite con `--script-param base=<ruta-absoluta-del-proyecto-con-barra-final>`. Después de importar los PNG en Godot, ejecutar `tests/ApplyPart5.tscn`. En una reconstrucción completa, exportar parte 5 después de `art_giro360.lua`; el constructor completo aplica el builder de parte 5 al final.

Validación vigente: `tests/Part5.tscn`. Comprueba umbrales de infección, referencias liberadas, las tres reacciones, ruta de huida y regreso, silbato/cooldown, los cinco estados de puerta, ciclos de servicios, trayectos completos, pausa, secado, geometría y cobertura del catálogo. Mide 40 s con render nativo a 1920×1080 y todas las actividades; las cifras del equipo están en `tests/part5_validation.json`. Auditorías adicionales: `part5_art.json`, `part5_preservation.json` y `part5_debug.json`. Capturas: `tests/CapturePart5.tscn`.

Resultado: todas las comprobaciones pasaron, sin errores ni warnings nuevos. En NVIDIA GeForce RTX 3060 Laptop GPU: **205,54 FPS medios**, p99 **10,196 ms**, máximo **14,898 ms**, ningún cuadro por encima de 16,667 ms durante la medición. Física a 60 Hz y render sin límite. Se verificaron 106 nodos sólidos sin cambios; las 57 fuentes originales permanecen idénticas. La medición corresponde a este equipo.
