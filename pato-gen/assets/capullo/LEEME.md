# Capullo del simbionte — 32x32

Diseño aprobado: versión oscura y orgánica del 28/10/2026.
Animación e integración: 29/10/2026, sobre la versión con selector de mapas.
Fuente editable: capullo.aseprite, dibujada mediante el MCP de Aseprite.
capullo_sheet.png contiene 24 cuadros transparentes de 32x32, sin recorte ni
separación, en una hoja horizontal de 768x32. capullo.json conserva sus tiempos.

| Animación | Cuadros (desde 1) | Disparador |
| --- | --- | --- |
| reposo | 1–4 | Respiración mientras espera ADN |
| inversion | 5–8 | Un pago aceptado de ADN |
| inquieto | 9–12 | Al alcanzar el 75% de la inversión requerida |
| eclosion | 13–18 | Ganar la carrera del simbionte |
| marchitar | 19–24 | El equipo rival gana la carrera |

Las raíces permanecen apoyadas durante el reposo. La envoltura se contrae,
se hincha y abre dos lóbulos antes de licuarse. Los fragmentos separados en
la eclosión son intencionales. Las venas mantienen colores apagados; cada
equipo recibe su propio ShaderMaterial. El shader admite el renderizador
Mobile con HDR 2D del proyecto y conserva la piel oscura.

La escena compartida scenes/capullo.tscn funciona en Shopping, Laboratorio
AV-07 y Pato Splash, incluyendo sus ubicaciones aleatorias. Mapa.gd comunica
los pagos aceptados y el ganador. El nacimiento del viajero y el cobro siguen
ocurriendo inmediatamente: las animaciones finales son objetos visuales hijos
del mapa que se eliminan al concluir y se liberan al cambiar de escena.
El nodo original del capullo se elimina en el mismo momento que antes.

La pausa del árbol detiene las animaciones. Durante infección, el reloj retenido
por el tutorial también las detiene. El reposo puede seguir durante preparación.
La animación no concede ADN, no decide ganadores y no altera la navegación.

Recursos: resources/animations/capullo.tres, scripts/aspecto_capullo.gd,
scripts/capullo.gd y shaders/capullo.gdshader.
Si se reordena la fuente o se cambian sus tiempos, actualizar SpriteFrames
al volver a exportar la hoja horizontal sin trim.

Pruebas: tests/test_capullo_animado.gd (46 comprobaciones en los tres mapas,
también ejecutadas con Vulkan Mobile), tests/test_simbionte.gd (94) y
tests/test_map_flow.gd (selector, reinicio y menú en los tres mapas).
Las capturas de tests/run_data/capullo convierten la lectura HDR lineal a sRGB
antes de guardarla como PNG. Las copias previas, los logs y las vistas GIF están
en work/capullo-integracion, fuera del proyecto.
