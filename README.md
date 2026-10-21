# Patogen

> Videojuego 2D competitivo de infección y estrategia, desarrollado en Godot 4. Dos jugadores enfrentan sus cepas —**cian** y **magenta**— para expandir sus contagios, administrar ADN y usar habilidades sobre una población de bots que intenta sobrevivir.

![Estado](https://img.shields.io/badge/Estado-Prototipo%20jugable-orange)
![Motor](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/Lenguaje-GDScript-478CBF)

## Cómo ejecutar el proyecto

1. Instalar [Godot Engine 4.7](https://godotengine.org/download/) (o una versión compatible).
2. Clonar este repositorio:

   ```bash
   git clone https://github.com/Code7C26/67Games.git
   ```

3. Abrir Godot y seleccionar **Importar**.
4. Elegir el archivo **`pato-gen/project.godot`**, correspondiente al **juego principal**.
5. Abrir el proyecto importado y presionar **F5** para ejecutarlo.

**Al iniciar el juego se muestra el menú principal.** Desde allí se accede al flujo de preparación e inicio de la partida. **F6** ejecuta únicamente la escena abierta en el editor, por lo que puede mostrar una pantalla diferente.

> **Importante:** `design/mapa-patogen/project.godot` es el proyecto del **mapa/prototipo de integración**; no debe confundirse con el punto de entrada del juego principal.

### Flujo de una partida

1. **Menú principal:** pantalla inicial del juego, desde la cual se inicia el recorrido hacia la partida.
2. **Preparación:** existe una pantalla de prepartida destinada a seleccionar el tipo de infectado de cada cepa. La integración completa de sus opciones, estadísticas y mutaciones continúa en desarrollo.
3. **Paciente Cero:** durante los primeros **15 segundos**, se controla al personaje inicial (*Pato*).
4. **Primera infección:** al terminar ese tiempo, Pato deja de moverse, reproduce una animación de desaparición y contagia al bot sano más cercano.
5. **Expansión de las cepas:** los bots infectados persiguen a los sanos; los jugadores compiten por aumentar sus contagios, conseguir ADN y aprovechar habilidades y zonas.
6. **Evolución de la partida:** el marcador de infectados y la disponibilidad de bots sanos condicionan las estrategias, especialmente en las fases avanzadas.

El objetivo estratégico es **expandir la propia cepa y superar la presencia de la rival**. Los criterios exactos de finalización y victoria todavía no están documentados aquí porque no se dispone de su configuración actual.

### Controles

PatoGen está diseñado para **dos jugadores locales**, identificados por las cepas **cian** y **magenta**. Los controles se organizan por jugador y por tipo de acción: **movimiento**, **mejoras**, **habilidades** y **zonas**.

> **Estado de las teclas:** en los archivos disponibles no aparecen las asignaciones del juego principal para cada cepa. El movimiento con `WASD` y flechas está documentado **para el prototipo del mapa**, pero no se puede asegurar qué grupo pertenece a cian o magenta durante la partida. Se indican por separado las acciones que deben comprobarse, sin presentar teclas inventadas como funcionales.

#### Jugador cian

| Categoría | Acción | Tecla en el juego principal |
| --- | --- | --- |
| Movimiento | Arriba | **Por confirmar** (`W` en el prototipo del mapa) |
| Movimiento | Abajo | **Por confirmar** (`S` en el prototipo del mapa) |
| Movimiento | Izquierda | **Por confirmar** (`A` en el prototipo del mapa) |
| Movimiento | Derecha | **Por confirmar** (`D` en el prototipo del mapa) |
| Mejoras | Comprar o activar mejoras de la cepa cian | **Por confirmar** |
| Mejoras | Cambiar entre los tres paneles de mutaciones cian | Flechas **de la interfaz** (tecla física por confirmar) |
| Habilidad | Posesión | **Por confirmar** |
| Habilidad | Robot | **Por confirmar** |
| Zona | Colocar o activar zona caliente | **Por confirmar** |
| Zona | Colocar o activar zona fría, si continúa disponible | **Por confirmar** |
| Zona | Zona de distorsión | **Sin tecla confirmada; funcionalidad en desarrollo** |

#### Jugador magenta

| Categoría | Acción | Tecla en el juego principal |
| --- | --- | --- |
| Movimiento | Arriba | **Por confirmar** (`↑` en el prototipo del mapa) |
| Movimiento | Abajo | **Por confirmar** (`↓` en el prototipo del mapa) |
| Movimiento | Izquierda | **Por confirmar** (`←` en el prototipo del mapa) |
| Movimiento | Derecha | **Por confirmar** (`→` en el prototipo del mapa) |
| Mejoras | Comprar o activar mejoras de la cepa magenta | **Por confirmar** |
| Mejoras | Cambiar entre los tres paneles de mutaciones magenta | Flechas **de la interfaz** (tecla física por confirmar) |
| Habilidad | Posesión | **Por confirmar** |
| Habilidad | Robot | **Por confirmar** |
| Zona | Colocar o activar zona caliente | **Por confirmar** |
| Zona | Colocar o activar zona fría, si continúa disponible | **Por confirmar** |
| Zona | Zona de distorsión | **Sin tecla confirmada; funcionalidad en desarrollo** |

**Mejoras y mutaciones:** el menú de cian está organizado en `VBoxContainer1`, `VBoxContainer2` y `VBoxContainer3`; el de magenta en `VBoxContainer4`, `VBoxContainer5` y `VBoxContainer6`. Estos son **paneles de interfaz**, no teclas del teclado. No se ha comprobado qué teclas ejecutan cada mejora ni si la selección se realiza exclusivamente con botones.

#### Controles comunes y del editor

| Contexto | Acción | Control |
| --- | --- | --- |
| Menú principal y prepartida | Elegir opciones y tipo de infectado | Botones de la interfaz |
| Editor de Godot | Iniciar el juego completo desde el menú principal | `F5` |
| Editor de Godot | Ejecutar únicamente la escena abierta | `F6` |

**Cómo confirmar las teclas pendientes:** abrir `pato-gen/project.godot` con Godot y consultar **Proyecto → Configuración del proyecto → Mapa de entrada**. Revisar también los scripts que procesan controles (por ejemplo, `Input.is_key_pressed()`, `Input.is_action_pressed()` y `_input()`), porque pueden usar teclas directamente sin declararlas en el Mapa de entrada. Una vez verificadas, sustituir las celdas **«Por confirmar»** por la tecla real de cada cepa.

## Funciones y mecánicas del juego

### Competencia entre dos cepas

- Cada jugador representa una cepa diferenciada visualmente: **cian** o **magenta**.
- Los bots infectados pertenecen a una cepa, permitiendo comparar su presencia mediante un **marcador de infectados**.
- El recurso **ADN** forma parte de la estrategia y está vinculado a los nuevos contagios.
- La disponibilidad de bots sanos es importante: cuando escasean, resulta más difícil seguir contagiando y obteniendo ADN.

### Paciente Cero

- El personaje **Pato** es controlable durante los **15 segundos iniciales**.
- Al agotarse el tiempo, se bloquea su movimiento y se reproduce la animación **`desaparecer`**, sin repetición.
- Al finalizar la animación, infecta al bot sano más cercano y el personaje inicial deja la escena.
- Esta transición da paso al protagonismo de los bots y a la propagación de la infección.

### Bots, inteligencia artificial y contagio

| Estado | Comportamiento |
| --- | --- |
| **Sano** | Se desplaza de forma autónoma, cambia de dirección y huye de los infectados que detecta en su área de visión. |
| **Infectado** | Busca y persigue bots sanos para extender la cepa a la que pertenece. |
| **Curado** | Vuelve al estado sano y puede recibir protección temporal frente a nuevos contagios. |

- Los bots utilizan áreas de **visión** y **contagio** para detectar objetivos e interactuar.
- El sistema revisa posibles contagios de forma periódica (en la implementación documentada, cada **0,5 segundos**) y aplica una **probabilidad configurable**.
- La curación se evalúa periódicamente (en la implementación documentada, cada **1 segundo**).
- Existe un **escudo temporal** de protección frente a nuevas infecciones después de la recuperación.
- Los bots admiten distintos **sprites y animaciones**, además de parámetros modificables de velocidad, curación y contagio.

### ADN, habilidades y zonas

El ADN y los tiempos de reutilización (*cooldowns*) obligan a decidir **cuándo conviene activar cada recurso**, no solo a contagiar más bots.

| Mecánica | Función dentro del juego | Estado documentado |
| --- | --- | --- |
| **Posesión** | Habilidad activa que aporta intervención directa sobre la partida. | Presente en el desarrollo, con cooldown. |
| **Robot** | Recurso especial que permite otra forma de intervención durante la partida. | Presente en el desarrollo, con cooldown. |
| **Zona caliente** | Zona ambiental con efectos sobre las condiciones de los bots, relacionadas con la temperatura. | Funcional y con representación visual animada. |
| **Zona fría** | Segunda clase de zona ambiental; su utilidad táctica está siendo reconsiderada. | En revisión de diseño. |
| **Zona de distorsión** | Propuesta de zona de control que **atraiga bots sanos** para influir en su movimiento. | Propuesta en desarrollo; no se presenta como integrada. |

Los sistemas de temperatura contemplan modificadores de **velocidad** y **contagio**. Sus valores concretos pueden variar según el balance de cada versión.

### Tipos de infectado, mutaciones y aspectos visuales

- El diseño contempla **tipos de infectado con estilos distintos** y **especializaciones permanentes por tipo**, en lugar de limitar toda la progresión a tres mutaciones universales.
- La pantalla de prepartida permite preparar la selección de tipo, mientras continúa la integración de sus **estadísticas base**, mutaciones y menús.
- Se están organizando **tres paneles de mutaciones por cepa**: `VBoxContainer1` a `VBoxContainer3` para cian y `VBoxContainer4` a `VBoxContainer6` para magenta.
- Se crearon sprites específicos para los infectados de cada cepa. Su asignación automática al infectarse y la recuperación del sprite de bot sano al curarse forman parte del trabajo de integración visual.

### Interfaz, música y efectos

- **Menú principal** como pantalla de entrada del juego.
- **Pantalla de prepartida**, menús de mutaciones e interfaz para diferenciar a ambos jugadores.
- **Marcador**, **ADN** y visualización de habilidades con sus tiempos de reutilización.
- **Música del menú** incorporada durante el desarrollo; la transición a la **música de partida** y la integración general de **efectos sonoros** están en proceso.
- El proyecto principal declara un autoload llamado **`AudioManager`** para gestionar el audio.

## Estado técnico actual

El proyecto se encuentra en etapa de **prototipo jugable de infección competitiva**. Los siguientes sistemas forman parte del desarrollo documentado:

- **Lógica de bots** con movimiento autónomo, persecución, huida, infección y curación.
- **Paciente Cero** y su transición automática al primer contagio.
- **Dos cepas**, recuento de infectados y sistema de ADN.
- **Habilidades** de posesión, robot y zona caliente, con cooldowns.
- **Zonas ambientales animadas** y multiplicadores que afectan el comportamiento de los bots.
- **Menús** principal y de preparación, con integración progresiva de mutaciones.
- **Recursos gráficos** de bots sanos e infectados y **recursos sonoros** del equipo.
- **Mapa Patogen Mall:** escenario 2D de centro comercial con 13 locales, atrio central, mezzanine, colisiones y áreas diferenciadas.

### Pendiente

- Finalizar y comprobar las **mutaciones**, **especializaciones por tipo**, estadísticas y navegación entre sus paneles.
- Completar la aplicación de los **sprites de infectados por cepa** y el retorno al aspecto sano tras la curación.
- Desarrollar y equilibrar la **zona de distorsión** si finalmente sustituye o complementa a la zona fría.
- Ajustar el **balance de partida avanzada**: se propuso otorgar **1 ADN por segundo** al jugador que vaya perdiendo por una diferencia de **5 o más infectados**; su integración efectiva debe verificarse en código.
- Terminar la **música de partida**, las transiciones musicales y la conexión de los **efectos de sonido** con las acciones correspondientes.
- Verificar y completar las **teclas definitivas por jugador** para movimiento, mejoras, posesión, robot y zonas; las acciones ya están separadas en las tablas de controles.
- Confirmar y describir las **condiciones de victoria, derrota y fin de partida**.
- Continuar con las pruebas, la corrección de errores, el balance general y las **exportaciones jugables**.

## Estructura del repositorio

```text
assets/                         Recursos gráficos y sonoros del equipo
  Sprites Pato/                 Sprites del personaje inicial
  Sprites NPC/                  Sprites de bots y personajes
  Sonidos/                      Música y efectos de sonido
design/mapa-patogen/            Proyecto de mapa e integración de Godot
  project.godot                 Configuración del prototipo del mapa
  main.tscn                     Escena principal del prototipo del mapa
  PatogenMall_MapOnly.tscn      Mapa integrable en otras escenas
  scripts/                      Lógica del mapa, personajes y visuales
  Art/                          Tiles y recursos del escenario
  MAP_INTEGRATION.md            Guía de integración del mapa
pato-gen/                       Proyecto principal del videojuego
  project.godot                 Configuración del juego que se debe importar
src/                            Otros archivos fuente del repositorio
docs/                           Documentación y material de diseño
README.md                       Presentación y guía del proyecto
```

## Integración del mapa

Para utilizar solamente el escenario en otra escena de Godot, se puede instanciar `design/mapa-patogen/PatogenMall_MapOnly.tscn`. Esta escena está pensada para incorporar el escenario **sin crear automáticamente jugadores, bots ni HUD**; mantiene las colisiones, zonas y marcadores del mapa.

Las zonas de este prototipo de mapa se agrupan bajo `patogen_condition_zone` y exponen los metadatos `zone_id`, `zone_type` e `intensity`. La guía técnica se encuentra en [`design/mapa-patogen/MAP_INTEGRATION.md`](design/mapa-patogen/MAP_INTEGRATION.md).

## Tecnologías

- **Godot Engine 4.7**.
- **GDScript** para la lógica del juego.
- **Godot 2D** para el movimiento, las colisiones, la inteligencia artificial y la interfaz.
- **Git y GitHub** para el control de versiones y la colaboración.

## Autoría

Proyecto desarrollado de forma colaborativa por el equipo **67Games**.
