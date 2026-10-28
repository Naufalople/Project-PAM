import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/model_barang_jastip.dart';
import 'layanan_basisdata_lokal.dart';

// Layanan API dan Katalog Jastip Mancanegara (Dynamic REST API & Hive Local Database)
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

  // Endpoint REST API Online untuk katalog produk jastip mancanegara
  static const String _urlKatalogApi = 'https://api.restful-api.dev/objects/ff808181a09d98f701a153a5bf76178b';

  // Seed data awal untuk inisialisasi basis data lokal Hive jika masih kosong
  static List<ModelBarangJastip> buatKatalogAwalDatabase() {
    return [
      ModelBarangJastip(
        id: 1,
        namaBarang: 'Action Figure Naruto Shippuden - Uzumaki Naruto Sage Mode (Grandista)',
        kategori: 'Hobi & Anime',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 3500.0,
        estimasiHargaIdr: 400000,
        fotoUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500',
        deskripsi: 'Action figure Naruto Uzumaki Sage Mode original Grandista Banpresto. Detail jubah oranye dan mata katak sangat presisi.',
        namaToko: 'Akihabara Radio Kaikan, Tokyo',
        batasWaktuPo: 'Besok (18:00 JST)',
        rating: 4.9,
        jumlahPeminat: 185,
      ),
      ModelBarangJastip(
        id: 2,
        namaBarang: 'Tokyo Banana Classic Custard Sponge Cake (Box 8 Pcs)',
        kategori: 'Kuliner',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 1200.0,
        estimasiHargaIdr: 135000,
        fotoUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500',
        deskripsi: 'Kue bolu pisang legendaris khas stasiun Tokyo. Tekstur spons lembut dengan isian pure pisang asli.',
        namaToko: 'Tokyo Station Souvenir Center',
        batasWaktuPo: 'Besok (16:00 JST)',
        rating: 4.9,
        jumlahPeminat: 210,
      ),
      ModelBarangJastip(
        id: 3,
        namaBarang: 'Gunpla RG 1/144 RX-78-2 Gundam Ver 2.0 Bandai',
        kategori: 'Hobi & Anime',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 3850.0,
        estimasiHargaIdr: 440000,
        fotoUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=500',
        deskripsi: 'Real Grade RX-78-2 Ver 2.0 terbaru dengan inner frame mutakhir dan artikulasi realistis dari Odaiba Gundam Base.',
        namaToko: 'The Gundam Base Tokyo (Odaiba)',
        batasWaktuPo: '2 Hari Lagi (15:00 JST)',
        rating: 5.0,
        jumlahPeminat: 175,
      ),
      ModelBarangJastip(
        id: 4,
        namaBarang: 'Hada Labo Gokujyun Premium Hyaluronic Acid Lotion 170ml',
        kategori: 'Skincare',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 990.0,
        estimasiHargaIdr: 115000,
        fotoUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
        deskripsi: 'Hydrating lotion Jepang terlaris dengan 7 jenis Hyaluronic Acid untuk mengunci kelembapan kulit secara intens.',
        namaToko: 'Don Quijote Shinjuku, Tokyo',
        batasWaktuPo: '2 Hari Lagi (20:00 JST)',
        rating: 4.8,
        jumlahPeminat: 140,
      ),
      ModelBarangJastip(
        id: 5,
        namaBarang: 'Nendoroid Gojo Satoru Jujutsu Kaisen (Good Smile Company)',
        kategori: 'Hobi & Anime',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 5800.0,
        estimasiHargaIdr: 660000,
        fotoUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=500',
        deskripsi: 'Figure Nendoroid Gojo Satoru dengan part mata terbuka dan blindfold penutup mata alternatif.',
        namaToko: 'AmiAmi Akihabara Flagship',
        batasWaktuPo: '3 Hari Lagi (19:00 JST)',
        rating: 5.0,
        jumlahPeminat: 310,
      ),
      ModelBarangJastip(
        id: 6,
        namaBarang: 'SK-II Facial Treatment Essence Pitera 230ml',
        kategori: 'Skincare',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 26000.0,
        estimasiHargaIdr: 2950000,
        fotoUrl: 'https://images.unsplash.com/photo-1608248597359-21b9338f0d86?w=500',
        deskripsi: 'Miracle water kultus asal Jepang berkandungan 90%+ Pitera untuk meremajakan dan mencerahkan kulit.',
        namaToko: 'Ginza Mitsukoshi Department Store',
        batasWaktuPo: '3 Hari Lagi (17:00 JST)',
        rating: 4.9,
        jumlahPeminat: 95,
      ),
      ModelBarangJastip(
        id: 7,
        namaBarang: 'BAPE (A Bathing Ape) Classic College Ape Head Tee',
        kategori: 'Fashion',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 9900.0,
        estimasiHargaIdr: 1130000,
        fotoUrl: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500',
        deskripsi: 'Kaos streetwear legendaris BAPE Harajuku dengan sablon grafis ikonik Ape Head 100% cotton original.',
        namaToko: 'BAPE Store Harajuku, Tokyo',
        batasWaktuPo: '2 Hari Lagi (21:00 JST)',
        rating: 4.8,
        jumlahPeminat: 160,
      ),
      ModelBarangJastip(
        id: 8,
        namaBarang: 'Onitsuka Tiger Mexico 66 Classic White Blue Red',
        kategori: 'Fashion',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 14300.0,
        estimasiHargaIdr: 1630000,
        fotoUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
        deskripsi: 'Sneakers retro klasik Onitsuka Tiger berbahan kulit premium dengan garis khas biru-merah ikonik.',
        namaToko: 'Onitsuka Tiger Shibuya Official',
        batasWaktuPo: 'Besok (19:00 JST)',
        rating: 4.9,
        jumlahPeminat: 230,
      ),
      ModelBarangJastip(
        id: 9,
        namaBarang: 'Royce\' Nama Chocolate Champagne Pierre Mignon (Hokkaido)',
        kategori: 'Kuliner',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 860.0,
        estimasiHargaIdr: 100000,
        fotoUrl: 'https://images.unsplash.com/photo-1548907040-4baa42d10919?w=500',
        deskripsi: 'Cokelat lumer khas Hokkaido dengan aroma champagne berpadu krim segar premium. Disertakan ice gel pack.',
        namaToko: 'Narita Airport Duty Free Terminal 1',
        batasWaktuPo: 'Besok (20:00 JST)',
        rating: 4.9,
        jumlahPeminat: 180,
      ),
      ModelBarangJastip(
        id: 10,
        namaBarang: 'Matcha Ceremonial Grade Uji Kyoto Marukyu Koyamaen (40g)',
        kategori: 'Kuliner',
        negara: 'Jepang',
        benderaNegara: '🇯🇵',
        kodeMataUang: 'JPY',
        hargaAsli: 2200.0,
        estimasiHargaIdr: 250000,
        fotoUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
        deskripsi: 'Bubuk teh hijau matcha kualitas seremonial kuil Uji Kyoto. Rasa umami pekat tanpa aftertaste pahit.',
        namaToko: 'Marukyu Koyamaen Kyoto Main Shop',
        batasWaktuPo: '2 Hari Lagi (14:00 JST)',
        rating: 5.0,
        jumlahPeminat: 135,
      ),
      ModelBarangJastip(
        id: 11,
        namaBarang: 'Komik Manhwa Solo Leveling Vol 1-3 Box Set (Korean Edition)',
        kategori: 'Hobi & Anime',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 45000.0,
        estimasiHargaIdr: 530000,
        fotoUrl: 'https://images.unsplash.com/photo-1618519764620-7403abdbdfe9?w=500',
        deskripsi: 'Paket komik manhwa Solo Leveling volume 1 hingga 3 original bahasa Korea, cetakan tebal full color dengan bonus bookmark eksklusif Sung Jin-Woo.',
        namaToko: 'Kyobo Book Centre Gwanghwamun, Seoul',
        batasWaktuPo: 'Besok (20:00 KST)',
        rating: 5.0,
        jumlahPeminat: 290,
      ),
      ModelBarangJastip(
        id: 12,
        namaBarang: 'COSRX Advanced Snail 96 Mucin Power Essence 100ml',
        kategori: 'Skincare',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 18000.0,
        estimasiHargaIdr: 215000,
        fotoUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=500',
        deskripsi: 'Essence lendir siput 96% terlaris untuk menenangkan kemerahan, memperbaiki skin barrier, dan memberi hidrasi mendalam.',
        namaToko: 'Olive Young Myeongdong Flagship, Seoul',
        batasWaktuPo: '2 Hari Lagi (21:00 KST)',
        rating: 4.9,
        jumlahPeminat: 195,
      ),
      ModelBarangJastip(
        id: 13,
        namaBarang: 'Beauty of Joseon Relief Sun Rice + Probiotics SPF50+ (50ml)',
        kategori: 'Skincare',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 15000.0,
        estimasiHargaIdr: 180000,
        fotoUrl: 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=500',
        deskripsi: 'Sunscreen organik viral Korea dengan ekstrak beras dan fermentasi gandum. Tekstur ringan tidak lengket tanpa white cast.',
        namaToko: 'Olive Young Hongdae, Seoul',
        batasWaktuPo: '2 Hari Lagi (19:00 KST)',
        rating: 4.8,
        jumlahPeminat: 215,
      ),
      ModelBarangJastip(
        id: 14,
        namaBarang: 'Album K-Pop BTS - Proof (Standard Edition) Weverse Official',
        kategori: 'Hobi & Anime',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 65000.0,
        estimasiHargaIdr: 770000,
        fotoUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
        deskripsi: 'Album kompilasi antologi resmi BTS lengkap dengan 3 CD, photo book tebal, art card eksklusif, dan photocard acak.',
        namaToko: 'K-Town4U Gangnam COEX, Seoul',
        batasWaktuPo: 'Besok (18:00 KST)',
        rating: 5.0,
        jumlahPeminat: 340,
      ),
      ModelBarangJastip(
        id: 15,
        namaBarang: 'Album NewJeans \'Get Up\' The 2nd EP Bunny Beach Bag Ver',
        kategori: 'Hobi & Anime',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 28000.0,
        estimasiHargaIdr: 330000,
        fotoUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
        deskripsi: 'Album resmi NewJeans kemasan tas pantai bunny transparan, lengkap dengan postcard, photo book retro, dan sticker pack.',
        namaToko: 'Withmuu AK Plaza Hongdae, Seoul',
        batasWaktuPo: '2 Hari Lagi (17:00 KST)',
        rating: 4.9,
        jumlahPeminat: 220,
      ),
      ModelBarangJastip(
        id: 16,
        namaBarang: 'Gentle Monster Sunglasses - Her 01 Black Frame',
        kategori: 'Fashion',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 280000.0,
        estimasiHargaIdr: 3300000,
        fotoUrl: 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500',
        deskripsi: 'Kacamata hitam desainer asal Seoul berbingkai kotak oversized yang dipakai artis drama Korea. Dilengkapi hardcase dan kartu autentisitas.',
        namaToko: 'Haus Dosan Gentle Monster Sinsa-dong',
        batasWaktuPo: '3 Hari Lagi (20:00 KST)',
        rating: 4.9,
        jumlahPeminat: 110,
      ),
      ModelBarangJastip(
        id: 17,
        namaBarang: 'Mardi Mercredi T-Shirt Flower Mardi White Green',
        kategori: 'Fashion',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 42000.0,
        estimasiHargaIdr: 495000,
        fotoUrl: 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=500',
        deskripsi: 'Kaos kasual oversized brand trendi Hannam-dong dengan sablon bunga daisy khas Mardi Mercredi.',
        namaToko: 'Mardi Mercredi Hannam Showroom, Seoul',
        batasWaktuPo: 'Besok (20:00 KST)',
        rating: 4.7,
        jumlahPeminat: 175,
      ),
      ModelBarangJastip(
        id: 18,
        namaBarang: 'Torriden DIVE-IN Low Molecular Hyaluronic Acid Serum 50ml',
        kategori: 'Skincare',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 22000.0,
        estimasiHargaIdr: 260000,
        fotoUrl: 'https://images.unsplash.com/photo-1608248597359-21b9338f0d86?w=500',
        deskripsi: 'Serum hidrasi pemenang Olive Young Awards nomor satu dengan formula asam hialuronat molekul mikro pastel blue.',
        namaToko: 'Olive Young Gangnam Station, Seoul',
        batasWaktuPo: '2 Hari Lagi (21:00 KST)',
        rating: 4.9,
        jumlahPeminat: 160,
      ),
      ModelBarangJastip(
        id: 19,
        namaBarang: 'Market O Real Brownie Box (8 Pcs) Original Choco',
        kategori: 'Kuliner',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 6500.0,
        estimasiHargaIdr: 78000,
        fotoUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500',
        deskripsi: 'Kue fudge brownie cokelat padat legendaris khas supermarket Korea tanpa bahan pengawet artifisial.',
        namaToko: 'Lotte Mart Seoul Station',
        batasWaktuPo: 'Besok (19:00 KST)',
        rating: 4.8,
        jumlahPeminat: 130,
      ),
      ModelBarangJastip(
        id: 20,
        namaBarang: 'Samyang Buldak Extra Spicy Hot Chicken Sauce Bottle 200g',
        kategori: 'Kuliner',
        negara: 'Korea Selatan',
        benderaNegara: '🇰🇷',
        kodeMataUang: 'KRW',
        hargaAsli: 4800.0,
        estimasiHargaIdr: 57000,
        fotoUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
        deskripsi: 'Saus pedas botolan bumbu mi samyang original Korea, cocok untuk cocolan gorengan dan marinasi daging.',
        namaToko: 'Emart Cheonggyecheon, Seoul',
        batasWaktuPo: 'Besok (21:00 KST)',
        rating: 4.8,
        jumlahPeminat: 155,
      ),
      ModelBarangJastip(
        id: 21,
        namaBarang: 'Novel Lord of the Mysteries (LOTM) Physical Collector Book Set',
        kategori: 'Hobi & Anime',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 168.0,
        estimasiHargaIdr: 375000,
        fotoUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500',
        deskripsi: 'Buku novel fisik Lord of the Mysteries (Guimi Zhi Zhu) karya Cuttlefish That Loves Diving edisi hardcover berbonus tarot card Klein Moretti.',
        namaToko: 'Shanghai Book Mall (Fuzhou Road), Shanghai',
        batasWaktuPo: '3 Hari Lagi (19:00 CST)',
        rating: 5.0,
        jumlahPeminat: 380,
      ),
      ModelBarangJastip(
        id: 22,
        namaBarang: 'Pop Mart Skullpanda The Warmth Series Blind Box Official',
        kategori: 'Hobi & Anime',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 69.0,
        estimasiHargaIdr: 155000,
        fotoUrl: 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=500',
        deskripsi: 'Blind box art toy original Pop Mart seri Skullpanda The Warmth edisi asli Shanghai Flagship store.',
        namaToko: 'Pop Mart Global Flagship East Nanjing Rd, Shanghai',
        batasWaktuPo: '2 Hari Lagi (20:00 CST)',
        rating: 5.0,
        jumlahPeminat: 285,
      ),
      ModelBarangJastip(
        id: 23,
        namaBarang: 'Genshin Impact Official Figure Zhongli - Heart of the Bedrock',
        kategori: 'Hobi & Anime',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 899.0,
        estimasiHargaIdr: 2000000,
        fotoUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500',
        deskripsi: 'Skala figure resmi Genshin Impact karakter Geo Archon Zhongli pose pilar batu dengan efek resin transparan.',
        namaToko: 'miHoYo Official Store, Shanghai',
        batasWaktuPo: '4 Hari Lagi (18:00 CST)',
        rating: 5.0,
        jumlahPeminat: 410,
      ),
      ModelBarangJastip(
        id: 24,
        namaBarang: 'Feiyue Classic Wushu Canvas Shoes White Red/Blue',
        kategori: 'Fashion',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 129.0,
        estimasiHargaIdr: 290000,
        fotoUrl: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=500',
        deskripsi: 'Sepatu kanvas legendaris shaolin wushu asal Shanghai dengan sol karet mentah lentur dan logo strip klasik.',
        namaToko: 'Feiyue Flagship Store Huaihai Road, Shanghai',
        batasWaktuPo: 'Besok (21:00 CST)',
        rating: 4.8,
        jumlahPeminat: 145,
      ),
      ModelBarangJastip(
        id: 25,
        namaBarang: 'Florasis (Hua Xizi) Floral Engraving Eyeshadow Palette',
        kategori: 'Skincare',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 259.0,
        estimasiHargaIdr: 580000,
        fotoUrl: 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=500',
        deskripsi: 'Palet riasan ukiran timbul relief seni klasik Tiongkok dengan pigmen sutra dan ekstrak bunga alami.',
        namaToko: 'Florasis Flagship Store West Lake, Hangzhou',
        batasWaktuPo: '2 Hari Lagi (17:00 CST)',
        rating: 4.9,
        jumlahPeminat: 165,
      ),
      ModelBarangJastip(
        id: 26,
        namaBarang: 'Teh Da Hong Pao Wuyi Mountain Oolong Premium Gift Tin',
        kategori: 'Kuliner',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 198.0,
        estimasiHargaIdr: 440000,
        fotoUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500',
        deskripsi: 'Daun teh oolong pegunungan Wuyi Fujian kualitas kelas atas dengan aroma panggang kayu manis dan manis di tenggorokan.',
        namaToko: 'Tenfu Tea (Tian Fu Ming Cha) Wangfujing, Beijing',
        batasWaktuPo: '3 Hari Lagi (16:00 CST)',
        rating: 4.9,
        jumlahPeminat: 120,
      ),
      ModelBarangJastip(
        id: 27,
        namaBarang: 'Haidilao Self-Heating Spicy Beef Instant Hotpot (425g)',
        kategori: 'Kuliner',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 38.0,
        estimasiHargaIdr: 85000,
        fotoUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
        deskripsi: 'Hotpot instan masak sendiri tanpa kompor atau air panas. Berisi potongan daging sapi, sayuran segar, dan kuah mala khas Haidilao.',
        namaToko: 'Haidilao Retail Store Sanlitun, Beijing',
        batasWaktuPo: 'Besok (20:00 CST)',
        rating: 4.8,
        jumlahPeminat: 240,
      ),
      ModelBarangJastip(
        id: 28,
        namaBarang: 'Pop Mart Labubu The Monsters Macaron Vinyl Face Plush',
        kategori: 'Hobi & Anime',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 99.0,
        estimasiHargaIdr: 220000,
        fotoUrl: 'https://images.unsplash.com/photo-1558877385-81a1c7e67d72?w=500',
        deskripsi: 'Gantungan tas boneka viral Labubu edisi warna pastel macaron berwajah vinyl ekspresif dari The Monsters.',
        namaToko: 'Pop Mart Chaoyang Joy City, Beijing',
        batasWaktuPo: 'Besok (19:00 CST)',
        rating: 5.0,
        jumlahPeminat: 490,
      ),
      ModelBarangJastip(
        id: 29,
        namaBarang: 'Permen Susu White Rabbit Retro Metal Tin Box (227g)',
        kategori: 'Kuliner',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 45.0,
        estimasiHargaIdr: 100000,
        fotoUrl: 'https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=500',
        deskripsi: 'Permen susu nostalgia khas Shanghai berbalut lapisan kertas beras yang bisa dimakan, dikemas dalam kaleng timah vintage.',
        namaToko: 'Guan Sheng Yuan Flagship Store Shanghai',
        batasWaktuPo: 'Besok (18:00 CST)',
        rating: 4.7,
        jumlahPeminat: 115,
      ),
      ModelBarangJastip(
        id: 30,
        namaBarang: 'Hanfu Modern Tang Dynasty Embroidered Linen Outer Jacket',
        kategori: 'Fashion',
        negara: 'China',
        benderaNegara: '🇨🇳',
        kodeMataUang: 'CNY',
        hargaAsli: 320.0,
        estimasiHargaIdr: 715000,
        fotoUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=500',
        deskripsi: 'Pakaian tradisional modis bergaya Dinasti Tang dengan sulaman benang emas motif awan keberuntungan.',
        namaToko: 'Rongbao Zhai Culture Mall, Xi\'an',
        batasWaktuPo: '3 Hari Lagi (20:00 CST)',
        rating: 4.8,
        jumlahPeminat: 95,
      ),
      ModelBarangJastip(
        id: 31,
        namaBarang: 'Harrods Heritage English Breakfast Loose Leaf Tea Tin 125g',
        kategori: 'Kuliner',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 15.0,
        estimasiHargaIdr: 360000,
        fotoUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
        deskripsi: 'Teh hitam racikan khas toserba mewah Harrods Knightsbridge dikemas dalam kaleng hijau tua berlogo emas elegan.',
        namaToko: 'Harrods Knightsbridge, London',
        batasWaktuPo: 'Besok (17:00 BST)',
        rating: 4.9,
        jumlahPeminat: 190,
      ),
      ModelBarangJastip(
        id: 32,
        namaBarang: 'The Ordinary Niacinamide 10% + Zinc 1% 60ml Value Size',
        kategori: 'Skincare',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 10.5,
        estimasiHargaIdr: 250000,
        fotoUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
        deskripsi: 'Serum pereda noda kemerahan dan pengontrol sebum favorit nomor satu di apotek Boots London.',
        namaToko: 'Boots Pharmacy Covent Garden, London',
        batasWaktuPo: '2 Hari Lagi (18:00 BST)',
        rating: 4.8,
        jumlahPeminat: 180,
      ),
      ModelBarangJastip(
        id: 33,
        namaBarang: 'Fortnum & Mason Piccadilly Lemon Curd Butter Biscuits 200g',
        kategori: 'Kuliner',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 12.95,
        estimasiHargaIdr: 310000,
        fotoUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500',
        deskripsi: 'Biskuit mentega khas kerajaan Inggris dengan selai lemon curd segar dalam kaleng motif Piccadilly berputar.',
        namaToko: 'Fortnum & Mason 181 Piccadilly, London',
        batasWaktuPo: 'Besok (16:30 BST)',
        rating: 5.0,
        jumlahPeminat: 150,
      ),
      ModelBarangJastip(
        id: 34,
        namaBarang: 'Burberry Classic Vintage Check Cashmere Scarf Camel',
        kategori: 'Fashion',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 390.0,
        estimasiHargaIdr: 9400000,
        fotoUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=500',
        deskripsi: 'Syal kasmir murni tenunan Skotlandia dengan motif kotak-kotak Burberry vintage paling ikonik di dunia.',
        namaToko: 'Burberry Regent Street Flagship, London',
        batasWaktuPo: '3 Hari Lagi (19:00 BST)',
        rating: 5.0,
        jumlahPeminat: 85,
      ),
      ModelBarangJastip(
        id: 35,
        namaBarang: 'Jo Malone London English Pear & Freesia Cologne (100ml)',
        kategori: 'Skincare',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 118.0,
        estimasiHargaIdr: 2840000,
        fotoUrl: 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=500',
        deskripsi: 'Parfum khas Inggris perpaduan kesegaran buah pir King William matang dan bunga freesia putih lembut.',
        namaToko: 'Jo Malone Sloane Street Boutique, London',
        batasWaktuPo: '2 Hari Lagi (18:00 BST)',
        rating: 4.9,
        jumlahPeminat: 165,
      ),
      ModelBarangJastip(
        id: 36,
        namaBarang: 'Tongkat Sihir Harry Potter Interactive Wand Ollivanders',
        kategori: 'Hobi & Anime',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 38.0,
        estimasiHargaIdr: 915000,
        fotoUrl: 'https://images.unsplash.com/photo-1551269901-5c5e14c25df7?w=500',
        deskripsi: 'Tongkat sihir interaktif resmi dari toko Ollivanders King\'s Cross Platform 9 3/4 lengkap dengan kotak dan peta mantra.',
        namaToko: 'The Harry Potter Shop King\'s Cross, London',
        batasWaktuPo: '2 Hari Lagi (19:00 BST)',
        rating: 4.9,
        jumlahPeminat: 275,
      ),
      ModelBarangJastip(
        id: 37,
        namaBarang: 'Barbour Classic Beaufort Waxed Jacket Olive',
        kategori: 'Fashion',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 299.0,
        estimasiHargaIdr: 7200000,
        fotoUrl: 'https://images.unsplash.com/photo-1544441893-675973e31985?w=500',
        deskripsi: 'Jaket katun berlapis lilin tahan cuaca hujan Inggris dengan kerah korduroi cokelat khas kaum bangsawan pedesaan.',
        namaToko: 'Barbour Duke of York Square, Chelsea',
        batasWaktuPo: '3 Hari Lagi (17:00 BST)',
        rating: 4.8,
        jumlahPeminat: 70,
      ),
      ModelBarangJastip(
        id: 38,
        namaBarang: 'Twinings Traditional Wooden Tea Chest 40 Envelopes',
        kategori: 'Kuliner',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 22.0,
        estimasiHargaIdr: 530000,
        fotoUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=500',
        deskripsi: 'Kotak kayu teh berukir Twinings berisi 4 macam varian teh klasik Inggris langsung dari toko pertama 216 Strand.',
        namaToko: 'Twinings 216 Strand Main Shop, London',
        batasWaktuPo: 'Besok (17:30 BST)',
        rating: 4.8,
        jumlahPeminat: 110,
      ),
      ModelBarangJastip(
        id: 39,
        namaBarang: 'Lush Mask of Magnaminty Face & Body Mask (315g)',
        kategori: 'Skincare',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 18.0,
        estimasiHargaIdr: 435000,
        fotoUrl: 'https://images.unsplash.com/photo-1567928804479-79888126e7d6?w=500',
        deskripsi: 'Masker tanah liat segar beraroma peppermint dan madu untuk membersihkan pori-pori dan komedo secara tuntas.',
        namaToko: 'Lush Oxford Street Flagship, London',
        batasWaktuPo: '2 Hari Lagi (19:00 BST)',
        rating: 4.8,
        jumlahPeminat: 145,
      ),
      ModelBarangJastip(
        id: 40,
        namaBarang: 'Boneka Paddington Bear Classic Plush Hat & Duffle Coat (30cm)',
        kategori: 'Hobi & Anime',
        negara: 'London (UK)',
        benderaNegara: '🇬🇧',
        kodeMataUang: 'GBP',
        hargaAsli: 25.0,
        estimasiHargaIdr: 600000,
        fotoUrl: 'https://images.unsplash.com/photo-1559454403-b8fb88521f11?w=500',
        deskripsi: 'Boneka beruang Paddington legendaris bertopi merah, mantel biru berkancing kayu, dan label \'Please look after this bear\'.',
        namaToko: 'Paddington Station Official Bear Store, London',
        batasWaktuPo: 'Besok (18:00 BST)',
        rating: 5.0,
        jumlahPeminat: 195,
      ),
      ModelBarangJastip(
        id: 41,
        namaBarang: 'IRVINS Salted Egg Fish Skin Pouch Big 210g',
        kategori: 'Kuliner',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 18.5,
        estimasiHargaIdr: 260000,
        fotoUrl: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=500',
        deskripsi: 'Keripik kulit ikan berlumur telur asin khas Singapura yang gurih renyah dengan daun kari aromatik.',
        namaToko: 'IRVINS Jewel Changi Airport #B2-248',
        batasWaktuPo: 'Besok (20:00 SGT)',
        rating: 4.9,
        jumlahPeminat: 260,
      ),
      ModelBarangJastip(
        id: 42,
        namaBarang: 'Bacha Coffee Seville Orange Fine Ground Coffee Box 200g',
        kategori: 'Kuliner',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 48.0,
        estimasiHargaIdr: 675000,
        fotoUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500',
        deskripsi: 'Kopi arabika 100% dengan aroma jeruk Seville Spanyol dan cokelat retak dalam kaleng oranye megah khas Bacha Coffee.',
        namaToko: 'Bacha Coffee ION Orchard Level 1, Singapore',
        batasWaktuPo: '2 Hari Lagi (19:00 SGT)',
        rating: 4.9,
        jumlahPeminat: 170,
      ),
      ModelBarangJastip(
        id: 43,
        namaBarang: 'Bengawan Solo Pandan Chiffon Cake Original Whole Changi',
        kategori: 'Kuliner',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 17.0,
        estimasiHargaIdr: 240000,
        fotoUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500',
        deskripsi: 'Kue sifon pandan santan asli paling empuk seperti kapas khas Singapura, dibeli fresh beberapa jam sebelum penerbangan.',
        namaToko: 'Bengawan Solo Changi Airport Terminal 3',
        batasWaktuPo: 'Besok (21:00 SGT)',
        rating: 5.0,
        jumlahPeminat: 310,
      ),
      ModelBarangJastip(
        id: 44,
        namaBarang: 'TWG Tea 1837 Black Tea Haute Couture Tin 100g',
        kategori: 'Kuliner',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 45.0,
        estimasiHargaIdr: 635000,
        fotoUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=500',
        deskripsi: 'Racikan teh hitam legendaris TWG Singapura beraroma buah bermuda dan karamel manis dalam kaleng kuning klasik.',
        namaToko: 'TWG Tea Salon Marina Bay Sands, Singapore',
        batasWaktuPo: '2 Hari Lagi (18:30 SGT)',
        rating: 4.8,
        jumlahPeminat: 140,
      ),
      ModelBarangJastip(
        id: 45,
        namaBarang: 'Charles & Keith Metallic Push-Lock Crossbody Bag Black',
        kategori: 'Fashion',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 79.9,
        estimasiHargaIdr: 1130000,
        fotoUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=500',
        deskripsi: 'Tas selempang elegan wanita beraksen kunci putar metalik emas, kulit sintetis terstruktur anti gores original Singapore.',
        namaToko: 'Charles & Keith Takashimaya Orchard',
        batasWaktuPo: '3 Hari Lagi (20:00 SGT)',
        rating: 4.9,
        jumlahPeminat: 205,
      ),
      ModelBarangJastip(
        id: 46,
        namaBarang: 'Balsam Tiger Balm White Ointment Extra Strength 50g',
        kategori: 'Skincare',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 9.8,
        estimasiHargaIdr: 140000,
        fotoUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500',
        deskripsi: 'Balsem herbal pereda sakit kepala, pegal linu, dan hidung tersumbat formula legendaris Harimau Putih Singapura.',
        namaToko: 'Watsons Ngee Ann City Orchard, Singapore',
        batasWaktuPo: 'Besok (19:00 SGT)',
        rating: 4.7,
        jumlahPeminat: 125,
      ),
      ModelBarangJastip(
        id: 47,
        namaBarang: 'Lego Architecture Singapore Marina Bay Sands 21057',
        kategori: 'Hobi & Anime',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 99.9,
        estimasiHargaIdr: 1410000,
        fotoUrl: 'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=500',
        deskripsi: 'Set Lego Architecture skyline Singapura menampilkan Marina Bay Sands, Gardens by the Bay, dan Singapore River.',
        namaToko: 'The Lego Certified Store Suntec City Mall',
        batasWaktuPo: '2 Hari Lagi (19:00 SGT)',
        rating: 4.9,
        jumlahPeminat: 180,
      ),
      ModelBarangJastip(
        id: 48,
        namaBarang: 'Pedro Icon Leather Bifold Wallet with Coin Pocket Navy',
        kategori: 'Fashion',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 65.9,
        estimasiHargaIdr: 930000,
        fotoUrl: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=500',
        deskripsi: 'Dompet kulit pria lipat dua Pedro Singapura dengan slot kartu terorganisir dan kompartemen koin kancing.',
        namaToko: 'Pedro VivoCity Level 1, Singapore',
        batasWaktuPo: '3 Hari Lagi (18:00 SGT)',
        rating: 4.8,
        jumlahPeminat: 115,
      ),
      ModelBarangJastip(
        id: 49,
        namaBarang: 'Ya Kun Kaya Toast Kaya Jam Jar (Pandan Coconut 290g)',
        kategori: 'Kuliner',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 6.2,
        estimasiHargaIdr: 88000,
        fotoUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500',
        deskripsi: 'Selai srikaya pandan legendaris Ya Kun sejak 1944. Sangat nikmat dioles pada roti panggang dengan mentega dingin.',
        namaToko: 'Ya Kun Kaya Toast Far East Square, Singapore',
        batasWaktuPo: 'Besok (17:00 SGT)',
        rating: 4.9,
        jumlahPeminat: 235,
      ),
      ModelBarangJastip(
        id: 50,
        namaBarang: 'Pokemon Center Changi Exclusive Pilot Pikachu Plush',
        kategori: 'Hobi & Anime',
        negara: 'Singapura',
        benderaNegara: '🇸🇬',
        kodeMataUang: 'SGD',
        hargaAsli: 32.0,
        estimasiHargaIdr: 450000,
        fotoUrl: 'https://images.unsplash.com/photo-1613771404784-3a5686aa2be3?w=500',
        deskripsi: 'Boneka Pikachu edisi terbatas berseragam kapten pilot pesawat terbang resmi hanya dijual di Pokemon Center Jewel Changi.',
        namaToko: 'Pokemon Center Singapore Jewel Changi Level 4',
        batasWaktuPo: 'Besok (21:30 SGT)',
        rating: 5.0,
        jumlahPeminat: 320,
      ),
    ];
  }

  // Fetching data produk secara asinkron dari API / Database NoSQL Hive
  static Future<List<ModelBarangJastip>> ambilSemuaBarang() async {
    // 1. Ambil data dari Basis Data Lokal Hive
    List<ModelBarangJastip> dataLokal = LayananBasisDataLokal.ambilSemuaKatalog();

    // 2. Jika database lokal masih kosong pertama kali, inisialisasi dari seed awal
    if (dataLokal.isEmpty) {
      dataLokal = buatKatalogAwalDatabase();
      await LayananBasisDataLokal.simpanSemuaKatalog(dataLokal);
    }

    // 3. Lakukan fetching asinkron dari Database Online (Firebase Realtime Database & REST API)
    try {
      final resFirebase = await http
          .get(Uri.parse('https://opank-ople-default-rtdb.firebaseio.com/katalog.json'))
          .timeout(const Duration(seconds: 4));
      if (resFirebase.statusCode == 200 && resFirebase.body.isNotEmpty && resFirebase.body != 'null') {
        final dynamic decoded = jsonDecode(resFirebase.body);
        if (decoded is List) {
          final List<ModelBarangJastip> produkOnline = decoded
              .map((item) => ModelBarangJastip.dariJson(Map<String, dynamic>.from(item)))
              .toList();
          if (produkOnline.isNotEmpty) {
            await LayananBasisDataLokal.simpanSemuaKatalog(produkOnline);
            return produkOnline;
          }
        }
      }
    } catch (_) {}

    try {
      final response = await http.get(Uri.parse(_urlKatalogApi)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['data'] != null && body['data']['products'] is List) {
          final List<dynamic> prodList = body['data']['products'];
          final List<ModelBarangJastip> produkApi =
              prodList.map((item) => ModelBarangJastip.dariJson(Map<String, dynamic>.from(item))).toList();
          if (produkApi.isNotEmpty) {
            await LayananBasisDataLokal.simpanSemuaKatalog(produkApi);
            return produkApi;
          }
        }
      }
    } catch (_) {
      // Jika terjadi gangguan koneksi/offline, gunakan data dari database lokal Hive
    }

    return dataLokal;
  }

  // Filter barang berdasarkan negara singgah dan kategori
  static Future<List<ModelBarangJastip>> filterBarang({
    String negara = 'Semua',
    String kategori = 'Semua',
    String kataKunci = '',
    String urutanHarga = 'Normal', // 'Termurah', 'Termahal', 'Populer'
  }) async {
    final List<ModelBarangJastip> daftar = await ambilSemuaBarang();
    List<ModelBarangJastip> hasil = List.from(daftar);

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

  // Catat pertambahan jumlah barang terjual ke Database Lokal & REST API Backend Online (Audit Poin 1)
  static Future<void> catatPembelianOnline(List<Map<String, dynamic>> daftarItem) async {
    try {
      final katalog = LayananBasisDataLokal.ambilSemuaKatalog();
      bool adaPerubahan = false;

      for (final item in daftarItem) {
        final String namaItem = item['namaBarang']?.toString().toLowerCase() ?? '';
        final int jumlahBeli = item['jumlah'] is int ? item['jumlah'] as int : 1;

        for (var b in katalog) {
          if (b.namaBarang.toLowerCase() == namaItem) {
            b.jumlahPeminat += jumlahBeli;
            adaPerubahan = true;
          }
        }
      }

      if (adaPerubahan) {
        // 1. Simpan pembaruan ke Database Lokal Hive
        await LayananBasisDataLokal.simpanSemuaKatalog(katalog);

        // 2. Sinkronkan ke Database REST API Online secara asinkron
        await http.put(
          Uri.parse(_urlKatalogApi),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': 'JASTIPGO_CATALOG_DATA',
            'data': {
              'keterangan': 'Katalog Online JastipGo',
              'terakhirDiperbarui': DateTime.now().toIso8601String(),
              'products': katalog.map((e) => e.keJson()).toList(),
            },
          }),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Toleransi offline: data tetap tersimpan aman di database lokal
    }
  }

  // Tambah Barang Jastip Baru ke Database Lokal Hive
  static Future<void> tambahBarangJastip(ModelBarangJastip barangBaru) async {
    await LayananBasisDataLokal.tambahBarangKatalog(barangBaru);
  }
}
