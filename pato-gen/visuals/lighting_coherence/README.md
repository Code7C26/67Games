# Recursos de iluminación y orientación

Creados con el MCP de Aseprite para la revisión de iluminación del 28/10/2026.

- `ceiling_fixture.aseprite` / PNG: referencia opcional de luminaria, 32×12 px; oculta en el juego por defecto. Sólo se ve la iluminación que genera.
- `ambient_mote.aseprite` / PNG: partícula ambiental, 8×8 px.
- `lab_backviews/`: seis vistas posteriores, con las dimensiones y la paleta del equipo original. Las fuentes originales se abrieron como referencia y no se guardaron ni editaron.

Las vistas posteriores muestran carcasas de servicio, rejillas y conductos. No son una inversión vertical de las caras delanteras. El controlador del Lab las aplica únicamente a equipos del borde sur, conservando transformaciones y colisiones.

Todos los PNG usan filtro nearest en el proyecto. Los parámetros de luminarias, motas y el umbral de orientación son exportables desde sus scripts.
