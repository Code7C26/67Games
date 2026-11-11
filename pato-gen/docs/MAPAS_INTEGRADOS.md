# Mapas integrados y legibilidad · 28/10/2026

Abrir `pato-gen/project.godot` con Godot 4.7.1 y ejecutar F5. El flujo es menú → cepas → mapa → partida. El selector ofrece Shopping, Laboratorio AV-07 y Pato Splash; conserva las cepas y recuerda el mapa. Reiniciar conserva el escenario y reinicia la economía y la población.

Los tres escenarios usan `Mapa.gd`, los dos `Pato.gd`, 65 `Bot.gd`, el HUD, las mutaciones, posesión, Simbionte, Coloso y resultados del juego principal. Los paquetes de entorno no cargan sus controladores, visitantes ni HUD de demostración. Splash conserva además sus 16 personajes de ambiente durante la preparación; al comenzar la infección evacúan una sola vez y no regresan durante esa partida. El aviso de evacuación explica que no son infectables. No suman población jugable, infectados ni ADN.

## Imagen

Cada NPC jugable recibe frames con margen transparente sin escalar el dibujo, outline exterior de 1 píxel, material propio y sombra de contacto al 38%. El sano usa contorno oscuro; el infectado conserva el color de equipo y un pulso de intensidad del 6%. Los frames se cachean y no se modifica el arte original. Las réplicas reciben las mismas reglas y la vestimenta del mapa.

Shopping incorpora CanvasModulate al 82%, piso menos saturado, grading tenue, sombra de pared de 3 píxeles y viñeta limitada a bordes. El laboratorio conserva su tratamiento de luces, normales y emisión. Los NPCs usan material sin iluminación y el HUD una capa propia. Se habilitó Mobile/Vulkan y HDR 2D para el glow del laboratorio. Filtro Nearest y escalado entero de ventana; la cámara conserva el encuadre automático para que el mapa completo entre entre las bandas del HUD, por lo que su zoom puede ser fraccionario.

## Circulación

Los entornos importados conservan sus colisiones. Una grilla derivada de la física, con radio de 19 px, limita las ubicaciones iniciales al componente transitable y deja separación entre actores. El mapa termina de preparar población y navegación antes de quitar la pantalla de carga.

`npc_brain.gd` mantiene las rutas al huir y perseguir: la evasión aleatoria anterior ya no cancela el recorrido al rozar una pared. La percepción llega a 240 px y exige un segmento libre de escenario; la persecución retiene una presa próxima hasta 420 px para evitar cambios continuos de objetivo. Los sanos eligen destinos transitables valorando distancia a amenazas, dirección inicial de escape y ocupación. Una huida mantiene su destino y sólo reconsidera uno amenazado después de 1,5 s. La distorsión sigue atrayendo sanos mediante rutas.

Actualización del 02/11/2026: Lab y Splash agrupan el piso transitable en sectores de 320×256 px. Sin amenazas, cada huésped elige un sector teniendo en cuenta sus seis sectores recientes, la ocupación y los destinos de otros bots. Al llegar camina dentro del sector durante 6–10 s antes de elegir otro. Esto permite que las salas pequeñas y la ampliación sur del laboratorio reciban visitas aunque tengan menos celdas de piso que el pasillo central.

Las rutas de paseo se conservan mientras sigan siendo transitables; se recalculan si un desvío deja el siguiente tramo detrás de una pared. Se omiten todos los puntos intermedios que el cuerpo puede alcanzar directamente. La separación local considera vecinos visibles o muy próximos y el paso lateral se reserva para encuentros de frente. Se siguen contando los cuerpos próximos al quedar contra una pared, aunque el margen conservador de navegación ya no permita una consulta de visibilidad. El movimiento favorece conservar el rumbo y mantiene un desvío seguro durante 0,35 s para evitar deshacerlo inmediatamente. Las consultas físicas comparan pasos de 12, 4 y 1,5 px; al recuperarse incluyen tangentes exactas para salir de huecos estrechos. Los intervalos de decisión se escalonan por el orden de los bots, sin depender de identificadores de objetos visuales.

Una ventana de progreso de 0,9 s detecta movimiento insuficiente; una llegada o un nuevo destino reinicia esa ventana. El bot busca espacio menos ocupado y mantiene una recuperación hasta 2,8 s. Si una colisión lo deja fuera del margen conservador de la grilla o en una celda aislada, busca una salida local en pasos de 8 px usando su cuerpo físico. Completa esa salida hasta una celda del componente jugable antes de volver a planificar; una ruta anterior no lo devuelve al mismo mueble. La búsqueda está acotada a 1.024 celdas y se comprueba de nuevo ante ocupación. No hay teletransportes ni cambios en capas de colisión o reglas de contagio. La posesión devuelve directamente la dirección del jugador. Las réplicas sólo aparecen si hay un segmento libre junto al huésped.

El HUD recibe los límites visuales del escenario. Simbionte y Coloso generan sus ubicaciones con las colisiones de cada mapa. Las escenas antiguas siguen conservando su encuadre original.

## Personajes de ambiente de Splash

Antes del contagio se conservan las rutinas que se detallan debajo. Al emitirse `fase_infeccion_iniciada`, `ambient_evacuation.gd` captura la posición actual de los 16 actores y detiene esas rutinas. Las representaciones de evacuación no tienen cuerpos físicos ni pertenecen al grupo `bots`: no bloquean a huéspedes, no reciben contagio y no generan ADN. El aviso dura 7,5 s y cada evacuado muestra `SALIDA`.

Los personajes dejan sillas y mostradores por sus tramos de salida; los visitantes de vestuarios emergen por la puerta y los pasajeros terminan el tobogán y salen del agua. Continúan por rutas hasta la entrada sur o los vestuarios, y se desvanecen en el umbral. Si excepcionalmente no existe ruta, se muestra `A RESGUARDO` antes de retirarlos. Se conserva la posición entre fases y la pausa del mapa. Reiniciar crea de nuevo la ambientación completa. Los científicos jugables del laboratorio siguen siendo huéspedes infectables.

- Toboganes: traspaso inmediato entre pasajero y nadador en la misma posición, salida por la escalera y regreso visible a la plataforma. Se eliminó el ocultamiento entre fases y al terminar la salida. El nadador conserva la apariencia del pasajero. El ciclo dura lo que requiere el recorrido, sin acelerar ni teletransportar al personaje para cumplir los antiguos 10 segundos.
- Helados: los dos clientes recorren el camino de ida y vuelta y esperan visibles; el helado se consume al final. Los puntos junto al mostrador se proyectan a piso transitable.
- Vestuarios: los dos visitantes sólo dejan de verse al entrar detrás de la puerta; su movimiento y el siguiente ciclo son continuos.
- Dos guardavidas, tres personas en reposeras, dos chicos, limpieza, fotógrafo y heladero: revisados los frames de rutina, las reacciones, la vuelta al puesto, las alertas y la pausa. Una ruta de huida ausente produce cobertura en el puesto; el regreso usa el recorrido de salida invertido.

Sin proveedor de navegación, el pasajero espera visible a la salida. No se reinicia desde la plataforma por teletransporte. El chapuzón permanece neutral respecto de infección.

## Pruebas reproducibles

Ejecutar con `godot --headless --path pato-gen --script res://tests/<archivo>.gd`:

- `test_maps.gd`: población, pieles, bordes, curación, navegación de 65 NPCs, réplica, fase real, Simbionte, Coloso y resultados en los tres mapas.
- `test_map_flow.gd`: selección, carga completa, reinicio y vuelta al menú en los tres escenarios.
- `test_park_life.gd`: los 16 personajes, 120 segundos de rutinas y 120 segundos de reacciones; continuidad, rutas de regreso y pausa.
- `test_npc_navigation.gd`: tres semillas por mapa, 65 huéspedes y 60 segundos de presión sostenida de infección por simulación. Comprueba movilidad individual, períodos de bloqueo, persecución, huida, límites, las 16 rutas de evacuación, continuidad por cuadro y pausa. Acepta argumentos de usuario `Laboratorio 128 crowd` o `PatoSplash 128 crowd` para reproducir grupos densos con 60 infectados y 5 sanos protegidos.
- `test_npc_roaming.gd`: 90 s de movimiento con 65 huéspedes sanos o todos infectados, sin presas. Mide ocupación del pasillo central, salas del sur, sectores visitados, bloqueos y cambios bruscos de rumbo. Ejemplo: `-- Laboratorio 128 infected 90 current`. Guarda métricas en `../work/bot-ai/`.
- `test_npc_steering.gd`: once posiciones de atasco tomadas de simulaciones reales, recuperación física continua, vuelta al piso transitable, posesión y pausa.
- `capture_npc_navigation.gd`: capturas a los 2, 6 y 40 segundos del inicio del contagio. Acepta el mapa como argumento de usuario.
- Suites existentes: menú, HUD, regresiones de partida, tutorial, Simbionte y Coloso.

Las capturas se generan con `capture_maps.gd` y `capture_park_cycles.gd` en `../map-captures/`, fuera de los recursos del juego. Las pruebas aún pueden emitir avisos de recursos retenidos al cerrar Godot; también aparecen en la versión base. No deben confundirse con errores de script o aserciones fallidas.

## Fuentes y limpieza

Se incorporaron los paquetes editables proporcionados por el proyecto: el AV-07 revisado y la versión local vigente de Pato Splash. Se conservaron fuentes Aseprite y paletas. No se compraron ni añadieron packs externos. Los ZIP y proyectos históricos del repositorio se mantienen como entregas independientes.

Se retiraron resultados y perfiles temporales de pruebas, capturas generadas, un guardado `.tmp` del editor y el shader de borde interior reemplazado. Las pruebas regeneran sus salidas y `.gitignore` evita volver a versionarlas. El respaldo y su manifiesto se guardan fuera del repositorio.
