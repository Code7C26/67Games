# Camaleón

Quinta cepa de PatoGen, disponible para ambos equipos en Shopping, Laboratorio y Pato Splash. Se especializa en acercarse sin provocar huida temprana. Usa el diseño aprobado v02, conservado sin modificar en `assets/camaleon/`.

## Reglas y controles

- Un bot de IA se camufla automáticamente al terminar la incubación, cuando está listo y lejos de humanos sanos.
- Camuflado conserva la marcha, la persecución y las colisiones normales. Los dos sistemas de percepción consultan `Bot.percibe_infectado`: AreaVision local y la IA de rutas de Laboratorio/Splash.
- Se revela al intentar contagiar, aunque falle la tirada o el humano esté protegido. También se revela a 35 px de un sano, al usar una zona o robot desde la posesión, al intentar curación ofensiva y al recibir la fusión del Simbionte.
- La proximidad continua a un sano y el aura visible del Simbionte impiden recuperar el camuflaje. Las bonificaciones del Simbionte, sus curaciones y su duración se conservan.
- La recarga normal es de 5 s desde una acción incompatible, también si el contagio falla. Desvanecimiento sólo la acorta después de una infección nueva atribuible a este huésped. Seguir cerca de un sano impide ocultarse, sin reiniciar continuamente el reloj ni borrar esa reducción. Pausa y reloj detenido por tutorial congelan la recuperación. FIN cancela el estado antes de pausar los resultados; curarse elimina el componente.
- Al revelarse, los humanos vuelven a detectarlo normalmente: se eliminó el retraso de reacción de Acecho silencioso.
- Poseer conserva el estado y su recarga. Para volver a ocultarse con un huésped poseído, pulsar de nuevo **X / J** o el cuarto botón contextual **Camuflar**. Mantener la tecla con la que se entró al huésped no dispara la habilidad. Liberarlo devuelve la recuperación automática a la IA.

## Parámetros configurables

Abrir `Bot.tscn` → **Cepa Camaleón / Configuración Camaleón**, o editar `resources/camaleon_config.tres`.

| Parámetro | Inicial |
| --- | --- |
| Factor de detección camuflado | 0,30 del rango del observador |
| Distancia de revelación obligatoria | 35 px entre centros |
| Recuperación | 5 s |
| Velocidad | 1,00 de la base (75 px/s) |
| Contagio | Base compartida: 35% por intento, intervalo 0,7 s e incubación 1,1 s |
| Ataque sorpresa, primer nivel | +25 puntos porcentuales sólo al primer intento desde camuflaje |
| Máximo del intento mejorado | 90% |
| Desvanecimiento, primer nivel | Como máximo 1 s restante después de un contagio efectivo |
| Resistencia a curación | Normal; conserva escudos y reglas compartidas |
| Transición de piel | 0,22 s; inmediata con movimiento reducido |

La IA navegada usa 240 px de percepción normal: el camuflaje inicial baja ese rango a 72 px. AreaVision usa un círculo de 53 px más el solapamiento físico del cuerpo; al camuflarse se compara distancia entre centros y se aplica `max(35, rango_normal × factor)`. Por eso el sensor local nunca baja de 35 px. No se reduce ni se cambia la forma compartida de AreaVision. Las otras cepas mantienen sus rangos y su lógica de percepción.

## Mejoras

Las tres ramas reutilizan los tres botones y las compras de **5 / 10 / 15 ADN**. Se transmiten a los nuevos contagios mediante el sistema existente del equipo.

| Rama y evoluciones | Efecto por nivel |
| --- | --- |
| Pigmentación avanzada → Mimetismo → Cromatóforos | Factor 0,27 / 0,24 / 0,21; en la IA de 240 px: 64,8 / 57,6 / 50,4 px. El piso local de 35 px se conserva. |
| Desvanecimiento → Retorno sigiloso → Adaptación fugaz | Un contagio efectivo reduce el tiempo restante a 1 / 0,9 / 0,8 s como máximo. Los fallos y las habilidades siguen usando la recuperación normal de 5 s. La cercanía de sanos y el aura del Simbionte siguen bloqueando ocultarse. |
| Ataque sorpresa → Emboscada viral → Golpe furtivo | +25 / +30 / +35 puntos porcentuales al primer intento de cada ciclo de camuflaje, con máximo de 90%. Consume el bono antes del azar, también al fallar o intentar contagiar a un humano inmune. No se repite sobre la siguiente presa del mismo pulso. |

Se conserva el orden de los botones y sus teclas: Pigmentación, Desvanecimiento y Ataque sorpresa en el lugar que ocupaba Acecho. No cambian los precios de ADN ni el número de ramas o niveles. Los identificadores antiguos de Acecho ya no son mejoras comprables.

Las mejoras no aumentan velocidad, reproducción ni contagio colectivo. Sólo Ataque sorpresa modifica una tirada concreta: primero se calcula la probabilidad normal existente, incluyendo temperatura y los modificadores compartidos, después se suma el bono y se aplica el límite del 90%. Por ejemplo, 40% pasa a 65% en el primer nivel; la base actual de 35% pasa a 60%. Las siguientes tiradas revelado usan la probabilidad normal. No se agrega ninguna tirada de azar.

Desvanecimiento funciona con éxitos de esa emboscada y con contagios normales del mismo Camaleón. Se aplica después de `infectar()` y de verificar que el objetivo era sano y quedó infectado por el equipo correcto. Repetir la llamada sobre ese objetivo ya infectado no vuelve a activar el efecto ni regala ADN; curarlo y contagiarlo legítimamente más tarde sí representa un nuevo éxito. Las inmunidades del Coloso y tras curación ofensiva, el escudo y las curaciones existentes conservan sus reglas.

Los tres efectos completan el ciclo: Pigmentación permite acercarse, Ataque sorpresa mejora una única tirada y un éxito con Desvanecimiento permite preparar antes otra emboscada. Tanto la IA como la posesión conservan sus controles y condiciones normales para recuperar el camuflaje.

Los parámetros de balance están en `resources/camaleon_config.tres`: `factor_deteccion`, `factores_pigmentacion`, `distancia_revelacion`, `recuperacion`, `bonos_ataque_sorpresa`, `probabilidad_maxima_ataque`, `tiempos_desvanecimiento` y `recuperacion_minima`. Este último es el piso de la reducción tras éxito, inicialmente 0,25 s; nunca permite ocultación instantánea. El tope de Ataque sorpresa está limitado al 90% también en código.

## Arte y presentación

`camaleon_arte.gd` conserva las cuatro poses aprobadas para el reposo y agrega ciclos de marcha de cuatro cuadros por dirección, a 8 fps. Las hojas `camaleon_marcha.png` y `camaleon_marcha_camuflada.png` contienen 16 cuadros de 32×32 en orden abajo, arriba, derecha e izquierda. La fuente editable y los JSON acompañan las hojas; los archivos aprobados originales permanecen intactos.

Al moverse, alterna piernas y brazos; al detenerse recupera el reposo mirando hacia la última dirección recorrida. La marcha consulta el desplazamiento físico real, por lo que deja de caminar si queda completamente bloqueado contra una pared. Funciona tanto con IA como durante la posesión.

Cada cambio de cuadro sincroniza la piel camuflada con la misma pose y silueta. El frente de reposo camuflado usa su PNG aprobado exacto; espalda y perfiles de reposo sustituyen solamente la paleta por los colores aprobados, en memoria. El shader exclusivo `camaleon.gdshader` interpola la piel y conserva el borde de equipo cian/magenta de 2 px y la iluminación del laboratorio. La opacidad del cuerpo no se reduce a cero.

## Archivos de integración

- `scripts/camaleon.gd`: estados, recuperación, proximidad, percepción de observadores y presentación.
- `scripts/camaleon_config.gd`, `resources/camaleon_config.tres`: parámetros y límites.
- `scripts/camaleon_arte.gd`, `assets/camaleon/`, `shaders/camaleon.gdshader`: arte aprobado, variantes de paleta y transición.
- `scripts/Bot.gd`, `scripts/npc_brain.gd`: integración de infección, curación y percepción.
- `scripts/Mapa.gd`: cepa, mejoras y limpieza al final.
- `scripts/Pato.gd`, `scripts/character_select.gd`, `scripts/match_hud.gd`: entrada, selector y estado de habilidad.

Pruebas y evidencia de esta integración: `work/camaleon-integracion-nov06/`, con respaldos, logs, capturas y un informe de ejecución. Las comprobaciones automáticas no sustituyen partidas humanas para afinar el balance competitivo.

Actualización de mutaciones del 06/11/2026: `work/camaleon-mutaciones-nov06/VERIFICACION.md`, con respaldos del estado anterior, pruebas de la nueva sinergia y sus logs. Los sprites, la marcha, el selector, los bordes y los controles se conservan.
