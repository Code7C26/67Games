# Patogen — infectados · 21 de octubre de 2026

Rediseño y animación realizados con el MCP de Aseprite, mediante su API nativa de píxeles, capas y fotogramas. Los archivos de origen se conservaron sin cambios.

## Ver el resultado

- Abrí `VISTA_PREVIA.html`: comparación animada de las cuatro direcciones, reproducción, pausa, avance por fotograma, escalas enteras, fondos y vista de silueta. La sección «Tamaño real» mantiene los personajes en 32×32 píxeles.
- `previews/comparacion.gif`: antes/después de los tres infectados, vista frontal. El original conserva su velocidad de reproducción.
- `previews/cuatro_direcciones.gif`: las doce animaciones nuevas simultáneas, ampliadas, con muestras 1×.
- `previews/escala_real.gif`: las doce animaciones a 32×32, sobre fondo opaco.
- `previews/cuatro_direcciones.png`: vista estática de las cuatro orientaciones.

Para evaluar la escala 1× en el navegador, usá zoom del 100 %. La ampliación siempre usa vecino más cercano.

## Diseño y movimiento

**Atlético — hipertrofia.** Conserva su casco rojo, franja clara y máscara facial. Se reconstruyeron torso, pectorales, hombros, bíceps y antebrazos. Su anchura frontal crece de 26 a 30 píxeles y se contrae en una secuencia 0→1→2→1→0, con pausas breves en los extremos. Tiene paso firme de 800 ms, ojos rojos y pequeñas gotas de saliva.

**Área — fuelles biológicos.** Cabeza humana adelantada y baja, torso abombado y grandes lóbulos respiratorios de membrana carnosa. Sus bocas oscuras tienen bordes amarillentos. Los lóbulos se expanden y abren desfasados; las cohortes de esporas nacen en sus aperturas, derivan lateralmente, ascienden y pierden opacidad. Su marcha arrastrada dura 1.600 ms. Los poros, el pecho y la silueta ancha lo identifican incluso sin partículas.

**Exponencial — gemación.** Dos cráneos separados por espacio transparente, cada uno con mandíbula propia; dos cuellos carnosos convergen en el torso. En los perfiles están escalonados en profundidad para conservar ambas cabezas visibles. Los movimientos de cada cabeza tienen fases distintas. Una cicatriz en forma de bifurcación recorre el pecho y un brazo incompleto emerge del flanco y se reabsorbe durante el ciclo. El crecimiento ocurre debajo de las cabezas.

Se reconstruyeron también las poses intermedias de las piernas. El apoyo inferior se mantiene en y=30 en todos los cuadros, con margen transparente hasta el límite de 32×32.

## Archivos listos para usar

Cada carpeta `npcs/<tipo>/` contiene:

- `NPC_2.aseprite`: 32×32, RGBA, cuatro capas y 64 fotogramas. Etiquetas Abajo, Arriba, Derecha e Izquierda.
- `NPC 2 abajo.png`, `arriba`, `derecha`, `izquierda`: hojas transparentes de 128×128, con 16 celdas de 32×32 en cuatro columnas y cuatro filas. Se leen por filas.
- `NPC2.tres`: recurso SpriteFrames de Godot 4 con las cuatro animaciones, 16 cuadros por dirección, 10 FPS y bucle.
- `NPC.png` y `NPC.json`: atlas completo de 512×128, 16 columnas y cuatro filas; metadatos exportados por Aseprite.
- `animacion.json`: dimensiones, alineación y ritmo.
- `paleta.gpl`: colores usados, para edición.

No hay recorte automático, rotación ni relleno entre celdas. Transparencia alfa real en PNG. El punto central del cuadro es (16,16); el apoyo inferior queda en (16,30).

## Cambios de compatibilidad que hay que aplicar

El exponencial de origen era **48×32**, aunque el tamaño solicitado para esta entrega es **32×32**. Fue redibujado para ese lienzo; no se redujo la imagen anterior. La anchura y las regiones de atlas se actualizaron en el recurso incluido. Si había offsets manuales específicos para su antiguo ancho de 48 píxeles, hay que revisarlos al integrarlo.

Atlético y área conservan 32×32. Se mantienen las cuatro direcciones, sus nombres y los nombres de archivos. Las hojas direccionales ahora son 128×128 y todas contienen 16 fotogramas. El atlético y el exponencial pasaron de 5 a 10 FPS. El área ya utilizaba 10 FPS.

Para integrar, colocá la carpeta `patogen-infectados-oct21` dentro de `res://assets/` y asigná el `NPC2.tres` correspondiente a AnimatedSprite2D. Usá filtro de textura Nearest. Los recursos nuevos ya apuntan a esa ubicación; deben acompañar a las imágenes nuevas. No uses las regiones del recurso anterior para cortar estas hojas.

## Revisión

Se comprobaron los 192 cuadros:
- PNG direccionales y composición de sus editables: cero diferencias de píxeles.
- Cero píxeles sobre los límites del lienzo.
- Apoyo inferior y=30 en los 192 cuadros.
- Dos grupos de cráneo separados en la región superior de los 64 cuadros del exponencial, además de revisión visual frontal, posterior y lateral.
- Apertura/cierre del ciclo y variaciones de volumen, fase, alfa y poses.
- Rutas, celdas y referencias del recurso Godot verificadas contra los archivos exportados.

El informe numérico está en `validacion_visual_y_exportacion.json`; la conservación de originales queda registrada en `originales_sha256.json`. La revisión de regiones y rutas se registra en `validacion_entrega.json`.

No se ejecutó una partida del juego porque esta carpeta no incluye el proyecto Godot.

El script reproducible de dibujo está en `tooling/redisenar.lua` y la validación nativa en `tooling/validar.lua`. Se ejecutan dentro de Aseprite; el parámetro `output` permite elegir otro destino sin tocar las referencias.

