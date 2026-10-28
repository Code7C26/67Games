# Muestra del laboratorio · sin reemplazo del mapa actual

La propuesta está aislada en `previews/lab_proposal/`, en la rama `codex/lab-proposal-preview`. No se modifican el mapa de producción, su selector, los scripts de partida, el HUD compartido ni los assets originales. La escena hereda el laboratorio sólo para construir una instancia de muestra.

Abrir `LabProposal.tscn` y ejecutar esa escena con F6. La escena principal del proyecto sigue siendo la habitual.

## Cambios propuestos

- Una franja inferior de 224 px: lavado, preparación, reactivos y almacenamiento. Piso ampliado a 1.888×1.024 px; se desplaza el borde exterior inferior y se prolongan los laterales sólo en la instancia de muestra. Se reserva espacio para circular por delante y detrás de las mesadas.
- Paredes divisorias, cuatro puertas de 96–128 px con umbrales y señalización, y continuidad de las paredes laterales. Se despeja la antigua fila sur de equipos para que cada puerta tenga acceso real. Se agregan carro de muestras, depósito de Petri, lavaojos, residuo biológico y carro de carga en los perímetros de las salas nuevas.
- Incubadora completamente nueva, 96×112 px, con puerta de vidrio, bandejas de Petri, panel de temperatura, burletes, bisagras y manija. Ocho frames compatibles con las regiones y tiempos de la incubadora actual. Se muestran las tres unidades del sector Cultivo.
- Mesadas con módulos claros, superficies oscuras, reactivos, pipetas y tubos; una mesada con pileta y grifería, y un estante de insumos. Inspirados en las fotografías aportadas.
- **16 luces cenitales** (cuatro por cuatro), manteniendo diámetro de 350 px, energía 1 y oclusión por paredes y equipos. Las luminarias siguen ocultas.
- Las incubadoras emiten **blanco frío con tono UV**, sin luz verde. Color de iluminación (0,86; 0,83; 1). Se ilumina el vidrio y las bandejas; las pantallas, indicadores y tiras de otros equipos también reciben emisión propia. Se conserva el detalle de los tubos de criogenia evitando sobreexponer toda la superficie del vidrio.
- El HUD conserva controles y textos existentes, con una consola envolvente y placas laterales para completar el espacio exterior al mapa. No se dibuja una capa opaca sobre el área jugable.
- Movimiento reducido congela la animación nueva de incubadoras; se mantienen las preferencias existentes de luces y partículas.

Los nuevos assets tienen fuentes `.aseprite` editables y exportaciones PNG. `draw_assets.lua` los reproduce mediante Aseprite MCP con `PATOGEN_ROOT` como ruta al proyecto.

## Revisión

Renders: `renders/Laboratorio_propuesta_full.png`, `Laboratorio_propuesta_reduced.png`, `Detalle_incubadora_y_mesadas.png`. El detalle muestra la incubadora anterior a la izquierda, la nueva en el centro y las mesadas a la derecha. Son archivos de muestra ignorados por Git.

`capture_proposal.gd` carga la escena real y comprueba población de 65 NPCs, fases de 3/120 s, 16 luces, tres incubadoras con emisión blanca/UV, conexión transitable de las cuatro puertas, bloqueo de las paredes nuevas y animación detenida con movimiento reducido. Godot MCP también ejecutó la escena. Esta es una revisión visual; la prueba completa de balance y navegación de un mapa ampliado corresponde a una eventual integración posterior.

La pasada final, con movimiento reducido activado y desactivado, registró cero fallos: cuatro recorridos desde las salas anteriores hasta detrás de las mesadas nuevas, espacio físico libre en los destinos y 181 posiciones de destino de NPCs conectadas dentro de la ampliación. Las mesadas se separaron de los umbrales para dar margen a la cuadrícula y al radio de los NPCs.

Compromiso de composición: para mostrar la franja nueva y toda el área anterior al mismo tiempo, la cámara reduce la escala del mapa. Las placas laterales completan el espacio sobrante y el tamaño del HUD se mantiene. Esto queda visible en la muestra para evaluar la dirección antes de sustituir la versión actual.
