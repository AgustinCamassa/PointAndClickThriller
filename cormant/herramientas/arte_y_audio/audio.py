import numpy as np, wave, subprocess, os
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
DEST = "../../assets/audio"
TMP = "/tmp/cormant_wav"
os.makedirs(DEST, exist_ok=True); os.makedirs(TMP, exist_ok=True)
rng = np.random.RandomState(7)

def t_(seg): return np.arange(int(seg*SR))/SR
def bp(x, lo, hi, orden=2):
    return sosfilt(butter(orden, [lo, hi], btype="band", fs=SR, output="sos"), x)
def lp(x, f, orden=2): return sosfilt(butter(orden, f, btype="low", fs=SR, output="sos"), x)
def hp(x, f, orden=2): return sosfilt(butter(orden, f, btype="high", fs=SR, output="sos"), x)
def env_ad(n, ataque, caida):
    t = np.arange(n)/SR
    return np.minimum(t/max(ataque, 1e-4), 1.0)*np.exp(-t/caida)
def ruido_periodico(seg, lo, hi, pend=0.0, semilla=None):
    """Ruido de banda perfectamente periódico (apto para bucles)."""
    r = np.random.RandomState(semilla if semilla is not None else rng.randint(1e6))
    n = int(seg*SR)
    f = np.fft.rfftfreq(n, 1/SR)
    mag = np.where((f >= lo) & (f <= hi), 1.0, 0.0)*(np.maximum(f, 1.0)**pend)
    fase = r.uniform(0, 2*np.pi, len(f))
    x = np.fft.irfft(mag*np.exp(1j*fase), n)
    return x/np.max(np.abs(x))
def tono_p(seg, f, fase=0.0):
    f = max(1, round(f*seg))/seg
    return np.sin(2*np.pi*f*t_(seg)+fase)
def reverb(x, tiempo=1.6, mezcla=0.3, semilla=3):
    r = np.random.RandomState(semilla)
    n = int(tiempo*SR)
    ir = r.randn(n)*np.exp(-np.arange(n)/SR*6.0/tiempo)
    ir = lp(ir, 5000)
    y = fftconvolve(x, ir)[:len(x)+n]
    y /= np.max(np.abs(y))+1e-9
    out = np.zeros(len(y)); out[:len(x)] += x*(1-mezcla)
    return out+y*mezcla*np.max(np.abs(x))
def norm(x, pico):
    return x/(np.max(np.abs(x))+1e-9)*pico
def anillo(x, pos, pulso):
    """Suma un pulso en 'pos' (s) con envoltura circular, para bucles."""
    n = len(x); i = int(pos*SR)
    idx = (np.arange(len(pulso))+i) % n
    np.add.at(x, idx, pulso)
def cerrar_bucle(x, seg):
    n = int(seg*SR)
    if len(x) > n:
        cola = x[n:]
        x = x[:n].copy()
        x[:len(cola)] += cola[:n]
    return x
def guardar(nombre, x, pico=0.8, bucle=False):
    x = np.clip(norm(x, pico), -1, 1)
    ruta = os.path.join(TMP, nombre+".wav")
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x*32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", ruta, "-c:a", "libvorbis", "-q:a", "4", os.path.join(DEST, nombre+".ogg")], check=True)

# ---------------------------------------------------------- bucles ambientales
def zumbido(seg, base=60, arm=(1, 2, 3, 5), niv=(1, .5, .3, .15)):
    return sum(n*tono_p(seg, base*a) for a, n in zip(arm, niv))

def ambiente_recepcion():
    L = 20
    x = 0.5*zumbido(L, 60)+0.25*ruido_periodico(L, 80, 900, -0.5, 1)+0.05*ruido_periodico(L, 2000, 4500, 0, 2)*(0.6+0.4*tono_p(L, 0.2))
    x += 0.04*tono_p(L, 120)*(0.5+0.5*tono_p(L, 0.35))
    for p in (3.1, 9.4, 15.2):    # chasquidos del fluorescente
        anillo(x, p, 0.5*env_ad(int(0.03*SR), 0.001, 0.008)*rng.randn(int(0.03*SR)))
    return x
def ambiente_pasillo():
    L = 24
    x = 0.6*tono_p(L, 44)+0.35*tono_p(L, 88)+0.3*ruido_periodico(L, 100, 700, -0.7, 3)*(0.7+0.3*tono_p(L, 1/12))
    x += 0.12*ruido_periodico(L, 600, 1800, 0, 4)*(0.5+0.5*tono_p(L, 1/8, 1.0))
    return x
def ambiente_vigilancia():
    L = 20
    x = 0.4*zumbido(L, 60, (1, 2, 4), (1, .4, .2))+0.3*ruido_periodico(L, 120, 1000, -0.6, 5)
    x += 0.025*tono_p(L, 7800)+0.02*tono_p(L, 3900)
    for p in (2.2, 6.5, 11.7, 16.1, 18.3):       # relés
        anillo(x, p, 0.7*env_ad(int(0.04*SR), 0.0005, 0.01)*np.sign(rng.randn(int(0.04*SR))))
    return x
def ambiente_laboratorio():
    L = 24
    x = 0.4*tono_p(L, 100)+0.25*tono_p(L, 200)+0.3*ruido_periodico(L, 60, 500, -0.5, 6)
    burb = bp(ruido_periodico(L, 100, 800, 0, 7), 150, 500)*np.clip(tono_p(L, 1.5)+tono_p(L, 2.3), 0, 1)
    x += 0.35*burb
    for p in np.arange(2, L, 6):                 # pitido de un equipo
        anillo(x, p, 0.18*np.sin(2*np.pi*1180*t_(0.12))*env_ad(int(0.12*SR), 0.003, 0.05))
    return x
def ambiente_oficina():
    L = 20
    x = 0.25*zumbido(L, 60, (1, 2), (1, .3))+0.2*ruido_periodico(L, 80, 600, -0.8, 8)
    for p in np.arange(0.5, L, 1.0):             # reloj de pared
        n = int(0.05*SR)
        tic = bp(rng.randn(n), 1500, 4000)*env_ad(n, 0.0005, 0.008)
        anillo(x, p, 0.9*tic*(1.0 if int(p) % 2 == 0 else 0.75))
    return x
def ambiente_habitacion():
    L = 20
    x = 0.3*tono_p(L, 50)+0.18*ruido_periodico(L, 60, 400, -0.6, 9)
    for p in np.arange(0.2, L, L/24):            # monitor de pulso: 72 pulsaciones/min
        n = int(0.11*SR)
        anillo(x, p, 0.5*np.sin(2*np.pi*880*np.arange(n)/SR)*env_ad(n, 0.002, 0.07))
    for p in (4.7, 13.3):                         # gotas
        n = int(0.25*SR)
        anillo(x, p, 0.4*np.sin(2*np.pi*(900-np.arange(n)/SR*2200)*np.arange(n)/SR)*env_ad(n, 0.001, 0.04))
    return x
def ambiente_pasillo_alterado():
    L = 24
    x = 0.5*tono_p(L, 36)+0.3*tono_p(L, 54.5)+0.2*tono_p(L, 72.7)
    viento = bp(ruido_periodico(L, 200, 1200, 0, 10), 250, 900)*(0.5+0.5*tono_p(L, 1/6))
    x += 0.5*viento*(0.6+0.4*tono_p(L, 1/4, 2.0))
    for p in (3.0, 8.2, 14.7, 20.5):
        n = int(0.35*SR)
        anillo(x, p, 0.35*np.sin(2*np.pi*(700-np.arange(n)/SR*1800)*np.arange(n)/SR)*env_ad(n, 0.001, 0.05))
    anillo(x, 11.0, 0.5*bp(rng.randn(int(0.9*SR)), 300, 800)*env_ad(int(0.9*SR), 0.2, 0.3))   # crujido metálico
    return x
def ambiente_tramo(n):
    L = 16
    if n == 1:
        return 0.6*tono_p(L, 38)+0.3*tono_p(L, 57)+0.15*ruido_periodico(L, 60, 300, -1, 11)
    if n == 2:
        return 0.6*tono_p(L, 34)*(0.7+0.3*tono_p(L, 0.5))+0.35*tono_p(L, 51)+0.2*tono_p(L, 203.5)*(0.3+0.7*tono_p(L, 0.25))+0.2*ruido_periodico(L, 60, 400, -1, 12)
    x = 0.8*tono_p(L, 28)*(0.6+0.4*tono_p(L, 1.0))+0.4*tono_p(L, 42)+0.3*tono_p(L, 63.7)
    x += 0.25*(tono_p(L, 311)+tono_p(L, 330.5))*(0.2+0.8*np.abs(tono_p(L, 0.5)))
    x += 0.15*bp(ruido_periodico(L, 300, 900, 0, 13), 300, 900)*(0.5+0.5*tono_p(L, 0.25, 1.0))
    return x
def tono_grave():
    L = 12
    return 0.7*tono_p(L, 55)+0.7*tono_p(L, 56.75)+0.3*tono_p(L, 110)*(0.5+0.5*tono_p(L, 0.25))+0.1*ruido_periodico(L, 40, 200, 0, 14)
def susurro_base(L, bursts, semilla, periodico=True):
    n = int(L*SR); y = np.zeros(n); r = np.random.RandomState(semilla)
    for _ in range(bursts):
        p = r.uniform(0, L-0.5); d = r.uniform(0.12, 0.35); m = int(d*SR)
        b = bp(r.randn(m), 1800, 6500)*0.7 + bp(r.randn(m), 500, 1400)*0.5
        e = np.sin(np.linspace(0, np.pi, m))**2
        idx = (np.arange(m)+int(p*SR)) % n
        np.add.at(y, idx, b*e)
    return y
def susurro_fijo():
    return reverb(susurro_base(12, 30, 21), 1.2, 0.3)
def musica_titulo():
    L = 32
    x = 0.45*tono_p(L, 55)+0.25*tono_p(L, 82.5)
    for f, niv in [(220, .22), (261.6, .18), (329.6, .14), (415.3, .10)]:
        x += niv*tono_p(L, f)*(0.5+0.5*tono_p(L, 1/16, f/100))
    notas = [(1.0, 440), (5.0, 523.3), (9.0, 659.3), (13.0, 392), (17.0, 440), (21.5, 622.3), (25.0, 523.3), (28.5, 329.6)]
    for p, f in notas:
        n = int(5.0*SR); tt = np.arange(n)/SR
        campana = (np.sin(2*np.pi*f*tt+1.5*np.sin(2*np.pi*f*2.01*tt)*np.exp(-tt/0.6))*np.exp(-tt/1.6))*0.28
        anillo(x, p, campana)
    x += 0.12*ruido_periodico(L, 100, 800, -1, 15)*(0.5+0.5*tono_p(L, 1/8))
    return reverb(x, 2.2, 0.3)

# ---------------------------------------------------------- efectos
def alerta_terminal():
    n = int(0.14*SR); tt = np.arange(n)/SR
    b = lambda f: np.sign(np.sin(2*np.pi*f*tt))*0.4*env_ad(n, 0.002, 0.06)+np.sin(2*np.pi*f*tt)*0.4*env_ad(n, 0.002, 0.08)
    x = np.concatenate([b(1250), np.zeros(int(0.05*SR)), b(940)])
    return lp(x, 5000)
def detector_bip():
    n = int(0.1*SR); tt = np.arange(n)/SR
    x = np.sin(2*np.pi*1900*tt)*0.55*env_ad(n, 0.002, 0.05) + np.sign(np.sin(2*np.pi*1900*tt))*0.25*env_ad(n, 0.002, 0.04)
    return lp(x, 6000)


def detector_alarma():
    """Pitido grave y suave (unos 620 Hz con leve trémolo), distinto de los 1900 Hz del aviso y de los 1000 Hz de la CAM 3."""
    n = int(0.22*SR); tt = np.arange(n)/SR
    x = (np.sin(2*np.pi*620*tt) + 0.3*np.sin(2*np.pi*930*tt))*(0.8+0.2*np.sin(2*np.pi*22*tt))*env_ad(n, 0.01, 0.12)
    return lp(x, 2500)*0.6


def tecla():
    n = int(0.06*SR); tt = np.arange(n)/SR
    return (bp(rng.randn(n), 1500, 5000)*0.5 + np.sin(2*np.pi*1100*tt)*0.4)*env_ad(n, 0.001, 0.035)*0.8


def apagon_inicio():
    """Corte de corriente: golpe grave, caída de tono (220 -> 35 Hz) y chasquido de relés."""
    L = 1.4; n = int(L*SR); tt = np.arange(n)/SR
    f = 35 + 185*np.exp(-tt*3.2)
    x = np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-tt*1.6)*0.9
    x += 0.5*bp(rng.randn(n), 80, 900)*np.exp(-tt*18)
    x += 0.35*np.sign(np.sin(2*np.pi*55*tt))*np.exp(-tt*5)
    x += 0.25*bp(rng.randn(n), 2500, 6000)*np.exp(-((tt-0.08)**2)/0.0004)
    return reverb(lp(x, 3000), 1.4, 0.3)*0.9


def apagon_fin():
    """Vuelve la corriente: chasquido y zumbido que sube de 40 a 110 Hz hasta estabilizarse."""
    L = 1.1; n = int(L*SR); tt = np.arange(n)/SR
    f = 40 + 70*(1-np.exp(-tt*5))
    x = np.sin(2*np.pi*np.cumsum(f)/SR)*0.5*np.minimum(1, tt/0.1)*np.minimum(1, (L-tt)/0.4)
    x += 0.3*np.sin(2*np.pi*50*tt)*np.minimum(1, (L-tt)/0.5)
    x += 0.6*bp(rng.randn(n), 1800, 7000)*np.exp(-tt*60)
    return lp(x, 4000)*0.8


def susurro_terminal():
    x = susurro_base(1.8, 7, 31)
    x = bp(x, 400, 3200)+0.05*bp(rng.randn(len(x)), 800, 3000)
    return x*np.minimum(1, np.minimum(np.arange(len(x))/2000, (len(x)-np.arange(len(x)))/4000))
def susurro_pasillo():
    x = np.concatenate([susurro_base(2.2, 9, 41), np.zeros(int(1.5*SR))])
    return reverb(x, 1.8, 0.55)
def estatica_breve():
    n = int(0.55*SR)
    x = rng.randn(n)*np.minimum(1, np.arange(n)/200)*np.exp(-np.arange(n)/SR/0.28)
    x += 0.5*hp(rng.randn(n), 3000)*(rng.rand(n) > 0.7)
    return x
def confirmacion():
    n = int(0.22*SR); tt = np.arange(n)/SR
    a = np.sin(2*np.pi*660*tt)*env_ad(n, 0.005, 0.1); b = np.sin(2*np.pi*990*tt)*env_ad(n, 0.005, 0.14)
    return reverb(np.concatenate([a, b, np.zeros(int(0.1*SR))]), 0.5, 0.2)
def error_terminal():
    n = int(0.5*SR); tt = np.arange(n)/SR
    saw = 2*((150*tt) % 1)-1
    x = (saw*0.6+np.sign(np.sin(2*np.pi*75*tt))*0.4)*np.minimum(1, tt/0.01)*np.exp(-tt/0.35)
    return lp(x, 2500)
def golpe_grave():
    n = int(1.6*SR); tt = np.arange(n)/SR
    x = np.sin(2*np.pi*(48+60*np.exp(-tt/0.04))*tt)*np.exp(-tt/0.35)
    x += 0.35*lp(rng.randn(n), 900)*np.exp(-tt/0.08)
    return reverb(x, 1.2, 0.3)
def advertencia_entidad():
    L = 7.0; n = int(L*SR); tt = np.arange(n)/SR
    sub = np.sin(2*np.pi*(38+10*tt/L)*tt)
    disc = np.sin(2*np.pi*(311+20*tt/L)*tt)*0.5+np.sin(2*np.pi*(329.6)*tt)*0.5
    pulso = 0.55+0.45*np.sin(2*np.pi*(1.0+2.5*tt/L)*tt)
    ruido = bp(rng.randn(n), 200, 2500)*(tt/L)**2*0.6
    x = (sub*0.8+disc*0.28*(tt/L)+ruido)*pulso*np.minimum(1, tt/0.6)
    x *= np.minimum(1, (L-tt)/0.5)
    return reverb(x, 1.5, 0.25)
def pasos_entidad():
    """Modo 3: pasos que se acercan (5 pisadas, cada vez más fuertes y más seguidas). Dura ~2,3 s: la ventana de reacción."""
    r = np.random.RandomState(31)
    L = 2.3; n = int(L*SR); x = np.zeros(n)
    tiempos = [0.05, 0.62, 1.12, 1.55, 1.93]
    for i, p in enumerate(tiempos):
        amp = 0.22 + 0.78*(i/(len(tiempos)-1))**1.2
        m = int(0.28*SR); tt = np.arange(m)/SR
        golpe = np.sin(2*np.pi*(78-40*tt/0.28)*tt)*np.exp(-tt/0.07)
        roce = lp(r.randn(m), 700)*np.exp(-tt/0.035)*0.9
        crujido = bp(r.randn(m), 900, 2200)*np.exp(-tt/0.015)*0.12*amp
        paso = (golpe + roce + crujido)*amp
        a = int(p*SR)
        x[a:a+m] += paso[:max(0, min(m, n-a))]
    return reverb(x, 1.3, 0.3)

def entidad_acecho():
    """Silueta que se acerca a la ventana de Vigilancia: chirrido agudo que sube, trémolo metálico y golpe grave final.
    Más estridente que pasos_entidad y que advertencia_entidad. Dura ~4,6 s (las 3 fases + el castigo)."""
    r = np.random.RandomState(52)
    L = 4.6; n = int(L*SR); tt = np.arange(n)/SR
    prog = tt/L
    f1 = 880 + 760*prog**1.5
    f2 = f1*1.0595*1.5            # segunda voz disonante (quinta + semitono)
    fase1 = 2*np.pi*np.cumsum(f1)/SR
    fase2 = 2*np.pi*np.cumsum(f2)/SR
    trem = 0.55 + 0.45*np.sin(2*np.pi*(6 + 14*prog)*tt)
    chirrido = (np.sin(fase1) + 0.6*np.sin(fase2) + 0.25*np.sin(3*fase1))*trem*(0.25 + 0.75*prog)
    raspa = bp(r.randn(n), 2500, 7500)*(0.15 + 0.85*prog**2)*(0.5 + 0.5*np.sin(2*np.pi*9*tt))
    sub = np.sin(2*np.pi*(42 + 12*prog)*tt)*(0.4 + 0.6*prog)
    x = (0.5*chirrido + 0.35*raspa + 0.7*sub)*np.minimum(1, tt/0.12)
    x *= np.minimum(1, (L - tt)/0.25)
    return reverb(x, 1.4, 0.25)
def musica_modo3():
    """Modo 3: colchón grave y oscuro que no tapa las pistas (todo por debajo de ~260 Hz, salvo una cola de aire muy suave).
    Dos graves en disonancia que baten despacio, un latido lejano y un oleaje de ruido filtrado. Bucle de 24 s."""
    L = 24
    base = 0.55*tono_p(L, 41.2) + 0.5*tono_p(L, 43.65)*(0.7 + 0.3*tono_p(L, 0.125)) + 0.3*tono_p(L, 61.7)*(0.5 + 0.5*tono_p(L, 0.25, 1.3))
    base += 0.18*tono_p(L, 123.5)*(0.3 + 0.7*np.abs(tono_p(L, 0.0833)))     # armónico que respira
    oleaje = lp(ruido_periodico(L, 40, 230, -1, 41), 230)*(0.4 + 0.6*np.abs(tono_p(L, 0.125, 0.6)))*0.5
    aire = lp(ruido_periodico(L, 1500, 5000, -1, 42), 5000)*0.04*(0.3 + 0.7*np.abs(tono_p(L, 0.0833, 2.0)))
    x = base + oleaje + aire
    for p in (1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5):        # latido lejano, lento, muy grave
        m = int(0.5*SR); tt = np.arange(m)/SR
        anillo(x, p, 0.6*np.sin(2*np.pi*(52 - 20*tt/0.5)*tt)*np.exp(-tt/0.12))
        anillo(x, p + 0.32, 0.35*np.sin(2*np.pi*(48 - 18*tt/0.5)*tt)*np.exp(-tt/0.1))
    return lp(x, 4000)
def cambio_camara():
    n = int(0.3*SR); tt = np.arange(n)/SR
    clic = np.sign(rng.randn(int(0.01*SR)))*0.8
    x = np.zeros(n); x[:len(clic)] += clic
    x += 0.5*hp(rng.randn(n), 1500)*np.exp(-tt/0.09)*np.minimum(1, tt/0.01)
    return x
def papel():
    x = np.zeros(int(0.7*SR))
    for p, d in [(0.0, 0.18), (0.2, 0.25), (0.45, 0.15)]:
        m = int(d*SR); b = bp(rng.randn(m), 1800, 7000)*np.sin(np.linspace(0, np.pi, m))**1.5*(0.5+0.5*rng.rand(m))
        x[int(p*SR):int(p*SR)+m] += b
    return x
def puerta():
    n = int(1.1*SR); tt = np.arange(n)/SR
    chirrido = bp(rng.randn(n), 600, 1400)*np.sin(np.pi*np.clip(tt/0.7, 0, 1))*0.4*(0.6+0.4*np.sin(2*np.pi*24*tt))
    golpe = np.sin(2*np.pi*(70+80*np.exp(-(tt-0.75)/0.03))*np.clip(tt-0.75, 0, None))*np.exp(-np.clip(tt-0.75, 0, None)/0.12)*(tt >= 0.75)
    return reverb(chirrido*(tt < 0.75)+golpe*1.1, 0.8, 0.2)
def pitido_plano():
    L = 5.5; n = int(L*SR); tt = np.arange(n)/SR
    x = np.sin(2*np.pi*1000*tt)*np.minimum(1, tt/0.02)*np.minimum(1, (L-tt)/0.6)
    return x+0.15*np.sin(2*np.pi*2000*tt)*np.minimum(1, tt/0.02)
def tono_revelacion():
    L = 5.5; n = int(L*SR); tt = np.arange(n)/SR
    x = sum(np.sin(2*np.pi*f*tt+i) for i, f in enumerate([110, 164.8, 220, 261.6, 277.2, 329.6]))/6
    sw = (tt/L)**2.0*np.minimum(1, (L-tt)/0.8)
    x = x*sw + 0.2*bp(rng.randn(n), 3000, 8000)*sw
    return reverb(x, 2.0, 0.35)
def latido():
    L = 3.6; n = int(L*SR); x = np.zeros(n)
    for k in range(4):
        base = k*0.9
        for off, niv in [(0.0, 1.0), (0.24, 0.65)]:
            m = int(0.22*SR); tt = np.arange(m)/SR
            th = np.sin(2*np.pi*(55+40*np.exp(-tt/0.03))*tt)*np.exp(-tt/0.08)*niv
            anillo(x, base+off, th)
    return lp(x, 400)

def susurro_derecha():
    """Susurro insistente y fuerte (bucle); en el juego se reproduce solo por el canal derecho."""
    return reverb(susurro_base(10, 34, 57), 1.0, 0.25)


def viento():
    """Viento en bucle: ruido de banda ancha con ráfagas lentas."""
    L = 14
    base = ruido_periodico(L, 120, 1400, -0.6, 77)
    racha = 0.55+0.45*tono_p(L, 1/7, 0.4)*(0.6+0.4*tono_p(L, 1/3.5, 1.1))
    silbido = 0.25*ruido_periodico(L, 900, 2200, 0, 78)*(0.5+0.5*tono_p(L, 1/4.7, 2.0))
    return base*racha+silbido


def pitidos(n):
    """N pitidos cortos (1000 Hz) y una pausa final; el 0 es un único tono largo y grave (440 Hz)."""
    if n == 0:
        L = 0.9; tt = np.arange(int(L*SR))/SR
        x = np.sin(2*np.pi*440*tt)*np.minimum(1, tt/0.02)*np.minimum(1, (L-tt)/0.05)
        return np.concatenate([x, np.zeros(int(1.8*SR))])
    d = 0.16; paso = 0.46
    tt = np.arange(int(d*SR))/SR
    p = np.sin(2*np.pi*1000*tt)*np.minimum(1, tt/0.01)*np.minimum(1, (d-tt)/0.02)
    pausa = np.zeros(int((paso-d)*SR))
    return np.concatenate([np.concatenate([p, pausa]) for _ in range(n)]+[np.zeros(int(1.8*SR))])


if __name__ == "__main__":
    import sys
    bucles = {
        "ambiente_recepcion": (ambiente_recepcion, 0.35), "ambiente_pasillo": (ambiente_pasillo, 0.35),
        "ambiente_vigilancia": (ambiente_vigilancia, 0.35), "ambiente_laboratorio": (ambiente_laboratorio, 0.35),
        "ambiente_oficina": (ambiente_oficina, 0.3), "ambiente_habitacion": (ambiente_habitacion, 0.35),
        "ambiente_pasillo_alterado": (ambiente_pasillo_alterado, 0.4),
        "ambiente_tramo_1": (lambda: ambiente_tramo(1), 0.3), "ambiente_tramo_2": (lambda: ambiente_tramo(2), 0.35),
        "ambiente_tramo_3": (lambda: ambiente_tramo(3), 0.4),
        "tono_grave": (tono_grave, 0.5), "susurro_fijo": (lambda: cerrar_bucle(susurro_fijo(), 12), 0.5), "musica_titulo": (lambda: cerrar_bucle(musica_titulo(), 32), 0.5),
        "latido": (latido, 0.8), "musica_modo3": (musica_modo3, 0.5), "viento": (viento, 0.5), "susurro_derecha": (lambda: cerrar_bucle(susurro_derecha(), 10), 0.85),
    }
    efectos = {
        "alerta_terminal": (alerta_terminal, 0.7), "detector_bip": (detector_bip, 0.6), "detector_alarma": (detector_alarma, 0.5), "apagon_inicio": (apagon_inicio, 0.9), "apagon_fin": (apagon_fin, 0.8), "tecla": (tecla, 0.5), "susurro_terminal": (susurro_terminal, 0.6),
        "susurro_pasillo": (susurro_pasillo, 0.6), "estatica_breve": (estatica_breve, 0.6),
        "confirmacion": (confirmacion, 0.55), "error_terminal": (error_terminal, 0.65),
        "golpe_grave": (golpe_grave, 0.9), "advertencia_entidad": (advertencia_entidad, 0.8),
        "pasos_entidad": (pasos_entidad, 0.9), "entidad_acecho": (entidad_acecho, 0.85),
        "cambio_camara": (cambio_camara, 0.5), "papel": (papel, 0.5), "puerta": (puerta, 0.7),
        # CAM 3: tantos pitidos como estrellas tiene la constelación del puzzle (4 a 9), en bucle
        **{"pitidos_%d" % n: ((lambda n=n: pitidos(n)), 0.5) for n in range(4, 10)},
        "pitido_plano": (pitido_plano, 0.5), "tono_revelacion": (tono_revelacion, 0.7),
    }
    # python3 audio.py nombre1 nombre2 -> genera solo esos
    for n, (f, p) in {**bucles, **efectos}.items():
        if len(sys.argv) > 1 and n not in sys.argv[1:]:
            continue
        guardar(n, f(), p)
        print("ok", n)
