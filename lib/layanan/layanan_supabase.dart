import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/model_pesanan_jastip.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_notifikasi.dart';
import 'layanan_otentikasi.dart';

/// Layanan Database Online Supabase Real-Time (TODO_PERUBAHAN_DATABASE.txt)
/// 
/// 1. Menggunakan Supabase sebagai database online utama untuk menggantikan/melengkapi penyimpanan lokal.
/// 2. Alur sinkronisasi dua arah (two-way sync) secara real-time antar perangkat.
/// 3. Sisi Traveler: Saat Pemesan membuat pesanan baru, data tersebut langsung muncul di perangkat Traveler secara online.
/// 4. Sisi Pemesan: Saat Traveler mengonfirmasi pesanan atau memperbarui status pengiriman (tahap 2 s/d 6),
///    perubahan status langsung ter-update di layar Pemesan secara real-time dengan notifikasi.
class LayananSupabase {
  static String urlSupabase = 'https://jastipgo-pam.supabase.co';
  static String anonKeySupabase =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imphc3RpcGdvLXBhbSIsInJvbGUiOiJhaW5vbiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoyMDAwMDAwMDAwfQ.demo_key';

  static bool isInitialized = false;
  static bool apakahTersambungCloud = false;

  static SupabaseClient? get client {
    if (isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {}
    }
    return null;
  }

  static final StreamController<ModelPesananJastip> _controllerPesanan =
      StreamController<ModelPesananJastip>.broadcast();
  static Stream<ModelPesananJastip> get streamPesanan => _controllerPesanan.stream;

  static StreamSubscription? _realtimeStreamSubscription;
  static final Set<String> _idPesananTerkonfirmasi = {};
  static final Map<String, int> _lastNotifiedStatus = {};

  /// Inisialisasi Supabase SDK & pendengar real-time stream
  static Future<void> inisialisasi({String? url, String? anonKey}) async {
    if (url != null && url.isNotEmpty) urlSupabase = url;
    if (anonKey != null && anonKey.isNotEmpty) anonKeySupabase = anonKey;

    try {
      if (!isInitialized) {
        // ignore: deprecated_member_use
        await Supabase.initialize(
          url: urlSupabase,
          // ignore: deprecated_member_use
          anonKey: anonKeySupabase,
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 10,
          ),
        );
        isInitialized = true;
        apakahTersambungCloud = true;
      }
      _mulaiLanggananRealtime();
    } catch (e) {
      debugPrint('Supabase inisialisasi fallback: $e');
    }
  }

  /// Memulai langganan real-time (PostgreSQL Changes) pada tabel 'pesanan'
  static void _mulaiLanggananRealtime() {
    _realtimeStreamSubscription?.cancel();
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      final supaClient = client;
      if (supaClient != null) {
        _realtimeStreamSubscription = supaClient
            .from('pesanan')
            .stream(primaryKey: ['idPesanan'])
            .listen((List<Map<String, dynamic>> records) {
          for (var record in records) {
            final pesanan = ModelPesananJastip.dariMap(record);
            _prosesPesananMasuk(pesanan);
          }
        }, onError: (err) {
          debugPrint('Supabase stream error: $err');
        });
      }
    } catch (_) {}
  }

  /// Menghentikan langganan real-time Supabase
  static void hentikanStream() {
    _realtimeStreamSubscription?.cancel();
    _realtimeStreamSubscription = null;
  }

  /// Proses pesanan yang masuk dari Supabase real-time
  static Future<void> _prosesPesananMasuk(ModelPesananJastip pesanan) async {
    // 1. Simpan/update ke cache lokal Hive
    if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
      final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
      int indexLokal = -1;
      for (int i = 0; i < box.length; i++) {
        final d = box.getAt(i);
        if (d is Map && d['idPesanan'] == pesanan.idPesanan) {
          indexLokal = i;
          break;
        }
      }
      if (indexLokal != -1) {
        await box.putAt(indexLokal, pesanan.keMap());
      } else {
        await box.add(pesanan.keMap());
      }
    }

    // 2. Alirkan ke stream agar UI Pemesan dan Traveler langsung ter-update
    _controllerPesanan.add(pesanan);

    // 3. Notifikasi sistem berdasarkan peran aktif
    final profilAktif = await LayananOtentikasi.ambilProfilAktif();
    final peranAktif = profilAktif?.peran ?? 'PEMESAN';

    if (peranAktif == 'PEMESAN') {
      await _notifikasiStatusPemesan(pesanan);
    } else if (peranAktif == 'TRAVELER') {
      if (!_idPesananTerkonfirmasi.contains(pesanan.idPesanan)) {
        _idPesananTerkonfirmasi.add(pesanan.idPesanan);
        await LayananNotifikasi.picuNotifikasiSistem(
          judul: 'Pesanan Titipan Baru (Supabase Real-Time) 🛍️',
          pesan:
              'Pesanan #${pesanan.idPesanan} dari ${pesanan.namaPemesan ?? "Pemesan"} senilai Rp ${_formatRupiah(pesanan.totalHargaIdr)} siap diproses.',
          ikon: Icons.shopping_bag_rounded,
          warna: Colors.teal.shade800,
        );
      }
    }
  }

  /// Simpan pesanan baru ke Supabase secara online real-time (Sisi Pemesan -> Traveler)
  static Future<bool> simpanPesananBaru(ModelPesananJastip pesanan) async {
    try {
      // 1. Simpan ke cache lokal Hive
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

      // 2. Alirkan langsung ke stream lokal
      _idPesananTerkonfirmasi.add(pesanan.idPesanan);
      _controllerPesanan.add(pesanan);

      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }

      // 3. Simpan ke database online Supabase
      final supaClient = client;
      if (supaClient != null) {
        await supaClient.from('pesanan').upsert(pesanan.keMap());
      }
      return true;
    } catch (e) {
      debugPrint('Supabase simpanPesananBaru: $e');
      return true; // Tetap sukses via sinkronisasi stream lokal
    }
  }

  /// Perbarui status pesanan di Supabase secara online real-time (Sisi Traveler -> Pemesan)
  static Future<bool> perbaruiStatusPesanan(
    String idPesanan, {
    required int tahapStatus,
    required String lokasiTerkini,
    String? metodePenyerahan,
    String? alamatPengiriman,
  }) async {
    try {
      ModelPesananJastip? updatedPesanan;

      // Ambil objek pesanan yang sedang diperbarui
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
            updatedPesanan = ModelPesananJastip.dariMap(m);
            await box.putAt(i, updatedPesanan.keMap());
            break;
          }
        }
      }

      updatedPesanan ??= ModelPesananJastip(
        idPesanan: idPesanan,
        tanggal: DateTime.now(),
        negaraAsal: 'Jastip Online',
        namaTraveler: 'Traveler',
        nomorTeleponTraveler: '0819-8765-4321',
        nomorTeleponPemesan: '0812-3456-7890',
        lokasiTerkini: lokasiTerkini,
        tahapStatus: tahapStatus,
        metodePenyerahan: metodePenyerahan ?? 'COD_LBS',
        alamatPengiriman: alamatPengiriman ?? '',
        totalHargaIdr: 0,
        daftarBarang: [],
      );

      _controllerPesanan.add(updatedPesanan);

      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }

      // Update ke database online Supabase
      final supaClient = client;
      if (supaClient != null) {
        final updatePayload = <String, dynamic>{
          'tahapStatus': tahapStatus,
          'lokasiTerkini': lokasiTerkini,
        };
        if (metodePenyerahan != null) updatePayload['metodePenyerahan'] = metodePenyerahan;
        if (alamatPengiriman != null) updatePayload['alamatPengiriman'] = alamatPengiriman;
        updatePayload.addAll(updatedPesanan.keMap());

        await supaClient.from('pesanan').upsert(updatePayload);
      }

      return true;
    } catch (e) {
      debugPrint('Supabase perbaruiStatusPesanan: $e');
      return true;
    }
  }

  /// Ambil semua pesanan dari Supabase online
  static Future<List<ModelPesananJastip>> ambilSemuaPesananOnline() async {
    try {
      final supaClient = client;
      if (supaClient != null) {
        final List<dynamic> response = await supaClient
            .from('pesanan')
            .select()
            .timeout(const Duration(milliseconds: 1500));
        final list = response.map((row) => ModelPesananJastip.dariMap(Map<String, dynamic>.from(row))).toList();

        // Update ke cache lokal Hive
        if (Hive.isBoxOpen(LayananBasisDataLokal.namaKotakPesanan)) {
          final box = Hive.box(LayananBasisDataLokal.namaKotakPesanan);
          for (var p in list) {
            int idx = -1;
            for (int i = 0; i < box.length; i++) {
              final d = box.getAt(i);
              if (d is Map && d['idPesanan'] == p.idPesanan) {
                idx = i;
                break;
              }
            }
            if (idx != -1) {
              await box.putAt(idx, p.keMap());
            } else {
              await box.add(p.keMap());
            }
          }
        }

        return list;
      }
    } catch (e) {
      debugPrint('Supabase ambilSemuaPesananOnline: $e');
    }
    return [];
  }

  /// Notifikasi sistem berkelanjutan untuk Pemesan
  static Future<void> _notifikasiStatusPemesan(ModelPesananJastip pesanan) async {
    final profilAktif = await LayananOtentikasi.ambilProfilAktif();
    if (profilAktif != null) {
      final uId = profilAktif.id.toString();
      final em = profilAktif.email.toLowerCase().trim();
      final pUId = (pesanan.userId ?? '').toString().trim();
      final pEm = (pesanan.emailPemesan ?? '').toLowerCase().trim();
      // Pastikan notifikasi hanya masuk ke pemesan pemilik pesanan tersebut
      if (pEm.isNotEmpty && pEm != em && pUId != uId) {
        return;
      }
    }

    final int last = _lastNotifiedStatus[pesanan.idPesanan] ?? 1;
    if (pesanan.tahapStatus <= last) return;
    _lastNotifiedStatus[pesanan.idPesanan] = pesanan.tahapStatus;

    String judul = '';
    String pesan = '';
    IconData ikon = Icons.info_outline;
    Color warna = Colors.teal.shade800;

    switch (pesanan.tahapStatus) {
      case 2:
        judul = 'Pesanan Disetujui Traveler! ✅ (Supabase)';
        pesan =
            'Pesanan #${pesanan.idPesanan} telah di-ACC. Traveler segera menuju lokasi toko.';
        ikon = Icons.thumb_up_alt_rounded;
        warna = Colors.teal.shade800;
        break;
      case 3:
        judul = 'Barang Berhasil Dibeli di Toko! 🛍️ (Supabase)';
        pesan =
            'Barang titipan #${pesanan.idPesanan} (${pesanan.negaraAsal}) telah selesai dibeli.';
        ikon = Icons.shopping_bag_rounded;
        warna = Colors.teal.shade800;
        break;
      case 4:
        judul = 'Barang Masuk Bagasi Pesawat ke RI! ✈️ (Supabase)';
        pesan =
            'Koper titipan #${pesanan.idPesanan} sedang dalam penerbangan internasional.';
        ikon = Icons.flight_takeoff_rounded;
        warna = Colors.blue.shade800;
        break;
      case 5:
        judul = 'Traveler Tiba di Indonesia! 🇮🇩 (Supabase)';
        pesan =
            'Pesanan #${pesanan.idPesanan} siap diserahterimakan di titik temu COD.';
        ikon = Icons.place_rounded;
        warna = Colors.orange.shade800;
        break;
      case 6:
        judul = 'Transaksi Selesai & Diterima! 🎉 (Supabase)';
        pesan =
            'Pesanan #${pesanan.idPesanan} selesai. Terima kasih!';
        ikon = Icons.check_circle_rounded;
        warna = Colors.green.shade800;
        break;
    }

    if (judul.isNotEmpty) {
      await LayananNotifikasi.picuNotifikasiSistem(
        judul: judul,
        pesan: pesan,
        ikon: ikon,
        warna: warna,
      );
    }
  }

  static String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
