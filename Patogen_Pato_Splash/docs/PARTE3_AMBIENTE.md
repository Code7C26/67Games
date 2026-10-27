# Parte 3 de 5 · Ambiente animado

Entrega del 26 de octubre de 2026. Fuentes y exportaciones realizadas con **Aseprite MCP**; autoría de escenas, recursos, capturas y ejecución con **Godot MCP**, Godot 4.7.1. Se inspeccionaron las animaciones anteriores antes de completar lo que faltaba.

## Respaldo y continuidad

Backup previo de **629 archivos** en `C:/Users/feliv/.codex/.chatgpt-projects/g-p-6ac7d270eca08191830907d9c9abeba3/.work/backups/PatoSplash_parte3_20261026_102128`, con manifiesto SHA256. El ZIP anterior también se conserva allí antes de reempaquetar.

Se mantiene el tile de **32×32**, la paleta compartida de **37 colores**, Nearest, los caminos de la parte 2, las salidas independientes de los toboganes y las escaleras de borde. Los cinco nuevos assets tienen `.aseprite`, PNG y JSON junto a las fuentes anteriores: **48 fuentes en total**. No se modificaron `sources/` ni las referencias originales.

## Efectos y decisiones

| Efecto | Implementación y límites | Variables de `08_Ambiente` |
| --- | --- | --- |
| Agua | Atlas de cuatro fases de 32 px con destellos; shader sin desplazamiento sobre cada interior de pileta. Conserva las ondas de agua previas y los bordes fijos. | `water_speed` (multiplicador), `water_intensity` (opacidad de destellos) |
| Nubes | Una capa grande de sombras con bordes suaves calculados en shader. Cruza lentamente el parque, opacidad predeterminada 10%, máximo de Inspector 18%; queda fuera del HUD. | `cloud_speed` (px/s), `cloud_intensity` (opacidad) |
| Palmeras | Reutiliza las poses pixel art anteriores: copa hasta ±2 px, tronco y cantero fijos. Fases distintas por ubicación. | `palm_speed` (ciclos/s), `palm_intensity` (px) |
| Hojas | Fuente nueva con cuatro poses; caída ondulante hacia el cantero, desvanecimiento al aterrizar, dos sprites reutilizados como máximo. RNG propio, no altera la aleatoriedad de los NPC. | `leaf_speed` (px/s aproximados), `leaf_intensity` (hojas/minuto para todo el mapa) |
| Banderas | Cuatro poses tomadas del arte original; sólo cambia la tela, mástil inmóvil. | `flag_speed` (ciclos/s), `flag_intensity` (amplitud discreta) |
| Ventiladores | Reutiliza ocho cuadros de aspas; cada equipo conserva su estructura fija. | `fan_speed` (cuadros/s), `fan_intensity` (fracción del tiempo de funcionamiento) |
| Flotantes | Cinco salvavidas y el inflable gigante derivan lentamente y se mecen. Sólo se desplaza el sprite, en píxeles enteros; se limita por la unión de sus siluetas de todas las poses dentro de la pileta. El pato gigante deriva la mitad. | `float_speed` (ciclos/s), `float_intensity` (px), `float_bob_intensity` (px) |
| Mini splash | La cortina pulsa entre 45% y 100% del flujo elegido, sin mover sombrero, columna ni base. Ocho cuadros nuevos de gotas y burbujas dentro de la pileta. | `fountain_speed` (pulsos/s), `fountain_intensity` (flujo/visibilidad del agua) |
| Sombrillas | Poses de lona a ±1 px; poste y colisión fijos, ciclo lento. | `umbrella_speed` (ciclos/s), `umbrella_intensity` (px) |
| Heladería | Letrero nuevo con cuatro estados: pequeño brillo y bajada breve de luminosidad, aproximadamente cada siete segundos. El texto sigue visible; no parpadea todo el edificio. | `sign_speed` (ciclos/s), `sign_intensity` (contraste discreto) |

`enabled` desactiva el conjunto visual y restaura las posiciones base de los flotantes. Las animaciones comparten un controlador y un reloj pausable; los shaders no usan `TIME`. No se crearon timers, tweens ni partículas físicas por objeto. Los sprites fuente conservan la paleta; la transparencia de sombras/agua produce mezcla de colores sólo durante el render.

## Archivos

- Nuevos: `splash/scripts/park_ambience.gd`, shaders `destellos_agua.gdshader`, `sombras_nubes.gdshader`, `fuente_pulso.gdshader`.
- Nuevos assets fuente/exportados: `destellos_agua`, `hoja_palmera`, `bandera_viento`, `fuente_burbujas`, `letrero_helados`; recursos SpriteFrames para los cuatro últimos.
- Mapa modificado: `splash/scenes/PatoSplash.tscn`, con `08_Ambiente`, cuatro capas recortadas de destellos y los detalles de fuente/letrero.
- Autoría reproducible: `tools/art_part3.lua`, `tools/part3_builder.gd`, `tests/apply_part3.gd`, `tests/ApplyPart3.tscn`; actualizado `tools/build_scene.gd` para conservar esta revisión al reconstruir.
- Pruebas/capturas: `tests/part3.gd`, `tests/Part3.tscn`, `tests/capture_part3.gd`, `tests/CapturePart3.tscn`, `tests/part3_validation.json`, `tests/part3_art.json`.
- Actualizados `LEEME.md`, `docs/INTEGRACION.md` y `tools/package.py` para entregar la revisión validada más reciente.

## Verificación y rendimiento

`tests/part3_validation.json`: **passed = true**, sin fallos. Render en **SubViewport nativo de 1920×1080**, para que el ajuste de ventana de Windows no reduzca la resolución de la prueba. Física normal a **60 Hz**, 54 NPC, render sin límite y VSync desactivado sólo durante el benchmark. No cambia la configuración del proyecto.

En NVIDIA GeForce RTX 3060 Laptop, Godot 4.7.1, se midieron **50 segundos con todos los efectos**: 11.994 cuadros, **239,88 FPS de promedio**, mediana de 3,34 ms, percentil 95 de 7,89 ms y **percentil 99 de 10,60 ms** (equivalente a 94,38 FPS). El 99,97% de los cuadros quedó dentro del presupuesto de 16,67 ms de 60 FPS. Hubo **cuatro picos aislados**, máximo 35,55 ms; el informe conserva los valores, sin prometer ausencia absoluta de interrupciones del escritorio. El resultado depende del equipo.

La referencia visual con ambiente desactivado duró ocho segundos y promedió 251,07 FPS. Es una comparación de la escena completa, no un aislamiento exacto del costo GPU de cada shader. El máximo observado con ambiente fue de 457 draw calls, incluyendo la presentación del SubViewport.

- **Geometría de colisión idéntica** antes/después de animar; cero muestras de penetración de visitantes y cero salidas de flotantes fuera del agua.
- **288 viajes completados**, recorrido mínimo de NPC de 2597,93 px; las animaciones no cambian sus destinos ni sus cuerpos.
- Cuatro hojas aparecieron en la prueba; máximo simultáneo observado de una, con presupuesto fijo de dos.
- Pausa comprobada también en shaders; 20 controles exportados de velocidad/intensidad, más el control vertical de flotantes. 206 nodos raster/tiles revisados con Nearest.
- Comprobación adicional de render en `tests/Part3Visual.tscn`: 1158 píxeles de agua cambian entre flujo completo y apagado; **cero píxeles estructurales** del sombrero, columna o base cambian. Esta comprobación se añadió al ajustar el recorte final de la columna.
- Chapuzón a 38,00 s, concentración máxima observada de nueve visitantes, por debajo del límite de diez.
- `tests/part3_art.json`: cinco assets nuevos, **cero píxeles fuera de la paleta**. Fuentes anteriores y paleta sin cambios.
- `tests/part3_preservation.json`: verificación SHA256 contra el backup; las **43 fuentes anteriores**, sus PNG, la paleta, la configuración del proyecto y las hojas de referencia permanecen idénticos. Incluye el inventario de archivos creados/modificados.
- Proyecto y demo ejecutados sin errores ni warnings nuevos en la verificación final.

Las capturas PNG son de 1920×1080. `captures/parte3_ambiente.gif` es una vista resumida a 960×540 y 10 FPS para revisar movimiento; esa tasa del GIF no representa el rendimiento del juego.

La entrega sigue siendo el mapa y la demo de circulación. Infección e IA de la partida principal mantienen la integración pendiente descrita en `INTEGRACION.md`.
