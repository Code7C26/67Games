# Mutaciones de Garfio y Rastreador

Actualización de noviembre de 2026. Este documento reemplaza las secciones de mutaciones de `GARFIO.md` y `RASTREADOR.md`; sus apartados de arte e identidad base siguen siendo referencias históricas válidas.

## Progresión y compatibilidad

Se conservan tres ramas por cepa y tres compras por rama, con costos de **5 / 10 / 15 ADN**. El primer nivel incorpora la mecánica completa; los siguientes afinan su control o alcance. Se mantienen los identificadores internos para reutilizar compras, herencia, teclas e iconos existentes.

| Cepa | Rama anterior (niveles I → II → III) | Rama actual |
| --- | --- | --- |
| Garfio | Tendón reforzado → Elasticidad → Gran alcance | Presa vulnerable I / II / III |
| Garfio | Arrastre brutal → Anclaje → Tracción | Doble tendón I / II / III |
| Garfio | Gancho virulento → Inóculo dirigido → Garra patógena | Reenganche I / II / III |
| Rastreador | Olfato reforzado → Olfato agudo → Olfato superior | Llamado de manada I / II / III |
| Rastreador | Fijación de presa → Memoria persistente → Rastro tenaz | Cerco depredador I / II / III |
| Rastreador | Instinto de manada → Rastro compartido → Caza coordinada | Marca biológica I / II / III |

`Mapa.gd` continúa cobrando ADN y aplicando la cepa y las mutaciones del equipo a nuevos infectados. La afiliación cian/magenta sigue siendo independiente de las cepas. Las infecciones neutrales del Parásito Alfa conservan sus reglas propias.

## Garfio

La captura base conserva alcance de 160 px, preparación de 0,35 s, extensión de 400 px/s, arrastre de 200 px/s, contacto a 36 px y recarga normal de 7 s. Las tres ramas ya no aumentan el alcance ni conceden virulencia incondicional.

- **Presa vulnerable:** un arrastre completado desorienta a esa presa durante 1 s. Su próximo intento de contagio por el mismo captor suma 25 puntos porcentuales, con un techo del 90%. Se consume tanto al acertar como al fallar. La desorientación reduce el movimiento al 50 / 40 / 30% según nivel, sin detener la IA. El estado se cancela si la presa o el captor dejan de ser válidos.
- **Doble tendón:** el mismo ataque reserva hasta dos sanos y reutiliza la máquina de captura existente con dos apéndices independientes. Cada uno comprueba alcance, línea libre, colisiones y validez. La recarga es común; el arrastre doble tarda un 25 / 20 / 15% adicional. No aumenta la velocidad del captor. Las llegadas respetan una cadencia compartida de 0,7 s para evitar tiradas duplicadas.
- **Reenganche:** un contagio propio vinculado a una captura válida reduce la recarga restante a un máximo de 3 / 2,8 / 2,6 s con la configuración inicial de 7 s. La proporción se mantiene si cambia la recarga base. Una captura doble sólo puede activarlo una vez; los fallos y contagios ajenos a la captura no lo activan.

La IA lanza el garfio automáticamente cuando está disponible. Durante posesión, se conserva **X / J** y el botón **Enganchar**, junto con el apuntado existente. Doble tendón usa esa misma acción. Los efectos reutilizan dibujo procedural y los materiales del garfio; los sprites aprobados permanecen intactos.

## Rastreador

Instinto depredador conserva detección de 1,75 veces el sensor base del mapa y memoria de 6 s. Su punto de persecución procede de una observación real y permanece congelado al perder visión.

- **Llamado de manada:** al fijar una presa visible, puede convocar hasta tres infectados disponibles del mismo equipo a 180 / 200 / 220 px. La convocatoria tiene 8 s de recarga y la coordinación dura como máximo 8 s. Incluye aliados de distintas cepas; excluye humanos, rivales, poseídos y acciones prioritarias. Una reserva individual impide asignar un bot a dos manadas.
- **Cerco depredador:** requiere una manada convocada y al menos dos aliados además del Rastreador. Mantiene una persecución directa y reparte aproximaciones laterales con separación de 48 / 60 / 72 px respecto del rastro observado. Usa la navegación y las colisiones existentes; una ruta lateral inválida cae a persecución normal. No concede velocidad ni contagio. Comprar Cerco antes de Llamado es posible, pero su comportamiento necesita una manada convocada por ese Rastreador.
- **Marca biológica:** una sola presa por Rastreador durante 8 / 9 / 10 s. Observar de nuevo no renueva esa ventana. Sólo el Rastreador y los miembros de su propia manada reciben la información; una observación válida de uno de ellos puede actualizar el último punto conocido. La expiración, infección, curación o eliminación de la presa limpia el estado correspondiente.

La percepción y la convocatoria funcionan automáticamente con IA y durante posesión. Los controles de movimiento del jugador conservan prioridad. No se añaden teclas ni botones. Los compañeros siguen puntos observados a través del planificador existente, con revisiones espaciadas; no consultan la posición oculta para generar destinos.

### Indicadores y pantalla compartida

La convocatoria muestra un pulso breve en el Rastreador. La marca sobre una presa sólo puede dibujarse cuando el mapa declara explícitamente `equipo_visible` para un equipo y la presa está siendo observada. Los mapas actuales comparten un único viewport entre ambos jugadores: allí se omite el indicador sobre la víctima para no revelar su ubicación al adversario. Esta adaptación conserva el efecto táctico de la marca y las señales del propio Rastreador sin prometer visibilidad privada en una pantalla pública.

## Parámetros editables

Los recursos `resources/garfio_config.tres` y `resources/rastreador_config.tres`, enlazados desde `Bot.tscn`, exponen sus propiedades mediante `scripts/garfio_config.gd` y `scripts/rastreador_config.gd`.

| Recurso | Parámetros nuevos principales |
| --- | --- |
| Garfio | `duracion_vulnerable`, `bono_vulnerable`, `probabilidad_maxima_vulnerable`, `factores_movimiento_desorientado`, `factores_duracion_doble`, `factores_recarga_reenganche`, `ventana_captura` |
| Rastreador | `radios_manada`, `maximo_aliados`, `intervalo_manada`, `duracion_manada`, `distancias_cerco`, `duraciones_marca` |

La percepción y la navegación conservan los intervalos configurables existentes. Los límites estructurales de dos presas y tres aliados no se amplían por subir de nivel. La cadencia de contagio proviene de `Bot.INTERVALO_CONTAGIO`, compartida con el sistema normal.

## Archivos de integración

- `scripts/garfio.gd`, `scripts/presa_vulnerable.gd`, configuración y recurso de Garfio: captura, estado temporal, dos tendones y recarga.
- `scripts/rastreador.gd`, `scripts/efecto_rastreador.gd`, configuración y recurso de Rastreador: percepción, reservas de aliados, coordinación, marca y señales.
- `scripts/Bot.gd`, `scripts/npc_brain.gd`: contagio existente, limpieza de estados y elección de destinos observados.
- `scripts/Mapa.gd`, `scripts/match_hud.gd`, `scripts/character_select.gd`: nombres, descripciones, iconos existentes y presentación de las dos cepas.

Los resultados de ejecución y las limitaciones de validación se registran por separado en el informe de verificación de esta entrega. Este documento describe las reglas y no afirma resultados de pruebas.
