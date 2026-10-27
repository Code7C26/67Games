# Integración en Patogen

La capa vigente de personajes y ambiente es `10_VidaParque`, instancia de `splash/scenes/VidaParque.tscn`. Conectar su proveedor de rutas y estados de infección según [PARTE5_VIDA_Y_CATALOGO.md](PARTE5_VIDA_Y_CATALOGO.md). El catálogo completo y copiable se encuentra en `scenes/asset_showcase.tscn`. Prueba actual: `tests/Part5.tscn`; los informes anteriores describen sus revisiones históricas.

## Mapa y cámara

1. Copiar **`splash` completa** al proyecto de mecánicas, manteniendo sus rutas `res://splash/...`.
2. Instanciar `res://splash/scenes/PatoSplash.tscn` en **(0,0), escala (1,1)** como entorno de una nueva escena de partida. Mantener los controladores, patos, bots y HUD reales.
3. El lienzo es **1920 × 1080**. El mapa ocupa `Rect2(32,112,1856,860)`, disponible como metadata `play_rect`; usar esa región para la cámara/HUD. El encabezado de la demo termina en y=96 y el pie comienza en y=992.
4. Los obstáculos usan **capa física 1, máscara 0**. Confirmar que los cuerpos reales consultan capa 1. El agua es un obstáculo: esta primera versión se recorre por las veredas, no incluye natación.
5. Leer los marcadores `06_Marcadores/InicioPato_A` **(592,744)** y `InicioPato_B` **(1328,744)**. El giro de 360° reparte 24 impactos sobre piso libre del parque, tres por sector. Los marcadores de terraza se conservan para compatibilidad; ya no se convoca NPCs allí.
6. Los objetos usan origen inferior y `04_Objetos` tiene `y_sort_enabled` y `z_index = 1`. Colocar los actores en ese contenedor o reproducir su orden de dibujo. Los charcos se dibujan a z=0 y los splashes a z=3. El balde es decorativo.

Los pisos son un `TileMapLayer` de 32 px; `07_Caminos` añade 383 celdas conectadas con el tileset `splash/assets/caminos_32.tres`, 16 variantes y terreno nativo `MATCH_SIDES`. Piletas, señales, objetos y marcadores son nodos editables. Las instancias de objetos permiten editar sus hijos; sus colisiones se guardan en la escena. No regenerar encima de una versión editada manualmente sin conservar una copia.

Las diez palmeras usan `palmera_cantero.tscn`: tierra y borde de cemento de 64×64 px, tronco centrado y una única colisión para el cantero; la antigua colisión del tronco está desactivada. Los carteles son decorativos y no añaden obstáculos. Todo el contenido raster usa Nearest y la paleta de 37 colores existentes `patogen_paleta.gpl`.

## NPC

Asignar en las skins sanas del Bot real uno de los recursos:

- `res://splash/assets/banador_1.tres` a `banador_3.tres`.
- `res://splash/assets/salvavidas_1.tres` a `salvavidas_3.tres`.
- `res://splash/assets/staff_1.tres` a `staff_3.tres`.

Animaciones **Abajo / Arriba / Derecha / Izquierda**, 2/2/4/4 cuadros, **5 FPS**, celdas de **32 × 32**. Se preservan las siluetas y el canal alfa original; los colores de cabezas y vestuario se unificaron a la paleta compartida en la parte 2. No hace falta cambiar tamaño ni colisión para vestirlos. Las capas de referencia y vestuario siguen separadas en Aseprite; las referencias originales externas permanecen intactas.

Las referencias provienen de las hojas NPC 1, 2 y 3 ya disponibles en la entrega local del laboratorio. Sus hashes están en `referencias_sha256.json`. Los patos de exploración usan ahora `splash/assets/pato_parque.tres`: 32 cuadros de 32×32, ocho por dirección a 8 FPS, basados en las hojas del jugador y sus once colores. La demo los muestra a escala 2× y conserva el radio físico de 15,6 px. Las hojas originales de `demo/references` no se modificaron.

## Ambiente configurable

La escena del mapa incluye `08_Ambiente`, con `splash/scripts/park_ambience.gd`. Sus diez grupos exponen velocidad e intensidad para agua, nubes, palmeras, hojas, banderas, ventiladores, flotantes, fuente, sombrillas y letrero. Las unidades figuran en el Inspector y en `PARTE3_AMBIENTE.md`; el vaivén vertical de flotantes tiene además `float_bob_intensity`.

El controlador es visual: no mueve los nodos físicos ni cambia la navegación. Las capas de destellos son hijas de cada pileta, debajo de los objetos. Las sombras se recortan al parque y no afectan al HUD. Las hojas se reutilizan en un pool fijo de dos sprites. Los shaders usan un reloj propio, sin `TIME`: pausar el mundo congela también nubes, agua y hojas. El nodo debe conservar el modo de proceso heredado del mundo pausable.

Para desactivar el ambiente usar `08_Ambiente.enabled = false`; se apagan las capas añadidas y los flotantes vuelven a su posición base. Las caídas de agua de los toboganes y el chapuzón siguen siendo efectos independientes. Los prefabs aislados conservan su animación original; los controles globales se aplican cuando están en la escena completa.

## Evento y conexión con la IA

El script de la raíz `splash/scripts/splash_event.gd` expone:

```gdscript
signal phase_changed(phase: String, seconds_left: float)
signal attraction_requested(destinations: Array[Vector2], max_visitors: int, duration: float)
signal attraction_finished
signal splash_impact(strength: float)
signal npc_splashed(actor: Node)
signal infection_effect_requested(actor: Node, effect: int, exposure: float)
```

- `phase_changed`: mostrar el estado y el aviso para ambos jugadores en el HUD real.
- `attraction_requested`: hook opcional para convocar visitantes usando **la navegación real**. La revisión de 360° establece `max_attracted_visitors = 0`; los NPCs mantienen sus recorridos. Si se habilita en el juego real, no reposicionarlos ni sobrescribir equipo, cepa o infección.
- `attraction_finished`: liberar la intención temporal de visita y devolverlos a su comportamiento normal.
- `splash_impact`: conectar a una vibración breve de la cámara común, dejando intacto el HUD. Respetar la preferencia de movimiento reducido.
- `npc_splashed`: aplicar o escuchar el estado empapado de un cuerpo alcanzado. El área `09_GranChapuzon/ParqueMojado` consulta capa física 2 y grupo `splash_visitors`; ajustar la máscara a las capas del juego real. La reacción requiere proximidad al impacto, no sólo estar dentro del área.
- `infection_effect_requested`: sólo se emite si `infection_effect` es 1 (limpiar) o 2 (propagar), una vez por actor y evento. El valor 0 (neutro) es el predeterminado. Conectar aquí el sistema real de contagio usando `exposure`; el mapa no presupone propiedades del Bot.

La secuencia actual es 1,5 s de aviso, 1,5 s de chorro y 1 s de cierre; luego el reloj vuelve a los 30 s de calma. Invocar `request_attraction()` para adelantarla desde el HUD. `09_GranChapuzon` contiene los emisores CPU, área y controles del cañón. La cámara puede tomar `shake_intensity`, `shake_duration` y `stream_shake_intensity` de ese nodo. `impacts_per_sector` controla el reparto (3 × 8 = 24); `particle_amount` controla el chorro (96). Ver `GIRO360_CORONA.md` para los estados de NPC, aterrizaje balístico y parámetros vigentes.

El mapa emite esas señales, pero **no dirige automáticamente el `Bot.gd` real**. `demo/visitor.gd` y `demo/routes.gd` son adaptadores de demostración, no sustitutos de esa IA. Antes de integrar, añadir una intención temporal de destino al controlador real respetando posesión, persecución y otras prioridades existentes.

La navegación de la demo prefiere las celdas de los paseos con un peso de 0,72 frente a 1 en el resto del suelo transitable; no obliga a todos los visitantes a caminar por una sola línea. La IA real debe adoptar explícitamente esta preferencia si se desea reproducirla. Las comprobaciones de paso incluyen los canteros sólidos de esta revisión.

Activar `enabled` cuando comienza la fase de partida correspondiente; desactivarlo al terminar. El reloj debe pausarse junto con la simulación. `audio_enabled` controla los sonidos del evento; la ambientación continua está en la demo y puede conectarse al AudioManager real.

Los roles salvavidas/staff son sólo apariencia en esta entrega. No curan, conceden recursos ni tienen inmunidad. La distribución de población y el impacto de la concentración temporal requieren pruebas de balance con las tres cepas.

## Regeneración

1. Para rehacer el arte de la parte 2 sobre esta entrega, ejecutar en Aseprite `--batch --script-param base=<ruta-absoluta-del-proyecto-con-barra-final> --script tools/art_part2.lua`. Las 43 fuentes y sus exportaciones ya están incluidas; este paso es opcional.
2. Importar los assets en Godot y ejecutar `tests/ApplyPart2.tscn` para aplicar nuevamente caminos, canteros, carteles y recursos del pato sobre el mapa existente. El script es repetible.
   Para la parte 3, exportar primero `tools/art_part3.lua` mediante Aseprite con el mismo parámetro `base`, y ejecutar después `tests/ApplyPart3.tscn` en Godot. Si se aplican ambas revisiones, el orden es parte 2 y luego parte 3.
3. Para reconstruir el mapa completo, `tools/prepare.py` prepara el layout y sonido; `tools/build_scene.gd` construye las escenas y llama también a `tools/part2_builder.gd` antes de guardar. No ejecutar esta reconstrucción encima de cambios manuales sin backup.
4. Para la parte 4 y el giro actual, ejecutar en Aseprite `tools/art_part4.lua` y después **`tools/art_giro360.lua`**, con el mismo parámetro `base`; esperar la importación de los PNG en Godot y ejecutar `tests/ApplyPart4.tscn`. El redibujado central `tools/art_pato_central.lua` debe preceder a esas exportaciones. El constructor completo aplica además el builder de parte 4 y la fuente.
5. Validación actual: **`tests/Giro360.tscn`**, con 54 NPC y render nativo a 1920×1080. Captura: `tests/CaptureGiro360.tscn`. Las pruebas y capturas anteriores son históricas; Part4 espera el abanico sustituido y otras asumen el balde.

`tools/build_art.lua` y los scripts de retoques anteriores son generadores históricos. Ejecutarlos solos restaura arte anterior: aplicar después parte 2, parte 3, redibujado central, parte 4 y giro360. Las pruebas vigentes están descritas en `GIRO360_CORONA.md`.

Los generadores sobrescriben los archivos generados de esta entrega. Su uso es opcional: las fuentes Aseprite, las escenas y los recursos pueden editarse directamente.
