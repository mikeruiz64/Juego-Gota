"""Gota en estilo dibujado a mano (inspirado en Hollow Knight), acabado A · Limpio.

Dibuja cada fotograma con curvas vectoriales (SVG), monta una hoja de
fotogramas por variante y la convierte a PNG con transparencia usando
Brave en modo headless. Fuente de verdad del diseño: CONTEXTO_PERSONAJE.md

Uso: python -I gota_hk.py <carpeta Gota>
"""
import json
import math
import os
import subprocess
import sys

TAM = 256          # unidades del lienzo de cada fotograma
ESCALA = 2         # el PNG se renderiza a 512 x 512 por fotograma
COLS = 8
SUELO = 200        # la base de la gota no se mueve
CX = 128
MS_FOTOGRAMA = 83  # ~12 fotogramas por segundo

BRAVE = os.path.join(os.environ["LOCALAPPDATA"], "BraveSoftware", "Brave-Browser",
                     "Application", "brave.exe")

ANCHO = 0.9   # un poco más delgada que la gota clásica


def _x(x):
    return f"{CX + (x - CX) * ANCHO:.2f}"


# Silueta: punta ligeramente redondeada arriba, base redonda y ancha
GOTA = (f"M {_x(130)} 61 C {_x(136)} 74, {_x(178)} 110, {_x(178)} 150 "
        f"A {50 * ANCHO:.2f} 50 0 0 1 {_x(78)} 150 "
        f"C {_x(78)} 110, {_x(120)} 74, {_x(126)} 61 Q {_x(128)} 57.5 {_x(130)} 61 Z")
def forma_bola(b):
    """Silueta entre la gota (b = 0) y una bola redonda (b = 1) del mismo ancho."""
    if b <= 0:
        return GOTA
    m = lambda a, c: a + (c - a) * b
    k = 50 * 0.5523   # control de una curva de Bézier que imita un cuarto de círculo
    return (f"M {_x(m(130, 128))} {m(61, 100):.2f} C {_x(m(136, 128 + k))} {m(74, 100):.2f}, "
            f"{_x(178)} {m(110, 150 - k):.2f}, {_x(178)} 150 "
            f"A {50 * ANCHO:.2f} 50 0 0 1 {_x(78)} 150 "
            f"C {_x(78)} {m(110, 150 - k):.2f}, {_x(m(120, 128 - k))} {m(74, 100):.2f}, {_x(m(126, 128))} {m(61, 100):.2f} "
            f"Q {_x(128)} {m(57.5, 100):.2f} {_x(m(130, 128))} {m(61, 100):.2f} Z")


REFLEJO = f"M {_x(93)} 117 Q {_x(86)} 136 {_x(90)} 156 Q {_x(92.5)} 138 {_x(99)} 119 Z"

ESTILO = ("line{stroke:#dfe3e9;stroke-opacity:.8;stroke-width:3.2;stroke-linecap:round}"
          ".mano{fill:#e9ecf0;fill-opacity:.8;stroke:#cfd5dc;stroke-width:1.2}"
          ".acido{fill:#a6e05a;fill-opacity:.95;stroke:#4e8a26;stroke-width:1.2}"
          ".palma{fill:#c3ccd7;fill-opacity:.95;stroke:#8e9aab;stroke-width:1.4}"
          ".zeta{font-family:Arial,sans-serif;font-weight:bold;fill:#eef2f6;stroke:#5f6a78;stroke-width:1.4;"
          "paint-order:stroke}")

DEFS = f"""
  <linearGradient id="cuerpo" x1="0" y1="60" x2="0" y2="200" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#f1f3f6" stop-opacity="0.38"/>
    <stop offset="0.55" stop-color="#e8ebf0" stop-opacity="0.62"/>
    <stop offset="1" stop-color="#dde2e8" stop-opacity="0.86"/>
  </linearGradient>
  <mask id="fuera" maskUnits="userSpaceOnUse" x="0" y="0" width="256" height="256">
    <rect width="256" height="256" fill="#fff"/><path d="{GOTA}" fill="#000"/>
  </mask>
  <filter id="sombra" x="-50%" y="-200%" width="200%" height="500%">
    <feGaussianBlur stdDeviation="2.5"/>
  </filter>"""

# Postura firme por defecto: pies algo separados y manos abiertas a los lados.
# Distancias "fuera" medidas en horizontal desde el punto de unión.
POSTURA = {
    "mano": (11, 16),        # sin brazos: la mano flota junto al cuerpo (fuera, abajo)
    "manoAz": 100,          # grados entre la mirada y cada mano
    "piernaSep": 14,         # separación de cada pie al eje
    "piernaAbre": 3.5,       # cuánto se abre cada pie hacia fuera
}
INCLINACION = 0.22           # cámara algo elevada: lo cercano se ve más abajo
INCLINACION_CENITAL = 0.45   # cámara cenital a ~45° (como Minish Cap): animaciones por dirección


def ancho_cuerpo(y):
    """Semiancho de la sección horizontal del cuerpo (es de revolución)."""
    d = y - 150
    return ANCHO * math.sqrt(max(0.0, 50 * 50 - d * d))


def respiracion(t, perfil, veces=1):
    """Valor -1..1 del ciclo. 'pausa' aplana los extremos (se detiene arriba y abajo)."""
    s = math.sin(2 * math.pi * veces * t)
    if perfil == "pausa":
        return math.copysign(abs(s) ** 0.55, s)
    return s


OJOS_BASE = {
    "parpado": (0, 0),   # parte superior recortada (lado interior, lado exterior), 0..1
    "ancho": 1, "alto": 1, "dy": 0,
    "mirada": 0,         # grados extra hacia donde mira (+) o hacia la cámara (-)
    "cerrados": False,
    "parpadeo": False,   # parpadea una vez por ciclo
}
_ids = [0]


def ojos_svg(v, t, giro, dy_extra=0.0):
    """Ojos negros sólidos, ovalados, sin pupilas. La expresión sale de su forma."""
    e = dict(OJOS_BASE, **(v["ojos_t"](t) if "ojos_t" in v else v.get("ojos", {})))
    r_ojo = ancho_cuerpo(136) * 0.8   # algo menor que el cuerpo: la cara no se pega al borde
    cerrados = e["cerrados"] or (e["parpadeo"] and 0.56 <= t < 0.63)
    res = []
    for lado in (-1, 1):
        az = giro + math.radians(e["mirada"]) + lado * math.radians(12)
        c = math.cos(az)
        if c <= 0.05:
            continue
        ex = CX + r_ojo * math.sin(az)
        # De perfil el ojo no se queda en una raya: se ve al menos a media anchura
        rx, ry = 3.4 * max(c, 0.5) * e["ancho"], 6.2 * e["alto"]
        cy = 136 + e["dy"] + dy_extra
        if cerrados:
            res.append(f'<path d="M {ex - rx - 1.2:.2f} {cy:.2f} Q {ex:.2f} {cy + 2.2:.2f} '
                       f'{ex + rx + 1.2:.2f} {cy:.2f}" fill="none" stroke="#121216" '
                       f'stroke-width="2" stroke-linecap="round"/>')
            continue
        ojo = f'<ellipse cx="{ex:.2f}" cy="{cy:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="#121216"'
        interior, exterior = e["parpado"]
        if not (interior or exterior):
            res.append(ojo + "/>")
            continue
        # El lado interior es el que da hacia el otro ojo
        izq, der = (exterior, interior) if lado == -1 else (interior, exterior)
        arriba = cy - ry
        x0, x1 = ex - rx - 2, ex + rx + 2
        _ids[0] += 1
        cid = f"parpado{_ids[0]}"
        res.append(f'<clipPath id="{cid}"><polygon points="{x0:.2f},{arriba + 2 * ry * izq:.2f} '
                   f'{x1:.2f},{arriba + 2 * ry * der:.2f} {x1:.2f},{cy + ry + 2:.2f} '
                   f'{x0:.2f},{cy + ry + 2:.2f}"/></clipPath>')
        res.append(ojo + f' clip-path="url(#{cid})"/>')
    return res


def fotograma(v, t):
    a = respiracion(t, v.get("perfil"), v.get("respiraciones", 1))
    if "extra_a" in v:            # p. ej. un sobresalto
        a += v["extra_a"](t)
    amp = v.get("amplitud", 0.025)
    sy = 1 + amp * a                         # inspira: un poco más alta
    sx = 1 - amp * 0.48 * a                  # y un poco más estrecha
    manoDy = -v.get("manos", 1.6) * a
    # Sentarse (0 de pie .. 1 sentada) y estirarse con pereza (0..1)
    sentada = v["sentada_t"](t) if "sentada_t" in v else v.get("sentada", 0)
    estira = v["estirar_t"](t) if "estirar_t" in v else 0
    # Agachada (sigilo): más baja y aplastada
    agachada = v.get("agachada", 0)
    # Acción en curso: altura del salto, estirar (+) o aplastar (-), manos arriba,
    # ladeo, avance (en la dirección en que mira), temblor lateral, opacidad y golpes
    acc = v["accion_t"](t) if "accion_t" in v else {}
    altura = acc.get("altura", 0)
    k_acc = acc.get("k", 0)
    sy *= 1 + k_acc
    sx *= (1 - 0.6 * k_acc) * (1 + acc.get("ancho", 0))
    sy *= 1 - 0.2 * agachada
    sx *= 1 + 0.1 * agachada
    # Saludo: cuánto sube la mano (0..1) y su vaivén (radianes)
    saludo_sube, saludo_vaiven = v["saludo_t"](t) if "saludo_t" in v else (0, 0)
    # Hecha una bola (0..1): la silueta se redondea y recoge manos y pies
    bola = v["bola_t"](t) if "bola_t" in v else v.get("bola", 0)
    forma = forma_bola(bola)
    # Acurrucada de rodillas (0..1, partiendo de sentada): más baja, compacta y encogida
    acurruca = v["acurruca_t"](t) if "acurruca_t" in v else v.get("acurruca", 0)
    sy *= (1 - 0.07 * sentada) * (1 + 0.16 * estira) * (1 - 0.1 * acurruca)
    sx *= (1 + 0.05 * sentada) * (1 - 0.06 * estira) * (1 + 0.06 * acurruca)
    # Pulso de transparencia (reposo prolongado): mínimo al final de la inspiración
    pulso = v.get("pulso", 0)
    op = 1 - pulso * (0.5 - 0.5 * math.cos(2 * math.pi * t))
    if "opacidad_t" in v:
        op = v["opacidad_t"](t)
    op *= acc.get("op", 1)
    op_contorno = 1 - (1 - op) * 0.4
    op_reflejo = 1 - (1 - op) * 0.5
    respira = (f"translate({CX} {SUELO}) scale({sx:.4f} {sy:.4f}) "
               f"translate({-CX} {-SUELO})")
    P = dict(POSTURA, **v.get("postura", {}))
    giro = math.radians(v.get("angulo", 45) + acc.get("giro", 0))   # 0 = de frente; mira a la derecha
    # Las animaciones por dirección (llevan "angulo") son de la cámara cenital
    incl = INCLINACION_CENITAL if "angulo" in v else INCLINACION

    # Caminar en el sitio (el juego desplaza el nodo). fase: un ciclo = dos pasos
    paso = {"paso": 0, "alto": 0, "rebote": 0, "inclinacion": 0, "braceo": 0,
            "balanceo": 0, "aplastar": 0, "manoAlto": 0, "bamboleo": 0, "gotitas": 0, "vuelo": 0, "pisada": 0, "manosAtras": False,
            "gelatina": 0,
            **v.get("caminar", {})}
    fase = 2 * math.pi * t
    # Pisada firme: el paso se frena un instante al apoyar el pie (fase 0 y pi)
    fase -= paso["pisada"] * math.sin(2 * fase) / 2
    # Aplastar: más baja y ancha al apoyar el pie, más alta al cruzar los pies
    k = paso["aplastar"] * math.cos(2 * fase)
    # Gelatina: además se estira y aplasta con retraso respecto a la pisada
    k += paso["gelatina"] * math.cos(2 * fase - 0.9)
    sy *= 1 - k
    sx *= 1 + k * 0.6
    respira = (f"translate({CX} {SUELO}) scale({sx:.4f} {sy:.4f}) "
               f"translate({-CX} {-SUELO})")

    def avance_pie(lado):
        """Avance del pie a lo largo de la mirada y su altura (avanza mientras está en el aire)."""
        ph = fase + (0 if lado < 0 else math.pi)
        # De perfil la zancada es algo más larga, para que se vean bien los pasos
        zancada = paso["paso"] * (1 + 0.5 * abs(math.sin(giro)))
        return -zancada * math.cos(ph), paso["alto"] * max(0.0, math.sin(ph))

    def mover(x, y, avance):
        """Desplaza un punto `avance` unidades en la dirección en la que mira."""
        return x + avance * math.sin(giro), y + avance * math.cos(giro) * incl

    rebote = -paso["rebote"] * (abs(math.sin(fase)) - 0.5)       # arriba al cruzar los pies
    # Balanceo: se mece hacia el pie que apoya en cada paso
    # La inclinación hacia delante y el bamboleo solo se ven de perfil (no de frente ni de espaldas)
    lateral = math.sin(giro)
    giro_cuerpo = paso["inclinacion"] * lateral + paso["balanceo"] * math.sin(fase)
    # Sentada se echa un poco hacia atrás (apoyada en las manos); acurrucada, hacia delante
    giro_cuerpo += lateral * (-4 * sentada * (1 - acurruca) + 8 * acurruca)
    giro_cuerpo += lateral * acc.get("ladeo", 0)
    # Desplazamiento de la acción: avance en la dirección en que mira, temblor y salto
    acc_x = acc.get("dx", 0) + acc.get("avance", 0) * math.sin(giro)
    acc_y = acc.get("avance", 0) * math.cos(giro) * incl - altura
    # Rueda (bola girando en el aire): rota todo el cuerpo alrededor de su centro
    if acc.get("rueda"):
        respira = f"rotate({acc['rueda']:.2f} {CX} 150) " + respira
    # Sentada: el cuerpo baja hasta apoyarse en el suelo
    respira = (f"translate({acc_x:.3f} {rebote + 12 * sentada + 5 * acurruca + 9 * agachada + acc_y:.3f}) rotate({giro_cuerpo:.3f} {CX} {SUELO}) " + respira)
    # Bamboleo: la punta acompaña cada paso con algo de retraso (es agua)
    sesgo = paso["bamboleo"] * lateral * math.sin(2 * fase - 1.2) if paso["bamboleo"] else 0
    if paso["gelatina"]:
        sesgo += paso["gelatina"] * 90 * (lateral * math.sin(2 * fase - 1.6)
                                          + (1 - abs(lateral)) * math.sin(fase - 1.2))
    sesgo += acc.get("sesgo", 0) * lateral
    if sesgo:
        respira += (f" translate({CX} {SUELO}) skewX({sesgo:.3f}) translate({-CX} {-SUELO})")

    def proyectar(az, radio, y):
        """Punto sobre la dirección az (rad, 0 = hacia la cámara) a cierta distancia del eje."""
        x = CX + radio * math.sin(az)
        z = radio * math.cos(az)
        return x, y + z * incl, z

    delante, detras = [], []   # extremidades delante o detrás del cuerpo

    # Manos (sin brazos): flotan junto al lateral del cuerpo
    mo, md = P["mano"]
    for lado in (-1, 1):
        az = giro + lado * math.radians(P["manoAz"])
        r0 = ancho_cuerpo(160)
        _, _, z = proyectar(az, r0, 160)
        xh, yh, _ = proyectar(az, r0 + mo, 160 + md)
        # braceo: la mano va al contrario que el pie de su lado
        bracea = (-avance_pie(lado)[0] * paso["braceo"] / paso["paso"]) if paso["paso"] else 0
        xh, yh = mover(xh, yh, bracea)
        # La mano sube un poco en los extremos del braceo (describe un arco)
        if paso["braceo"]:
            yh -= paso["manoAlto"] * (bracea / paso["braceo"]) ** 2
        if z <= 0:
            # Mano lejana: asoma por detrás del borde de la silueta
            lado_x = 1 if math.sin(az) >= 0 else -1
            xh = CX + lado_x * (ancho_cuerpo(yh) + 1.5)
        if abs(math.sin(giro)) > 0.9 and not paso["manosAtras"]:
            # De perfil: cada mano en la misma vertical que su pie (la cercana delante
            # del cuerpo, la lejana detrás)
            yh = 160 + md
            xh, _, _ = proyectar(giro + lado * math.pi / 2, P["piernaSep"] + P["piernaAbre"] + 3, 213)
            xh, yh = mover(xh, yh, bracea)
            if paso["braceo"]:
                yh -= paso["manoAlto"] * (bracea / paso["braceo"]) ** 2
        if paso["manosAtras"] and abs(math.sin(giro)) > 0.9:
            # Estilo Naruto (solo de perfil): las dos manos atrás y a la misma altura,
            # en línea recta; se agitan un poco con cada paso
            atras = -1 if math.sin(giro) > 0 else 1
            cerca = z > 0
            yh = 165 + 1.5 * math.sin(2 * fase)
            xh = CX + atras * (ancho_cuerpo(yh) + (19 if cerca else 11) + 2 * math.sin(2 * fase))
        elif paso["manosAtras"]:
            # En las demás direcciones: las manos atrás y abiertas, asomando por los lados
            xh, yh, z = proyectar(giro + math.pi + lado * math.radians(60), r0 + 16,
                                  165 + 1.5 * math.sin(2 * fase))
            if z <= 0 and abs(xh - CX) < ancho_cuerpo(yh) + 1.5:
                xh = CX + (1 if xh >= CX else -1) * (ancho_cuerpo(yh) + 1.5)
        if saludo_sube and lado == 1:
            xs = CX + ancho_cuerpo(112) + 13 + 8 * math.sin(saludo_vaiven)
            xh, yh = xh + (xs - xh) * saludo_sube, yh + (104 - yh) * saludo_sube
            z = 1.0   # por fuera de la silueta: siempre visible
        yh += 4 * agachada   # agachada: manos más bajas
        # Al estirarse suben por encima de la cabeza y se abren
        yh -= 80 * estira
        xh = CX + (xh - CX) * (1 + 0.25 * estira)
        if acc.get("manos"):
            yh -= 26 * acc["manos"]
            xh = CX + (xh - CX) * (1 + 0.2 * acc["manos"])
        e = acc.get("golpe", {}).get(lado, 0)
        if e:
            xg, yg, zg = proyectar(giro + lado * math.radians(40 * (1 - e) + 10), r0 + 4 + 34 * e, 168)
            yg = 168 + (yg - 168) * 0.4   # el puño va a la altura del pecho, no hacia el suelo
            yg += acc.get("golpe_y", {}).get(lado, 0)
            w = suave(min(1.0, abs(e) * 3))
            xh, yh, z = xh + (xg - xh) * w, yh + (yg - yh) * w, z + (zg - z) * w
        if sentada or acurruca:
            # Sentada: se apoya en las manos, en el suelo y por detrás del cuerpo.
            # Acurrucada: las manos se recogen delante, junto a las rodillas
            xb, yb, zb = proyectar(giro + math.pi + lado * math.radians(40), r0 + 4, 194)
            xa, ya, za = proyectar(giro + lado * math.radians(30), r0 * 0.7, 192)
            xh, yh, z = (xh + (xb - xh) * sentada, yh + (yb - yh) * sentada, z + (zb - z) * sentada)
            xh, yh, z = (xh + (xa - xh) * acurruca, yh + (ya - yh) * acurruca, z + (za - z) * acurruca)
            if z <= 0 and abs(xh - CX) < ancho_cuerpo(yh) + 1.5:
                # Si queda escondida detrás, que asome por el borde
                xh = CX + (1 if xh >= CX else -1) * (ancho_cuerpo(yh) + 1.5)
        # El puño crece al acercarse a la cámara
        radio = 4.6 * (1 + 0.45 * e * max(0.0, math.cos(giro)))
        if bola:
            # En bola, las manos se recogen pegadas delante del cuerpo
            xr, yr, zr = proyectar(giro + lado * math.radians(55), ancho_cuerpo(165) * 0.9, 168)
            xh, yh, z = xh + (xr - xh) * bola, yh + (yr - yh) * bola, z + (abs(zr) + 1 - z) * bola
        trozo = f'<circle class="palma" cx="{xh:.2f}" cy="{yh + manoDy:.2f}" r="{radio:.2f}"/>'
        (delante if z > 0 else detras).append(trozo)

    # Pies (sin piernas): flotan bajo el cuerpo y no se mueven al respirar
    pies_d, pies_t = [], []
    for lado in (-1, 1):
        az = giro + lado * math.pi / 2
        sep, abre = P["piernaSep"], P["piernaAbre"]
        _, _, z = proyectar(az, sep, 199)
        xf, yf, _ = proyectar(az, sep + abre + 3, 213)
        avance, alto = avance_pie(lado)
        xf, yf = mover(xf, yf, avance)
        yf -= alto
        # Vuelo (correr): en mitad de la zancada los dos pies se despegan del suelo
        yf -= paso["vuelo"] * max(0.0, -math.cos(2 * fase))
        # Sentada: los pies salen hacia delante (de frente, hacia la cámara y algo abiertos)
        if sentada:
            k = sentada * (1 - acurruca)
            xf, yf = mover(xf, yf, (11 + 14 * abs(math.sin(giro))) * k)
            yf += k * (1 + 5 * max(0.0, math.cos(giro)))
            xf = CX + (xf - CX) * (1 + 0.3 * k * abs(math.cos(giro)))
        # De rodillas: los pies se recogen debajo y detrás del cuerpo
        if acurruca:
            xf, yf = mover(xf, yf, -8 * acurruca)
            yf -= 3 * acurruca
        # En bola, los pies se recogen bajo el cuerpo
        if bola:
            xf = CX + (xf - CX) * (1 - 0.5 * bola)
            yf -= 6 * bola
        # Acción: un pie da un paso (lado, avance, altura)
        if acc.get("pie") and acc["pie"][0] == lado:
            xf, yf = mover(xf, yf, acc["pie"][1])
            yf -= acc["pie"][2]
        if lado in acc.get("pies", {}):
            xf, yf = mover(xf, yf, acc["pies"][lado][0])
            yf -= acc["pies"][lado][1]
        yf -= 4 * acc.get("recoge", 0)   # en el aire, los pies se recogen bajo el cuerpo
        # Acción: los pies acompañan al cuerpo (en el aire se recogen un poco)
        xf += acc_x
        yf += acc_y - 3 * min(1.0, altura / 8)
        if acc.get("rueda") is not None:
            continue   # rodando, los pies van recogidos dentro de la bola
        trozo = f'<ellipse class="mano" cx="{xf:.2f}" cy="{yf:.2f}" rx="6" ry="4.2"/>'
        delante_del_cuerpo = (z > 0 or (sentada > 0.5 and acurruca < 0.5 and math.cos(giro) > 0.5)
                              or (acurruca > 0.5 and math.cos(giro) < -0.5))
        (pies_d if delante_del_cuerpo else pies_t).append(trozo)

    sombra_x = CX + acc.get("avance", 0) * math.sin(giro)
    sombra_k = 1 - min(0.4, altura / 100)   # en el aire, la sombra se encoge
    partes = [] if v.get("sin_sombra") else [
        f'<ellipse cx="{sombra_x:.2f}" cy="222" rx="{46 * (1 - 0.02 * a) * (1 + 0.06 * sentada) * sombra_k:.2f}" '
        f'ry="{6.5 * incl / INCLINACION:.2f}" fill="#0f1320" fill-opacity="{0.22 * op:.3f}" filter="url(#sombra)"/>']
    oculta = v["sin_extremidades_t"](t) if "sin_extremidades_t" in v else v.get("sin_extremidades", 0)
    op_ext = op * (1 - oculta)
    partes.append(f'<g opacity="{op_ext:.3f}">{"".join(pies_t)}</g>')

    cuerpo = [f'<g opacity="{op_ext:.3f}"><g mask="url(#fuera)">{"".join(detras)}</g></g>'
              f'<g opacity="{op:.3f}">'
              f'<path d="{forma}" fill="url(#cuerpo)"/></g>',
              # Doble contorno gris muy claro
              f'<g opacity="{op_contorno:.3f}">'
              f'<path d="{forma}" fill="none" stroke="#cdd3da" stroke-opacity="0.95" '
              f'stroke-width="2.2" stroke-linejoin="round"/>'
              f'<path d="{forma}" fill="none" stroke="#e3e7ec" stroke-opacity="0.8" '
              f'stroke-width="1.1" transform="translate(128 142) scale(0.93) translate(-128 -142)"/></g>',
              # Reflejo pequeño en el lateral izquierdo (la luz no gira con ella)
              f'<path d="{REFLEJO}" fill="#ffffff" '
              f'fill-opacity="{0.88 * op_reflejo:.3f}"/>']
    # Ojos: juntos, se acortan con la perspectiva. Radio algo menor que el del
    # cuerpo (convención de dibujo) para que la cara no se pegue al borde
    cuerpo.extend(ojos_svg(v, t, giro, 3 * acurruca))
    cuerpo.append(f'<g opacity="{op_ext:.3f}">{"".join(delante)}</g>')
    partes.append(f'<g transform="{respira}">{"".join(cuerpo)}</g>')
    partes.append(f'<g opacity="{op_ext:.3f}">{"".join(pies_d)}</g>')
    # Ácido: una gota verde que sale por delante del cuerpo y se aleja en arco
    ac = acc.get("acido")
    if ac is not None and 0 <= ac <= 1:
        d = ancho_cuerpo(150) + 6 + 34 * ac
        ax = acc_x + CX + d * math.sin(giro)
        ay = acc_y + 150 + d * math.cos(giro) * incl - 14 * math.sin(math.pi * ac)
        r = 3 + 2.5 * min(1.0, ac * 4)
        partes.append(f'<ellipse class="acido" cx="{ax:.2f}" cy="{ay:.2f}" rx="{r:.2f}" ry="{r * 1.15:.2f}" '
                      f'opacity="{1 - 0.3 * ac:.3f}"/>')
    # Salpicadura: gotitas que saltan del cuerpo y caen, desvaneciéndose
    sp = acc.get("salpica")
    if sp:
        u, sentido = sp
        if 0 < u < 1:
            for i in range(4):
                ang = math.radians(-60 + 40 * i)
                d = (18 + 10 * i % 3) * u
                gx = acc_x + CX + sentido * math.sin(giro) * (40 + d * math.cos(ang)) + (i - 1.5) * 9 * math.cos(giro)
                gy = acc_y + 170 + d * math.sin(ang) + 40 * u * u
                partes.append(f'<circle class="mano" cx="{gx:.2f}" cy="{gy:.2f}" r="{2.4 - 0.3 * i:.2f}" '
                              f'stroke-width="0.6" opacity="{(1 - u) ** 1.2:.3f}"/>')
    # Zzz (durmiendo): tres zetas que suben en diagonal, crecen y se desvanecen
    if v.get("zzz"):
        for i in range(3):
            u = (t + i / 3) % 1
            op_z = math.sin(math.pi * u) ** 0.8
            partes.append(f'<text class="zeta" x="{CX + 20 + 34 * u:.2f}" y="{100 - 62 * u:.2f}" '
                          f'opacity="{op_z:.3f}" font-size="{14 + 14 * u:.1f}">z</text>')
    # Gotitas: se desprenden por detrás en cada pisada y desaparecen enseguida
    u = (2 * t) % 1                      # tiempo desde la última pisada (0..1)
    if paso["gotitas"] and u < 0.7:
        k = u / 0.7
        for i in range(paso["gotitas"]):
            gx = CX - (34 + (12 + 7 * i) * k) * lateral + (i - 1) * 14 * (1 - abs(lateral))
            gy = 186 - 4 * i - (14 + 5 * i) * k + 26 * k * k
            r = (1.9 - 0.4 * i) * (1 - 0.5 * k)
            partes.append(f'<circle class="mano" cx="{gx:.2f}" cy="{gy:.2f}" r="{r:.2f}" '
                          f'stroke-width="0.6" opacity="{(1 - k) ** 1.5:.3f}"/>')
    return "".join(partes)


def hoja_svg(v, n):
    filas = math.ceil(n / COLS)
    w, h = COLS * TAM, filas * TAM
    celdas = []
    for i in range(n):
        ox, oy = (i % COLS) * TAM, (i // COLS) * TAM
        celdas.append(f'<g transform="translate({ox} {oy})">{fotograma(v, i / n)}</g>')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w * ESCALA}" height="{h * ESCALA}" '
            f'viewBox="0 0 {w} {h}"><style>{ESTILO}</style><defs>{DEFS}</defs>'
            f'{"".join(celdas)}</svg>'), w * ESCALA, h * ESCALA


def renderizar(svg_path, png_path, w, h):
    subprocess.run([BRAVE, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--window-size={w},{h}",
                    f"--screenshot={png_path}", "file:///" + svg_path.replace("\\", "/")],
                   check=True, capture_output=True)


ALERTA = {"mano": (14, 8), "piernaSep": 16, "piernaAbre": 4.5}

def suave(x):
    """0..1 con aceleración y frenado suaves."""
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def tramo(t, t0, t1):
    return (t - t0) / (t1 - t0)


PARPADEO = {"parpadeo": True}
OJOS_ALERTA = {"ancho": 1.12, "alto": 1.22}
OJOS_DETERMINADA = {"parpado": (0.5, 0.1)}
OJOS_PREOCUPADA = {"parpado": (0.1, 0.5)}
OJOS_RECELOSA = {"alto": 0.6, "dy": 1, "parpado": (0.15, 0.15)}


def ojos_entrada_prolongado(t):
    """Mira a la cámara -> párpados a media altura -> ojos cerrados."""
    p = 0.38 * suave(tramo(t, 0.40, 0.55)) + 0.54 * suave(tramo(t, 0.70, 0.88))
    return {"mirada": -28 * suave(tramo(t, 0.05, 0.25)), "parpado": (p, p), "cerrados": t >= 0.9}


def campana(t, t0, t1, t2, t3):
    """0 -> 1 entre t0 y t1, se mantiene y 1 -> 0 entre t2 y t3."""
    return suave(tramo(t, t0, t1)) - suave(tramo(t, t2, t3))


def salto(alto, prep, estira, manos, ladeo, aterriza, bamboleo=1):
    """Salto en el sitio: se agacha, sube, cae y amortigua el aterrizaje."""
    def f(t):
        u = tramo(t, 0.24, 0.76)
        en_aire = 0 <= u <= 1
        arco = math.sin(math.pi * u) if en_aire else 0
        k = -prep * campana(t, 0.0, 0.18, 0.18, 0.26)
        if en_aire:
            k += estira * 0.7 * math.cos(math.pi * u)   # se estira al subir, se recoge al caer
        if t >= 0.76:
            w = tramo(t, 0.76, 1)
            k -= aterriza * math.exp(-4 * w) * math.cos(math.pi * w * (1 + 2 * bamboleo))
        return {"altura": alto * arco, "k": k, "manos": manos * arco, "ladeo": ladeo * arco}
    return f


def dano(temblor, retro, aplasta, parpadea):
    """Recibir daño: temblor, retroceso, aplastón y parpadeo de transparencia."""
    def f(t):
        r = retro * (suave(tramo(t, 0.0, 0.15)) - suave(tramo(t, 0.45, 0.95)))
        w = tramo(t, 0.05, 1)
        k = -aplasta * (t / 0.05 if t < 0.05 else math.exp(-4 * w) * math.cos(3 * math.pi * w))
        apagada = 0.1 < t < 0.2 or 0.3 < t < 0.4
        return {"dx": temblor * math.sin(2 * math.pi * 9 * t) * max(0.0, 1 - t / 0.6),
                "avance": -r, "k": k, "ladeo": -6 * (r / retro if retro else 0),
                "op": 1 - parpadea * apagada}
    return f


def ojos_dano(t):
    """Cierre breve de los ojos al recibir el golpe."""
    return {"cerrados": 0.06 <= t < 0.42}


def puno(t, t0, t1):
    """Recorrido de un puñetazo entre t0 y t1: prepara (la mano retrocede), golpea rápido
    pasándose un poco, se queda un instante y vuelve despacio. -0,25 .. 1,05."""
    u = tramo(t, t0, t1)
    if u <= 0 or u >= 1:
        return 0.0
    if u < 0.22:
        return -0.25 * suave(u / 0.22)
    if u < 0.4:
        x = (u - 0.22) / 0.18
        return -0.25 + 1.3 * (1 - (1 - x) ** 3)
    if u < 0.52:
        return 1.05 - 0.05 * suave((u - 0.4) / 0.12)
    return 1 - suave((u - 0.52) / 0.48)


def peso(e):
    """El cuerpo acompaña al puño: se echa un poco atrás al preparar y adelante al golpear."""
    return {"avance": 4 * max(0.0, e) + 6 * min(0.0, e), "ladeo": 5 * max(0.0, e) + 4 * min(0.0, e)}


def golpe_directo(t):
    e = puno(t, 0.04, 0.96)
    e_cuerpo = puno(t, 0.07, 0.99)   # el cuerpo va un poco detrás de la mano
    return {"golpe": {-1: e}, **peso(e_cuerpo), "pie": (-1, 4 * max(0.0, e_cuerpo), 0)}


def golpe_uno_dos(t):
    a, b = puno(t, 0.02, 0.6), puno(t, 0.36, 0.96)
    c = max(puno(t, 0.05, 0.63), puno(t, 0.39, 0.99), key=abs)
    return {"golpe": {-1: a, 1: b}, **peso(c), "pie": (-1, 3 * max(0.0, c), 0)}


def golpe_embestida(t):
    """Se echa atrás y se lanza con todo el cuerpo, las manos por delante."""
    atras = campana(t, 0.0, 0.25, 0.27, 0.36)
    u = tramo(t, 0.3, 1)
    lanza = 0.0 if u <= 0 else (1 - (1 - min(1.0, u / 0.25)) ** 3 if u < 0.25 else 1 - suave((u - 0.35) / 0.65)
                                 if u > 0.35 else 1.0)
    return {"golpe": {-1: 0.35 * lanza, 1: 0.35 * lanza}, "avance": -4 * atras + 15 * lanza,
            "k": -0.06 * atras + 0.08 * campana(t, 0.3, 0.4, 0.45, 0.6), "ladeo": -4 * atras + 8 * lanza,
            "pie": (-1, 6 * lanza, 2 * campana(t, 0.3, 0.38, 0.38, 0.46))}


def frenar(t):
    """Frena como un líquido: la punta sigue hacia delante por inercia y se bambolea,
    el cuerpo se aplasta y tiembla, y salpican unas gotitas hacia delante."""
    amort = math.exp(-3.5 * t)
    b = campana(t, 0.0, 0.15, 0.3, 0.8)
    return {"sesgo": 16 * amort * math.cos(3 * math.pi * t), "ladeo": -4 * b,
            "k": -0.09 * math.exp(-4 * t) * math.cos(4 * math.pi * t),
            "golpe": {-1: 0.15 * b, 1: 0.15 * b}, "salpica": (tramo(t, 0.02, 0.6), 1)}


def dano_salpicadura(t):
    """El golpe le abolla el lado y le salta agua por detrás."""
    w = tramo(t, 0.04, 1)
    k = 0.12 * (t / 0.04 if t < 0.04 else math.exp(-4 * w) * math.cos(3 * math.pi * w))
    return {"k": k, "avance": -5 * campana(t, 0.0, 0.1, 0.3, 0.8), "ladeo": -5 * campana(t, 0.0, 0.1, 0.3, 0.8),
            "salpica": (tramo(t, 0.03, 0.75), -1)}


def dano_ondulacion(t):
    """Se ondula como el agua al recibir una piedra: tiembla rápido y se vuelve transparente."""
    amort = math.exp(-3 * t)
    return {"k": 0.08 * amort * math.sin(2 * math.pi * 6 * t), "sesgo": 6 * amort * math.sin(2 * math.pi * 4 * t),
            "op": 1 - 0.45 * campana(t, 0.0, 0.1, 0.35, 0.8)}


def dano_tambaleo(t):
    """Retrocede tambaleándose, mareada, y recupera el equilibrio."""
    amort = 1 - suave(tramo(t, 0.5, 1))
    return {"avance": -8 * campana(t, 0.0, 0.2, 0.4, 1.0), "dx": 5 * amort * math.sin(2 * math.pi * 2 * t),
            "ladeo": 7 * amort * math.sin(2 * math.pi * 2 * t + 0.5)}


def dano_derrame(t):
    """Pierde la forma un instante (se derrama casi como un charco) y se recompone."""
    b = campana(t, 0.0, 0.15, 0.3, 0.75)
    w = tramo(t, 0.75, 1)
    rebote = 0.06 * math.exp(-4 * w) * math.sin(2 * math.pi * w) if t >= 0.75 else 0
    return {"k": -0.32 * b + rebote, "op": 1 - 0.25 * b}


def ojos_dano_largo(t):
    return {"cerrados": 0.06 <= t < 0.6}


def golpe_gancho(t):
    """Gancho: la mano baja al preparar, sale desde abajo y sube; da un saltito con el golpe."""
    e = puno(t, 0.04, 0.96)
    e_cuerpo = puno(t, 0.08, 1.0)
    return {"golpe": {-1: e}, "golpe_y": {-1: 22 - 48 * max(0.0, e)}, **peso(e_cuerpo),
            "altura": 6 * campana(t, 0.3, 0.42, 0.46, 0.65), "k": 0.05 * campana(t, 0.28, 0.4, 0.45, 0.62)}


def golpe_rafaga(t):
    """Ráfaga: cuatro golpes rápidos alternando las manos, cada uno con su recorrido."""
    g = {-1: 0.0, 1: 0.0}
    for i in range(4):
        t0 = 0.02 + 0.18 * i
        lado = -1 if i % 2 == 0 else 1
        g[lado] = max(g[lado], puno(t, t0, t0 + 0.32), key=abs)
    m = max(g.values(), key=abs)
    return {"golpe": g, **peso(m), "avance": 2 + 2 * max(0.0, m)}


def golpe_giratorio(t):
    """Giratorio: da una vuelta completa con las manos abiertas golpeando al pasar."""
    vuelta = suave(tramo(t, 0.12, 0.72))
    abre = campana(t, 0.05, 0.15, 0.7, 0.85)
    return {"giro": 360 * vuelta, "golpe": {-1: 0.6 * abre, 1: 0.6 * abre}, "altura": 4 * abre,
            "k": -0.04 * campana(t, 0.0, 0.1, 0.1, 0.18)}


def aire(estira, manos, ladeo):
    """Postura en el aire de 0 (despega) a 1 (va a tocar el suelo): estirada al subir,
    recogida al caer, pies recogidos y manos algo arriba."""
    def f(t):
        arco = math.sin(math.pi * t)
        return {"k": estira * math.cos(math.pi * t), "manos": manos * arco, "ladeo": ladeo * arco,
                "recoge": arco, "sesgo": 3 * math.sin(2 * math.pi * t) * arco}
    return f


def aire_corriendo(t):
    """Salto corriendo: inclinada hacia delante, piernas abiertas (una delante y otra detrás)."""
    arco = math.sin(math.pi * t)
    return {"k": 0.1 * math.cos(math.pi * t), "ladeo": 4 + 4 * arco, "recoge": 0.5 * arco,
            "pies": {-1: (7 * arco, 3 * arco), 1: (-7 * arco, 2 * arco)},
            "sesgo": -4 * math.cos(math.pi * t)}


def aterrizar(t):
    """Toca el suelo como una gota de agua que choca: se aplasta y ensancha, rebota
    estirándose, la punta se bambolea y se asienta temblando."""
    amort = math.exp(-4.0 * t)
    return {"k": -0.34 * amort * math.cos(3.2 * math.pi * t), "recoge": 0.6 * (1 - suave(t * 3)),
            "sesgo": 6 * amort * math.sin(4 * math.pi * t)}


def cargar_acido(t):
    """Mientras carga el ácido: se hincha un poco y late."""
    return {"k": 0.04 + 0.025 * math.sin(2 * math.pi * t), "ladeo": -2}


def soltar_acido(t):
    """Suelta el ácido: se contrae de golpe hacia delante y vuelve."""
    b = campana(t, 0.0, 0.25, 0.3, 1.0)
    return {"k": 0.06 * (1 - suave(t * 4)) - 0.11 * b, "ladeo": -2 + 8 * b, "avance": 3 * b}


def escupir(t):
    """Coge aire (se hincha y se echa atrás), se contrae de golpe y expulsa una gota de ácido."""
    carga, suelta = campana(t, 0.0, 0.35, 0.35, 0.45), campana(t, 0.38, 0.48, 0.55, 0.9)
    return {"k": 0.09 * carga - 0.1 * suelta, "ladeo": -5 * carga + 6 * suelta,
            "avance": -2 * carga + 3 * suelta, "acido": tramo(t, 0.4, 0.62) if t >= 0.4 else None}


def frenar_firme(t):
    """Planta los pies: se aplasta un poco y se asienta, la punta apenas se mueve."""
    b = campana(t, 0.0, 0.18, 0.25, 0.8)
    return {"k": -0.05 * b, "ladeo": 2 * campana(t, 0.0, 0.1, 0.1, 0.35),
            "sesgo": 4 * math.exp(-5 * t) * math.cos(3 * math.pi * t)}


def frenar_bamboleo(t):
    """La punta sigue un poco por inercia y se bambolea suave, como agua que se calma."""
    return {"sesgo": 8 * math.exp(-3.5 * t) * math.cos(3 * math.pi * t),
            "k": -0.05 * math.exp(-4 * t) * math.cos(4 * math.pi * t)}


def frenar_paso(t):
    """Da un último paso corto para juntar los pies y se asienta."""
    p = suave(tramo(t, 0.0, 0.4))
    w = tramo(t, 0.35, 1)
    tiembla = math.exp(-4 * w) * math.sin(3 * math.pi * w) if t >= 0.35 else 0
    return {"pie": (-1, -5 + 5 * p, 4 * math.sin(math.pi * p)),
            "k": -0.05 * campana(t, 0.35, 0.45, 0.45, 0.6) + 0.025 * tiembla,
            "sesgo": 4.5 * math.exp(-4 * t) * math.cos(3 * math.pi * t)}


def reaparecen(t):
    """Manos y pies ocultos durante el choque; reaparecen al final."""
    return 1 - suave((t - 0.65) / 0.3)


def charco_forma(t):
    """D3d: charco tembloroso un poco más largo; se levanta como una cúpula y la punta se forma la última."""
    if t < 0.4:
        return {"k": -0.8 + 0.035 * math.sin(t * 36)}
    if t < 0.7:
        u = suave((t - 0.4) / 0.3)
        return {"k": -0.8 + 0.62 * u}
    w = (t - 0.7) / 0.3
    return {"k": -0.18 * (1 - suave(w)) + 0.06 * math.exp(-4 * w) * math.sin(w * 18)}


def bola_charco_forma(t):
    """En D3d la silueta es una cúpula (bola) mientras se levanta y recupera la punta al final."""
    return 1.0 if t < 0.7 else 1 - suave((t - 0.7) / 0.3)


def derrota_aplana(t):
    """Derrota A: se aplana poco a poco hasta ser un charco y se desvanece."""
    a = suave(t / 0.55)
    return {"k": -0.85 * a + 0.03 * math.sin(t * 30) * (1 - t), "ancho": 0.18 * a, "altura": -16 * a}


def derrota_derrite(t):
    """Derrota B: se derrite temblando, gotea hacia abajo y se evapora (el juego dibuja el vapor)."""
    baja = suave(t / 0.7)
    return {"k": -0.8 * baja + 0.05 * math.sin(t * 22) * (1 - baja), "sesgo": 4 * math.sin(t * 18) * (1 - baja),
            "ancho": 0.12 * baja, "altura": -15 * baja}


def derrota_filtra(t):
    """Derrota C: se aplana en un charco que se va encogiendo, como si el suelo se lo bebiera."""
    aplana = suave(t / 0.35)
    encoge = suave((t - 0.4) / 0.6)
    return {"k": -0.85 * aplana, "ancho": 0.2 * aplana - 0.85 * encoge, "altura": -16 * aplana}


def ojos_derrota(t):
    """Cierra los ojos al empezar a caer y ya no los abre."""
    return {"cerrados": t > 0.18, "parpado": (0.4 * suave(t / 0.18), 0.4 * suave(t / 0.18))}


def ojos_golpe(t):
    return dict(OJOS_DETERMINADA)


def ojos_relajar(t0, mirar=False):
    """Párpados a media altura desde t0; de perfil, antes mira a la pantalla."""
    def ojos(t):
        p = 0.38 * suave(tramo(t, t0, t0 + 0.15))
        return {"parpado": (p, p), "mirada": -28 * suave(tramo(t, 0.04, 0.2)) if mirar else 0}
    return ojos


def ojos_cerrar(mirada):
    """Acurrucarse: de párpados a media altura a ojos cerrados."""
    def ojos(t):
        p = 0.38 + 0.54 * suave(tramo(t, 0.3, 0.7))
        return {"parpado": (p, p), "cerrados": t >= 0.75, "mirada": mirada}
    return ojos


def ojos_levantarse(mirada):
    """Se levanta de golpe con los ojos de alerta y deja de mirar a la pantalla."""
    def ojos(t):
        return dict(OJOS_ALERTA, mirada=mirada * (1 - suave(tramo(t, 0.2, 0.8))))
    return ojos


def saludar(t):
    """Sube la mano, la mueve tres veces de un lado a otro y la baja."""
    sube = suave(tramo(t, 0.0, 0.2)) - suave(tramo(t, 0.82, 1.0))
    return sube, 3 * 2 * math.pi * max(0.0, min(1.0, tramo(t, 0.2, 0.82)))


def estirarse(t):
    """Se estira con pereza: sube despacio, se queda arriba un momento y baja."""
    return suave(tramo(t, 0.04, 0.24)) - suave(tramo(t, 0.36, 0.5))


def ojos_reaccion(t):
    """Abre de golpe en alerta, se relaja y parpadea hasta la expresión seria."""
    if t < 0.04:
        return {"cerrados": True}
    k = 1 - suave(tramo(t, 0.50, 0.70))
    return {"ancho": 1 + 0.12 * k, "alto": 1 + 0.22 * k, "cerrados": 0.78 <= t < 0.84}


def sobresalto(t):
    return 1.6 * math.exp(-((t - 0.07) / 0.05) ** 2)


def animacion(id_, nombre, descripcion, nota, **v):
    v.setdefault("aprobada", True)
    return {"nombre": nombre, "descripcion": descripcion,
            "variantes": [dict(id=id_, nombre=nombre, nota=nota, **v)]}


# Cámara cenital (como Minish Cap o los Pokémon clásicos): Gota en 4 direcciones.
# Abajo = de frente, arriba = de espaldas; la izquierda es el espejo de la derecha.
DIRECCIONES = {"abajo": 0, "abajo_derecha": 45, "derecha": 90, "arriba_derecha": 135, "arriba": 180}
# Direcciones en las que, al entrar en reposo prolongado, mira a la pantalla
MIRAN_PANTALLA = ("derecha", "abajo_derecha")
# El reposo prolongado mira a la cámara: de espaldas se gira y usa el de frente
DIRECCIONES_CAMARA = {"abajo": 0, "derecha": 90}


def en_direcciones(id_, nombre, descripcion, nota, direcciones=DIRECCIONES, **v):
    """Una animación con una variante por dirección (id_abajo, id_derecha, id_arriba)."""
    v.setdefault("aprobada", True)
    return {"nombre": nombre, "descripcion": descripcion,
            "variantes": [dict(id=f"{id_}_{d}", nombre=f"{nombre} · {d}", nota=nota, angulo=ang, **v)
                          for d, ang in direcciones.items()]}


# Propuestas de caminar serio y algo seguro (sin las manos atrás)
# Caminar elegido por el usuario (2026-10-16): «S1 · Serio y firme»
CAMINAR = en_direcciones(
    "caminar", "Caminar", "Caminar normal: erguida, paso medido y pisada firme (antes «S1 · Serio y firme»).",
    "Pasos y manos bien marcados, con un poco de gelatina.", ciclo=700, amplitud=0.01,
    caminar=dict(paso=6.5, alto=5, rebote=1.5, inclinacion=2, braceo=4, manoAlto=1.5, aplastar=0.02, pisada=0.4,
                 gelatina=0.022))

# Acciones. Elegidas por el usuario (2026-10-16): saltar (antes «C · Gota»), frenar al
# correr, frenar al caminar (antes «C · Paso de ajuste»), escupitajo y los golpes por nivel
# de pelea a mano limpia. El daño queda pendiente (dependerá de la zona y los enemigos).
GOLPES = [
    ("a", "A · Directo (nivel 0)", "Lanza una mano hacia delante y la recoge.", 650, golpe_directo),
    ("b", "B · Uno-dos (nivel 1+)", "Dos golpes, primero con una mano y después con la otra.", 850,
     golpe_uno_dos),
    ("c", "C · Embestida (nivel 2+)", "Coge impulso hacia atrás y se lanza con todo el cuerpo.", 850,
     golpe_embestida),
    ("d", "D · Gancho (nivel 3+)", "La mano baja, sale desde abajo y sube, con un saltito.", 750, golpe_gancho),
    ("e", "E · Ráfaga (nivel 3+)", "Cuatro puñetazos rápidos alternando las manos.", 1000, golpe_rafaga),
    ("g", "G · Giratorio (nivel 4)", "Da una vuelta completa con las manos abiertas, golpeando al pasar.", 900,
     golpe_giratorio),
]
ACCIONES = [
    # Salto físico: el juego sube y baja a Gota; estas son sus posturas (sin sombra en el aire)
    en_direcciones("saltar_aire", "Saltar · en el aire",
                   "Postura en el aire del salto «Gota»; el juego elige el fotograma según el vuelo.",
                   "Se estira al subir, se recoge al caer, con los pies recogidos.",
                   ciclo=600, ms=50, bucle=False, amplitud=0.01, ojos=PARPADEO, sin_sombra=True,
                   accion_t=aire(0.13, 0.4, 3)),
    en_direcciones("saltar_aire_correr", "Saltar corriendo · en el aire",
                   "Salto largo corriendo: el juego conserva la velocidad que llevaba.",
                   "Inclinada hacia delante, una pierna delante y otra detrás y las manos atrás.",
                   ciclo=600, ms=50, bucle=False, amplitud=0.01, ojos=PARPADEO, sin_sombra=True,
                   caminar=dict(manosAtras=True), accion_t=aire_corriendo),
    en_direcciones("saltar_atras_aire", "Saltar hacia atrás · en el aire",
                   "Salto hacia atrás sin dejar de mirar al frente; el juego la desplaza.",
                   "Echada hacia atrás y con las manos por delante.",
                   ciclo=600, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_golpe, sin_sombra=True,
                   accion_t=aire(0.1, 0.2, -6)),
    # Caída en picado (saltar y agacharse en el aire), elegida por el usuario (2026-10-16):
    # «D3d · charco que se forma de abajo arriba». Se estira como una gota de lluvia, cae sin
    # manos ni pies, se aplasta en un charco y se levanta como una cúpula; la punta, la última.
    en_direcciones("gota_estirar", "Caída en picado · se estira como una gota de lluvia",
                   "Al empezar a caer se estira hacia arriba (sin manos ni pies).", "0,15 s, sin sombra.",
                   ciclo=150, ms=40, bucle=False, amplitud=0.01, ojos_t=ojos_golpe, sin_sombra=True,
                   accion_t=lambda t: {"k": 0.22 * suave(t * 1.2), "manos": 0.6 * suave(t * 1.2),
                                       "recoge": suave(t * 1.2)}, sin_extremidades=1),
    en_direcciones("gota_cayendo", "Caída en picado · cayendo estirada",
                   "Cae estirada, temblando un poco por la velocidad.", "Bucle corto, sin sombra.",
                   ciclo=240, ms=40, amplitud=0.01, ojos_t=ojos_golpe, sin_sombra=True,
                   accion_t=lambda t: {"k": 0.22 + 0.02 * math.sin(2 * math.pi * t), "manos": 0.6, "recoge": 1,
                                       "sesgo": 2 * math.sin(2 * math.pi * t)}, sin_extremidades=1),
    en_direcciones("gota_impacto_charco_forma", "Caída en picado · se hace charco y se forma de abajo arriba",
                   "Se aplasta en un charco tembloroso, se levanta como una cúpula y la punta se forma la última.",
                   "0,95 s; manos y pies reaparecen al final.",
                   ciclo=950, ms=40, bucle=False, amplitud=0.01, ojos_t=lambda t: {"cerrados": t < 0.6},
                   accion_t=charco_forma, bola_t=bola_charco_forma, agachada=1, sin_extremidades_t=reaparecen),
    # Derrota (vida a 0): propuestas
    en_direcciones("derrota_a", "Derrota A · se aplana y se desvanece",
                   "Se aplana poco a poco hasta ser un charco, cierra los ojos y se desvanece.", "1,6 s.",
                   ciclo=1600, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_derrota, accion_t=derrota_aplana,
                   sin_extremidades_t=lambda t: suave(t / 0.4),
                   opacidad_t=lambda t: 1 - suave((t - 0.5) / 0.48), aprobada=False),
    en_direcciones("derrota_b", "Derrota B · se derrite y se evapora",
                   "Se derrite temblando hasta un charco y se evapora (el juego dibuja el vapor).", "1,8 s.",
                   ciclo=1800, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_derrota, accion_t=derrota_derrite,
                   sin_extremidades_t=lambda t: suave(t / 0.35),
                   opacidad_t=lambda t: 1 - suave((t - 0.4) / 0.58), aprobada=False),
    en_direcciones("derrota_c", "Derrota C · se filtra en el suelo",
                   "Se aplana en un charco que se va encogiendo, como si el suelo se lo bebiera.", "1,6 s.",
                   ciclo=1600, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_derrota, accion_t=derrota_filtra,
                   sin_extremidades_t=lambda t: suave(t / 0.3),
                   opacidad_t=lambda t: 1 - suave((t - 0.8) / 0.18), aprobada=False),
    en_direcciones("aterrizar", "Aterrizar",
                   "Al tocar el suelo (una vez); se corta al moverse o con cualquier botón.",
                   "Como una gota que choca: se aplasta, rebota estirándose y se asienta temblando. 0,5 s.",
                   ciclo=500, ms=40, bucle=False, amplitud=0.01, ojos=PARPADEO, accion_t=aterrizar),
    en_direcciones("frenar", "Frenar al correr",
                   "Al dejar de correr (una vez); el juego la hace deslizar un poco hasta parar.",
                   "Como un líquido: la punta sigue por inercia y se bambolea, se aplasta y temblequea, "
                   "y salpica unas gotitas. 0,6 s.",
                   ciclo=600, bucle=False, amplitud=0.01, ojos=PARPADEO, accion_t=frenar),
    en_direcciones("frenar_caminar", "Frenar al caminar",
                   "Al dejar de caminar (una vez).",
                   "Da un último paso corto para juntar los pies y se asienta temblando como gelatina. 0,6 s.",
                   ciclo=600, bucle=False, amplitud=0.01, ojos=PARPADEO, accion_t=frenar_paso),
    # Escupitajo cargado (nivel 4): mientras se mantiene, el juego dibuja la bola de ácido
    # creciendo dentro del cuerpo; al soltar, se contrae y la lanza
    en_direcciones("cargar_acido", "Cargar ácido (nivel 4)",
                   "Mientras se mantiene el botón: se hincha y late; la bola crece dentro (la dibuja el juego).",
                   "Bucle de 0,8 s.", ciclo=800, ms=50, amplitud=0.01, ojos_t=ojos_golpe, accion_t=cargar_acido),
    en_direcciones("soltar_acido", "Soltar ácido (nivel 4)",
                   "Al soltar el botón (una vez): se contrae de golpe y lanza la bola; más carga, más grande.",
                   "0,4 s; la bola sale en el tercer fotograma.",
                   ciclo=400, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_golpe, accion_t=soltar_acido),
    *[en_direcciones(f"golpear_{letra}{aereo}", f"Golpear · {nombre}{' · en el aire' if aereo else ''}",
                     "Golpe a mano limpia (una vez), en la dirección en que mira. Se encadena en combo."
                     + (" Versión aérea, sin sombra: se puede saltar y golpear a la vez." if aereo else ""),
                     nota, ciclo=ciclo, ms=50, bucle=False, amplitud=0.01, ojos_t=ojos_golpe, accion_t=f,
                     sin_sombra=bool(aereo))
      for letra, nombre, nota, ciclo, f in GOLPES for aereo in ("", "_aire")],
    # Daño: propuestas, pendiente de decidir según zonas y enemigos
    en_direcciones("dano_a", "Recibir daño · A · Temblor",
                   "Al recibir un golpe (una vez).",
                   "Pequeño temblor y cierre breve de los ojos, como dice el documento. 0,6 s.",
                   ciclo=600, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano,
                   accion_t=dano(3, 0, 0.05, 0)),
    en_direcciones("dano_b", "Recibir daño · B · Retroceso",
                   "Al recibir un golpe (una vez).",
                   "Sale empujada hacia atrás, se echa para atrás y parpadea en transparencia. 0,7 s.",
                   ciclo=700, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano,
                   accion_t=dano(1.5, 10, 0.06, 0.5)),
    en_direcciones("dano_c", "Recibir daño · C · Aplastón",
                   "Al recibir un golpe (una vez).",
                   "Se aplasta con el golpe y vuelve a su forma temblando como el agua. 0,8 s.",
                   ciclo=800, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano,
                   accion_t=dano(1, 0, 0.2, 0)),
    en_direcciones("dano_d", "Recibir daño · D · Salpicadura",
                   "Al recibir un golpe (una vez).",
                   "El golpe la abolla, retrocede un poco y le salta agua por detrás. 0,7 s.",
                   ciclo=700, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano,
                   accion_t=dano_salpicadura),
    en_direcciones("dano_e", "Recibir daño · E · Ondulación",
                   "Al recibir un golpe (una vez).",
                   "Se ondula como el agua cuando cae una piedra y se vuelve más transparente. 0,8 s.",
                   ciclo=800, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano,
                   accion_t=dano_ondulacion),
    en_direcciones("dano_f", "Recibir daño · F · Tambaleo",
                   "Al recibir un golpe fuerte (una vez).",
                   "Retrocede tambaleándose, mareada, y recupera el equilibrio. 1 s.",
                   ciclo=1000, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano_largo,
                   accion_t=dano_tambaleo),
    en_direcciones("dano_g", "Recibir daño · G · Derrame",
                   "Al recibir un golpe muy fuerte (una vez).",
                   "Pierde la forma un instante, casi como un charco, y se recompone. 1 s.",
                   ciclo=1000, bucle=False, aprobada=False, amplitud=0.01, ojos_t=ojos_dano_largo,
                   accion_t=dano_derrame),
]

# Desplazamiento aprobado (2026-10-16). Al correr, de perfil, lleva las manos atrás (estilo Naruto)
PASO_CORRER = dict(paso=8, alto=8, rebote=4.5, vuelo=4, inclinacion=10, braceo=8, aplastar=0.03,
                   manoAlto=4, bamboleo=2.5, manosAtras=True, gelatina=0.02, gotitas=3)
PASO_SIGILOSO = dict(paso=7.5, alto=8, rebote=0.8, inclinacion=5, braceo=3.5, manoAlto=1.5, gelatina=0.018)

DESPLAZAMIENTO = [
    en_direcciones("correr", "Correr", "Con el botón de correr (antes «A · Carrera decidida»).",
                   "Zancadas largas, inclinada de perfil y con los dos pies en el aire a mitad de zancada.",
                   ciclo=480, amplitud=0.01, caminar=PASO_CORRER),
    en_direcciones("caminar_sigiloso", "Caminar sigilosa", "Con el botón de agacharse pulsado.",
                   "Pasos lentos y largos, levanta mucho los pies y casi no rebota.",
                   ciclo=1250, amplitud=0.01, caminar=PASO_SIGILOSO, agachada=1),
    en_direcciones("reposo_agachada", "Reposo agachada",
                   "Con el botón de agacharse pulsado y sin moverse: agachada, seria y atenta.",
                   "Respira despacio y parpadea una vez.",
                   ciclo=2400, respiraciones=1, agachada=1, ojos=PARPADEO, aprobada=True),
]

# Reposos en 4 direcciones (propuesta): los mismos que a 45°, de frente, de perfil y de espaldas
REPOSOS_CENITAL = [
    en_direcciones("reposo", "Reposo", "Idle normal. Expresión: seria con parpadeo.",
                   "Respira dos veces cada 3,2 s y parpadea una vez.",
                   ciclo=3200, respiraciones=2, ojos=PARPADEO, aprobada=True),
    animacion("saludar_abajo", "Saludar",
              "A los 10 s quieta, solo si está de frente (una vez): saluda a la pantalla con la mano. "
              "Expresión seria con un parpadeo.",
              "Sube la mano junto a la cabeza, la mueve tres veces y la baja. 2,2 s.",
              angulo=0, ciclo=2200, respiraciones=1, bucle=False, aprobada=True,
              saludo_t=saludar, ojos=PARPADEO),
    # Reposo prolongado (tras 20 s quieta): se sienta apoyada en las manos y, a los 6 s,
    # se acurruca de rodillas. Al moverse se levanta en alerta y después anda.
    {"nombre": "Reposo prolongado · entrada",
     "descripcion": "Quieta 20 s (una vez). De frente: no se gira; de perfil: mira a la pantalla; "
                    "de espaldas: se estira con pereza. Después se sienta apoyándose en las manos.",
     "variantes": [
         {"id": "reposo_prolongado_entrada_abajo", "nombre": "Entrada · abajo", "angulo": 0,
          "nota": "Sin girarse: se sienta apoyada en las manos y baja los párpados. 4 s.",
          "ciclo": 4000, "respiraciones": 2, "bucle": False, "aprobada": True,
          "sentada_t": lambda t: suave(tramo(t, 0.1, 0.4)), "ojos_t": ojos_relajar(0.48)},
         {"id": "reposo_prolongado_entrada_derecha", "nombre": "Entrada · derecha", "angulo": 90,
          "nota": "Mira a la pantalla, se sienta apoyada en las manos y baja los párpados. 4,4 s.",
          "ciclo": 4400, "respiraciones": 2, "bucle": False, "aprobada": True,
          "sentada_t": lambda t: suave(tramo(t, 0.22, 0.5)), "ojos_t": ojos_relajar(0.55, mirar=True)},
         {"id": "reposo_prolongado_entrada_arriba", "nombre": "Entrada · arriba", "angulo": 180,
          "nota": "Se estira con pereza (manos arriba) y después se sienta apoyada en las manos. 4,4 s.",
          "ciclo": 4400, "respiraciones": 2, "bucle": False, "aprobada": True,
          "estirar_t": estirarse, "sentada_t": lambda t: suave(tramo(t, 0.55, 0.82)),
          "ojos_t": ojos_relajar(0.6)},
         {"id": "reposo_prolongado_entrada_abajo_derecha", "nombre": "Entrada · abajo-derecha", "angulo": 45,
          "nota": "Como de perfil: mira a la pantalla, se sienta y baja los párpados. 4,4 s.",
          "ciclo": 4400, "respiraciones": 2, "bucle": False, "aprobada": True,
          "sentada_t": lambda t: suave(tramo(t, 0.22, 0.5)), "ojos_t": ojos_relajar(0.55, mirar=True)},
         {"id": "reposo_prolongado_entrada_arriba_derecha", "nombre": "Entrada · arriba-derecha", "angulo": 135,
          "nota": "Como de espaldas: se estira con pereza y después se sienta. 4,4 s.",
          "ciclo": 4400, "respiraciones": 2, "bucle": False, "aprobada": True,
          "estirar_t": estirarse, "sentada_t": lambda t: suave(tramo(t, 0.55, 0.82)),
          "ojos_t": ojos_relajar(0.6)},
     ]},
    {"nombre": "Reposo prolongado · sentada",
     "descripcion": "Sentada, echada un poco hacia atrás y apoyada en las manos, con los párpados a media "
                    "altura. A los 6 s se acurruca.",
     "variantes": [{"id": f"reposo_sentada_{d}", "nombre": f"Sentada · {d}", "angulo": ang,
                    "nota": "Bucle de 2,4 s; el juego cuenta los 6 s.", "ciclo": 2400, "respiraciones": 1,
                    "sentada": 1, "ojos": {"parpado": (0.38, 0.38), "mirada": -28 if d in MIRAN_PANTALLA else 0},
                    "aprobada": True}
                   for d, ang in DIRECCIONES.items()]},
    {"nombre": "Reposo prolongado · acurrucarse",
     "descripcion": "Pasa de sentada a acurrucada de rodillas (una vez) y cierra los ojos.",
     "variantes": [{"id": f"acurrucarse_{d}", "nombre": f"Acurrucarse · {d}", "angulo": ang,
                    "nota": "Recoge los pies debajo, las manos delante y se encoge. 1,6 s.",
                    "ciclo": 1600, "respiraciones": 1, "bucle": False, "sentada": 1,
                    "acurruca_t": lambda t: suave(tramo(t, 0.05, 0.8)),
                    "ojos_t": ojos_cerrar(-28 if d in MIRAN_PANTALLA else 0), "aprobada": True}
                   for d, ang in DIRECCIONES.items()]},
    en_direcciones("reposo_prolongado", "Reposo prolongado · bucle",
                   "Acurrucada de rodillas, con los ojos cerrados y un ligero pulso de transparencia.",
                   "El cuerpo baja hasta el 75 % de opacidad y vuelve, en 2 s.",
                   ciclo=2000, pulso=0.25, sentada=1, acurruca=1, ojos={"cerrados": True}, zzz=True,
                   aprobada=True),
    {"nombre": "Levantarse en alerta",
     "descripcion": "Al moverse durante el reposo prolongado (una vez): se levanta de un respingo con los "
                    "ojos de alerta y después echa a andar.",
     "variantes": [{"id": f"levantarse{origen}_{d}", "nombre": f"Levantarse {nombre} · {d}", "angulo": ang,
                    "nota": "0,7 s.", "ciclo": 700, "respiraciones": 1, "bucle": False,
                    "sentada_t": lambda t: 1 - suave(tramo(t, 0.1, 0.75)),
                    "acurruca_t": (lambda t: 1 - suave(tramo(t, 0.0, 0.6))) if origen == "" else (lambda t: 0),
                    "extra_a": sobresalto, "ojos_t": ojos_levantarse(-28 if d in MIRAN_PANTALLA else 0),
                    "aprobada": True}
                   for origen, nombre in (("", "(acurrucada)"), ("_sentada", "(sentada)"))
                   for d, ang in DIRECCIONES.items()]},
    en_direcciones("reposo_alerta", "Reposo en alerta · ojos de alerta",
                   "Zona peligrosa: respiración corta, manos altas, pies abiertos y ojos de alerta.",
                   "De espaldas no se ven los ojos: la alerta se nota en la postura.",
                   ciclo=2500, respiraciones=2, amplitud=0.018, manos=1.2, postura=ALERTA,
                   ojos=dict(OJOS_ALERTA, **PARPADEO), aprobada=True),
    en_direcciones("reposo_determinada", "Reposo en alerta · determinada",
                   "Misma postura de alerta, con la mirada determinada.",
                   "Para enemigos o zonas muy peligrosas: se planta y no retrocede.",
                   ciclo=2500, respiraciones=2, amplitud=0.018, manos=1.2, postura=ALERTA,
                   ojos=dict(OJOS_DETERMINADA, **PARPADEO), aprobada=True),
    en_direcciones("reposo_preocupada", "Reposo · preocupada",
                   "Idle normal con la mirada preocupada, según el contexto de la historia.",
                   "Su lado sensible, sin dramatismo.",
                   ciclo=3200, respiraciones=2, ojos=dict(OJOS_PREOCUPADA, **PARPADEO), aprobada=True),
    en_direcciones("reposo_recelosa", "Reposo · recelosa",
                   "Idle normal con los ojos entrecerrados, según el contexto de la historia.",
                   "Desconfía o se concentra.",
                   ciclo=3200, respiraciones=2, ojos=dict(OJOS_RECELOSA, **PARPADEO), aprobada=True),
]


# Animaciones a 45° (vista lateral anterior). Se retiran cuando se aprueben los reposos cenitales.
PROPUESTAS = [
    *ACCIONES,
    CAMINAR,
    *REPOSOS_CENITAL,
    *DESPLAZAMIENTO,
    animacion("caminar_sigiloso", "Caminar sigilosa (45°)",
              "Con el botón de agacharse pulsado: pasos lentos y largos, sin apenas rebote.",
              "Antes «F · Sigilosa». Levanta mucho los pies, misteriosa, como si acechara.",
              ciclo=1200, amplitud=0.01,
              caminar=dict(paso=7, alto=8, rebote=0.8, inclinacion=5, braceo=2, manoAlto=1)),
    animacion("reposo", "Reposo", "Idle normal. Expresión: seria con parpadeo.",
              "Respira dos veces cada 3,2 s y parpadea una vez.",
              ciclo=3200, respiraciones=2, ojos=PARPADEO),
    animacion("reposo_prolongado_entrada", "Reposo prolongado · entrada",
              "Cuando lleva mucho tiempo quieta (se reproduce una vez): mira a la cámara, "
              "baja los párpados a media altura y cierra los ojos.",
              "4 s. Al terminar enlaza con el bucle de reposo prolongado.",
              ciclo=4000, respiraciones=2, ojos_t=ojos_entrada_prolongado, bucle=False),
    animacion("reposo_prolongado", "Reposo prolongado · bucle",
              "Ojos cerrados y ligero pulso de transparencia, como si respirara.",
              "El cuerpo baja hasta el 75 % de opacidad y vuelve, en 2 s.",
              ciclo=2000, pulso=0.25, ojos={"cerrados": True}),
    animacion("reaccion_movimiento", "Reacción al movimiento",
              "Cuando detecta movimiento (se reproduce una vez): alerta y luego seria con parpadeo.",
              "Abre los ojos de golpe con un pequeño sobresalto, los relaja y parpadea. 1,8 s.",
              ciclo=1800, respiraciones=1, ojos_t=ojos_reaccion, extra_a=sobresalto, bucle=False),
    animacion("reposo_alerta", "Reposo en alerta · ojos de alerta",
              "Zona peligrosa: respiración corta, manos altas, pies abiertos y ojos de alerta.",
              "Para peligro moderado o al recuperarse de un golpe. Parpadea una vez por ciclo.",
              ciclo=2500, respiraciones=2, amplitud=0.018, manos=1.2, postura=ALERTA,
              ojos=dict(OJOS_ALERTA, **PARPADEO)),
    animacion("reposo_determinada", "Reposo en alerta · determinada",
              "Misma postura de alerta, con la mirada determinada.",
              "Para enemigos o zonas muy peligrosas: se planta y no retrocede.",
              ciclo=2500, respiraciones=2, amplitud=0.018, manos=1.2, postura=ALERTA,
              ojos=dict(OJOS_DETERMINADA, **PARPADEO)),
    animacion("reposo_preocupada", "Reposo · preocupada",
              "Idle normal con la mirada preocupada, según el contexto de la historia.",
              "Su lado sensible, sin dramatismo.",
              ciclo=3200, respiraciones=2, ojos=dict(OJOS_PREOCUPADA, **PARPADEO)),
    animacion("reposo_recelosa", "Reposo · recelosa",
              "Idle normal con los ojos entrecerrados, según el contexto de la historia.",
              "Desconfía o se concentra.",
              ciclo=3200, respiraciones=2, ojos=dict(OJOS_RECELOSA, **PARPADEO)),
]


def main():
    base = os.path.abspath(sys.argv[1])
    rev = os.path.join(base, "revision")
    carpeta = os.path.join(rev, "sprites")
    fuentes = os.path.join(base, "fuentes")
    os.makedirs(carpeta, exist_ok=True)
    os.makedirs(fuentes, exist_ok=True)
    # Uso: gota_hk.py <carpeta Arte/Gota> [prefijo]  -> solo genera las animaciones
    # cuyo id empieza por el prefijo y conserva el resto del manifiesto
    prefijo = sys.argv[2] if len(sys.argv) > 2 else ""
    ruta_manifiesto = os.path.join(rev, "manifest.json")
    previas = []
    if prefijo and os.path.exists(ruta_manifiesto):
        with open(ruta_manifiesto, encoding="utf-8") as f:
            previas = json.load(f)["animaciones"]
    animaciones = []
    for anim in PROPUESTAS:
        if not anim["variantes"][0]["id"].startswith(prefijo):
            continue
        variantes = []
        for v in anim["variantes"]:
            n = max(8, round(v["ciclo"] / v.get("ms", MS_FOTOGRAMA)))
            svg, w, h = hoja_svg(v, n)
            svg_path = os.path.join(fuentes, v["id"] + ".svg")
            with open(svg_path, "w", encoding="utf-8") as f:
                f.write(svg)
            renderizar(svg_path, os.path.join(carpeta, v["id"] + ".png"), w, h)
            variantes.append({"id": v["id"], "nombre": v["nombre"], "nota": v["nota"],
                              "hoja": f"sprites/{v['id']}.png", "cols": COLS, "n": n,
                              "duraciones": [round(v["ciclo"] / n)] * n,
                              "bucle": v.get("bucle", True),
                              "aprobada": v.get("aprobada", False)})
            print("ok", v["id"], n, "fotogramas")
        animaciones.append({"nombre": anim["nombre"], "descripcion": anim["descripcion"],
                            "multiple": anim.get("multiple", False), "variantes": variantes})
    # Las nuevas van primero en la página; las demás se conservan
    nuevas = {v["id"] for a in animaciones for v in a["variantes"]}
    animaciones += [a for a in previas if not any(v["id"] in nuevas for v in a["variantes"])]
    with open(ruta_manifiesto, "w", encoding="utf-8") as f:
        json.dump({"tam": TAM, "escalaFuente": ESCALA, "suave": True,
                   "animaciones": animaciones}, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
