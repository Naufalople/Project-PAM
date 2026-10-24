import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_transaksi_rekber.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_blockchain.dart';
import 'layanan_firebase.dart';
import 'layanan_sinkronisasi_online.dart';

/// Layanan Rekening Bersama (Rekber / Escrow) JastipGo
/// Menggantikan sistem blockchain lama untuk menjamin keamanan transaksi:
/// 1. Saat Pemesan membayar, uang DITAHAN di Rekber (Escrow) dan DILARANG ditarik oleh Traveler.
/// 2. Saldo yang ditahan ditampilkan di dashboard Traveler sebagai "Saldo Rekber (Tertahan)".
/// 3. Dana baru resmi cair / berpindah ke "Saldo Aktif" Traveler HANYA jika Pemesan
///    sudah mengonfirmasi barang diterima (status pesanan = "Sudah Diterima" / tahapStatus >= 6).
class LayananRekber {
  static const String namaKotakPenarikan = 'kotak_penarikan_rekber';
  static const String namaKotakDompetPemesan = 'kotak_dompet_pemesan';
  static const String namaKotakRiwayatRefund = 'kotak_riwayat_refund_pemesan';

  /// Inisialisasi kotak database penarikan dana dan dompet pemesan jika belum dibuka
  static Future<void> inisialisasi() async {
    if (!Hive.isBoxOpen(namaKotakPenarikan)) {
      await Hive.openBox(namaKotakPenarikan);
    }
    if (!Hive.isBoxOpen(namaKotakDompetPemesan)) {
      await Hive.openBox(namaKotakDompetPemesan);
    }
    if (!Hive.isBoxOpen(namaKotakRiwayatRefund)) {
      await Hive.openBox(namaKotakRiwayatRefund);
    }
  }

  /// Menghitung total Saldo Rekber (Dana Tertahan di Escrow)
  /// Dana dari pesanan yang tahapStatus >= 1 dan < 6 (belum diselesaikan)
  /// Pesanan yang dibatalkan (tahapStatus == 0) dikembalikan utuh ke Pemesan dan TIDAK tertahan di Rekber
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

      // Pesanan yang aktif di Rekber HANYA tahapStatus 1 s/d 5 (status 0 = Dibatalkan & di-refund)
      if (pesanan.tahapStatus >= 1 && pesanan.tahapStatus < 6) {
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
  /// sekaligus mencatat blok transaksi baru ke dalam Rantai Blok (Blockchain Sederhana)
  static Future<void> catatPembayaranRekber({
    required String idPesanan,
    required String namaPemesan,
    required int nominalIdr,
    required String namaTraveler,
    List<String>? daftarBarang,
    String? negaraAsal,
  }) async {
    await inisialisasi();
    debugPrint(
      'REKBER LOG: Pesanan #$idPesanan sebesar Rp ${_formatRupiah(nominalIdr)} dari $namaPemesan resmi DITAHAN di Rekber Escrow untuk Traveler $namaTraveler.',
    );
    try {
      await LayananBlockchain.catatTransaksiBaru(
        idPesanan: idPesanan,
        namaPembeli: namaPemesan,
        totalHargaIdr: nominalIdr,
        daftarBarang: daftarBarang ?? [idPesanan],
        negaraAsal: negaraAsal ?? 'Internasional',
      );
    } catch (_) {}
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

  // =========================================================================
  // SISTEM AUTO-REFUND REKBER KE DOMPET PEMESAN (TODO_MANAJEMEN_PESANAN.txt)
  // =========================================================================

  /// Mengambil total saldo dompet (hasil pengembalian / refund dana Rekber) milik Pemesan
  static int ambilSaldoDompetPemesan({String? userId, String? email}) {
    try {
      if (!Hive.isBoxOpen(namaKotakDompetPemesan)) return 0;
      final box = Hive.box(namaKotakDompetPemesan);
      if (box.isEmpty) return 0;

      if (userId != null && userId.isNotEmpty) {
        final val = box.get(userId);
        if (val is num) return val.toInt();
        if (val is Map) return (val['saldo'] as num?)?.toInt() ?? 0;
      }
      if (email != null && email.isNotEmpty) {
        final val = box.get(email);
        if (val is num) return val.toInt();
        if (val is Map) return (val['saldo'] as num?)?.toInt() ?? 0;
      }

      // Fallback: jika key '1' tersedia
      final val1 = box.get('1');
      if (val1 is num) return val1.toInt();
      if (val1 is Map) return (val1['saldo'] as num?)?.toInt() ?? 0;

      // Fallback: ambil saldo pertama yang ada di box
      final firstVal = box.values.firstOrNull;
      if (firstVal is num) return firstVal.toInt();
      if (firstVal is Map) return (firstVal['saldo'] as num?)?.toInt() ?? 0;

      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Menambah saldo dompet Pemesan dan mencatat riwayat transaksi pengembalian dana
  static Future<int> tambahSaldoDompetPemesan({
    required String userId,
    required String email,
    required int nominal,
    required String keterangan,
    required String idPesanan,
  }) async {
    await inisialisasi();
    final box = Hive.box(namaKotakDompetPemesan);
    final key = userId.isNotEmpty ? userId : email;
    final int saldoLama = ambilSaldoDompetPemesan(userId: userId, email: email);
    final int saldoBaru = saldoLama + nominal;

    await box.put(key, {
      'userId': userId,
      'email': email,
      'saldo': saldoBaru,
      'waktuUpdate': DateTime.now().toIso8601String(),
    });

    // Catat ke riwayat transaksi refund
    if (Hive.isBoxOpen(namaKotakRiwayatRefund)) {
      final boxRiwayat = Hive.box(namaKotakRiwayatRefund);
      await boxRiwayat.add({
        'idRefund': 'RF-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        'idPesanan': idPesanan,
        'userId': userId,
        'email': email,
        'nominal': nominal,
        'keterangan': keterangan,
        'alasan': keterangan,
        'tanggal': DateTime.now().toIso8601String(),
        'status': 'SELESAI_100_PERSEN',
      });
    }

    return saldoBaru;
  }

  /// Mengambil seluruh riwayat transaksi pengembalian dana (refund) untuk akun Pemesan
  static List<Map<String, dynamic>> ambilRiwayatRefundPemesan({String? userId, String? email}) {
    try {
      if (!Hive.isBoxOpen(namaKotakRiwayatRefund)) return [];
      final boxRiwayat = Hive.box(namaKotakRiwayatRefund);
      final List<Map<String, dynamic>> list = [];

      for (int i = 0; i < boxRiwayat.length; i++) {
        final d = boxRiwayat.getAt(i);
        if (d != null && d is Map) {
          final m = Map<String, dynamic>.from(d);
          final u = m['userId']?.toString() ?? '';
          final e = m['email']?.toString() ?? '';
          if (userId != null && userId.isNotEmpty && u.isNotEmpty && u != userId) {
            continue;
          }
          if (email != null && email.isNotEmpty && e.isNotEmpty && e != email) {
            continue;
          }
          list.add(m);
        }
      }

      list.sort((a, b) {
        final tA = DateTime.tryParse(a['tanggal']?.toString() ?? '') ?? DateTime.now();
        final tB = DateTime.tryParse(b['tanggal']?.toString() ?? '') ?? DateTime.now();
        return tB.compareTo(tA);
      });

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Fungsi Auto-Refund otomatis dari Rekber ke Dompet Pemesan saat pesanan dibatalkan (Barang Kosong)
  /// Mengembalikan 100% uang pesanan yang tertahan di Rekber ke saldo dompet Pemesan
  static Future<bool> refundDanaKePemesan({
    required ModelPesananJastip pesanan,
    String alasan = 'Barang Tidak Tersedia di Luar Negeri',
  }) async {
    await inisialisasi();
    final nominalRefund = pesanan.totalHargaIdr;
    final userId = pesanan.userId ?? '1';
    final email = pesanan.emailPemesan ?? 'pemesan@jastipgo.com';

    // 1. Tambahkan saldo utuh 100% ke dompet akun pemesan
    await tambahSaldoDompetPemesan(
      userId: userId,
      email: email,
      nominal: nominalRefund,
      keterangan: 'Auto-Refund 100% Rekber: $alasan (#${pesanan.idPesanan})',
      idPesanan: pesanan.idPesanan,
    );

    debugPrint(
      'AUTO-REFUND REKBER BERHASIL: Uang sebesar Rp ${_formatRupiah(nominalRefund)} dari pesanan #${pesanan.idPesanan} telah DIKEMBALIKAN 100% dari Rekber ke Dompet Pemesan ($email).',
    );

    // 2. Sinkronisasikan perubahan pembatalan dan refund ke Firebase Database secara real-time
    await LayananFirebase.batalkanPesananDanRefund(
      pesanan: pesanan,
      alasan: alasan,
    );

    // 3. Picu notifikasi UI
    LayananSinkronisasiOnline.pemicuPembaruanRekber.value++;
    LayananSinkronisasiOnline.pemicuPembaruanPesanan.value++;

    return true;
  }

  /// Helper format Rupiah
  static String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
