# Documentación de Patogen

Revisión del **06/11/2026**, basada en el juego principal de [`pato-gen/`](../pato-gen/) y en la versión publicada del repositorio. Patogen es un **prototipo jugable de estrategia e infección para dos jugadores locales**. El balance con personas, la exportación distribuible y la validación comercial siguen pendientes.

## Estado del producto

- Los jugadores eligen entre Atlético, Área y Exponencial, y compiten con las cepas cian y magenta.
- Se puede elegir Shopping, Laboratorio AV-07 o Pato Splash. Los mapas integrados usan 65 huéspedes jugables.
- La fase inicial de los patos dura 3 segundos; después de la transición comienza la infección de 120 segundos. El tutorial puede retener el reloj.
- Gana quien tenga más bots infectados al terminar. Si los conteos son iguales, hay empate técnico.
- Están implementados ADN, mutaciones, posesión, robot curador, distorsión, zona caliente, remontada, Simbionte, Coloso Antiviral, audio y tutorial.
- El alcance actual es local. No se debe presentar al prototipo como un juego con servidores, matchmaking, personalización cosmética o compras de skins.
- La propuesta comercial es vender una licencia mediante un pago único. Es una decisión de planificación: el repo no acredita una tienda activa, precio validado, ventas ni acuerdos de patrocinio.

## Documentos

| Documento | Contenido y alcance |
| --- | --- |
| [Guía del juego](../README.md) | Instalación, controles, reglas, mecánicas y pendientes técnicos. |
| [Investigación de usuarios](INVESTIGACION_USUARIOS.md) | Fuente editable de los mapas A y B, roles CUPID y preguntas pendientes de validación. |
| [Mapa A](Mapa_Empatia_A.png) | Perfil provisional del jugador de partidas locales. |
| [Mapa B](Mapa_Empatia_B.png) | Perspectiva provisional del equipo, identificado como actor interno. |
| [CUPID](CUPID.docx) | Comprador, usuario, pagador, influenciador y decisor de la compra. |
| [FODA](FODA.md) | Fuente editable de los análisis del juego y del equipo; distingue capacidades de riesgos e hipótesis. |
| [Viabilidad comercial](Viabilidad_Comercial.md) | Fuente editable del informe de costos, monetización y propiedad intelectual. |
| [Informe comercial en PDF](Trabajo%20Viabilidad%20Comercial.pdf) | Versión para lectura y entrega. Las estimaciones históricas se identifican como tales. |
| [Encuesta](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) | Instrumento para investigar el público; el enlace por sí solo no valida los perfiles. |

## Cómo interpretar la investigación

Los mapas de empatía describen hipótesis de necesidades y motivaciones. No son testimonios ni resultados de una encuesta. La presencia de un tutorial o de pruebas automáticas tampoco demuestra que la curva de aprendizaje y el balance ya estén resueltos.

Para validar los perfiles, registrar comprensión de las reglas y los controles, dificultades de lectura de la partida, intención de repetir y disposición a pagar. Separar las respuestas de jugadores de las opiniones del equipo y documentar fecha, participantes y método.

## Evidencia técnica

Las reglas se contrastaron con [`Mapa.gd`](../pato-gen/scripts/Mapa.gd), [`Pato.gd`](../pato-gen/scripts/Pato.gd), [`map_select.gd`](../pato-gen/scripts/map_select.gd), [`integrated_map.gd`](../pato-gen/scripts/integrated_map.gd), las escenas integradas y [MAPAS_INTEGRADOS.md](../pato-gen/docs/MAPAS_INTEGRADOS.md). Esta revisión documental no vuelve a ejecutar las suites ni reemplaza un playtest.

Las notas de demos, pruebas anteriores y ZIP independientes conservan su contexto histórico. Para describir el producto actual se toma como referencia `pato-gen/`.
