import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';

// Model Data Kartu Memori Jastip
class ModelKartuJastip {
  final int id;
  final int idPasangan;
  final String nama;
  final String negara;
  final String bendera;
  final IconData ikon;
  final Color warna;
  final String fotoUrl;
  bool terbuka;
  bool cocok;

  ModelKartuJastip({
    required this.id,
    required this.idPasangan,
    required this.nama,
    required this.negara,
    required this.bendera,
    required this.ikon,
    required this.warna,
    required this.fotoUrl,
    this.terbuka = false,
    this.cocok = false,
  });
}

// Halaman Mini Game Kartu Memori: "Tebak Pasangan Koper Jastip"
class HalamanMiniGame extends StatefulWidget {
  final String? peranOverride;

  const HalamanMiniGame({super.key, this.peranOverride});

  @override
  State<HalamanMiniGame> createState() => _HalamanMiniGameState();
}

class _HalamanMiniGameState extends State<HalamanMiniGame> {
  static const int _durasiAwalDetik = 45; // Waktu tantangan 45 detik
  int _sisaWaktu = _durasiAwalDetik;
  Timer? _timer;

  List<ModelKartuJastip> _kartu = [];
  int? _indeksPilihanPertama;
  int? _indeksPilihanKedua;
  bool _sedangMemeriksa = false;

  int _langkah = 0;
  int _pasanganCocok = 0;
  static const int _totalPasangan = 6; // 6 Pasang = 12 Kartu (Grid 4x3)

  bool _permainanSelesai = false;
  bool _menang = false;
  ModelVoucher? _voucherHadiah;
  bool _hadiahSudahPernahDiklaim = false;
  bool _sedangMemuat = true;
  String _peranAktif = 'PEMESAN';

  static const String _kunciVoucherKuisKlaim = 'kuis_voucher_sudah_diklaim';

  // Master Data 6 Produk Jastip Mancanegara Ikonik
  final List<Map<String, dynamic>> _masterProduk = [
    {
      'nama': 'Naruto Figure',
      'negara': 'Jepang',
      'bendera': '🇯🇵',
      'ikon': Icons.person_pin_circle_rounded,
      'warna': Colors.deepOrange,
      'fotoUrl': 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500',
    },
    {
      'nama': 'Solo Leveling',
      'negara': 'Korea',
      'bendera': '🇰🇷',
      'ikon': Icons.menu_book_rounded,
      'warna': Colors.deepPurple,
      'fotoUrl': 'https://images.unsplash.com/photo-1618519764620-7403abdbdfe9?w=500',
    },
    {
      'nama': 'Novel LOTM',
      'negara': 'China',
      'bendera': '🇨🇳',
      'ikon': Icons.auto_stories_rounded,
      'warna': Colors.amber.shade900,
      'fotoUrl': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500',
    },
    {
      'nama': 'Tokyo Banana',
      'negara': 'Jepang',
      'bendera': '🇯🇵',
      'ikon': Icons.bakery_dining_rounded,
      'warna': Colors.amber.shade700,
      'fotoUrl': 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500',
    },
    {
      'nama': 'Harrods Tea',
      'negara': 'London',
      'bendera': '🇬🇧',
      'ikon': Icons.emoji_food_beverage_rounded,
      'warna': Colors.teal.shade800,
      'fotoUrl': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
    },
    {
      'nama': 'Bacha Coffee',
      'negara': 'Singapura',
      'bendera': '🇸🇬',
      'ikon': Icons.coffee_rounded,
      'warna': Colors.brown.shade700,
      'fotoUrl': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.peranOverride != null) {
      _peranAktif = widget.peranOverride!;
    }
    _inisialisasiGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _inisialisasiGame() async {
    final prefs = await SharedPreferences.getInstance();
    final profil = await LayananOtentikasi.ambilProfilAktif();
    final String userId = profil?.id != null ? profil!.id.toString() : '1';
    final bool pernahKlaim = prefs.getBool('${_kunciVoucherKuisKlaim}_$userId') ?? false;
    final peran = widget.peranOverride ?? profil?.peran ?? await LayananOtentikasi.ambilPeranAktif();

    if (!mounted) return;

    setState(() {
      _peranAktif = peran;
      _sedangMemuat = false;
      _hadiahSudahPernahDiklaim = pernahKlaim;
    });

    // Permainan kartu dan hitung mundur timer HANYA dimulai untuk PEMESAN
    if (peran != 'TRAVELER') {
      _resetDanMulaiGame();
    }
  }

  void _resetDanMulaiGame() {
    _timer?.cancel();
    if (_peranAktif == 'TRAVELER') return;

    // Buat 12 kartu (6 pasang x 2 kartu identik)
    final List<ModelKartuJastip> daftarBaru = [];
    int idCounter = 0;
    for (int i = 0; i < _masterProduk.length; i++) {
      final item = _masterProduk[i];
      // Kartu Pertama dari Pasangan
      daftarBaru.add(ModelKartuJastip(
        id: idCounter++,
        idPasangan: i,
        nama: item['nama'],
        negara: item['negara'],
        bendera: item['bendera'],
        ikon: item['ikon'],
        warna: item['warna'],
        fotoUrl: item['fotoUrl'],
      ));
      // Kartu Kedua dari Pasangan
      daftarBaru.add(ModelKartuJastip(
        id: idCounter++,
        idPasangan: i,
        nama: item['nama'],
        negara: item['negara'],
        bendera: item['bendera'],
        ikon: item['ikon'],
        warna: item['warna'],
        fotoUrl: item['fotoUrl'],
      ));
    }

    // Acak posisi kartu di atas meja koper
    daftarBaru.shuffle();

    setState(() {
      _kartu = daftarBaru;
      _sisaWaktu = _durasiAwalDetik;
      _langkah = 0;
      _pasanganCocok = 0;
      _permainanSelesai = false;
      _menang = false;
      _indeksPilihanPertama = null;
      _indeksPilihanKedua = null;
      _sedangMemeriksa = false;
      _voucherHadiah = null;
    });

    _mulaiTimerHitungMundur();
  }

  void _mulaiTimerHitungMundur() {
    if (_peranAktif == 'TRAVELER') return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_sisaWaktu > 1) {
        setState(() => _sisaWaktu--);
      } else {
        timer.cancel();
        setState(() {
          _sisaWaktu = 0;
          _permainanSelesai = true;
          _menang = false;
        });

        LayananNotifikasi.kirimNotifikasi(
          context,
          judul: 'Waktu Habis! ⏱️',
          pesan: 'Anda belum mencocokkan seluruh koper jastip tepat waktu. Coba lagi untuk menang!',
          ikon: Icons.timer_off_rounded,
          warna: Colors.red.shade700,
        );
      }
    });
  }

  Future<void> _bukaKartu(int index) async {
    // Abaikan klik jika permainan selesai, waktu habis, kartu sudah terbuka/cocok, atau sedang animasi
    if (_permainanSelesai ||
        _sedangMemeriksa ||
        _kartu[index].terbuka ||
        _kartu[index].cocok) {
      return;
    }

    setState(() {
      _kartu[index].terbuka = true;
    });

    if (_indeksPilihanPertama == null) {
      // Pemain baru membuka kartu pertama
      _indeksPilihanPertama = index;
    } else {
      // Pemain membuka kartu kedua -> periksa kecocokan
      _indeksPilihanKedua = index;
      _langkah++;
      _sedangMemeriksa = true;

      final kartuSatu = _kartu[_indeksPilihanPertama!];
      final kartuDua = _kartu[_indeksPilihanKedua!];

      if (kartuSatu.idPasangan == kartuDua.idPasangan) {
        // COCOK! Pasangan gambar sama ditemukan
        setState(() {
          kartuSatu.cocok = true;
          kartuDua.cocok = true;
          _pasanganCocok++;
          _indeksPilihanPertama = null;
          _indeksPilihanKedua = null;
          _sedangMemeriksa = false;
        });

        // Periksa apakah seluruh 6 pasangan sudah ditemukan (KONDISI MENANG)
        if (_pasanganCocok == _totalPasangan) {
          _tanganiKemenangan();
        }
      } else {
        // TIDAK COCOK! Beri jeda 800ms agar pemain dapat mengingat kartu, lalu tutup kembali
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            kartuSatu.terbuka = false;
            kartuDua.terbuka = false;
            _indeksPilihanPertama = null;
            _indeksPilihanKedua = null;
            _sedangMemeriksa = false;
          });
        }
      }
    }
  }

  Future<void> _tanganiKemenangan() async {
    _timer?.cancel();

    ModelVoucher? hadiah;
    final prefs = await SharedPreferences.getInstance();

    if (!_hadiahSudahPernahDiklaim) {
      final profil = await LayananOtentikasi.ambilProfilAktif();
      final String userId = profil?.id != null ? profil!.id.toString() : '1';

      hadiah = ModelVoucher(
        kode: 'MATCH50',
        judul: '🎉 Voucher Juara Kartu Rp 50.000',
        potonganIdr: 50000,
        deskripsi: 'Hadiah kemenangan mencocokkan kartu koper jastip sebelum waktu habis.',
        userId: userId,
      );

      await LayananBasisDataLokal.simpanVoucher(hadiah, userId: userId);
      await prefs.setBool('${_kunciVoucherKuisKlaim}_$userId', true);
      await prefs.setBool(_kunciVoucherKuisKlaim, true);
      _hadiahSudahPernahDiklaim = true;

      if (!mounted) return;
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Luar Biasa! Anda Menang! 🏆',
        pesan: 'Semua kartu tercocokkan dengan sisa waktu $_sisaWaktu detik! Voucher Rp 50.000 berhasil didapatkan!',
        ikon: Icons.card_giftcard,
        warna: Colors.teal.shade800,
      );
    } else {
      if (!mounted) return;
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Hebat! Kartu Selesai (Mode Latihan) 🎯',
        pesan: 'Anda berhasil menyelesaikan memori koper jastip dalam $_langkah langkah!',
        ikon: Icons.verified_user_outlined,
        warna: Colors.teal.shade700,
      );
    }

    setState(() {
      _permainanSelesai = true;
      _menang = true;
      _voucherHadiah = hadiah;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Game Kartu Koper Jastip'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Proteksi RBAC: Traveler difokuskan pada logistik pesanan
    if (_peranAktif == 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Game Kartu Koper Jastip'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.style_rounded, size: 64, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akses Khusus Pemesan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Game kartu memori & klaim voucher diskon belanja diperuntukkan bagi Pemesan jastip.\n\nSebagai Traveler, antarmuka Anda difokuskan pada pemantauan titipan barang masuk, logistik bagasi, dan pencatatan struk belanja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Kembali ke Menu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Game Kartu Koper Jastip'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Mulai Ulang',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: _resetDanMulaiGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: _permainanSelesai ? _tampilkanLayarHasil() : _tampilkanArenaGame(),
        ),
      ),
    );
  }

  // Tampilan Utama Arena Permainan Kartu
  Widget _tampilkanArenaGame() {
    final double persentaseWaktu = _sisaWaktu / _durasiAwalDetik;
    final bool waktuKritis = _sisaWaktu <= 10;

    return Column(
      children: [
        // Panel Statistik: Waktu, Pasangan, Langkah
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Countdown Timer
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: waktuKritis ? Colors.red.shade700 : Colors.indigo.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '00:${_sisaWaktu.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: waktuKritis ? Colors.red.shade700 : Colors.indigo.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pasangan Ditemukan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cocok: $_pasanganCocok/$_totalPasangan',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                  // Jumlah Langkah
                  Text(
                    'Langkah: $_langkah',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress Bar Waktu
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: persentaseWaktu,
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    waktuKritis ? Colors.red.shade600 : Colors.teal.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Petunjuk Singkat (dengan Flexible anti-overflow)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: Colors.indigo.shade600),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Buka 2 kartu yang sama sebelum waktu habis!',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Grid 12 Kartu (4 baris x 3 kolom)
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _kartu.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final kartu = _kartu[index];
              return _bangunWidgetKartu(kartu, index);
            },
          ),
        ),
      ],
    );
  }

  // Desain Kartu Interaktif dengan Status Buka/Tutup/Cocok
  Widget _bangunWidgetKartu(ModelKartuJastip kartu, int index) {
    final bool tampilDepan = kartu.terbuka || kartu.cocok;

    return GestureDetector(
      onTap: () => _bukaKartu(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: tampilDepan
              ? (kartu.cocok ? Colors.teal.shade50 : Colors.white)
              : Colors.indigo.shade800,
          border: Border.all(
            color: kartu.cocok
                ? Colors.teal.shade500
                : (tampilDepan ? Colors.indigo.shade200 : Colors.indigo.shade900),
            width: kartu.cocok ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: tampilDepan
                  ? (kartu.cocok
                      ? Colors.teal.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.08))
                  : Colors.indigo.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: tampilDepan
            ? _bangunIsiKartuTerbuka(kartu)
            : _bangunIsiKartuTertutup(),
      ),
    );
  }

  // Tampilan Depan Kartu (Terbuka): Foto Produk + Ikon + Negara
  Widget _bangunIsiKartuTerbuka(ModelKartuJastip kartu) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          // Header Bendera & Negara (Anti-Overflow dengan Flexible)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kartu.bendera, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  kartu.negara,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: kartu.warna,
                  ),
                ),
              ),
              if (kartu.cocok) ...[
                const SizedBox(width: 3),
                Icon(Icons.check_circle, size: 11, color: Colors.teal.shade700),
              ],
            ],
          ),
          const SizedBox(height: 2),
          // Gambar Produk
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: kartu.warna.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  kartu.fotoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(kartu.ikon, color: kartu.warna, size: 24),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Nama Produk
          Text(
            kartu.nama,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan Belakang Kartu (Tertutup): Logo Koper Misteri
  Widget _bangunIsiKartuTertutup() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade700,
            Colors.indigo.shade900,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.luggage_rounded,
            size: 38,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'JASTIP',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan Layar Hasil (Menang / Kalah Waktu Habis)
  Widget _tampilkanLayarHasil() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon Hasil
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _menang ? Colors.teal.shade50 : Colors.red.shade50,
                ),
                child: Icon(
                  _menang ? Icons.emoji_events_rounded : Icons.timer_off_rounded,
                  color: _menang ? Colors.amber.shade700 : Colors.red.shade700,
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),

              // Judul Hasil
              Text(
                _menang ? 'Selamat, Anda Menang! 🎉' : 'Waktu Habis! ⏱️',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Deskripsi Rincian
              Text(
                _menang
                    ? 'Luar biasa! Semua 6 pasangan kartu koper jastip berhasil Anda cocokkan dalam $_langkah langkah dengan sisa waktu $_sisaWaktu detik.'
                    : 'Waktu 45 detik telah habis! Anda berhasil mencocokkan $_pasanganCocok dari $_totalPasangan pasangan. Coba lagi untuk membuka semua kartu!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),

              // Kartu Voucher Hadiah (Jika Menang)
              if (_voucherHadiah != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.teal.shade900, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _voucherHadiah!.judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KODE: ${_voucherHadiah!.kode} • POTONGAN ${LayananKonversi.formatRupiah(_voucherHadiah!.potonganIdr)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.indigo.shade900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '✅ Kupon sudah otomatis tersimpan di dompet akun Anda dan siap digunakan saat checkout!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],

              // Info Anti-Eksploitasi (Jika sudah pernah klaim)
              if (_menang && _voucherHadiah == null && _hadiahSudahPernahDiklaim) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.blueGrey.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Mode Latihan: Voucher Rp 50.000 sudah pernah diklaim sebelumnya pada akun ini.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Tombol Main Lagi / Coba Lagi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _menang ? Colors.teal.shade800 : Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _resetDanMulaiGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _menang ? 'Main Lagi' : 'Coba Lagi (Mulai Ulang)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
