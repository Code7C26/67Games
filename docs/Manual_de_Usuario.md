# Manual de usuario de Patogen

67Games · Prototipo jugable · Revisión del 06/11/2026

Patogen es un juego de infección y estrategia para **dos jugadores locales en una misma computadora y pantalla**. Cada jugador controla una cepa, propaga su infección y usa ADN para evolucionarla. Gana quien tenga más personajes infectados de su equipo al terminar el tiempo.

## Antes de jugar

Necesitás dos personas, teclado y mouse, y una copia del proyecto principal. Los jugadores comparten el teclado. La versión documentada se ejecuta desde Godot; el repositorio todavía no presenta una exportación final del juego principal lista para instalar. Los ZIP independientes de mapas son demos de desarrollo.

### Abrir el prototipo

1. Obtené la última versión de [67Games en GitHub](https://github.com/Code7C26/67Games). Si la descargás como ZIP, descomprimila antes de abrirla.
2. Instalá Godot 4.7.1, la versión indicada por las pruebas del proyecto.
3. En Godot, elegí **Importar** y seleccioná el archivo **pato-gen/project.godot** de la carpeta descargada.
4. Esperá a que se importen los recursos y presioná **F5** para ejecutar el proyecto completo.
5. Comprobá que ambos jugadores puedan usar sus teclas. Si jugás desde el editor, hacé clic en la ventana del juego para darle el foco.

Para esta entrega no se publican requisitos mínimos de hardware validados. El proyecto utiliza renderizado Mobile/Vulkan. Si no inicia, consultá al equipo e indicá tu sistema y el mensaje que aparece.

### Empezar una partida

1. En el menú principal, elegí **Nueva partida con tutorial** si es tu primera vez. **Jugar** inicia el flujo normal; la primera visita puede incluir una introducción que se puede omitir.
2. Usá las flechas de selección de cada lado para elegir **Atlético**, **Área** o **Exponencial**. Cian es el jugador 1 y magenta el jugador 2.
3. Continuá a la selección de mapa. Elegí **Shopping**, **Laboratorio AV-07** o **Pato Splash** y pulsá **Comenzar partida**.
4. Mové tu pato durante los **3 segundos iniciales** para elegir desde dónde comenzar. Al terminar, desaparece con una animación, infecta al personaje sano más cercano disponible y se convierte en fantasma.
5. Durante los **120 segundos de infección**, administrá ADN, comprá mutaciones y usá tus habilidades. El tutorial puede detener temporalmente el reloj mientras enseña.

El menú también ofrece **Ver tutorial**, **Movimiento reducido** y **Salir**. Movimiento reducido modifica animaciones de la introducción y la guía; no cambia las reglas de la partida.

<!-- PAGE -->

## Pantalla de juego

![Partida en Shopping con los paneles de mutaciones abiertos](../map-captures/Shopping_after.png)

Partida en Shopping con los contadores superiores y ambos paneles de mutaciones abiertos.

| Elemento | Para qué sirve |
| --- | --- |
| P1 Cian y P2 Magenta | Identifican los equipos. El número de infectados indica cuántos personajes pertenecen a cada uno en ese momento. |
| Reloj y mensaje de fase | Muestran la etapa de la partida y el tiempo restante. Durante la introducción puede verse «Busca tu huésped». |
| ADN | Es el saldo disponible para compras y habilidades. Gastarlo no reduce directamente el contador de infectados. |
| Panel de mutaciones | Permite consultar y comprar la siguiente evolución de cada rama. Se muestra u oculta con E u O. |
| Indicadores del Simbionte | Muestran el avance de la inversión de cada equipo hacia 60 ADN. |

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
| Poseer al infectado aliado más cercano | X | J |
| Invertir en el Simbionte o poseer a su portador aliado | Q | U |
| Abrir la guía durante la partida | F1 | F1 |

También podés usar los botones visibles del panel para consultar y comprar opciones. La interfaz se maneja con el mouse compartido. Si una descripción es larga, usá la rueda del mouse para leerla.

**Escape** permite omitir o cerrar la guía visible según el contexto. No es una tecla de pausa general de la partida. Para repetir el tutorial, volvé al menú y elegí Nueva partida con tutorial.

### Fases de la partida

**Inicio con patos:** disponés de 3 segundos de movimiento antes de la animación de desaparición. Las habilidades de infección se utilizan en la etapa siguiente.

**Infección:** el pato pasa a fantasma y empieza el reloj de 120 segundos. Podés moverte, gestionar mutaciones y activar habilidades cuando su fase, saldo y recarga lo permiten.

**Resultado:** el juego se detiene y muestra ganador o empate técnico. Usá los botones de la pantalla de resultado para reiniciar el mapa actual o volver al menú.

### Cómo obtener y gastar ADN

Un contagio recompensado suma **1 ADN**. Algunas réplicas y reinfecciones no generan recompensa. Las compras se descuentan del saldo de tu equipo y las mutaciones mejoran a tus infectados actuales y a los que incorpores después.

Si una acción no se activa, comprobá que estés en la fase de infección, tengas ADN suficiente y haya terminado su recarga. En el tutorial, completá la indicación visible antes de intentar otra acción.

<!-- PAGE -->

## Cepas y mutaciones

Las tres cepas ofrecen ramas distintas. Elegí una antes de la partida y consultá las descripciones del panel para conocer el efecto de cada compra. El balance entre cepas todavía se está probando con jugadores.

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

Cada rama avanza en orden. La primera evolución cuesta **5 ADN**, la segunda **10 ADN** y la tercera **15 ADN**, cuando existe. El Exponencial tiene dos ramas: la tercera tecla de compra no ofrece una evolución.

### Ejemplo de compra

Si jugás con Atlético y sos cian, **Shift + 1** consulta la primera rama sin gastar ADN. Con 5 ADN disponibles, **1** compra Fiebre. La siguiente compra de esa misma rama cuesta 10 ADN y obtiene Rabia. No se compran todos los niveles con una sola pulsación.

Para magenta, la primera rama se consulta con **Shift + 8** y se compra con **8**. Las otras ramas usan 2 y 3 para cian, y 9 y 0 para magenta.

### Elegir qué mejorar

Antes de gastar, revisá el tiempo restante, tu saldo y la cantidad de infectados de ambos equipos. Las mutaciones compiten por el mismo ADN que las habilidades y el Simbionte. Guardar recursos puede ser útil, pero el ADN sobrante no suma puntos al resultado final.

<!-- PAGE -->

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

### Remontada

Si tu equipo tiene al menos **5 infectados menos** que el rival, recibe **1 ADN por segundo** mientras mantenga esa desventaja. También existen ajustes de curación para limitar diferencias grandes. Son ayudas automáticas: no garantizan empatar ni ganar.

<!-- PAGE -->

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
| Bajó mi número de infectados | La curación natural, robots y Coloso pueden reducirlo. El aura del Simbionte rival también cura a tus infectados. |
| El reloj no avanza | El tutorial puede retenerlo mientras espera una acción. En la pantalla de resultado la partida ya terminó. |

### Compartir una observación

Usá la [encuesta de Patogen](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) o los [issues del repositorio](https://github.com/Code7C26/67Games/issues). Indicá mapa, cepas, equipo, acción intentada y qué ocurrió. Una captura ayuda a explicar problemas de lectura o controles.

### Versión de esta guía

La guía corresponde al código y escenas publicados del prototipo revisados el 06/11/2026. Los costos y tiempos pueden cambiar con el balance. Para cambios posteriores, consultá la [documentación actual](README.md) y el [README del juego](../README.md).
