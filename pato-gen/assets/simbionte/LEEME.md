# Simbionte 32x32

Fuente editable: `simbionte.aseprite`, dibujada y exportada con el MCP de Aseprite.
Hoja horizontal transparente: `simbionte_sheet.png`, 1664x32, 52 cuadros sin recortar.
Metadatos: `simbionte.json`, con etiquetas y duraciones de Aseprite.

| Etiqueta | Cuadros (desde 1) | Uso |
| --- | --- | --- |
| reposo_Abajo | 1–4 | Respiración, pies fijos |
| caminar_Abajo | 5–10 | Marcha frontal |
| reposo_Arriba | 11–14 | Respiración de espaldas |
| caminar_Arriba | 15–20 | Marcha de espaldas |
| reposo_Derecha | 21–24 | Respiración de perfil |
| caminar_Derecha | 25–30 | Marcha de perfil |
| reposo_Izquierda | 31–34 | Respiración de perfil |
| caminar_Izquierda | 35–40 | Marcha de perfil |
| eclosion | 41–46 | De baba a cuerpo |
| fusion | 47–52 | Cuerpo a baba; se reproduce al revés al cubrir al anfitrión |

Cada cuadro conserva el lienzo 32x32 y el pivote central. La paleta oscura azulada,
el contorno, las proporciones y la luz superior se adaptan a los personajes del juego.
Los ojos claros, la mandíbula, las garras, el manto rojizo y los tentáculos toman
elementos de las referencias. Las venas usan cian #42c7c8; el shader las cambia
a magenta #e489ce para el segundo equipo sin teñir ojos ni cuerpo.

`resources/animations/simbionte.tres` refleja los cuadros y tiempos de la fuente.
`scripts/aspecto_simbionte.gd` selecciona dirección, reposo, marcha y transiciones;
usa filtro nearest y detiene la animación cuando el reloj de partida está retenido.
El viajero y el anfitrión comparten esta presentación. Al terminar el efecto se
restaura la visibilidad anterior del NPC; su skin y material de infección se mantienen
en su AnimatedSprite2D original. Las reglas de contacto, duración y bonificaciones
siguen en los componentes existentes.

Para editar: conservar 32x32, etiquetas y orden al exportar horizontalmente, sin
padding ni trim. Si se agregan cuadros o cambian los tiempos, actualizar también
el recurso SpriteFrames.

Validación: `tests/test_simbionte_sprite.gd` comprueba los cuadros, las direcciones,
el avance real de las animaciones, la pausa, la transformación, los colores por equipo
y la restauración al expirar, curarse o retirarse el componente. Con renderizado
guarda capturas del mapa en `tests/run_data/simbionte_sprite/`.
La suite existente `tests/test_simbionte.gd` verifica la mecánica.

En `work/simbionte-sprite/`, fuera del proyecto, quedan los originales previos,
las poses de autoría, los logs y la vista GIF ampliada.
