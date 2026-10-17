import 'package:hive_flutter/hive_flutter.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';
import '../model/model_pesanan_jastip.dart';

// Model data untuk Kupon / Voucher Promo Diskon Jastip
class ModelVoucher {
  final String kode;
  final String judul;
  final int potonganIdr;
  final String deskripsi;

  ModelVoucher({
    required this.kode,
    required this.judul,
    required this.potonganIdr,
    required this.deskripsi,
  });

  Map<String, dynamic> keMap() => {
        'kode': kode,
        'judul': judul,
        'potonganIdr': potonganIdr,
        'deskripsi': deskripsi,
      };

  factory ModelVoucher.dariMap(Map data) => ModelVoucher(
        kode: data['kode']?.toString() ?? '',
        judul: data['judul']?.toString() ?? '',
        potonganIdr: (data['potonganIdr'] as num?)?.toInt() ?? 0,
        deskripsi: data['deskripsi']?.toString() ?? '',
      );
}

// Layanan Basis Data Lokal Menggunakan Hive (NoSQL)
class LayananBasisDataLokal {
  static const String namaKotakKeranjang = 'kotak_keranjang';
  static const String namaKotakBlockchain = 'kotak_blockchain';
  static const String namaKotakPesanan = 'kotak_pesanan';
  static const String namaKotakVoucher = 'kotak_voucher';

  // Inisialisasi Hive saat aplikasi pertama kali dijalankan
  static Future<void> inisialisasi() async {
    await Hive.initFlutter();
    await Hive.openBox(namaKotakKeranjang);
    await Hive.openBox(namaKotakBlockchain);
    final boxPesanan = await Hive.openBox(namaKotakPesanan);
    final boxVoucher = await Hive.openBox(namaKotakVoucher);

    // Inisialisasi daftar pesanan awal jika masih kosong
    if (boxPesanan.isEmpty) {
      await _inisialisasiPesananAwal(boxPesanan);
    }

    // Inisialisasi voucher promo awal jika masih kosong
    if (boxVoucher.isEmpty) {
      await _inisialisasiVoucherAwal(boxVoucher);
    }
  }

  // Voucher awal untuk demonstrasi dan uji coba pemesan
  static Future<void> _inisialisasiVoucherAwal(Box box) async {
    final voucherAwal = [
      ModelVoucher(
        kode: 'SHAKE50',
        judul: '🎉 Diskon Ongkos Jastip Rp 50.000',
        potonganIdr: 50000,
        deskripsi: 'Didapat dari Goyang HP (Shake Promo)',
      ),
      ModelVoucher(
        kode: 'POJASTIP100',
        judul: '🎁 Potongan Belanja Rp 100.000 (Spesial Harrods & Tokyo)',
        potonganIdr: 100000,
        deskripsi: 'Voucher pengguna baru jastip internasional',
      ),
    ];
    for (var v in voucherAwal) {
      await box.add(v.keMap());
    }
  }

  // Pesanan awal demonstrasi dengan variasi negara, banyak barang, dan lokasi live
  static Future<void> _inisialisasiPesananAwal(Box box) async {
    final pesananAwal = [
      ModelPesananJastip(
        idPesanan: 'PO-JSTP-882194',
        tanggal: DateTime.now().subtract(const Duration(hours: 4)),
        negaraAsal: 'Jepang 🇯🇵',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Sedang di Toko Ginza Mitsukoshi, Tokyo 🇯🇵',
        tahapStatus: 2, // Di-ACC Traveler, Sedang Menuju Toko
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 475000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Tokyo Banana Tokyo Station Edition (Isi 8)',
            fotoUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Tokyo Banana Official Store Ginza',
            jumlah: 1,
            hargaIdr: 285000,
          ),
          ModelItemPesanan(
            namaBarang: 'Matcha KitKat Premium Uji Kyoto Special',
            fotoUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
            negara: 'Jepang 🇯🇵',
            namaToko: 'Don Quijote Ginza',
            jumlah: 2,
            hargaIdr: 190000,
          ),
        ],
      ),
      ModelPesananJastip(
        idPesanan: 'PO-JSTP-943012',
        tanggal: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        negaraAsal: 'Korea Selatan 🇰🇷',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Mendarat di Indonesia (Siap COD LBS Hub UPN Jogja / Bandara YIA) 🇮🇩',
        tahapStatus: 5, // Tiba di RI (Siap COD LBS atau Kurir)
        metodePenyerahan: 'COD_LBS',
        totalHargaIdr: 4430000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Gentle Monster Her 01 Oversized Sunglasses',
            fotoUrl: 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500',
            negara: 'Korea Selatan 🇰🇷',
            namaToko: 'Gentle Monster Flagship Hongdae',
            jumlah: 1,
            hargaIdr: 3450000,
          ),
          ModelItemPesanan(
            namaBarang: 'Sulwhasoo First Care Activating Serum VI (60ml)',
            fotoUrl: 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=500',
            negara: 'Korea Selatan 🇰🇷',
            namaToko: 'Olive Young Myeongdong',
            jumlah: 1,
            hargaIdr: 980000,
          ),
        ],
      ),
      ModelPesananJastip(
        idPesanan: 'PO-JSTP-512087',
        tanggal: DateTime.now().subtract(const Duration(days: 2)),
        negaraAsal: 'Inggris 🇬🇧',
        namaTraveler: 'Dimas Pratama',
        lokasiTerkini: 'Penerbangan Internasional LHR ✈️ CGK (Ketinggian 35.000 ft)',
        tahapStatus: 4, // Dalam Penerbangan ke RI
        metodePenyerahan: 'KURIR_ANTAR',
        totalHargaIdr: 520000,
        daftarBarang: [
          ModelItemPesanan(
            namaBarang: 'Harrods Heritage English Breakfast Blend (Tin 125g)',
            fotoUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
            negara: 'Inggris 🇬🇧',
            namaToko: 'Harrods Knightsbridge London',
            jumlah: 2,
            hargaIdr: 520000,
          ),
        ],
      ),
    ];

    for (var pesanan in pesananAwal) {
      await box.add(pesanan.keMap());
    }
  }

  // ==========================================
  // FITUR DAFTAR PESANAN & STATUS (CRUD HIVE)
  // ==========================================

  // Ambil semua pesanan tersimpan
  static List<ModelPesananJastip> ambilSemuaPesanan() {
    final box = Hive.box(namaKotakPesanan);
    final List<ModelPesananJastip> daftar = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        daftar.add(ModelPesananJastip.dariMap(data));
      }
    }
    // Urutkan dari pesanan terbaru
    daftar.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return daftar;
  }

  // Tambah pesanan baru (misal saat checkout selesai)
  static Future<void> tambahPesanan(ModelPesananJastip pesananBaru) async {
    final box = Hive.box(namaKotakPesanan);
    await box.add(pesananBaru.keMap());
  }

  // Perbarui status dan lokasi pesanan
  static Future<void> perbaruiStatusPesanan(
    String idPesanan, {
    required int tahapStatus,
    required String lokasiTerkini,
    String? metodePenyerahan,
    String? alamatPengiriman,
  }) async {
    final box = Hive.box(namaKotakPesanan);
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map && data['idPesanan'] == idPesanan) {
        final pesanan = ModelPesananJastip.dariMap(data);
        pesanan.tahapStatus = tahapStatus;
        pesanan.lokasiTerkini = lokasiTerkini;
        if (metodePenyerahan != null) {
          pesanan.metodePenyerahan = metodePenyerahan;
        }
        if (alamatPengiriman != null) {
          pesanan.alamatPengiriman = alamatPengiriman;
        }
        await box.putAt(i, pesanan.keMap());
        break;
      }
    }
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

  // ==========================================
  // FITUR MANAJEMEN VOUCHER PROMO (HIVE)
  // ==========================================

  // Ambil semua voucher yang belum dipakai
  static List<ModelVoucher> ambilSemuaVoucher() {
    final box = Hive.box(namaKotakVoucher);
    final List<ModelVoucher> daftar = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        daftar.add(ModelVoucher.dariMap(data));
      }
    }
    return daftar;
  }

  // Simpan voucher baru (didapat dari Shake Promo atau Mini Game)
  static Future<void> simpanVoucher(ModelVoucher voucher) async {
    final box = Hive.box(namaKotakVoucher);
    // Cek jika voucher dengan kode ini sudah ada
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map && data['kode'] == voucher.kode) {
        return; // Jangan duplikasi
      }
    }
    await box.add(voucher.keMap());
  }

  // Gunakan voucher (langsung dihapus dari database agar tidak bisa dipakai ulang)
  static Future<bool> gunakanVoucher(String kode) async {
    final box = Hive.box(namaKotakVoucher);
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map && data['kode'] == kode) {
        await box.deleteAt(i);
        return true;
      }
    }
    return false;
  }
}
