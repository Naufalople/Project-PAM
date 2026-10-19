import 'package:hive_flutter/hive_flutter.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_pesan_chat.dart';
import '../model/model_barang_jastip.dart';

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

// Model ringkasan thread obrolan pemesan untuk inbox traveler
class ThreadChatPemesan {
  final String idPemesan;
  final String namaPemesan;
  final String pesanTerakhir;
  final DateTime waktuTerakhir;
  final int totalPesan;
  final String? infoTitipan;

  ThreadChatPemesan({
    required this.idPemesan,
    required this.namaPemesan,
    required this.pesanTerakhir,
    required this.waktuTerakhir,
    required this.totalPesan,
    this.infoTitipan,
  });
}

// Layanan Basis Data Lokal Menggunakan Hive (NoSQL)
class LayananBasisDataLokal {
  static const String namaKotakKeranjang = 'kotak_keranjang';
  static const String namaKotakBlockchain = 'kotak_blockchain';
  static const String namaKotakPesanan = 'kotak_pesanan';
  static const String namaKotakVoucher = 'kotak_voucher';
  static const String namaKotakChat = 'kotak_chat_jastip';
  static const String namaKotakKatalog = 'kotak_katalog_jastip';

  // Inisialisasi Hive saat aplikasi pertama kali dijalankan
  static Future<void> inisialisasi() async {
    await Hive.initFlutter();
    await Hive.openBox(namaKotakKeranjang);
    await Hive.openBox(namaKotakBlockchain);
    final boxPesanan = await Hive.openBox(namaKotakPesanan);
    final boxVoucher = await Hive.openBox(namaKotakVoucher);
    final boxChat = await Hive.openBox(namaKotakChat);
    await Hive.openBox(namaKotakKatalog);

    // Hapus pesanan bawaan dummy lama agar HANYA pesanan nyata yang dibuat pengguna yang tampil
    final List<int> indeksHapus = [];
    for (int i = 0; i < boxPesanan.length; i++) {
      final data = boxPesanan.getAt(i);
      if (data is Map) {
        final id = data['idPesanan']?.toString() ?? '';
        if (id == 'PO-JSTP-882194' ||
            id == 'PO-JSTP-943012' ||
            id == 'PO-JSTP-512087' ||
            id == 'PO-JSTP-943201' ||
            id == 'PO-JSTP-771120') {
          indeksHapus.add(i);
        }
      }
    }
    for (int idx in indeksHapus.reversed) {
      await boxPesanan.deleteAt(idx);
    }

    // Inisialisasi voucher promo awal jika masih kosong
    if (boxVoucher.isEmpty) {
      await _inisialisasiVoucherAwal(boxVoucher);
    }

    // Inisialisasi pembuka obrolan dari berbagai pemesan jika masih kosong (Poin 5: Multi-Pemesan Inbox)
    if (boxChat.isEmpty) {
      final waktuSekarang = DateTime.now();
      // Thread 1: Pemesan Utama (Siti / Anda)
      await boxChat.add(
        ModelPesanChat(
          id: 'pesan_awal_1',
          teks: 'Halo! Saya Dimas Pratama (Traveler Luar Negeri). Ada yang ingin dititipkan dari luar negeri?',
          adalahPengguna: false,
          pengirim: 'TRAVELER',
          namaPengirim: 'Dimas Pratama (Traveler)',
          waktu: waktuSekarang.subtract(const Duration(hours: 2)),
          idPemesan: 'pemesan@jastipgo.com',
          namaPemesan: 'Pemesan Jastip (Anda)',
        ).keMap(),
      );
      await boxChat.add(
        ModelPesanChat(
          id: 'pesan_awal_2',
          teks: 'Halo kak Dimas! Saya mau titip Tokyo Banana Classic Box ya.',
          adalahPengguna: true,
          pengirim: 'PEMESAN',
          namaPengirim: 'Pemesan Jastip (Anda)',
          waktu: waktuSekarang.subtract(const Duration(hours: 1, minutes: 45)),
          idPemesan: 'pemesan@jastipgo.com',
          namaPemesan: 'Pemesan Jastip (Anda)',
        ).keMap(),
      );
      // Thread 2: Jessica Tan (Seoul)
      await boxChat.add(
        ModelPesanChat(
          id: 'pesan_jessica_1',
          teks: 'Kak Dimas, apakah essence COSRX Snail Mucin di Olive Young Myeongdong stoknya masih ada?',
          adalahPengguna: true,
          pengirim: 'PEMESAN',
          namaPengirim: 'Jessica Tan',
          waktu: waktuSekarang.subtract(const Duration(hours: 1, minutes: 15)),
          idPemesan: 'jessica.tan@gmail.com',
          namaPemesan: 'Jessica Tan (Jakarta)',
        ).keMap(),
      );
      await boxChat.add(
        ModelPesanChat(
          id: 'pesan_jessica_2',
          teks: 'Halo Jessica! Sudah aman, barusan saya belikan di gerai Myeongdong ya.',
          adalahPengguna: false,
          pengirim: 'TRAVELER',
          namaPengirim: 'Dimas Pratama (Traveler)',
          waktu: waktuSekarang.subtract(const Duration(minutes: 50)),
          idPemesan: 'jessica.tan@gmail.com',
          namaPemesan: 'Jessica Tan (Jakarta)',
        ).keMap(),
      );
      // Thread 3: Budi Santoso (Surabaya)
      await boxChat.add(
        ModelPesanChat(
          id: 'pesan_budi_1',
          teks: 'Halo kak, untuk Gunpla Gundam RG apakah slot koper masih cukup muat ya?',
          adalahPengguna: true,
          pengirim: 'PEMESAN',
          namaPengirim: 'Budi Santoso',
          waktu: waktuSekarang.subtract(const Duration(minutes: 25)),
          idPemesan: 'budi.santoso@yahoo.com',
          namaPemesan: 'Budi Santoso (Surabaya)',
        ).keMap(),
      );
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

  // ==========================================
  // FITUR OBROLAN DUA ARAH REAL PEMESAN & TRAVELER
  // ==========================================

  // Ambil semua pesan percakapan
  static List<ModelPesanChat> ambilSemuaPesanChat() {
    final box = Hive.box(namaKotakChat);
    final List<ModelPesanChat> pesan = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        pesan.add(ModelPesanChat.dariMap(data));
      }
    }
    return pesan;
  }

  // Ambil pesan percakapan khusus untuk pemesan tertentu (Poin 5: Isolasi Obrolan)
  static List<ModelPesanChat> ambilPesanChatUntukPemesan(String idPemesan) {
    final semua = ambilSemuaPesanChat();
    final hasil = semua.where((p) => p.idPemesan.toLowerCase() == idPemesan.toLowerCase()).toList();
    hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
    return hasil;
  }

  // Ambil ringkasan seluruh thread pemesan untuk tampilan inbox traveler (Poin 5: Inbox Traveler)
  static List<ThreadChatPemesan> ambilDaftarThreadPemesan() {
    final semuaPesan = ambilSemuaPesanChat();
    final Map<String, List<ModelPesanChat>> grup = {};

    for (var p in semuaPesan) {
      grup.putIfAbsent(p.idPemesan, () => []).add(p);
    }

    final List<ThreadChatPemesan> threads = [];
    grup.forEach((idPemesan, listPesan) {
      listPesan.sort((a, b) => a.waktu.compareTo(b.waktu));
      final terakhir = listPesan.last;

      String nama = terakhir.namaPemesan;
      if (nama.isEmpty || nama == 'Pengguna') {
        final kandidat = listPesan.firstWhere(
          (m) => m.pengirim == 'PEMESAN' && m.namaPengirim.isNotEmpty,
          orElse: () => terakhir,
        );
        nama = kandidat.namaPengirim;
      }

      String? infoTitipan;
      if (idPemesan.contains('pemesan') || idPemesan.contains('siti')) {
        infoTitipan = 'Tokyo Banana Classic Box (Jepang 🇯🇵)';
      } else if (idPemesan.contains('jessica')) {
        infoTitipan = 'COSRX Snail Mucin (Korea 🇰🇷)';
      } else if (idPemesan.contains('budi')) {
        infoTitipan = 'Gundam RG 1/144 (Jepang 🇯🇵)';
      }

      threads.add(ThreadChatPemesan(
        idPemesan: idPemesan,
        namaPemesan: nama,
        pesanTerakhir: terakhir.teks,
        waktuTerakhir: terakhir.waktu,
        totalPesan: listPesan.length,
        infoTitipan: infoTitipan,
      ));
    });

    threads.sort((a, b) => b.waktuTerakhir.compareTo(a.waktuTerakhir));
    return threads;
  }

  // Kirim pesan baru ke database Hive
  static Future<void> kirimPesanChat(ModelPesanChat pesanBaru) async {
    final box = Hive.box(namaKotakChat);
    await box.add(pesanBaru.keMap());
  }

  // Kosongkan riwayat obrolan jika diperlukan
  static Future<void> bersihkanChat() async {
    final box = Hive.box(namaKotakChat);
    await box.clear();
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

  // ==========================================
  // FITUR KATALOG PRODUK JASTIP (HIVE NOSQL)
  // ==========================================

  // Ambil seluruh katalog produk dari database lokal Hive
  static List<ModelBarangJastip> ambilSemuaKatalog() {
    if (!Hive.isBoxOpen(namaKotakKatalog)) return [];
    final box = Hive.box(namaKotakKatalog);
    final List<ModelBarangJastip> daftar = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        daftar.add(ModelBarangJastip.dariJson(Map<String, dynamic>.from(data)));
      }
    }
    return daftar;
  }

  // Simpan / Sinkronkan seluruh katalog produk ke Hive
  static Future<void> simpanSemuaKatalog(List<ModelBarangJastip> daftarBarang) async {
    if (!Hive.isBoxOpen(namaKotakKatalog)) {
      await Hive.openBox(namaKotakKatalog);
    }
    final box = Hive.box(namaKotakKatalog);
    await box.clear();
    for (var b in daftarBarang) {
      await box.add(b.keJson());
    }
  }

  // Tambahkan barang jastip baru ke katalog Hive
  static Future<void> tambahBarangKatalog(ModelBarangJastip barang) async {
    if (!Hive.isBoxOpen(namaKotakKatalog)) {
      await Hive.openBox(namaKotakKatalog);
    }
    final box = Hive.box(namaKotakKatalog);
    await box.add(barang.keJson());
  }
}
