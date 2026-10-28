# Mapas integrados y legibilidad · 28/10/2026

Abrir `pato-gen/project.godot` con Godot 4.7.1 y ejecutar F5. El flujo es menú → cepas → mapa → partida. El selector ofrece Shopping, Laboratorio AV-07 y Pato Splash; conserva las cepas y recuerda el mapa. Reiniciar conserva el escenario y reinicia la economía y la población.

Los tres escenarios usan `Mapa.gd`, los dos `Pato.gd`, 65 `Bot.gd`, el HUD, las mutaciones, posesión, Simbionte, Coloso y resultados del juego principal. Los paquetes de entorno no cargan sus controladores, visitantes ni HUD de demostración. Splash conserva además sus 16 personajes de ambiente; observan la infección real pero no suman infectados ni ADN.

## Imagen

Cada NPC jugable recibe frames con margen transparente sin escalar el dibujo, outline exterior de 1 píxel, material propio y sombra de contacto al 38%. El sano usa contorno oscuro; el infectado conserva el color de equipo y un pulso de intensidad del 6%. Los frames se cachean y no se modifica el arte original. Las réplicas reciben las mismas reglas y la vestimenta del mapa.

Shopping incorpora CanvasModulate al 82%, piso menos saturado, grading tenue, sombra de pared de 3 píxeles y viñeta limitada a bordes. El laboratorio conserva su tratamiento de luces, normales y emisión. Los NPCs usan material sin iluminación y el HUD una capa propia. Se habilitó Mobile/Vulkan y HDR 2D para el glow del laboratorio. Filtro Nearest y escalado entero de ventana; la cámara conserva el encuadre automático para que el mapa completo entre entre las bandas del HUD, por lo que su zoom puede ser fraccionario.

## Circulación

Los entornos importados conservan sus colisiones. Una grilla derivada de la física, con radio de 19 px, limita las ubicaciones iniciales al componente transitable y deja separación entre actores. El mapa termina de preparar población y navegación antes de quitar la pantalla de carga. Los NPCs se apartan al encontrarse de frente sin perder sus colisiones. La posesión conserva los controles del juego. Las réplicas sólo aparecen si hay un segmento libre junto al huésped.

El HUD recibe los límites visuales del escenario. Simbionte y Coloso generan sus ubicaciones con las colisiones de cada mapa. Las escenas antiguas siguen conservando su encuadre original.

## Revisión de los 16 personajes de ambiente de Splash

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
- Suites existentes: menú, HUD, regresiones de partida, tutorial, Simbionte y Coloso.

Las capturas se generan con `capture_maps.gd` y `capture_park_cycles.gd` en `../map-captures/`, fuera de los recursos del juego. Las pruebas aún pueden emitir avisos de recursos retenidos al cerrar Godot; también aparecen en la versión base. No deben confundirse con errores de script o aserciones fallidas.

## Fuentes y limpieza

Se incorporaron los paquetes editables proporcionados por el proyecto: el AV-07 revisado y la versión local vigente de Pato Splash. Se conservaron fuentes Aseprite y paletas. No se compraron ni añadieron packs externos. Los ZIP y proyectos históricos del repositorio se mantienen como entregas independientes.

Se retiraron resultados y perfiles temporales de pruebas, capturas generadas, un guardado `.tmp` del editor y el shader de borde interior reemplazado. Las pruebas regeneran sus salidas y `.gitignore` evita volver a versionarlas. El respaldo y su manifiesto se guardan fuera del repositorio.
