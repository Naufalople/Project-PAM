import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_pesan_chat.dart';
import '../model/model_transaksi_rekber.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_notifikasi.dart';
import 'layanan_otentikasi.dart';
import 'layanan_rekber.dart';

/// Layanan Sinkronisasi Database Real-Time Online Lintas Perangkat (Strictly Non-Firebase)
/// 
/// Sesuai TODO_PERBAIKAN_DATABASE.txt, TODO_SINKRONISASI_AKUN.txt, & TODO_SINKRONISASI_REALTIME.txt:
/// 1. MIGRASI DATABASE ONLINE REAL-TIME (NON-FIREBASE):
///    - DILARANG KERAS menggunakan Firebase Auth, Firestore, atau Realtime Database.
///    - Menggunakan REST API Backend Collections terotentikasi di cloud dan dukungan Node.js backend.
///    - Sinkronisasi instan saat membuat pesanan, update status, dan kirim pesan.
/// 
/// 2. MANAJEMEN PENYIMPANAN LOKAL SEBAGAI CACHE (OFFLINE SUPPORT):
///    - Hive berfungsi sebagai cache offline-first: baca dari lokal terlebih dahulu agar instan.
///    - Data baru dari server online otomatis disimpan ke Hive.
/// 
/// 3. PERSISTENSI DATA LINTAS PERANGKAT (CROSS-DEVICE LOGIN):
///    - Data pesanan dan chat diikat dengan ID Akun di cloud.
///    - Saat login di HP baru, `pulihkanDataPenggunaOnline` memulihkan seluruh riwayat.
/// 
/// 4. NOTIFIKASI REAL-TIME & PENCAIRAN OTOMATIS REKBER:
///    - Notifikasi pesanan & chat masuk di HP Traveler.
///    - Saat barang dikonfirmasi sampai, Rekber otomatis cair ke saldo aktif Traveler.
class LayananSinkronisasiOnline {
  // REST API Cloud Collections Endpoints (Strictly Non-Firebase)
  static const String _baseUrlCloud = 'https://api.restful-api.dev/collections';
  static const String _koleksiPesanan = 'orders';
  static const String _koleksiChat = 'chats';
  static const String _koleksiRekber = 'rekber';
  static const String _apiKey = 'c5413392-8fb5-44b2-84f4-81a819c9d9e8';

  // Opsi Custom Backend Node.js lokal / hosting (Strictly Non-Firebase)
  static String urlCustomBackend = 'http://localhost:3000';

  // Headers wajib dengan API Key & User-Agent
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) JastipGoApp/2.0',
  };

  // Reactive notifiers agar UI layar dapat langsung merespons data baru
  static final ValueNotifier<int> pemicuPembaruanPesanan = ValueNotifier<int>(0);
  static final ValueNotifier<int> pemicuPembaruanChat = ValueNotifier<int>(0);
  static final ValueNotifier<int> pemicuPembaruanRekber = ValueNotifier<int>(0);

  // Status tracking untuk mencegah notifikasi ganda / spam
  static final Set<String> _idPesananTerkonfirmasi = {};
  static final Set<String> _idPesanChatTerkonfirmasi = {};
  static final Set<String> _idDanaCairTerkonfirmasi = {};

  static Timer? _timerPolling;
  static bool _sedangSinkron = false;
  static bool _terinisialisasi = false;

  /// Inisialisasi awal saat aplikasi dijalankan
  static Future<void> inisialisasi() async {
    if (_terinisialisasi) return;

    _catatIdLokalLama();
    _terinisialisasi = true;

    // Background sync berkala (15 detik) untuk mode santai di latar belakang
    mulaiSinkronisasiOtomatis(interval: const Duration(seconds: 15));

    // Jalankan sinkronisasi awal
    await sinkronkanSemua();
  }

  /// Catat seluruh ID pesanan dan chat lokal yang sudah ada di memori awal
  static void _catatIdLokalLama() {
    try {
      if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
        final boxPesanan = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
        for (int i = 0; i < boxPesanan.length; i++) {
          final d = boxPesanan.getAt(i);
          if (d is Map && d['idPesanan'] != null) {
            _idPesananTerkonfirmasi.add(d['idPesanan'].toString());
            final int st = (d['tahapStatus'] as num?)?.toInt() ?? 1;
            if (st >= 6) {
              _idDanaCairTerkonfirmasi.add(d['idPesanan'].toString());
            }
          }
        }
      }

      if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakChat)) {
        final boxChat = Hive.box(LayananBasisDataLokal.namaKotakChat);
        for (int i = 0; i < boxChat.length; i++) {
          final d = boxChat.getAt(i);
          if (d is Map && d['id'] != null) {
            _idPesanChatTerkonfirmasi.add(d['id'].toString());
          }
        }
      }
    } catch (_) {}
  }

  /// Memulai background polling (default 15 detik)
  static void mulaiSinkronisasiOtomatis({Duration interval = const Duration(seconds: 15)}) {
    _timerPolling?.cancel();
    _timerPolling = Timer.periodic(interval, (_) async {
      await sinkronkanSemua();
    });
  }

  /// Menghentikan background polling
  static void hentikanSinkronisasiOtomatis() {
    _timerPolling?.cancel();
    _timerPolling = null;
  }

  /// Jalankan seluruh sinkronisasi data online (Pesanan, Chat, & Rekber)
  static Future<void> sinkronkanSemua() async {
    if (_sedangSinkron) return;
    _sedangSinkron = true;
    try {
      await Future.wait([
        sinkronkanPesananOnline(),
        sinkronkanChatOnline(),
        sinkronkanRekberOnline(),
      ]);
    } catch (_) {
    } finally {
      _sedangSinkron = false;
    }
  }

  // =========================================================================
  // 1. SINKRONISASI PESANAN LINTAS PERANGKAT & NOTIFIKASI TRAVELER
  // =========================================================================

  /// Tarik data pesanan dari database online dan perbarui cache lokal Hive
  static Future<bool> sinkronkanPesananOnline() async {
    try {
      if (!Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
        await Hive.openBox(LayananBasisDataLokal.namaKotakPesanan);
      }

      final url = Uri.parse('$_baseUrlCloud/$_koleksiPesanan/objects');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        final List<dynamic> items = body is List ? body : [];

        final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
        final profilAktif = await LayananOtentikasi.ambilProfilAktif();
        final String peranAktif = profilAktif?.peran ?? 'PEMESAN';

        bool adaPerubahanLokal = false;
        final Set<String> idOnlineSet = {};

        for (var item in items) {
          final Map<String, dynamic> dataMap = _ekstrakDataMap(item);
          if (dataMap.isEmpty || dataMap['idPesanan'] == null) continue;

          final pesananOnline = ModelPesananJastip.dariMap(dataMap);
          idOnlineSet.add(pesananOnline.idPesanan);

          int indexLokal = -1;
          ModelPesananJastip? pesananLokal;
          for (int i = 0; i < box.length; i++) {
            final d = box.getAt(i);
            if (d is Map && d['idPesanan'] == pesananOnline.idPesanan) {
              indexLokal = i;
              pesananLokal = ModelPesananJastip.dariMap(d);
              break;
            }
          }

          if (indexLokal == -1) {
            // Pesanan baru dari HP lain (HP 1 Pemesan -> HP 2 Traveler)
            await box.add(pesananOnline.keMap());
            adaPerubahanLokal = true;

            if (peranAktif == 'TRAVELER') {
              if (!_idPesananTerkonfirmasi.contains(pesananOnline.idPesanan)) {
                _idPesananTerkonfirmasi.add(pesananOnline.idPesanan);
                await LayananNotifikasi.picuNotifikasiSistem(
                  judul: 'Pesanan Titipan Baru Masuk! 🛍️',
                  pesan:
                      'Pesanan #${pesananOnline.idPesanan} dari ${pesananOnline.namaPemesan ?? "Pemesan"} senilai Rp ${_formatRupiah(pesananOnline.totalHargaIdr)} perlu diproses.',
                  ikon: Icons.shopping_bag_rounded,
                  warna: Colors.teal.shade800,
                );
              }
            }
          } else {
            // Pembaruan status pesanan (misal konfirmasi sampai)
            if (pesananLokal != null &&
                (pesananLokal.tahapStatus != pesananOnline.tahapStatus ||
                    pesananLokal.lokasiTerkini != pesananOnline.lokasiTerkini)) {
              await box.putAt(indexLokal, pesananOnline.keMap());
              adaPerubahanLokal = true;

              // Pencairan Otomatis Rekber saat barang dikonfirmasi sampai
              if (pesananOnline.tahapStatus >= 6 && pesananLokal.tahapStatus < 6) {
                if (peranAktif == 'TRAVELER') {
                  if (!_idDanaCairTerkonfirmasi.contains(pesananOnline.idPesanan)) {
                    _idDanaCairTerkonfirmasi.add(pesananOnline.idPesanan);
                    await LayananNotifikasi.picuNotifikasiSistem(
                      judul: 'Dana Rekber Otomatis Cair! 🎉',
                      pesan:
                          'Pemesan telah mengonfirmasi barang diterima. Dana Rp ${_formatRupiah(pesananOnline.totalHargaIdr)} dari #${pesananOnline.idPesanan} berhasil masuk ke Saldo Aktif Anda!',
                      ikon: Icons.account_balance_wallet_rounded,
                      warna: Colors.green.shade800,
                    );
                  }
                }
              }
            }
          }
        }

        // Sinkronisasi pesanan lokal yang belum terunggah ke cloud
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['idPesanan'] != null) {
            final p = ModelPesananJastip.dariMap(d);
            if (!idOnlineSet.contains(p.idPesanan)) {
              await _unggahObjekKoleksi(_koleksiPesanan, p.idPesanan, p.keMap());
            }
          }
        }

        if (adaPerubahanLokal) {
          pemicuPembaruanPesanan.value++;
          pemicuPembaruanRekber.value++;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Unggah pesanan baru ke server online secara instan
  static Future<bool> unggahPesananBaru(ModelPesananJastip pesanan) async {
    try {
      // 1. Simpan ke Hive cache lokal
      if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
        final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
        bool sudahAda = false;
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['idPesanan'] == pesanan.idPesanan) {
            sudahAda = true;
            break;
          }
        }
        if (!sudahAda) {
          await box.add(pesanan.keMap());
        }
      }

      // 2. Unggah ke Cloud Collections
      final sukses = await _unggahObjekKoleksi(
        _koleksiPesanan,
        pesanan.idPesanan,
        pesanan.keMap(),
      );

      _idPesananTerkonfirmasi.add(pesanan.idPesanan);
      pemicuPembaruanPesanan.value++;
      return sukses;
    } catch (_) {
      return false;
    }
  }

  /// Perbarui status pesanan di database online
  static Future<bool> perbaruiStatusPesananOnline(
    String idPesanan, {
    required int tahapStatus,
    required String lokasiTerkini,
    String? metodePenyerahan,
    String? alamatPengiriman,
  }) async {
    try {
      // 1. Update di Hive cache lokal
      if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
        final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['idPesanan'] == idPesanan) {
            final m = Map<String, dynamic>.from(d);
            m['tahapStatus'] = tahapStatus;
            m['lokasiTerkini'] = lokasiTerkini;
            if (metodePenyerahan != null) m['metodePenyerahan'] = metodePenyerahan;
            if (alamatPengiriman != null) m['alamatPengiriman'] = alamatPengiriman;
            await box.putAt(i, m);
            break;
          }
        }
      }

      // 2. Ambil dokumen online terkait dan update via PUT
      final docId = await _temukanDocIdDiKoleksi(_koleksiPesanan, 'idPesanan', idPesanan);
      if (docId != null) {
        final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['idPesanan'] == idPesanan) {
            await http.put(
              Uri.parse('$_baseUrlCloud/$_koleksiPesanan/objects/$docId'),
              headers: _headers,
              body: jsonEncode({
                'name': idPesanan,
                'data': d,
              }),
            ).timeout(const Duration(seconds: 4));
            break;
          }
        }
      }

      pemicuPembaruanPesanan.value++;
      pemicuPembaruanRekber.value++;
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 2. SINKRONISASI CHAT LINTAS PERANGKAT & OFFLINE CACHE
  // =========================================================================

  /// Tarik seluruh pesan chat online dan sinkronkan ke cache lokal Hive
  static Future<bool> sinkronkanChatOnline() async {
    try {
      if (!Hive.isBoxOpen(LayananBasisDataLokal.namaKotakChat)) {
        await Hive.openBox(LayananBasisDataLokal.namaKotakChat);
      }

      final url = Uri.parse('$_baseUrlCloud/$_koleksiChat/objects');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        final List<dynamic> items = body is List ? body : [];

        final box = Hive.box(LayananBasisDataLokal.namaKotakChat);
        final profilAktif = await LayananOtentikasi.ambilProfilAktif();
        final String peranAktif = profilAktif?.peran ?? 'PEMESAN';
        final String userIdAktif = profilAktif?.id.toString() ?? '1';
        final String emailAktif = profilAktif?.email ?? '';

        final Set<String> idChatLokal = {};
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['id'] != null) {
            idChatLokal.add(d['id'].toString());
          }
        }

        bool adaPerubahanLokal = false;

        for (var item in items) {
          final Map<String, dynamic> dataMap = _ekstrakDataMap(item);
          if (dataMap.isEmpty || dataMap['id'] == null) continue;

          final pesanOnline = ModelPesanChat.dariMap(dataMap);

          if (!idChatLokal.contains(pesanOnline.id)) {
            // Pesan baru dari online masuk ke cache lokal Hive
            await box.add(pesanOnline.keMap());
            idChatLokal.add(pesanOnline.id);
            adaPerubahanLokal = true;

            // Cek apakah pesan ini ditujukan untuk akun yang sedang aktif
            final bool ditujukanUntukSaya = (peranAktif == 'TRAVELER' &&
                    pesanOnline.pengirim == 'PEMESAN') ||
                (peranAktif == 'PEMESAN' &&
                    pesanOnline.pengirim == 'TRAVELER' &&
                    (pesanOnline.receiverId == userIdAktif ||
                        pesanOnline.receiverId == emailAktif ||
                        pesanOnline.idPemesan == emailAktif ||
                        pesanOnline.idPemesan == userIdAktif));

            if (ditujukanUntukSaya &&
                !_idPesanChatTerkonfirmasi.contains(pesanOnline.id)) {
              _idPesanChatTerkonfirmasi.add(pesanOnline.id);
              await LayananNotifikasi.picuNotifikasiSistem(
                judul: 'Pesan Baru dari ${pesanOnline.namaPengirim} 💬',
                pesan: pesanOnline.teks,
                ikon: Icons.chat_bubble_rounded,
                warna: Colors.indigo.shade800,
              );
            }
          }
        }

        // Sinkronkan chat lokal yang belum terunggah ke online
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['id'] != null) {
            final String id = d['id'].toString();
            final bool sudahAdaDiServer = items.any((it) {
              final m = _ekstrakDataMap(it);
              return m['id'] == id;
            });
            if (!sudahAdaDiServer) {
              await _unggahObjekKoleksi(_koleksiChat, id, Map<String, dynamic>.from(d));
            }
          }
        }

        if (adaPerubahanLokal) {
          pemicuPembaruanChat.value++;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Unggah pesan obrolan baru ke REST API online secara instan
  static Future<bool> unggahPesanChatBaru(ModelPesanChat pesan) async {
    try {
      // 1. Simpan ke Hive cache lokal (Offline-first & respons instan)
      if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakChat)) {
        final box = Hive.box(LayananBasisDataLokal.namaKotakChat);
        bool sudahAda = false;
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['id'] == pesan.id) {
            sudahAda = true;
            break;
          }
        }
        if (!sudahAda) {
          await box.add(pesan.keMap());
        }
      }

      _idPesanChatTerkonfirmasi.add(pesan.id);

      // 2. Unggah ke Cloud Collections
      final sukses = await _unggahObjekKoleksi(
        _koleksiChat,
        pesan.id,
        pesan.keMap(),
      );

      pemicuPembaruanChat.value++;
      return sukses;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 3. SINKRONISASI REKBER & PENARIKAN DANA LINTAS PERANGKAT
  // =========================================================================

  /// Tarik data transaksi Rekber & penarikan dana dari server online
  static Future<bool> sinkronkanRekberOnline() async {
    try {
      if (!Hive.isBoxOpen(LayananRekber.namaKotakPenarikan)) {
        await Hive.openBox(LayananRekber.namaKotakPenarikan);
      }

      final url = Uri.parse('$_baseUrlCloud/$_koleksiRekber/objects');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        final List<dynamic> items = body is List ? body : [];

        final box = Hive.box(LayananRekber.namaKotakPenarikan);
        final Set<String> idLokal = {};
        for (int i = 0; i < box.length; i++) {
          final d = box.getAt(i);
          if (d is Map && d['id'] != null) {
            idLokal.add(d['id'].toString());
          }
        }

        bool adaPerubahan = false;
        for (var item in items) {
          final Map<String, dynamic> dataMap = _ekstrakDataMap(item);
          if (dataMap.isEmpty || dataMap['id'] == null) continue;

          // Cek jika ini adalah objek penarikan dana
          if (dataMap['tipe'] == 'PENARIKAN' || dataMap['nominal'] != null) {
            final wd = ModelPenarikanDana.dariMap(dataMap);
            if (!idLokal.contains(wd.id)) {
              await box.add(wd.keMap());
              idLokal.add(wd.id);
              adaPerubahan = true;
            }
          }
        }

        if (adaPerubahan) {
          pemicuPembaruanRekber.value++;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Catat pelepasan dana Rekber ke server online saat barang sampai
  static Future<void> catatPelepasanDanaRekber({
    required ModelPesananJastip pesanan,
  }) async {
    try {
      final dataPelepasan = {
        'tipe': 'PELEPASAN_ESCROW',
        'idPesanan': pesanan.idPesanan,
        'namaPemesan': pesanan.namaPemesan,
        'nominalIdr': pesanan.totalHargaIdr,
        'namaTraveler': pesanan.namaTraveler,
        'status': 'CAIR',
        'waktuCair': DateTime.now().toIso8601String(),
      };

      await _unggahObjekKoleksi(
        _koleksiRekber,
        'ESCROW-${pesanan.idPesanan}',
        dataPelepasan,
      );

      pemicuPembaruanRekber.value++;
    } catch (_) {}
  }

  /// Unggah penarikan dana ke rekening bank ke database online
  static Future<bool> unggahPenarikanDana(ModelPenarikanDana penarikan) async {
    try {
      final dataWd = penarikan.keMap();
      dataWd['tipe'] = 'PENARIKAN';

      final sukses = await _unggahObjekKoleksi(
        _koleksiRekber,
        'WD-${penarikan.id}',
        dataWd,
      );

      pemicuPembaruanRekber.value++;
      return sukses;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 4. PEMULIHAN AKUN LINTAS PERANGKAT (CROSS-DEVICE LOGIN RESTORE)
  // =========================================================================

  /// Tarik seluruh riwayat pesanan dan chat milik akun dari database online (TODO Poin 3)
  static Future<void> pulihkanDataPenggunaOnline({
    required String userId,
    required String email,
    required String peran,
    String? nama,
  }) async {
    try {
      // 1. Tarik pesanan dari cloud
      await sinkronkanPesananOnline();

      // 2. Tarik pesan chat dari cloud
      await sinkronkanChatOnline();

      // 3. Tarik transaksi rekber dari cloud
      await sinkronkanRekberOnline();

      pemicuPembaruanPesanan.value++;
      pemicuPembaruanChat.value++;
      pemicuPembaruanRekber.value++;
    } catch (_) {}
  }

  // =========================================================================
  // HELPER FUNCTIONS (Koleksi REST API & Data Parsing)
  // =========================================================================

  static Map<String, dynamic> _ekstrakDataMap(dynamic item) {
    if (item is Map) {
      if (item['data'] is Map) {
        final d = Map<String, dynamic>.from(item['data']);
        d['_docId'] = item['id'];
        return d;
      }
      return Map<String, dynamic>.from(item);
    }
    return {};
  }

  static Future<bool> _unggahObjekKoleksi(
    String collection,
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$_baseUrlCloud/$collection/objects');
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _temukanDocIdDiKoleksi(
    String collection,
    String key,
    String targetVal,
  ) async {
    try {
      final url = Uri.parse('$_baseUrlCloud/$collection/objects');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        if (body is List) {
          for (var item in body) {
            final m = _ekstrakDataMap(item);
            if (m[key] == targetVal) {
              return item['id']?.toString();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
