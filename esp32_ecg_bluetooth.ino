#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

// Pin del ADC donde esta conectada la salida del modulo ECG.
const int ECG_PIN = 34;

// Nombre que aparecera al emparejar el ESP32 por Bluetooth.
const char* BT_NAME = "ESP32-ECG";

// Frecuencia de muestreo deseada.
const int SAMPLE_RATE_HZ = 250;
const unsigned long SAMPLE_PERIOD_US = 1000000UL / SAMPLE_RATE_HZ;

unsigned long lastSampleUs = 0;

void setup() {
  Serial.begin(115200);
  SerialBT.begin(BT_NAME);

  pinMode(ECG_PIN, INPUT);
  analogReadResolution(12);
  analogSetPinAttenuation(ECG_PIN, ADC_11db);
}

void loop() {
  if (!SerialBT.hasClient()) {
    return;
  }

  unsigned long nowUs = micros();

  if (nowUs - lastSampleUs >= SAMPLE_PERIOD_US) {
    lastSampleUs = nowUs;

    int adcValue = analogRead(ECG_PIN);

    // Formato: tiempo_en_us,valor_adc
    SerialBT.print(nowUs);
    SerialBT.print(",");
    SerialBT.println(adcValue);
  }
}
