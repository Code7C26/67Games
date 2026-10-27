# Simbionte — controles, integración y verificación

Implementado para Godot 4.7.1. La escena de partida es `Shopping.tscn`.

## Cómo jugar

- **Q (cian) / U (magenta):** invertir 5 ADN desde cualquier posición, también durante la posesión.
- Después de la fusión, **Q / U** poseen directamente al portador aliado desde cualquier distancia. Durante el viaje o tras expirar/curarse la fusión no seleccionan otro bot ni cobran ADN.
- La posesión directa usa los 10 s y la recarga de 20 s existentes. Si ya se controla otro bot, transfiere el control conservando el tiempo y la recarga restantes. Repetir la tecla no reinicia ninguno de los relojes. **X / J** mantienen la selección normal del infectado más cercano.
- Cada pulsación aceptada tiene 1,5 segundos de recarga individual. Mantener la tecla no compra repetidamente.
- Se necesitan 12 pagos: 60 ADN. No hay devolución; el rival conserva únicamente su saldo no gastado.
- La primera solicitud válida que completa los 60 gana. No hay segundo Simbionte en esa partida.
- El viajero busca al infectado aliado más cercano, camina hasta él y se fusiona por contacto. Si deja de ser válido, busca otro. Si no hay aliados, espera.
- Los **20 segundos** comienzan al tocar al bot. Poseerlo con **X / J** no altera ese plazo.
- El aura cura solamente infectados rivales. No los convierte al equipo del anfitrión.
- Si curan al anfitrión, la fusión termina. Tampoco se transmite por réplica o reinfección.
- El reinicio borra inversiones, recargas, ganador, viajero y efecto. No se conserva nada en un autoload.

## Valores iniciales de balance

Estos valores son una primera configuración para jugar, no un balance validado competitivamente. Se ajustan en el Inspector del nodo raíz Shopping, grupo **Simbionte**:

| Propiedad | Valor inicial |
| --- | --- |
| `velocidad_simbionte` | 100 px/s durante el viaje |
| `velocidad_fusion` | 1,35 × la velocidad calculada del bot |
| `curacion_fusion` | 0,50 × la probabilidad de curación |
| `radio_aura_simbionte` | 140 px |
| `chance_aura_simbionte` | 0,50 por intento y rival en radio |
| `intervalo_aura_simbionte` | 0,75 segundos |

La resistencia se aplica a la curación natural, ofensiva y del robot. Las defensas actuales mantienen sus reglas: el robot sigue ignorando escudo/caparazón/inmortalidad y no activa Último Aliento; la resistencia del Simbionte sí reduce su probabilidad.

El radio del aura sigue el criterio del robot: distancia, sin bloqueo por paredes. La **fusión** sí verifica obstáculos y superposición física.

## Organización

- `Mapa.gd`: única autoridad del gasto de ADN y la carrera. Las compras existentes usan `gastar_adn()` sin cambiar sus costos. Las escenas históricas que no contienen los dos capullos siguen funcionando sin activar esta mecánica.
- `Bot.gd`: conserva infección, curación, estadísticas y posesión. Aplica un componente temporal sin sobrescribir valores base, mutaciones ni factores de calor.
- `curacion_radial.gd`: filtro compartido por el RRobot y el aura; delega la curación en el bot. El robot conserva el filtro de ambos equipos.
- `efecto_simbionte.gd`: duración, bonificaciones y aura; hijo del bot, con limpieza al curarse, expirar, salir de escena o terminar la partida.
- `simbionte.gd`: viajero independiente del grupo `bots`, para no alterar población, contagios o ADN.
- `navegacion_simbionte.gd`: cuadrícula A* de 16 px construida por partes desde las colisiones reales. Reserva espacio para el cuerpo; suaviza segmentos solo cuando caben físicamente. Excluye actores móviles del cálculo de paredes.
- `capullo.gd`: dibujo, progreso y ayuda de tecla en el mundo. No posee una segunda copia de la economía.

No se cambian el HUD, la cámara, la geometría, la decoración ni los pasajes existentes. Cada partida sortea dos posiciones de capullo separadas al menos 400 px, con una huella libre de 32 px de radio. Solo se admiten celdas conectadas con el interior del shopping; el espacio libre exterior no cuenta. Los capullos se muestran cuando termina la cuadrícula de colisiones, y hasta entonces no se acepta gasto de ADN. Si una escena modificada no tiene dos posiciones válidas, la inversión queda bloqueada con un aviso, sin cobrar. El sorteo usa su propio generador aleatorio.

El viajero rodea obstáculos; no utiliza los pasajes reservados a bots. Si su objetivo usa uno, recalcula el camino. Si no encuentra ruta hasta un objetivo todavía válido, espera y reintenta; no se teletransporta ni fusiona a distancia.

El reloj y las inversiones respetan la pausa general y el reloj retenido por el tutorial. La visualización incluye progreso sobre el capullo y segundos restantes sobre el anfitrión.

## Pruebas

La suite `test_simbionte.gd` usa fondos y escenarios controlados **solo dentro del test**. Comprueba:

- Rechazo por fase, pausa, jugador inválido, saldo y cooldown; Q/U y repetición de teclado.
- Doce pagos, simultaneidad del último pago, ambos ganadores, destrucción rival y ausencia de ADN adicional.
- Selección del aliado más cercano, objetivo curado, convertido o eliminado, espera sin aliados y contacto bloqueado por paredes.
- Caminata real, rutas por locales y cruce del shopping mediante física.
- Duración real de 20 segundos, posesión, mejoras durante la fusión, calor y retirada del efecto.
- Filtro del aura, curación del robot, resistencia y recompensas normales de reinfección.
- Réplicas sin copia de poderes ni recursos adicionales.
- Fin de partida y botón real de reinicio.

`test_simbionte_balance.gd` reutiliza esos escenarios y comprueba 128 posiciones sorteadas contra las colisiones y rutas reales, separación, variación, eclosión y caminata desde la posición aleatoria, recarga y alcance del aura, ausencia de ADN adicional y salida de escena mientras se genera la cuadrícula.

`test_simbionte_possession.gd` verifica Q/U para ambos equipos: pagos, espera durante el viaje, selección directa del portador distante, transferencia de posesión sin extender tiempos, recarga normal, filtros de equipo/fase/pausa, curación, expiración y eliminación del anfitrión.

Ejecutar con el binario de consola de Godot:

```text
godot --headless --path Pato-gen --audio-driver Dummy --max-fps 60 --script res://tests/test_simbionte.gd -- --onboarding-test
```

Las suites existentes `test_match_regressions.gd` y `test_onboarding.gd` se ejecutan de la misma forma. **`test_match_ui.gd` y `test_menu.gd` se verifican con renderizado**, sin `--headless`: validan clics, ventanas y transiciones de interfaz.

`capture_simbionte.gd` genera capturas de preparación, inversión, eclosión, fusión y posesión con el renderizador real. No agrega recursos ni atajos de depuración al juego normal.

En `work/simbionte/`, fuera del proyecto, se guardan los originales modificados, el lanzador local de pruebas y los logs. El lanzador aísla los datos de Godot del perfil real del usuario.

Resultados del 23/10/2026: **301 comprobaciones aprobadas** (93 Simbionte, 23 regresiones, 112 HUD, 50 tutorial y 23 menú). Capturas revisadas con el renderizador OpenGL real.

Ajuste del 26/10/2026: **224 comprobaciones aprobadas** (94 Simbionte, 23 posiciones y balance, 34 sprites, 23 regresiones y 50 tutorial). Se revisaron capturas reales de las posiciones aleatorias y del aura ampliada; la escena Shopping y los recursos de animación conservan sus hashes anteriores. La recarga pasa de 3 a 1,5 s, el viaje de 150 a 100 px/s y el aura de 90 px / 20% / 1 s a 140 px / 40% / 0,75 s. Se tolera el residuo de precisión decimal en el límite del pulso. Los originales de este ajuste, logs y capturas están en `work/simbionte-balance-oct26/`.

Ajuste posterior de posesión directa: aura al **50% por pulso**, con radio de 140 px e intervalo de 0,75 s. Q/U reutilizan el ciclo de posesión existente para seleccionar el portador fusionado y transferir el control sin aumentar los tiempos. **226 comprobaciones aprobadas** (52 posesión directa, 94 Simbionte, 23 posiciones y balance, 34 sprites y 23 regresiones). Originales y logs en `work/simbionte-direct-possession/`. Persisten los avisos de recursos de audio al cierre ya documentados en algunas suites.

Diagnósticos separados de la mecánica:

- Algunas ejecuciones avisan de recursos de audio pendientes al cerrar. Se reprodujeron los mismos avisos y tipos de recursos ejecutando las regresiones sobre una copia de los archivos anteriores al Simbionte; no se modificó AudioManager para este trabajo.
- La prueba del tutorial escribe a propósito un perfil corrupto y verifica su recuperación; el mensaje de ConfigFile correspondiente es esperado.
- La prueba de clic del HUD falló en modo headless y pasó sus 112 comprobaciones con renderizado. Una repetición headless del menú agotó la espera de carga; la ejecución con renderizado pasó las 23 comprobaciones. No se alteraron esas pruebas para omitir aserciones.

Queda para la prueba humana ajustar fuerza y oportunidad del Simbionte en partidas de 120 segundos, especialmente el ciclo aura → humano sano → reinfección y su interacción con la remontada.
