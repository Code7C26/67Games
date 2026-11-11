# Rastreador

Sexta cepa jugable, disponible para ambos equipos en los tres mapas. Conserva el diseño v02 aprobado: nariz estrellada, manos de topo y orejas biológicas. Ahora cuenta con respiración, marcha y detección en las cuatro direcciones, desarrolladas a partir de ese diseño. Los PNG y la fuente Aseprite originales permanecen intactos como referencia.

## Instinto de caza

- Detecta sanos con un segmento despejado para el cuerpo completo. Paredes, muebles y piscinas bloquean la detección. Los humanos inmunes temporalmente o capturados por Garfio no se priorizan.
- Fija una presa y mantiene ese objetivo hasta que deja de ser válido o vence su memoria. El aislamiento solo favorece candidatos observados a distancias similares; no conoce multitudes ocultas.
- Actualiza la última posición conocida únicamente al confirmar una observación propia. Al perder contacto sigue el punto guardado, usando rutas físicas; no lee la posición actual oculta para mover el destino.
- Tras seis segundos sin confirmación abandona el rastro y vuelve a buscar. Infectar, eliminar o invalidar la presa permite elegir otra sin esperar ese plazo.

La selección de Rastreador evita exclusivamente la retención genérica de `npc_brain`, que puede seguir directamente un nodo objetivo. Las otras cepas conservan su selección anterior. Se reutilizan el planificador, la evasión y los obstáculos de los mapas importados. Shopping conserva sus rutinas locales y utiliza el mismo servicio `navegacion_simbionte.gd` para las rutas del Rastreador, con una cuadrícula compartida de radio conservador 19 px; no cambia la navegación de Simbionte ni la de otros huéspedes.

## Balance configurable

Editar `resources/rastreador_config.tres`, también accesible desde la propiedad Configuración Rastreador del Bot en el Inspector. La definición exportada está en `scripts/rastreador_config.gd`.

| Parámetro | Base |
| --- | --- |
| Multiplicador de detección | 1,75 |
| Memoria de persecución | 6 s |
| Reevaluación de candidatos | 1 s, adquisiciones iniciales escalonadas |
| Confirmación del objetivo actual | 0,20 s |
| Actualización de ruta recordada | 0,65 s |
| Velocidad | 100 % de la base: 75 px/s con Bot estándar |
| Probabilidad de contagio | 35 %, mediante el sistema de contacto existente |
| Probabilidad de curación natural | 1 % por segundo, sin resistencia extra |

El multiplicador usa el sensor real de cada arquitectura: **53 → 92,75 px en Shopping** y **240 → 420 px en Laboratorio/Pato Splash**. La forma compartida de AreaVision conserva su radio original. Temperatura, escudos, protección tras curación, robots, Coloso, Alfa y Simbionte mantienen sus reglas anteriores.

## Mejoras de ADN

Las tres ramas usan los espacios, teclas y costes existentes: 5/10/15 ADN por nivel. Los nuevos contagios heredan automáticamente la cepa y las mejoras de su dueño.

| Rama | Niveles |
| --- | --- |
| Olfato reforzado → Olfato agudo → Olfato superior | Rango normal ×2,0 / ×2,2 / ×2,4 |
| Fijación de presa → Memoria persistente → Rastro tenaz | 8 / 10 / 12 s de memoria |
| Instinto de manada → Rastro compartido → Caza coordinada | Hasta 2 / 3 / 4 Rastreadores aliados en 120 / 140 / 160 px |

Manada comunica un único punto observado cada dos segundos, con conexión local despejada. Solo lo reciben aliados sin una presa propia; conservan la edad del recuerdo y no reenvían informes. No cambia Alfa ni unidades especiales. Dado que la cepa del equipo se hereda en todos sus contagios ordinarios, los receptores habituales del equipo son Rastreadores. No hay comunicación global ni revelación de todos los humanos.

## Posesión y señales

El rastreo es **pasivo durante la posesión**. Se conservan todas las teclas y el jugador mantiene el movimiento; la IA no dirige al huésped poseído. No se añadió una acción de percepción ni un radar. Las señales se muestran exclusivamente sobre el infectado: chevrón al fijar, arco al buscar y marcas breves al agotar el rastro. Nunca se dibujan líneas o marcadores en coordenadas ocultas de la presa.

Se conservan el margen de transparencia, la escala y el borde cian/magenta compartidos. La reproducción visual usa la velocidad real del cuerpo después de moverse: un huésped bloqueado por una pared vuelve a reposo, mientras que uno que se desliza físicamente junto a ella continúa caminando.

Pausa y retención del reloj de tutorial congelan la memoria. Curación y cambio de cepa eliminan el componente; FIN limpia el rastro y las señales antes de pausar los resultados. El dibujo del infectado continúa siendo el sprite aprobado.

## Animaciones

`assets/rastreador/rastreador_animaciones.png` es un atlas de **256 × 192 px**, con ocho columnas y seis filas: 48 celdas transparentes de 32 × 32. Su fuente editable es `rastreador_animaciones.aseprite`; `rastreador.aseprite`, los cinco PNG de poses y la hoja original de aprobación se conservan sin cambios.

Cada dirección contiene 12 cuadros, en este orden: **Abajo, Arriba, Derecha, Izquierda**. Dentro de cada bloque hay cuatro cuadros de reposo, cuatro de marcha y cuatro de detección.

| Clips por dirección | Cuadros | Cadencia | Reproducción |
| --- | ---: | ---: | --- |
| `idle_*` | 4 | 4 fps, 250 ms por cuadro | Respiración en bucle |
| `caminar_*` | 4 | 8 fps, 125 ms por cuadro | Marcha en bucle |
| `detectar_*` | 4 | 10 fps, 100 ms por cuadro | Un gesto de 0,4 s |

`scripts/rastreador_arte.gd` comparte las texturas y SpriteFrames entre huéspedes. La orientación y el estado de detección se guardan por sprite. Repetir la actualización cada tick conserva la fase de la misma animación; detenerse mantiene la última orientación. La detección empieza solamente cuando se activa un evento nuevo y no se repite porque su señal siga activa. Si el huésped gira durante ese gesto, conserva su fase en la vista nueva.

Con **movimiento reducido**, el reposo se queda en su primer cuadro y el gesto de detección se omite; la marcha continúa animada para que el desplazamiento sea legible. Los aliases direccionales originales y `Detectar` siguen disponibles para las herramientas y la compatibilidad del proyecto.

## Verificación

Pruebas, métricas, capturas y límites de la integración jugable en `work/rastreador-integracion-nov06/VERIFICACION.md`. Las pruebas específicas son `test_rastreador.gd`, `test_rastreador_partida.gd` y `test_rastreador_rendimiento.gd`. Las capturas se generan con `capture_rastreador.gd` y `capture_rastreador_selector.gd`.

La verificación de reproducción está en `test_rastreador_animaciones.gd`; `capture_rastreador_animaciones.gd` registra cuadros reales del juego. La evidencia de esta etapa de animación se guarda por separado en `work/rastreador-animaciones-nov06/`.
