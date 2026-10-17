import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/model_pengguna.dart';

// Layanan Otentikasi Pengguna: Login, Registrasi, Enkripsi SHA-256, dan Sesi
class LayananOtentikasi {
  static const String _kunciToken = 'token_pengguna';
  static const String _kunciIdPengguna = 'id_pengguna';
  static const String _kunciNamaPengguna = 'nama_pengguna';
  static const String _kunciEmailPengguna = 'email_pengguna';
  static const String _kunciDaftarAkun = 'daftar_akun_tersimpan';

  // Fungsi enkripsi password menggunakan algoritma SHA-256 (Non-Firebase)
  static String enkripsiPassword(String passwordTeksBiasa) {
    final List<int> bytes = utf8.encode(passwordTeksBiasa);
    final Digest hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Akun bawaan (Default Demo Accounts)
  static final List<ModelPengguna> _akunBawaan = [
    ModelPengguna(
      id: 1,
      nama: 'Budi Santoso',
      email: 'budi@jastipgo.com',
      passwordHash: enkripsiPassword('password123'),
      nomorTelepon: '081234567890',
      fotoProfil: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    ),
    ModelPengguna(
      id: 2,
      nama: 'Siti Rahma',
      email: 'siti@jastipgo.com',
      passwordHash: enkripsiPassword('rahasia123'),
      nomorTelepon: '082198765432',
      fotoProfil: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    ),
  ];

  // Inisialisasi daftar akun ke SharedPreferences jika belum ada
  static Future<void> inisialisasiAkun() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kunciDaftarAkun)) {
      final List<Map<String, dynamic>> daftarJson =
          _akunBawaan.map((akun) => akun.keJson()).toList();
      await prefs.setString(_kunciDaftarAkun, jsonEncode(daftarJson));
    }
  }

  // Ambil semua akun yang terdaftar
  static Future<List<ModelPengguna>> ambilSemuaAkun() async {
    await inisialisasiAkun();
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(_kunciDaftarAkun);
    if (dataString == null) return _akunBawaan;

    final List<dynamic> dataDecoded = jsonDecode(dataString);
    return dataDecoded.map((item) => ModelPengguna.dariJson(item)).toList();
  }

  // Proses Registrasi Akun Baru dengan Password Terenkripsi
  static Future<bool> daftarkanPenggunaBaru({
    required String nama,
    required String email,
    required String password,
    required String nomorTelepon,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();

    // Cek apakah email sudah terdaftar
    final bool emailSudahAda = semuaAkun.any(
      (akun) => akun.email.toLowerCase() == email.toLowerCase(),
    );
    if (emailSudahAda) {
      return false; // Email duplikat
    }

    final int idBaru = semuaAkun.length + 1;
    final ModelPengguna akunBaru = ModelPengguna(
      id: idBaru,
      nama: nama,
      email: email,
      passwordHash: enkripsiPassword(password),
      nomorTelepon: nomorTelepon,
      fotoProfil: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    );

    semuaAkun.add(akunBaru);
    final List<Map<String, dynamic>> daftarJson =
        semuaAkun.map((akun) => akun.keJson()).toList();
    await prefs.setString(_kunciDaftarAkun, jsonEncode(daftarJson));
    return true;
  }

  // Proses Login Pengguna (Membandingkan Hash Password)
  static Future<ModelPengguna?> prosesMasuk({
    required String email,
    required String password,
  }) async {
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    final String hashInput = enkripsiPassword(password);

    for (var akun in semuaAkun) {
      if (akun.email.toLowerCase() == email.toLowerCase() &&
          akun.passwordHash == hashInput) {
        // Simpan sesi login
        await _simpanSesi(akun);
        return akun;
      }
    }
    return null; // Login gagal
  }

  // Proses Masuk Cepat dengan Biometrik (Menggunakan Akun Terdaftar / Email Input)
  static Future<ModelPengguna?> masukDenganBiometrik({String? email}) async {
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    if (semuaAkun.isEmpty) return null;

    ModelPengguna targetAkun;
    if (email != null && email.trim().isNotEmpty) {
      targetAkun = semuaAkun.firstWhere(
        (a) => a.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => semuaAkun.first,
      );
    } else {
      targetAkun = semuaAkun.first;
    }

    await _simpanSesi(targetAkun);
    return targetAkun;
  }

  // Simpan data sesi pengguna ke SharedPreferences
  static Future<void> _simpanSesi(ModelPengguna pengguna) async {
    final prefs = await SharedPreferences.getInstance();
    final String token = 'TOKEN-${DateTime.now().millisecondsSinceEpoch}-${pengguna.id}';
    await prefs.setString(_kunciToken, token);
    await prefs.setInt(_kunciIdPengguna, pengguna.id);
    await prefs.setString(_kunciNamaPengguna, pengguna.nama);
    await prefs.setString(_kunciEmailPengguna, pengguna.email);
  }

  // Cek apakah ada sesi login aktif
  static Future<bool> cekApakahSudahMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_kunciToken);
    return token != null && token.isNotEmpty;
  }

  // Ambil data profil pengguna yang sedang login
  static Future<ModelPengguna?> ambilProfilAktif() async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt(_kunciIdPengguna);
    if (id == null) return null;

    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    for (var akun in semuaAkun) {
      if (akun.id == id) return akun;
    }
    return null;
  }

  // Logout / Hapus sesi login
  static Future<void> keluarSesi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciToken);
    await prefs.remove(_kunciIdPengguna);
    await prefs.remove(_kunciNamaPengguna);
    await prefs.remove(_kunciEmailPengguna);
  }
}
