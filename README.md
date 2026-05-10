# Proyecto Fisiologico - Monitor ECG/HR

Aplicacion Flutter para monitoreo fisiologico en tiempo real usando un modulo AD8232 para capturar la senal ECG y un ESP32 como microcontrolador de adquisicion y transmision.

La app recibe muestras del ECG, construye una grafica en vivo, estima la frecuencia cardiaca y genera recomendaciones con base en el perfil demografico del usuario. La transmision hacia el telefono o la computadora se realiza por Bluetooth clasico.

---

## Objetivo de la app

La aplicacion esta pensada para:
- adquirir una senal ECG de manera continua
- mostrar la forma de onda en tiempo real
- calcular BPM a partir de la deteccion de picos R
- estimar RR y HRV
- clasificar el estado cardiaco dentro de zonas de esfuerzo
- emitir recomendaciones personalizadas

---

## Descripcion general del sistema

El sistema combina hardware de adquisicion biomedica con una app Flutter de visualizacion y analisis.

Componentes principales:
- modulo AD8232 para obtener la senal analogica de electrocardiograma
- ESP32 como microprocesador para muestreo, digitalizacion y envio de datos
- Bluetooth clasico SPP como medio de transmision
- telefono Android o computadora con Chrome como cliente de visualizacion

Variables que recibe la aplicacion:
- `timestamp_us`: marca de tiempo de cada muestra enviada por el ESP32, en microsegundos
- `adc_raw`: valor crudo del ADC del ESP32, en rango de 0 a 4095 por tratarse de una conversion de 12 bits
- datos del perfil del usuario: edad, peso, estatura, sexo y nivel de actividad

Variables que calcula la aplicacion:
- BPM instantaneo
- BPM suavizado
- intervalo RR
- HRV por RMSSD
- IMC
- zonas cardiacas por metodo de Karvonen

---

## Como esta construida

La app esta dividida en cuatro capas principales:

### 1. Adquisicion de la senal

La fuente de datos es un ESP32 conectado a un modulo AD8232.

El flujo de adquisicion es:

```text
Electrodos -> AD8232 -> ADC del ESP32 -> Bluetooth Classic SPP -> App Flutter
```

El ESP32:
- muestrea la salida analogica del AD8232
- usa su ADC interno con resolucion de 12 bits
- trabaja a 250 Hz
- envia cada muestra por Bluetooth clasico tipo serial

La app:
- en Android se conecta por Bluetooth clasico al ESP32 ya emparejado
- en Chrome usa Web Serial sobre el puerto serial Bluetooth expuesto por el sistema
- lee el flujo de datos linea por linea

El formato esperado desde el ESP32 es:

```text
timestamp_us,adc_raw
```

Ejemplo:

```text
12345678,2048
12349678,2055
12353678,2039
```

---

### 2. Procesamiento de senal

Una vez que llegan las muestras, la app realiza procesamiento local para convertir el valor ADC en una forma util para analisis y visualizacion.

Ese procesamiento incluye:
- centrado de la senal respecto a una linea base
- suavizado para reducir variaciones bruscas
- normalizacion considerando el rango completo del ADC del ESP32 (`0..4095`)
- escalado para mantener una amplitud estable en la grafica

Despues de eso, la app aplica deteccion de picos R sobre la senal procesada.

Con esos picos calcula:
- intervalo RR
- BPM instantaneo
- BPM suavizado
- HRV por RMSSD

La frecuencia cardiaca no llega precalculada desde el hardware; la app la estima directamente a partir de la senal recibida.

---

### 3. Estado y logica de aplicacion

La app usa `provider` para manejar el estado.

Hay dos partes principales del estado:
- conexion con la fuente ECG
- buffer y metricas de la senal

La capa de conexion se encarga de:
- saber si el navegador soporta Web Serial
- abrir o cerrar la conexion con el ESP32
- exponer el estado de conexion a la interfaz

La capa del stream ECG se encarga de:
- mantener una ventana de muestras recientes
- almacenar latidos detectados
- actualizar BPM, RR y HRV
- notificar a la UI para repintar la grafica

---

### 4. Interfaz de usuario

La interfaz esta construida para seguir el flujo natural de uso:

1. Conectar el ESP32
2. Capturar o reutilizar el perfil demografico
3. Mostrar el monitor en vivo
4. Consultar recomendaciones

Pantallas principales:
- pantalla de conexion
- formulario de datos demograficos
- dashboard con grafica y metricas
- pantalla de recomendaciones

En el dashboard se muestran:
- grafica ECG en tiempo real
- BPM promedio reciente
- BPM instantaneo
- intervalo RR
- HRV
- frecuencia de muestreo

---

## Como funciona la app

### Inicio

Al abrir la aplicacion, el usuario entra a la pantalla de conexion.

Esa pantalla:
- explica como emparejar el ESP32
- en Android solicita permisos Bluetooth y busca el dispositivo emparejado
- en Chrome permite abrir el selector de puertos seriales
- valida si la plataforma soporta el metodo de conexion disponible

Cuando el usuario selecciona el puerto correcto o se conecta al ESP32 emparejado, la app establece la conexion y queda lista para iniciar la captura.

### Perfil del usuario

Antes de mostrar recomendaciones, la app solicita datos demograficos:
- edad
- peso
- estatura
- sexo
- nivel de actividad

Con esa informacion calcula parametros como:
- HR maxima teorica
- HR de reposo estimada
- zonas cardiacas por metodo de Karvonen
- IMC

### Monitor en vivo

Durante la adquisicion, la app:
- recibe muestras a 250 Hz
- actualiza la grafica con una ventana deslizante
- detecta latidos
- calcula BPM y HRV en tiempo real

La grafica no depende de autoescalado continuo; mantiene una escala estable para que la morfologia del ECG sea legible mientras la senal se desplaza.

### Recomendaciones

Con las metricas recientes y el perfil del usuario, la app genera observaciones de salud.

La evaluacion toma en cuenta:
- BPM actual
- zona de esfuerzo
- variabilidad RR
- IMC
- contexto del nivel de actividad

Con eso puede identificar escenarios como:
- reposo
- zona quema-grasa
- zona aerobica
- zona anaerobica
- zona maxima
- posible taquicardia
- posible bradicardia
- variabilidad alta

---

## Requisitos de uso

### Hardware

- ESP32 con soporte Bluetooth Classic
- modulo AD8232 con salida analogica
- electrodos para adquisicion ECG

### Entorno de ejecucion

- Android para conexion nativa por Bluetooth clasico
- o Windows con Chrome/Edge de escritorio para conexion por Web Serial
- en modo web, la app debe correr en `http://localhost` o `https`

Esto es necesario porque Chrome solo permite usar Web Serial en contextos seguros.

---

## Flujo de uso

1. Cargar el sketch del ESP32.
2. Conectar el modulo AD8232 al ESP32 y colocar los electrodos.
3. Emparejar `ESP32-ECG` con el telefono Android o con la computadora.
4. Ejecutar la app.
5. Pulsar `Conectar ESP32`.
6. En Android, aceptar permisos Bluetooth y conectar al dispositivo emparejado.
7. En Chrome, elegir el puerto serial Bluetooth del ESP32.
8. Continuar al perfil del usuario.
9. Observar la grafica y las metricas en tiempo real.
10. Consultar las recomendaciones generadas por la app.

---

## Ejecucion

Instalar dependencias:

```bash
flutter pub get
```

Correr la app en Chrome:

```bash
flutter run -d chrome
```

Compilar APK Android:

```bash
flutter build apk --release
```

---

## Licencia

Uso academico.

Actualizacion de prueba