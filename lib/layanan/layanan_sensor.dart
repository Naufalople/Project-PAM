import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

// Layanan Sensor Hardware: Akselerometer (Goyang HP) & Giroskop (Kemiringan HP)
class LayananSensor {
  // ==========================================
  // 1. SENSOR AKSELEROMETER (DETEKSI GOYANGAN / SHAKE)
  // ==========================================

  // Ambang batas goyangan (Shake Threshold)
  static const double _ambangBatasGoyangan = 18.0;

  // Dengarkan event goyangan HP (Shake)
  static StreamSubscription<AccelerometerEvent> dengarkanGoyanganHp({
    required Function() saatGoyanganTerdeteksi,
  }) {
    DateTime waktuGoyanganTerakhir = DateTime.now();

    return accelerometerEventStream().listen((AccelerometerEvent event) {
      // Hitung total percepatan (magnitudo g-force)
      final double magnitudo = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final DateTime sekarang = DateTime.now();
      // Cegah deteksi berkali-kali dalam selang waktu 1.5 detik
      if (magnitudo > _ambangBatasGoyangan) {
        if (sekarang.difference(waktuGoyanganTerakhir).inMilliseconds > 1500) {
          waktuGoyanganTerakhir = sekarang;
          saatGoyanganTerdeteksi();
        }
      }
    });
  }

  // ==========================================
  // 2. SENSOR GIROSKOP (DETEKSI KEMIRINGAN / TILT 3D)
  // ==========================================

  // Dengarkan perubahan sudut rotasi kemiringan HP
  static StreamSubscription<GyroscopeEvent> dengarkanKemiringanHp({
    required Function(double rotasiX, double rotasiY, double rotasiZ) saatMiring,
  }) {
    return gyroscopeEventStream().listen((GyroscopeEvent event) {
      saatMiring(event.x, event.y, event.z);
    });
  }
}
