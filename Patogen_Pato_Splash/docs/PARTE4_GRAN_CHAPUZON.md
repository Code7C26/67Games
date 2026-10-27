# Parte 4 · Gran chapuzón

> Documento histórico del primer cañón. La implementación vigente gira 360°, reparte impactos por todo el parque y usa menos agua: ver [GIRO360_CORONA.md](GIRO360_CORONA.md). Sus parámetros y pruebas sustituyen los del abanico descrito aquí.

El pato inflable central reemplaza al balde como atracción. El botón del HUD y la tecla E llaman a `request_attraction()`; el reloj sigue emitiendo `phase_changed`. El balde queda decorativo y el antiguo nodo de descarga está vacío.

## Secuencia

1. **Aviso, 1,5 s:** silbato de dos tonos cortos, encabezado rojo intermitente, pose inflada con squash/stretch leve, ondas centrales aceleradas y burbujas alrededor del pato.
2. **Disparo, 1,5 s:** pose con pico abierto, `CPUParticles2D` anclado al pico, gravedad de 1.400 px/s², velocidades aleatorias entre 456 y 484 px/s. Un Tween barre de −33° a +33°. El géiser de la cabeza emite durante 0,48 s.
3. **Cierre, 1 s:** las últimas gotas llegan a la terraza. Impactos de cuatro cuadros y charcos cenitales, de silueta irregular y elíptica. El pato recupera sus ocho cuadros ambientales y su escala original.
4. **Secado independiente:** cada charco desaparece en 10 s; cada NPC recupera su aspecto en 6 s. No se bloquea el suelo ni se cambia su colisión.

Las partículas CPU no exponen un callback por muerte individual. Se programan paquetes de impactos con la misma posición inicial, dirección, gravedad, intervalo de velocidad y vida de las partículas. Al cumplirse ese tiempo se crea el splash, se comprueba que el punto sea terraza libre y se consulta `TerrazaMojada`, un `Area2D` sin colisión sólida. La reacción depende de estar cerca del impacto, no simplemente de entrar en el área.

## Variables editables

En la raíz del mapa (`splash_event.gd`): `calm_seconds`, `warning_seconds`, `splash_seconds`, `settle_seconds`, `soaked_seconds`, `max_attracted_visitors`, `audio_enabled`, `infection_effect` e `infection_exposure`.

En `09_GranChapuzon` (`duck_cannon.gd`): `shake_intensity` (9 px), `shake_duration` (0,6 s), `stream_shake_intensity` (1,4 px), `fan_angle_degrees` (66°), `particle_amount` (360), `initial_velocity` (470 px/s), `water_gravity` (1.400 px/s²), `droplet_lifetime` (1 s), `puddle_dry_seconds` (10 s), `wet_radius` (62 px), `impacts_per_second` (16) y `puddle_opacity` (0,32).

La cámara de la demo suma el golpe con decay cuadrático y la vibración menor mientras hay chorro; el HUD permanece fijo. La pausa del árbol congela el reloj, Tween, partículas, charcos y estados de NPC. Los valores balísticos están ajustados para la terraza actual; cambios extremos de velocidad/vida/gravedad requieren volver a comprobar dónde cae el agua.

## NPC e infección

`demo/visitor.gd` implementa `become_soaked(duration)`: tinte oscuro, gotas animadas y reacción de 1,5 s. Los NPC pares corren a 1,65× por una ruta válida hacia un lado; los impares se cubren y paran brevemente. Ambos recuperan su navegación normal. Se reutilizan las skins originales.

Política exportada `infection_effect`: **0 Neutro**, **1 Limpiar**, **2 Propagar**. Neutro no emite un efecto de infección. Las otras opciones emiten:

```gdscript
signal infection_effect_requested(actor: Node, effect: int, exposure: float)
signal npc_splashed(actor: Node)
```

Conectar `infection_effect_requested` al sistema real de Patogen y decidir allí cuánto limpiar/propagar usando `effect` y `exposure`. Se emite una sola exposición por actor y evento. No se inventaron ni modificaron propiedades del Bot real. Los cuerpos participantes deben estar en capa 2 y en el grupo `splash_visitors`; adaptar `TerrazaMojada.collision_mask` si el juego usa otras capas. `become_soaked` es opcional para un actor externo; `npc_splashed` permite aplicar su propio estado visual.

## Rendimiento y conservación

Prueba renderizada en Godot 4.7.1, 54 NPC, 1920×1080, física a 60 Hz, AMD Radeon(TM) Graphics. 40 s de medición con eventos repetidos: **283,93 FPS medios durante el evento**, p99 **9,877 ms**, máximo **16,03 ms**, ningún cuadro del evento por encima de 16,667 ms. No garantiza el mismo rendimiento en otro hardware.

Se comprobaron 153 impactos, 104 aplicaciones de empapado a lo largo de varios eventos, ambas reacciones, política neutra y hooks limpiar/propagar sin duplicados, barrido completo, aviso rojo, géiser, burbujas, restauración del pato, pausa y secado. Máximo observado: 45 charcos y 7 splashes simultáneos; ambos usan pools de 64, sin crecimiento indefinido. Cámara: pico observado de 10 px.

Las 48 fuentes anteriores, paleta, configuración de proyecto, fuente Press Start 2P, patos controlables y prefabs permanecen idénticos al backup. Se compararon 106 nodos de geometría sólida, sin diferencias. Los siete nuevos assets están dentro de los mismos 37 colores y conservan `.aseprite`, PNG y JSON.

Informes: `tests/part4_validation.json`, `tests/part4_art.json`, `tests/part4_preservation.json`. La escena de prueba es `tests/Part4.tscn`; las capturas se generan con `tests/CapturePart4.tscn`. Los informes de las partes anteriores son históricos.

## Archivos y regeneración

- Nuevos: `splash/scripts/duck_cannon.gd`; `splash/assets/pato_canon`, `gota_canon`, `burbuja_canon`, `splash_deck`, `charco_deck`, `npc_empapado`, `npc_cubrirse` y `silbato_guardavidas.wav`; generadores y pruebas de parte 4.
- Modificados: `splash/scenes/PatoSplash.tscn`, `splash/scripts/splash_event.gd`, `splash/scripts/park_ambience.gd`, `demo/demo.gd`, `demo/visitor.gd`, `demo/routes.gd`, generador completo, empaquetado y documentación.
- Decisiones: balde conservado como decoración, infección neutra de fábrica, charcos debajo de personajes, geometría fija y audio del silbato sintetizado en Godot. El filtro de navegación sólo recoge sólidos, para que el área de detección no bloquee la terraza.

Exportar `tools/art_part4.lua` con Aseprite y `--script-param base=<proyecto-con-barra-final>`. Después importar los PNG en Godot y ejecutar `tests/ApplyPart4.tscn`. Para regenerar desde las partes anteriores: arte de parte 2, parte 3, `art_pato_central.lua` y parte 4; después `tools/build_scene.gd`, que aplica todos los builders y la fuente en orden.

Backup previo a la parte 4: `.work/backups/PatoSplash_parte4_20261026_111326`, con manifiesto SHA256 y el ZIP validado de fuente/nubes/pato. `sources/` no se modificó.
