# 2025-Engineering-Project
1. **Mount the Servos**  
   - Insert the two MG995 servos into the 3D-printed mounts (pan and tilt).  
   - Secure each with screws through the designated mounting holes.

2. **Wire the Hardware**  
   - Connect the servo signal pins to **GPIO 12 (X)** and **GPIO 13 (Y)** on the ESP32 Nano.  
   - Use a breadboard to connect **5V power** and **GND** to both servos.  
   - (Optional) Use an external 5–6V power source for more stable servo performance.

3. **Upload the Code to the ESP32**  
   - Open the Arduino IDE.  
   - Install required libraries (`ESP32Servo`, `BLEDevice`).  
   - Connect the ESP32 via USB and upload the provided Bluetooth face tracking code.

4. **Download and Launch the iOS App**  
   - Install the Swift-based face tracking app on your iPhone.  
   - Open the app and grant camera & Bluetooth permissions.

5. **Pair with ESP32 Bluetooth**  
   - Power on the ESP32.  
   - Look for the Bluetooth device name **`ESP32-FaceBot`** on your iPhone.  
   - Once connected, the app will begin sending face coordinates automatically.
<img width="674" alt="Screenshot 2025-04-22 at 2 02 40 PM" src="https://github.com/user-attachments/assets/88d32d3b-af5c-4282-bcf6-abda9beed137" />
