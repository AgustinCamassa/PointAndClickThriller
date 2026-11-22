"""Texto escrito con sangre para el final del modo 3 -> assets/sprites/sangre_sabes_quien_soy.png

Ahora usa la misma letra «escrita con el dedo» que la palabra del cuadro del pasillo (ver sangre_mensajes.py: GLIFOS y sprite_final).
La versión anterior (DejaVu Serif Bold Italic con letras rotadas) se sustituyó a petición del diseñador.
Uso: python3 sangre.py
"""
import sangre_mensajes

if __name__ == "__main__":
    img = sangre_mensajes.sprite_final()
    print("ok sangre_sabes_quien_soy", img.size)
