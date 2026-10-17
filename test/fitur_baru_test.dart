import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_pam/layanan/layanan_basisdata_lokal.dart';
import 'package:project_pam/layanan/layanan_ai.dart';
import 'package:project_pam/model/model_keranjang.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
    await Hive.openBox(LayananBasisDataLokal.namaKotakKeranjang);
    await Hive.openBox(LayananBasisDataLokal.namaKotakPesanan);
    await Hive.openBox(LayananBasisDataLokal.namaKotakVoucher);
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

  group('Uji Fitur 1: AI Lens Scanner', () {
    test('AI Scanner mendeteksi produk dan menghasilkan estimasi harga', () async {
      final hasil = await LayananAi.pindaiGambarKamera(namaFileAtauPath: 'tokyo_banana.jpg');
      expect(hasil.namaProduk, isNotEmpty);
      expect(hasil.estimasiHargaIdr, greaterThan(0));
      expect(hasil.tingkatKeyakinan, inInclusiveRange(0.0, 1.0));
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
}
