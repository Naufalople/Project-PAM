import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_pam/layanan/layanan_basisdata_lokal.dart';
import 'package:project_pam/layanan/layanan_ai.dart';
import 'package:project_pam/layanan/layanan_api.dart';
import 'package:project_pam/model/model_keranjang.dart';
import 'package:project_pam/model/model_barang_jastip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
    await Hive.openBox(LayananBasisDataLokal.namaKotakKeranjang);
    await Hive.openBox(LayananBasisDataLokal.namaKotakPesanan);
    await Hive.openBox(LayananBasisDataLokal.namaKotakVoucher);
    await Hive.openBox(LayananBasisDataLokal.namaKotakKatalog);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box(LayananBasisDataLokal.namaKotakKeranjang).clear();
    await Hive.box(LayananBasisDataLokal.namaKotakVoucher).clear();
  });

  group('Uji Fitur 1: AI Recommendation Engine Berbasis Data Pembelian', () {
    test('AI Engine menghitung total kuantitas pembelian dummy dan peringkat terlaris', () async {
      final totalBeli = LayananAi.hitungTotalPembelianPerBarang();
      expect(totalBeli, isNotEmpty);
      expect(totalBeli[1], greaterThan(20)); // Tokyo Banana memiliki banyak transaksi dummy

      final matriksCoBeli = LayananAi.hitungMatriksPembelianBersamaan();
      expect(matriksCoBeli, isNotEmpty);
      expect(LayananAi.ambilFrekuensiDibeliBersama(1, 2), greaterThan(0)); // Tokyo Banana & Hada Labo sering dibeli bersama
    });
  });

  group('Uji Fitur 2: Keranjang Belanja Reaktif', () {
    test('Menambahkan barang ke keranjang lokal Hive', () async {
      final item = ModelKeranjang(
        idBarang: 101,
        namaBarang: 'Tokyo Banana Classic Box',
        fotoUrl: 'https://example.com/tokyo.jpg',
        negara: 'Jepang 🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 1200.0,
        hargaIdr: 135000,
        jumlah: 2,
      );

      await LayananBasisDataLokal.tambahKeKeranjang(item);
      final list = LayananBasisDataLokal.ambilSemuaKeranjang();
      expect(list.length, equals(1));
      expect(list.first.namaBarang, equals('Tokyo Banana Classic Box'));
      expect(list.first.totalHargaIdr, equals(270000));
    });
  });

  group('Uji Fitur 5: Promo & Voucher Hilang Setelah Dipakai', () {
    test('Voucher dapat disimpan, diambil, dan langsung terhapus setelah digunakan', () async {
      final voucher = ModelVoucher(
        kode: 'SHAKE50',
        judul: 'Diskon Shake Rp 50.000',
        potonganIdr: 50000,
        deskripsi: 'Potongan Rp 50.000 dari guncangan hoki Shake Promo',
      );

      // 1. Simpan voucher hasil goyang / kuis
      await LayananBasisDataLokal.simpanVoucher(voucher);
      var daftarVoucher = LayananBasisDataLokal.ambilSemuaVoucher();
      expect(daftarVoucher.any((v) => v.kode == 'SHAKE50'), isTrue);

      // 2. Gunakan voucher saat checkout
      await LayananBasisDataLokal.gunakanVoucher('SHAKE50');

      // 3. Pastikan voucher sudah hilang dan tidak bisa dipakai ulang
      daftarVoucher = LayananBasisDataLokal.ambilSemuaVoucher();
      expect(daftarVoucher.any((v) => v.kode == 'SHAKE50'), isFalse);
    });
  });

  group('Uji Fitur TODO_FIX Poin 5: AI Recommendation Engine', () {
    test('Algoritma Content-Based merekomendasikan produk berdasarkan kemiripan negara & kategori', () async {
      final barangAcuan = ModelBarangJastip(
        id: 1,
        namaBarang: 'Tokyo Banana Classic Box',
        kategori: 'Kuliner',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 1200.0,
        estimasiHargaIdr: 135000,
        fotoUrl: 'https://example.com/tokyo.jpg',
        deskripsi: 'Kue pisang',
        namaToko: 'Tokyo Station',
        batasWaktuPo: '2 Hari',
        rating: 4.9,
        jumlahPeminat: 100,
      );

      final katalog = [
        barangAcuan,
        ModelBarangJastip(
          id: 2,
          namaBarang: 'Hada Labo Lotion',
          kategori: 'Skincare',
          negara: 'Jepang',
          benderaNegara: '🇯🇵',
          kodeMataUang: 'JPY',
          hargaAsli: 990.0,
          estimasiHargaIdr: 110000,
          fotoUrl: 'https://example.com/hadalabo.jpg',
          deskripsi: 'Lotion pelembab',
          namaToko: 'Don Quijote',
          batasWaktuPo: '2 Hari',
          rating: 4.8,
          jumlahPeminat: 90,
        ),
        ModelBarangJastip(
          id: 3,
          namaBarang: 'Harrods Bag',
          kategori: 'Fashion',
          negara: 'London (UK)',
          benderaNegara: '🇬🇧',
          kodeMataUang: 'GBP',
          hargaAsli: 35.0,
          estimasiHargaIdr: 720000,
          fotoUrl: 'https://example.com/harrods.jpg',
          deskripsi: 'Tas belanja',
          namaToko: 'Harrods',
          batasWaktuPo: 'Hari Ini',
          rating: 4.9,
          jumlahPeminat: 50,
        ),
      ];

      final rekomendasi = LayananAi.rekomendasikanBarang(
        barangAcuan: barangAcuan,
        semuaBarang: katalog,
      );

      expect(rekomendasi, isNotEmpty);
      expect(rekomendasi.first.barang.id, equals(2)); // Hada Labo dari Jepang (skor kemiripan tertinggi)
      expect(rekomendasi.first.skorKemiripan, greaterThan(0.4));
      expect(rekomendasi.first.alasanRekomendasi, contains('Jepang'));
    });
  });

  group('Uji Fitur TODO_FIX Poin 3: Migrasi Produk Dinamis', () {
    test('Katalog produk dimuat secara dinamis dari API / database Hive', () async {
      final produk = await LayananApi.ambilSemuaBarang();
      expect(produk, isNotEmpty);
      expect(produk.length, greaterThanOrEqualTo(10));
      expect(produk.any((p) => p.negara.contains('Jepang')), isTrue);
    });
  });
}
