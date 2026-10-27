# Verificación de Pato Splash

> Registro histórico anterior a las partes 1 y 2. La validación vigente está en `PARTE2_MAPA_SPRITES.md`, `tests/part2_validation.json` y `tests/part2_palette_check.json`. El antiguo dato de cero píxeles de cabeza modificados corresponde a esta revisión histórica; la parte 2 unificó los colores conservando las siluetas y el alfa.

Revisión final de arte: inflable de la pileta, materiales de los objetos y edificio de vestuarios. Godot **4.7.1**; fuentes raster creadas y exportadas por **Aseprite MCP**. Godot MCP se utilizó para crear la escena inicial, consultar el proyecto y ejecutar capturas y la demo.

## Resultado

`tests/validation.json`: **passed = true**, sin fallos.

- **289 pares de destinos conectados**, comprobando ida y vuelta.
- **289 pares conectados con margen de 36 px**, equivalente a 72 px geométricos. Es una prueba de espacio, no una simulación de robots reales.
- Ambos puntos de aparición tienen una ruta de **736 px** al marcador central del gran chapuzón.
- Todos los marcadores originales quedan libres; no se ocultan destinos bloqueados moviéndolos a otra ubicación en la prueba.
- **54 NPC durante 120 segundos simulados**; recorrido mínimo **5109,76 px**; **574 viajes** terminados.
- **0 muestras de penetración** de los cuerpos en la geometría. Distancia exacta cápsula-rectángulo, tolerancia 0,35 px; muestreo cada dos segundos.
- Se excluyen **20 celdas aisladas** detrás del decorado del conjunto de posiciones donde la demo puede crear visitantes. Todos los destinos de circulación permanecen en la región accesible.
- **11 replanteos de ruta**; mayor bloqueo temporal observado **1,82 s**. Los NPC de demostración se separan suavemente y pueden solaparse entre sí.
- Dos impactos a **38,02 y 88,02 s**, separados por el ciclo normal de **50 s**.
- Concentración limitada a **10 visitantes**; no se modifican las colisiones durante el evento. Pausa comprobada y vibración desactivable comprobada.
- Las cuatro direcciones están presentes en las nueve skins. La comprobación de Aseprite informa **108 cuadros adaptados, 0 píxeles de cabeza alterados y 0 cambios de alfa** (`npc_preservation.json`).
- El balde conserva el punto de giro guardado y su colisión decorativa está desactivada. Los toboganes conservan su colisión sólida.
- **35 fuentes `.aseprite`**: 26 assets ambientales y 9 skins. Todos tienen exportación PNG; los animados incluyen JSON. Los materiales añadidos se conservan en capas separadas cuando corresponde.
- Capturas del mapa y de la descarga a **1920 × 1080**; hojas de contacto y GIFs del inflable y los vestuarios.

## Límites

La demo no es una partida completa: infección, mutaciones, posesión y robots pertenecen al proyecto de mecánicas. Los eventos emiten señales para integrarse con esa IA; la conexión no se considera probada en el juego principal.

La igualdad de distancia es geométrica. El equilibrio entre cepas y ambos jugadores necesita partidas con población, IA y habilidades reales. La fachada de vestuarios es sólida; las puertas se animan ambientalmente y no habilitan interiores.

## Repetir

```text
Godot --headless --path <proyecto> --fixed-fps 60 --script tests/validate.gd
Godot --path <proyecto> tests/Capture.tscn
```

`tests/validation.log` contiene la salida de la prueba final. Las fuentes originales permanecen intactas; `docs/referencias_sha256.json` registra las copias de referencia utilizadas.
