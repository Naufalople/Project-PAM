import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Layanan Sensor Hardware JastipGo:
/// 1. Sensor Akselerometer (Deteksi Goyangan HP / Shake Promo)
/// 2. Sensor Mikrofon (Voice Recognition / Speech-to-Text untuk Pencarian Produk)
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
  // 2. SENSOR MIKROFON & SUARA (VOICE SEARCH)
  // ==========================================

  /// Inisialisasi sensor mikrofon
  static Future<bool> inisialisasiSensorSuara() => LayananSensorSuara.inisialisasi();

  /// Mulai merekam suara pengguna dari mikrofon
  static Future<void> mulaiPencarianSuara({
    required Function(String teksHasil, bool finalResult) saatMendengar,
    Function(String error)? saatError,
    String bahasa = 'id_ID',
  }) =>
      LayananSensorSuara.mulaiMendengarkan(
        saatMendengar: saatMendengar,
        saatError: saatError,
        bahasa: bahasa,
      );

  /// Hentikan perekaman suara
  static Future<void> hentikanSensorSuara() => LayananSensorSuara.berhenti();

  /// Status apakah mikrofon sedang aktif mendengarkan
  static bool get apakahMendengarkanSuara => LayananSensorSuara.sedangMendengarkan;
}

/// Layanan Khusus Sensor Mikrofon & Pengenalan Suara (Speech-to-Text)
class LayananSensorSuara {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _terinisialisasi = false;
  static bool _sedangMendengarkan = false;
  static String _kataTerakhir = '';

  static bool get sedangMendengarkan => _sedangMendengarkan;
  static bool get terinisialisasi => _terinisialisasi;
  static String get kataTerakhir => _kataTerakhir;

  /// Daftar contoh kata kunci produk untuk demo / fallback jika mic tidak ada input
  static const List<String> daftarContohSuara = [
    'Tokyo Banana',
    'Gundam RG',
    'COSRX Snail',
    'Harrods English Tea',
    'KitKat Matcha',
    'Skin Aqua Tone Up',
  ];

  /// Inisialisasi sensor mikrofon & speech engine
  static Future<bool> inisialisasi() async {
    try {
      _terinisialisasi = await _speech.initialize(
        onError: (val) {
          debugPrint('Error Sensor Suara: ${val.errorMsg}');
          _sedangMendengarkan = false;
        },
        onStatus: (status) {
          debugPrint('Status Sensor Suara: $status');
          if (status == 'done' || status == 'notListening') {
            _sedangMendengarkan = false;
          }
        },
      );
      return _terinisialisasi;
    } catch (e) {
      debugPrint('Pengecualian saat inisialisasi sensor suara: $e');
      _terinisialisasi = false;
      return false;
    }
  }

  /// Mulai merekam suara pengguna dari mikrofon
  static Future<void> mulaiMendengarkan({
    required Function(String teksHasil, bool finalResult) saatMendengar,
    Function(String error)? saatError,
    String bahasa = 'id_ID',
  }) async {
    try {
      if (!_terinisialisasi) {
        final berhasil = await inisialisasi();
        if (!berhasil) {
          saatError?.call('Sensor mikrofon / speech recognition tidak didukung di perangkat ini.');
          return;
        }
      }

      _sedangMendengarkan = true;
      _kataTerakhir = '';

      await _speech.listen(
        onResult: (result) {
          _kataTerakhir = result.recognizedWords;
          saatMendengar(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _sedangMendengarkan = false;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: bahasa,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      _sedangMendengarkan = false;
      saatError?.call('Gagal mengaktifkan mikrofon: $e');
    }
  }

  /// Berhenti merekam suara mikrofon
  static Future<void> berhenti() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _sedangMendengarkan = false;
  }
}
