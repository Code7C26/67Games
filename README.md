# Patogen

> Videojuego 2D competitivo de infección y estrategia para **dos jugadores locales**, desarrollado por **67Games** en Godot. Las cepas **cian** y **magenta** compiten por expandirse entre una población de bots, administrar ADN y evolucionar sus infectados.

![Estado](https://img.shields.io/badge/Estado-Prototipo%20jugable-orange)
![Motor](https://img.shields.io/badge/Godot-4.7.1-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/Lenguaje-GDScript-478CBF)

Estado revisado contra los archivos del repositorio el **27/10/2026**. El juego principal incluye mutaciones por cepa, distorsión, remontada, audio, tutorial, Simbionte y Coloso Antiviral. El balance competitivo y la integración de los mapas adicionales siguen pendientes.

## Ejecutar el juego

1. Instalar **Godot 4.7.1**, versión indicada por las pruebas del proyecto.
2. Clonar el repositorio:

   ```bash
   git clone https://github.com/Code7C26/67Games.git
   ```

3. En Godot, seleccionar **Importar** y abrir **[`pato-gen/project.godot`](pato-gen/project.godot)**.
4. Esperar la importación de recursos y pulsar **F5**.

El juego inicia en el menú principal, usa **GL Compatibility** y un lienzo de **1920 × 1080**. F6 ejecuta sólo la escena abierta en el editor.

El menú permite jugar, iniciar una partida con tutorial, consultar la guía y activar **movimiento reducido**. El tutorial guarda el progreso del perfil y también puede consultarse con **F1** durante la partida.

## Cómo se juega

1. Cada jugador elige una cepa en la prepartida: **Atlético**, **Área** o **Exponencial**.
2. En Shopping, la fase inicial de los patos está configurada en **3 segundos**. Al terminar, cada pato reproduce su desaparición, inicia el contagio y pasa al modo fantasma.
3. Cuando termina esa transición comienza la fase de infección de **120 segundos**. El tutorial puede retener el reloj mientras enseña las acciones.
4. Los bots sanos huyen; los infectados persiguen sanos y propagan su cepa. Los jugadores intervienen con posesión, mutaciones, zonas y robot.
5. Al agotarse el reloj, **gana quien tenga más bots infectados en ese momento**. Conteos iguales producen **empate técnico**. El resultado pausa el mundo y permite reiniciar o volver al menú.

Estos tiempos corresponden a [Shopping.tscn](pato-gen/scenes/Shopping.tscn). El resultado se calcula en [Mapa.gd](pato-gen/scripts/Mapa.gd); no depende del ADN sobrante ni de los contagios históricos.

## Controles

Las teclas siguientes están implementadas en [Pato.gd](pato-gen/scripts/Pato.gd) y [Mapa.gd](pato-gen/scripts/Mapa.gd). Varias se leen directamente desde el teclado y no aparecen en el Mapa de entrada de Godot.

| Acción | Cian · jugador 1 | Magenta · jugador 2 |
| --- | --- | --- |
| Movimiento del pato/fantasma o bot poseído | **W A S D** | **Flechas** |
| Mostrar/ocultar panel de mutaciones | **E** | **O** |
| Comprar siguiente evolución de una rama | **1 / 2 / 3** | **8 / 9 / 0** |
| Consultar una rama sin comprar | **Shift + 1 / 2 / 3** | **Shift + 8 / 9 / 0** |
| Invocar robot curador | **Z** | **H** |
| Colocar distorsión | **C** | **K** |
| Colocar zona caliente | **V** | **L** |
| Poseer un infectado aliado cercano | **X** | **J** |
| Invertir en Simbionte; tras la fusión, poseer al portador | **Q** | **U** |

El Exponencial tiene **dos ramas**, por lo que la tercera opción no ofrece una compra. Los paneles también permiten consultar y comprar mediante la interfaz. Las habilidades requieren fase, saldo y recarga válidos.

## Cepas y evolución

La selección de prepartida se aplica a la partida y a sus bots. Cada cepa tiene estadísticas y ramas propias; las compras mejoran infectados existentes y se aplican a los nuevos.

| Cepa | Ramas de mutaciones |
| --- | --- |
| **Atlético** | Fiebre → Rabia; Parásito → Colonia → Mente colmena; Caparazón → Regeneración → Infección inmortal |
| **Área** | Contagio en cadena → Último aliento → Explosión infecciosa; Esporas → Nube tóxica → Epidemia ambiental; Sobrecarga → Pulso viral → Tormenta infecciosa |
| **Exponencial** | Adaptación → Evolución rápida → Supercepa; División celular → Replicación → Brote masivo |

Las evoluciones de una rama cuestan **5, 10 y 15 ADN**, según su nivel y longitud. Los infectados usan sprites de su tipo y contorno de equipo; al curarse recuperan el aspecto sano.

## ADN, habilidades y remontada

- **Contagios:** una infección recompensada suma **1 ADN**. Las réplicas no generan ADN; la primera reinfección después del tratamiento del Coloso tampoco.
- **Posesión:** control directo de un infectado aliado durante **10 s**, con **20 s** de recarga.
- **Robot curador:** cuesta **10 ADN**, con **25 s** de recarga; puede curar infectados de ambos equipos.
- **Distorsión:** cuesta **4 ADN**, con **10 s** de recarga. Atrae bots sanos; el código conserva el identificador histórico `FRIO`.
- **Zona caliente:** cuesta **4 ADN**, con **10 s** de recarga propia; modifica velocidad y contagio.
- **Remontada:** el equipo con **5 o más infectados menos** recibe **1 ADN por segundo** mientras mantenga esa desventaja.
- **Balance tardío:** aumenta la curación natural del líder según la diferencia; la curación ofensiva de remontada se activa con una diferencia de 20 y se desactiva al bajar a 15.

Son parámetros actuales de implementación; requieren partidas humanas para validar su equilibrio.

## Simbionte

Ambos jugadores compiten por financiar un único Simbionte. **Q/U** invierte **5 ADN por pulsación**, con **1,5 s** de recarga, hasta **60 ADN**. El primero que completa la inversión gana la carrera.

El viajero busca un infectado aliado accesible y se fusiona por contacto. La fusión dura **20 s**, mejora movimiento y resistencia a la curación, y emite un aura que cura únicamente infectados rivales. No los convierte al equipo del portador.

Después de fusionarse, **Q/U** selecciona directamente al portador aliado para poseerlo. **X/J** conserva la posesión normal del aliado cercano. Cambiar de portador no extiende los relojes; curar al anfitrión termina la fusión.

Reglas, parámetros y pruebas: [SIMBIONTE.md](pato-gen/tests/SIMBIONTE.md).

## Coloso Antiviral

Evento ambiental **neutral** integrado en Shopping. Tras los primeros 30 s de infección, una crisis sostenida de **7 sanos o menos** puede iniciar su aparición, con aviso previo. Hay como máximo **dos apariciones** por partida y no se inician nuevos intentos cuando quedan 25 s o menos.

El Coloso recorre el mapa y cura infectados sin priorizar equipo. Las paredes bloquean su pulso; evita curar la última infección de cada equipo. Se retira por tiempo, presupuesto de curaciones, recuperación de población o falta de objetivos.

No puede poseerse ni concede recompensas por derrotarlo. Su arte actual es provisional. La intervención tiene límites y **no garantiza** restaurar toda la población sana.

Probabilidades, tiempos, protección y pruebas: [COLOSO_ANTIVIRAL.md](pato-gen/tests/COLOSO_ANTIVIRAL.md).

## Mapas y proyectos

| Ruta | Estado y uso |
| --- | --- |
| [`pato-gen/`](pato-gen/) | **Juego principal**: menú, selección, tutorial y partida en Shopping, con Simbionte y Coloso. |
| [`proyecto/`](proyecto/) | Otra copia del juego con diferencias. Para ejecutar y desarrollar la versión principal, usar `pato-gen/`. Unificación pendiente en [#9](https://github.com/Code7C26/67Games/issues/9). |
| [`design/mapa-patogen/`](design/mapa-patogen/) | Prototipo/editor del mapa Mall. Incluye `PatogenMall_MapOnly.tscn` y [guía de integración](design/mapa-patogen/MAP_INTEGRATION.md). |
| [`Patogen_Pato_Splash/`](Patogen_Pato_Splash/) | Proyecto editable y demo del parque, con ambiente, NPCs y Gran Chapuzón de 360°. Integración con la partida real pendiente. |
| [`Patogen_Laboratorio_AV07.zip`](Patogen_Laboratorio_AV07.zip) | Entrega independiente del laboratorio; debe extraerse e importarse como proyecto separado. Integración con la partida real pendiente. |
| [`assets/`](assets/), [`docs/`](docs/), [`src/`](src/) | Recursos compartidos, documentación y otros archivos del equipo. |

Los proyectos independientes de mapas no quedan seleccionables en la partida por estar presentes en el repositorio. Pato Splash expone conexiones para la IA y el contagio reales: consultar [INTEGRACION.md](Patogen_Pato_Splash/docs/INTEGRACION.md) y [GIRO360_CORONA.md](Patogen_Pato_Splash/docs/GIRO360_CORONA.md). Sus visitantes y HUD de demo no sustituyen los sistemas del juego.

## Pruebas

Las suites están en [`pato-gen/tests/`](pato-gen/tests/). Desde la raíz del repositorio, con el ejecutable de consola de Godot disponible como `godot`:

```text
godot --headless --path pato-gen --audio-driver Dummy --max-fps 60 --script res://tests/test_simbionte.gd -- --onboarding-test
```

El mismo patrón permite ejecutar las suites headless de Simbionte, Coloso y regresiones. **`test_match_ui.gd` y `test_menu.gd` requieren renderizado**: ejecutarlas sin `--headless`. Los detalles y escenarios están en los documentos de cada mecánica.

La documentación del Coloso registra **530 comprobaciones aprobadas** en su ejecución del 27/10/2026. Es un resultado documentado de esa ejecución; esta actualización del README no vuelve a ejecutar las suites ni certifica el balance competitivo.

Hay avisos de recursos/audio y ObjectDB al cerrar algunas pruebas, además del error de perfil corrupto provocado deliberadamente por el test del tutorial. El lanzador local mencionado en las notas de pruebas aún no está versionado; su reproducción y automatización se siguen en [#6](https://github.com/Code7C26/67Games/issues/6) y [#12](https://github.com/Code7C26/67Games/issues/12).

## Próximo trabajo

Los issues incluyen estado actual, referencias y criterios de aceptación. **P1** identifica el trabajo prioritario; **P2**, las tareas posteriores.

| Prioridad | Issue |
| --- | --- |
| P1 | [#4 · Integrar Laboratorio AV-07 en una partida real](https://github.com/Code7C26/67Games/issues/4) |
| P1 | [#5 · Conectar Pato Splash con bots, infección y HUD](https://github.com/Code7C26/67Games/issues/5) |
| P1 | [#6 · Pruebas reproducibles y regresiones automáticas](https://github.com/Code7C26/67Games/issues/6) |
| P1 | [#7 · Balance humano de cepas, remontada, Simbionte y Coloso](https://github.com/Code7C26/67Games/issues/7) |
| P1 | [#8 · Exportación Windows y build de prueba](https://github.com/Code7C26/67Games/issues/8) |
| P2 | [#9 · Unificar la fuente canónica y proyectos históricos](https://github.com/Code7C26/67Games/issues/9) |
| P2 | [#10 · Guía de juego para Simbionte y Coloso](https://github.com/Code7C26/67Games/issues/10) |
| P2 | [#11 · Rendimiento de la partida completa](https://github.com/Code7C26/67Games/issues/11) |
| P2 | [#12 · Avisos de recursos y ObjectDB](https://github.com/Code7C26/67Games/issues/12) |
| P2 | [#13 · Arte definitivo del Coloso Antiviral](https://github.com/Code7C26/67Games/issues/13) |

La exportación del juego principal está pendiente. Los ZIP de mapas son proyectos editables de Godot.

## Tecnologías y autoría

**Godot 4.7.1**, **GDScript**, herramientas 2D de Godot, **Aseprite**, Git y GitHub.

Desarrollado de forma colaborativa por el equipo **67Games**.
