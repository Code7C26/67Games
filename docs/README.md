# Documentación de Patogen

La documentación describe el juego principal de [`pato-gen/`](../pato-gen/) y la versión publicada del repositorio. Patogen es un **juego de estrategia e infección para dos jugadores locales**. Las pruebas presenciales con parejas del curso indican que la mayoría de los beta testers se sintió cómoda con los controles y que los jugadores comprenden los controles y las mecánicas después de dos partidas. La única recomendación recibida fue agregar movimiento al mapa; esa mejora ya se incorporó.

## Estado del producto

- Los jugadores eligen entre Atlético, Área, Exponencial, Garfio, Camaleón y Rastreador, y compiten con los equipos cian y magenta.
- Se puede elegir Shopping, Laboratorio AV-07 o Pato Splash. Los mapas integrados usan 65 huéspedes jugables.
- La fase inicial de los patos dura 3 segundos; después de la transición comienza la infección de 120 segundos. El tutorial puede retener el reloj.
- Gana quien tenga más bots infectados al terminar. Si los conteos son iguales, hay empate técnico.
- Están implementados ADN, mutaciones por cepa, posesión, robot curador, distorsión, zona caliente, remontada, Simbionte, Coloso Antiviral, audio, tutorial y movimiento del mapa. Garfio captura y arrastra; Camaleón usa camuflaje y emboscadas; Rastreador recuerda presas y coordina aliados.
- `PatoGen-Windows.zip` contiene una build Windows de 64 bits. Se extrae y se abre `PatoGen.exe`; no hace falta instalar Godot. La prueba de la build en otra computadora no está registrada en el [issue #8](https://github.com/Code7C26/67Games/issues/8).
- El alcance actual es local. Patogen no incluye servidores, matchmaking, personalización cosmética ni compras de skins.
- La propuesta comercial es vender una licencia mediante un pago único. El repositorio no acredita una tienda activa, precio definido, ventas ni acuerdos de patrocinio.

## Documentos

| Documento | Contenido y alcance |
| --- | --- |
| [Guía del juego](../README.md) | Instalación, controles, reglas y mecánicas. |
| [Informe final Proyecto 2026](Proyecto%202026.docx) | Informe largo con lluvia de ideas, carátula TP50, resultados de pruebas, capturas actuales de los tres mapas y manual de usuario como anexo. |
| [Manual de usuario en español](Manual_de_Usuario.md) | Guía para abrir la build de Windows o el proyecto Godot, elegir cepa y jugar. Disponible en [Word](Manual%20de%20Usuario%20de%20Patogen.docx) y [PDF](Manual%20de%20Usuario%20de%20Patogen.pdf). |
| [User Manual in English](User_Manual.md) | English-language guide to installation, controls, strains, abilities, and match rules. Available in [Word](User%20Manual%20of%20Patogen.docx) and [PDF](User%20Manual%20of%20Patogen.pdf). |
| [Investigación de usuarios](INVESTIGACION_USUARIOS.md) | Mapas A y B basados en las pruebas presenciales, roles CUPID y resultados comunicados. |
| [Mapa A](Mapa_Empatia_A_resultados.png) | Mapa de empatía del jugador, basado en las pruebas presenciales y su devolución. |
| [Mapa B](Mapa_Empatia_B_resultados.png) | Mapa de empatía del equipo como actor interno y su respuesta a la devolución. |
| [CUPID](CUPID.docx) | Comprador, usuario, pagador, influenciador y decisor de la compra. |
| [FODA](FODA.md) | Análisis del juego y del equipo que incorpora la evidencia de las pruebas presenciales. |
| [Viabilidad comercial](Viabilidad_Comercial.md) | Fuente editable del informe de costos, monetización y propiedad intelectual. |
| [Informe comercial en PDF](Trabajo%20Viabilidad%20Comercial.pdf) | Exportación anterior; las estimaciones históricas se mantienen identificadas como tales. |
| [Encuesta](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831) | Instrumento de preferencias generales, distinto de las pruebas presenciales del juego. |

## Resultados de las pruebas presenciales

Las pruebas se realizaron con parejas del curso. La mayoría de los beta testers dijo que los controles les resultaban cómodos. Después de dos partidas, los jugadores comprendían los controles y las mecánicas. La única recomendación fue agregar movimiento al mapa; el equipo incorporó esa mejora aproximadamente un mes después.

La encuesta enlazada arriba es otra fuente: reúne preferencias generales y no registra por sí sola el mapa, las cepas ni el desempeño de cada partida. No se atribuyen a la encuesta los resultados de las pruebas presenciales.

## Evidencia técnica

Las reglas se contrastan con [`Mapa.gd`](../pato-gen/scripts/Mapa.gd), [`Pato.gd`](../pato-gen/scripts/Pato.gd), [`character_select.gd`](../pato-gen/scripts/character_select.gd), [`map_select.gd`](../pato-gen/scripts/map_select.gd), las escenas integradas y [MAPAS_INTEGRADOS.md](../pato-gen/docs/MAPAS_INTEGRADOS.md). Las reglas de las cepas se describen en [Camaleón](../pato-gen/docs/CAMALEON.md), [Garfio y Rastreador](../pato-gen/docs/MUTACIONES_GARFIO_RASTREADOR.md) y [Rastreador](../pato-gen/docs/RASTREADOR.md). Los resultados de las pruebas de juego de esta documentación corresponden a la devolución aportada por el equipo de Patogen.

Las notas de demos, pruebas anteriores y ZIP independientes conservan su contexto histórico. Para describir el producto actual se toma como referencia `pato-gen/`.
