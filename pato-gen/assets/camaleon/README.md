# Camaleón — arte aprobado v02

Las poses originales proceden de `work/camaleon-concepto-v02/` y conservan sus bytes aprobados. El ciclo de marcha del 06/11/2026 se añade en archivos separados.

- `camaleon.aseprite`: copia exacta de la fuente aprobada `camaleon_v02.aseprite`, seis poses estáticas de 32×32 con cuatro capas.
- `camaleon_abajo.png`, `camaleon_arriba.png`, `camaleon_derecha.png`, `camaleon_izquierda.png`: cuatro vistas normales aprobadas.
- `camaleon_camuflado.png`: frente ceniza aprobado con manchas grandes, sin franja clara ni ojos ámbar.
- `camaleon_emboscada.png`: pose frontal aprobada de emboscada.
- `retrato.png`: copia exacta de `camaleon_abajo.png`, utilizada en el selector.
- `camaleon_poses_sheet.png` y `.json`: exportación aprobada horizontal de 192×32. Orden: abajo, arriba, derecha, izquierda, camuflado, emboscada.
- `poses_fuente.json`: dibujos originales y paletas normal/camuflada.

`camaleon_marcha.aseprite`, `camaleon_marcha.png` y `camaleon_marcha.json` contienen la nueva marcha: cuatro cuadros por dirección a 125 ms, hoja horizontal de 512×32. El orden es Abajo (1–4), Arriba (5–8), Derecha (9–12), Izquierda (13–16). La hoja `camaleon_marcha_camuflada.png` y su fuente/JSON corresponden a los mismos pasos, con transparencia idéntica cuadro por cuadro. Los brazos y las piernas alternan su apoyo conservando el diseño original.

`scripts/camaleon_arte.gd` construye cuatro animaciones de marcha de cuatro cuadros a 8 fps y cuatro animaciones `idle_*` con las poses originales. `frames()` devuelve celdas normales de 32×32; Bot aplica el margen compartido de dos píxeles por lado.

`piel_camuflada(direccion, cuadro = -1)` devuelve una textura de 36×36 con ese mismo margen para alinear el shader de transición. Con `cuadro = -1` usa el reposo: la vista frontal utiliza exactamente el PNG camuflado aprobado y las otras tres vistas sustituyen en memoria los colores de `palette` por los de `camouflage_palette` del JSON aprobado. Con cuadros 0–3 usa la hoja de marcha camuflada. Las señales de `AnimatedSprite2D` mantienen la piel alternativa sincronizada incluso entre actualizaciones físicas.

Las trece parejas de colores del JSON están incorporadas literalmente en la constante `REMAPEO` del builder. Las texturas usan `preload` como dependencias explícitas de exportación. El juego exportado no necesita abrir el JSON con `FileAccess`; el archivo original se conserva como fuente de auditoría junto al arte aprobado.

Las texturas generadas se comparten entre bots y no escriben archivos nuevos. La transparencia de los cuerpos sigue siendo binaria. El shader de Camaleón cambia la piel y mantiene por separado el contorno de equipo cian/magenta. `limpiar_cache()` libera las referencias propias al terminar las pruebas, sin borrar las texturas de otras cepas.
