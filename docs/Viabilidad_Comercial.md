# Viabilidad comercial de Patogen

**67Games · Revisión 06/11/2026**
Integrantes: Felipe Virga, Matias Moschella y Federico Bonetto.
Materia: Emprendimiento. Docente: Tamara Pichinni. Fecha de entrega del trabajo original: 13/08/2026.

Patogen tiene una base jugable; su viabilidad comercial requiere pruebas con jugadores, una versión distribuible y una propuesta de precio. Este informe actualiza su alcance y distingue las estimaciones económicas del trabajo original de los gastos realizados y las cotizaciones vigentes.

## Producto y monetización

Patogen es un videojuego 2D de infección y estrategia para dos jugadores locales en una misma computadora, desarrollado en Godot. Cada jugador elige una cepa entre Atlético, Área y Exponencial. Shopping, Laboratorio AV-07 y Pato Splash están integrados en el juego principal, con 65 huéspedes jugables por mapa.

Después de los 3 segundos iniciales de los patos y su transición comienza una fase de infección de 120 segundos. Gana quien tenga más bots infectados al terminar; un conteo igual produce empate técnico. Hay ADN, mutaciones, posesión, robot curador, distorsión, zona caliente, remontada, Simbionte, Coloso Antiviral, audio y tutorial. El tutorial puede retener el reloj mientras enseña.

El juego principal es `pato-gen/`. El balance humano y la exportación distribuible siguen pendientes. El prototipo no ofrece servidores de partidas, matchmaking ni una tienda de skins. Las cepas y mutaciones forman parte de la estrategia de juego.

Se mantiene como propuesta la **licencia de pago único** para acceder al juego. No hay precio validado, previsión de ventas comprobada ni rentabilidad demostrada en esta documentación. La propuesta no depende de microtransacciones o suscripciones. La publicación en Steam es una alternativa por evaluar, no un lanzamiento acreditado.

El comprador adquiere la licencia y el pagador la abona; pueden ser la misma persona. Los usuarios participan de las partidas locales. Amigos, reseñas y creadores pueden influir en la compra. 67Games decide el alcance y la publicación del producto. Un eventual sponsor financiaría el desarrollo mediante un acuerdo separado, todavía no acreditado.

## Costos y estimaciones

Se separan herramientas y servicios, gastos únicos de publicación o registro, trabajo del equipo y gastos variables. Los servicios opcionales requieren una decisión de contratación. Steam Direct se cuenta una sola vez por aplicación.

### Referencias del trabajo original

Los importes en pesos y el valor salarial siguientes se conservan para hacer trazable el cálculo del TP original. Salvo donde se indica consulta oficial, no se actualizaron las cotizaciones. Deben verificarse antes de contratar o pagar.

| Concepto | Referencia | Tipo | Aplicación al proyecto |
| --- | --- | --- | --- |
| Dominio .com.ar | ARS 8.500 | Anual, opcional | Presencia web; no es requisito para ejecutar partidas locales. Valor histórico del TP. |
| Hosting web | ARS 2.499 por mes | Mensual, opcional | Sitio o difusión; depende de plan, plazo y renovación. Valor histórico del TP. |
| Godot | USD 0 de licencia | Herramienta | Motor utilizado. Deben respetarse los avisos de licencia correspondientes. |
| GitHub Free | USD 0 en el plan considerado | Herramienta | Control de versiones; servicios adicionales requerirían otro presupuesto. Referencia del TP. |
| Registro de software DNDA | ARS 3.800 más tasa legal | Por registro | Importe publicado en la página oficial consultada el 06/11/2026. No acredita un registro realizado. |
| Registro de marca | A cotizar según arancel INPI | Por solicitud | Verificar modalidad, clase y arancel vigentes antes de iniciar. |
| Steam Direct | USD 100 por aplicación, más impuestos aplicables | Por aplicación | Solo si se decide distribuir en Steam. Referencia oficial consultada el 06/11/2026. |

Steam informa que la tarifa no es reembolsable y puede recuperarse en un pago posterior al alcanzar USD 1.000 de ingresos brutos ajustados por el producto, según sus condiciones. No se registra como ingreso garantizado.

### Trabajo del equipo

El trabajo original tomó como referencia una mediana salarial mensual de ARS 1.538.500 atribuida a la encuesta Sysarmy/OpenQube 2026.01. Es una base histórica del cálculo, no una cotización salarial nueva. Al dividir por 160 horas se obtienen ARS 9.615,625; se usa el valor redondeado de ARS 9.616 por hora.

| Integrante | Horas estimadas | Valor por hora | Trabajo valorizado |
| --- | --- | --- | --- |
| Felipe Virga | 200 h | ARS 9.616 | ARS 1.923.200 |
| Matias Moschella | 200 h | ARS 9.616 | ARS 1.923.200 |
| Federico Bonetto | 200 h | ARS 9.616 | ARS 1.923.200 |
| Total | 600 h | | ARS 5.769.600 |

Las 600 horas son una estimación de planificación, no un registro de horas efectivamente trabajadas. El valor económico del trabajo se distingue de los pagos de caja. Para un presupuesto actualizado se necesitan horas reales, cotizaciones nuevas y alcance acordado.

### Gastos variables y alcance futuro

Pueden existir gastos de recursos con licencia, servicios por consumo, promoción, comisiones e impuestos aplicables a ventas, según las decisiones y contratos que se adopten. No se asignan importes sin cotización.

El prototipo local no requiere servidores de partidas ni matchmaking para su funcionamiento. Una eventual modalidad online necesitaría una evaluación separada de desarrollo, operación y costos. El hosting de una página web no equivale a infraestructura multijugador.

## Propiedad intelectual y preparación de la publicación

67Games se describe aquí como equipo de desarrollo. El repositorio no permite acreditar por sí solo una forma societaria, inscripción fiscal, registro de marca o registro de software. Esos hitos deben documentarse con sus constancias antes de presentarlos como realizados.

### Marca

Para evaluar la protección de 67Games y Patogen corresponde consultar antecedentes, clases y requisitos del INPI. El portal oficial permite iniciar solicitudes y seguir expedientes. El nombre del equipo o la existencia del repositorio no acreditan que la marca esté registrada. Los aranceles se verifican en la fuente oficial al iniciar la solicitud.

### Software

La DNDA dispone de un trámite para software puesto en conocimiento público. La página oficial solicita identificar la obra, autores y titular, y presentar la documentación y el depósito según el procedimiento elegido. El trámite se inicia mediante TAD. La condición aplicable y la titularidad deben revisarse con los datos del equipo; no se afirma que Patogen ya tenga un certificado.

### Código y recursos de terceros

Antes de distribuir una versión, el equipo debe reunir la atribución y las condiciones de uso del código, sprites, música, efectos, fuentes y otros recursos. También debe acordar los aportes y la titularidad entre integrantes. El uso de Godot no concede una licencia sobre todos los archivos del juego; deben cumplirse los avisos del motor y las licencias particulares de cada recurso.

El proyecto actual es software y no incluye hardware propio documentado. Por eso, una evaluación de patentes o diseños de un dispositivo físico no forma parte del alcance actual de Patogen.

## Validación y próximos pasos

1. Exportar una versión de prueba del juego principal y verificarla en el entorno previsto para compartirla.
2. Observar partidas de dos personas para comprobar comprensión de controles, condición de victoria, ADN y mutaciones.
3. Comparar cepas y mapas para ajustar balance, remontada, Simbionte y Coloso. Las pruebas automáticas no sustituyen esta evidencia.
4. Registrar intención de repetir, situaciones de juego local y disposición a pagar. Los mapas A y B y el FODA son hipótesis que requieren contraste.
5. Registrar horas y gastos reales, revisar licencias y obtener cotizaciones antes de fijar presupuesto, precio o fecha de lanzamiento.

La base técnica permite organizar estas pruebas, pero no demuestra demanda ni rentabilidad. La siguiente decisión comercial debe apoyarse en resultados documentados de uso y compra, manteniendo el pago único como propuesta hasta validarlo.

## Fuentes

Producto revisado el 06/11/2026: [README](../README.md), [reglas](../pato-gen/scripts/Mapa.gd), [controles](../pato-gen/scripts/Pato.gd), [selector](../pato-gen/scripts/map_select.gd), [mapas integrados](../pato-gen/docs/MAPAS_INTEGRADOS.md), [usuarios y CUPID](INVESTIGACION_USUARIOS.md), [FODA](FODA.md), [pendientes](https://github.com/Code7C26/67Games/issues) y [encuesta](https://docs.google.com/forms/d/e/1FAIpQLSdcVXtVcuFnc-ONDs5G1jO4dhMEx9lVbaN2AGFfKulQGXbKgg/viewform?usp=sharing&ouid=109783700324919521831).

Fuentes oficiales consultadas el 06/11/2026: [Steam Direct](https://partner.steamgames.com/doc/gettingstarted/appfee), [registro de software DNDA](https://www.argentina.gob.ar/servicio/registrar-un-software-puesto-en-conocimiento-publico), [registro de marca INPI](https://www.argentina.gob.ar/inpi/marcas/registrar-una-marca), [aranceles INPI](https://www.argentina.gob.ar/inpi/aranceles-inpi) y [licencias de Godot](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).

Referencia histórica conservada para el cálculo salarial: [Sysarmy/OpenQube 2026.01](https://sueldos.openqube.io/encuesta-sueldos-2026.01/), citada en el trabajo original. No se presenta como salario vigente ni como fuente de horas ejecutadas por el equipo.
