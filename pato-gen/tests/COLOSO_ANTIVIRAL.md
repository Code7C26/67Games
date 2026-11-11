# Coloso Antiviral — implementación inicial

Implementado el 27/10/2026 para Godot 4.7.1. Es una intervención ambiental neutral, sin vida, daño, recompensas por derrotarlo ni posesión. Usa el sprite aprobado de 32 × 32 en `assets/coloso/coloso_antiviral.png`. Desde el 04/11/2026 se muestra a escala 1,75 con filtro nearest, separando cuerpo y piernas mediante regiones de esa misma textura para animar marcha y respiración. La preferencia de movimiento reducido suaviza la marcha y elimina respiración y onda expansiva. Se conservan la colisión de radio 20 y los límites de aparición y curación. El original editable está en `work/coloso-sprite/coloso_32_v01.aseprite`, fuera del proyecto.

## Reglas actuales

- Sólo se habilita en Shopping, mediante `EventoColosoAntiviral`. Las escenas históricas no incorporan el evento.
- La referencia es la población inicial de la escena: 65 bots. Las réplicas posteriores no elevan ese denominador; las réplicas curadas sí cuentan como sanos.
- Crisis: 12% o menos de esa referencia, redondeado hacia abajo. En Shopping son **7 sanos o menos**.
- Se conservan 30 segundos iniciales de infección sin evento. Todos los tiempos nuevos respetan pausa general y `TimerJuego.paused` durante el tutorial.
- Tras **5 segundos continuos de crisis**, se realiza la primera tirada: **60%**.
- Si falla y la crisis continúa, se vuelve a intentar cada **20 segundos**, sin aumentar ni reducir la probabilidad.
- Recuperarse por encima del umbral cancela esa crisis y su espera de intento fallido. Una crisis nueva requiere nuevamente 5 segundos.
- Una tirada exitosa inicia un aviso de **3 segundos** en una posición segura. Se vuelve a comprobar población y ocupación antes de materializar la entidad. Si se recupera la población o se ocupa el lugar, se cancela; no consume aparición ni reduce el 60%. Un aviso cancelado deja 20 segundos de descanso para evitar avisos repetidos.
- Sólo una **aparición efectiva** cambia las futuras tiradas a **40%**. Se mantiene ese porcentaje; no disminuye a 20%.
- No hay tiradas mientras existe un Coloso. Después de retirarse hay 20 segundos de descanso, además de exigir crisis. Máximo **dos apariciones** por partida.
- No se inician nuevas tiradas cuando quedan **25 segundos o menos**. El aviso se cancela si ya no queda tiempo para una intervención de 20 segundos.

## Intervención

- Movimiento autónomo a 82 unidades/s, cuerpo de radio 20, con aceleración y frenado. Suaviza esquinas saltando hasta 12 celdas únicamente cuando un barrido de la huella completa confirma el tramo libre. Selecciona concentraciones de infectados en destinos accesibles y conserva el destino anterior como candidato para evitar cambios innecesarios; no prioriza colores. No bloquea bots ni usa sus pasajes.
- Radio curativo de 170 unidades. Un intento por segundo, 95% de probabilidad, máximo un objetivo por pulso. La carga alrededor de los pies anticipa el intento; cada cura exitosa dibuja un rayo hasta el receptor, un círculo y el texto «SANO» durante 0,9 segundos.
- Las paredes bloquean la curación del Coloso. El RRobot y el Simbionte conservan su curación radial por distancia, incluso a través de paredes.
- Se reutiliza `curar_por_robot()` y `curar(false)`: no activa Último aliento; ignora escudos ordinarios y respeta la resistencia del Simbionte. Curar al portador termina su fusión mediante la limpieza existente.
- Nunca selecciona la última infección de un equipo. Esta protección no cambia las otras fuentes de curación del juego.
- Un bot tratado queda protegido de reinfección durante 6 segundos, con un aro verde. La siguiente infección efectiva no da ADN ni incrementa contagios acumulados, independientemente del equipo. Esa infección sí cuenta en la población y recibe las mutaciones correspondientes. Después vuelve a las reglas económicas normales.
- No trata dos veces a la misma entidad durante una intervención. No crea ni elimina bots, no devuelve cuotas de réplica y no copia poderes.
- Termina al cumplirse cualquiera de estas condiciones: **20 segundos**, **12 curaciones exitosas**, **17 o más sanos durante 3 segundos**, ausencia de objetivos elegibles durante 3 segundos, retirada de la entidad o fin de partida. La detección de falta de objetivos se actualiza con la búsqueda de ruta cada segundo.
- La recuperación puede ser parcial: no se extiende el plazo ni se aumenta el presupuesto para alcanzar los 17 sanos.
- El resultado final sigue dependiendo de los infectados al terminar `TimerJuego`. Reiniciar borra apariciones, efectos, marcas y contadores nuevos.

## Integración y alcance

Archivos existentes modificados: `scripts/Mapa.gd`, `scripts/Bot.gd`, `scripts/curacion_radial.gd`, `scripts/navegacion_simbionte.gd` y `scenes/Shopping.tscn`.

La escena Shopping sólo suma una referencia de script y el nodo controlador (4 líneas). No cambia la geometría, posiciones, cámara ni HUD. El navegador conserva radio 8 para el Simbionte y utiliza otra instancia con radio 20 para el Coloso. Los candidatos se obtienen del componente interior conectado y se comprueban contra cuerpos, mobiliario, capullos y pasajes.

Nuevos scripts de producción: `scripts/evento_coloso_antiviral.gd` y `scripts/coloso_antiviral.gd`; nueva escena: `scenes/coloso_antiviral.tscn`. Los valores se ajustan en el Inspector de `Shopping/EventoColosoAntiviral`.

Se corrigió además la concesión de bonificaciones de contagio cuando el objetivo protegido rechazaba la infección: ahora se comprueba que realmente quedó infectado por el atacante.

## Pruebas y reproducción

El lanzador `work/coloso-antiviral/run_checks.ps1`, fuera del proyecto, guarda logs y usa perfiles de ejecución aislados. Detecta errores de script aunque Godot devuelva código 0. Desde la carpeta que contiene Pato-gen:

```powershell
& .\work\coloso-antiviral\run_checks.ps1 test_coloso_antiviral test_coloso_integracion test_coloso_partida
& .\work\coloso-antiviral\run_checks.ps1 test_simbionte test_simbionte_balance test_simbionte_possession test_simbionte_sprite test_match_regressions test_match_ui test_onboarding test_menu
& .\work\coloso-antiviral\run_checks.ps1 capture_coloso
```

- `test_coloso_antiviral.gd`: límites temporales y probabilidades con semillas controladas, pausas, aviso cancelado, concurrencia, reapariciones, conteo, economía, posesión, resistencias, paredes, réplicas y fallos de colocación.
- `test_coloso_integracion.gd`: 48 posiciones sobre las colisiones reales, rutas con el cuerpo grande, movimiento físico, curación efectiva, presupuesto, calor, fin y botón real de reinicio.
- `test_coloso_partida.gd`: dos partidas automáticas completas de 120 segundos, aceleradas 6×, con crisis inicial preparada sólo en el test. Incluyen cepas Atlético/Área con Simbionte y Exponencial/Exponencial con reproducción, además de RRobot y calor. Comprueban contabilidad, concurrencia y finalización; no constituyen validación competitiva.
- `capture_coloso.gd`: renderiza aviso, intervención, pulso y detalle. Las capturas están en `work/coloso-antiviral/capturas`.

Las pruebas originales de HUD y menú se ejecutan con renderizado. Se mantienen los avisos de recursos/ObjectDB al cierre que ya estaban documentados en `SIMBIONTE.md`; el test del tutorial provoca deliberadamente un error de lectura de su perfil corrupto. No se cambió AudioManager ni se ocultaron esos diagnósticos.

Resultado de la implementación inicial: **530 comprobaciones aprobadas**, sin fallos de aserción ni errores de script en las ejecuciones finales: 72 reglas del Coloso, 37 integración, 10 comprobaciones sobre las dos partidas automáticas, 94 Simbionte, 23 posiciones/balance, 52 posesión, 34 sprites, 23 regresiones, 112 HUD, 50 tutorial y 23 menú. Las cuatro capturas finales se guardaron correctamente; se revisaron visualmente la intervención en el mapa y el detalle del Coloso.

Integración del sprite, 29/10/2026: se repitieron las 72 comprobaciones de reglas y las 37 de integración (**109 aprobadas, 0 fallos**) y se regeneraron las cuatro capturas. Se revisaron la intervención dentro de Shopping y el detalle renderizado con la nueva textura. Persisten los avisos de recursos/ObjectDB al salir. No se repitió el resto de la batería inicial para este cambio visual.

Mejora de lectura, 04/11/2026: **137 comprobaciones aprobadas, 0 fallos**: 72 reglas, 37 integración, 16 lectura y 12 sobre dos partidas automáticas. `test_coloso_lectura.gd` verifica alcance a 160 unidades, protección y su vencimiento, receptor del efecto visual, articulación, pausa y movimiento reducido. `capture_coloso_lectura.gd` guarda dos pasos de marcha y una curación en `work/jugabilidad-nov04/coloso`; se revisaron las imágenes renderizadas con conversión de HDR lineal a sRGB. Persisten avisos de recursos/ObjectDB al cerrar algunas pruebas. Las pruebas automáticas no validan balance competitivo humano.

## Balance pendiente

Hace falta jugar partidas humanas para ajustar frecuencia, fuerza y oportunidad. En las dos simulaciones iniciales se alcanzaron cero sanos; hubo dos apariciones en Atlético/Área y una en Exponencial/Exponencial, que llegó a 81 bots. Una tirada exitosa puede cancelarse durante el aviso y conservar el 60%, tal como ocurrió en esa segunda simulación.

La neutralidad no garantiza pérdidas idénticas para ambos equipos: la distribución espacial importa. Debe observarse especialmente la combinación con las ayudas de remontada y la pérdida de una fusión de Simbionte. No se declaró el balance competitivo como validado.

Los originales anteriores al cambio están en `work/coloso-antiviral/before`.
