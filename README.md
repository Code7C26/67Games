# Patogen

> Videojuego 2D competitivo de infección y estrategia para **dos jugadores locales**, desarrollado por **67Games** en Godot. Las cepas **cian** y **magenta** compiten por expandirse entre una población de bots, administrar ADN y evolucionar sus infectados.

![Estado](https://img.shields.io/badge/Estado-Prototipo%20jugable-orange)
![Motor](https://img.shields.io/badge/Godot-4.7.1-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/Lenguaje-GDScript-478CBF)

El juego principal ofrece seis cepas, tres mapas, tutorial, audio, Simbionte, Coloso Antiviral y una versión ejecutable para Windows. Las pruebas presenciales con parejas del curso mostraron que la mayoría de los beta testers encontró cómodos los controles y que los jugadores comprenden los controles y mecánicas después de dos partidas. La única recomendación fue agregar movimiento al mapa; esa mejora ya está integrada. La build para Windows está en [PatoGen-Windows.zip](PatoGen-Windows.zip); su prueba en otra computadora sigue como tarea técnica.

La [documentación del producto y su propuesta comercial](docs/README.md) reúne los mapas de empatía basados en las pruebas presenciales, CUPID, FODA y viabilidad. La [encuesta de Patogen](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) registra preferencias generales y se interpreta por separado de las partidas observadas.

Para aprender a jugar, consultá el [manual de usuario en español](docs/Manual_de_Usuario.md), también disponible en [PDF](docs/Manual%20de%20Usuario%20de%20Patogen.pdf) y [Word](docs/Manual%20de%20Usuario%20de%20Patogen.docx), o el [User Manual in English](docs/User_Manual.md), disponible en [PDF](docs/User%20Manual%20of%20Patogen.pdf) y [Word](docs/User%20Manual%20of%20Patogen.docx).

## Ejecutar el juego

### Windows

1. Descargá [PatoGen-Windows.zip](PatoGen-Windows.zip) desde este repositorio.
2. Extraé el ZIP completo.
3. Abrí `PatoGen-Windows/PatoGen.exe`. No necesitás instalar Godot.

Para compartir el juego, enviá el ZIP completo, no el ejecutable aislado. La build publicada incluye instrucciones y licencias.

### Desde el código fuente

1. Instalá **Godot 4.7.1**, versión indicada por la configuración del proyecto.
2. Cloná el repositorio:

   ```bash
   git clone https://github.com/Code7C26/67Games.git
   ```

3. En Godot, seleccioná **Importar** y abrí **[`pato-gen/project.godot`](pato-gen/project.godot)**.
4. Esperá la importación de recursos y pulsá **F5**.

El juego inicia en el menú principal, usa **Mobile/Vulkan con HDR 2D** y un lienzo de **1920 × 1080**. F6 ejecuta sólo la escena abierta en el editor.

La presentación inicial dura unos 3,4 segundos y se puede omitir. El menú permite jugar con tutorial, consultar la guía, activar **movimiento reducido** y cambiar entre **English / Español**. El idioma y el estado del tutorial se guardan en el perfil local. Durante una partida, **Esc** abre la pausa y **F1** muestra la guía.

## Cómo se juega

1. Cada jugador elige una de seis cepas en la prepartida: **Atlético**, **Área**, **Exponencial**, **Garfio**, **Camaleón** o **Rastreador**.
2. Elegir **Shopping**, **Laboratorio AV-07** o **Pato Splash**. En los tres mapas, la fase inicial de los patos está configurada en **3 segundos**. Al terminar, cada pato reproduce su desaparición, inicia el contagio y pasa al modo fantasma.
3. Cuando termina esa transición comienza la fase de infección de **120 segundos**. El tutorial puede retener el reloj mientras enseña las acciones.
4. Los bots sanos huyen; los infectados persiguen sanos y propagan su cepa. Los jugadores intervienen con posesión, mutaciones, zonas y robot.
5. Al agotarse el reloj, **gana quien tenga más bots infectados en ese momento**. Conteos iguales producen **empate técnico**. El resultado pausa el mundo y permite reiniciar o volver al menú.

Los tres mapas comparten estos tiempos y 65 huéspedes jugables. En Pato Splash también aparecen personajes decorativos que salen del escenario antes de la infección y no se pueden contagiar. Ver [integración de mapas](pato-gen/docs/MAPAS_INTEGRADOS.md). El resultado se calcula en [Mapa.gd](pato-gen/scripts/Mapa.gd); no depende del ADN sobrante ni de los contagios históricos.

| Cepa | Estilo | Acción propia al poseer un infectado |
| --- | --- | --- |
| **Atlético** | Persecución rápida y presión constante. | Sin acción adicional. |
| **Área** | Contagios en cadena y control de zonas. | Sin acción adicional. |
| **Exponencial** | Adaptación, reproducción y crecimiento. | Sin acción adicional. |
| **Garfio** | Captura y arrastre de huéspedes sanos. | **X / J** o el botón contextual para enganchar en la dirección apuntada. La captura puede fallar y no garantiza un contagio. |
| **Camaleón** | Infiltración y emboscadas. | **X / J** o **Camuflar** para ocultarse cuando se cumplen las condiciones; acercarse, contagiar o usar una habilidad puede revelar al huésped. |
| **Rastreador** | Detecta y recuerda presas; coordina una cacería con aliados. | Rastreo pasivo; no agrega una tecla de habilidad. |

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
| **Garfio** | Presa vulnerable I → II → III; Doble tendón I → II → III; Reenganche I → II → III |
| **Camaleón** | Pigmentación avanzada → Mimetismo → Cromatóforos; Desvanecimiento → Retorno sigiloso → Adaptación fugaz; Ataque sorpresa → Emboscada viral → Golpe furtivo |
| **Rastreador** | Llamado de manada I → II → III; Cerco depredador I → II → III; Marca biológica I → II → III |

Las evoluciones de una rama cuestan **5, 10 y 15 ADN**, según su nivel y longitud. Los nuevos infectados heredan la cepa y las mejoras de su equipo. Los infectados usan sprites de su tipo y contorno de equipo; al curarse recuperan el aspecto sano. Los detalles de Garfio y Rastreador están en [mutaciones](pato-gen/docs/MUTACIONES_GARFIO_RASTREADOR.md); las reglas del [Camaleón](pato-gen/docs/CAMALEON.md) también se documentan por separado.

## ADN, habilidades y remontada

- **Contagios:** una infección recompensada suma **1 ADN**. Las réplicas no generan ADN; la primera reinfección después del tratamiento del Coloso tampoco.
- **Posesión:** control directo de un infectado aliado durante **10 s**, con **20 s** de recarga.
- **Robot curador:** cuesta **10 ADN**, con **25 s** de recarga; puede curar infectados de ambos equipos.
- **Distorsión:** cuesta **4 ADN**, con **10 s** de recarga. Atrae bots sanos; el código conserva el identificador histórico `FRIO`.
- **Zona caliente:** cuesta **4 ADN**, con **10 s** de recarga propia; modifica velocidad y contagio.
- **Remontada:** el equipo con **5 o más infectados menos** recibe **1 ADN por segundo** mientras mantenga esa desventaja.
- **Balance tardío:** aumenta la curación natural del líder según la diferencia; la curación ofensiva de remontada se activa con una diferencia de 20 y se desactiva al bajar a 15.

Las pruebas presenciales con parejas del curso incluyeron controles, mecánicas y balance. La mayoría de los beta testers encontró cómodos los controles y comprendió las mecánicas después de dos partidas; el único pedido fue agregar movimiento al mapa, ya integrado.

## Simbionte

Ambos jugadores compiten por financiar un único Simbionte. **Q/U** invierte **5 ADN por pulsación**, con **1,5 s** de recarga, hasta **60 ADN**. El primero que completa la inversión gana la carrera.

El viajero busca un infectado aliado accesible y se fusiona por contacto. La fusión dura **20 s**, mejora movimiento y resistencia a la curación, y emite un aura que cura únicamente infectados rivales. No los convierte al equipo del portador.

Después de fusionarse, **Q/U** selecciona directamente al portador aliado para poseerlo. **X/J** conserva la posesión normal del aliado cercano; si el huésped poseído es un Garfio o un Camaleón, esa tecla activa su acción contextual. Rastreador sigue funcionando de manera pasiva. Cambiar de portador no extiende los relojes; curar al anfitrión termina la fusión.

Reglas, parámetros y pruebas: [SIMBIONTE.md](pato-gen/tests/SIMBIONTE.md).

## Coloso Antiviral

Evento ambiental **neutral** integrado en los tres mapas. Tras los primeros 30 s de infección, una crisis sostenida de **7 sanos o menos** puede iniciar su aparición, con aviso previo. Hay como máximo **dos apariciones** por partida y no se inician nuevos intentos cuando quedan 25 s o menos.

El Coloso recorre el mapa y cura infectados sin priorizar equipo. Las paredes bloquean su pulso; evita curar la última infección de cada equipo. Se retira por tiempo, presupuesto de curaciones, recuperación de población o falta de objetivos.

No puede poseerse ni concede recompensas por derrotarlo. Su arte actual es provisional. La intervención tiene límites y **no garantiza** restaurar toda la población sana.

Probabilidades, tiempos, protección y pruebas: [COLOSO_ANTIVIRAL.md](pato-gen/tests/COLOSO_ANTIVIRAL.md).

## Archivos principales

| Ruta | Uso |
| --- | --- |
| [`pato-gen/`](pato-gen/) | Proyecto canónico de Godot: seis cepas, tres mapas, tutorial y partida. |
| [`PatoGen-Windows.zip`](PatoGen-Windows.zip) | Build ejecutable de Windows de 64 bits; se extrae antes de abrir. |
| [`docs/`](docs/) | Manual, documentación del producto e investigación de usuarios. |
| [`design/mapa-patogen/`](design/mapa-patogen/) | Prototipo y herramientas del mapa Shopping. |
| [`assets/`](assets/), [`map-captures/`](map-captures/), [`src/`](src/) | Recursos, capturas y herramientas del equipo. |

Para jugar con infección, habilidades, HUD y resultado, usá el proyecto canónico `pato-gen/` o la build Windows publicada. El issue [#9](https://github.com/Code7C26/67Games/issues/9) conserva tareas de auditoría de la reorganización y de validación de un clon limpio.

## Pruebas

Las suites están en [`pato-gen/tests/`](pato-gen/tests/). Desde la raíz del repositorio, con el ejecutable de consola de Godot disponible como `godot`:

```text
godot --headless --path pato-gen --audio-driver Dummy --max-fps 60 --script res://tests/test_simbionte.gd -- --onboarding-test
```

El mismo patrón permite ejecutar las suites headless de Simbionte, Coloso y regresiones. **`test_match_ui.gd` y `test_menu.gd` requieren renderizado**: ejecutarlas sin `--headless`. Los detalles y escenarios están en los documentos de cada mecánica.

La documentación del Coloso registra **530 comprobaciones aprobadas** en su ejecución del 27/10/2026. Además, las pruebas presenciales con parejas del curso confirmaron la comodidad de los controles para la mayoría de los beta testers y la comprensión de controles y mecánicas después de dos partidas. La única recomendación fue agregar movimiento al mapa; ya se incorporó.

Hay avisos de recursos/audio y ObjectDB al cerrar algunas pruebas, además del error de perfil corrupto provocado deliberadamente por el test del tutorial. El lanzador local mencionado en las notas de pruebas aún no está versionado; su reproducción y automatización se siguen en [#6](https://github.com/Code7C26/67Games/issues/6) y [#12](https://github.com/Code7C26/67Games/issues/12).

## Próximo trabajo

Los issues incluyen estado actual, referencias y criterios de aceptación. **P1** identifica el trabajo prioritario; **P2**, las tareas posteriores.

| Prioridad | Issue |
| --- | --- |
| P1 | [#6 · Pruebas reproducibles y regresiones automáticas](https://github.com/Code7C26/67Games/issues/6) |
| P1 | [#8 · Validar la build Windows publicada en una computadora externa](https://github.com/Code7C26/67Games/issues/8) |
| P2 | [#9 · Auditar la reorganización y probar un clon limpio](https://github.com/Code7C26/67Games/issues/9) |
| P2 | [#10 · Completar la ayuda interactiva de Simbionte y Coloso](https://github.com/Code7C26/67Games/issues/10) |
| P2 | [#11 · Rendimiento de la partida completa](https://github.com/Code7C26/67Games/issues/11) |
| P2 | [#12 · Avisos de recursos y ObjectDB](https://github.com/Code7C26/67Games/issues/12) |
| P2 | [#13 · Arte definitivo del Coloso Antiviral](https://github.com/Code7C26/67Games/issues/13) |

Hay una build de Windows publicada en `PatoGen-Windows.zip`. El issue #8 sigue abierto porque falta registrar una prueba fuera del editor y en otra computadora, con sonido, resolución y perfil. No se anuncian requisitos mínimos de hardware validados.

## Tecnologías y autoría

**Godot 4.7.1**, **GDScript**, herramientas 2D de Godot, **Aseprite**, Git y GitHub.

Desarrollado de forma colaborativa por el equipo **67Games**.
