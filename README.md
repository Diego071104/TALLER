# Proyecto Fisiológico — Monitor ECG/HR

App Flutter de monitoreo fisiológico en tiempo real para la entrega de **Desarrollo de App** del Departamento de Mecatrónica e Ingeniería Biomédica del Tec de Monterrey (Abril 2026).

Captura una variable fisiológica (ECG y frecuencia cardíaca), la cruza con datos demográficos del usuario y emite recomendaciones de salud personalizadas con visualización en tiempo real.

---

## Variable fisiológica

- **Señal:** Electrocardiograma (ECG) muestreado a **250 Hz**
- **Variable derivada:** Frecuencia cardíaca instantánea (BPM) a partir de la detección de picos R
- **Lógica de salud:** Comparación contra zonas de Karvonen calculadas con edad y nivel de actividad del usuario para emitir alertas (taquicardia, bradicardia, arritmia) y recomendaciones (zona quema-grasa, aeróbica, anaeróbica, máxima)

---

## Arquitectura

```
┌───────────────────────────┐    WebSocket    ┌───────────────────────────┐
│  simulator/ecg_server.py  │ ◄────ws://────► │  app Flutter              │
│  (sustituye al hardware)  │   localhost     │  (UI + lógica de salud)   │
│                           │     :8765       │                           │
│  • numpy → ECG sintético  │                 │  • fl_chart (sliding)     │
│  • PQRST realista         │                 │  • provider               │
│  • modos: normal,         │                 │  • google_fonts           │
│    tachy, brady,          │                 │  • web_socket_channel     │
│    arrhythmia, exercise   │                 │                           │
└───────────────────────────┘                 └───────────────────────────┘
```

### ¿Por qué simulador y no Arduino + Bluetooth?

Originalmente la entrega sugiere un Arduino con sensor de pulso enviando datos por Bluetooth (HC-06). Por restricciones de hardware, se sustituyó por un servidor WebSocket en Python que **genera ECG sintético realista** con la morfología clásica PQRST y exporta los datos al mismo ritmo que un sensor real. La capa de transporte cambia de BLE a WebSocket pero la **lógica de procesamiento, visualización y recomendación es idéntica** a la que se usaría con hardware físico.

---

## Stack técnico

| Componente | Tecnología | Versión |
|------------|------------|---------|
| Framework móvil | Flutter | 3.38.3 |
| Lenguaje app | Dart | 3.10.1 |
| Gráficas | fl_chart | ^1.2.0 |
| WebSocket | web_socket_channel | ^3.0.3 |
| State mgmt | provider | ^6.1.5+1 |
| Tipografía | google_fonts | ^8.1.0 |
| Simulador | Python | 3.11+ |
| Lib simulador | websockets, numpy | latest |

---

## Cómo correr el proyecto

### 1. Levantar el simulador

```bash
cd simulator
pip install -r requirements.txt
python ecg_server.py --mode normal --port 8765
```

Modos disponibles: `normal`, `tachycardia`, `bradycardia`, `arrhythmia`, `exercise`. El modo también se puede cambiar en caliente desde la app vía mensaje WebSocket.

### 2. Correr la app Flutter

En otra terminal:

```bash
flutter pub get
flutter run
```

En la pantalla de conexión, deja la URL por default (`ws://localhost:8765`) si corres en emulador en la misma máquina. Si corres en celular físico, cambia a `ws://<IP_de_tu_laptop>:8765` (mismo WiFi).

---

## Protocolo WebSocket

Mensajes que **el simulador envía** a la app:

```json
// muestra de ECG (250 veces por segundo)
{ "type": "ecg_sample", "ts": 1746205823.412, "mv": -0.12 }

// latido detectado (cada vez que hay un QRS)
{ "type": "beat", "ts": 1746205823.892, "rr_ms": 856, "instant_bpm": 70.1 }
```

Mensajes que **la app envía** al simulador:

```json
{ "type": "set_mode", "mode": "exercise" }
```

---

## Estructura de carpetas

```
proyecto_fisiologico/
├── lib/
│   ├── core/        # tema, colores, constantes
│   ├── data/        # modelos + servicios (WebSocket)
│   ├── state/       # providers
│   ├── logic/       # análisis de salud (Karvonen, detección)
│   └── ui/
│       ├── screens/ # 5 pantallas principales
│       └── widgets/ # componentes reutilizables
├── simulator/
│   ├── ecg_server.py        # WebSocket server
│   ├── ecg_synth.py         # generación PQRST
│   └── requirements.txt
├── android/
└── linux/
```

---

## Equipo

Entrega de equipo del curso de Desarrollo de App. Repositorio académico Abril 2026.

---

## Licencia

Uso académico — ITESM Mecatrónica/Biomédica.
