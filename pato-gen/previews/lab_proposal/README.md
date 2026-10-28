# Muestra del laboratorio · sin reemplazo del mapa actual

La propuesta está aislada en `previews/lab_proposal/`, en la rama `codex/lab-proposal-preview`. No se modifican el mapa de producción, su selector, los scripts de partida, el HUD compartido ni los assets originales. La escena hereda el laboratorio sólo para construir una instancia de muestra.

Abrir `LabProposal.tscn` y ejecutar esa escena con F6. La escena principal del proyecto sigue siendo la habitual.

## Cambios propuestos

- Una franja inferior de 224 px: lavado, preparación, reactivos y almacenamiento. Piso ampliado a 1.888×1.024 px; se desplaza el borde exterior inferior y se prolongan los laterales sólo en la instancia de muestra. Se reserva espacio para circular por delante y detrás de las mesadas.
- Paredes divisorias, cuatro puertas de 96–128 px con umbrales y señalización, y continuidad de las paredes laterales. Se despeja la antigua fila sur de equipos para que cada puerta tenga acceso real. Se agregan carro de muestras, depósito de Petri, lavaojos, residuo biológico y carro de carga en los perímetros de las salas nuevas.
- Incubadora completamente nueva, 96×112 px, con puerta de vidrio, bandejas de Petri, panel de temperatura, burletes, bisagras y manija. Ocho frames compatibles con las regiones y tiempos de la incubadora actual. Se muestran las tres unidades del sector Cultivo.
- Mesadas con módulos claros, superficies oscuras, reactivos, pipetas y tubos; una mesada con pileta y grifería, y un estante de insumos. Inspirados en las fotografías aportadas.
- **28 luces cenitales en las posiciones marcadas por el usuario**. Se convierten los puntos y centros de los círculos de la captura 1920×1080 a coordenadas del mapa. Diámetro de 280 px y energía 0,78 para conservar una iluminación suave con más fuentes. Las luminarias siguen ocultas.
- Todas las paredes conservan la oclusión. Las fuentes del techo utilizan la máscara de paredes; así una marca sobre una mesada ilumina su superficie sin quedar anulada por la huella 2D de ese mismo mueble. Las luces de las máquinas mantienen su máscara de paredes y props. Se conservan las normales, los brillos locales y las sombras de contacto.
- Las incubadoras emiten **blanco frío con tono UV**, sin luz verde. Color de iluminación (0,86; 0,83; 1). Se ilumina el vidrio y las bandejas; las pantallas, indicadores y tiras de otros equipos también reciben emisión propia. Se conserva el detalle de los tubos de criogenia evitando sobreexponer toda la superficie del vidrio.
- El HUD conserva controles y textos existentes, con una consola envolvente y placas laterales para completar el espacio exterior al mapa. No se dibuja una capa opaca sobre el área jugable.
- Movimiento reducido congela la animación nueva de incubadoras; se mantienen las preferencias existentes de luces y partículas.

Los nuevos assets tienen fuentes `.aseprite` editables y exportaciones PNG. `draw_assets.lua` los reproduce mediante Aseprite MCP con `PATOGEN_ROOT` como ruta al proyecto. Ejecutar después `draw_room_details.lua` genera nueve variantes adicionales: mesada de lavado con dispensadores, preparación con centrífuga, reactivos con instrumental, estación de higiene, conductos con manómetros, tablero de muestras, desagües, bandejas de cables y contenedor de transporte. Se mantienen las huellas de las mesadas y el carro. Los detalles pequeños no agregan colisiones ni actores infectables.

## Revisión

Renders: `renders/Laboratorio_propuesta_full.png`, `Laboratorio_propuesta_reduced.png`, `Detalle_incubadora_y_mesadas.png` y `Salas_nuevas_detalle.png`. El detalle de assets muestra la incubadora anterior a la izquierda, la nueva en el centro y las mesadas a la derecha. El acercamiento de las salas se amplía 2× con nearest. Son archivos de muestra ignorados por Git.

`capture_proposal.gd` carga la escena real y comprueba población de 65 NPCs, fases de 3/120 s, 28 luces en sus posiciones de pantalla, oclusión de las 36 paredes, tres incubadoras con emisión blanca/UV, conexión transitable de las cuatro puertas, bloqueo de las paredes nuevas y animación detenida con movimiento reducido. Godot MCP también ejecutó la escena. Esta es una revisión visual; la prueba completa de balance y navegación de un mapa ampliado corresponde a una eventual integración posterior.

La pasada final, con movimiento reducido activado y desactivado, registró cero fallos: cuatro recorridos desde las salas anteriores hasta detrás de las mesadas nuevas, espacio físico libre en los destinos y 181 posiciones de destino de NPCs conectadas dentro de la ampliación. Las mesadas se separaron de los umbrales para dar margen a la cuadrícula y al radio de los NPCs.

La colocación de las 28 fuentes difiere como máximo 0,42 px respecto de la captura marcada. `ceiling_points`, `marked_light_energy` y `marked_light_diameter` quedan exportados para ajustes posteriores. La opción `benchmark` del capturador mide 360 cuadros tras 100 de calentamiento, con 65 NPCs activos y VSync desactivado.

Con las 28 luces y los detalles nuevos: **173,6 FPS promedio**, cuadro p95 de **9,42 ms** y mayor cuadro de **14,19 ms**, en 1920×1080 Mobile/HDR sobre RTX 3060 Laptop. No se observó un cuadro superior a 16,67 ms en esa muestra. Ambas capturas, con y sin movimiento reducido, conservaron las cuatro conexiones y las 181 posiciones transitables; cero fallos. Godot MCP ejecutó también la escena actualizada, sin errores de ejecución.

Compromiso de composición: para mostrar la franja nueva y toda el área anterior al mismo tiempo, la cámara reduce la escala del mapa. Las placas laterales completan el espacio sobrante y el tamaño del HUD se mantiene. Esto queda visible en la muestra para evaluar la dirección antes de sustituir la versión actual.
