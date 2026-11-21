# Manual de usuario de Patogen

67Games · Guía para jugar Patogen

Patogen es un juego de infección y estrategia para **dos jugadores locales en una misma computadora y pantalla**. Cada jugador elige una de seis cepas, propaga su infección y usa ADN para evolucionarla. Gana quien tenga más personajes infectados de su equipo al terminar el tiempo. Las pruebas presenciales con parejas del curso confirmaron que la mayoría de los beta testers se sintió cómoda con los controles y que, después de dos partidas, se comprenden los controles y las mecánicas. La única recomendación de esas pruebas fue agregar movimiento al mapa; esa mejora ya está integrada.

## Antes de jugar

Necesitás dos personas, teclado y mouse. Los jugadores comparten el teclado. Podés usar la build de Windows publicada o abrir el proyecto con Godot.

### Abrir la versión para Windows

1. Descargá [PatoGen-Windows.zip](https://github.com/Code7C26/67Games/raw/refs/heads/main/PatoGen-Windows.zip) desde el repositorio.
2. Extraé el ZIP completo en una carpeta.
3. Abrí `PatoGen-Windows/PatoGen.exe`.
4. Hacé clic en la ventana del juego para darle foco y comprobá que ambos jugadores puedan usar sus teclas.

No hace falta instalar Godot. Para compartir el juego, enviá el ZIP completo porque contiene las instrucciones y licencias.

### Abrir el proyecto con Godot

1. Instalá Godot 4.7.1, versión indicada por la configuración del proyecto.
2. Obtené el repositorio [67Games en GitHub](https://github.com/Code7C26/67Games) y descomprimilo si lo descargaste como ZIP.
3. En Godot, elegí **Importar** y seleccioná `pato-gen/project.godot`.
4. Esperá a que se importen los recursos y presioná **F5** para ejecutar el proyecto completo.

Para esta entrega no se publican requisitos mínimos de hardware validados. El proyecto utiliza renderizado Mobile/Vulkan. Si el juego no inicia, consultá al equipo e indicá tu sistema y el mensaje que aparece.

### Empezar una partida

1. La presentación de 67Games dura unos 3,4 segundos y se puede omitir. En el menú podés cambiar **English / Español**. El idioma y el estado del tutorial se guardan en el perfil local de Windows.
2. Elegí **Nueva partida con tutorial** si es tu primera vez. **Jugar** inicia el flujo normal; la primera visita puede incluir una introducción que se puede omitir.
3. En la selección de cepas, cada lado puede elegir con **A / D** para el jugador azul (cian) y **← / →** para el jugador magenta, o hacer clic en una cepa. Hay seis opciones: Atlético, Área, Exponencial, Garfio, Camaleón y Rastreador.
4. Continuá a la selección de mapa. Elegí **Shopping**, **Laboratorio AV-07** o **Pato Splash** y pulsá **Comenzar partida**.
5. Mové tu pato durante los **3 segundos iniciales** para elegir desde dónde comenzar. Al terminar, desaparece con una animación, infecta al personaje sano más cercano disponible y se convierte en fantasma.
6. Durante los **120 segundos de infección**, administrá ADN, comprá mutaciones y usá tus habilidades. El tutorial puede detener temporalmente el reloj mientras enseña.

El menú también ofrece **Ver tutorial**, **Movimiento reducido** y **Salir**. Movimiento reducido modifica algunas animaciones de la introducción y la guía; no cambia las reglas de la partida. Durante la partida, **Esc** abre la pausa y **F1** muestra la guía.

## Pantalla de juego

![Partida en Shopping con los paneles de mutaciones abiertos](../map-captures/Shopping_after.png)

Partida en Shopping con los contadores superiores y ambos paneles de mutaciones abiertos.

| Elemento | Para qué sirve |
| --- | --- |
| P1 Azul/Cian y P2 Magenta | Identifican los equipos. El número de infectados indica cuántos personajes pertenecen a cada uno en ese momento. |
| Reloj y mensaje de fase | Muestran la etapa de la partida y el tiempo restante. Durante la introducción puede verse «Busca tu huésped». |
| ADN | Es el saldo disponible para compras y habilidades. Gastarlo no reduce directamente el contador de infectados. |
| Panel de mutaciones | Permite consultar y comprar la siguiente evolución de cada rama. Se muestra u oculta con E u O. |
| Indicadores del Simbionte | Muestran el avance de la inversión de cada equipo hacia 60 ADN. |
| Botón contextual | Si controlás un Garfio o un Camaleón, muestra la acción disponible: enganchar o camuflar. |

Los infectados se desplazan automáticamente. Los sanos huyen y los infectados buscan nuevos huéspedes. Tu fantasma te permite intervenir; cuando poseés a un infectado, las mismas teclas de movimiento pasan a controlar a ese personaje.

**El número que decide el resultado es el de infectados al final.** Un personaje curado deja de contar para su antiguo equipo. El ADN acumulado o los contagios logrados durante toda la partida no reemplazan ese conteo.

<!-- PAGE -->

## Controles de los dos jugadores

| Acción | Jugador 1 Cian | Jugador 2 Magenta |
| --- | --- | --- |
| Mover pato, fantasma o infectado poseído | W A S D | Flechas |
| Mostrar u ocultar mutaciones | E | O |
| Comprar siguiente evolución de una rama | 1 / 2 / 3 | 8 / 9 / 0 |
| Consultar una rama sin comprar | Shift + 1 / 2 / 3 | Shift + 8 / 9 / 0 |
| Invocar robot curador | Z | H |
| Colocar distorsión | C | K |
| Colocar zona caliente | V | L |
| Poseer al infectado aliado más cercano o activar acción de cepa | X | J |
| Invertir en el Simbionte o poseer a su portador aliado | Q | U |
| Abrir la guía durante la partida | F1 | F1 |
| Abrir o cerrar la pausa durante la partida | Esc | Esc |

También podés usar los botones visibles del panel para consultar y comprar opciones. La interfaz se maneja con el mouse compartido. Si una descripción es larga, usá la rueda del mouse para leerla.

Al controlar una cepa especial, la acción de **X / J** cambia: Garfio engancha y Camaleón intenta camuflarse. Si no estás controlando un huésped, la tecla permite poseer al infectado aliado más cercano. En pantallas de introducción o guía, seguí la indicación visible para continuar u omitir.

### Fases de la partida

**Inicio con patos:** disponés de 3 segundos de movimiento antes de la animación de desaparición. Las habilidades de infección se utilizan en la etapa siguiente.

**Infección:** el pato pasa a fantasma y empieza el reloj de 120 segundos. Podés moverte, gestionar mutaciones y activar habilidades cuando su fase, saldo y recarga lo permiten.

**Resultado:** el juego se detiene y muestra ganador o empate técnico. Usá los botones de la pantalla de resultado para reiniciar el mapa actual o volver al menú.

### Cómo obtener y gastar ADN

Un contagio recompensado suma **1 ADN**. Algunas réplicas y reinfecciones no generan recompensa. Las compras se descuentan del saldo de tu equipo y las mutaciones mejoran a tus infectados actuales y a los que incorpores después.

Si una acción no se activa, comprobá que estés en la fase de infección, tengas ADN suficiente y haya terminado su recarga. En el tutorial, completá la indicación visible antes de intentar otra acción.

<!-- PAGE -->

## Cepas y mutaciones

Las seis cepas ofrecen estilos distintos. Elegí una antes de la partida y consultá las descripciones del panel para conocer el efecto de cada compra. Las pruebas presenciales confirmaron que la mayoría de los beta testers encontró cómodos los controles y pudo comprender los controles y las mecánicas después de dos partidas.

| Cepa | Estilo de juego | Acción o ventaja distintiva |
| --- | --- | --- |
| Atlético | Persecución rápida. | Presiona a los huéspedes con su velocidad. |
| Área | Propagación y control de zonas. | Favorece contagios en cadena y el uso de zonas. |
| Exponencial | Crecimiento y adaptación. | Puede reproducirse y mejorar a medida que avanza la partida. |
| Garfio | Captura y arrastre. | Engancha a huéspedes sanos visibles y los acerca; esquivar o bloquear el gancho es posible y el contagio no está garantizado. |
| Camaleón | Infiltración y emboscada. | Se camufla cuando está listo y no hay humanos sanos demasiado cerca; una acción incompatible puede revelarlo. |
| Rastreador | Búsqueda y coordinación. | Detecta y recuerda presas observadas; algunas mejoras coordinan a infectados aliados. |

| Cepa | Rama | Evoluciones en orden |
| --- | --- | --- |
| Atlético | 1 | Fiebre → Rabia |
| Atlético | 2 | Parásito → Colonia → Mente colmena |
| Atlético | 3 | Caparazón → Regeneración → Infección inmortal |
| Área | 1 | Contagio en cadena → Último aliento → Explosión infecciosa |
| Área | 2 | Esporas → Nube tóxica → Epidemia ambiental |
| Área | 3 | Sobrecarga → Pulso viral → Tormenta infecciosa |
| Exponencial | 1 | Adaptación → Evolución rápida → Supercepa |
| Exponencial | 2 | División celular → Replicación → Brote masivo |
| Garfio | 1 | Presa vulnerable I → II → III |
| Garfio | 2 | Doble tendón I → II → III |
| Garfio | 3 | Reenganche I → II → III |
| Camaleón | 1 | Pigmentación avanzada → Mimetismo → Cromatóforos |
| Camaleón | 2 | Desvanecimiento → Retorno sigiloso → Adaptación fugaz |
| Camaleón | 3 | Ataque sorpresa → Emboscada viral → Golpe furtivo |
| Rastreador | 1 | Llamado de manada I → II → III |
| Rastreador | 2 | Cerco depredador I → II → III |
| Rastreador | 3 | Marca biológica I → II → III |

Cada rama avanza en orden. La primera evolución cuesta **5 ADN**, la segunda **10 ADN** y la tercera **15 ADN**, cuando existe. Todas las cepas nuevas tienen tres ramas. Exponencial tiene dos ramas: la tercera tecla de compra no ofrece una evolución.

### Ejemplo de compra

Si jugás con Atlético y sos cian, **Shift + 1** consulta la primera rama sin gastar ADN. Con 5 ADN disponibles, **1** compra Fiebre. La siguiente compra de esa misma rama cuesta 10 ADN y obtiene Rabia. No se compran todos los niveles con una sola pulsación.

Para magenta, la primera rama se consulta con **Shift + 8** y se compra con **8**. Las otras ramas usan 2 y 3 para cian, y 9 y 0 para magenta.

### Elegir qué mejorar

Antes de gastar, revisá el tiempo restante, tu saldo y la cantidad de infectados de ambos equipos. Las mutaciones compiten por el mismo ADN que las habilidades y el Simbionte. Guardar recursos puede ser útil, pero el ADN sobrante no suma puntos al resultado final.

## Habilidades y eventos

| Acción | Costo | Recarga | Uso |
| --- | --- | --- | --- |
| Posesión | Sin costo de ADN | 20 s desde la activación | Controlás hasta 10 s al infectado aliado más cercano. Si se cura, termina la posesión. |
| Robot curador | 10 ADN | 25 s | Invoca un robot que puede curar infectados de ambos equipos. Usalo teniendo en cuenta a tus propios aliados. |
| Distorsión | 4 ADN | 10 s | Coloca una zona que atrae personajes sanos. |
| Zona caliente | 4 ADN | 10 s | Coloca una zona que modifica velocidad y contagio. Su recarga es independiente de la distorsión. |

### Simbionte

Los dos equipos compiten por un único Simbionte. Durante la infección, pulsá **Q** para cian o **U** para magenta para invertir **5 ADN por pulsación**. Cada aporte tiene **1,5 s de recarga**. El primer equipo que llega a **60 ADN invertidos** gana la carrera; el rival deja de poder invertir.

El Simbionte busca un infectado aliado accesible y se fusiona por contacto. La fusión dura **20 segundos**, mejora movimiento y resistencia a la curación, y emite un aura que cura infectados rivales. Los personajes curados no se convierten automáticamente a tu equipo.

Después de la fusión, Q o U permite seleccionar al portador aliado para poseerlo, respetando las condiciones de la posesión. X o J conserva la selección normal del aliado más cercano. Cambiar de portador no reinicia los relojes; si se cura el anfitrión, termina la fusión.

### Coloso Antiviral

Es un evento neutral que puede aparecer cuando quedan muy pocos sanos. Cura infectados de ambos equipos, se desplaza por el mapa y se retira según las condiciones de la partida. Las paredes bloquean su pulso y evita curar la última infección de cada equipo.

No lo controlás ni lo derrotás para ganar recompensas. Prestá atención al aviso de aparición y al cambio de conteos. Su presencia no garantiza que toda la población vuelva a estar sana.

### Uso de las nuevas cepas

- **Garfio:** la IA intenta capturar automáticamente cuando puede. Si poseés a un Garfio, apuntá con el movimiento y pulsá **X / J** o el botón **Enganchar**. La presa puede escapar, la pared puede bloquear el ataque y la llegada produce un solo intento de contagio.
- **Camaleón:** se oculta solo si está listo y lejos de humanos sanos. Al poseerlo, pulsá **X / J** o **Camuflar** para volver a intentarlo. Contagiar o usar ciertas habilidades puede revelarlo.
- **Rastreador:** funciona sin una tecla adicional. Recuerda la última ubicación observada de una presa y, con mejoras, coordina a algunos infectados aliados. Si pierde el rastro, vuelve a buscar.

Las descripciones completas de las evoluciones aparecen en el panel del juego. El [repositorio](https://github.com/Code7C26/67Games) conserva las reglas técnicas de [Garfio y Rastreador](https://github.com/Code7C26/67Games/blob/main/pato-gen/docs/MUTACIONES_GARFIO_RASTREADOR.md) y [Camaleón](https://github.com/Code7C26/67Games/blob/main/pato-gen/docs/CAMALEON.md).

### Remontada

Si tu equipo tiene al menos **5 infectados menos** que el rival, recibe **1 ADN por segundo** mientras mantenga esa desventaja. También existen ajustes de curación para limitar diferencias grandes. Son ayudas automáticas: no garantizan empatar ni ganar.

## Primera partida y ayuda

Para aprender, empezá con el tutorial. Ubicá tu color, abrí el panel, consultá una rama antes de comprarla y probá una posesión. Después repetí una partida para comparar otra cepa o mapa. Podés usar cualquiera de los tres mapas desde el selector.

### Ganar y volver a jugar

Al terminar el reloj se comparan los infectados actuales. El número mayor gana; si son iguales, hay **empate técnico**. **Reiniciar** vuelve a cargar el mapa actual. Para cambiar cepas o mapa, usá la opción de volver al menú y comenzá otra partida.

### Preguntas frecuentes

| Situación | Qué revisar |
| --- | --- |
| No responde el teclado | Hacé clic en la ventana del juego y verificá el grupo de teclas de tu jugador. Completá u omití la guía si está activa. |
| El pato desapareció | Es la transición al modo fantasma. Si además estás poseyendo a un infectado, el fantasma permanece oculto hasta terminar la posesión. |
| No veo las mutaciones | Mostrá el panel con E para cian u O para magenta. |
| Una compra o habilidad no funciona | Revisá fase, saldo, recarga y si la rama ya está completa. Exponencial no tiene tercera rama. |
| X o J no permite poseer | Necesitás modo fantasma, un infectado aliado y recarga disponible. Si el aliado se cura, perdés su control. |
| Q o U ya no agrega inversión | Puede faltar ADN, seguir la recarga o haberse decidido la carrera. Tras la fusión, esa tecla pasa a seleccionar al portador aliado. |
| X o J no engancha o no camufla | La acción especial sólo aparece al poseer un Garfio o Camaleón. Revisá el botón contextual, la fase de juego y el estado del huésped. |
| Bajó mi número de infectados | La curación natural, robots y Coloso pueden reducirlo. El aura del Simbionte rival también cura a tus infectados. |
| El reloj no avanza | El tutorial puede retenerlo mientras espera una acción. En la pantalla de resultado la partida ya terminó. |

### Compartir una observación

Usá la [encuesta de Patogen](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) o los [issues del repositorio](https://github.com/Code7C26/67Games/issues). Indicá mapa, cepas, equipo, acción intentada y qué ocurrió. Una captura ayuda a explicar problemas de lectura o controles. Esta guía abarca el modo local, las seis cepas y los tres mapas; para cambios del proyecto, revisá la [documentación](README.md) y el [README del juego](../README.md).
