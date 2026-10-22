# Materiales modulares del shopping V2

Creado y validado en Aseprite mediante su MCP real. `mall_tiles_v2.aseprite` contiene cinco capas editables y 192 slices nombrados. El PNG es su exportación directa. La grilla es de 32 × 32 px; atlas de 512 × 512 px, margen 0 y separación 0. Importar con filtro nearest, sin mipmaps.

| Fila | Material |
|---|---|
| 0 | Porcelanato marfil, circulación principal |
| 1 | Terrazo gris, accesos y vestíbulos |
| 2 | Roble cálido, gastronomía |
| 3 | Baldosa azul, supermercado |
| 4 | Alfombra violeta, cine y arcade |
| 5 | Cerámica terracota, comida rápida |
| 6 | Césped y piedras de jardín |
| 7 | Nogal, tienda de muebles |
| 8 | Pared de piedra caliza crema |
| 9 | Pared de paneles de roble |
| 10 | Pared de ladrillo terracota |
| 11 | Pared de paneles índigo |
| 12 | Esquinas y jambas arquitectónicas |
| 13 | Marcas transparentes de piso |
| 14–15 | Reserva transparente |

En las filas 0–7, las columnas 0–1 son variantes limpias, la 2 tiene desgaste fino y la 3 suciedad tenue. Todas conservan los dos píxeles exteriores idénticos: pueden alternarse sin romper las juntas. Una distribución sugerida es 70 % variante 0, 20 % variante 1, 7 % variante 2 y 3 % variante 3; aumentar el desgaste junto a accesos y mostradores.

Las columnas 4, 5, 6 y 7 conectan cada material al porcelanato por el norte, este, sur y oeste. Las columnas 8–11 agregan medallón, franja horizontal, franja vertical y mosaico; usarlas de manera localizada. En jardín, 8–9 son piedras rectangulares y 10–11 senderos vertical/horizontal.

En las filas 8–11 la columna equivale a la máscara de conexiones: N=1, E=2, S=4, O=8. Por ejemplo: horizontal=10, vertical=5, T abierta abajo=14, cruz=15. El núcleo arquitectónico ocupa exactamente 20 px de ancho, desde 6 hasta 25. Las conexiones se prolongan hasta el borde del tile. Las sombras se desplazan 2 px a la derecha y 3 hacia abajo; las sombras no deben tener colisión.

La fila 12 tiene esquinas exteriores en las columnas 0–3, interiores en 4–7 (máscaras 9,3,6,12) y jambas en 8–11 para piedra y 12–15 para roble (máscaras 1,2,4,8).

La fila 13 contiene rayas 0–3, pisadas 4–7, polvo 8–11 y hojas caídas 12–15. Son marcas visuales sin colisión y deben colocarse con moderación. Las hojas no son plantas ni objetos de gameplay.

No hay personajes, muebles, robots, textos ni interfaz en el atlas. Los colores no activan mecánicas térmicas. Las colisiones se deben generar en Godot a partir de la geometría de cada máscara, no del rectángulo completo ni de su sombra.

La validación `validation.json` comprobó 192 slices alineados, 98.304 píxeles de piso opacos, 25.600 píxeles de núcleo de pared opacos y 5.760 comparaciones de bordes entre variantes sin diferencias. La circulación con NPC reales y sus colisiones se verifica en la escena integrada.
