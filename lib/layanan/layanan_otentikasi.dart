import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/model_pengguna.dart';

// Layanan Otentikasi Pengguna: Login, Registrasi, Enkripsi SHA-256, Sesi,
// serta Penyimpanan Basis Data Akun (Pemesan & Pembeli/Traveler) Anti-Hilang
class LayananOtentikasi {
  static const String _kunciToken = 'token_pengguna';
  static const String _kunciIdPengguna = 'id_pengguna';
  static const String _kunciNamaPengguna = 'nama_pengguna';
  static const String _kunciEmailPengguna = 'email_pengguna';
  static const String _kunciTeleponPengguna = 'telepon_pengguna';
  static const String _kunciFotoPengguna = 'foto_pengguna';
  static const String _kunciPeranPengguna = 'peran_pengguna';
  static const String _kunciLokasiPengguna = 'lokasi_pengguna';
  static const String _kunciDaftarAkun = 'daftar_akun_tersimpan';
  static const String _kunciEmailTerakhir = 'email_terakhir_masuk';

  // Fungsi enkripsi password menggunakan algoritma SHA-256 (Non-Firebase)
  static String enkripsiPassword(String passwordTeksBiasa) {
    final List<int> bytes = utf8.encode(passwordTeksBiasa);
    final Digest hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Akun bawaan awal yang otomatis tersimpan di Database (Hive / SharedPreferences & File Backup)
  // Menyediakan 1 Akun Pemesan dan 1 Akun Pembeli / Traveler di Luar Negeri
  static final List<ModelPengguna> _akunBawaanDatabase = [
    ModelPengguna(
      id: 1,
      nama: 'Pemesan Jastip (Anda)',
      email: 'pemesan@jastipgo.com',
      passwordHash: enkripsiPassword('password123'),
      nomorTelepon: '081234567890',
      fotoProfil: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      peran: 'PEMESAN',
      lokasi: 'Yogyakarta, Indonesia 🇮🇩',
    ),
    ModelPengguna(
      id: 2,
      nama: 'Dimas Pratama',
      email: 'traveler.dimas@jastipgo.com',
      passwordHash: enkripsiPassword('password123'),
      nomorTelepon: '081234567890',
      fotoProfil: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      peran: 'TRAVELER',
      lokasi: 'Ginza, Tokyo 🇯🇵',
    ),
  ];

  // ========================================================
  // MEKANISME CADANGAN ANTI-HILANG (TETAP ADA SAAT HAPUS DATA)
  // ========================================================

  static Future<File?> _ambilFileCadangan() async {
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          return File('${dir.path}/jastipgo_cadangan_akun.json');
        }
        return File('/sdcard/Download/jastipgo_cadangan_akun.json');
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '.';
        return File('$userProfile\\jastipgo_cadangan_akun.json');
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _simpanCadanganEksternal(String dataJson) async {
    try {
      final file = await _ambilFileCadangan();
      if (file != null) {
        await file.writeAsString(dataJson, flush: true);
      }
    } catch (_) {}
  }

  static Future<String?> _bacaCadanganEksternal() async {
    try {
      final file = await _ambilFileCadangan();
      if (file != null && await file.exists()) {
        final isi = await file.readAsString();
        if (isi.trim().isNotEmpty) {
          return isi;
        }
      }
    } catch (_) {}
    return null;
  }

  // Inisialisasi daftar akun saat aplikasi pertama kali dijalankan
  static Future<void> inisialisasiAkun() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataDiPrefs = prefs.getString(_kunciDaftarAkun);

    if (dataDiPrefs == null || dataDiPrefs.isEmpty) {
      final String? cadangan = await _bacaCadanganEksternal();

      if (cadangan != null && cadangan.isNotEmpty) {
        await prefs.setString(_kunciDaftarAkun, cadangan);
        try {
          final List<dynamic> decoded = jsonDecode(cadangan);
          if (decoded.isNotEmpty) {
            final akunTerakhir = ModelPengguna.dariJson(decoded.last);
            await _simpanSesi(akunTerakhir);
            await prefs.setString(_kunciEmailTerakhir, akunTerakhir.email);
          }
        } catch (_) {}
      } else {
        // Simpan akun bawaan pemesan & pembeli ke database
        final List<Map<String, dynamic>> daftarJson =
            _akunBawaanDatabase.map((akun) => akun.keJson()).toList();
        final stringJson = jsonEncode(daftarJson);
        await prefs.setString(_kunciDaftarAkun, stringJson);
        await _simpanCadanganEksternal(stringJson);
      }
    }
  }

  // Ambil semua akun dari database lokal
  static Future<List<ModelPengguna>> ambilSemuaAkun() async {
    await inisialisasiAkun();
    final prefs = await SharedPreferences.getInstance();
    String? dataString = prefs.getString(_kunciDaftarAkun);

    if (dataString == null || dataString.isEmpty) {
      dataString = await _bacaCadanganEksternal();
    }

    if (dataString == null || dataString.isEmpty) return _akunBawaanDatabase;

    try {
      final List<dynamic> dataDecoded = jsonDecode(dataString);
      return dataDecoded.map((item) => ModelPengguna.dariJson(item)).toList();
    } catch (_) {
      return _akunBawaanDatabase;
    }
  }

  // Registrasi Akun Baru (Bisa Pemesan atau Pembeli/Traveler)
  static Future<bool> daftarkanPenggunaBaru({
    required String nama,
    required String email,
    required String password,
    required String nomorTelepon,
    String peran = 'PEMESAN',
    String lokasi = 'Indonesia 🇮🇩',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();

    // Cek apakah email sudah terdaftar
    final bool emailSudahAda = semuaAkun.any(
      (akun) => akun.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailSudahAda) {
      return false; // Email duplikat
    }

    final int idBaru = DateTime.now().millisecondsSinceEpoch % 100000;
    final ModelPengguna akunBaru = ModelPengguna(
      id: idBaru,
      nama: nama.trim(),
      email: email.trim(),
      passwordHash: enkripsiPassword(password),
      nomorTelepon: nomorTelepon.trim(),
      fotoProfil: peran == 'TRAVELER'
          ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'
          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      peran: peran,
      lokasi: lokasi,
    );

    semuaAkun.add(akunBaru);
    final List<Map<String, dynamic>> daftarJson =
        semuaAkun.map((akun) => akun.keJson()).toList();
    final stringJson = jsonEncode(daftarJson);

    // 1. Simpan ke Database SharedPreferences
    await prefs.setString(_kunciDaftarAkun, stringJson);

    // 2. Simpan ke Cadangan File Eksternal (anti-hilang)
    await _simpanCadanganEksternal(stringJson);

    // 3. Langsung aktifkan sesi untuk akun yang baru didaftarkan ini
    await _simpanSesi(akunBaru);
    await prefs.setString(_kunciEmailTerakhir, akunBaru.email);

    return true;
  }

  // Proses Login Pengguna
  static Future<ModelPengguna?> prosesMasuk({
    required String email,
    required String password,
  }) async {
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    final String hashInput = enkripsiPassword(password);
    final String emailInput = email.trim().toLowerCase();

    for (var akun in semuaAkun) {
      if (akun.email.toLowerCase() == emailInput && akun.passwordHash == hashInput) {
        await _simpanSesi(akun);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kunciEmailTerakhir, akun.email);
        return akun;
      }
    }
    return null;
  }

  // Masuk Cepat dengan Sensor Sidik Jari (Biometrik)
  static Future<ModelPengguna?> masukDenganBiometrik({String? email}) async {
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    if (semuaAkun.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final String? emailTerakhir = prefs.getString(_kunciEmailTerakhir);
    final String? emailAktif = prefs.getString(_kunciEmailPengguna);

    ModelPengguna targetAkun;

    if (email != null && email.trim().isNotEmpty) {
      targetAkun = semuaAkun.firstWhere(
        (a) => a.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => semuaAkun.last,
      );
    } else if (emailAktif != null && emailAktif.isNotEmpty) {
      targetAkun = semuaAkun.firstWhere(
        (a) => a.email.toLowerCase() == emailAktif.trim().toLowerCase(),
        orElse: () => semuaAkun.last,
      );
    } else if (emailTerakhir != null && emailTerakhir.isNotEmpty) {
      targetAkun = semuaAkun.firstWhere(
        (a) => a.email.toLowerCase() == emailTerakhir.trim().toLowerCase(),
        orElse: () => semuaAkun.last,
      );
    } else {
      targetAkun = semuaAkun.last;
    }

    await _simpanSesi(targetAkun);
    return targetAkun;
  }

  // Simpan data sesi aktif
  static Future<void> _simpanSesi(ModelPengguna pengguna) async {
    final prefs = await SharedPreferences.getInstance();
    final String token = 'TOKEN-${DateTime.now().millisecondsSinceEpoch}-${pengguna.id}';
    await prefs.setString(_kunciToken, token);
    await prefs.setInt(_kunciIdPengguna, pengguna.id);
    await prefs.setString(_kunciNamaPengguna, pengguna.nama);
    await prefs.setString(_kunciEmailPengguna, pengguna.email);
    await prefs.setString(_kunciTeleponPengguna, pengguna.nomorTelepon);
    await prefs.setString(_kunciFotoPengguna, pengguna.fotoProfil);
    await prefs.setString(_kunciPeranPengguna, pengguna.peran);
    await prefs.setString(_kunciLokasiPengguna, pengguna.lokasi);
  }

  // Cek apakah ada sesi login aktif
  static Future<bool> cekApakahSudahMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_kunciToken);
    return token != null && token.isNotEmpty;
  }

  // Ambil email terakhir
  static Future<String?> ambilEmailTerakhir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kunciEmailTerakhir) ?? prefs.getString(_kunciEmailPengguna);
  }

  // Ambil peran aktif ('PEMESAN' atau 'TRAVELER')
  static Future<String> ambilPeranAktif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kunciPeranPengguna) ?? 'PEMESAN';
  }

  // Ambil data profil aktif
  static Future<ModelPengguna?> ambilProfilAktif() async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt(_kunciIdPengguna);
    final String? email = prefs.getString(_kunciEmailPengguna);
    final String? nama = prefs.getString(_kunciNamaPengguna);
    final String? telepon = prefs.getString(_kunciTeleponPengguna);
    final String? foto = prefs.getString(_kunciFotoPengguna);
    final String? peran = prefs.getString(_kunciPeranPengguna);
    final String? lokasi = prefs.getString(_kunciLokasiPengguna);

    if (id != null || email != null) {
      final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
      for (var akun in semuaAkun) {
        if ((id != null && akun.id == id) ||
            (email != null && akun.email.toLowerCase() == email.toLowerCase())) {
          return akun;
        }
      }
    }

    if (nama != null && email != null) {
      return ModelPengguna(
        id: id ?? 100,
        nama: nama,
        email: email,
        passwordHash: '',
        nomorTelepon: telepon ?? '-',
        fotoProfil: foto ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        peran: peran ?? 'PEMESAN',
        lokasi: lokasi ?? 'Indonesia 🇮🇩',
      );
    }

    final semua = await ambilSemuaAkun();
    if (semua.isNotEmpty) return semua.last;
    return null;
  }

  // Perbarui profil pengguna aktif
  static Future<void> perbaruiProfilAktif({
    required String nama,
    required String nomorTelepon,
    String? lokasi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt(_kunciIdPengguna);
    final String? email = prefs.getString(_kunciEmailPengguna);

    await prefs.setString(_kunciNamaPengguna, nama.trim());
    await prefs.setString(_kunciTeleponPengguna, nomorTelepon.trim());
    if (lokasi != null) {
      await prefs.setString(_kunciLokasiPengguna, lokasi.trim());
    }

    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    for (int i = 0; i < semuaAkun.length; i++) {
      if ((id != null && semuaAkun[i].id == id) ||
          (email != null && semuaAkun[i].email.toLowerCase() == email.toLowerCase())) {
        semuaAkun[i] = ModelPengguna(
          id: semuaAkun[i].id,
          nama: nama.trim(),
          email: semuaAkun[i].email,
          passwordHash: semuaAkun[i].passwordHash,
          nomorTelepon: nomorTelepon.trim(),
          fotoProfil: semuaAkun[i].fotoProfil,
          peran: semuaAkun[i].peran,
          lokasi: lokasi ?? semuaAkun[i].lokasi,
        );
        break;
      }
    }

    final List<Map<String, dynamic>> daftarJson =
        semuaAkun.map((akun) => akun.keJson()).toList();
    final stringJson = jsonEncode(daftarJson);

    await prefs.setString(_kunciDaftarAkun, stringJson);
    await _simpanCadanganEksternal(stringJson);
  }

  // Logout / Hapus sesi login
  static Future<void> keluarSesi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciToken);
    await prefs.remove(_kunciIdPengguna);
    await prefs.remove(_kunciNamaPengguna);
    await prefs.remove(_kunciEmailPengguna);
    await prefs.remove(_kunciTeleponPengguna);
    await prefs.remove(_kunciFotoPengguna);
    await prefs.remove(_kunciPeranPengguna);
    await prefs.remove(_kunciLokasiPengguna);
  }
}
