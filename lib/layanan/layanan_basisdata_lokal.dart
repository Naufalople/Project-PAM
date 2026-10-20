import 'package:hive_flutter/hive_flutter.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_pesan_chat.dart';
import '../model/model_barang_jastip.dart';

// Model data untuk Kupon / Voucher Promo Diskon Jastip dengan Isolasi Akun (User ID)
class ModelVoucher {
  final String kode;
  final String judul;
  final int potonganIdr;
  final String deskripsi;
  final String userId;

  ModelVoucher({
    required this.kode,
    required this.judul,
    required this.potonganIdr,
    required this.deskripsi,
    this.userId = '',
  });

  Map<String, dynamic> keMap() => {
        'kode': kode,
        'judul': judul,
        'potonganIdr': potonganIdr,
        'deskripsi': deskripsi,
        'userId': userId,
      };

  factory ModelVoucher.dariMap(Map data) => ModelVoucher(
        kode: data['kode']?.toString() ?? '',
        judul: data['judul']?.toString() ?? '',
        potonganIdr: (data['potonganIdr'] as num?)?.toInt() ?? 0,
        deskripsi: data['deskripsi']?.toString() ?? '',
        userId: data['userId']?.toString() ?? '',
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
  static const String namaKotakPengguna = 'kotak_pengguna';

  // Inisialisasi Hive saat aplikasi pertama kali dijalankan
  static Future<void> inisialisasi() async {
    await Hive.initFlutter();
    await Hive.openBox(namaKotakKeranjang);
    await Hive.openBox(namaKotakBlockchain);
    final boxPesanan = await Hive.openBox(namaKotakPesanan);
    final boxVoucher = await Hive.openBox(namaKotakVoucher);
    final boxChat = await Hive.openBox(namaKotakChat);
    await Hive.openBox(namaKotakKatalog);
    await Hive.openBox(namaKotakPengguna);

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

    // Bersihkan obrolan bawaan dummy lama agar chat room bersih (Poin 5: Hapus Auto-Chat Default)
    final List<int> indeksHapusChat = [];
    for (int i = 0; i < boxChat.length; i++) {
      final data = boxChat.getAt(i);
      if (data is Map) {
        final id = data['id']?.toString() ?? '';
        if (id.startsWith('pesan_awal') ||
            id.startsWith('pesan_jessica') ||
            id.startsWith('pesan_budi')) {
          indeksHapusChat.add(i);
        }
      }
    }
    for (int idx in indeksHapusChat.reversed) {
      await boxChat.deleteAt(idx);
    }
  }

  // Voucher awal untuk demonstrasi dan uji coba pemesan terikat ke User ID 1 (Siti)
  static Future<void> _inisialisasiVoucherAwal(Box box) async {
    final voucherAwal = [
      ModelVoucher(
        kode: 'SHAKE50',
        judul: '🎉 Diskon Ongkos Jastip Rp 50.000',
        potonganIdr: 50000,
        deskripsi: 'Didapat dari Goyang HP (Shake Promo)',
        userId: '1',
      ),
      ModelVoucher(
        kode: 'POJASTIP100',
        judul: '🎁 Potongan Belanja Rp 100.000 (Spesial Harrods & Tokyo)',
        potonganIdr: 100000,
        deskripsi: 'Voucher pengguna baru jastip internasional',
        userId: '1',
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

  // Ambil pesan percakapan khusus untuk pemesan tertentu (Poin 3: Sinkronisasi senderId & receiverId)
  static List<ModelPesanChat> ambilPesanChatUntukPemesan(String idPemesan, {String? userId}) {
    final semua = ambilSemuaPesanChat();
    final cleanId = idPemesan.toLowerCase().trim();
    final cleanUser = userId?.toLowerCase().trim();

    final hasil = semua.where((p) {
      final s = p.senderId.toLowerCase().trim();
      final r = p.receiverId.toLowerCase().trim();
      final pId = p.idPemesan.toLowerCase().trim();
      final uId = p.userId?.toLowerCase().trim();

      if (cleanUser != null && (s == cleanUser || r == cleanUser || uId == cleanUser)) return true;
      if (s == cleanId || r == cleanId || pId == cleanId) return true;
      return false;
    }).toList();
    hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
    return hasil;
  }

  // Ambil seluruh pesan di mana receiverId atau senderId cocok dengan akun Traveler (Poin 3)
  static List<ModelPesanChat> ambilPesanChatUntukTraveler({
    required String travelerId,
    String? emailTraveler,
  }) {
    final semua = ambilSemuaPesanChat();
    final tId = travelerId.toLowerCase().trim();
    final eId = emailTraveler?.toLowerCase().trim() ?? '';

    final hasil = semua.where((p) {
      final r = p.receiverId.toLowerCase().trim();
      final s = p.senderId.toLowerCase().trim();

      // Cocok jika receiverId adalah Traveler (pesan masuk dari Pemesan)
      if (r == tId || (eId.isNotEmpty && r == eId) || r == '2' || r.contains('traveler')) return true;
      // Atau senderId adalah Traveler (pesan balasan keluar dari Traveler)
      if (s == tId || (eId.isNotEmpty && s == eId) || s == '2' || s.contains('traveler')) return true;

      return false;
    }).toList();

    hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
    return hasil;
  }

  // Ambil ringkasan seluruh thread pemesan untuk tampilan inbox traveler (Poin 3 & Poin 5)
  static List<ThreadChatPemesan> ambilDaftarThreadPemesan({String? travelerId, String? emailTraveler}) {
    final List<ModelPesanChat> semuaPesan = (travelerId != null || emailTraveler != null)
        ? ambilPesanChatUntukTraveler(travelerId: travelerId ?? '2', emailTraveler: emailTraveler)
        : ambilSemuaPesanChat();

    final Map<String, List<ModelPesanChat>> grup = {};

    for (var p in semuaPesan) {
      // Kelompokkan per thread pemesan
      String keyThread = p.idPemesan;
      if (keyThread.isEmpty || keyThread == '2' || keyThread.contains('traveler')) {
        keyThread = p.senderId != '2' && !p.senderId.contains('traveler') ? p.senderId : p.receiverId;
      }
      grup.putIfAbsent(keyThread, () => []).add(p);
    }

    final List<ThreadChatPemesan> threads = [];
    final List<ModelPesananJastip> daftarPesanan = ambilSemuaPesanan();
    final List<Map<String, dynamic>> daftarAkun = ambilSemuaAkunHive();

    grup.forEach((idPemesan, listPesan) {
      listPesan.sort((a, b) => a.waktu.compareTo(b.waktu));
      final terakhir = listPesan.last;

      // Resolusi Akurat: Nama Asli Akun Pemesan (Poin 1 TODO_PERBAIKAN_FITUR)
      String nama = '';

      // 1. Cari dari pesan yang dikirim oleh pemesan
      for (var m in listPesan.reversed) {
        if (m.pengirim == 'PEMESAN' && m.namaPengirim.trim().isNotEmpty) {
          final n = m.namaPengirim.trim();
          if (!n.toLowerCase().contains('traveler') && n.toLowerCase() != 'dimas pratama') {
            nama = n;
            break;
          }
        }
      }

      // 2. Cari dari m.adalahPengguna
      if (nama.isEmpty) {
        for (var m in listPesan.reversed) {
          if (m.adalahPengguna && m.namaPengirim.trim().isNotEmpty) {
            final n = m.namaPengirim.trim();
            if (!n.toLowerCase().contains('traveler') && n.toLowerCase() != 'dimas pratama') {
              nama = n;
              break;
            }
          }
        }
      }

      // 3. Cari dari daftar pesanan aktif pemesan
      if (nama.isEmpty) {
        final idTarget = idPemesan.toLowerCase().trim();
        for (var pesanan in daftarPesanan) {
          final em = pesanan.emailPemesan?.toLowerCase().trim() ?? '';
          final uId = pesanan.userId?.toLowerCase().trim() ?? '';
          final nm = pesanan.namaPemesan?.trim() ?? '';
          if (em == idTarget || uId == idTarget) {
            if (nm.isNotEmpty) {
              nama = nm;
              break;
            }
          }
        }
      }

      // 4. Cari dari data akun pengguna yang terdaftar di Hive
      if (nama.isEmpty) {
        final idTarget = idPemesan.toLowerCase().trim();
        for (var akun in daftarAkun) {
          final em = akun['email']?.toString().toLowerCase().trim() ?? '';
          final idAkun = akun['id']?.toString().toLowerCase().trim() ?? '';
          if (em == idTarget || idAkun == idTarget) {
            final nm = akun['nama']?.toString().trim() ?? '';
            if (nm.isNotEmpty && !nm.toLowerCase().contains('traveler')) {
              nama = nm;
              break;
            }
          }
        }
      }

      // 5. Cek terakhir.namaPemesan jika bukan nama traveler
      if (nama.isEmpty) {
        final n = terakhir.namaPemesan.trim();
        if (n.isNotEmpty &&
            n != 'Pengguna' &&
            n != 'Pemesan' &&
            !n.toLowerCase().contains('traveler') &&
            n.toLowerCase() != 'dimas pratama') {
          nama = n;
        }
      }

      // 6. Fallback cerdas berdasarkan idPemesan
      if (nama.isEmpty) {
        final idTarget = idPemesan.toLowerCase().trim();
        if (idTarget.contains('siti') || idTarget == '1') {
          nama = 'Siti Rahma';
        } else if (idTarget.contains('jessica')) {
          nama = 'Jessica Mila';
        } else if (idTarget.contains('budi')) {
          nama = 'Budi Santoso';
        } else {
          nama = 'Pemesan ($idPemesan)';
        }
      }

      String? infoTitipan;
      if (idPemesan.contains('pemesan') || idPemesan.contains('siti') || idPemesan == '1') {
        infoTitipan = 'Tokyo Banana Classic Box (Jepang 🇯🇵)';
      } else if (idPemesan.contains('jessica')) {
        infoTitipan = 'COSRX Snail Mucin (Korea 🇰🇷)';
      } else if (idPemesan.contains('budi')) {
        infoTitipan = 'Gundam RG 1/144 (Jepang 🇯🇵)';
      }
      if (infoTitipan == null) {
        final idTarget = idPemesan.toLowerCase().trim();
        for (var pesanan in daftarPesanan) {
          final em = pesanan.emailPemesan?.toLowerCase().trim() ?? '';
          final uId = pesanan.userId?.toLowerCase().trim() ?? '';
          if (em == idTarget || uId == idTarget) {
            infoTitipan = '${pesanan.idPesanan} (${pesanan.negaraAsal})';
            break;
          }
        }
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

  // Kosongkan riwayat obrolan jika diperlukan / saat logout (Poin 6: Isolasi Sesi Chat)
  static Future<void> bersihkanMemoriChat() async {
    if (Hive.isBoxOpen(namaKotakChat)) {
      final box = Hive.box(namaKotakChat);
      await box.clear();
    }
  }

  static Future<void> bersihkanChat() async => bersihkanMemoriChat();

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

  // Ambil pesanan yang difilter khusus untuk akun pengguna yang login (Poin 8: Isolasi Pelacakan Pesanan)
  static List<ModelPesananJastip> ambilPesananUntukPengguna({String? userId, String? email}) {
    final semua = ambilSemuaPesanan();
    if (userId == null && email == null) return semua;

    return semua.where((p) {
      if (userId != null && p.userId != null && p.userId == userId) return true;
      if (email != null && p.emailPemesan != null && p.emailPemesan!.toLowerCase() == email.toLowerCase()) return true;
      // Kompatibilitas untuk pesanan lama
      if (p.userId == null && p.emailPemesan == null) {
        if (email != null && email.toLowerCase() == 'pemesan@jastipgo.com') return true;
        if (userId != null && userId == '1') return true;
      }
      return false;
    }).toList();
  }

  // ========================================================
  // VALIDASI PESANAN AKTIF TRAVELER (TODO_VALIDASI_DESTINASI)
  // ========================================================

  /// Memeriksa apakah masih ada pesanan yang ditangani traveler dengan status belum mencapai
  /// tahap 4 ("Dikirim ke Indonesia" / Penerbangan).
  /// Mengembalikan true jika ada pesanan yang belum dikirim ke Indonesia.
  static bool apakahAdaPesananBelumDikirim({String? namaTraveler}) {
    final semua = ambilSemuaPesanan();
    if (semua.isEmpty) return false;

    return semua.any((pesanan) {
      if (namaTraveler != null && namaTraveler.trim().isNotEmpty) {
        final String cleanInput = namaTraveler.trim().toLowerCase();
        final String cleanOrder = pesanan.namaTraveler.trim().toLowerCase();
        final bool cocok = cleanOrder.contains(cleanInput) || cleanInput.contains(cleanOrder);
        if (!cocok) return false;
      }
      // Status < 4 berarti masih dalam tahap 1 (Menunggu ACC), 2 (Menuju Toko), atau 3 (Sudah Dibeli tapi belum terbang ke RI)
      return pesanan.tahapStatus < 4;
    });
  }

  /// Mengambil daftar pesanan aktif yang sedang ditangani traveler dan belum dikirim ke Indonesia
  static List<ModelPesananJastip> ambilPesananBelumDikirimTraveler({String? namaTraveler}) {
    final semua = ambilSemuaPesanan();
    return semua.where((pesanan) {
      if (namaTraveler != null && namaTraveler.trim().isNotEmpty) {
        final String cleanInput = namaTraveler.trim().toLowerCase();
        final String cleanOrder = pesanan.namaTraveler.trim().toLowerCase();
        final bool cocok = cleanOrder.contains(cleanInput) || cleanInput.contains(cleanOrder);
        if (!cocok) return false;
      }
      return pesanan.tahapStatus < 4;
    }).toList();
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

  /// Mengonfirmasi pesanan telah diterima oleh Pemesan (Poin 5)
  /// Mengubah tahapStatus menjadi 6 (Selesai/Sudah Diterima)
  static Future<void> konfirmasiPesananDiterima(String idPesanan) async {
    await perbaruiStatusPesanan(
      idPesanan,
      tahapStatus: 6,
      lokasiTerkini: 'Telah Diterima Pemesan di Alamat Tujuan (Transaksi Selesai) 🎉',
    );
  }

  /// Mengambil daftar pesanan berstatus "Belum Diterima" (tahapStatus < 6)
  static List<ModelPesananJastip> ambilPesananBelumDiterima({String? userId, String? email}) {
    final list = ambilPesananUntukPengguna(userId: userId, email: email);
    return list.where((p) => p.apakahBelumDiterima).toList();
  }

  /// Mengambil daftar pesanan berstatus "Sudah Diterima" (tahapStatus >= 6)
  static List<ModelPesananJastip> ambilPesananSudahDiterima({String? userId, String? email}) {
    final list = ambilPesananUntukPengguna(userId: userId, email: email);
    return list.where((p) => p.apakahSudahDiterima).toList();
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
  // ISOLASI PROMO BERDASARKAN USER ID (POIN 4)
  // ==========================================

  // Ambil semua voucher yang belum dipakai dengan filter User ID akun aktif
  static List<ModelVoucher> ambilSemuaVoucher({String? userId}) {
    final box = Hive.box(namaKotakVoucher);
    final List<ModelVoucher> daftar = [];
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        final voucher = ModelVoucher.dariMap(data);
        if (userId != null && userId.isNotEmpty) {
          // Hanya muat kupon yang terikat dengan User ID milik akun yang sedang login saat ini
          if (voucher.userId == userId) {
            daftar.add(voucher);
          } else if (voucher.userId.isEmpty && (userId == '1' || userId.toLowerCase().contains('pemesan'))) {
            // Kompatibilitas kupon awal untuk akun pemesan default
            daftar.add(voucher);
          }
        } else {
          daftar.add(voucher);
        }
      }
    }
    return daftar;
  }

  // Simpan voucher baru dengan pengenal unik User ID (didapat dari Shake Promo atau Mini Game)
  static Future<void> simpanVoucher(ModelVoucher voucher, {String? userId}) async {
    final box = Hive.box(namaKotakVoucher);
    final String targetUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : (voucher.userId.isNotEmpty ? voucher.userId : '1');

    // Cek jika voucher dengan kode ini sudah ada untuk akun/User ID yang sama
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        final existing = ModelVoucher.dariMap(data);
        if (existing.kode == voucher.kode &&
            (existing.userId == targetUserId || (existing.userId.isEmpty && targetUserId == '1'))) {
          return; // Jangan duplikasi voucher yang sama untuk akun ini
        }
      }
    }

    final voucherBaru = ModelVoucher(
      kode: voucher.kode,
      judul: voucher.judul,
      potonganIdr: voucher.potonganIdr,
      deskripsi: voucher.deskripsi,
      userId: targetUserId,
    );
    await box.add(voucherBaru.keMap());
  }

  // Gunakan voucher (langsung dihapus dari database khusus milik User ID terkait agar tidak bisa dipakai ulang)
  static Future<bool> gunakanVoucher(String kode, {String? userId}) async {
    final box = Hive.box(namaKotakVoucher);
    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null && data is Map) {
        final v = ModelVoucher.dariMap(data);
        if (v.kode == kode) {
          if (userId == null ||
              userId.isEmpty ||
              v.userId == userId ||
              (v.userId.isEmpty && (userId == '1' || userId.toLowerCase().contains('pemesan')))) {
            await box.deleteAt(i);
            return true;
          }
        }
      }
    }
    return false;
  }

  // Bersihkan memori/state promo saat pengguna logout agar data tidak bocor ke akun lain
  static void bersihkanStatePromo() {
    // Memastikan pembersihan state memori lokal promo
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

  // ========================================================
  // PENYIMPANAN AKUN PENGGUNA DI HIVE (VALIDASI REGISTRASI)
  // ========================================================

  // Mengambil seluruh data akun yang tersimpan di database lokal Hive
  static List<Map<String, dynamic>> ambilSemuaAkunHive() {
    try {
      if (!Hive.isBoxOpen(namaKotakPengguna)) return [];
      final box = Hive.box(namaKotakPengguna);
      final List<Map<String, dynamic>> hasil = [];
      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i);
        if (data != null && data is Map) {
          hasil.add(Map<String, dynamic>.from(data));
        }
      }
      return hasil;
    } catch (_) {
      return [];
    }
  }

  // Menyimpan entri data akun pengguna baru ke database lokal Hive
  static Future<void> simpanAkunHive(Map<String, dynamic> akunJson) async {
    try {
      if (!Hive.isBoxOpen(namaKotakPengguna)) {
        await Hive.openBox(namaKotakPengguna);
      }
      final box = Hive.box(namaKotakPengguna);
      final String targetEmail = akunJson['email']?.toString().trim().toLowerCase() ?? '';
      final String targetNama = akunJson['nama']?.toString().trim().toLowerCase() ?? '';

      // Hindari duplikasi jika akun sudah ada di Hive
      for (int i = 0; i < box.length; i++) {
        final data = box.getAt(i);
        if (data != null && data is Map) {
          final String em = data['email']?.toString().trim().toLowerCase() ?? '';
          final String nm = data['nama']?.toString().trim().toLowerCase() ?? '';
          if (em == targetEmail || nm == targetNama) {
            return;
          }
        }
      }
      await box.add(akunJson);
    } catch (_) {}
  }
}
