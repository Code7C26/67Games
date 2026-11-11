# Reciclaje — tercera rama del Exponencial

Integrada el 05/11/2026 en el controlador compartido de Shopping, Laboratorio y Pato Splash.

| Nivel | Compra | Biomasa necesaria | Efecto |
| --- | --- | --- | --- |
| Reciclaje | 5 ADN | 5 | Prepara una réplica adicional tras cinco pérdidas válidas. |
| Biomasa | 10 ADN | 4 | Reduce el requisito y conserva el progreso hasta la nueva meta. |
| Renacimiento | 15 ADN | 3 | Reduce el requisito a tres pérdidas válidas. |

La rama se compra con **3** (azul) y **0** (magenta), o con el tercer botón del panel. Shift + tecla permite consultar la siguiente evolución.

## Reglas de la reserva

- Cada huésped original curado aporta una unidad al equipo que lo perdió, si ya compró Reciclaje. Una marca persistente en el huésped limita su aporte a una vez por equipo y partida, incluso si cambia de dueño o se reinfecta.
- Cuentan la curación natural, los robots rivales, el Simbionte rival, la curación ofensiva rival y el Coloso neutral. Las curas del propio equipo y las pérdidas de réplicas no aportan.
- Solo se guarda una carga: la reserva se detiene en la meta actual. Las pérdidas mientras está llena no se acumulan ni se descuentan de futuras reservas.
- La carga se libera cuando un infectado original logra contagiar a otro huésped original. Se crea una réplica junto al nuevo infectado y se vacía la reserva únicamente si la creación tiene éxito.
- No se activa con contagios de réplicas, semillas iniciales, recuperación de posesión, intentos bloqueados ni reinfecciones del Coloso que no dan recompensa.
- La réplica cuenta para el resultado y comparte el cupo existente de ocho réplicas por jugador con División celular. También respeta el máximo de cien bots. No concede ADN ni contagios acumulados, no se reproduce y no hereda el Simbionte.
- Si no queda cupo, se alcanzó el máximo de bots o no hay una posición transitable, la reserva se conserva. Shopping ahora comprueba también el trayecto y el lugar de aparición con su navegación física; Laboratorio y Splash mantienen sus comprobaciones existentes.
- La pausa, el reloj retenido por el tutorial y el final de partida bloquean tanto el aporte como la liberación. El estado pertenece a la escena y se reinicia en la siguiente partida.

## Presentación

El estado aparece bajo el nombre del jugador: `BIOMASA n/meta`, `RÉPLICA LISTA` o `CUPO COMPLETO`. Las tres evoluciones tienen iconos de 24×24 en `assets/ui/mutaciones_reciclaje.aseprite`, su hoja PNG y JSON con tags. El atlas original de mutaciones se conserva.

## Verificación

`tests/test_reciclaje.gd` ejecuta compras por teclado, los tres niveles y los ciclos completos para ambos jugadores, robot propio/rival real, curación neutral/ofensiva, marcas por huésped/equipo, inmunidades, posesión, ADN, límites de población, terreno inválido, pausa y reinicio.

`tests/capture_reciclaje.gd` captura el HUD de los tres mapas y verifica una creación real por Reciclaje en cada uno. Las capturas y los logs de esta integración están en `work/reciclaje-nov05/`; el detalle final de resultados queda en su `VERIFICACION.md`.

Los requisitos 5/4/3 son un balance inicial para probar jugando, no un balance competitivo validado con jugadores.
