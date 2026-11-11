# Parásito Alfa

Implementado el 2 de noviembre de 2026 y probado con Godot 4.7.1.

## Comportamiento

- Disponible en Shopping, Laboratorio y Pato Splash. Cada partida realiza una única tirada del 50% a los 35 segundos de la fase de infección. Una tirada fallida descarta el evento hasta la próxima partida.
- El organismo permanece fijo y no bloquea el paso. Usa la criatura de 64 × 64 píxeles aprobada por el usuario, creada con el MCP de Aseprite: cabeza dentada, ojos verdes, ojo grande en el hombro y raíces. No pertenece al grupo de bots ni participa en posesión, combate o puntuación.
- Su aparición exige una posición interior segura y tres lugares libres cercanos. Prioriza el centro exacto si está conectado al interior y es válido; si contiene una piscina, fuente, mobiliario u ocupación, examina el suelo interior más próximo al centro. Reserva un radio de 34 píxeles para el cuerpo. Utiliza los candidatos de navegación del Simbionte sin modificar esa navegación. Comprueba cuerpos, obstáculos, límites, capullos, pasajes y organismos especiales.
- Crea tres bots nuevos y luego uno cada diez segundos durante sesenta segundos. En condiciones normales, el nacimiento del segundo 60 ocurre antes de retirarse: nueve entidades adicionales.
- Si falta espacio, reintenta una vez por segundo. No crea una tanda inicial incompleta. No acumula nacimientos pendientes ni compensa cuadros lentos con ráfagas; en esos casos puede producir menos de nueve bots.
- Respeta pausa general, pausa del reloj durante el tutorial, fin de partida y retirada externa del organismo.
- Al terminar, desaparece el organismo; los huéspedes pertenecen al mapa, sobreviven y siguen contagiando con la IA normal. Reiniciar recarga la población original y el estado del evento.

## Equipos, población y economía

La afiliación usa `player_duenio`: 0 sano/sin dueño, 1 cian, 2 magenta y 3 Alfa. `cepa` sigue siendo la clase de mutaciones; el perfil interno `alfa` usa estadísticas base, sin mutaciones de jugador. Reutiliza las animaciones infectadas existentes mediante cuatro hojas propias recoloreadas en Aseprite a tres tonos casi negros. El shader existente mantiene el borde verde luminoso independiente del cuerpo. Al curarse recupera su apariencia sana, incluida la del mapa correspondiente.

Las tres infecciones solo contagian a sanos. Los verdes respetan las protecciones de curación, pueden curarse naturalmente o por las mecánicas existentes y no pueden ser poseídos. Nacimientos y contagios neutrales no dan ADN ni progreso de adaptación a jugadores.

La población se cuenta como `total = sanos + blue + magenta + verdes`. El Alfa no cuenta. Su fábrica de bots no usa el límite de 100 ni las cuotas de réplica; no hay un límite adicional para este evento. La replicación de los jugadores conserva su límite global de 100 y sus ocho generaciones por equipo. Si la población extra alcanza 100, los jugadores dejan de replicar mientras el total siga en ese límite o por encima.

La victoria conserva el reloj y la comparación cian/magenta. Un bot de origen Alfa, una vez curado e infectado por un jugador, cuenta normalmente para ese jugador. Se conserva la supresión de recompensa de la primera reinfección después de una curación del Coloso.

El Coloso conserva sus umbrales referidos a la población inicial (7 sanos para crisis y 17 para recuperación con 65 iniciales), tiempos y probabilidades. Se adaptó exclusivamente su elegibilidad de objetivos: protege el último cian y magenta, pero puede curar el último verde.

## Configuración

Seleccionar `EventoParasitoAlfa` en cualquiera de las tres escenas y editar en el Inspector:

| Propiedad | Valor inicial |
| --- | --- |
| habilitado | true |
| probabilidad | 0.5 |
| segundo_aparicion | 35.0 |
| duracion | 60.0 |
| intervalo_generacion | 10.0 |
| cantidad_inicial | 3 |
| radio_aparicion | 34.0 |

Para comprobarlo manualmente en cada partida, usar temporalmente probabilidad 1.0. Los archivos de producción conservan 0.5.

## Archivos

Nuevos: `scripts/equipos_infeccion.gd`, `scripts/evento_parasito_alfa.gd`, `scripts/parasito_alfa.gd` y `scenes/parasito_alfa.tscn`.

Adaptaciones pequeñas en `Mapa.gd`, `Bot.gd`, `Pato.gd` y `curacion_radial.gd`. Cada mapa agrega la referencia al controlador y un nodo. No se cambió la geometría, el HUD ni las reglas de victoria. No se agregó un selector general de eventos ni un Recolector.

## Validación

607 comprobaciones aprobadas, sin fallos de aserción ni errores de script en las ejecuciones finales:

| Prueba | Comprobaciones |
| --- | ---: |
| test_parasito_alfa | 64 |
| test_alfa_mapas | 36 |
| test_coloso_antiviral | 72 |
| test_coloso_integracion | 37 |
| test_coloso_partida | 12 |
| test_simbionte | 94 |
| test_simbionte_balance | 23 |
| test_simbionte_possession | 52 |
| test_maps | 61 |
| test_match_regressions | 23 |
| test_match_ui | 112 |
| test_map_flow | 21 |

Las pruebas nuevas cubren 100 → 103 → 104, nueve nacimientos, las nueve combinaciones entre infectados, ADN, posesión normal y directa, curación, protección temporal, último verde, aparición bloqueada, reintentos, cuadros lentos, retirada externa, fin y reinicio real. En los tres mapas se revisan las huellas físicas de nacimiento y el movimiento autónomo.

Las dos partidas automáticas completas de 120 segundos fuerzan el Alfa solo en la prueba. Alcanzaron 74 y 90 bots, respectivamente; mantuvieron contabilidad exacta y cierre normal, con intervenciones del Coloso y reproducción de jugadores.

Persisten avisos de ObjectDB/recursos al cerrar algunas pruebas, de la misma clase ya documentada en las pruebas previas del proyecto. No se consideran corregidos por este cambio. Las simulaciones no sustituyen partidas humanas para validar balance competitivo.

Desde la carpeta que contiene `pato-gen`:

```powershell
& ./work/parasito-alfa/run_checks.ps1 test_parasito_alfa test_alfa_mapas
& ./work/parasito-alfa/run_checks.ps1 test_coloso_antiviral test_coloso_integracion test_coloso_partida test_simbionte test_simbionte_balance test_simbionte_possession test_maps test_match_regressions test_match_ui test_map_flow
& ./work/parasito-alfa/run_checks.ps1 capture_alfa benchmark_alfa
```

Copias anteriores a los cambios: `work/parasito-alfa/before`. Logs finales y perfiles aislados: `work/parasito-alfa/logs` y `runtime`. Capturas: `work/parasito-alfa/capturas`.

El benchmark compara 65, 74, 90, 100, 150 y 200 bots en cada mapa. Mide los callbacks de física de los nodos entre dos sondas de prioridad extrema, con calentamiento y 180 muestras por escenario. No mide GPU, FPS visibles ni el trabajo del motor fuera de esos callbacks. Sus resultados se guardan en `work/parasito-alfa/benchmark.json`; no introduce límites automáticos de población.

## Criatura aprobada, animación y centro

La versión integrada usa `assets/alfa/criatura_alfa.png`, una hoja de ocho fotogramas de 64 × 64, exportada desde `work/alfa-criatura-integracion/parasito_alfa_juego.aseprite`. El original aprobado permanece en `work/alfa-criatura-v02`. La hoja de producción conserva el diseño y elimina la silueta de huésped que se usó para demostrar la acción en el GIF: los huéspedes visibles en el juego son los bots reales.

El torso se contrae durante los 340 ms anteriores al nacimiento periódico y se abre en el mismo tick que lo crea. Luego reproduce las poses de recuperación y vuelve a reposo. Las raíces permanecen fijas. Los tres huéspedes iniciales nacen inmediatamente con la criatura en la pose de liberación. El controlador avanza tanto reloj como animación, de modo que también se congelan al pausar el tutorial. Se conserva la retirada a los 60 segundos después del último nacimiento, sin ampliar la duración para terminar su animación.

El reposo ahora incluye respiración, balanceo del torso/cabeza y un pulso tenue en las venas, mediante `shaders/alfa_reposo.gdshader`. El movimiento afecta solo a la parte superior; las filas 49–63 del arte conservan sus raíces. Su reloj proviene de `parasito_alfa.avanzar()`, y no de un reloj independiente del renderizador. La opción de movimiento reducido desactiva esta deformación y el pulso radial, conservando las poses de la apertura. Los cuadros originales y la cadencia de generación se mantienen.

La selección central ordena una sola vez los puntos interiores y revalida los más próximos antes de materializar la criatura. Las búsquedas siguen acotadas y no mueven obstáculos o huéspedes existentes.

Validación de esta integración: **258 comprobaciones aprobadas** (19 de animación y sincronía, 64 del Alfa, 42 sobre el Alfa en los tres mapas, 12 de partidas completas con Coloso, 37 de integración del Coloso, 61 de mapas y 23 de regresiones). Se verifican pausa, restauración del reposo, raíces, ausencia de duplicados, población superior a 100, finalización y reinicio. Persisten los avisos de recursos al salir documentados previamente.

Las copias anteriores al cambio, logs y capturas de reposo/liberación están en `work/alfa-criatura-integracion`. Para repetir:

```powershell
& ./work/alfa-criatura-integracion/run_checks.ps1 test_alfa_animacion test_parasito_alfa test_alfa_mapas test_coloso_partida test_coloso_integracion test_maps test_match_regressions
$env:ALFA_CAPTURE_MAP = 'Shopping' # También Laboratorio o PatoSplash
& ./work/alfa-criatura-integracion/run_checks.ps1 capture_alfa_integrado
Remove-Item Env:ALFA_CAPTURE_MAP
```

Resultados de esta máquina, percentil 95 del tiempo medido en milisegundos:

| Mapa | 65 bots | 74 bots | 90 bots | 100 bots | 150 bots | 200 bots |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Shopping | 3.10 | 4.25 | 7.04 | 7.95 | 11.71 | 14.89 |
| Laboratorio | 13.96 | 19.49 | 20.40 | 22.52 | 45.38 | 72.28 |
| Pato Splash | 15.96 | 20.29 | 17.89 | 33.09 | 38.62 | 73.95 |

Es una prueba de estrés secuencial con posiciones e infecciones cambiantes; no aísla exclusivamente el costo de añadir nueve bots. Los escenarios de 150–200 muestran un costo alto en la navegación existente de Laboratorio y Pato Splash. No se garantiza una tasa de cuadros concreta ni se añadió un corte automático. Conviene perfilar esa IA antes de aumentar sustancialmente la duración o frecuencia del evento.

Las capturas finales se inspeccionaron visualmente. Pato Splash se capturó también en un proceso independiente para evitar texto del HUD incompleto al encadenar escenas en la herramienta de capturas; no requirió cambios en el HUD de producción. Para repetir una captura aislada:

```powershell
$env:ALFA_CAPTURE_MAP = 'PatoSplash'
& ./work/parasito-alfa/run_checks.ps1 capture_alfa
Remove-Item Env:ALFA_CAPTURE_MAP
```
