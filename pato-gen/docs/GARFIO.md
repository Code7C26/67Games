# Garfio

Cuarta cepa para ambos jugadores en Shopping, Laboratorio y Pato Splash. Reutiliza selección, posesión, infección, curación, ADN y HUD existentes. Los assets aprobados y `resources/animations/garfio.tres` se conservan sin cambios.

## Controles

- IA: enganche automático contra un sano visible dentro del alcance.
- Garfio poseído: apuntar con el movimiento y pulsar **X (Azul) / J (Magenta)**, o el botón **Enganchar** del HUD. Quieto conserva su última orientación.
- X/J siguen iniciando posesión fuera de un huésped. Mantener la tecla al poseer no dispara; hay que soltar y volver a pulsar.
- El mismo cuarto botón cambia entre Poseer y Enganchar. Se conservan robot, distorsión, calor, mutaciones y Simbionte con sus atajos actuales.

## Captura e infección

1. Reserva exclusivamente un humano sano elegible, con línea libre y dentro del alcance. Todavía puede huir durante preparación y vuelo.
2. Se planta, reproduce preparación durante 0,35 s y muestra una línea discontinua.
3. Extiende el apéndice en línea recta a 400 px/s. La dirección queda fijada al lanzar y permite esquivarlo. Los sólidos bloquean selección, vuelo y arrastre.
4. Al impactar muestra una señal del color del equipo durante 0,16 s. Arrastra la cápsula física real con colisiones, sin teletransporte.
5. Al llegar a 36 px hace **una sola tirada de contagio** usando `_chance_contagio()`, `_contagiar_objetivo()` e `infectar()` del Bot. Conserva temperatura, protecciones, cepa/equipo y recompensas existentes. El valor base es 35%; capturar no garantiza infectar.
6. Entra en recuperación y enfriamiento. Si falla, se interrumpe o agota los 0,65 s sin llegar, no hace la tirada de llegada.

El timer normal omite a la presa reservada y durante el intervalo de 0,7 s posterior a la tirada de llegada. Otros contactos mantienen sus reglas habituales. No crea réplicas, contagios remotos, áreas ni ADN adicional.

Curación del captor, infección/eliminación de la presa, cambio de cepa, pasos del mapa y FIN liberan el agarre. Pausa y reloj del tutorial congelan sus tiempos. Poseer un Garfio cancela una captura automática ya iniciada; la próxima requiere activación manual.

## Ajustar en Godot

Abrir **`resources/garfio_config.tres` en el Inspector**, o acceder desde `Bot.tscn` → script → **Cepa Garfio / Configuración Garfio**. Es un Resource compartido; puede duplicarse y asignarse a otro Bot para variantes. Los parámetros son propiedades exportadas de `scripts/garfio_config.gd`.

| Propiedad | Valor inicial |
| --- | ---: |
| alcance_base | 160 px |
| preparacion | 0,35 s |
| duracion_max_arrastre | 0,65 s |
| enfriamiento | 7 s |
| multiplicador_velocidad | 0,90 de la base (67,5 px/s si base=75) |
| probabilidad_contagio | 0,35 |
| velocidad_arrastre | 200 px/s |
| velocidad_extension | 400 px/s |
| distancia_minima / distancia_contacto | 52 / 36 px |
| radio_impacto / recuperacion | 18 px / 0,25 s |
| alcance_por_nivel / arrastre_por_nivel | +20 px / +35 px/s |
| bonos_virulentos | +0,03 / +0,05 / +0,08 |

200 px/s permite recorrer de 160 a 36 px (124 px) dentro de 0,65 s: el presupuesto alcanza 130 px. Los anteriores 135 px/s no llegaban desde ese borde. Se mantienen alcance, preparación, duración, enfriamiento y marcha solicitados. Con más alcance y poca tracción puede producirse un acercamiento parcial: combinar ramas permite completar capturas lejanas. El presupuesto se limita donde se mueve la presa, incluso con un delta grande o cambiando el orden de los bots.

## Mejoras de ADN

Mismos tres botones y costos **5/10/15 ADN**. Cada nivel reemplaza el anterior:

| Rama | Evoluciones | Efecto inicial |
| --- | --- | --- |
| Tendón reforzado | Tendón reforzado → Ligamentos elásticos → Alcance predador | Alcance 180 / 200 / 220 px |
| Arrastre brutal | Arrastre brutal → Anclaje tenaz → Tracción brutal | Arrastre 235 / 270 / 305 px/s |
| Gancho virulento | Gancho virulento → Inóculo dirigido → Garra patógena | +3 / +5 / +8 puntos porcentuales solo en la tirada de llegada |

Gancho virulento no mejora contagios normales ni capturas interrumpidas. Conserva el límite común del 95%. Ninguna rama aumenta la marcha, reduce por sí sola la recarga ni multiplica infectados.

## Archivos

- `scripts/garfio.gd`: fases, búsqueda, disparo, arrastre, llegada y señal visual.
- `scripts/garfio_config.gd`, `resources/garfio_config.tres`: balance exportado.
- `scripts/Bot.gd`: configuración e infección común, con prevención de tiradas duplicadas.
- `scripts/Pato.gd`: activación contextual X/J por flanco de pulsación.
- `scripts/character_select.gd`, `scripts/Mapa.gd`, `scripts/match_hud.gd`: selección, propagación, compra, descripciones y botón contextual.

Pruebas y registros de este ajuste: `work/garfio-ajuste-nov05/`. Los registros anteriores de 5 s/2,3 s y disparo automático poseído son históricos. Estos valores iniciales todavía requieren partidas humanas para evaluar balance competitivo.
