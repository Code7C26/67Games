# Garfio — arte integrado

Diseño aprobado: infectado encorvado, torso estrecho, brazos largos, tendón expuesto y garras óseas curvas. Se conserva la perspectiva RPG oblicua del resto de los infectados y una paleta común de doce colores opacos. Los cuerpos no incluyen el borde de equipo: lo añade el shader del juego.

## Archivos

- `garfio.aseprite`: fuente animada editable, 32 cuadros de 32×32. La capa visible contiene los dibujos de cada pose.
- `garfio_diseno_aprobado.aseprite`: fuente original de aprobación, con sus cuatro capas separadas y cinco poses.
- `garfio_sheet.png` y `garfio_sheet.json`: exportación Aseprite horizontal de 1024×32, sin separación y con doce etiquetas de animación.
- `../../resources/animations/garfio.tres`: SpriteFrames que usa esa hoja. Las regiones son siempre celdas de 32×32, sin recortar al contenido.
- `garfio_abajo.png`, `garfio_arriba.png`, `garfio_derecha.png`, `garfio_izquierda.png`: cuatro hojas de marcha de 128×32 para herramientas que trabajan con texturas por dirección.
- `retrato.png`: pose frontal aprobada, estática, de 32×32, para el selector.
- `punta_garfio.aseprite` y `punta_garfio.png`: extremo óseo independiente de 16×16, orientado hacia +X. Su centro de dibujo es (8,8). El sistema de enganche puede rotarlo sin rotar el cuerpo.

## Animaciones reales

| Etiqueta | Cuadros Aseprite (1-based) | Velocidad Godot | Bucle |
| --- | --- | --- | --- |
| idle_abajo | 1–2 | 3,5 fps | Sí |
| caminar_abajo | 3–6 | 7,5 fps | Sí |
| idle_arriba | 7–8 | 3,5 fps | Sí |
| caminar_arriba | 9–12 | 7,5 fps | Sí |
| idle_derecha | 13–14 | 3,5 fps | Sí |
| caminar_derecha | 15–18 | 7,5 fps | Sí |
| idle_izquierda | 19–20 | 3,5 fps | Sí |
| caminar_izquierda | 21–24 | 7,5 fps | Sí |
| preparacion | 25–26 | 8 fps | No |
| enganche | 27–28 | 12 fps | No |
| tension | 29–30 | 5 fps | Sí |
| recuperacion | 31–32 | 8 fps | No |

Las acciones del cuerpo se dibujaron hacia abajo. Para las otras orientaciones, el controlador conserva su reposo direccional y el apéndice independiente muestra la dirección real. La extensión del tendón se presenta fuera del cuadro de 32×32: no se agranda el cuerpo.

La marcha alterna poses de contacto y paso con piernas redibujadas y una oscilación de un píxel del torso y brazos. El reposo mantiene los pies en su lugar y mueve hombros/cabeza juntos. Las duraciones de Aseprite se aproximan a los fps del SpriteFrames en milisegundos enteros (286/133/125/83/200 ms).

## Edición y verificación

Los PNG conservan transparencia binaria (alfa 0/255) y píxel duro. Usar nearest y mantener la línea de pies cerca de y=30; el pivote de referencia es (16,30). Se revisaron las poses de marcha y acción ampliadas desde Aseprite. `finalize_exports.py` verifica que los 32 cuadros exportados coincidan píxel por píxel con las definiciones de `poses.json`, y reconstruye las cuatro hojas de marcha, el retrato y el SpriteFrames sin cambiar los píxeles.

`build_frames.py` guarda las definiciones de pose para autoría con Aseprite MCP, a partir de los PNG aprobados conservados en `work/garfio-concepto`. No reemplaza por sí mismo las exportaciones finales.
