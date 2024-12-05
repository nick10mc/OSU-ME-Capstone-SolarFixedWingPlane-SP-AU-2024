/*
  Solar Wing Temperature/Humidity recorder code
  By Nicholas McCatherine, November 13th, 2024
  The Ohio State University

  Refering to and modifying example code from official Arduino SD example
  and the DHT11 Nonblocking Script by Toan Nguyen, requiring the following:

  This code is licensed under the Apache License, Version 2.0, January 2004.
  All rights to the libraries used are reserved by their respective owners.
  Implementation and modifications - Copyright 2024 Nicholas McCatherine

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
#include <SD.h>
#include <EEPROM.h>
#include <DHT_Async.h>
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
  #include <avr/sleep.h>
  #include <avr/power.h>
#else
  #include <SPI.h>
#endif

///////////////DEFINES///////////////
#if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
  //Define the chip select pin for SD card
    // SDO - Pin 11
    // SDI - Pin 12
    // CLK - Pin 13
  #define chipSelect 10
#else
  #define chipSelect BUILTIN_SDCARD
#endif
//Define the output file name
char filename[] = "temp&humidLog";
const char file[] = ".csv";
const char increment[] = "";
//Define the sensor serial pin
#define DHT_SENSOR_PIN 2
//Define Sensor Type
#define DHT_SENSOR_TYPE DHT_TYPE_11
//Define measurement interval, in unsigned long (UL)
#define MEAS_INTERVAL 4000ul
/////////////////////////////////////

// initialize the file object
File csv;

//Declare the constructor for the temp/humidity sensor
DHT_Async dht_sensor(DHT_SENSOR_PIN, DHT_SENSOR_TYPE);

void setup() {
  digitalWrite(LED_BUILTIN,HIGH);
  #if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
    // Power down uneeded peripherals
    PRR |= (1<<PRTWI);
    PRR |= (1<<PRADC);
    PRR |= (1<<PRTIM2);
    PRR |= (1<<PRTIM1);
    // Only timer 0 is used for millis()
  #endif

  Serial.begin(115200);
  Serial.println(F("DHT11 Sensor Recorder - Solar Wing - Ohio State University"));
  if (SD.begin(chipSelect)) {
    Serial.println(F("SD card ready"));
  } else {
    Serial.println(F("SD card failure!"));
    while (true) {
      #if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
        // Start sleep mode
        SMCR |= (1<<SM1);
        cli();
        SMCR |= (1<<SE);
        sei();
        asm("SLEEP");
      #endif
    }
  }

  // Check the EEPROM program counter for file naming
  int counter = EEPROM.read(0);
  if (counter >= 255) {
    counter = 0;
  } else {
    counter = counter+1;
  }
  EEPROM.write(0,counter);
  itoa(counter,increment,10); // Convert counter integer to character array, base ten, and assign to "increment"
  strcat(filename,increment); // Concatenate
  strcat(filename,file);

  if (SD.exists(filename)) {
    SD.remove(filename);
  }

  // Open the file
  csv = SD.open(filename, FILE_WRITE);
  if (!csv) {
    Serial.print(F("Error opening "));
    Serial.println(filename);
    while (true) {
      #if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
        // Start sleep mode
        SMCR |= (1<<SM1);
        cli();
        SMCR |= (1<<SE);
        sei();
        asm("SLEEP");
      #endif
    };
  } else { 
    //Write the headers
    Serial.println(F("Writing Headers..."));
    csv.println(F("Time,Temperature,Humidity,"));
    csv.close();
    Serial.println(F("Headers written."));
  }

/*
  // Setup the buffer size, do not exceed dynamic memory
  #if defined(__AVR_ATmega328P__) || defined(__AVR_ATmega168__)
    buf.reserve(256);
  #else
    buf.reserve(256000);
  #endif
*/
  digitalWrite(LED_BUILTIN,LOW);
  Serial.println(F("Writing to file..."));
}

static bool measure_environment(float *temperature, float *humidity) {
  static uint32_t measurement_timeStamp = millis();

  if (millis() - measurement_timeStamp > MEAS_INTERVAL) {
    if (dht_sensor.measure(temperature, humidity)) {
      measurement_timeStamp = millis();
      return true;
    }
  }

  return false;
}

void loop() {
  float temperature;
  float humidity;
  uint32_t now = millis();

  if (measure_environment(&temperature, &humidity)) {
    csv = SD.open(filename, FILE_WRITE);
    Serial.print(F("Temperature = "));
    Serial.print(temperature, 1);
    Serial.print(F("°C | Humidity = "));
    Serial.print(humidity, 1);
    Serial.println(F("%"));

/*
    // Add data to buffer
    buf += now; buf += ",";
    buf += temperature; buf += ",";
    buf += humidity; //buf += ",\r\n";
    
    
    // Print to csv
    Serial.print(F("Data buffer length (B): "));
    Serial.println(buf.length());
    Serial.print("Buffer Contents: ");
    Serial.println(buf);

    digitalWrite(LED_BUILTIN,HIGH);
    csv.println(buf);
    csv.close();
    digitalWrite(LED_BUILTIN,LOW);
    //Clear the buffer
    buf = "";
*/
    digitalWrite(LED_BUILTIN,HIGH);
    csv.print(now); csv.print(",");
    csv.print(temperature); csv.print(",");
    csv.print(humidity); csv.println(",");
    csv.close();
    digitalWrite(LED_BUILTIN,LOW);
  }

/* Disabled - DHT software does NOT use hardware USART - not a serial device
  //Set the sleep mode to idle, can be woken up by USART
  SMCR |= (0<<SM2) | (0<<SM1) | (0<<SM0);
  SMCR |= (1<<SE);
  sei();
*/
}
