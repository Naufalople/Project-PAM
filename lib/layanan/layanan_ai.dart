import 'dart:math' as math;
import '../model/model_barang_jastip.dart';
import 'layanan_basisdata_lokal.dart';
import 'layanan_api.dart';

// Model Hasil Rekomendasi Algoritma AI (Collaborative Filtering & Content Similarity)
class RekomendasiBarangAi {
  final ModelBarangJastip barang;
  final double skorKemiripan; // 0.0 - 1.0
  final String alasanRekomendasi;
  final int totalPembelian;
  final int frekuensiBersama;

  RekomendasiBarangAi({
    required this.barang,
    required this.skorKemiripan,
    required this.alasanRekomendasi,
    this.totalPembelian = 0,
    this.frekuensiBersama = 0,
  });

  int get persentaseCocok => (skorKemiripan * 100).round().clamp(1, 99);
}

// Model Transaksi Riwayat Pembelian (Data Dummy & Real Transaction)
class TransaksiRiwayatDummy {
  final String idTransaksi;
  final String namaPembeli;
  final DateTime tanggal;
  final Map<int, int> itemDanJumlah; // ID Barang -> Kuantitas beli

  const TransaksiRiwayatDummy({
    required this.idTransaksi,
    required this.namaPembeli,
    required this.tanggal,
    required this.itemDanJumlah,
  });
}

// Layanan Cerdas AI: Recommendation Engine & LLM Chatbot Asisten Jastip
class LayananAi {
  // ========================================================
  // 1. DATASET TRANSAKSI PEMBELIAN (DUMMY HISTORICAL DATA)
  // Digunakan oleh Recommendation Engine untuk Collaborative Filtering & Market Basket
  // ========================================================

  static final List<TransaksiRiwayatDummy> _basisRiwayatTransaksi = [
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-001',
      namaPembeli: 'Siti Rahma',
      tanggal: DateTime(2026, 9, 10),
      itemDanJumlah: {1: 5, 2: 3}, // Tokyo Banana x5, Hada Labo x3
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-002',
      namaPembeli: 'Budi Santoso',
      tanggal: DateTime(2026, 9, 12),
      itemDanJumlah: {1: 6, 9: 4, 7: 2}, // Tokyo Banana x6, Irvins x4, Twinings x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-003',
      namaPembeli: 'Ahmad Fadil',
      tanggal: DateTime(2026, 9, 15),
      itemDanJumlah: {3: 2, 11: 5}, // Gundam RG x2, Pop Mart x5
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-004',
      namaPembeli: 'Jessica Tan',
      tanggal: DateTime(2026, 9, 18),
      itemDanJumlah: {4: 4, 2: 3, 5: 1}, // COSRX x4, Hada Labo x3, BTS Album x1
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-005',
      namaPembeli: 'Rian Hidayat',
      tanggal: DateTime(2026, 9, 21),
      itemDanJumlah: {6: 2, 7: 3, 8: 1}, // Harrods Bag x2, Twinings x3, Jo Malone x1
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-006',
      namaPembeli: 'Clara Wijaya',
      tanggal: DateTime(2026, 9, 25),
      itemDanJumlah: {5: 4, 11: 4}, // BTS Album x4, Pop Mart x4
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-007',
      namaPembeli: 'Farhan Putra',
      tanggal: DateTime(2026, 9, 28),
      itemDanJumlah: {1: 8, 3: 1}, // Tokyo Banana x8, Gundam x1
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-008',
      namaPembeli: 'Nadia Safitri',
      tanggal: DateTime(2026, 10, 2),
      itemDanJumlah: {9: 5, 10: 2}, // Irvins Chips x5, Charles & Keith x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-009',
      namaPembeli: 'Eko Prasetyo',
      tanggal: DateTime(2026, 10, 5),
      itemDanJumlah: {4: 3, 5: 2}, // COSRX x3, BTS Album x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-010',
      namaPembeli: 'Indah Kusuma',
      tanggal: DateTime(2026, 10, 7),
      itemDanJumlah: {1: 7, 2: 4, 11: 3}, // Tokyo Banana x7, Hada Labo x4, Pop Mart x3
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-011',
      namaPembeli: 'Kevin Chandra',
      tanggal: DateTime(2026, 10, 9),
      itemDanJumlah: {11: 6, 3: 2}, // Pop Mart x6, Gundam x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-012',
      namaPembeli: 'Mega Utami',
      tanggal: DateTime(2026, 10, 11),
      itemDanJumlah: {6: 1, 8: 2}, // Harrods Bag x1, Jo Malone x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-013',
      namaPembeli: 'Dimas Kurnia',
      tanggal: DateTime(2026, 10, 13),
      itemDanJumlah: {1: 5, 9: 3}, // Tokyo Banana x5, Irvins x3
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-014',
      namaPembeli: 'Rina Marlina',
      tanggal: DateTime(2026, 10, 15),
      itemDanJumlah: {4: 5, 2: 2}, // COSRX x5, Hada Labo x2
    ),
    TransaksiRiwayatDummy(
      idTransaksi: 'TRX-DUMMY-015',
      namaPembeli: 'Aris Setiawan',
      tanggal: DateTime(2026, 10, 17),
      itemDanJumlah: {10: 3, 6: 1}, // Charles & Keith x3, Harrods Bag x1
    ),
  ];

  // ========================================================
  // 2. AGREGASI STATISTIK PEMBELIAN & CO-PURCHASE
  // ========================================================

  // Menghitung akumulasi total kuantitas pembelian per ID barang (Dummy + Real Order Hive)
  static Map<int, int> hitungTotalPembelianPerBarang() {
    final Map<int, int> totalBeli = {};

    // 1. Agregasi dari basis data transaksi dummy
    for (final trx in _basisRiwayatTransaksi) {
      trx.itemDanJumlah.forEach((idBarang, qty) {
        totalBeli[idBarang] = (totalBeli[idBarang] ?? 0) + qty;
      });
    }

    // 2. Agregasi dinamis dari pesanan nyata yang tersimpan di Hive
    try {
      final pesananReal = LayananBasisDataLokal.ambilSemuaPesanan();
      final katalog = LayananBasisDataLokal.ambilSemuaKatalog();
      for (final pesanan in pesananReal) {
        for (final item in pesanan.daftarBarang) {
          final brg = katalog.where((k) => k.namaBarang.toLowerCase() == item.namaBarang.toLowerCase()).firstOrNull;
          if (brg != null) {
            totalBeli[brg.id] = (totalBeli[brg.id] ?? 0) + item.jumlah;
          }
        }
      }
    } catch (_) {}

    return totalBeli;
  }

  // Mengambil total pembelian untuk satu ID barang tertentu
  static int ambilTotalPembelian(int idBarang) {
    final totalMap = hitungTotalPembelianPerBarang();
    return totalMap[idBarang] ?? 0;
  }

  // Menghitung matriks frekuensi pembelian bersamaan (Co-Purchase Matrix)
  static Map<int, Map<int, int>> hitungMatriksPembelianBersamaan() {
    final Map<int, Map<int, int>> matriks = {};

    void catatPasangan(int a, int b) {
      if (a == b) return;
      matriks.putIfAbsent(a, () => {});
      matriks[a]![b] = (matriks[a]![b] ?? 0) + 1;
    }

    // Dari data transaksi dummy
    for (final trx in _basisRiwayatTransaksi) {
      final keys = trx.itemDanJumlah.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        for (int j = 0; j < keys.length; j++) {
          if (i != j) {
            catatPasangan(keys[i], keys[j]);
          }
        }
      }
    }

    // Dari pesanan nyata Hive
    try {
      final pesananReal = LayananBasisDataLokal.ambilSemuaPesanan();
      final katalog = LayananBasisDataLokal.ambilSemuaKatalog();
      for (final pesanan in pesananReal) {
        final List<int> ids = [];
        for (final item in pesanan.daftarBarang) {
          final brg = katalog.where((k) => k.namaBarang.toLowerCase() == item.namaBarang.toLowerCase()).firstOrNull;
          if (brg != null) ids.add(brg.id);
        }
        final uniqueIds = ids.toSet().toList();
        for (int i = 0; i < uniqueIds.length; i++) {
          for (int j = 0; j < uniqueIds.length; j++) {
            if (i != j) {
              catatPasangan(uniqueIds[i], uniqueIds[j]);
            }
          }
        }
      }
    } catch (_) {}

    return matriks;
  }

  // Mengambil frekuensi berapa kali dua barang dibeli bersamaan
  static int ambilFrekuensiDibeliBersama(int idA, int idB) {
    final matriks = hitungMatriksPembelianBersamaan();
    return matriks[idA]?[idB] ?? 0;
  }

  // ========================================================
  // 3. AI RECOMMENDATION ENGINE
  // (Collaborative Filtering + Content-Based + Total Purchase Weight)
  // ========================================================

  // Menghitung rekomendasi barang serupa untuk satu barang acuan
  static List<RekomendasiBarangAi> rekomendasikanBarang({
    required ModelBarangJastip barangAcuan,
    required List<ModelBarangJastip> semuaBarang,
    int batasHasil = 5,
  }) {
    final List<RekomendasiBarangAi> daftarSkor = [];
    final totalBeliSemua = hitungTotalPembelianPerBarang();
    final matriksCoBeli = hitungMatriksPembelianBersamaan();

    // Nilai maksimum pembelian untuk normalisasi skor volume
    int maxPembelian = 1;
    for (final val in totalBeliSemua.values) {
      if (val > maxPembelian) maxPembelian = val;
    }

    // Nilai maksimum co-beli untuk normalisasi
    int maxCoBeli = 1;
    final coBeliAcuan = matriksCoBeli[barangAcuan.id] ?? {};
    for (final val in coBeliAcuan.values) {
      if (val > maxCoBeli) maxCoBeli = val;
    }

    for (final kandidat in semuaBarang) {
      if (kandidat.id == barangAcuan.id) continue;

      final totalBeliKandidat = totalBeliSemua[kandidat.id] ?? 0;
      final frekuensiCoBeli = coBeliAcuan[kandidat.id] ?? 0;

      // 1. Bobot Volume Pembelian / Popularitas Pasar (30%)
      final double skorVolume = (totalBeliKandidat / maxPembelian).clamp(0.0, 1.0);

      // 2. Bobot Pembelian Bersamaan / Collaborative Signal (25%)
      final double skorCoBeli = (frekuensiCoBeli / maxCoBeli).clamp(0.0, 1.0);

      // 3. Kesamaan Kategori Produk (20%)
      final bool samaKategori = kandidat.kategori.toLowerCase() == barangAcuan.kategori.toLowerCase();
      final double skorKategori = samaKategori ? 1.0 : 0.0;

      // 4. Kesamaan Negara Asal Jastip (15%)
      final bool samaNegara = kandidat.negara.toLowerCase() == barangAcuan.negara.toLowerCase();
      final double skorNegara = samaNegara ? 1.0 : 0.0;

      // 5. Kedekatan Rentang Harga (10%)
      final double selisihHarga = (kandidat.estimasiHargaIdr - barangAcuan.estimasiHargaIdr).abs().toDouble();
      final double maksHarga = [kandidat.estimasiHargaIdr, barangAcuan.estimasiHargaIdr].reduce((a, b) => a > b ? a : b).toDouble();
      final double skorHarga = (1.0 - (selisihHarga / (maksHarga > 0 ? maksHarga : 1.0))).clamp(0.0, 1.0);

      // Kalkulasi Skor Akhir Hybrid AI
      final double totalSkor = (skorVolume * 0.30) +
          (skorCoBeli * 0.25) +
          (skorKategori * 0.20) +
          (skorNegara * 0.15) +
          (skorHarga * 0.10);

      // Penjelasan AI yang transparan dan informatif
      final List<String> poinAlasan = [];
      if (totalBeliKandidat > 0) {
        poinAlasan.add('$totalBeliKandidat terjual');
      }
      if (frekuensiCoBeli > 0) {
        poinAlasan.add('${frekuensiCoBeli}x dibeli bersama');
      }
      if (samaNegara && samaKategori) {
        poinAlasan.add('${kandidat.negara} • ${kandidat.kategori}');
      } else if (samaNegara) {
        poinAlasan.add('Asal ${kandidat.negara}');
      } else if (samaKategori) {
        poinAlasan.add('Kategori ${kandidat.kategori}');
      }

      final String alasan = poinAlasan.isNotEmpty ? poinAlasan.join(' • ') : 'Rekomendasi Populer';

      daftarSkor.add(RekomendasiBarangAi(
        barang: kandidat,
        skorKemiripan: totalSkor,
        alasanRekomendasi: alasan,
        totalPembelian: totalBeliKandidat,
        frekuensiBersama: frekuensiCoBeli,
      ));
    }

    // Urutkan skor tertinggi ke terendah
    daftarSkor.sort((a, b) => b.skorKemiripan.compareTo(a.skorKemiripan));

    return daftarSkor.take(batasHasil).toList();
  }

  // Mengambil daftar produk terlaris berdasarkan total volume pembelian (Trending Best Seller)
  static List<RekomendasiBarangAi> ambilProdukTerlaris({
    required List<ModelBarangJastip> semuaBarang,
    int batasHasil = 10,
  }) {
    final totalBeliSemua = hitungTotalPembelianPerBarang();

    int maxBeli = 1;
    for (final v in totalBeliSemua.values) {
      if (v > maxBeli) maxBeli = v;
    }

    final List<RekomendasiBarangAi> hasil = semuaBarang.map((b) {
      final int total = totalBeliSemua[b.id] ?? 0;
      final double skor = (total / maxBeli).clamp(0.05, 0.99);

      return RekomendasiBarangAi(
        barang: b,
        skorKemiripan: skor,
        alasanRekomendasi: '🔥 $total pcs terjual di platform',
        totalPembelian: total,
      );
    }).toList();

    hasil.sort((a, b) => b.totalPembelian.compareTo(a.totalPembelian));
    return hasil.take(batasHasil).toList();
  }

  // Memberikan rekomendasi personalisasi cerdas berdasarkan isi keranjang & pesanan pengguna
  static List<RekomendasiBarangAi> rekomendasikanUntukPengguna({
    required List<ModelBarangJastip> semuaBarang,
    int batasHasil = 6,
  }) {
    final keranjang = LayananBasisDataLokal.ambilSemuaKeranjang();
    final pesanan = LayananBasisDataLokal.ambilSemuaPesanan();

    final Set<int> idInteraksiPengguna = {};
    for (final k in keranjang) {
      idInteraksiPengguna.add(k.idBarang);
    }
    for (final p in pesanan) {
      for (final item in p.daftarBarang) {
        final brg = semuaBarang.where((b) => b.namaBarang.toLowerCase() == item.namaBarang.toLowerCase()).firstOrNull;
        if (brg != null) idInteraksiPengguna.add(brg.id);
      }
    }

    // Jika pengguna belum berinteraksi, tampilkan produk terlaris sebagai rekomendasi awal
    if (idInteraksiPengguna.isEmpty) {
      return ambilProdukTerlaris(semuaBarang: semuaBarang, batasHasil: batasHasil);
    }

    // Cari barang acuan utama dari keranjang / pesanan terbaru
    final ModelBarangJastip acuan = semuaBarang.firstWhere(
      (b) => idInteraksiPengguna.contains(b.id),
      orElse: () => semuaBarang.first,
    );

    // Gunakan hybrid recommendation berbasis barang yang diminati pengguna
    final rekomendasi = rekomendasikanBarang(
      barangAcuan: acuan,
      semuaBarang: semuaBarang,
      batasHasil: batasHasil,
    );

    return rekomendasi;
  }

  // ========================================================
  // 4. LLM CHATBOT (ASISTEN PINTAR JASTIP & REGULASI KOPER)
  // ========================================================

  /// Instruksi Sistem (System Prompt) untuk membatasi ruang lingkup asisten AI
  static const String instruksiSistemChatbotJastip =
      'Anda adalah Asisten Cerdas JastipGo khusus layanan Jasa Titip (Jastip). '
      'Konteks percakapan mencakup aturan barang bawaan jastip, regulasi koper, '
      'bea cukai, pajak impor, IMEI, rekomendasi oleh-oleh luar negeri (Jepang, Korea, London, Singapura, China), '
      'kurs mata uang asing, spesifikasi dan katalog produk/barang yang ada di aplikasi (termasuk informasi barang termahal, termurah, dan harga katalog), '
      'serta fitur dan sistem transaksi aplikasi JastipGo. '
      'Jika pertanyaan pengguna di luar konteks layanan Jastip dan data aplikasi, berikan jawaban penolakan baku.';

  /// Respon penolakan baku saat pengguna menanyakan hal di luar topik aplikasi jastip
  static const String pesanPenolakanDiLuarKonteks =
      'Maaf, saya hanya bisa menjawab seputar aplikasi Jastip ini. Jika di luar itu, saya tidak memiliki kemampuan untuk menjawabnya.';

  /// Mengambil data katalog produk yang aktif dari Hive lokal atau master seed
  static List<ModelBarangJastip> ambilKatalogAktif() {
    List<ModelBarangJastip> daftar = LayananBasisDataLokal.ambilSemuaKatalog();
    if (daftar.isEmpty) {
      daftar = LayananApi.buatKatalogAwalDatabase();
    }
    return daftar;
  }

  static String _formatNominalRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  /// Validasi apakah pertanyaan pengguna masih berada dalam konteks layanan Jastip & data aplikasi
  static bool apakahDalamKonteksJastip(String pertanyaan) {
    final q = pertanyaan.toLowerCase().trim();
    if (q.isEmpty) return false;

    // Kata kunci penanda topik yang valid dalam ekosistem jastip & aplikasi
    final kataKunciJastip = [
      'jastip', 'titip', 'titipan', 'koper', 'belanja', 'toko', 'barang',
      'termahal', 'termurah', 'paling mahal', 'paling murah', 'katalog', 'daftar barang',
      'daftar produk', 'list barang', 'produk', 'spesifikasi', 'harga tertinggi', 'harga terendah',
      'paling hemat', 'paling terjangkau',
      'bea cukai', 'pajak', 'cukai', 'pmk', 'fob', '500', 'usd', 'kurs', 'mata uang',
      'yen', 'jpy', 'won', 'krw', 'pound', 'gbp', 'dolar', 'sgd', 'yuan', 'cny', 'rupiah', 'idr',
      'harga', 'biaya', 'ongkir', 'tarif', 'diskon', 'voucher', 'promo',
      'imei', 'hp', 'gadget', 'iphone', 'android',
      'jepang', 'tokyo', 'don quijote', 'ginza', 'shinjuku', 'akihabara', 'tokyo banana', 'gundam',
      'korea', 'seoul', 'myeongdong', 'olive young', 'cosrx', 'k-pop', 'bts',
      'london', 'uk', 'inggris', 'harrods', 'twinings', 'jo malone',
      'singapura', 'singapore', 'orchard', 'irvins', 'charles & keith',
      'china', 'shanghai', 'pop mart',
      'pesan', 'pesanan', 'order', 'checkout', 'keranjang', 'batal', 'acc',
      'traveler', 'pemesan', 'pembeli', 'chat', 'hub', 'cod', 'lbs', 'antar', 'kurir',
      'blockchain', 'rekber', 'escrow', 'struk', 'verifikasi', 'keamanan',
      'profil', 'biometrik', 'sidik jari', 'bantuan', 'fitur', 'aplikasi', 'jastipgo',
      'halo', 'hai', 'hi', 'pagi', 'siang', 'sore', 'malam', 'assalamualaikum',
      'terima kasih', 'makasih', 'thanks', 'siapa kamu', 'apa itu jastip',
    ];

    for (final kata in kataKunciJastip) {
      if (q.contains(kata)) return true;
    }

    return false;
  }

  /// Alias untuk pemanggilan asisten cerdas jastip
  static Future<String> tanyaAsistenJastip(String pertanyaan) => prosesPesanChatbot(pertanyaan);

  static Future<String> prosesPesanChatbot(String pertanyaan) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Validasi Poin 2: Jika di luar konteks jastip, berikan jawaban penolakan baku
    if (!apakahDalamKonteksJastip(pertanyaan)) {
      return pesanPenolakanDiLuarKonteks;
    }

    final q = pertanyaan.toLowerCase();
    final katalog = ambilKatalogAktif();

    // ------------------------------------------------------------------------
    // SUNTIKAN KONTEKS DATA KATALOG PRODUK APLIKASI JASTIPGO (POIN 2)
    // Mampu menjawab spesifikasi, barang termahal, termurah, dan daftar katalog
    // ------------------------------------------------------------------------
    final bool tanyaTermahal = q.contains('termahal') ||
        q.contains('paling mahal') ||
        q.contains('harga tertinggi') ||
        (q.contains('mahal') && (q.contains('barang') || q.contains('produk') || q.contains('aplikasi')));

    final bool tanyaTermurah = q.contains('termurah') ||
        q.contains('paling murah') ||
        q.contains('harga terendah') ||
        q.contains('paling hemat') ||
        q.contains('paling terjangkau') ||
        (q.contains('murah') && (q.contains('barang') || q.contains('produk') || q.contains('aplikasi')));

    // 1. Pertanyaan Perbandingan Keduanya (Termahal & Termurah Sekaligus)
    if (tanyaTermahal && tanyaTermurah && katalog.isNotEmpty) {
      final termahal = katalog.reduce((a, b) => a.estimasiHargaIdr > b.estimasiHargaIdr ? a : b);
      final termurah = katalog.reduce((a, b) => a.estimasiHargaIdr < b.estimasiHargaIdr ? a : b);

      return '📊 **Analisis Data Katalog Aplikasi JastipGo:**\n\n'
          '💎 **Barang Termahal di Aplikasi:**\n'
          '• **Nama Produk:** ${termahal.namaBarang}\n'
          '• **Harga:** Rp ${_formatNominalRupiah(termahal.estimasiHargaIdr)} (${termahal.hargaAsli.toStringAsFixed(0)} ${termahal.kodeMataUang})\n'
          '• **Negara Asal:** ${termahal.benderaNegara} ${termahal.negara} (${termahal.namaToko})\n'
          '• **Kategori:** ${termahal.kategori}\n'
          '• **Deskripsi:** ${termahal.deskripsi}\n\n'
          '🏷️ **Barang Termurah di Aplikasi:**\n'
          '• **Nama Produk:** ${termurah.namaBarang}\n'
          '• **Harga:** Rp ${_formatNominalRupiah(termurah.estimasiHargaIdr)} (${termurah.hargaAsli.toStringAsFixed(1)} ${termurah.kodeMataUang})\n'
          '• **Negara Asal:** ${termurah.benderaNegara} ${termurah.negara} (${termurah.namaToko})\n'
          '• **Kategori:** ${termurah.kategori}\n'
          '• **Deskripsi:** ${termurah.deskripsi}\n\n'
          '💡 Semua barang di atas dapat langsung Anda pesan melalui halaman Beranda dengan jaminan perlindungan dana Rekber Escrow!';
    }

    // 2. Pertanyaan Khusus Barang Termahal
    if (tanyaTermahal && katalog.isNotEmpty) {
      final urutMahal = List<ModelBarangJastip>.from(katalog)
        ..sort((a, b) => b.estimasiHargaIdr.compareTo(a.estimasiHargaIdr));
      final termahal = urutMahal.first;

      final buffer = StringBuffer();
      buffer.writeln('💎 **Barang Termahal di Aplikasi JastipGo:**\n');
      buffer.writeln('Produk dengan harga tertinggi saat ini adalah **${termahal.namaBarang}** dengan harga **Rp ${_formatNominalRupiah(termahal.estimasiHargaIdr)}** (${termahal.hargaAsli.toStringAsFixed(0)} ${termahal.kodeMataUang}).');
      buffer.writeln('• **Asal Negara:** ${termahal.benderaNegara} ${termahal.negara} (Toko: ${termahal.namaToko})');
      buffer.writeln('• **Kategori:** ${termahal.kategori}');
      buffer.writeln('• **Deskripsi:** ${termahal.deskripsi}\n');
      buffer.writeln('📌 **3 Produk dengan Nilai Tertinggi di Aplikasi:**');
      for (int i = 0; i < math.min(3, urutMahal.length); i++) {
        final item = urutMahal[i];
        buffer.writeln('${i + 1}. **${item.namaBarang}** - Rp ${_formatNominalRupiah(item.estimasiHargaIdr)} (${item.negara})');
      }
      return buffer.toString().trim();
    }

    // 3. Pertanyaan Khusus Barang Termurah
    if (tanyaTermurah && katalog.isNotEmpty) {
      final urutMurah = List<ModelBarangJastip>.from(katalog)
        ..sort((a, b) => a.estimasiHargaIdr.compareTo(b.estimasiHargaIdr));
      final termurah = urutMurah.first;

      final buffer = StringBuffer();
      buffer.writeln('🏷️ **Barang Termurah & Paling Terjangkau di Aplikasi JastipGo:**\n');
      buffer.writeln('Produk dengan harga paling hemat saat ini adalah **${termurah.namaBarang}** dengan harga **Rp ${_formatNominalRupiah(termurah.estimasiHargaIdr)}** (${termurah.hargaAsli.toStringAsFixed(1)} ${termurah.kodeMataUang}).');
      buffer.writeln('• **Asal Negara:** ${termurah.benderaNegara} ${termurah.negara} (Toko: ${termurah.namaToko})');
      buffer.writeln('• **Kategori:** ${termurah.kategori}');
      buffer.writeln('• **Deskripsi:** ${termurah.deskripsi}\n');
      buffer.writeln('📌 **3 Produk Paling Hemat di Aplikasi:**');
      for (int i = 0; i < math.min(3, urutMurah.length); i++) {
        final item = urutMurah[i];
        buffer.writeln('${i + 1}. **${item.namaBarang}** - Rp ${_formatNominalRupiah(item.estimasiHargaIdr)} (${item.negara})');
      }
      return buffer.toString().trim();
    }

    // 4. Pertanyaan Mengenai Daftar / Katalog Produk Aplikasi
    if (q.contains('katalog') ||
        q.contains('daftar barang') ||
        q.contains('daftar produk') ||
        q.contains('list barang') ||
        q.contains('list produk') ||
        q.contains('apa saja barang') ||
        q.contains('ada barang apa')) {
      final buffer = StringBuffer();
      buffer.writeln('📦 **Daftar Ringkasan Katalog Produk JastipGo (${katalog.length} Produk Aktif):**\n');
      final Map<String, List<ModelBarangJastip>> perNegara = {};
      for (final b in katalog) {
        perNegara.putIfAbsent('${b.benderaNegara} ${b.negara}', () => []).add(b);
      }
      perNegara.forEach((negara, listBrg) {
        buffer.writeln('**$negara:**');
        for (final b in listBrg) {
          buffer.writeln('• ${b.namaBarang} - Rp ${_formatNominalRupiah(b.estimasiHargaIdr)} (${b.kategori})');
        }
        buffer.writeln('');
      });
      buffer.writeln('💡 Anda dapat memfilter produk berdasarkan negara singgah dan kategori di halaman Beranda!');
      return buffer.toString().trim();
    }

    // ------------------------------------------------------------------------
    // ATURAN RESMI, KOPER, KURS, & FITUR APLIKASI
    // ------------------------------------------------------------------------
    if (q.contains('bea cukai') || q.contains('pajak') || q.contains('aturan') || q.contains('cukai')) {
      return '📋 **Aturan Bea Cukai Impor Barang Penumpang:**\n'
          'Sesuai PMK 203/2017, batas pembebasan bea masuk barang bawaan pribadi adalah **FOB USD 500 per orang**. '
          'Jika total belanjaan jastip Anda melebihi USD 500, kelebihannya akan dikenakan tarif bea masuk flat 10% + PPN 11%. Pastikan traveler selalu menyimpan struk resmi ya!';
    } else if (q.contains('imei') || q.contains('hp') || q.contains('iphone') || q.contains('gadget')) {
      return '📱 **Aturan Pendaftaran IMEI Gadget:**\n'
          'Untuk gadget/HP dari luar negeri (seperti iPhone atau Android), traveler wajib mendaftarkan IMEI di pos Bea Cukai bandara kedatangan. '
          'HP dengan harga di bawah USD 500 bebas pajak, sedangkan di atas USD 500 dikenakan PPh dan PPN.';
    } else if (q.contains('jepang') || q.contains('tokyo')) {
      return '🇯🇵 **Rekomendasi Oleh-Oleh Populer Jepang:**\n'
          '1. **Kuliner:** Tokyo Banana (Terlaris #1), Shiroi Koibito, KitKat rasa Matcha Uji.\n'
          '2. **Skincare:** Hada Labo Premium, Biore UV Aqua Rich, Rohto Melano CC.\n'
          '3. **Hobi:** Gunpla Gundam Base Odaiba dan merchandise Akihabara.\n'
          'Kurs saat ini: 1 JPY ≈ Rp 112.5.';
    } else if (q.contains('korea') || q.contains('seoul')) {
      return '🇰🇷 **Rekomendasi Jastip Populer Korea Selatan:**\n'
          '1. **Skincare:** COSRX Snail Mucin, Beauty of Joseon Sun Relief, Torriden Dive-In Serum (bisa dibeli di Olive Young Myeongdong).\n'
          '2. **K-Pop:** Album resmi dan merchandise idol dari K-Town4U.\n'
          'Kurs saat ini: 1 KRW ≈ Rp 11.8.';
    } else if (q.contains('london') || q.contains('uk') || q.contains('inggris')) {
      return '🇬🇧 **Rekomendasi Jastip Ikonik London:**\n'
          '1. **Tas:** Harrods Signature Green Shopper Bag.\n'
          '2. **Teh:** Twinings English Breakfast & Fortnum & Mason Tea.\n'
          '3. **Parfum:** Jo Malone London Wood Sage & Sea Salt.\n'
          'Perhatikan jam London (GMT), biasanya toko di Regent Street tutup pukul 18:00 sore!';
    } else if (q.contains('singapura') || q.contains('singapore')) {
      return '🇸🇬 **Rekomendasi Jastip Populer Singapura:**\n'
          '1. **Kuliner:** Irvins Salted Egg Fish Skin, Bacha Coffee, Garrett Popcorn.\n'
          '2. **Fashion:** Charles & Keith (Orchard Road / Bandara Changi).\n'
          'Kurs saat ini: 1 SGD ≈ Rp 11.950.';
    } else if (q.contains('china') || q.contains('shanghai')) {
      return '🇨🇳 **Rekomendasi Jastip Populer China:**\n'
          '1. **Hobi & Mainan:** Pop Mart Blind Box (Labubu, Skullpanda, Dimoo) di Shanghai Store.\n'
          '2. **Kuliner:** Teh Melati Jasmine & Snack khas Yunnan.\n'
          'Kurs saat ini: 1 CNY ≈ Rp 2.230.';
    } else if (q.contains('kurs') || q.contains('uang') || q.contains('harga') || q.contains('yen') || q.contains('won') || q.contains('pound')) {
      return '💱 **Kurs Mata Uang Asing Hari Ini:**\n'
          '• 1 JPY (Yen Jepang) = Rp 112.5\n'
          '• 1 KRW (Won Korea) = Rp 11.8\n'
          '• 1 GBP (Pound London) = Rp 20.600\n'
          '• 1 SGD (Dolar Singapura) = Rp 11.950\n'
          '• 1 CNY (Yuan China) = Rp 2.230\n'
          'Anda bisa menggunakan menu **Kalkulator Kurs** di tab Fitur Cerdas untuk kalkulasi instan!';
    } else if (q.contains('rekber') || q.contains('escrow') || q.contains('keamanan') || q.contains('dana')) {
      return '🛡️ **Sistem Keamanan Rekber Escrow JastipGo:**\n'
          '1. Saat Pemesan membayar, dana otomatis masuk ke sistem Rekber (Dana Tertahan) dan DILARANG untuk ditarik atau dicairkan oleh Traveler.\n'
          '2. Traveler dapat memantau dana tertahan di dashboard, namun tidak dapat menariknya selama proses belanja & pengantaran.\n'
          '3. Pelepasan Dana (Release Fund): Dana di Rekber otomatis cair ke Saldo Aktif Traveler HANYA JIKA Pemesan sudah mengonfirmasi "Sudah Diterima" bahwa produk telah sampai dengan baik.';
    } else if (q.contains('cara titip') || q.contains('pesan') || q.contains('order') || q.contains('titip')) {
      return '🛒 **Cara Menitip Barang di JastipGo:**\n'
          '1. Pilih barang dari katalog Open PO atau temukan saran di fitur **Rekomendasi Cerdas AI** berdasarkan tren transaksi belanja.\n'
          '2. Masukkan ke Keranjang Belanja.\n'
          '3. Lakukan konfirmasi pembayaran dengan sidik jari.\n'
          '4. Pembayaran Anda dilindungi sistem Rekber Escrow hingga barang tiba dan dikonfirmasi diterima!';
    } else {
      return 'Halo! Saya **Asisten Cerdas JastipGo** 🤖\n'
          'Saya siap membantu Anda seputar:\n'
          '• Katalog produk, barang termahal & termurah di aplikasi JastipGo.\n'
          '• Aturan bea cukai & batas koper belanjaan luar negeri (FOB USD 500).\n'
          '• Rekomendasi oleh-oleh terbaik dari Jepang, Korea, London, & Singapura.\n'
          '• Keamanan transaksi Rekber Escrow (dana tertahan hingga barang sampai).\n'
          '• Cek kurs mata uang asing dan zona waktu toko internasional.\n'
          'Ada yang bisa saya bantu untuk rencana titipan Anda?';
    }
  }
}
