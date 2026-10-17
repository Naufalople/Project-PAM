import '../model/model_barang_jastip.dart';

// Layanan API dan Katalog Jastip Mancanegara (Online Data Service)
class LayananApi {
  // Daftar negara singgah yang didukung aplikasi
  static const List<Map<String, String>> daftarNegaraSinggah = [
    {'nama': 'Semua', 'bendera': '🌏', 'kode': 'ALL', 'mataUang': 'IDR'},
    {'nama': 'Jepang', 'bendera': '🇯🇵', 'kode': 'JP', 'mataUang': 'JPY'},
    {'nama': 'Korea Selatan', 'bendera': '🇰🇷', 'kode': 'KR', 'mataUang': 'KRW'},
    {'nama': 'London (UK)', 'bendera': '🇬🇧', 'kode': 'GB', 'mataUang': 'GBP'},
    {'nama': 'Singapura', 'bendera': '🇸🇬', 'kode': 'SG', 'mataUang': 'SGD'},
    {'nama': 'China', 'bendera': '🇨🇳', 'kode': 'CN', 'mataUang': 'CNY'},
  ];

  // Data awal barang-barang jastip autentik dari berbagai negara
  static final List<ModelBarangJastip> _daftarBarangJastip = [
    // === JEPANG ===
    ModelBarangJastip(
      id: 1,
      namaBarang: 'Tokyo Banana Classic Box (8 Pcs)',
      kategori: 'Kuliner',
      negara: 'Jepang',
      benderaNegara: '🇯🇵',
      kodeMataUang: 'JPY',
      hargaAsli: 1200.0,
      estimasiHargaIdr: 135000,
      fotoUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500',
      deskripsi: 'Kue spons pisang legendaris dari stasiun Tokyo. Sangat lembut dengan krim pisang asli.',
      namaToko: 'Tokyo Station Souvenir Center',
      batasWaktuPo: '2 Hari Lagi (18:00 JST)',
      rating: 4.9,
      jumlahPeminat: 142,
    ),
    ModelBarangJastip(
      id: 2,
      namaBarang: 'Hada Labo Gokujyun Premium Lotion 170ml',
      kategori: 'Skincare',
      negara: 'Jepang',
      benderaNegara: '🇯🇵',
      kodeMataUang: 'JPY',
      hargaAsli: 990.0,
      estimasiHargaIdr: 110000,
      fotoUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
      deskripsi: 'Hydrating lotion dengan 7 tipe Hyaluronic Acid. Sangat melembabkan kulit kering.',
      namaToko: 'Don Quijote Shinjuku',
      batasWaktuPo: '2 Hari Lagi (20:00 JST)',
      rating: 4.8,
      jumlahPeminat: 98,
    ),
    ModelBarangJastip(
      id: 3,
      namaBarang: 'Gundam RG 1/144 RX-78-2 Ver 2.0',
      kategori: 'Hobi & Anime',
      negara: 'Jepang',
      benderaNegara: '🇯🇵',
      kodeMataUang: 'JPY',
      hargaAsli: 3850.0,
      estimasiHargaIdr: 430000,
      fotoUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500',
      deskripsi: 'Model kit gunpla original dari Odaiba Gundam Base dengan artikulasi realistis.',
      namaToko: 'The Gundam Base Tokyo',
      batasWaktuPo: 'Besok (15:00 JST)',
      rating: 5.0,
      jumlahPeminat: 215,
    ),

    // === KOREA SELATAN ===
    ModelBarangJastip(
      id: 4,
      namaBarang: 'COSRX Snail Mucin 96 Essence 100ml',
      kategori: 'Skincare',
      negara: 'Korea Selatan',
      benderaNegara: '🇰🇷',
      kodeMataUang: 'KRW',
      hargaAsli: 18000.0,
      estimasiHargaIdr: 210000,
      fotoUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=500',
      deskripsi: 'Essence lendir siput viral untuk mencerahkan dan memperbaiki skin barrier.',
      namaToko: 'Olive Young Myeongdong',
      batasWaktuPo: '3 Hari Lagi (21:00 KST)',
      rating: 4.9,
      jumlahPeminat: 180,
    ),
    ModelBarangJastip(
      id: 5,
      namaBarang: 'Album K-Pop BTS - Proof (Standard Edition)',
      kategori: 'Hobi & Anime',
      negara: 'Korea Selatan',
      benderaNegara: '🇰🇷',
      kodeMataUang: 'KRW',
      hargaAsli: 65000.0,
      estimasiHargaIdr: 760000,
      fotoUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
      deskripsi: 'Album antologi resmi lengkap dengan photobook dan postcard eksklusif Weverse.',
      namaToko: 'K-Town4U Gangnam',
      batasWaktuPo: 'Besok (19:00 KST)',
      rating: 5.0,
      jumlahPeminat: 310,
    ),

    // === LONDON (UK) ===
    ModelBarangJastip(
      id: 6,
      namaBarang: 'Harrods Signature Green Shopper Bag',
      kategori: 'Fashion',
      negara: 'London (UK)',
      benderaNegara: '🇬🇧',
      kodeMataUang: 'GBP',
      hargaAsli: 35.0,
      estimasiHargaIdr: 720000,
      fotoUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
      deskripsi: 'Tas belanja ikonik Harrods Knightsbridge London. Bahan tebal tahan air.',
      namaToko: 'Harrods Knightsbridge London',
      batasWaktuPo: 'Hari Ini (18:00 GMT)',
      rating: 4.9,
      jumlahPeminat: 88,
    ),
    ModelBarangJastip(
      id: 7,
      namaBarang: 'Twinings English Breakfast Tea Tin 100g',
      kategori: 'Kuliner',
      negara: 'London (UK)',
      benderaNegara: '🇬🇧',
      kodeMataUang: 'GBP',
      hargaAsli: 8.5,
      estimasiHargaIdr: 175000,
      fotoUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
      deskripsi: 'Teh hitam klasik khas sarapan keluarga bangsawan Inggris dalam kaleng vintage.',
      namaToko: 'Fortnum & Mason Piccadilly',
      batasWaktuPo: 'Besok (16:00 GMT)',
      rating: 4.8,
      jumlahPeminat: 64,
    ),
    ModelBarangJastip(
      id: 8,
      namaBarang: 'Jo Malone Wood Sage & Sea Salt Cologne 30ml',
      kategori: 'Fashion',
      negara: 'London (UK)',
      benderaNegara: '🇬🇧',
      kodeMataUang: 'GBP',
      hargaAsli: 58.0,
      estimasiHargaIdr: 1190000,
      fotoUrl: 'https://images.unsplash.com/photo-1523293182086-7651a899d37f?w=500',
      deskripsi: 'Parfum aromatik segar dengan nuansa pantai pesisir tebing laut Inggris.',
      namaToko: 'Covent Garden Boutique',
      batasWaktuPo: '3 Hari Lagi (17:00 GMT)',
      rating: 4.9,
      jumlahPeminat: 112,
    ),

    // === SINGAPURA ===
    ModelBarangJastip(
      id: 9,
      namaBarang: 'Irvins Salted Egg Potato Chips 105g',
      kategori: 'Kuliner',
      negara: 'Singapura',
      benderaNegara: '🇸🇬',
      kodeMataUang: 'SGD',
      hargaAsli: 8.8,
      estimasiHargaIdr: 105000,
      fotoUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500',
      deskripsi: 'Keripik kentang telur asin paling viral di Singapura. Gurih dan renyah.',
      namaToko: 'Changi Airport Terminal 3',
      batasWaktuPo: 'Hari Ini (22:00 SGT)',
      rating: 4.8,
      jumlahPeminat: 156,
    ),
    ModelBarangJastip(
      id: 10,
      namaBarang: 'Charles & Keith Gabine Saddle Bag',
      kategori: 'Fashion',
      negara: 'Singapura',
      benderaNegara: '🇸🇬',
      kodeMataUang: 'SGD',
      hargaAsli: 79.0,
      estimasiHargaIdr: 940000,
      fotoUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=500',
      deskripsi: 'Tas selempang elegan dengan aksen buckle emas khas Orchard Road.',
      namaToko: 'ION Orchard Flagship Store',
      batasWaktuPo: 'Besok (21:00 SGT)',
      rating: 4.9,
      jumlahPeminat: 140,
    ),

    // === CHINA ===
    ModelBarangJastip(
      id: 11,
      namaBarang: 'Pop Mart Skullpanda The Warmth Series Blindbox',
      kategori: 'Hobi & Anime',
      negara: 'China',
      benderaNegara: '🇨🇳',
      kodeMataUang: 'CNY',
      hargaAsli: 69.0,
      estimasiHargaIdr: 155000,
      fotoUrl: 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=500',
      deskripsi: 'Blind box art toy original Pop Mart edisi eksklusif Shanghai.',
      namaToko: 'Pop Mart Global Flagship Shanghai',
      batasWaktuPo: '3 Hari Lagi (20:00 CST)',
      rating: 5.0,
      jumlahPeminat: 275,
    ),
  ];

  // Ambil semua daftar barang jastip
  static Future<List<ModelBarangJastip>> ambilSemuaBarang() async {
    // Simulasi jeda network seperti memanggil REST API
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_daftarBarangJastip);
  }

  // Filter barang berdasarkan negara singgah dan kategori
  static Future<List<ModelBarangJastip>> filterBarang({
    String negara = 'Semua',
    String kategori = 'Semua',
    String kataKunci = '',
    String urutanHarga = 'Normal', // 'Termurah', 'Termahal', 'Populer'
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    List<ModelBarangJastip> hasil = List.from(_daftarBarangJastip);

    // 1. Filter Negara
    if (negara != 'Semua') {
      hasil = hasil.where((b) => b.negara.toLowerCase().contains(negara.toLowerCase())).toList();
    }

    // 2. Filter Kategori
    if (kategori != 'Semua') {
      hasil = hasil.where((b) => b.kategori.toLowerCase() == kategori.toLowerCase()).toList();
    }

    // 3. Filter Kata Kunci Pencarian
    if (kataKunci.trim().isNotEmpty) {
      hasil = hasil.where((b) {
        return b.namaBarang.toLowerCase().contains(kataKunci.toLowerCase()) ||
            b.deskripsi.toLowerCase().contains(kataKunci.toLowerCase()) ||
            b.namaToko.toLowerCase().contains(kataKunci.toLowerCase());
      }).toList();
    }

    // 4. Urutan
    if (urutanHarga == 'Termurah') {
      hasil.sort((a, b) => a.estimasiHargaIdr.compareTo(b.estimasiHargaIdr));
    } else if (urutanHarga == 'Termahal') {
      hasil.sort((a, b) => b.estimasiHargaIdr.compareTo(a.estimasiHargaIdr));
    } else if (urutanHarga == 'Populer') {
      hasil.sort((a, b) => b.jumlahPeminat.compareTo(a.jumlahPeminat));
    }

    return hasil;
  }

  // Tambah Barang Jastip Baru (Hasil Request Foto AI atau Input Pengguna)
  static Future<void> tambahBarangJastip(ModelBarangJastip barangBaru) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _daftarBarangJastip.insert(0, barangBaru);
  }
}
