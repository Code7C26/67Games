# Rastreador: diseño v02 y animaciones

El diseño aprobado procede de `work/rastreador-concepto-v02/`. Su fuente original se conserva como `rastreador.aseprite`; `retrato.png` es copia exacta del frente aprobado. Los cinco PNG de poses, la hoja original y sus JSON permanecen intactos.

Las animaciones se guardan en archivos nuevos:

- `rastreador_animaciones.aseprite`: fuente editable de 48 cuadros de 32 × 32.
- `rastreador_animaciones.png`: atlas de 256 × 192, ocho columnas por seis filas.

Orden de las celdas: cuatro direcciones **Abajo, Arriba, Derecha, Izquierda**, cada una con un bloque de 12 cuadros. Dentro del bloque: reposo 1–4, marcha 5–8 y detección 9–12. El atlas no lleva separaciones entre celdas; la transparencia y el contorno oscuro forman parte del dibujo, mientras que el borde de equipo se aplica durante el juego.

| Animación | Cuadros por dirección | Velocidad | Bucle |
| --- | ---: | ---: | --- |
| `idle_*` | 4 | 4 fps / 250 ms | Sí |
| `caminar_*` | 4 | 8 fps / 125 ms | Sí |
| `detectar_*` | 4 | 10 fps / 100 ms | No: un gesto de 0,4 s |

El builder `scripts/rastreador_arte.gd` usa preloads explícitos y comparte atlas y SpriteFrames. `npc_readability.gd` añade los dos píxeles de margen por lado para el borde cian/magenta, dejando cada cuadro de presentación en 36 × 36. Los aliases originales `Abajo`, `Arriba`, `Derecha`, `Izquierda` y `Detectar` siguen usando los PNG aprobados.

La reproducción conserva la orientación cuando el bot se detiene y no reinicia la fase al actualizar la misma animación. Detectar se activa una vez por evento, no en cada frame. El Bot decide entre marcha y reposo con su velocidad real, por lo que no sigue moviendo los pies al estar bloqueado contra una pared.

Con movimiento reducido, el reposo queda en el primer cuadro y se omite el gesto de detección; la marcha permanece animada. Las señales de fijación y búsqueda continúan junto al propio huésped y conservan la identificación de equipo. No se añadieron ataques ni cambios de comportamiento jugable como parte de estas animaciones.
