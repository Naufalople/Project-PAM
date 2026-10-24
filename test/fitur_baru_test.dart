import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pam/layanan/layanan_basisdata_lokal.dart';
import 'package:project_pam/layanan/layanan_otentikasi.dart';
import 'package:project_pam/layanan/layanan_ai.dart';
import 'package:project_pam/layanan/layanan_api.dart';
import 'package:project_pam/model/model_keranjang.dart';
import 'package:project_pam/model/model_barang_jastip.dart';
import 'package:project_pam/model/model_pesanan_jastip.dart';
import 'package:project_pam/model/model_pesan_chat.dart';
import 'package:project_pam/model/model_pengguna.dart';
import 'package:project_pam/layanan/layanan_sensor.dart';
import 'package:project_pam/layanan/layanan_rekber.dart';
import 'package:project_pam/layanan/layanan_notifikasi.dart';
import 'package:project_pam/layanan/layanan_sinkronisasi_online.dart';
import 'package:project_pam/layanan/layanan_supabase.dart';
import 'package:project_pam/layanan/layanan_firebase.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:project_pam/tampilan/halaman_peta_lokasi.dart';
import 'package:project_pam/tampilan/halaman_profil.dart';
import 'package:project_pam/tampilan/halaman_fitur_cerdas.dart';
import 'package:project_pam/tampilan/halaman_dompet_rekber.dart';
import 'package:project_pam/tampilan/halaman_status_pesanan.dart';
import 'package:project_pam/tampilan/halaman_kelola_pesanan_traveler.dart';

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
    await Hive.openBox(LayananBasisDataLokal.namaKotakPengguna);
    await Hive.openBox(LayananBasisDataLokal.namaKotakChat);
    await Hive.openBox(LayananRekber.namaKotakPenarikan);
    await Hive.openBox(LayananRekber.namaKotakDompetPemesan);
    await Hive.openBox(LayananRekber.namaKotakRiwayatRefund);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box(LayananBasisDataLokal.namaKotakKeranjang).clear();
    await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();
    await Hive.box(LayananBasisDataLokal.namaKotakVoucher).clear();
    await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();
    await Hive.box(LayananRekber.namaKotakPenarikan).clear();
    await Hive.box(LayananRekber.namaKotakDompetPemesan).clear();
    await Hive.box(LayananRekber.namaKotakRiwayatRefund).clear();
  });

  tearDown(() async {
    LayananSinkronisasiOnline.hentikanStreamRealtime();
    LayananSinkronisasiOnline.hentikanSinkronisasiOtomatis();
    LayananSupabase.hentikanStream();
    LayananFirebase.hentikanStream();
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

  group('Uji Fitur 5: Promo & Voucher Hilang Setelah Dipakai & Isolasi Berdasarkan Akun (TODO_PERBAIKAN_UI_PROMO)', () {
    test('Voucher dapat disimpan, diambil, dan langsung terhapus setelah digunakan', () async {
      final voucher = ModelVoucher(
        kode: 'SHAKE50',
        judul: 'Diskon Shake Rp 50.000',
        potonganIdr: 50000,
        deskripsi: 'Potongan Rp 50.000 dari guncangan hoki Shake Promo',
        userId: '1',
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

    test('Isolasi Promo: Kueri database hanya memuat voucher milik akun (userId) yang sedang login', () async {
      // Akun 1 menyimpan voucher
      final voucherAkun1 = ModelVoucher(
        kode: 'USER1_KUPON',
        judul: 'Kupon Spesial Akun 1',
        potonganIdr: 30000,
        deskripsi: 'Khusus Akun 1',
        userId: '1',
      );
      await LayananBasisDataLokal.simpanVoucher(voucherAkun1, userId: '1');

      // Akun 2 menyimpan voucher
      final voucherAkun2 = ModelVoucher(
        kode: 'USER2_KUPON',
        judul: 'Kupon Spesial Akun 2',
        potonganIdr: 70000,
        deskripsi: 'Khusus Akun 2',
        userId: '2',
      );
      await LayananBasisDataLokal.simpanVoucher(voucherAkun2, userId: '2');

      // Kueri saat Akun 1 login (hanya melihat kupon milik Akun 1)
      final listAkun1 = LayananBasisDataLokal.ambilSemuaVoucher(userId: '1');
      expect(listAkun1.any((v) => v.kode == 'USER1_KUPON'), isTrue);
      expect(listAkun1.any((v) => v.kode == 'USER2_KUPON'), isFalse);

      // Kueri saat Akun 2 login (hanya melihat kupon milik Akun 2)
      final listAkun2 = LayananBasisDataLokal.ambilSemuaVoucher(userId: '2');
      expect(listAkun2.any((v) => v.kode == 'USER2_KUPON'), isTrue);
      expect(listAkun2.any((v) => v.kode == 'USER1_KUPON'), isFalse);
    });

    test('Isolasi Penggunaan: Pemakaian voucher oleh Akun 1 tidak menghapus voucher Akun 2 dengan kode yang sama', () async {
      // Kedua akun memiliki promo dengan nama kode yang sama (misal hasil shake)
      final v1 = ModelVoucher(
        kode: 'SHAKE_SHARED',
        judul: 'Diskon Shake Akun 1',
        potonganIdr: 50000,
        deskripsi: 'Guncangan Akun 1',
        userId: '10',
      );
      final v2 = ModelVoucher(
        kode: 'SHAKE_SHARED',
        judul: 'Diskon Shake Akun 2',
        potonganIdr: 50000,
        deskripsi: 'Guncangan Akun 2',
        userId: '20',
      );

      await LayananBasisDataLokal.simpanVoucher(v1, userId: '10');
      await LayananBasisDataLokal.simpanVoucher(v2, userId: '20');

      // Akun 10 menggunakan voucher SHAKE_SHARED
      final berhasilPakai = await LayananBasisDataLokal.gunakanVoucher('SHAKE_SHARED', userId: '10');
      expect(berhasilPakai, isTrue);

      // Voucher milik Akun 10 telah terhapus
      final kuponAkun10 = LayananBasisDataLokal.ambilSemuaVoucher(userId: '10');
      expect(kuponAkun10.any((v) => v.kode == 'SHAKE_SHARED'), isFalse);

      // Voucher milik Akun 20 TETAP ADA dan utuh!
      final kuponAkun20 = LayananBasisDataLokal.ambilSemuaVoucher(userId: '20');
      expect(kuponAkun20.any((v) => v.kode == 'SHAKE_SHARED'), isTrue);
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

  group('Uji Validasi Registrasi: Validasi Duplikasi Email & Kebebasan Username (TODO_VALIDASI_AKUN)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Hive.box(LayananBasisDataLokal.namaKotakPengguna).clear();
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final f = File('$userProfile\\jastipgo_cadangan_akun.json');
        if (f.existsSync()) {
          try { f.deleteSync(); } catch (_) {}
        }
      }
      await LayananOtentikasi.inisialisasiAkun();
    });

    test('1. periksaDuplikasiAkun menolak jika email sudah ada di database (meskipun nama/username berbeda)', () async {
      final duplikat = await LayananOtentikasi.periksaDuplikasiAkun(
        email: 'pemesan@jastipgo.com', // Email bawaan yang sudah ada
        namaAtauUsername: 'User Baru Banget', // Nama baru
      );

      expect(duplikat, isNotNull);
      expect(duplikat, equals('Email sudah terdaftar, silakan gunakan email lain'));
    });

    test('2. periksaDuplikasiAkun mengizinkan pendaftaran jika email baru meskipun username/nama sama persis dengan akun lain', () async {
      final duplikat = await LayananOtentikasi.periksaDuplikasiAkun(
        email: 'email.baru.bebas@gmail.com', // Email baru
        namaAtauUsername: 'Siti Nurhaliza', // Nama sama persis dengan akun bawaan
      );

      // Harusnya null (diizinkan karena email belum terdaftar)
      expect(duplikat, isNull);
    });

    test('3. periksaDuplikasiAkun mengizinkan akun yang benar-benar baru', () async {
      final duplikat = await LayananOtentikasi.periksaDuplikasiAkun(
        email: 'pengguna.unik.baru@example.com',
        namaAtauUsername: 'Pengguna Unik 2026',
      );

      expect(duplikat, isNull);
    });

    test('4. prosesDaftarAkunBaru menolak pendaftaran jika email sudah terdaftar di database', () async {
      final hasil = await LayananOtentikasi.prosesDaftarAkunBaru(
        nama: 'Nama Siapa Saja',
        email: 'pemesan@jastipgo.com', // Email duplikat bawaan
        password: 'password123',
        nomorTelepon: '081299998888',
      );

      expect(hasil.berhasil, isFalse);
      expect(hasil.pesanError, equals('Email sudah terdaftar, silakan gunakan email lain'));
    });

    test('5. prosesDaftarAkunBaru berhasil mendaftarkan akun baru meskipun nama sama persis dengan traveler/user lain', () async {
      final hasil = await LayananOtentikasi.prosesDaftarAkunBaru(
        nama: 'Dimas Pratama', // Nama persis sama dengan traveler bawaan
        email: 'dimas.junior.baru@gmail.com', // Email baru
        password: 'password123',
        nomorTelepon: '081233445566',
      );

      expect(hasil.berhasil, isTrue);
      expect(hasil.pesanError, isNull);

      // Verifikasi tersimpan di database lokal
      final semuaAkun = await LayananOtentikasi.ambilSemuaAkun();
      expect(semuaAkun.any((a) => a.email == 'dimas.junior.baru@gmail.com'), isTrue);

      // Verifikasi jika mencoba mendaftar ulang dengan email yang sama akan ditolak
      final duplikatLagi = await LayananOtentikasi.periksaDuplikasiAkun(
        email: 'dimas.junior.baru@gmail.com',
        namaAtauUsername: 'Nama Lain Lagi',
      );
      expect(duplikatLagi, equals('Email sudah terdaftar, silakan gunakan email lain'));
    });
  });

  group('Uji Fitur Validasi Destinasi Traveler (TODO_VALIDASI_DESTINASI)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();
      await LayananOtentikasi.inisialisasiAkun();
    });

    test('apakahAdaPesananBelumDikirim bernilai false jika belum ada pesanan sama sekali (0 pesanan)', () {
      final ada = LayananBasisDataLokal.apakahAdaPesananBelumDikirim(namaTraveler: 'Dimas Pratama');
      expect(ada, isFalse);

      final belumKirim = LayananBasisDataLokal.ambilPesananBelumDikirimTraveler(namaTraveler: 'Dimas Pratama');
      expect(belumKirim, isEmpty);
    });

    test('apakahAdaPesananBelumDikirim bernilai true jika ada pesanan dengan tahapStatus < 4', () async {
      final pesananAktif = ModelPesananJastip(
        idPesanan: 'PO-TEST-001',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama (Traveler Terverifikasi)',
        lokasiTerkini: 'Toko Don Quijote Tokyo',
        tahapStatus: 3, // Sudah dibeli di toko tapi belum dikirim ke Indonesia (< 4)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 250000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Tokyo Banana Classic Box',
            fotoUrl: 'https://example.com/tokyo.jpg',
            negara: 'Jepang',
            namaToko: 'Tokyo Station',
            jumlah: 1,
            hargaIdr: 250000,
          ),
        ],
      );

      await LayananBasisDataLokal.tambahPesanan(pesananAktif);

      final ada = LayananBasisDataLokal.apakahAdaPesananBelumDikirim(namaTraveler: 'Dimas Pratama');
      expect(ada, isTrue);

      final belumKirim = LayananBasisDataLokal.ambilPesananBelumDikirimTraveler(namaTraveler: 'Dimas Pratama');
      expect(belumKirim.length, equals(1));
      expect(belumKirim.first.idPesanan, equals('PO-TEST-001'));
      expect(belumKirim.first.tahapStatus, lessThan(4));
    });

    test('simpanDestinasiAktifTraveler menolak (return false) jika masih ada pesanan belum dikirim ke Indonesia', () async {
      final pesananAktif = ModelPesananJastip(
        idPesanan: 'PO-TEST-002',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Tokyo Akihabara',
        tahapStatus: 2, // Traveler Menuju Toko (< 4)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 150000,
        daftarBarang: [],
      );

      await LayananBasisDataLokal.tambahPesanan(pesananAktif);

      // Traveler mencoba mengubah negara dari Jepang ke London
      final berhasilUbah = await LayananOtentikasi.simpanDestinasiAktifTraveler(
        'London (UK)',
        namaTraveler: 'Dimas Pratama',
      );

      expect(berhasilUbah, isFalse);

      // Pastikan destinasi di SharedPreferences tidak berubah ke London
      final destinasiTersimpan = await LayananOtentikasi.ambilDestinasiAktifTraveler();
      expect(destinasiTersimpan, isNot(equals('London (UK)')));
    });

    test('simpanDestinasiAktifTraveler diizinkan (return true) jika pesanan sudah mencapai status Dikirim ke Indonesia (tahapStatus >= 4)', () async {
      final pesananDikirim = ModelPesananJastip(
        idPesanan: 'PO-TEST-003',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Bagasi Pesawat Menuju Bandara Indonesia ✈️',
        tahapStatus: 4, // Sudah Dikirim ke Indonesia (Penerbangan)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 300000,
        daftarBarang: [],
      );

      await LayananBasisDataLokal.tambahPesanan(pesananDikirim);

      // Pengecekan ada pesanan belum dikirim harus false
      final adaBelumKirim = LayananBasisDataLokal.apakahAdaPesananBelumDikirim(namaTraveler: 'Dimas Pratama');
      expect(adaBelumKirim, isFalse);

      // Traveler sekarang boleh mengubah negara destinasi ke Korea Selatan
      final berhasilUbah = await LayananOtentikasi.simpanDestinasiAktifTraveler(
        'Korea Selatan',
        namaTraveler: 'Dimas Pratama',
      );

      expect(berhasilUbah, isTrue);

      final destinasiTersimpan = await LayananOtentikasi.ambilDestinasiAktifTraveler();
      expect(destinasiTersimpan, equals('Korea Selatan'));
    });
  });

  group('Uji TODO_PERBAIKAN_LANJUTAN Poin 2: Pembatasan Konteks Chatbot AI (Out-of-Scope Fallback)', () {
    test('apakahDalamKonteksJastip mengidentifikasi pertanyaan seputar jastip vs di luar konteks', () {
      // Pertanyaan seputar Jastip
      expect(LayananAi.apakahDalamKonteksJastip('Berapa ongkos titip barang dari Jepang?'), isTrue);
      expect(LayananAi.apakahDalamKonteksJastip('Bagaimana cara kerja pembayaran Rekber Escrow?'), isTrue);
      expect(LayananAi.apakahDalamKonteksJastip('Kapan pesanan PO saya sampai di Indonesia?'), isTrue);
      expect(LayananAi.apakahDalamKonteksJastip('Apakah bisa ambil sendiri COD di bandara?'), isTrue);

      // Pertanyaan di luar konteks Jastip
      expect(LayananAi.apakahDalamKonteksJastip('Siapa presiden pertama Amerika Serikat?'), isFalse);
      expect(LayananAi.apakahDalamKonteksJastip('Bagaimana rumus luas lingkaran dan trigonometri?'), isFalse);
      expect(LayananAi.apakahDalamKonteksJastip('Buatkan resep memasak nasi goreng spesial'), isFalse);
    });

    test('tanyaAsistenJastip mengembalikan respons baku penolakan jika pertanyaan di luar konteks', () async {
      const pertanyaanLuarKonteks = 'Ceritakan lelucon lucu tentang programmer';
      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaanLuarKonteks);

      expect(jawaban, equals(LayananAi.pesanPenolakanDiLuarKonteks));
      expect(jawaban, contains('Maaf, saya hanya bisa menjawab seputar aplikasi Jastip ini. Jika di luar itu, saya tidak memiliki kemampuan untuk menjawabnya.'));
    });

    test('tanyaAsistenJastip menjawab secara informatif jika pertanyaan relevan dengan jastip', () async {
      const pertanyaanJastip = 'Bagaimana sistem keamanan pembayaran Rekber Escrow di JastipGo?';
      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaanJastip);

      expect(jawaban, isNot(equals(LayananAi.pesanPenolakanDiLuarKonteks)));
      expect(jawaban.toLowerCase(), contains('rekber'));
    });
  });

  group('Uji TODO_PERBAIKAN_LANJUTAN Poin 3: Sinkronisasi & Persistensi Chat (senderId & receiverId)', () {
    test('Pesan chat menyimpan senderId & receiverId dan dapat dimuat oleh Traveler yang dituju', () async {
      final pesan = ModelPesanChat(
        id: 'CHAT-001',
        senderId: '1', // ID Pemesan (Siti Nurhaliza)
        receiverId: '2', // ID Traveler (Dimas Pratama)
        idPemesan: '1',
        namaPemesan: 'Siti Nurhaliza',
        pengirim: 'PEMESAN',
        namaPengirim: 'Siti Nurhaliza',
        teks: 'Halo mas Dimas, tolong carikan Tokyo Banana ya!',
        waktu: DateTime.now(),
      );

      // 1. Simpan ke database Hive
      await LayananBasisDataLokal.kirimPesanChat(pesan);

      // 2. Ambil pesan khusus untuk Traveler dengan ID '2'
      final pesanTraveler = LayananBasisDataLokal.ambilPesanChatUntukTraveler(travelerId: '2');
      expect(pesanTraveler, isNotEmpty);
      expect(pesanTraveler.first.senderId, equals('1'));
      expect(pesanTraveler.first.receiverId, equals('2'));
      expect(pesanTraveler.first.teks, contains('Tokyo Banana'));

      // 3. Ambil pesan khusus untuk Pemesan dengan ID '1'
      final pesanPemesan = LayananBasisDataLokal.ambilPesanChatUntukPemesan('1');
      expect(pesanPemesan, isNotEmpty);
      expect(pesanPemesan.first.senderId, equals('1'));

      // 4. Balasan dari Traveler
      final balasan = ModelPesanChat(
        id: 'CHAT-002',
        senderId: '2',
        receiverId: '1',
        idPemesan: '1',
        namaPemesan: 'Siti Nurhaliza',
        pengirim: 'TRAVELER',
        namaPengirim: 'Dimas Pratama',
        teks: 'Siap mbak Siti, besok saya belikan di Tokyo Station!',
        waktu: DateTime.now(),
      );
      await LayananBasisDataLokal.kirimPesanChat(balasan);

      final threadTraveler = LayananBasisDataLokal.ambilPesanChatUntukTraveler(travelerId: '2');
      expect(threadTraveler.length, equals(2));
      expect(threadTraveler.last.senderId, equals('2'));
      expect(threadTraveler.last.receiverId, equals('1'));
    });
  });

  group('Uji TODO_PERBAIKAN_LANJUTAN Poin 5: Pemisahan Status Pesanan (Belum vs Sudah Diterima) & Konfirmasi Penerimaan', () {
    test('Pesanan terpisah dengan benar antara Belum Diterima dan Sudah Diterima', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();

      final pesananBerjalan = ModelPesananJastip(
        idPesanan: 'PO-TEST-ACTIVE',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Penerbangan ke Indonesia ✈️',
        tahapStatus: 4, // Belum Diterima (< 6)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 450000,
        daftarBarang: [],
      );

      final pesananSelesai = ModelPesananJastip(
        idPesanan: 'PO-TEST-DONE',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now().subtract(const Duration(days: 3)),
        negaraAsal: 'Korea Selatan 🇰🇷',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Telah Diterima Pemesan di Alamat Tujuan (Transaksi Selesai) 🎉',
        tahapStatus: 6, // Sudah Diterima (>= 6)
        metodePenyerahan: 'KURIR',
        totalHargaIdr: 320000,
        daftarBarang: [],
      );

      await LayananBasisDataLokal.tambahPesanan(pesananBerjalan);
      await LayananBasisDataLokal.tambahPesanan(pesananSelesai);

      // Verifikasi getter model
      expect(pesananBerjalan.apakahBelumDiterima, isTrue);
      expect(pesananBerjalan.apakahSudahDiterima, isFalse);
      expect(pesananSelesai.apakahBelumDiterima, isFalse);
      expect(pesananSelesai.apakahSudahDiterima, isTrue);

      // Verifikasi daftar filter dari basis data
      final listBelum = LayananBasisDataLokal.ambilPesananBelumDiterima(userId: '1');
      final listSudah = LayananBasisDataLokal.ambilPesananSudahDiterima(userId: '1');

      expect(listBelum.length, equals(1));
      expect(listBelum.first.idPesanan, equals('PO-TEST-ACTIVE'));

      expect(listSudah.length, equals(1));
      expect(listSudah.first.idPesanan, equals('PO-TEST-DONE'));

      // Lakukan konfirmasi penerimaan pesanan aktif
      await LayananBasisDataLokal.konfirmasiPesananDiterima('PO-TEST-ACTIVE');

      // Setelah dikonfirmasi, otomatis berpindah ke Sudah Diterima
      final listBelumSetelah = LayananBasisDataLokal.ambilPesananBelumDiterima(userId: '1');
      final listSudahSetelah = LayananBasisDataLokal.ambilPesananSudahDiterima(userId: '1');

      expect(listBelumSetelah, isEmpty);
      expect(listSudahSetelah.length, equals(2));
      expect(listSudahSetelah.any((p) => p.idPesanan == 'PO-TEST-ACTIVE'), isTrue);
    });
  });

  group('Uji TODO_PERBAIKAN_UI_MAPS_LLM Poin 2: Perluasan Konteks Chatbot LLM (Membaca Data Katalog)', () {
    test('Chatbot menjawab dengan akurat pertanyaan perbandingan barang termahal atau termurah', () async {
      const pertanyaan = 'Apa barang termahal atau termurah di aplikasi ini?';
      
      // Pastikan pertanyaan dalam konteks
      expect(LayananAi.apakahDalamKonteksJastip(pertanyaan), isTrue);

      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaan);

      expect(jawaban, isNot(equals(LayananAi.pesanPenolakanDiLuarKonteks)));
      expect(jawaban, contains('Barang Termahal di Aplikasi'));
      expect(jawaban, contains('Barang Termurah di Aplikasi'));
      // Barang termahal adalah Jo Malone Cologne / Charles & Keith / Harrods / Gundam
      expect(jawaban, contains('Rp '));
    });

    test('Chatbot menjawab dengan akurat pertanyaan spesifik barang termahal di aplikasi', () async {
      const pertanyaan = 'Barang termahal di aplikasi';
      expect(LayananAi.apakahDalamKonteksJastip(pertanyaan), isTrue);

      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaan);
      expect(jawaban, contains('Barang Termahal'));
      expect(jawaban, contains('Produk dengan Nilai Tertinggi'));
    });

    test('Chatbot menjawab dengan akurat pertanyaan spesifik barang termurah di aplikasi', () async {
      const pertanyaan = 'Barang termurah di aplikasi apa saja?';
      expect(LayananAi.apakahDalamKonteksJastip(pertanyaan), isTrue);

      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaan);
      expect(jawaban, contains('Barang Termurah'));
      expect(jawaban, contains('Produk Paling Hemat'));
    });

    test('Chatbot menyajikan ringkasan katalog saat pengguna menanyakan list katalog produk', () async {
      const pertanyaan = 'Tampilkan katalog produk jastip yang ada di aplikasi';
      expect(LayananAi.apakahDalamKonteksJastip(pertanyaan), isTrue);

      final jawaban = await LayananAi.tanyaAsistenJastip(pertanyaan);
      expect(jawaban, contains('Daftar Ringkasan Katalog Produk'));
      expect(jawaban, contains('Tokyo Banana'));
    });
  });

  group('Uji TODO_PERBAIKAN_FITUR Poin 1: Sinkronisasi Nama Pemesan di Inbox Traveler', () {
    test('ambilDaftarThreadPemesan menampilkan nama asli pemesan dan bukan nama traveler', () async {
      await LayananBasisDataLokal.bersihkanMemoriChat();

      // Simulasi pesan percakapan dari Pemesan "Budi Santoso" ke Traveler "Dimas Pratama"
      final pesanMasuk = ModelPesanChat(
        id: 'msg-test-01',
        teks: 'Halo kak Dimas, titipan Gundam saya apakah sudah dibeli?',
        adalahPengguna: true,
        pengirim: 'PEMESAN',
        namaPengirim: 'Budi Santoso',
        waktu: DateTime.now().subtract(const Duration(minutes: 10)),
        idPemesan: 'budi@gmail.com',
        namaPemesan: 'Budi Santoso',
        userId: '3',
        senderId: '3',
        receiverId: '2',
      );
      await LayananBasisDataLokal.kirimPesanChat(pesanMasuk);

      // Simulasi balasan dari Traveler "Dimas Pratama"
      final pesanBalasan = ModelPesanChat(
        id: 'msg-test-02',
        teks: 'Sudah mas Budi, ini sedang saya antre di Akihabara.',
        adalahPengguna: false,
        pengirim: 'TRAVELER',
        namaPengirim: 'Dimas Pratama',
        waktu: DateTime.now(),
        idPemesan: 'budi@gmail.com',
        namaPemesan: 'Budi Santoso',
        userId: 'budi@gmail.com',
        senderId: '2',
        receiverId: 'budi@gmail.com',
      );
      await LayananBasisDataLokal.kirimPesanChat(pesanBalasan);

      // Traveler memuat daftar thread di inbox
      final threads = LayananBasisDataLokal.ambilDaftarThreadPemesan(
        travelerId: '2',
        emailTraveler: 'dimas@jastipgo.com',
      );

      expect(threads.isNotEmpty, isTrue);
      final threadBudi = threads.firstWhere((t) => t.idPemesan == 'budi@gmail.com');
      // Pastikan nama di inbox traveler adalah "Budi Santoso", BUKAN "Dimas Pratama"
      expect(threadBudi.namaPemesan, equals('Budi Santoso'));
      expect(threadBudi.namaPemesan, isNot(equals('Dimas Pratama')));
      expect(threadBudi.pesanTerakhir, contains('Akihabara'));
    });
  });

  group('Uji TODO_PERBAIKAN_FITUR Poin 2: Peta Interaktif OpenStreetMap (OSM) Titik Temu COD', () {
    test('Koordinat Hub COD dan integrasi jarak LBS akurat', () {
      const latUPN = -7.7602;
      const lngUPN = 110.4089;
      const latMalioboro = -7.7928;
      const lngMalioboro = 110.3658;

      final double jarak = Geolocator.distanceBetween(latUPN, lngUPN, latMalioboro, lngMalioboro);
      final double jarakKm = jarak / 1000.0;

      expect(jarakKm, greaterThan(4.0));
      expect(jarakKm, lessThan(7.0));

      final double bearing = Geolocator.bearingBetween(latUPN, lngUPN, latMalioboro, lngMalioboro);
      expect(bearing, isNotNull);
    });
  });

  group('Uji TODO_PERBAIKAN_FITUR Poin 3: Penggantian Sensor Gyroscope ke Sensor Suara / Voice Search', () {
    test('LayananSensorSuara menyediakan daftar contoh suara pencarian produk', () {
      expect(LayananSensorSuara.daftarContohSuara, isNotEmpty);
      expect(LayananSensorSuara.daftarContohSuara, contains('Tokyo Banana'));
      expect(LayananSensorSuara.daftarContohSuara, contains('Gundam RG'));
    });

    test('Filter barang katalog dengan kata kunci pencarian suara berhasil menemukan produk yang relevan', () async {
      final semuaBarang = await LayananApi.ambilSemuaBarang();
      expect(semuaBarang, isNotEmpty);

      // Uji query suara 1: "Tokyo"
      final hasilTokyo = semuaBarang.where((b) =>
        b.namaBarang.toLowerCase().contains('tokyo') ||
        b.namaToko.toLowerCase().contains('tokyo') ||
        b.negara.toLowerCase().contains('tokyo')
      ).toList();
      expect(hasilTokyo.isNotEmpty, isTrue);

      // Uji query suara 2: "Gundam"
      final hasilGundam = semuaBarang.where((b) =>
        b.namaBarang.toLowerCase().contains('gundam')
      ).toList();
      expect(hasilGundam.isNotEmpty, isTrue);

      // Uji query suara 3: "Tea"
      final hasilTea = semuaBarang.where((b) =>
        b.namaBarang.toLowerCase().contains('tea') ||
        b.kategori.toLowerCase().contains('tea')
      ).toList();
      expect(hasilTea.isNotEmpty, isTrue);
    });
  });

  group('Uji TODO_PERUBAHAN_REKBER: Sistem Keamanan Rekber (Escrow) & Penahanan Dana Traveler', () {
    test('Siklus Lengkap Rekber: Penahanan Dana -> Penolakan Penarikan -> Pelepasan Dana saat Diterima -> Pencairan Saldo Aktif', () async {
      const namaTraveler = 'Dimas Pratama';
      const idPesanan = 'ORD-REKBER-001';

      // 1. Pemesan membuat pesanan & melakukan checkout (masuk ke Rekber)
      await LayananBasisDataLokal.tambahPesanan(ModelPesananJastip(
        idPesanan: idPesanan,
        userId: 'pemesan_1',
        namaPemesan: 'Rafi Ahmad',
        tanggal: DateTime.now(),
        namaTraveler: namaTraveler,
        negaraAsal: 'Jepang 🇯🇵',
        lokasiTerkini: 'Menunggu ACC Traveler',
        tahapStatus: 1, // Pesanan Baru
        metodePenyerahan: 'COD_LBS',
        alamatPengiriman: 'Kampus UPN',
        totalHargaIdr: 200000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Tokyo Banana',
            fotoUrl: 'https://example.com/tb.jpg',
            jumlah: 2,
            hargaIdr: 100000,
            negara: 'Jepang',
            namaToko: 'Donki',
          ),
        ],
      ));

      await LayananRekber.catatPembayaranRekber(
        idPesanan: idPesanan,
        namaPemesan: 'Rafi Ahmad',
        nominalIdr: 200000,
        namaTraveler: namaTraveler,
      );

      // Verifikasi 1: Uang berada di Saldo Tertahan (200.000) dan Saldo Aktif = 0
      final saldoTertahan1 = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: namaTraveler);
      final saldoAktif1 = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: namaTraveler);
      expect(saldoTertahan1, equals(200000));
      expect(saldoAktif1, equals(0));

      // Verifikasi 2: Traveler DILARANG menarik dana saat berstatus Dana Tertahan di Rekber
      final hasilTarikDitolak = await LayananRekber.tarikDanaKeRekening(
        jumlahTarik: 100000,
        namaBank: 'BCA',
        nomorRekening: '1234567890',
        namaPemilikRekening: 'Dimas Pratama',
        namaTraveler: namaTraveler,
      );
      expect(hasilTarikDitolak.berhasil, isFalse);
      expect(hasilTarikDitolak.pesan, contains('DITAHAN REKBER'));
      expect(hasilTarikDitolak.saldoAktif, equals(0));
      expect(hasilTarikDitolak.saldoTertahan, equals(200000));

      // 3. Pemesan mengonfirmasi bahwa produk telah sampai (status = 6 / Sudah Diterima)
      await LayananBasisDataLokal.konfirmasiPesananDiterima(idPesanan);
      final pesananSelesai = LayananBasisDataLokal.ambilSemuaPesanan()
          .firstWhere((p) => p.idPesanan == idPesanan);
      expect(pesananSelesai.tahapStatus, equals(6));

      // Pelepasan dana ke Traveler
      await LayananRekber.lepaskanDanaKeTraveler(pesanan: pesananSelesai);

      // Verifikasi 3: Dana otomatis berpindah ke Saldo Aktif
      final saldoTertahan2 = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: namaTraveler);
      final saldoAktif2 = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: namaTraveler);
      expect(saldoTertahan2, equals(0));
      expect(saldoAktif2, equals(200000));

      // 4. Traveler mencairkan dana dari Saldo Aktif
      final hasilTarikBerhasil = await LayananRekber.tarikDanaKeRekening(
        jumlahTarik: 150000,
        namaBank: 'BCA',
        nomorRekening: '1234567890',
        namaPemilikRekening: 'Dimas Pratama',
        namaTraveler: namaTraveler,
      );
      expect(hasilTarikBerhasil.berhasil, isTrue);
      expect(hasilTarikBerhasil.saldoAktif, equals(50000)); // 200.000 - 150.000

      // Verifikasi 4: Riwayat penarikan tercatat
      final riwayat = LayananRekber.ambilRiwayatPenarikan(namaTraveler: namaTraveler);
      expect(riwayat.length, equals(1));
      expect(riwayat.first.jumlahIdr, equals(150000));
      expect(riwayat.first.namaBank, equals('BCA'));
    });
  });

  group('Uji TODO_NAVIGASI_OSM_GMAPS: LBS Real-Time OSM & Navigasi Eksternal (GMaps)', () {
    test('1. Format URL Navigasi Google Maps Eksternal sesuai standar spesifikasi', () {
      const double userLat = -7.7602;
      const double userLng = 110.4089;
      const double codLat = -7.9029;
      const double codLng = 110.0573;

      final url = HalamanPetaLokasi.buatUrlNavigasiGoogleMaps(
        latUser: userLat,
        lngUser: userLng,
        latCod: codLat,
        lngCod: codLng,
      );

      expect(
        url,
        equals('https://www.google.com/maps/dir/?api=1&origin=-7.7602,110.4089&destination=-7.9029,110.0573'),
      );
      expect(url.startsWith('https://www.google.com/maps/dir/?api=1'), isTrue);
      expect(url.contains('origin=-7.7602,110.4089'), isTrue);
      expect(url.contains('destination=-7.9029,110.0573'), isTrue);
      expect(url.contains('travelmode'), isFalse);
    });

    test('2. Perhitungan jarak lurus LBS via Geolocator.distanceBetween', () {
      const double userLat = -7.7602; // UPN Condongcatur
      const double userLng = 110.4089;
      const double yiaLat = -7.9029; // Bandara YIA
      const double yiaLng = 110.0573;

      final jarakKm = HalamanPetaLokasi.hitungJarakLurusKm(
        latAwal: userLat,
        lngAwal: userLng,
        latTujuan: yiaLat,
        lngTujuan: yiaLng,
      );

      expect(jarakKm, greaterThan(35.0));
      expect(jarakKm, lessThan(50.0));

      final teksJarak = 'Jarak ke titik temu: ${jarakKm.toStringAsFixed(1)} km';
      expect(teksJarak, startsWith('Jarak ke titik temu:'));
      expect(teksJarak, endsWith('km'));
    });

    testWidgets('3. Verifikasi UI: OpenStreetMap, 2 Marker, In-App Routing Polyline, & Navigasi Mandiri', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanPetaLokasi(indeksTitikAwal: 0),
        ),
      );
      await tester.pump();

      // Verifikasi 1: Peta FlutterMap hadir
      expect(find.byType(FlutterMap), findsOneWidget);

      // Verifikasi 2: TileLayer OpenStreetMap menggunakan URL resmi OSM
      final tileLayerFinder = find.byType(TileLayer);
      expect(tileLayerFinder, findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(tileLayerFinder);
      expect(tileLayer.urlTemplate, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));

      // Verifikasi 3: MarkerLayer memiliki 2 marker (Marker A Pengguna & Marker B Titik COD)
      final markerLayerFinder = find.byType(MarkerLayer);
      expect(markerLayerFinder, findsOneWidget);
      final markerLayer = tester.widget<MarkerLayer>(markerLayerFinder);
      expect(markerLayer.markers.length, equals(2));
      expect(markerLayer.markers.any((m) => m.key == const ValueKey('marker_pengguna_lbs')), isTrue);
      expect(markerLayer.markers.any((m) => m.key == const ValueKey('marker_titik_cod')), isTrue);

      // Verifikasi 4: Teks jarak ke titik temu tampil di UI
      expect(find.textContaining('Jarak ke titik temu:'), findsOneWidget);

      // Verifikasi 5: Sesuai TODO_PERUBAHAN_DATABASE.txt, tombol Navigasi Mandiri In-App hadir
      final tombolNavigasi = find.byKey(const ValueKey('tombol_navigasi_in_app'));
      expect(tombolNavigasi, findsOneWidget);
      expect(find.text('Mulai Navigasi Langsung di Aplikasi'), findsOneWidget);

      // Verifikasi 6: Tekan Mulai Navigasi -> PolylineLayer rute OSRM muncul & Banner Navigasi Aktif
      await tester.ensureVisible(tombolNavigasi);
      await tester.tap(tombolNavigasi);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.text('NAVIGASI IN-APP AKTIF 🧭'), findsOneWidget);
      expect(find.text('Hentikan Navigasi'), findsOneWidget);

      // Verifikasi 7: Tekan Hentikan Navigasi -> Mode navigasi berhenti
      await tester.ensureVisible(find.text('Hentikan Navigasi'));
      await tester.tap(find.text('Hentikan Navigasi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Mulai Navigasi Langsung di Aplikasi'), findsOneWidget);
    });
  });

  group('Uji TODO_BATASAN_REKBER: Pembatasan Visibilitas UI Rekber Berdasarkan Role', () {
    testWidgets('1. Sisi Pemesan: Menu Dompet & Saldo Rekber disembunyikan sepenuhnya dari HalamanProfil', (tester) async {
      final profilPemesan = ModelPengguna(
        id: 1,
        nama: 'Siti Nurhaliza',
        email: 'pemesan@jastipgo.com',
        passwordHash: 'hash',
        nomorTelepon: '081234567890',
        fotoProfil: '',
        peran: 'PEMESAN',
        lokasi: 'Yogyakarta',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HalamanProfil(profilOverride: profilPemesan),
        ),
      );
      await tester.pump();

      // Verifikasi 1: Menu Dompet & Saldo Rekber TIDAK MUNCUL untuk Pemesan
      expect(find.text('Dompet & Saldo Rekber Escrow'), findsNothing);

      // Verifikasi 2: Judul Pesanan hanya "Pesanan Saya" tanpa embel-embel Rekber Escrow
      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Pesanan Saya & Rekber Escrow'), findsNothing);
    });

    testWidgets('2. Sisi Traveler: Menu Dompet & Saldo Rekber EKSKLUSIF ditampilkan di HalamanProfil', (tester) async {
      final profilTraveler = ModelPengguna(
        id: 2,
        nama: 'Dimas Pratama',
        email: 'traveler.dimas@jastipgo.com',
        passwordHash: 'hash',
        nomorTelepon: '081234567890',
        fotoProfil: '',
        peran: 'TRAVELER',
        lokasi: 'Tokyo',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HalamanProfil(profilOverride: profilTraveler),
        ),
      );
      await tester.pump();

      // Verifikasi: Menu Dompet & Saldo Rekber MUNCUL khusus untuk Traveler
      expect(find.text('Dompet & Saldo Rekber Escrow'), findsOneWidget);
      expect(find.text('Kelola Pesanan Masuk (Traveler)'), findsOneWidget);
    });

    testWidgets('3. Sisi Pemesan vs Traveler di HalamanFiturCerdas', (tester) async {
      // Akun Pemesan: Tidak boleh ada menu Rekber di Pusat Fitur Cerdas
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanFiturCerdas(
            key: ValueKey('fitur_cerdas_pemesan'),
            peranOverride: 'PEMESAN',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dompet & Saldo Rekber Escrow'), findsNothing);
      expect(find.text('Pelacakan Status Pesanan (Pemesan)'), findsOneWidget);

      // Akun Traveler: Fitur Dompet & Saldo Rekber tersedia
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanFiturCerdas(
            key: ValueKey('fitur_cerdas_traveler'),
            peranOverride: 'TRAVELER',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dompet & Saldo Rekber Escrow'), findsOneWidget);
    });

    testWidgets('4. Proteksi HalamanDompetRekber: Menolak akses akun Pemesan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanDompetRekber(peranOverride: 'PEMESAN'),
        ),
      );
      await tester.pump();

      // Pemesan diblokir dengan tampilan Akses Khusus Traveler
      expect(find.text('Akses Khusus Traveler'), findsOneWidget);
      expect(find.text('Tarik Saldo ke Rekening Bank'), findsNothing);
    });

    testWidgets('5. Akses HalamanDompetRekber: Mengizinkan akun Traveler memantau dan mencairkan saldo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanDompetRekber(peranOverride: 'TRAVELER'),
        ),
      );
      await tester.pump();

      // Traveler dapat mengakses penuh fitur Dompet & Saldo Rekber
      expect(find.text('Akses Khusus Traveler'), findsNothing);
      expect(find.text('Dompet & Saldo Rekber Escrow'), findsOneWidget);
      expect(find.text('Tarik Saldo ke Rekening Bank'), findsOneWidget);
    });

    testWidgets('6. Sisi Pemesan di HalamanStatusPesanan: Bebas dari tombol/menu Saldo Rekber', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanStatusPesanan(),
        ),
      );
      await tester.pump();

      expect(find.text('Pelacakan Status Pesanan'), findsOneWidget);
      expect(find.text('Lihat Status Proteksi Rekber'), findsNothing);
      expect(find.byIcon(Icons.shield_outlined), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('Uji TODO_SINKRONISASI_REALTIME: Sinkronisasi Lintas Perangkat (Non-Firebase), Notifikasi Real-Time, & Pencairan Otomatis Rekber', () {
    test('1. SINKRONISASI DATABASE (NON-FIREBASE): LayananSinkronisasiOnline dapat mengunggah dan menyinkronkan data pesanan dan chat secara online', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();
      await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();

      final pesananUji = ModelPesananJastip(
        idPesanan: 'PO-SYNC-HP1-001',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Toko Don Quijote Tokyo',
        tahapStatus: 1,
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 250000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Hada Labo Gokujyun',
            fotoUrl: '',
            negara: 'Jepang',
            namaToko: 'Don Quijote',
            jumlah: 1,
            hargaIdr: 250000,
          ),
        ],
      );

      // Simpan pesanan lokal & picu sinkronisasi online
      await LayananBasisDataLokal.tambahPesanan(pesananUji);
      await LayananSinkronisasiOnline.sinkronkanPesananOnline();
      final pesananTersimpan = LayananBasisDataLokal.ambilSemuaPesanan();
      expect(pesananTersimpan.length, equals(1));
      expect(pesananTersimpan.first.idPesanan, equals('PO-SYNC-HP1-001'));

      // Kirim pesan chat & verifikasi
      final pesanUji = ModelPesanChat(
        id: 'CHAT-SYNC-001',
        teks: 'Kak Dimas, titipan Hada Labo saya apakah sudah di-ACC?',
        adalahPengguna: true,
        pengirim: 'PEMESAN',
        namaPengirim: 'Siti Nurhaliza',
        waktu: DateTime.now(),
        idPemesan: 'pemesan@jastipgo.com',
        senderId: '1',
        receiverId: '2',
      );

      await LayananBasisDataLokal.kirimPesanChat(pesanUji);
      final chatTersimpan = LayananBasisDataLokal.ambilSemuaPesanChat();
      expect(chatTersimpan.length, equals(1));
      expect(chatTersimpan.first.id, equals('CHAT-SYNC-001'));
    });

    test('2. NOTIFIKASI PESANAN & CHAT MASUK: LayananNotifikasi memicu notifikasi lokal real-time di sistem OS', () async {
      final totalAwal = LayananNotifikasi.ambilSemuaNotifikasi().length;

      // Pemicu notifikasi pesanan masuk
      await LayananNotifikasi.picuNotifikasiSistem(
        judul: 'Pesanan Titipan Baru Masuk! 🛍️',
        pesan: 'Pesanan #PO-SYNC-HP1-001 dari Siti Nurhaliza senilai Rp 250.000 perlu diproses.',
      );

      // Pemicu notifikasi chat masuk
      await LayananNotifikasi.picuNotifikasiSistem(
        judul: 'Pesan Baru dari Siti Nurhaliza 💬',
        pesan: 'Kak Dimas, titipan Hada Labo saya apakah sudah di-ACC?',
      );

      final notifikasiTerbaru = LayananNotifikasi.ambilSemuaNotifikasi();
      expect(notifikasiTerbaru.length, equals(totalAwal + 2));
      expect(notifikasiTerbaru.any((n) => n.judul.contains('Pesanan Titipan Baru Masuk!')), isTrue);
      expect(notifikasiTerbaru.any((n) => n.judul.contains('Pesan Baru dari Siti Nurhaliza')), isTrue);
    });

    test('3. ALUR OTOMATIS PENCAIRAN DANA REKBER: Konfirmasi "Barang Sudah Sampai" mencairkan dana Rekber ke Saldo Aktif Traveler', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();
      await Hive.box(LayananRekber.namaKotakPenarikan).clear();

      final pesananAktif = ModelPesananJastip(
        idPesanan: 'PO-REKBER-AUTO-01',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Siti Nurhaliza',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Tiba di Indonesia',
        tahapStatus: 5, // Belum selesai (masih ditahan Rekber)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 500000,
        daftarBarang: [],
      );
      await LayananBasisDataLokal.tambahPesanan(pesananAktif);

      // Saat tahapStatus = 5: Saldo Tertahan = 500.000, Saldo Aktif = 0
      int tertahanSebelum = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: 'Dimas Pratama');
      int aktifSebelum = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: 'Dimas Pratama');
      expect(tertahanSebelum, equals(500000));
      expect(aktifSebelum, equals(0));

      // Simulasi Pemesan di HP 1 menekan konfirmasi "Barang Sudah Sampai/Diterima"
      await LayananBasisDataLokal.konfirmasiPesananDiterima('PO-REKBER-AUTO-01');
      await LayananRekber.lepaskanDanaKeTraveler(pesanan: pesananAktif);

      // Verifikasi status pesanan lokal & online telah berubah menjadi 6 (Selesai/Diterima)
      final pesananTerbaru = LayananBasisDataLokal.ambilSemuaPesanan().firstWhere((p) => p.idPesanan == 'PO-REKBER-AUTO-01');
      expect(pesananTerbaru.tahapStatus, equals(6));
      expect(pesananTerbaru.apakahSudahDiterima, isTrue);

      // Simulasi Traveler di HP 2 membuka / merefresh dashboard
      int tertahanSetelah = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: 'Dimas Pratama');
      int aktifSetelah = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: 'Dimas Pratama');

      // Saldo Rekber (Tertahan) berkurang menjadi 0, dan Saldo Aktif Traveler bertambah menjadi 500.000!
      expect(tertahanSetelah, equals(0));
      expect(aktifSetelah, equals(500000));

      // Traveler dapat melakukan penarikan saldo aktif ke rekening bank
      final hasilTarik = await LayananRekber.tarikDanaKeRekening(
        jumlahTarik: 500000,
        namaBank: 'BCA',
        nomorRekening: '1234567890',
        namaPemilikRekening: 'Dimas Pratama',
        namaTraveler: 'Dimas Pratama',
      );

      expect(hasilTarik.berhasil, isTrue);
      expect(LayananRekber.hitungSaldoAktifTraveler(namaTraveler: 'Dimas Pratama'), equals(0));
    });
  });

  group('Uji TODO_PERBAIKAN_DATABASE: Migrasi Online Real-Time Non-Firebase, Cache Lokal Offline, & Pemisahan Inbox 1-on-1', () {
    test('1. PEMISAHAN INBOX TRAVELER: 5 Pemesan menghubungi Traveler menghasilkan tepat 5 percakapan pribadi (1-on-1) terpisah', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();
      await Hive.box(LayananBasisDataLokal.namaKotakPengguna).clear();

      // Daftarkan 5 akun pemesan di Hive
      final pemesanList = [
        {'id': 101, 'nama': 'Siti Nurhaliza', 'email': 'siti@jastipgo.com', 'peran': 'PEMESAN'},
        {'id': 102, 'nama': 'Budi Santoso', 'email': 'budi@jastipgo.com', 'peran': 'PEMESAN'},
        {'id': 103, 'nama': 'Andi Wijaya', 'email': 'andi@jastipgo.com', 'peran': 'PEMESAN'},
        {'id': 104, 'nama': 'Dewi Lestari', 'email': 'dewi@jastipgo.com', 'peran': 'PEMESAN'},
        {'id': 105, 'nama': 'Rian Hidayat', 'email': 'rian@jastipgo.com', 'peran': 'PEMESAN'},
      ];

      for (var p in pemesanList) {
        await LayananBasisDataLokal.simpanAkunHive(p);
      }

      // 5 Pemesan masing-masing mengirim pesan ke Traveler (receiverId: '2' / Dimas Pratama)
      for (int i = 0; i < pemesanList.length; i++) {
        final p = pemesanList[i];
        final pesan = ModelPesanChat(
          id: 'MSG-TEST-${i + 1}-01',
          pengirim: 'PEMESAN',
          teks: 'Halo Traveler Dimas, saya ${p['nama']} ingin titip barang.',
          waktu: DateTime.now().add(Duration(minutes: i)),
          idPesanan: 'PO-TEST-00$i',
          namaPengirim: p['nama'] as String,
          senderId: p['id'].toString(),
          receiverId: '2',
          idPemesan: p['email'] as String,
          userId: p['id'].toString(),
          namaPemesan: p['nama'] as String,
        );
        await LayananBasisDataLokal.kirimPesanChat(pesan);

        // Traveler membalas setiap pemesan secara individual
        final balasanTraveler = ModelPesanChat(
          id: 'MSG-TEST-${i + 1}-REPLY',
          pengirim: 'TRAVELER',
          teks: 'Halo ${p['nama']}, koper saya masih muat untuk titipanmu.',
          waktu: DateTime.now().add(Duration(minutes: i, seconds: 30)),
          idPesanan: 'PO-TEST-00$i',
          namaPengirim: 'Dimas Pratama',
          senderId: '2',
          receiverId: p['id'].toString(),
          idPemesan: p['email'] as String,
          userId: p['id'].toString(),
          namaPemesan: p['nama'] as String,
        );
        await LayananBasisDataLokal.kirimPesanChat(balasanTraveler);
      }

      // Ambil daftar thread inbox Traveler
      final threads = LayananBasisDataLokal.ambilDaftarThreadPemesan(
        travelerId: '2',
        emailTraveler: 'traveler.dimas@jastipgo.com',
      );

      // Verifikasi: Terdapat TEPAT 5 thread 1-on-1 terpisah, tidak digabung jadi satu!
      expect(threads.length, equals(5));

      final namaPemesanDiThreads = threads.map((t) => t.namaPemesan.toLowerCase()).toList();
      expect(namaPemesanDiThreads.any((n) => n.contains('siti')), isTrue);
      expect(namaPemesanDiThreads.any((n) => n.contains('budi')), isTrue);
      expect(namaPemesanDiThreads.any((n) => n.contains('andi')), isTrue);
      expect(namaPemesanDiThreads.any((n) => n.contains('dewi')), isTrue);
      expect(namaPemesanDiThreads.any((n) => n.contains('rian')), isTrue);

      // Setiap thread memiliki total pesan = 2 (1 tanya dari pemesan, 1 jawab dari traveler)
      for (var thread in threads) {
        expect(thread.totalPesan, equals(2));
      }
    });

    test('2. ISOLASI RUANG CHAT 1-ON-1: Pesan antara Traveler & Pemesan A tidak bocor ke Pemesan B', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();

      // Buat percakapan Pemesan A (Siti) dengan Traveler
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-SITI-01',
        pengirim: 'PEMESAN',
        teks: 'Halo kak, titip Tokyo Banana ya.',
        waktu: DateTime.now(),
        senderId: '101',
        receiverId: '2',
        idPemesan: 'siti@jastipgo.com',
        userId: '101',
        namaPengirim: 'Siti Nurhaliza',
      ));
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-SITI-02',
        pengirim: 'TRAVELER',
        teks: 'Siap Siti, dibelikan segera.',
        waktu: DateTime.now().add(const Duration(minutes: 1)),
        senderId: '2',
        receiverId: '101',
        idPemesan: 'siti@jastipgo.com',
        userId: '101',
        namaPengirim: 'Dimas Pratama',
      ));

      // Buat percakapan Pemesan B (Budi) dengan Traveler
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-BUDI-01',
        pengirim: 'PEMESAN',
        teks: 'Halo kak, titip Gundam RG ya.',
        waktu: DateTime.now(),
        senderId: '102',
        receiverId: '2',
        idPemesan: 'budi@jastipgo.com',
        userId: '102',
        namaPengirim: 'Budi Santoso',
      ));
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-BUDI-02',
        pengirim: 'TRAVELER',
        teks: 'Siap Budi, nanti saya carikan di Akihabara.',
        waktu: DateTime.now().add(const Duration(minutes: 1)),
        senderId: '2',
        receiverId: '102',
        idPemesan: 'budi@jastipgo.com',
        userId: '102',
        namaPengirim: 'Dimas Pratama',
      ));

      // Ambil obrolan khusus untuk Siti Nurhaliza (id: 101 / siti@jastipgo.com)
      final chatSiti = LayananBasisDataLokal.ambilPesanChatUntukPemesan(
        'siti@jastipgo.com',
        userId: '101',
      );

      // Ambil obrolan khusus untuk Budi Santoso (id: 102 / budi@jastipgo.com)
      final chatBudi = LayananBasisDataLokal.ambilPesanChatUntukPemesan(
        'budi@jastipgo.com',
        userId: '102',
      );

      // Verifikasi isolasi pesan:
      expect(chatSiti.length, equals(2));
      expect(chatBudi.length, equals(2));

      // Ruang chat Siti hanya berisi percakapan Siti & Traveler
      for (var m in chatSiti) {
        expect(m.teks.contains('Budi'), isFalse);
        expect(m.teks.contains('Gundam'), isFalse);
      }

      // Ruang chat Budi hanya berisi percakapan Budi & Traveler
      for (var m in chatBudi) {
        expect(m.teks.contains('Siti'), isFalse);
        expect(m.teks.contains('Tokyo Banana'), isFalse);
      }
    });

    test('3. CACHE LOKAL OFFLINE: Riwayat obrolan tetap tersimpan dan dapat dibaca seketika dari Hive tanpa server', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();

      // Simpan 3 pesan ke cache lokal Hive
      for (int i = 1; i <= 3; i++) {
        await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
          id: 'MSG-OFFLINE-$i',
          pengirim: i.isOdd ? 'PEMESAN' : 'TRAVELER',
          teks: 'Pesan cache offline ke-$i',
          waktu: DateTime.now(),
          senderId: i.isOdd ? '1' : '2',
          receiverId: i.isOdd ? '2' : '1',
          idPemesan: 'pemesan@jastipgo.com',
          userId: '1',
          namaPengirim: i.isOdd ? 'Pemesan' : 'Traveler',
        ));
      }

      // Pastikan data obrolan ada di Hive cache dan terbaca seketika
      final semuaPesan = LayananBasisDataLokal.ambilSemuaPesanChat();
      expect(semuaPesan.length, equals(3));

      // Verifikasi membaca pesan pertama
      final pesanAwal = semuaPesan.first;
      expect(pesanAwal.teks, equals('Pesan cache offline ke-1'));
      expect(pesanAwal.pengirim, equals('PEMESAN'));
    });

    test('4. PEMULIHAN AKUN LINTAS PERANGKAT: pulihkanDataPenggunaOnline menarik data tanpa error', () async {
      // Uji pemanggilan pulihkanDataPenggunaOnline
      await LayananSinkronisasiOnline.pulihkanDataPenggunaOnline(
        userId: '2',
        email: 'traveler.dimas@jastipgo.com',
        peran: 'TRAVELER',
        nama: 'Dimas Pratama',
      );

      // Listener pemicu pembaruan terpicu
      expect(LayananSinkronisasiOnline.pemicuPembaruanChat.value, greaterThan(0));
    });
  });

  group('Uji TODO_PERBAIKAN_PRODUCT_AND_CHAT: Pembaruan Status Berkelanjutan & Chat Dua Arah Keep-Alive', () {
    test('1. PEMBARUAN STATUS PESANAN BERKELANJUTAN (Tahap 2 hingga 6) TANPA MACET', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();

      // Buat pesanan baru tahap 1
      final pesananAwal = ModelPesananJastip(
        idPesanan: 'PO-TEST-CONTINUOUS-01',
        userId: '1',
        emailPemesan: 'ahmad@jastipgo.com',
        namaPemesan: 'Ahmad Dahlan',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Pesanan Diterima Sistem',
        tahapStatus: 1,
        metodePenyerahan: 'COD LBS',
        totalHargaIdr: 150000,
        daftarBarang: [],
      );
      await LayananBasisDataLokal.tambahPesanan(pesananAwal);

      final List<int> statusStreamDiterima = [];
      final sub = LayananSinkronisasiOnline.streamPesanan.listen((p) {
        if (p.idPesanan == 'PO-TEST-CONTINUOUS-01') {
          statusStreamDiterima.add(p.tahapStatus);
        }
      });

      // Simulasi Traveler memperbarui status bertahap:
      // Tahap 2: ACC oleh Traveler
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-TEST-CONTINUOUS-01',
        tahapStatus: 2,
        lokasiTerkini: 'Toko Resmi di Ginza (Traveler Menuju Lokasi)',
        peranPengguna: 'TRAVELER',
      );

      // Tahap 3: Selesai Dibeli di Toko
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-TEST-CONTINUOUS-01',
        tahapStatus: 3,
        lokasiTerkini: 'Kantong Belanja Traveler (Struk Resmi Diverifikasi)',
        peranPengguna: 'TRAVELER',
      );

      // Tahap 4: Masuk Bagasi Pesawat ke RI
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-TEST-CONTINUOUS-01',
        tahapStatus: 4,
        lokasiTerkini: 'Bagasi Pesawat Internasional ke Indonesia ✈️',
        peranPengguna: 'TRAVELER',
      );

      // Tahap 5: Mendarat di Indonesia
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-TEST-CONTINUOUS-01',
        tahapStatus: 5,
        lokasiTerkini: 'Mendarat di Indonesia (Siap COD) 🇮🇩',
        peranPengguna: 'TRAVELER',
      );

      // Tahap 6: Diterima Pemesan (Selesai)
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-TEST-CONTINUOUS-01',
        tahapStatus: 6,
        lokasiTerkini: 'Telah Diterima Pemesan (Selesai) 🎉',
        peranPengguna: 'TRAVELER',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      // Verifikasi status akhir di database lokal Hive
      final pesananAkhir = LayananBasisDataLokal.ambilSemuaPesanan().firstWhere(
        (p) => p.idPesanan == 'PO-TEST-CONTINUOUS-01',
      );
      expect(pesananAkhir.tahapStatus, equals(6));
      expect(pesananAkhir.apakahSudahDiterima, isTrue);

      // Verifikasi bahwa seluruh tahap status berhasil dialirkan ke stream tanpa terputus
      expect(statusStreamDiterima, contains(2));
      expect(statusStreamDiterima, contains(3));
      expect(statusStreamDiterima, contains(4));
      expect(statusStreamDiterima, contains(5));
      expect(statusStreamDiterima, contains(6));
    });

    test('2. SINKRONISASI CHAT DUA ARAH BERKELANJUTAN (Multi-Turn Keep-Alive Stream)', () async {
      await Hive.box(LayananBasisDataLokal.namaKotakChat).clear();

      final List<ModelPesanChat> pesanStreamDiterima = [];
      final sub = LayananSinkronisasiOnline.streamPesanChat.listen((m) {
        pesanStreamDiterima.add(m);
      });

      // Turn 1: Pemesan kirim pesan pertama
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-TURN-01',
        pengirim: 'PEMESAN',
        teks: 'Halo Traveler, apakah koper masih ada sisa?',
        waktu: DateTime.now(),
        senderId: '1',
        receiverId: '2',
        idPemesan: 'pemesan@jastipgo.com',
        userId: '1',
        namaPengirim: 'Pemesan',
      ));

      // Turn 1: Balasan Traveler pertama
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-TURN-02',
        pengirim: 'TRAVELER',
        teks: 'Halo! Masih ada sisa 5 kg kak.',
        waktu: DateTime.now().add(const Duration(seconds: 1)),
        senderId: '2',
        receiverId: 'pemesan@jastipgo.com',
        idPemesan: 'pemesan@jastipgo.com',
        userId: 'pemesan@jastipgo.com',
        namaPengirim: 'Dimas Pratama',
      ));

      // Turn 2: Pemesan kirim pesan lanjutan kedua (tidak boleh macet)
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-TURN-03',
        pengirim: 'PEMESAN',
        teks: 'Bagus kak, titip 2 box Tokyo Banana ya.',
        waktu: DateTime.now().add(const Duration(seconds: 2)),
        senderId: '1',
        receiverId: '2',
        idPemesan: 'pemesan@jastipgo.com',
        userId: '1',
        namaPengirim: 'Pemesan',
      ));

      // Turn 2: Balasan Traveler kedua
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-TURN-04',
        pengirim: 'TRAVELER',
        teks: 'Siap kak, sudah saya catat di keranjang belanja saya.',
        waktu: DateTime.now().add(const Duration(seconds: 3)),
        senderId: '2',
        receiverId: 'pemesan@jastipgo.com',
        idPemesan: 'pemesan@jastipgo.com',
        userId: 'pemesan@jastipgo.com',
        namaPengirim: 'Dimas Pratama',
      ));

      // Turn 3: Pemesan kirim pesan lanjutan ketiga
      await LayananBasisDataLokal.kirimPesanChat(ModelPesanChat(
        id: 'MSG-TURN-05',
        pengirim: 'PEMESAN',
        teks: 'Terima kasih banyak kak!',
        waktu: DateTime.now().add(const Duration(seconds: 4)),
        senderId: '1',
        receiverId: '2',
        idPemesan: 'pemesan@jastipgo.com',
        userId: '1',
        namaPengirim: 'Pemesan',
      ));

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      // Verifikasi stream tidak terputus dan menerima seluruh 5 pesan interaksi dua arah
      expect(pesanStreamDiterima.length, equals(5));
      expect(pesanStreamDiterima[0].id, equals('MSG-TURN-01'));
      expect(pesanStreamDiterima[1].id, equals('MSG-TURN-02'));
      expect(pesanStreamDiterima[2].id, equals('MSG-TURN-03'));
      expect(pesanStreamDiterima[3].id, equals('MSG-TURN-04'));
      expect(pesanStreamDiterima[4].id, equals('MSG-TURN-05'));

      // Verifikasi pembacaan dari Hive cache
      final obrolanLokal = LayananBasisDataLokal.ambilPesanChatUntukPemesan(
        'pemesan@jastipgo.com',
        userId: '1',
      );
      expect(obrolanLokal.length, equals(5));
    });
  });

  group('Uji TODO_PERUBAHAN_DATABASE: Integrasi Supabase Real-Time & Navigasi In-App LBS', () {
    test('1. API perutean OSRM (ambilRuteOsrm) dan fallback interpolasi rute geometris in-app', () async {
      final titik = await HalamanPetaLokasi.ambilRuteOsrm(
        latAwal: -7.7602,
        lngAwal: 110.4089,
        latTujuan: -7.7928,
        lngTujuan: 110.3658,
      );

      expect(titik.isNotEmpty, isTrue);
      expect(titik.first.latitude, closeTo(-7.7602, 0.001));
      expect(titik.first.longitude, closeTo(110.4089, 0.001));
      expect(titik.last.latitude, closeTo(-7.7928, 0.001));
      expect(titik.last.longitude, closeTo(110.3658, 0.001));
    });

    test('2. Sisi Traveler: Pemesan membuat pesanan baru -> tersinkronisasi via Supabase Real-Time', () async {
      final pesananBaruSupabase = ModelPesananJastip(
        idPesanan: 'ORD-SUPA-001',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Rafi Ahmad',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Menunggu konfirmasi Traveler di Tokyo',
        tahapStatus: 1,
        totalHargaIdr: 120000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Matcha KitKat Tokyo Special',
            fotoUrl: '',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Don Quijote Shinjuku',
            jumlah: 1,
            hargaIdr: 120000,
          ),
        ],
      );

      final List<ModelPesananJastip> pesananDiterimaTraveler = [];
      final sub = LayananSupabase.streamPesanan.listen((p) {
        pesananDiterimaTraveler.add(p);
      });

      // Simpan pesanan baru via Supabase
      final sukses = await LayananSupabase.simpanPesananBaru(pesananBaruSupabase);
      expect(sukses, isTrue);

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(pesananDiterimaTraveler.any((p) => p.idPesanan == 'ORD-SUPA-001'), isTrue);
      expect(pesananDiterimaTraveler.firstWhere((p) => p.idPesanan == 'ORD-SUPA-001').tahapStatus, equals(1));
    });

    test('3. Sisi Pemesan: Traveler perbarui status pengiriman (Tahap 2 s/d 6) -> ter-update real-time via Supabase', () async {
      // Pastikan pesanan terdaftar di basis data lokal & Supabase
      final pesananAwal = ModelPesananJastip(
        idPesanan: 'ORD-SUPA-001',
        userId: '1',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Rafi Ahmad',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Menunggu konfirmasi Traveler di Tokyo',
        tahapStatus: 1,
        totalHargaIdr: 120000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Matcha KitKat Tokyo Special',
            fotoUrl: '',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Don Quijote Shinjuku',
            jumlah: 1,
            hargaIdr: 120000,
          ),
        ],
      );
      await LayananBasisDataLokal.tambahPesanan(pesananAwal);

      final List<int> riwayatTahapStatus = [];
      final sub = LayananSupabase.streamPesanan.listen((p) {
        if (p.idPesanan == 'ORD-SUPA-001') {
          riwayatTahapStatus.add(p.tahapStatus);
        }
      });

      // Traveler ACC pesanan (Tahap 2)
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'ORD-SUPA-001',
        tahapStatus: 2,
        lokasiTerkini: 'Pesanan telah di-ACC. Traveler bersiap menuju toko di Tokyo.',
        peranPengguna: 'TRAVELER',
      );

      // Traveler beli barang di toko (Tahap 3)
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'ORD-SUPA-001',
        tahapStatus: 3,
        lokasiTerkini: 'Barang titipan telah dibeli di Don Quijote Shinjuku.',
        peranPengguna: 'TRAVELER',
      );

      // Barang masuk bagasi pesawat (Tahap 4)
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'ORD-SUPA-001',
        tahapStatus: 4,
        lokasiTerkini: 'Barang masuk bagasi penerbangan Haneda - Jakarta.',
        peranPengguna: 'TRAVELER',
      );

      // Traveler tiba di Indonesia (Tahap 5)
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'ORD-SUPA-001',
        tahapStatus: 5,
        lokasiTerkini: 'Traveler tiba di Hub JastipGo Kampus UPN Condongcatur.',
        peranPengguna: 'TRAVELER',
      );

      // Pemesan konfirmasi pesanan diterima (Tahap 6 - Transaksi Selesai)
      await LayananBasisDataLokal.konfirmasiPesananDiterima('ORD-SUPA-001');

      await Future.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(riwayatTahapStatus.contains(2), isTrue);
      expect(riwayatTahapStatus.contains(3), isTrue);
      expect(riwayatTahapStatus.contains(4), isTrue);
      expect(riwayatTahapStatus.contains(5), isTrue);
      expect(riwayatTahapStatus.contains(6), isTrue);

      // Verifikasi di Hive lokal cache
      final pesananLokal = LayananBasisDataLokal.ambilSemuaPesanan()
          .firstWhere((p) => p.idPesanan == 'ORD-SUPA-001');
      expect(pesananLokal.tahapStatus, equals(6));
      expect(pesananLokal.apakahSudahDiterima, isTrue);
    });
  });

  group('Uji TODO_MANAJEMEN_PESANAN: Firebase Database, Hak Akses Traveler, & Auto-Refund Rekber', () {
    test('1. Hak Akses Status Pesanan: Pemesan dilarang memperbarui status, HANYA Traveler yang diizinkan', () async {
      final pesanan = ModelPesananJastip(
        idPesanan: 'PO-ROLE-SECURITY-01',
        userId: 'pemesan_123',
        emailPemesan: 'pemesan@jastipgo.com',
        namaPemesan: 'Andi Pemesan',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Budi Traveler',
        lokasiTerkini: 'Pesanan Dibuat oleh Pemesan',
        tahapStatus: 1,
        totalHargaIdr: 150000,
        metodePenyerahan: 'LBS_COD',
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Matcha KitKat Special Edition',
            fotoUrl: 'https://example.com/kitkat.jpg',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Donki Tokyo',
            jumlah: 1,
            hargaIdr: 150000,
          ),
        ],
      );
      await LayananBasisDataLokal.tambahPesanan(pesanan);

      // Pemesan mencoba mengubah status -> Harus DITOLAK (throw StateError)
      expect(
        () async => await LayananBasisDataLokal.perbaruiStatusPesanan(
          'PO-ROLE-SECURITY-01',
          tahapStatus: 2,
          lokasiTerkini: 'Pemesan mencoba menggeser status',
          peranPengguna: 'PEMESAN',
        ),
        throwsA(isA<StateError>()),
      );

      // Pastikan status di database lokal Hive tidak berubah (masih 1)
      var cekPesanan = LayananBasisDataLokal.ambilSemuaPesanan()
          .firstWhere((p) => p.idPesanan == 'PO-ROLE-SECURITY-01');
      expect(cekPesanan.tahapStatus, equals(1));

      // Traveler mengubah status -> Berhasil diizinkan
      await LayananBasisDataLokal.perbaruiStatusPesanan(
        'PO-ROLE-SECURITY-01',
        tahapStatus: 2,
        lokasiTerkini: 'Pesanan di-ACC oleh Traveler di Tokyo',
        peranPengguna: 'TRAVELER',
      );

      cekPesanan = LayananBasisDataLokal.ambilSemuaPesanan()
          .firstWhere((p) => p.idPesanan == 'PO-ROLE-SECURITY-01');
      expect(cekPesanan.tahapStatus, equals(2));
    });

    test('2. Pembatalan Pesanan (Barang Kosong) & Pengembalian Dana Otomatis (Auto-Refund Rekber)', () async {
      // Siapkan dompet pemesan awal = 0
      final boxDompet = Hive.box(LayananRekber.namaKotakDompetPemesan);
      await boxDompet.clear();
      final boxRefund = Hive.box(LayananRekber.namaKotakRiwayatRefund);
      await boxRefund.clear();

      final pesanan = ModelPesananJastip(
        idPesanan: 'PO-REFUND-BARANG-KOSONG',
        userId: 'pemesan_paris',
        emailPemesan: 'pemesan@paris.com',
        namaPemesan: 'Citra Pemesan',
        tanggal: DateTime.now(),
        negaraAsal: 'Prancis 🇫🇷',
        namaTraveler: 'Budi Traveler',
        lokasiTerkini: 'Traveler mencari di Galeries Lafayette Paris',
        tahapStatus: 2, // Traveler sudah ACC, dana tertahan di Rekber
        totalHargaIdr: 2750000,
        metodePenyerahan: 'LBS_COD',
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Parfum Chanel N°5 Limited Paris',
            fotoUrl: 'https://example.com/chanel.jpg',
            negara: 'Prancis 🇫🇷',
            namaToko: 'Galeries Lafayette',
            jumlah: 1,
            hargaIdr: 2750000,
          ),
        ],
      );
      await LayananBasisDataLokal.tambahPesanan(pesanan);

      // Verifikasi awal: Saldo tertahan di Rekber adalah 2.750.000, dompet pemesan 0
      expect(LayananRekber.hitungSaldoTertahanRekber(), equals(2750000));
      expect(LayananRekber.ambilSaldoDompetPemesan(), equals(0));

      // Pemesan dilarang membatalkan dengan fitur pembatalan traveler
      expect(
        () async => await LayananBasisDataLokal.batalkanPesananBarangKosong(
          'PO-REFUND-BARANG-KOSONG',
          alasan: 'Pemesan iseng batalkan',
          peranPengguna: 'PEMESAN',
        ),
        throwsA(isA<StateError>()),
      );

      // Traveler membatalkan karena stok habis di luar negeri
      final suksesBatal = await LayananBasisDataLokal.batalkanPesananBarangKosong(
        'PO-REFUND-BARANG-KOSONG',
        alasan: 'Stok kosong di seluruh counter Paris',
        peranPengguna: 'TRAVELER',
      );
      expect(suksesBatal, isTrue);

      // Verifikasi status pesanan berubah menjadi Dibatalkan (tahapStatus = 0)
      final pesananBatal = LayananBasisDataLokal.ambilSemuaPesanan()
          .firstWhere((p) => p.idPesanan == 'PO-REFUND-BARANG-KOSONG');
      expect(pesananBatal.tahapStatus, equals(0));
      expect(pesananBatal.apakahDibatalkan, isTrue);
      expect(pesananBatal.alasanPembatalan, contains('Stok kosong'));

      // Verifikasi Saldo Tertahan Rekber otomatis berkurang (pesanan batal tidak dihitung tertahan)
      expect(LayananRekber.hitungSaldoTertahanRekber(), equals(0));

      // Verifikasi Saldo Dompet Pemesan otomatis bertambah 100% (2.750.000)
      expect(LayananRekber.ambilSaldoDompetPemesan(), equals(2750000));

      // Verifikasi riwayat refund tercatat lengkap
      final riwayatRefund = LayananRekber.ambilRiwayatRefundPemesan();
      expect(riwayatRefund.length, equals(1));
      expect(riwayatRefund.first['idPesanan'], equals('PO-REFUND-BARANG-KOSONG'));
      expect(riwayatRefund.first['nominal'], equals(2750000));
      expect(riwayatRefund.first['alasan'], contains('Stok kosong'));
    });

    test('3. Firebase Realtime Stream: Sinkronisasi pesanan dibatalkan & stream dompet refund', () async {
      final pesananStreamEvent = <ModelPesananJastip>[];
      final dompetStreamEvent = <Map<String, dynamic>>[];

      final subPesanan = LayananFirebase.streamPesanan.listen((p) {
        pesananStreamEvent.add(p);
      });
      final subDompet = LayananFirebase.streamDompet.listen((data) {
        dompetStreamEvent.add(data);
      });

      final pesanan = ModelPesananJastip(
        idPesanan: 'PO-STREAM-FIREBASE-01',
        userId: 'pemesan_sepatu',
        emailPemesan: 'pemesan@sepatu.com',
        namaPemesan: 'Dedi Pemesan',
        tanggal: DateTime.now(),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Budi Traveler',
        lokasiTerkini: 'Shibuya',
        tahapStatus: 2,
        totalHargaIdr: 2000000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Sneakers Onitsuka Tiger Tokyo',
            fotoUrl: 'https://example.com/tiger.jpg',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Onitsuka Shibuya',
            jumlah: 1,
            hargaIdr: 2000000,
          ),
        ],
      );
      await LayananBasisDataLokal.tambahPesanan(pesanan);

      await LayananBasisDataLokal.batalkanPesananBarangKosong(
        'PO-STREAM-FIREBASE-01',
        alasan: 'Ukuran sepatu habis total',
        peranPengguna: 'TRAVELER',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await subPesanan.cancel();
      await subDompet.cancel();

      expect(pesananStreamEvent.any((p) => p.idPesanan == 'PO-STREAM-FIREBASE-01' && p.tahapStatus == 0), isTrue);
      expect(dompetStreamEvent.any((d) => d['nominal'] == 2000000), isTrue);
    });

    testWidgets('4. UI Sisi Pemesan (HalamanStatusPesanan): Read-Only tanpa tombol ubah status & Kartu Auto-Refund', (tester) async {
      final profilPemesan = ModelPengguna(
        id: 1,
        nama: 'Andi Pemesan',
        email: 'pemesan@jastipgo.com',
        passwordHash: 'hash',
        nomorTelepon: '08123456789',
        fotoProfil: '',
        peran: 'PEMESAN',
      );

      await tester.runAsync(() async {
        await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();

        final pesananBatal = ModelPesananJastip(
          idPesanan: 'PO-PEMESAN-BATAL-99',
          userId: '1',
          emailPemesan: 'pemesan@jastipgo.com',
          namaPemesan: 'Andi Pemesan',
          tanggal: DateTime.now(),
          negaraAsal: 'Jepang 🇯🇵',
          namaTraveler: 'Dimas Traveler',
          lokasiTerkini: 'Toko Akihabara, Tokyo 🇯🇵',
          tahapStatus: 0, // Dibatalkan (Barang kosong)
          alasanPembatalan: 'Stok barang habis di toko resmi',
          totalHargaIdr: 1500000,
          daftarBarang: [
            ModelItemPesanan(
              namaBarang: 'Gunpla Perfect Grade Gundam RX-78',
              fotoUrl: '',
              negara: 'Jepang 🇯🇵',
              namaToko: 'Gundam Base',
              jumlah: 1,
              hargaIdr: 1500000,
            ),
          ],
        );
        await LayananBasisDataLokal.tambahPesanan(pesananBatal);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HalamanStatusPesanan(
            idPesananTerpilih: 'PO-PEMESAN-BATAL-99',
            peranOverride: 'PEMESAN',
            profilOverride: profilPemesan,
          ),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Pastikan judul halaman muncul
      expect(find.text('Pelacakan Status Pesanan'), findsOneWidget);

      // Verifikasi banner pembatalan dan auto-refund 100% muncul
      expect(find.text('PESANAN DIBATALKAN (BARANG KOSONG) ❌'), findsOneWidget);
      expect(find.text('Lihat Saldo Dompet & Riwayat Refund'), findsOneWidget);

      // Verifikasi Pemesan TIDAK memiliki tombol ubah status (Read-Only)
      expect(find.text('Update Status Pesanan'), findsNothing);
      expect(find.text('Sudah Dibeli di Toko'), findsNothing);
      expect(find.text('Barang Dalam Bagasi Pesawat'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('5. UI Sisi Traveler (HalamanKelolaPesananTraveler): Tombol Pembatalan Barang Kosong Tersedia', (tester) async {
      await tester.runAsync(() async {
        await Hive.box(LayananBasisDataLokal.namaKotakPesanan).clear();

        final pesananAktif = ModelPesananJastip(
          idPesanan: 'PO-TRAVELER-MANAGE-01',
          userId: 'pemesan_royce',
          emailPemesan: 'pemesan@royce.com',
          namaPemesan: 'Eko Pemesan',
          tanggal: DateTime.now(),
          negaraAsal: 'Jepang 🇯🇵',
          namaTraveler: 'traveler_123',
          lokasiTerkini: 'Traveler berada di New Chitose Airport',
          tahapStatus: 2, // ACC oleh traveler
          totalHargaIdr: 250000,
          daftarBarang: [
            ModelItemPesanan(
              namaBarang: 'Cokelat Royce Nama Cocoa',
              fotoUrl: '',
              negara: 'Jepang 🇯🇵',
              namaToko: 'Royce Chitose',
              jumlah: 1,
              hargaIdr: 250000,
            ),
          ],
        );
        await LayananBasisDataLokal.tambahPesanan(pesananAktif);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HalamanKelolaPesananTraveler(
            idPesananTerpilih: 'PO-TRAVELER-MANAGE-01',
            peranOverride: 'TRAVELER',
          ),
        ),
      );
      await tester.pump();

      // Verifikasi tombol pembatalan pesanan karena barang kosong hadir untuk Traveler
      expect(find.text('Batalkan Pesanan (Barang Tidak Ada)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}



