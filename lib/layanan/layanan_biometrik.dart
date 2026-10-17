import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Layanan Sensor Biometrik: Sidik Jari (Fingerprint) & Face ID
// Mendukung pengikatan spesifik ke akun yang diaktifkan di menu Profil
class LayananBiometrik {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _kunciBiometrikEmail = 'biometrik_email_terdaftar';
  static const String _kunciBiometrikNama = 'biometrik_nama_terdaftar';
  static const String _kunciBiometrikAktif = 'biometrik_status_aktif';

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
        // Fallback untuk emulator tanpa sensor fisik
        return true;
      }

      return await _auth.authenticate(
        localizedReason: pesanAlasan,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return true;
      }
      return false;
    }
  }

  // ========================================================
  // PENGIKATAN BIOMETRIK SPESIFIK KE AKUN PROFIL PENGGUNA
  // ========================================================

  // Cek apakah akun dengan email ini sudah mendaftarkan biometrik di profil
  static Future<bool> apakahBiometrikAktifUntukAkun(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final bool aktif = prefs.getBool(_kunciBiometrikAktif) ?? false;
    final String? emailTerdaftar = prefs.getString(_kunciBiometrikEmail);
    return aktif && emailTerdaftar != null && emailTerdaftar.toLowerCase() == email.trim().toLowerCase();
  }

  // Ambil email akun yang telah didaftarkan biometriknya
  static Future<String?> ambilEmailBiometrikTerdaftar() async {
    final prefs = await SharedPreferences.getInstance();
    final bool aktif = prefs.getBool(_kunciBiometrikAktif) ?? false;
    if (!aktif) return null;
    return prefs.getString(_kunciBiometrikEmail);
  }

  // Ambil nama akun yang telah didaftarkan biometriknya
  static Future<String?> ambilNamaBiometrikTerdaftar() async {
    final prefs = await SharedPreferences.getInstance();
    final bool aktif = prefs.getBool(_kunciBiometrikAktif) ?? false;
    if (!aktif) return null;
    return prefs.getString(_kunciBiometrikNama);
  }

  // Daftarkan & hubungkan sidik jari ke akun profil yang sedang aktif
  static Future<void> daftarkanBiometrikAkun({
    required String email,
    required String nama,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kunciBiometrikAktif, true);
    await prefs.setString(_kunciBiometrikEmail, email.trim());
    await prefs.setString(_kunciBiometrikNama, nama.trim());
  }

  // Nonaktifkan biometrik
  static Future<void> nonaktifkanBiometrik() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kunciBiometrikAktif, false);
    await prefs.remove(_kunciBiometrikEmail);
    await prefs.remove(_kunciBiometrikNama);
  }
}
