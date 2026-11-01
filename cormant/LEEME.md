# Cormant · demo (código y mecánicas)

Godot **4.7.2 estable** (probado con esa versión; el proyecto declara «4.7» en `project.godot`) (GDScript, todo en español). Abre la carpeta con Godot y pulsa F5. Sin menú de opciones ni shaders.

## Estructura
- `scripts/nucleo/` · autoloads: `estado_juego` (compatibilidad, tiempo, tramos, código), `director_eventos` (bolsa, penalizaciones, entidad), `interfaz` (HUD, menú reportar/descartar, ocultarse, pausa), `sonido`, `transicion`, `recursos`; y los datos: `datos_salas` (salas y zonas clicables), `textos`.
- `scripts/mundo/` · `escenario` (sala + zonas), `alicia`, paneles (cámaras, ventanas, terminal del laboratorio, textos).
- `scripts/escenas/` · título, muerte, game over, final (bueno/malo), pantalla final.
- `pruebas/` · pruebas automáticas sin pantalla (ver abajo).

## Valores ajustables (todos provisionales)
Constantes al inicio de `director_eventos.gd` (duraciones, penalizaciones, tramos, umbrales de la entidad) y `INICIO_TRAMOS` en `estado_juego.gd`. `SEMILLA_FIJA >= 0` fija el orden aleatorio para depurar.

## Assets (ya incluidos, provisionales)
Los **fondos** son imágenes fotorrealistas aportadas por el autor (retocadas con `herramientas/arte_y_audio/importar_fondos.py`); Alicia (personaje) sale de ilustraciones del autor; cuadro, mancha y audio siguen siendo provisionales (generados por código). El juego detecta los assets por nombre: para cambiar cualquiera basta con sustituir el archivo, sin tocar código.
- `assets/fondos/` (1280x720): `recepcion`, `recepcion_reverso` (la panorámica original convertida a 16:9: recorte centrado en las puertas de salida con techo y suelo estirados; **se pierden las dos puertas laterales**), `pasillo` (placas retocadas: HAB-01→VIG-01, HAB-04→LAB-04; HAB-02/03 = puertas cerradas), `pasillo_alterado` (placa 14-B y huellas añadidas), `pasillo_secreto`, `vigilancia` (monitores con los feeds en verde: laboratorio, pasillo y «sin señal»), `laboratorio`, `oficina`, `habitacion_secreta` (Alicia tumbada bajo la sábana) y `habitacion_secreta_sentada` (se intercambia a los 3 s tras morir), `ventana_recepcion` (vista ampliada desde la ventana de Vigilancia, con marco; plantas de la puerta doble derecha borradas), `titulo`. **Las puertas de color conservan el color de los fondos originales** (ya no se tiñen). Cámaras `cam_1` (laboratorio) y `cam_2` (pasillo) con **filtro verde** (1056x526); la CAM 3 se dibuja en código como «SIN SEÑAL». También el cuadro y la mancha que se superponen al feed se pasan a verde monocromo (`VistaCamara._en_verde`).
- `assets/sprites/`: `detector` (detector de señales, LCD en blanco), `alicia_de_espaldas` (87x300 px en pantalla = 1,68 m), `alicia_sentada` (en la silla de oficina, 168x337 px, cabeza a 1,30 m), `cuadro_recto`, `mancha_suelo`. La silueta de la entidad es el sprite de Alicia en negro. Los tamaños base de cada pose están en `alicia.gd` (`TAMANOS`); el factor por sala, en `zonas_fondos.gd` (`ALICIA`), calculado con la perspectiva de cada fondo para que la escala sea natural.
- `assets/audio/` (.ogg; los bucles deben ser .ogg): ambientes por sala (`ambiente_recepcion`, `_pasillo`, `_vigilancia`, `_laboratorio`, `_oficina`, `_habitacion`, `_pasillo_alterado`), por tramo (`ambiente_tramo_1/2/3`), `musica_titulo`, `tono_grave`, `susurro_fijo`, `latido`, `pitidos_0..9` (N pitidos = dígito N; 0 = tono largo grave), `viento`, y efectos (`alerta_terminal`, `susurro_terminal`, `susurro_pasillo`, `estatica_breve`, `confirmacion`, `error_terminal`, `golpe_grave`, `advertencia_entidad`, `pasos_entidad`, `cambio_camara`, `papel`, `puerta`, `pitido_plano`, `tono_revelacion`).
- **Zonas clicables**: polígonos escritos a mano sobre los fondos en `scripts/nucleo/zonas_fondos.gd` (ya no los genera `exportar3d.py`, que queda como herramienta de los fondos provisionales antiguos). `datos_salas.gd` solo enlaza cada zona con su texto/acción/destino. Con fondo real, las zonas son invisibles y solo se iluminan un poco al pasar el ratón. Para ajustar una zona, mide sobre `assets/fondos/<sala>.png` (1280x720).
- Alicia y su escala por sala, la posición del cuadro en la cámara del laboratorio, la mancha del pasillo y las siluetas también están en `zonas_fondos.gd`. Correspondencias objeto↔zona nuevas: los textos se adaptaron al arte: casco→«Incubadora» del laboratorio, frasco→«Tubos de muestra», calendario→«Lámina del cerebro» (el reloj ya no cita el calendario), mesita→«Estantería» (la ficha es la carpeta sujeta al montante), «lector rojo»→teclado de acceso con luz azul, tablón de la oficina→normas y avisos.
- Si una puerta queda **detrás de la cámara** (la de entrada en Pasillo, Laboratorio y Oficina), se sale con la franja inferior de la pantalla (cursor de mano abajo al centro): «Volver a …».
- `herramientas/arte_y_audio/` contiene los generadores (Python) por si quieres retocar colores, objetos o sonidos.

## Depuración (solo en ejecución desde el editor)
F1 panel de estado · F2 forzar un evento · F3 +10 % de compatibilidad · Esc pausa · Espacio/H = ocultarse.

## Pruebas automáticas (y capturas)
```
godot --headless --path . --script res://pruebas/prueba_humo.gd
godot --headless --path . --script res://pruebas/prueba_muerte.gd
```
Capturas reales de cada sala (necesita pantalla o `xvfb-run`):
```
xvfb-run -a godot --path . --rendering-driver opengl3 --script res://pruebas/capturas.gd -- /carpeta/salida
```

## Habitación secreta (sala 5)
Vista desde la puerta de entrada: camilla a la derecha (largo hacia el fondo), puerta morada centrada al fondo, y a la izquierda el soporte con monitor de pulso y gotero junto a una mesita con utensilios y la ficha clínica (caso 14-B). Alicia aparece tumbada bajo la sábana (fondo `habitacion_secreta`); tras la primera muerte, a los 3 s, el fondo pasa a `habitacion_secreta_sentada` (sentada en la camilla). No hay sprites en esta sala.

## Alicia (personaje)
Protagonista (antes Eric; ya no existe en la historia). Hoja de personaje: `hoja_personaje.png` del autor (aparece rotulada «LUCÍA»; en el juego se llama **Alicia**). Los sprites se recortan con `herramientas/arte_y_audio/importar_personaje.py` a partir de `espaldas.png` y `silla.png`.

## Anomalías y código (6 anomalías, 5 dígitos desbloqueados por orden)
- El terminal del laboratorio (ARCHIVOS) entrega el código dígito a dígito, de izquierda a derecha: SOLICITAR → buscar → CONFIRMAR. Un dígito solo se revela si estaba solicitado y se desvanece a los 30 s (Notas no guarda los números).
- 1 Recepción: silueta (ventana de Vigilancia) → número en el mostrador tras la marca de 25 s · 2 Pasillo: mancha (CAM 2) · 3 Laboratorio: cuadro girado 180° (CAM 1) · 4 Señal: pitidos de CAM 3 (N pitidos = N; 0 = tono largo) · 5 Oficina (sala 5): viento y N manchas (1–9) en el pasillo visto por la ventana.
- Susurros (CAM 3) y parpadeos (Vigilancia, inevitables: +10 %) no dan dígito.
- Dígito equivocado en el terminal (cualquiera de los 5): bloqueo del terminal de 30 s (modo 1), 45 s (modo 2) o 60 s (modo 3), y todo lo confirmado vuelve a 0 (lo desbloqueado sigue desbloqueado: hay que reintroducirlo). Modos 1 y 2 suman además +5 % de compatibilidad; el modo 3 no (empieza al 99 % y mataría).
- Al solicitar un dígito, su anomalía pasa a 2.ª–3.ª de la bolsa (nunca la primera). Con el 5.º disponible, el laboratorio susurra solo por el canal derecho (`susurro_derecha`, bus «Derecha»).
- Solo modo 1: si la primera muerte llega con el dígito de los pitidos (4.º) solicitado y sin resolver, la mesita de la habitación incluye una nota de un técnico anterior que apunta, sin decirlo, a la cámara 3 (`EstadoJuego.ayuda_pitidos`, `Textos.NOTA_EX_TRABAJADOR`).
- Tras la primera muerte el terminal vuelve a 0: hay que reintroducir lo ya desbloqueado (o esperar de nuevo su anomalía).
- Pruebas: `prueba_humo.gd` y `prueba_muerte.gd` con `--script`; `prueba_camaras.tscn` se ejecuta como escena (`godot --headless --path . res://pruebas/prueba_camaras.tscn`).

## Modos de juego
Se eligen en el título (un botón por modo desbloqueado; el progreso se guarda en `user://progreso.cfg`). Parámetros en `EstadoJuego.MODOS`.
- **Modo 1 · Observación**: señales de 50 s, máx. 2 activas. La sombra del 60 % no mata: suma +20 % (esconderse: 5 s seguidos de 8 s). Se muere al llegar al 100 %. Reaparece con 60 %.
- **Modo 2 · Vigilancia estricta** (se desbloquea al llegar al final del 1): señales de 35 s, máx. 5 activas, esconderse 2,5 s de 3,5 s y no esquivar la sombra mata. Reaparece con 80 %.
- **Modo 3 · Sesión roja** (se desbloquea al llegar al final del 2): frecuencias del último tramo desde el inicio, modo rojo y 99 % de compatibilidad. Sin sombra por el 60 %: la entidad aparece cada 4 anomalías que surgen, en cualquier sala (se oyen sus pasos, `pasos_entidad.ogg`): hay una ventana de 2 s y hay que mantener OCULTARSE 1 s seguido; si no, game over. (`SOMBRA_SOLO_VIGILANCIA` en `director_eventos.gd` la limita a Vigilancia, con el contador congelado fuera.) Cualquier muerte, incluido llegar a 100 %, es game over. El parpadeo de Vigilancia no suma compatibilidad: dura el doble (7 s) y parpadea con el doble de intensidad.
- Llegar a 100 % de compatibilidad mata en los tres modos.

## Atajos del desarrollador (solo en compilaciones de depuración, es decir, al ejecutar desde el editor)
- **G**: activa/desactiva la invulnerabilidad (no sube la compatibilidad, no se muere; se ve «[DEV] INVULNERABLE» abajo a la izquierda).
- **F**: suma +20 % de compatibilidad (también con la invulnerabilidad activa).
- Al volver al título se apagan todos los trucos (invulnerabilidad y panel de depuración).
- F1: panel de depuración · F2: fuerza una señal · F3: +10 %.

## Finales y estrellas
- Modo 3 (final único): la hoja del documento muestra los textos de los finales anteriores, se tachan línea a línea y encima aparece escrito con sangre «Sabes quién soy...» (`assets/sprites/sangre_sabes_quien_soy.png`, generado con `herramientas/arte_y_audio/sangre.py`; tachado en `scripts/escenas/texto_tachado.gd`). Después sigue el cierre del final malo (silueta detrás de Alicia).
- Cielo del título: una estrella por final alcanzado (m1 bueno, m1 malo, m2 bueno, m2 malo, m3), 5 en total, en las posiciones de Casiopea (Segin, Ruchbah, Gamma, Schedar, Caph). Con las 5 se dibuja la línea blanca que las une. Se guardan en `user://progreso.cfg` (`estrellas`); la recién ganada aparece con fundido al volver al título. Código: `EstadoJuego.estrellas/id_final()`, `scripts/escenas/constelacion.gd`.

## Interfaz (HUD)
- Abajo, centro: botones **Volver** (sala anterior, `DatosSalas.VOLVER_A`; desactivado en la recepción, la habitación y el 14-B) y **Cerrar** (cierra el panel abierto; los paneles ya no llevan botón propio). Encima, la caja de texto de mensajes.
- Abajo a la izquierda: **Libreta** (hoja de objetivos: objetivo final, siguiente paso del código y estado de los 5 dígitos; sin números).
- Esquina inferior derecha: **detector de señales** (`assets/sprites/detector.png`, 211x600). **No se tiene al empezar**: el primer clic en los monitores de Vigilancia muestra un texto que lo otorga (`EstadoJuego.obtener_detector()`), se queda toda la partida y se pierde al empezar otra (`nueva_partida`). Su LCD lista todas las señales activas (`_refrescar_senales`) y, debajo, el texto de la señal seleccionada (`>`). Los 9 LEDs están apagados sin anomalías, se encienden con alguna y, con cada señal nueva, parpadean 2 veces con un pitido (`detector_bip`); con el detector ya no suena el aviso `alerta_terminal`. Los botones dibujados en el detector son solo decorativos (sprite original). Para **descartar**, **reportar** o cambiar a **otra señal** aparecen tres botones (DESCARTAR · REPORTAR · OTRA SEÑAL) uno junto a otro en el centro inferior de la pantalla, justo encima de Volver y Cerrar; solo se ven en Vigilancia, con el detector y alguna señal activa. El botón OCULTARSE queda a la derecha de esa fila.
- Pausa (Esc) centrada. Tras morir, en la habitación secreta solo pueden surgir el parpadeo y la entidad hasta que se sale de ella.

