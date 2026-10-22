import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_transaksi_rekber.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_sinkronisasi_online.dart';

/// Layanan Rekening Bersama (Rekber / Escrow) JastipGo
/// Menggantikan sistem blockchain lama untuk menjamin keamanan transaksi:
/// 1. Saat Pemesan membayar, uang DITAHAN di Rekber (Escrow) dan DILARANG ditarik oleh Traveler.
/// 2. Saldo yang ditahan ditampilkan di dashboard Traveler sebagai "Saldo Rekber (Tertahan)".
/// 3. Dana baru resmi cair / berpindah ke "Saldo Aktif" Traveler HANYA jika Pemesan
///    sudah mengonfirmasi barang diterima (status pesanan = "Sudah Diterima" / tahapStatus >= 6).
class LayananRekber {
  static const String namaKotakPenarikan = 'kotak_penarikan_rekber';

  /// Inisialisasi kotak database penarikan dana jika belum dibuka
  static Future<void> inisialisasi() async {
    if (!Hive.isBoxOpen(namaKotakPenarikan)) {
      await Hive.openBox(namaKotakPenarikan);
    }
  }

  /// Menghitung total Saldo Rekber (Dana Tertahan di Escrow)
  /// Dana dari pesanan yang tahapStatus < 6 (belum diselesaikan / dikonfirmasi pemesan)
  static int hitungSaldoTertahanRekber({String? namaTraveler}) {
    final semuaPesanan = LayananBasisDataLokal.ambilSemuaPesanan();
    int totalTertahan = 0;

    for (var pesanan in semuaPesanan) {
      if (namaTraveler != null && namaTraveler.isNotEmpty) {
        final target = namaTraveler.toLowerCase().trim();
        final travelerPesanan = pesanan.namaTraveler.toLowerCase().trim();
        if (!travelerPesanan.contains(target) && !target.contains(travelerPesanan)) {
          continue;
        }
      }

      // Pesanan yang belum selesai (tahapStatus < 6) masih ditahan di Rekber
      if (pesanan.tahapStatus < 6) {
        totalTertahan += pesanan.totalHargaIdr;
      }
    }

    return totalTertahan;
  }

  /// Menghitung total Saldo Aktif Traveler yang sudah siap ditarik / dicairkan
  /// Dana dari pesanan yang tahapStatus >= 6 (Sudah Diterima oleh pemesan)
  /// dikurangi dana yang sudah berhasil ditarik sebelumnya
  static int hitungSaldoAktifTraveler({String? namaTraveler}) {
    final semuaPesanan = LayananBasisDataLokal.ambilSemuaPesanan();
    int totalCair = 0;

    for (var pesanan in semuaPesanan) {
      if (namaTraveler != null && namaTraveler.isNotEmpty) {
        final target = namaTraveler.toLowerCase().trim();
        final travelerPesanan = pesanan.namaTraveler.toLowerCase().trim();
        if (!travelerPesanan.contains(target) && !target.contains(travelerPesanan)) {
          continue;
        }
      }

      // Pesanan yang sudah selesai (tahapStatus >= 6) telah dilepas dari Rekber
      if (pesanan.tahapStatus >= 6) {
        totalCair += pesanan.totalHargaIdr;
      }
    }

    final totalDitarik = hitungTotalPenarikan(namaTraveler: namaTraveler);
    final sisa = totalCair - totalDitarik;
    return sisa > 0 ? sisa : 0;
  }

  /// Menghitung total penarikan dana yang pernah dilakukan Traveler
  static int hitungTotalPenarikan({String? namaTraveler}) {
    final riwayat = ambilRiwayatPenarikan(namaTraveler: namaTraveler);
    int total = 0;
    for (var r in riwayat) {
      if (r.status == 'BERHASIL') {
        total += r.jumlahIdr;
      }
    }
    return total;
  }

  /// Mengambil seluruh riwayat penarikan dana ke rekening bank
  static List<ModelPenarikanDana> ambilRiwayatPenarikan({String? namaTraveler}) {
    try {
      if (!Hive.isBoxOpen(namaKotakPenarikan)) return [];
      final box = Hive.box(namaKotakPenarikan);
      final List<ModelPenarikanDana> hasil = [];

      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i);
        if (data != null && data is Map) {
          final penarikan = ModelPenarikanDana.dariMap(Map<String, dynamic>.from(data));
          if (namaTraveler != null && namaTraveler.isNotEmpty) {
            final t = penarikan.namaTraveler?.toLowerCase().trim() ?? '';
            final target = namaTraveler.toLowerCase().trim();
            if (t.isNotEmpty && !t.contains(target) && !target.contains(t)) {
              continue;
            }
          }
          hasil.add(penarikan);
        }
      }

      hasil.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      return hasil;
    } catch (_) {
      return [];
    }
  }

  /// Eksekusi Penarikan Dana Saldo Aktif ke Rekening Bank Traveler
  /// DENGAN VALIDASI KETAT: Dilarang keras menarik dana yang masih berstatus DITAHAN REKBER!
  static Future<HasilPenarikanDana> tarikDanaKeRekening({
    required int jumlahTarik,
    required String namaBank,
    required String nomorRekening,
    required String namaPemilikRekening,
    String? namaTraveler,
  }) async {
    await inisialisasi();

    final int saldoTertahan = hitungSaldoTertahanRekber(namaTraveler: namaTraveler);
    final int saldoAktif = hitungSaldoAktifTraveler(namaTraveler: namaTraveler);

    if (jumlahTarik <= 0) {
      return HasilPenarikanDana(
        berhasil: false,
        pesan: 'Jumlah penarikan harus lebih dari Rp 0.',
        saldoTertahan: saldoTertahan,
        saldoAktif: saldoAktif,
      );
    }

    // ATURAN REKBER UTAMA: Uang tertahan DILARANG untuk ditarik / dicairkan!
    if (saldoAktif < jumlahTarik) {
      if (saldoTertahan > 0) {
        return HasilPenarikanDana(
          berhasil: false,
          pesan: 'PENARIKAN DITOLAK!\n\n'
              'Dana sebesar Rp ${_formatRupiah(saldoTertahan)} saat ini masih berstatus DITAHAN REKBER (Escrow Locked). '
              'Traveler DILARANG mencairkan dana ini sampai Pemesan mengonfirmasi bahwa produk telah sampai dan status pesanan berubah menjadi "Sudah Diterima".',
          saldoTertahan: saldoTertahan,
          saldoAktif: saldoAktif,
        );
      } else {
        return HasilPenarikanDana(
          berhasil: false,
          pesan: 'Saldo aktif Anda (Rp ${_formatRupiah(saldoAktif)}) tidak mencukupi untuk melakukan penarikan sebesar Rp ${_formatRupiah(jumlahTarik)}.',
          saldoTertahan: saldoTertahan,
          saldoAktif: saldoAktif,
        );
      }
    }

    // Jika saldo aktif mencukupi, proses pencairan dana ke rekening
    final dataPenarikan = ModelPenarikanDana(
      id: 'WD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
      tanggal: DateTime.now(),
      jumlahIdr: jumlahTarik,
      namaBank: namaBank,
      nomorRekening: nomorRekening,
      namaPemilik: namaPemilikRekening,
      status: 'BERHASIL',
      namaTraveler: namaTraveler,
    );

    final box = Hive.box(namaKotakPenarikan);
    await box.add(dataPenarikan.keMap());
    await LayananSinkronisasiOnline.unggahPenarikanDana(dataPenarikan);

    final sisaAktif = saldoAktif - jumlahTarik;
    return HasilPenarikanDana(
      berhasil: true,
      pesan: 'Penarikan dana sebesar Rp ${_formatRupiah(jumlahTarik)} berhasil diproses! '
          'Dana telah ditransfer ke rekening $namaBank ($nomorRekening a.n. $namaPemilikRekening).',
      saldoTertahan: saldoTertahan,
      saldoAktif: sisaAktif,
    );
  }

  /// Mencatat pembayaran pesanan baru masuk ke sistem Rekber (Escrow)
  static Future<void> catatPembayaranRekber({
    required String idPesanan,
    required String namaPemesan,
    required int nominalIdr,
    required String namaTraveler,
  }) async {
    await inisialisasi();
    debugPrint(
      'REKBER LOG: Pesanan #$idPesanan sebesar Rp ${_formatRupiah(nominalIdr)} dari $namaPemesan resmi DITAHAN di Rekber Escrow untuk Traveler $namaTraveler.',
    );
  }

  /// Pelepasan Dana (Release Fund):
  /// Dipanggil saat pemesan mengonfirmasi barang diterima (tahapStatus = 6)
  static Future<void> lepaskanDanaKeTraveler({
    required ModelPesananJastip pesanan,
  }) async {
    await inisialisasi();
    debugPrint(
      'REKBER LOG: Pemesan mengonfirmasi penerimaan pesanan #${pesanan.idPesanan}. Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} BERPINDAH dari Rekber Tertahan ke Saldo Aktif Traveler.',
    );
    await LayananSinkronisasiOnline.catatPelepasanDanaRekber(pesanan: pesanan);
  }

  /// Helper format Rupiah
  static String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
