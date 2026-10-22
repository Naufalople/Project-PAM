import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/model_pengguna.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_sinkronisasi_online.dart';

// Hasil proses registrasi akun baru
class HasilRegistrasi {
  final bool berhasil;
  final String? pesanError;

  HasilRegistrasi({
    required this.berhasil,
    this.pesanError,
  });
}

// Layanan Otentikasi Pengguna: Login, Registrasi, Enkripsi SHA-256, Sesi,
// serta Penyimpanan Basis Data Akun (Pemesan & Pembeli/Traveler) Online & Lokal
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
  static const String _kunciWaktuMasukBackground = 'waktu_masuk_background';
  static const String _kunciDestinasiTraveler = 'destinasi_aktif_traveler';
  static const int batasMenitTimeout = 15;

  // Endpoint REST API Publik untuk Sinkronisasi Akun Lintas Perangkat
  static const String _urlOnlineApi = 'https://api.restful-api.dev/objects';
  static const String _idRegistriOnline = 'ff808181a09d98f701a153a07864177d';

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
      nama: 'Siti Nurhaliza',
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

    // Sinkronkan akun bawaan awal ke database lokal Hive
    for (var akun in _akunBawaanDatabase) {
      await LayananBasisDataLokal.simpanAkunHive(akun.keJson());
    }

    if (dataDiPrefs == null || dataDiPrefs.isEmpty) {
      final String? cadangan = await _bacaCadanganEksternal();

      if (cadangan != null && cadangan.isNotEmpty) {
        await prefs.setString(_kunciDaftarAkun, cadangan);
        try {
          final List<dynamic> decoded = jsonDecode(cadangan);
          if (decoded.isNotEmpty) {
            for (var item in decoded) {
              if (item is Map) {
                await LayananBasisDataLokal.simpanAkunHive(Map<String, dynamic>.from(item));
              }
            }
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
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(dataDiPrefs);
        for (var item in decoded) {
          if (item is Map) {
            await LayananBasisDataLokal.simpanAkunHive(Map<String, dynamic>.from(item));
          }
        }
      } catch (_) {}
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

  // ========================================================
  // SINKRONISASI DATABASE ONLINE (REST API LINTAS PERANGKAT)
  // ========================================================

  // Sinkronisasi akun terenkripsi (SHA-256) ke database online REST API
  static Future<void> _sinkronkanKeDatabaseOnline(ModelPengguna akun) async {
    try {
      // 1. Simpan akun individual ke endpoint REST API
      await http.post(
        Uri.parse(_urlOnlineApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'JASTIPGO_USER_${akun.email.toLowerCase()}',
          'data': {
            'id': akun.id,
            'nama': akun.nama,
            'email': akun.email,
            'passwordHash': akun.passwordHash,
            'nomorTelepon': akun.nomorTelepon,
            'fotoProfil': akun.fotoProfil,
            'peran': akun.peran,
            'lokasi': akun.lokasi,
            'terdaftarPada': DateTime.now().toIso8601String(),
          },
        }),
      ).timeout(const Duration(seconds: 4));

      // 2. Perbarui registri pengguna global online agar dapat divalidasi dari perangkat lain
      final resGet = await http
          .get(Uri.parse('$_urlOnlineApi/$_idRegistriOnline'))
          .timeout(const Duration(seconds: 4));

      if (resGet.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resGet.body);
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic> ? Map<String, dynamic>.from(body['data']) : {};
        List<dynamic> users = data['users'] is List ? List<dynamic>.from(data['users']) : [];

        // Hapus duplikat akun lama bila ada
        users.removeWhere((u) {
          if (u is Map) return u['email']?.toString().toLowerCase() == akun.email.toLowerCase();
          return false;
        });

        users.add({
          'id': akun.id,
          'nama': akun.nama,
          'email': akun.email,
          'passwordHash': akun.passwordHash,
          'nomorTelepon': akun.nomorTelepon,
          'fotoProfil': akun.fotoProfil,
          'peran': akun.peran,
          'lokasi': akun.lokasi,
        });

        await http.put(
          Uri.parse('$_urlOnlineApi/$_idRegistriOnline'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': 'JASTIPGO_GLOBAL_USERS',
            'data': {'users': users},
          }),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Toleransi offline: jika tidak ada koneksi internet, akun tetap aman di penyimpanan lokal
    }
  }

  // Validasi kredensial login langsung ke REST API Online secara real-time
  static Future<ModelPengguna?> _validasiLoginOnline(String emailInput, String hashInput) async {
    try {
      final res = await http
          .get(Uri.parse('$_urlOnlineApi/$_idRegistriOnline'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['data'] != null && body['data']['users'] != null) {
          final List<dynamic> users = body['data']['users'];
          for (var item in users) {
            if (item is Map) {
              final String itemEmail = item['email']?.toString().toLowerCase() ?? '';
              final String itemHash = item['passwordHash']?.toString() ?? '';
              if (itemEmail == emailInput && itemHash == hashInput) {
                return ModelPengguna(
                  id: item['id'] is int
                      ? item['id']
                      : int.tryParse(item['id']?.toString() ?? '') ?? 999,
                  nama: item['nama']?.toString() ?? 'Pengguna',
                  email: item['email']?.toString() ?? emailInput,
                  passwordHash: itemHash,
                  nomorTelepon: item['nomorTelepon']?.toString() ?? '-',
                  fotoProfil: item['fotoProfil']?.toString() ??
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
                  peran: item['peran']?.toString() ?? 'PEMESAN',
                  lokasi: item['lokasi']?.toString() ?? 'Indonesia 🇮🇩',
                );
              }
            }
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }
    return null;
  }

  // ========================================================
  // VALIDASI PENDAFTARAN & PENCEGAHAN DUPLIKASI EMAIL (TODO_VALIDASI_AKUN)
  // ========================================================

  /// Melakukan query pengecekan duplikasi akun ke database lokal (Hive & SharedPreferences)
  /// serta database online REST API secara real-time sebelum registrasi.
  /// Aturan Validasi:
  /// - Fokus pengecekan duplikasi HANYA pada alamat EMAIL (Email harus unik).
  /// - Penggunaan Username/Nama yang sama DIIZINKAN untuk alamat email yang berbeda.
  /// - Mengembalikan pesan error jika email sudah ada di database:
  ///   "Email sudah terdaftar, silakan gunakan email lain"
  /// - Mengembalikan null jika email belum terdaftar (diizinkan daftar).
  static Future<String?> periksaDuplikasiAkun({
    required String email,
    String? namaAtauUsername,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      return 'Email wajib diisi.';
    }

    // 1. Query Pengecekan Duplikasi Email ke Database Lokal Hive (NoSQL)
    final List<Map<String, dynamic>> akunHive = LayananBasisDataLokal.ambilSemuaAkunHive();
    for (var akun in akunHive) {
      final String em = akun['email']?.toString().trim().toLowerCase() ?? '';
      if (em == cleanEmail) {
        return 'Email sudah terdaftar, silakan gunakan email lain';
      }
    }

    // 2. Query Pengecekan Duplikasi Email ke Database Lokal SharedPreferences & Cadangan Eksternal
    final List<ModelPengguna> akunLokal = await ambilSemuaAkun();
    for (var akun in akunLokal) {
      final String em = akun.email.trim().toLowerCase();
      if (em == cleanEmail) {
        return 'Email sudah terdaftar, silakan gunakan email lain';
      }
    }

    // 3. Query Pengecekan Duplikasi Email ke Database Online REST API Global Registry
    try {
      final resGet = await http
          .get(Uri.parse('$_urlOnlineApi/$_idRegistriOnline'))
          .timeout(const Duration(seconds: 4));

      if (resGet.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resGet.body);
        final Map<String, dynamic> data =
            body['data'] is Map<String, dynamic> ? Map<String, dynamic>.from(body['data']) : {};
        if (data['users'] is List) {
          final List<dynamic> users = data['users'];
          for (var u in users) {
            if (u is Map) {
              final String em = u['email']?.toString().trim().toLowerCase() ?? '';
              if (em == cleanEmail) {
                return 'Email sudah terdaftar, silakan gunakan email lain';
              }
            }
          }
        }
      }
    } catch (_) {
      // Toleransi offline: jika tidak ada koneksi internet, validasi tetap aman oleh database lokal
    }

    return null; // Email baru dan belum terdaftar di database (Username/Nama boleh sama)
  }

  // Registrasi Akun Baru (Dengan Pengecekan Validasi Duplikat Menyeluruh)
  static Future<HasilRegistrasi> prosesDaftarAkunBaru({
    required String nama,
    required String email,
    required String password,
    required String nomorTelepon,
    String peran = 'PEMESAN',
    String lokasi = 'Indonesia 🇮🇩',
  }) async {
    // 1. Lakukan query pengecekan terlebih dahulu ke database lokal & online
    final String? duplikasi = await periksaDuplikasiAkun(
      email: email,
      namaAtauUsername: nama,
    );

    // 2. Jika akun sudah ada di database:
    // - Gagalkan proses registrasi secara langsung.
    // - Jangan membuat entri data baru atau mengizinkan login otomatis.
    if (duplikasi != null) {
      return HasilRegistrasi(berhasil: false, pesanError: duplikasi);
    }

    // 3. Pendaftaran hanya berlanjut jika akun benar-benar baru dan belum tercatat di database
    final prefs = await SharedPreferences.getInstance();
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();

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

    // a. Simpan ke Database SharedPreferences Lokal
    await prefs.setString(_kunciDaftarAkun, stringJson);

    // b. Simpan ke Cadangan File Eksternal (anti-hilang)
    await _simpanCadanganEksternal(stringJson);

    // c. Simpan ke Database Lokal Hive (kotak_pengguna)
    await LayananBasisDataLokal.simpanAkunHive(akunBaru.keJson());

    // d. Sinkronkan Kredensial Terenkripsi ke Database Online / REST API Backend
    _sinkronkanKeDatabaseOnline(akunBaru);

    // e. Langsung aktifkan sesi untuk akun yang baru didaftarkan ini
    await _simpanSesi(akunBaru);
    await prefs.setString(_kunciEmailTerakhir, akunBaru.email);

    return HasilRegistrasi(berhasil: true);
  }

  // Wrapper kompatibilitas untuk fungsi daftarkanPenggunaBaru
  static Future<bool> daftarkanPenggunaBaru({
    required String nama,
    required String email,
    required String password,
    required String nomorTelepon,
    String peran = 'PEMESAN',
    String lokasi = 'Indonesia 🇮🇩',
  }) async {
    final hasil = await prosesDaftarAkunBaru(
      nama: nama,
      email: email,
      password: password,
      nomorTelepon: nomorTelepon,
      peran: peran,
      lokasi: lokasi,
    );
    return hasil.berhasil;
  }

  // Proses Login Pengguna (Online REST API dengan Fallback Database Lokal)
  static Future<ModelPengguna?> prosesMasuk({
    required String email,
    required String password,
  }) async {
    final String hashInput = enkripsiPassword(password);
    final String identitasInput = email.trim().toLowerCase();

    // 1. Validasi langsung ke Database Online / REST API secara Real-Time
    final onlineAkun = await _validasiLoginOnline(identitasInput, hashInput);
    if (onlineAkun != null) {
      // Simpan akun online ke lokal jika belum ada di perangkat ini
      final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
      if (!semuaAkun.any((a) => a.email.toLowerCase() == onlineAkun.email.toLowerCase())) {
        semuaAkun.add(onlineAkun);
        final prefs = await SharedPreferences.getInstance();
        final stringJson = jsonEncode(semuaAkun.map((a) => a.keJson()).toList());
        await prefs.setString(_kunciDaftarAkun, stringJson);
        await _simpanCadanganEksternal(stringJson);
        await LayananBasisDataLokal.simpanAkunHive(onlineAkun.keJson());
      }
      await _simpanSesi(onlineAkun);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kunciEmailTerakhir, onlineAkun.email);
      // Pulihkan riwayat online ke cache lokal
      await LayananSinkronisasiOnline.pulihkanDataPenggunaOnline(
        userId: onlineAkun.id.toString(),
        email: onlineAkun.email,
        peran: onlineAkun.peran,
        nama: onlineAkun.nama,
      );
      return onlineAkun;
    }

    // 2. Fallback: Validasi pada Database Lokal (Offline Mode / Akun Bawaan)
    final List<ModelPengguna> semuaAkunLokal = await ambilSemuaAkun();
    for (var akun in semuaAkunLokal) {
      if ((akun.email.toLowerCase() == identitasInput || akun.nama.toLowerCase() == identitasInput) &&
          akun.passwordHash == hashInput) {
        await _simpanSesi(akun);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kunciEmailTerakhir, akun.email);
        // Pulihkan riwayat online ke cache lokal
        await LayananSinkronisasiOnline.pulihkanDataPenggunaOnline(
          userId: akun.id.toString(),
          email: akun.email,
          peran: akun.peran,
          nama: akun.nama,
        );
        return akun;
      }
    }
    return null;
  }

  // ========================================================
  // MANAJEMEN SESI & TIMEOUT BACKGROUND (KETENTUAN POIN 1)
  // ========================================================

  // Catat waktu aplikasi diminimalkan / masuk background (paused / inactive)
  static Future<void> catatWaktuMasukBackground() async {
    final bool sedangMasuk = await cekApakahSudahMasuk();
    if (sedangMasuk) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kunciWaktuMasukBackground, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // Hapus catatan waktu background saat aplikasi kembali aktif dalam kurun waktu aman
  static Future<void> hapusWaktuMasukBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciWaktuMasukBackground);
  }

  // Periksa apakah sesi telah kedaluwarsa setelah berada di background >= 15 menit
  static Future<bool> apakahSesiKedaluwarsa() async {
    final bool sedangMasuk = await cekApakahSudahMasuk();
    if (!sedangMasuk) return false;

    final prefs = await SharedPreferences.getInstance();
    final int? waktuLatar = prefs.getInt(_kunciWaktuMasukBackground);
    if (waktuLatar == null) return false;

    final int selisihMilidetik = DateTime.now().millisecondsSinceEpoch - waktuLatar;
    final int batasMilidetik = batasMenitTimeout * 60 * 1000;

    if (selisihMilidetik >= batasMilidetik) {
      return true;
    } else {
      // Masih dalam batas waktu aman (< 15 menit), reset catatan waktu latar
      await hapusWaktuMasukBackground();
      return false;
    }
  }

  // Tangani Cold Start: Saat aplikasi dimatikan/dibersihkan dari recent apps lalu dibuka kembali,
  // wajibkan login ulang sesuai ketentuan poin 1
  static Future<void> tanganiColdStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kunciToken);
    await prefs.remove(_kunciWaktuMasukBackground);
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
    await LayananSinkronisasiOnline.pulihkanDataPenggunaOnline(
      userId: targetAkun.id.toString(),
      email: targetAkun.email,
      peran: targetAkun.peran,
      nama: targetAkun.nama,
    );
    return targetAkun;
  }

  // Ganti akun aktif secara instan (untuk kemudahan pengujian peran Pemesan vs Traveler)
  static Future<ModelPengguna?> gantiAkunAktif(String email) async {
    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    for (var akun in semuaAkun) {
      if (akun.email.toLowerCase() == email.trim().toLowerCase()) {
        await _simpanSesi(akun);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kunciEmailTerakhir, akun.email);
        await LayananSinkronisasiOnline.pulihkanDataPenggunaOnline(
          userId: akun.id.toString(),
          email: akun.email,
          peran: akun.peran,
          nama: akun.nama,
        );
        return akun;
      }
    }
    return null;
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

  // Perbarui foto profil pengguna aktif (Poin 3: Fitur Ubah Foto Profil Kustom)
  static Future<void> perbaruiFotoProfilAktif(String pathAtauUrlFoto) async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt(_kunciIdPengguna);
    final String? email = prefs.getString(_kunciEmailPengguna);

    await prefs.setString(_kunciFotoPengguna, pathAtauUrlFoto.trim());

    final List<ModelPengguna> semuaAkun = await ambilSemuaAkun();
    for (int i = 0; i < semuaAkun.length; i++) {
      if ((id != null && semuaAkun[i].id == id) ||
          (email != null && semuaAkun[i].email.toLowerCase() == email.toLowerCase())) {
        semuaAkun[i] = ModelPengguna(
          id: semuaAkun[i].id,
          nama: semuaAkun[i].nama,
          email: semuaAkun[i].email,
          passwordHash: semuaAkun[i].passwordHash,
          nomorTelepon: semuaAkun[i].nomorTelepon,
          fotoProfil: pathAtauUrlFoto.trim(),
          peran: semuaAkun[i].peran,
          lokasi: semuaAkun[i].lokasi,
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

  // ========================================================
  // DESTINASI AKTIF TRAVELER & VALIDASI PEMESANAN (POIN 4)
  // ========================================================

  static const List<Map<String, String>> daftarDestinasiTersedia = [
    {'nama': 'Jepang', 'bendera': '🇯🇵', 'kota': 'Tokyo / Ginza'},
    {'nama': 'Korea Selatan', 'bendera': '🇰🇷', 'kota': 'Seoul / Myeongdong'},
    {'nama': 'London (UK)', 'bendera': '🇬🇧', 'kota': 'London / Harrods'},
    {'nama': 'Singapura', 'bendera': '🇸🇬', 'kota': 'Orchard Road'},
    {'nama': 'China', 'bendera': '🇨🇳', 'kota': 'Shanghai'},
  ];

  static Future<String> ambilDestinasiAktifTraveler() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kunciDestinasiTraveler) ?? 'Jepang';
  }

  /// Memeriksa apakah Traveler diizinkan mengubah negara destinasinya.
  /// Diizinkan HANYA JIKA tidak ada pesanan aktif (0 pesanan) ATAU semua pesanan sudah dikirim ke Indonesia (tahapStatus >= 4).
  static bool dapatMengubahDestinasiTraveler({String? namaTraveler}) {
    return !LayananBasisDataLokal.apakahAdaPesananBelumDikirim(namaTraveler: namaTraveler);
  }

  static Future<bool> simpanDestinasiAktifTraveler(String negara, {String? namaTraveler}) async {
    if (LayananBasisDataLokal.apakahAdaPesananBelumDikirim(namaTraveler: namaTraveler)) {
      return false; // Gagalkan proses: masih ada pesanan yang belum dikirim ke Indonesia
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kunciDestinasiTraveler, negara.trim());
    return true;
  }

  static bool apakahNegaraSesuai(String negaraBarang, String destinasiTraveler) {
    final b = negaraBarang.toLowerCase().trim();
    final d = destinasiTraveler.toLowerCase().trim();

    if (b == d) return true;
    if (b.contains('jepang') && d.contains('jepang')) return true;
    if (b.contains('korea') && d.contains('korea')) return true;
    if ((b.contains('london') || b.contains('inggris') || b.contains('uk')) &&
        (d.contains('london') || d.contains('inggris') || d.contains('uk'))) {
      return true;
    }
    if (b.contains('singapura') && d.contains('singapura')) return true;
    if (b.contains('china') && d.contains('china')) return true;

    return false;
  }

  // Logout / Hapus sesi login & isolasi state akun (Poin 4: Bersihkan memori promo saat logout)
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
    // Poin 4: Bersihkan memori (clear state) promo saat pengguna logout agar promo tiap akun mandiri
    LayananBasisDataLokal.bersihkanStatePromo();
    // Catatan Poin 3: Data obrolan tetap persisten di database Hive dan tidak dihapus saat logout
  }
}
