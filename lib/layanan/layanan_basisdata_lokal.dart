import 'package:hive_flutter/hive_flutter.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';

// Layanan Basis Data Lokal Menggunakan Hive (NoSQL)
class LayananBasisDataLokal {
  static const String namaKotakKeranjang = 'kotak_keranjang';
  static const String namaKotakBlockchain = 'kotak_blockchain';

  // Inisialisasi Hive saat aplikasi pertama kali dijalankan
  static Future<void> inisialisasi() async {
    await Hive.initFlutter();
    await Hive.openBox(namaKotakKeranjang);
    await Hive.openBox(namaKotakBlockchain);
  }

  // ==========================================
  // FITUR KERANJANG BELANJA TITIPAN (CRUD HIVE)
  // ==========================================

  // 1. Ambil Semua Item Keranjang
  static List<ModelKeranjang> ambilSemuaKeranjang() {
    final box = Hive.box(namaKotakKeranjang);
    final List<ModelKeranjang> daftar = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        daftar.add(ModelKeranjang.dariMap(data));
      }
    }
    return daftar;
  }

  // 2. Tambah Barang ke Keranjang
  static Future<void> tambahKeKeranjang(ModelKeranjang itemBaru) async {
    final box = Hive.box(namaKotakKeranjang);
    // Cek apakah barang sudah ada di keranjang, jika ya tambahkan jumlahnya
    bool sudahAda = false;
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map && data['idBarang'] == itemBaru.idBarang) {
        final itemLama = ModelKeranjang.dariMap(data);
        itemLama.jumlah += itemBaru.jumlah;
        await box.putAt(i, itemLama.keMap());
        sudahAda = true;
        break;
      }
    }

    if (!sudahAda) {
      await box.add(itemBaru.keMap());
    }
  }

  // 3. Update Jumlah Item Keranjang
  static Future<void> ubahJumlahItem(int indeks, int jumlahBaru) async {
    final box = Hive.box(namaKotakKeranjang);
    if (indeks >= 0 && indeks < box.length) {
      if (jumlahBaru <= 0) {
        await box.deleteAt(indeks);
      } else {
        final data = box.getAt(indeks);
        if (data != null && data is Map) {
          final item = ModelKeranjang.dariMap(data);
          item.jumlah = jumlahBaru;
          await box.putAt(indeks, item.keMap());
        }
      }
    }
  }

  // 4. Hapus Item dari Keranjang
  static Future<void> hapusDariKeranjang(int indeks) async {
    final box = Hive.box(namaKotakKeranjang);
    if (indeks >= 0 && indeks < box.length) {
      await box.deleteAt(indeks);
    }
  }

  // 5. Kosongkan Keranjang Belanja
  static Future<void> kosongkanKeranjang() async {
    final box = Hive.box(namaKotakKeranjang);
    await box.clear();
  }

  // Hitung total harga seluruh keranjang dalam IDR
  static int hitungTotalHargaKeranjang() {
    final items = ambilSemuaKeranjang();
    int total = 0;
    for (var item in items) {
      total += item.totalHargaIdr;
    }
    return total;
  }

  // ==========================================
  // FITUR BUKTI TRANSAKSI BLOCKCHAIN (HIVE)
  // ==========================================

  // Ambil semua blok transaksi tersimpan
  static List<ModelBlokTransaksi> ambilRantaiBlockchain() {
    final box = Hive.box(namaKotakBlockchain);
    final List<ModelBlokTransaksi> rantai = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        rantai.add(ModelBlokTransaksi.dariMap(data));
      }
    }
    return rantai;
  }

  // Simpan blok transaksi baru ke dalam Hive
  static Future<void> simpanBlokKeBlockchain(ModelBlokTransaksi blok) async {
    final box = Hive.box(namaKotakBlockchain);
    await box.add(blok.keMap());
  }
}
