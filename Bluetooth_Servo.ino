#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ESP32Servo.h>

#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define ServoX 12
#define ServoY 13

Servo myservox;
Servo myservoy;

// Center constants
const float CENTER_X = 0.5;
const float CENTER_Y = 0.5;

// Tuning params
const float threshold_x = 0.08;  // ignore tiny jitter
const float threshold_y = 0.02;
const float servo_pan_speed  = 25.0;  // change per update
const float servo_tilt_speed = 25.0;

const int pulse_pan_min = 0;
const int pulse_pan_max = 180;

// Direction config (+1 or -1 depending on your setup)
const int dir_x = 1;
const int dir_y = 1;

float servo_pos_x = 90;
float servo_pos_y = 90;

BLECharacteristic *pCharacteristic;

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      Serial.print("Received: ");
      Serial.println(value.c_str());

      int xStart = value.find("\"x\":");
      int yStart = value.find("\"y\":");

      if (xStart != std::string::npos && yStart != std::string::npos) {
        float face_x = atof(value.substr(xStart + 4, value.find(",", xStart) - (xStart + 4)).c_str());
        float face_y = atof(value.substr(yStart + 4, value.find("}", yStart) - (yStart + 4)).c_str());

        // Calculate difference from center
        float diff_x = face_x - CENTER_X;
        if (abs(diff_x) <= threshold_x) diff_x = 0;

        float diff_y = face_y - CENTER_Y;
        if (abs(diff_y) <= threshold_y) diff_y = 0;

        // Calculate how much to move based on speed
        float mov_x = dir_x * servo_pan_speed * diff_x;
        float mov_y = dir_y * servo_tilt_speed * diff_y;

        // Update servo positions
        servo_pos_x += mov_x;
        servo_pos_y += mov_y;

        // Constrain to limits
        servo_pos_x = constrain(servo_pos_x, pulse_pan_min, pulse_pan_max);
        servo_pos_y = constrain(servo_pos_y, pulse_pan_min, pulse_pan_max);

        Serial.printf("→ Moving to X: %d | Y: %d\n", (int)servo_pos_x, (int)servo_pos_y);
      }
    }
  }
};

void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32-FaceBot");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  myservox.setPeriodHertz(50);
  myservox.attach(ServoX, 1000, 2000);

  myservoy.setPeriodHertz(50);
  myservoy.attach(ServoY, 1000, 2000);

  Serial.println("✅ ESP32 BLE service started. Waiting for phone...");
}

void loop() {
  myservox.write((int)servo_pos_x);
  myservoy.write((int)servo_pos_y);
}