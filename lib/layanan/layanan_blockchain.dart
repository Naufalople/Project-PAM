import '../model/model_blok_transaksi.dart';
import 'layanan_basisdata_lokal.dart';

// Layanan Rantai Blok (Blockchain Sederhana): Bukti Transaksi & Sertifikat Keaslian
class LayananBlockchain {
  // Inisialisasi Genesis Block (Blok Awal) jika rantai masih kosong
  static Future<void> inisialisasiBlockchain() async {
    final List<ModelBlokTransaksi> rantai = LayananBasisDataLokal.ambilRantaiBlockchain();
    if (rantai.isEmpty) {
      final ModelBlokTransaksi blokGenesis = ModelBlokTransaksi(
        indeks: 0,
        waktuStempel: DateTime.now().toIso8601String(),
        dataTransaksi: {
          'idPesanan': 'GENESIS-000',
          'deskripsi': 'Blok Awal Sistem Ledger Keaslian JastipGo',
          'status': 'GENESIS_BLOCK',
        },
        hashSebelumnya: '0000000000000000000000000000000000000000000000000000000000000000',
        hash: ModelBlokTransaksi.hitungHash(
          indeks: 0,
          waktuStempel: DateTime.now().toIso8601String(),
          dataTransaksi: {'pesan': 'Genesis Block'},
          hashSebelumnya: '0',
        ),
      );
      await LayananBasisDataLokal.simpanBlokKeBlockchain(blokGenesis);
    }
  }

  // Tambahkan Blok Transaksi Baru ke dalam Blockchain (Pencatatan Pembayaran)
  static Future<ModelBlokTransaksi> catatTransaksiBaru({
    required String idPesanan,
    required String namaPembeli,
    required int totalHargaIdr,
    required List<String> daftarBarang,
    required String negaraAsal,
  }) async {
    await inisialisasiBlockchain();
    final List<ModelBlokTransaksi> rantai = LayananBasisDataLokal.ambilRantaiBlockchain();
    final ModelBlokTransaksi blokTerakhir = rantai.last;

    final int indeksBaru = blokTerakhir.indeks + 1;
    final Map<String, dynamic> dataPayload = {
      'idPesanan': idPesanan,
      'namaPembeli': namaPembeli,
      'totalHargaIdr': totalHargaIdr,
      'daftarBarang': daftarBarang,
      'negaraAsal': negaraAsal,
      'statusPembayaran': 'LUNAS_TERVERIFIKASI',
      'keaslianStruk': '100% ORIGINAL STORE GUARANTEED',
    };

    final ModelBlokTransaksi blokBaru = ModelBlokTransaksi.buatBlokBaru(
      indeks: indeksBaru,
      dataTransaksi: dataPayload,
      hashSebelumnya: blokTerakhir.hash,
    );

    await LayananBasisDataLokal.simpanBlokKeBlockchain(blokBaru);
    return blokBaru;
  }

  // Verifikasi Validitas dan Integritas Rantai Blok (Mendeteksi Manipulasi Data)
  static bool verifikasiIntegritasBlockchain() {
    final List<ModelBlokTransaksi> rantai = LayananBasisDataLokal.ambilRantaiBlockchain();
    if (rantai.length <= 1) return true;

    for (int i = 1; i < rantai.length; i++) {
      final ModelBlokTransaksi blokSaatIni = rantai[i];
      final ModelBlokTransaksi blokSebelumnya = rantai[i - 1];

      // 1. Cek apakah hashSebelumnya cocok dengan hash blok sebelumnya
      if (blokSaatIni.hashSebelumnya != blokSebelumnya.hash) {
        return false; // Rantai rusak / terputus!
      }

      // 2. Hitung ulang hash blok saat ini untuk memastikan data tidak pernah diubah
      final String hashHitungUlang = ModelBlokTransaksi.hitungHash(
        indeks: blokSaatIni.indeks,
        waktuStempel: blokSaatIni.waktuStempel,
        dataTransaksi: blokSaatIni.dataTransaksi,
        hashSebelumnya: blokSaatIni.hashSebelumnya,
      );

      if (blokSaatIni.hash != hashHitungUlang) {
        return false; // Data di dalam blok telah dimanipulasi!
      }
    }

    return true; // Rantai 100% valid dan asli
  }
}
