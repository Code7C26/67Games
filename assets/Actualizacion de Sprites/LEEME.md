# Patogen — NPC infectados y zonas de temperatura

Recursos gráficos creados con el MCP de Aseprite a partir de los cinco NPC originales de `67Games/assets/Sprites NPC`. Los originales se conservan como referencia en `referencias/npc`; sus huellas SHA256 están en `referencias/originales_sha256.json`.

## Contenido

- `npcs/sano_retoque/`: cinco humanos con paleta, contornos y pequeñas luces retocados.
- `npcs/atletico/`: cinco cazadores con casco rojo de fútbol americano más ajustado, rejilla metálica, brazos más esbeltos y perfil reconstruido. La ropa desgarrada, el gesto agresivo y la piel cálida toman como referencia al Dr. Mundo proporcionado por el usuario; la piel no es violeta.
- `npcs/area/`: cinco propagadores con una silueta humana más estrecha y crecimientos de hongos concentrados en cabeza, hombro y costado. Conservan pústulas y esporas en tonos hueso, ocre y marrón, inspirados en las referencias del Bloater de TLOU proporcionadas.
- `npcs/exponencial/`: cinco estrategas, con tejido violeta, nódulos celulares y ramificaciones luminosas.
- `npcs/exponencial_endgame/`: **un único modelo adicional**, basado en el NPC 2, con **dos cabezas en total** para el endgame. Las dos caras nacen de un cráneo compartido y compacto, con una fisura central que sugiere la división. La mandíbula se apoya cerca del cuello corto, dentro del cuello de la ropa. Conserva las cuatro direcciones y no sustituye al exponencial base.
- `npcs/previews/npc_variantes.gif`: comparación animada de los cinco personajes en los cuatro estados, mostrando las cuatro direcciones.
- `npcs/previews/rediseno_infectados.gif`: vista ampliada de los tres rediseños solicitados. `rediseno_direcciones.png` muestra sus cuatro direcciones.
- `zonas/`: zonas redondas caliente y fría con partículas interiores y exteriores.

Cada carpeta de NPC incluye las hojas PNG por dirección, un índice `NPC.png`, fuentes nativos de Aseprite y recursos `SpriteFrames` de Godot. Los tres tipos infectados base suman **15 conjuntos completos**. La versión humana suma cinco, y el modelo de endgame suma uno: **21 conjuntos**, **84 hojas direccionales** y **252 fotogramas**.

## Zonas de temperatura

El interior caliente contiene brasas que ascienden, pequeñas estelas y ondulaciones térmicas. El interior frío contiene motas y fragmentos de hielo que caen, y niebla tenue. Las partículas atraviesan también el centro: no hay un símbolo central fijo. Los efectos exteriores de la versión anterior se conservan.

Las animaciones miden **384 × 384 px**, tienen **48 fotogramas**, **12 capas** y duran **3 segundos**. El área circular de referencia conserva un diámetro de **270 px**; el lienzo deja 57 px por lado para las partículas exteriores. El centro gráfico es (192, 192). Las hojas PNG miden 3072 × 2304 y se dividen en ocho columnas y seis filas de 384 × 384, sin margen ni separación.

Usar bucle a **16 FPS**, filtro **Nearest**, `centered = true` y escala efectiva 1. La escala local sería 2/3 si la raíz conserva una escala de 1.5. El margen decorativo no amplía el alcance físico. Para un área circular de 270 px, el radio efectivo de colisión es 135 px.

`zonas/previews/zonas_caliente_y_fria.gif` muestra los efectos sobre el piso oscurecido. `sobre_piso_claro.gif` usa el piso original del mall. Los fondos pertenecen solamente a las vistas previas; las hojas finales son transparentes.

## NPC: animaciones y uso

Las animaciones se llaman **Abajo, Arriba, Derecha e Izquierda**, igual que los recursos del juego. Abajo y Arriba tienen dos fotogramas; Derecha e Izquierda, cuatro. El orden de las celdas de cada hoja sigue siendo por filas. Las fuentes Aseprite contienen las cuatro etiquetas y 12 fotogramas a 5 FPS. Los índices `NPC.png` conservan el orden visual original: abajo, izquierda, derecha y arriba.

Los 20 conjuntos base conservan fotogramas de **32 × 32 px**. El único modelo de dos cabezas usa **48 × 32 px**, para que ambas cabezas mantengan el detalle. Su cuerpo está desplazado ocho píxeles hacia la derecha dentro del lienzo ampliado; con `centered = true` los pies siguen en la misma posición local que antes. Su `.tres` ya usa regiones de 48 × 32. Las hojas de frente/espalda miden 48 × 64 y las laterales 96 × 64. El ancho del dibujo no implica un cambio automático de colisión.

Para usar los recursos `.tres`, copiar esta carpeta con el nombre **Actualizacion de Sprites** dentro de `res://assets/` del proyecto Godot. Las rutas se ajustaron al nombre que ahora tiene la carpeta de arte del repositorio: `res://assets/Actualizacion de Sprites/npcs/...`. Cada recurso referencia los PNG de su variante dentro de esa carpeta. Los UID antiguos se quitaron de las copias nuevas para evitar colisiones con los recursos originales.

La carpeta de referencia de arte `67Games/assets` y la carpeta del proyecto ejecutable `67Games/pato-gen/assets` son distintas en esta copia del repositorio. La entrega de arte no activa por sí misma el cambio de apariencia al infectar: el controlador de infección debe escoger el `SpriteFrames` de su tipo y del NPC correspondiente. En el script consultado la infección aplica además un `modulate` de jugador; al integrar hay que decidir cómo combinar ese tinte con la nueva paleta para que se distingan las clases.

Las mutaciones dibujadas representan las tres familias visuales. Los cambios de velocidad, contagio, curación y progresión corresponden al sistema de juego. Esta entrega no cambia esas reglas ni sus colisiones.

## Edición y validación

Los scripts de generación y comprobación están en las carpetas `tooling`. Las fuentes de NPC separan Base retocada, Mutación morfológica y Detalles vivos. Las zonas separan las emisiones interiores de los efectos del perímetro.

Las cuatro imágenes de inspiración adjuntadas por el usuario se guardan en `referencias/inspiracion`. Son referencias visuales; los sprites finales se dibujaron dentro de Aseprite mediante MCP. La revisión conserva los recursos gráficos de las zonas, los humanos retocados y los exponenciales base.

`validacion.json` registra las comprobaciones de los fotogramas, sus etiquetas y exportaciones. Se compara cada celda PNG con su fuente Aseprite, se conserva la animación de los pies de los NPC y se comprueba que las zonas tienen partículas interiores durante todo el ciclo. Las rutas de los recursos SpriteFrames se verifican contra los PNG de la entrega. La activación de apariencias en una partida debe conectarse en el proyecto ejecutable.
