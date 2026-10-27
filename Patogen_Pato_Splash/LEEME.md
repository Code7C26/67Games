# Patogen · Pato Splash

Primera versión explorable del parque acuático, creada con los MCP de **Aseprite y Godot**. Agua celeste, geometría estable y un único evento principal: el gran chapuzón.

**Parte 5 vigente:** guardavidas, reposeras ocupadas, pelota, limpieza, fotografía, heladería, vestuarios y pasajeros de toboganes. Tres reacciones configurables a infección, atardecer sutil, libélulas, logo y huellas. **75 fuentes Aseprite** y catálogo completo en **`scenes/asset_showcase.tscn`** (F6). Documentación: [PARTE5_VIDA_Y_CATALOGO.md](docs/PARTE5_VIDA_Y_CATALOGO.md). **I** prueba las reacciones sin modificar el sistema real de contagio.

**Actualización vigente · giro de 360°:** el pato central gira erguido con 16 vistas y reparte **24 impactos: tres en cada uno de los ocho sectores** del parque. Menos gotas, géiser breve y coronas de agua celestes con cresta blanca escalonada, inspiradas en la referencia suministrada. Los NPCs siguen sus recorridos; los alcanzados se empapan y corren o se cubren. Infección `Neutro` por defecto, con hooks `Limpiar` / `Propagar`. Documentación: [GIRO360_CORONA.md](docs/GIRO360_CORONA.md). Vista animada: [giro360_chapuzon.gif](captures/giro360_chapuzon.gif).

**Última revisión · fuente, nubes e inflable:** Press Start 2P del ZIP suministrado aplicada al mapa y la interfaz, sombras de nubes visibles desde el inicio y pato central redibujado en Aseprite. Vista vigente: `captures/revision_visual_1920x1080.png`. Comparación del inflable: `captures/pato_central_antes_despues.png` (anterior a la izquierda, nuevo a la derecha). Archivos y comprobaciones: `docs/REVISION_FUENTE_NUBES_PATO.md`. Las capturas y cifras de las partes anteriores son históricas.

**Actualización · parte 3 de 5 (ambiente):** destellos de agua, sombras suaves de nubes, palmeras con hojas ocasionales, banderas, ventiladores, flotantes con deriva, fuente pulsante, sombrillas y letrero de heladería animados. Velocidad e intensidad editables en `08_Ambiente`, pausa compartida y colisiones intactas. Detalles de efectos/rendimiento en `docs/PARTE3_AMBIENTE.md`; vista animada en `captures/parte3_ambiente.gif`.

**Actualización · parte 2 de 5 (mapa y sprites):** paseo conectado de 383 tiles con terrenos nativos, diez canteros de 2×2 tiles, ocho carteles y más equipamiento del parque. Toboganes, balde, fuente, reposera y pato del parque revisados en Aseprite; 43 fuentes con una paleta compartida de 37 colores ya existentes. Detalles y pruebas actuales en `docs/PARTE2_MAPA_SPRITES.md`; capturas en `captures/parte2_1920x1080.png` y `captures/parte2_assets.png`.

**Actualización · parte 1 de 5 (bugs):** dos caídas de agua independientes en los toboganes, cuatro escaleras ancladas al borde, patos controlables a 64×64 px e inflable a 240×216 px. Vista inicial a 1920×1080 con Nearest. Detalles, archivos y backup en `docs/PARTE1_BUGS.md`; captura actual en `captures/parte1_1920x1080.png`.

## Abrir

Importar `project.godot` en Godot 4.7.1 y pulsar **F5**. La escena inicial es `demo/PatoSplashDemo.tscn`. El mapa editable es `splash/scenes/PatoSplash.tscn`.

- **WASD / flechas:** recorrer el parque con los dos patos.
- **E** o botón «Ver chapuzón»: adelantar el aviso del cañón; conserva 1,5 s de anticipación.
- **Espacio:** pausar/reanudar todo el parque.
- **Tab:** catálogo animado de NPC; pausa el parque mientras está abierto.
- **R:** activar/desactivar la vibración de cámara.
- **M:** activar/desactivar el sonido.
- **H:** mostrar/ocultar interfaz.
- **F11:** pantalla completa. **Esc:** cerrar catálogo o salir de pantalla completa.

## Contenido

- Cuatro piletas de agua celeste; pato inflable gigante, toboganes dobles, balde, fuente hongo y flotadores.
- Reposeras, sombrillas, heladería, vestuarios en una construcción baja con tres cabinas de puertas dobles de madera tipo saloon y lockers empotrados, sillas de salvavidas, palmeras, banderines, filtros, mesas, bancos y papeleras. Duchas y casilleros independientes también incluidos como assets reutilizables.
- **69 objetos colocados**, además de las piletas, los pisos y la señalética general. Incluye ocho carteles de piso mojado/no pisar. Escenas de objetos reutilizables en `splash/scenes/objetos`.
- Paseos de **32 px** en `07_Caminos`, con `TileMapLayer`, atlas de 16 variantes y terrenos de conexión lateral. Las diez palmeras tienen canteros de tierra de **64×64 px**, borde de ladrillos de cemento y una única colisión por cantero.
- Agua, pato, toboganes, sombrillas, palmeras, toldo, duchas, flotadores, banderines, ventiladores y fuente animados. La descarga actual sale del pato central; el balde permanece estático.
- **9 skins de NPC:** 3 bañadores, 3 salvavidas y 3 staff. Cada una conserva las cuatro direcciones y los 12 cuadros de marcha originales: **108 cuadros adaptados**. Siluetas y rasgos conservados; sus colores se unificaron a la paleta compartida, sin alterar el canal alfa.
- **75 fuentes `.aseprite`**, hojas **PNG**, metadatos **JSON**, recursos **SpriteFrames `.tres`** y paleta editable `splash/assets/patogen_paleta.gpl`. Los 18 assets de parte 5 usan los mismos 37 colores y conservan intactas las 57 fuentes anteriores.
- Revisión artística: inflable con contornos escalonados, pico ancho y ala angular; materiales de madera, tela, metal y cerámica. El nuevo `pato_parque` usa el jugador como base y sus once colores originales, con alas/detalles de chaleco y 32 cuadros en cuatro direcciones; se muestra a escala entera 2× conservando la colisión.
- Demo con **70 NPCs** (54 visitantes + 16 personajes de ambiente), dos patos controlables y audio original sintetizado para agua, aviso y descarga.

## Evento

El ciclo normal dura **34 segundos**: 30 de calma, 1,5 de aviso, 1,5 de disparo y 1 de cierre. El chorro empieza a los 31,5 s; las gotas tardan 0,8 s en alcanzar los destinos repartidos por el parque. Los charcos duran 10 s y no alargan el evento. Sacudida inicial de 9 px con decay de 0,6 s, más 1,4 px durante el chorro. Todo es configurable y se puede desactivar la vibración con R.

Los visitantes mantienen sus recorridos, sin convocatoria al centro. Los alcanzados por el agua quedan empapados durante 6 s y reaccionan durante 1,5 s. Los impactos se reparten por igual entre ocho sectores, sin consultar equipo ni infección. Los caminos y las colisiones permanecen fijos. La política de infección predeterminada es neutra; las otras dos opciones emiten un hook para que el juego real decida la modificación.

## Alcance

Esta entrega es el **mapa y su demo de circulación**, con el controlador de evento listo para conectar. **No incorpora una partida completa con infección, mutaciones o robots de Patogen.** Los nueve aspectos son skins sanas; las transformaciones infectadas siguen perteneciendo al juego principal.

La igualdad de distancia al evento y las pruebas de navegación son comprobaciones geométricas, no una certificación de balance competitivo. La integración con la IA real y las habilidades debe probarse en partidas.

La construcción de vestuarios es una fachada sólida en esta primera versión; sus puertas animadas son ambientales. No incluye interiores transitables.

Ver `docs/INTEGRACION.md` y `docs/PARTE3_AMBIENTE.md`. `docs/PARTE2_MAPA_SPRITES.md` y `docs/VALIDACION.md` conservan las pruebas históricas correspondientes. Las capturas están en `captures`.
