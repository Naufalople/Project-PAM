import '../model/model_barang_jastip.dart';

// Hasil Pemindaian AI (Google Lens Scanner)
class HasilPemindaianAi {
  final String namaProduk;
  final String kategori;
  final String negaraAsal;
  final String kodeMataUang;
  final double estimasiHargaAsli;
  final int estimasiHargaIdr;
  final String deskripsi;
  final double tingkatKeyakinan; // Confidence score (0.0 - 1.0)
  final String rekomendasiToko;

  HasilPemindaianAi({
    required this.namaProduk,
    required this.kategori,
    required this.negaraAsal,
    required this.kodeMataUang,
    required this.estimasiHargaAsli,
    required this.estimasiHargaIdr,
    required this.deskripsi,
    required this.tingkatKeyakinan,
    required this.rekomendasiToko,
  });
}

// Layanan Cerdas AI: Google Lens Vision Scanner & LLM Chatbot Asisten Jastip
class LayananAi {
  // ========================================================
  // 1. AI VISUAL SCANNER (ALA GOOGLE LENS PENDETEKSI BARANG)
  // ========================================================

  // Database referensi cerdas untuk pencocokan visual barang mancanegara
  static final List<HasilPemindaianAi> _basisPengetahuanVisual = [
    HasilPemindaianAi(
      namaProduk: 'Tokyo Banana Classic Box',
      kategori: 'Kuliner',
      negaraAsal: 'Jepang',
      kodeMataUang: 'JPY',
      estimasiHargaAsli: 1200.0,
      estimasiHargaIdr: 135000,
      deskripsi: 'Kue spons pisang populer isi krim custard pisang asli dari Tokyo.',
      tingkatKeyakinan: 0.96,
      rekomendasiToko: 'Tokyo Station / Haneda Airport',
    ),
    HasilPemindaianAi(
      namaProduk: 'Hada Labo Gokujyun Premium Lotion',
      kategori: 'Skincare',
      negaraAsal: 'Jepang',
      kodeMataUang: 'JPY',
      estimasiHargaAsli: 990.0,
      estimasiHargaIdr: 110000,
      deskripsi: 'Lotion pelembab kulit dengan 7 jenis Hyaluronic Acid asal Osaka.',
      tingkatKeyakinan: 0.94,
      rekomendasiToko: 'Don Quijote / Matsumoto Kiyoshi',
    ),
    HasilPemindaianAi(
      namaProduk: 'COSRX Snail Mucin 96 Essence',
      kategori: 'Skincare',
      negaraAsal: 'Korea Selatan',
      kodeMataUang: 'KRW',
      estimasiHargaAsli: 18000.0,
      estimasiHargaIdr: 210000,
      deskripsi: 'Essence perawatan kulit wajah kaya snail secretion filtrate.',
      tingkatKeyakinan: 0.95,
      rekomendasiToko: 'Olive Young Myeongdong, Seoul',
    ),
    HasilPemindaianAi(
      namaProduk: 'Album K-Pop BTS - Proof',
      kategori: 'Hobi & Anime',
      negaraAsal: 'Korea Selatan',
      kodeMataUang: 'KRW',
      estimasiHargaAsli: 65000.0,
      estimasiHargaIdr: 760000,
      deskripsi: 'Album fisik resmi K-Pop dengan photobook dan postcard kolektor.',
      tingkatKeyakinan: 0.98,
      rekomendasiToko: 'K-Town4U Gangnam / Withmuu',
    ),
    HasilPemindaianAi(
      namaProduk: 'Harrods Green Shopper Bag',
      kategori: 'Fashion',
      negaraAsal: 'London (UK)',
      kodeMataUang: 'GBP',
      estimasiHargaAsli: 35.0,
      estimasiHargaIdr: 720000,
      deskripsi: 'Tas belanja bahan tebal tahan air warna hijau khas Harrods London.',
      tingkatKeyakinan: 0.97,
      rekomendasiToko: 'Harrods Knightsbridge, London',
    ),
    HasilPemindaianAi(
      namaProduk: 'Twinings English Breakfast Tea Tin',
      kategori: 'Kuliner',
      negaraAsal: 'London (UK)',
      kodeMataUang: 'GBP',
      estimasiHargaAsli: 8.5,
      estimasiHargaIdr: 175000,
      deskripsi: 'Kaleng vintage teh hitam racikan bangsawan Inggris abad ke-18.',
      tingkatKeyakinan: 0.93,
      rekomendasiToko: 'Fortnum & Mason / Tesco London',
    ),
    HasilPemindaianAi(
      namaProduk: 'Irvins Salted Egg Potato Chips',
      kategori: 'Kuliner',
      negaraAsal: 'Singapura',
      kodeMataUang: 'SGD',
      estimasiHargaAsli: 8.8,
      estimasiHargaIdr: 105000,
      deskripsi: 'Keripik kentang saus telur asin khas Singapura dengan daun kari.',
      tingkatKeyakinan: 0.95,
      rekomendasiToko: 'Changi Airport Jewel / Takashimaya',
    ),
    HasilPemindaianAi(
      namaProduk: 'Pop Mart Skullpanda Blindbox',
      kategori: 'Hobi & Anime',
      negaraAsal: 'China',
      kodeMataUang: 'CNY',
      estimasiHargaAsli: 69.0,
      estimasiHargaIdr: 155000,
      deskripsi: 'Art toy desainer edisi terbatas dari flagship store Shanghai.',
      tingkatKeyakinan: 0.96,
      rekomendasiToko: 'Pop Mart Global Flagship Shanghai',
    ),
  ];

  // Fungsi Pindai Gambar Menggunakan Mesin Cerdas
  static Future<HasilPemindaianAi> pindaiGambarProduk({int presetIndeks = 0}) async {
    // Simulasi waktu komputasi pemrosesan citra AI
    await Future.delayed(const Duration(milliseconds: 1200));

    // Pilih hasil deteksi dari basis pengetahuan
    final indeksAman = presetIndeks % _basisPengetahuanVisual.length;
    return _basisPengetahuanVisual[indeksAman];
  }

  // Fungsi Pindai Gambar dari Kamera atau Galeri Menggunakan Mesin Cerdas
  static Future<HasilPemindaianAi> pindaiGambarKamera({
    String? namaFileAtauPath,
    int presetIndeks = 0,
  }) async {
    // Simulasi jeda waktu pemrosesan Computer Vision AI
    await Future.delayed(const Duration(milliseconds: 1400));

    if (namaFileAtauPath != null && namaFileAtauPath.isNotEmpty) {
      final namaLower = namaFileAtauPath.toLowerCase();
      for (var item in _basisPengetahuanVisual) {
        if (namaLower.contains(item.namaProduk.toLowerCase()) ||
            namaLower.contains(item.kategori.toLowerCase()) ||
            namaLower.contains(item.negaraAsal.toLowerCase())) {
          return item;
        }
      }
      // Heuristik hash deterministik agar hasil kamera konsisten
      final int hash = namaFileAtauPath.hashCode.abs() % _basisPengetahuanVisual.length;
      return _basisPengetahuanVisual[hash];
    }

    final indeksAman = presetIndeks % _basisPengetahuanVisual.length;
    return _basisPengetahuanVisual[indeksAman];
  }

  // Buat objek ModelBarangJastip dari hasil pemindaian AI
  static ModelBarangJastip konversiKeBarangJastip(HasilPemindaianAi hasil, String fotoUrl) {
    String bendera = '🌏';
    if (hasil.negaraAsal.contains('Jepang')) bendera = '🇯🇵';
    if (hasil.negaraAsal.contains('Korea')) bendera = '🇰🇷';
    if (hasil.negaraAsal.contains('London')) bendera = '🇬🇧';
    if (hasil.negaraAsal.contains('Singapura')) bendera = '🇸🇬';
    if (hasil.negaraAsal.contains('China')) bendera = '🇨🇳';

    return ModelBarangJastip(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      namaBarang: hasil.namaProduk,
      kategori: hasil.kategori,
      negara: hasil.negaraAsal,
      benderaNegara: bendera,
      kodeMataUang: hasil.kodeMataUang,
      hargaAsli: hasil.estimasiHargaAsli,
      estimasiHargaIdr: hasil.estimasiHargaIdr,
      fotoUrl: fotoUrl.isNotEmpty ? fotoUrl : 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500',
      deskripsi: hasil.deskripsi,
      namaToko: hasil.rekomendasiToko,
      batasWaktuPo: 'Request Khusus AI (Tersedia)',
      rating: 5.0,
      jumlahPeminat: 1,
    );
  }

  // ========================================================
  // 2. LLM CHATBOT (ASISTEN PINTAR JASTIP & REGULASI KOPER)
  // ========================================================

  // Logika inferensi percakapan kontekstual LLM
  static Future<String> prosesPesanChatbot(String pertanyaan) async {
    // Simulasi jeda berpikir LLM
    await Future.delayed(const Duration(milliseconds: 800));

    final q = pertanyaan.toLowerCase();

    if (q.contains('bea cukai') || q.contains('pajak') || q.contains('aturan')) {
      return '📋 **Aturan Bea Cukai Impor Barang Penumpang:**\n'
          'Sesuai PMK 203/2017, batas pembebasan bea masuk barang bawaan pribadi adalah **FOB USD 500 per orang**. '
          'Jika total belanjaan jastip Anda melebihi USD 500, kelebihannya akan dikenakan tarif bea masuk flat 10% + PPN 11%. Pastikan traveler selalu menyimpan struk resmi ya!';
    } else if (q.contains('imei') || q.contains('hp') || q.contains('iphone')) {
      return '📱 **Aturan Pendaftaran IMEI Gadget:**\n'
          'Untuk gadget/HP dari luar negeri (seperti iPhone atau Android), traveler wajib mendaftarkan IMEI di pos Bea Cukai bandara kedatangan. '
          'HP dengan harga di bawah USD 500 bebas pajak, sedangkan di atas USD 500 dikenakan PPh dan PPN.';
    } else if (q.contains('jepang') || q.contains('tokyo')) {
      return '🇯🇵 **Rekomendasi Oleh-Oleh Populer Jepang:**\n'
          '1. **Kuliner:** Tokyo Banana, Shiroi Koibito, KitKat rasa Matcha Uji.\n'
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
    } else if (q.contains('kurs') || q.contains('uang') || q.contains('harga')) {
      return '💱 **Kurs Mata Uang Asing Hari Ini:**\n'
          '• 1 JPY (Yen Jepang) = Rp 112.5\n'
          '• 1 KRW (Won Korea) = Rp 11.8\n'
          '• 1 GBP (Pound London) = Rp 20.600\n'
          '• 1 SGD (Dolar Singapura) = Rp 11.950\n'
          '• 1 CNY (Yuan China) = Rp 2.230\n'
          'Anda bisa menggunakan menu **Kalkulator Kurs** di tab Fitur Cerdas untuk kalkulasi instan!';
    } else if (q.contains('cara titip') || q.contains('pesan') || q.contains('order')) {
      return '🛒 **Cara Menitip Barang di JastipGo:**\n'
          '1. Pilih barang dari katalog Open PO atau gunakan fitur **Scan Foto AI (Google Lens)** untuk mencari produk dari foto.\n'
          '2. Masukkan ke Keranjang Belanja.\n'
          '3. Lakukan konfirmasi pembayaran dengan sidik jari.\n'
          '4. Struk dan bukti pembelian Anda akan dienkripsi ke dalam **Blockchain** agar terjamin 100% original!';
    } else {
      return 'Halo! Saya **Asisten Cerdas JastipGo** 🤖\n'
          'Saya siap membantu Anda seputar:\n'
          '• Aturan bea cukai & batas koper belanjaan luar negeri.\n'
          '• Rekomendasi oleh-oleh terbaik dari Jepang, Korea, London, & Singapura.\n'
          '• Cek kurs mata uang asing dan zona waktu toko internasional.\n'
          'Ada yang bisa saya bantu untuk rencana titipan Anda?';
    }
  }
}
