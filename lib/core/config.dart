/// App-wide configuration constants.
class AppConfig {
  AppConfig._();

  /// USB Vendor ID used to auto-connect to the RFID PCB.
  ///
  /// `0x2E8A` is Raspberry Pi — covers any RP2040 board (Pico, Pico W, Pico 2)
  /// running any firmware (MicroPython, CircuitPython, Arduino, custom). Change
  /// here if the PCB hardware changes vendor.
  static const int pcbUsbVid = 0x2E8A;

  /// Serial baud rate the PCB firmware uses.
  static const int pcbBaudRate = 115200;
}
