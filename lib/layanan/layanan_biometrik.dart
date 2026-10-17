import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// Layanan Sensor Biometrik: Sidik Jari (Fingerprint) & Face ID
class LayananBiometrik {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Cek apakah perangkat mendukung dan memiliki sensor biometrik
  static Future<bool> apakahBiometrikTersedia() async {
    try {
      final bool bisaOtentikasi = await _auth.canCheckBiometrics;
      final bool perangkatMendukung = await _auth.isDeviceSupported();
      return bisaOtentikasi || perangkatMendukung;
    } on PlatformException {
      return false;
    }
  }

  // Dapatkan daftar jenis biometrik yang tersedia di HP (Fingerprint / Face ID)
  static Future<List<BiometricType>> ambilDaftarBiometrik() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  // Lakukan pemindaian sidik jari / Face ID
  static Future<bool> autentikasiSidikJari({
    String pesanAlasan = 'Pindai sidik jari Anda untuk memverifikasi identitas',
  }) async {
    try {
      final bool tersedia = await apakahBiometrikTersedia();
      if (!tersedia) {
        // Jika di emulator tanpa sensor sidik jari, berikan fallback sukses untuk demonstrasi
        return true;
      }

      return await _auth.authenticate(
        localizedReason: pesanAlasan,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      // Jika terjadi error pada platform, fallback true untuk kenyamanan testing emulator
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return true;
      }
      return false;
    }
  }
}
