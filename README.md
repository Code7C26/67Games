# Patogen

> Prototipo de videojuego 2D en Godot donde el jugador recorre un centro comercial diseñado para futuras mecánicas de propagación y condiciones ambientales.

![Estado](https://img.shields.io/badge/Estado-Prototipo%20jugable-orange)
![Motor](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/Lenguaje-GDScript-478CBF)

## Cómo ejecutar el proyecto

1. Instalar [Godot Engine 4.7](https://godotengine.org/download/), o una versión 4.x compatible.
2. Clonar este repositorio:

   ```bash
   git clone https://github.com/Code7C26/67Games.git
   ```

3. Abrir Godot y seleccionar **Importar**.
4. Elegir el archivo `design/mapa-patogen/project.godot`.
5. Abrir el proyecto importado y presionar **F6** para ejecutar la escena actual o **F5** para ejecutar el proyecto completo.

Al iniciar, se carga la escena principal `main.tscn` del mapa Patogen Mall.

### Controles

| Acción | Teclas |
| --- | --- |
| Mover a la izquierda | `A` o flecha izquierda |
| Mover a la derecha | `D` o flecha derecha |
| Mover hacia arriba | `W` o flecha arriba |
| Mover hacia abajo | `S` o flecha abajo |

## Estado técnico actual

El proyecto se encuentra en etapa de **prototipo jugable de mapa e integración**. Actualmente incluye:

- Mapa 2D de un centro comercial con 13 locales, atrio central y mezzanine.
- Personaje temporal controlable con movimiento en ocho direcciones y cámara con límites del mapa.
- Colisiones generadas por código para paredes, locales, puertas, mobiliario, fuente y barandas.
- Accesos transitables en Cinema, Arcade, Market, Café y Sports.
- Seis zonas de condición para futuras mecánicas de Patogen:
  - **Hot:** Food Court, Arcade y Atrium.
  - **Cold:** Market, Cinema y Mezzanine.
- Marcadores de navegación estables para incorporar la IA de NPCs en una siguiente etapa.
- Sprites de personaje y NPC disponibles en `assets/`.

### Pendiente

- Integrar el personaje definitivo, sus animaciones y las mecánicas principales del equipo.
- Conectar las zonas hot/cold con el sistema de propagación del juego.
- Implementar navegación y comportamiento de los NPCs.
- Añadir interfaz, objetivos, condiciones de victoria y derrota, y exportaciones jugables.

## Estructura del repositorio

```text
assets/                         Recursos gráficos del equipo
  Sprites Pato/                 Sprites del personaje
  Sprites NPC/                  Sprites de NPC
design/mapa-patogen/            Proyecto ejecutable de Godot
  project.godot                 Configuración del proyecto
  main.tscn                     Escena principal del prototipo
  PatogenMall_MapOnly.tscn      Mapa listo para integrar en otra escena
  scripts/                      Lógica del mapa, jugador y visuales
  Art/                          Tiles y recursos del mapa
  MAP_INTEGRATION.md            Guía de integración del mapa
docs/                           Documentación y material de diseño
```

## Integración del mapa

Para incorporar solamente el escenario en otra escena de Godot, instanciar `design/mapa-patogen/PatogenMall_MapOnly.tscn`. Esta escena no crea jugador, bots ni HUD; conserva las colisiones, zonas y marcadores que necesita el proyecto principal.

Las zonas se agrupan bajo `patogen_condition_zone` y exponen los metadatos `zone_id`, `zone_type` e `intensity`. La guía técnica completa está en [`design/mapa-patogen/MAP_INTEGRATION.md`](design/mapa-patogen/MAP_INTEGRATION.md).

## Tecnologías

- Godot Engine 4.7 (Forward Plus)
- GDScript
- Git y GitHub

## Autoría

Proyecto desarrollado de forma colaborativa por el equipo 67Games.
