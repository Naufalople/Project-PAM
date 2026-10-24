import 'package:flutter/material.dart';
import '../layanan/layanan_otentikasi.dart';
import 'halaman_rekomendasi_ai.dart';
import 'halaman_chatbot.dart';
import 'halaman_shake_promo.dart';
import 'halaman_jam_dunia.dart';
import 'halaman_kalkulator_kurs.dart';
import 'halaman_mini_game.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_dompet_rekber.dart';
import 'halaman_status_pesanan.dart';
import 'halaman_kelola_pesanan_traveler.dart';
import 'halaman_pencarian_suara.dart';

// Halaman Hub Fitur Cerdas: Pusat Navigasi Berbasis Peran (RBAC Pemesan vs Traveler)
class HalamanFiturCerdas extends StatefulWidget {
  final String? peranOverride;

  const HalamanFiturCerdas({super.key, this.peranOverride});

  @override
  State<HalamanFiturCerdas> createState() => _HalamanFiturCerdasState();
}

class _HalamanFiturCerdasState extends State<HalamanFiturCerdas> {
  String _peranAktif = 'PEMESAN';
  bool _sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    if (widget.peranOverride != null) {
      _peranAktif = widget.peranOverride!;
      _sedangMemuat = false;
    } else {
      _muatPeran();
    }
  }

  @override
  void didUpdateWidget(covariant HalamanFiturCerdas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.peranOverride != null && widget.peranOverride != oldWidget.peranOverride) {
      setState(() {
        _peranAktif = widget.peranOverride!;
        _sedangMemuat = false;
      });
    }
  }

  Future<void> _muatPeran() async {
    final peran = await LayananOtentikasi.ambilPeranAktif();
    if (!mounted) return;
    setState(() {
      _peranAktif = peran;
      _sedangMemuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pusat Fitur Cerdas'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool adalahTraveler = _peranAktif == 'TRAVELER';

    // Daftar menu fitur yang disesuaikan secara dinamis berdasarkan RBAC
    final List<Map<String, dynamic>> menuFitur = [];

    if (adalahTraveler) {
      // ==========================================
      // FITUR KHUSUS SISI TRAVELER (JASTIPER)
      // ==========================================
      menuFitur.addAll([
        {
          'judul': 'Kelola Pesanan Masuk (Traveler)',
          'subjudul': 'ACC pesanan titipan pemesan, konfirmasi belanja LN, & mendarat',
          'ikon': Icons.flight_takeoff_rounded,
          'warna': Colors.indigo.shade700,
          'halaman': const HalamanKelolaPesananTraveler(),
          'tag': 'Sisi Traveler',
        },
        {
          'judul': 'Chatbot Regulasi Bea Cukai',
          'subjudul': 'Konsultasi batasan koper USD 500 & aturan IMEI bandara',
          'ikon': Icons.smart_toy_rounded,
          'warna': Colors.teal,
          'halaman': const HalamanChatbot(),
          'tag': 'LLM AI',
        },
        {
          'judul': 'Kalkulator Kurs Valas',
          'subjudul': 'Konversi JPY, KRW, GBP, USD, SGD ke Rupiah secara live',
          'ikon': Icons.currency_exchange_rounded,
          'warna': Colors.green.shade700,
          'halaman': const HalamanKalkulatorKurs(),
          'tag': 'Mata Uang',
        },
        {
          'judul': 'Zona Waktu Dunia',
          'subjudul': 'Pantau jam London, Tokyo, Seoul, WIB, WITA, WIT',
          'ikon': Icons.schedule_rounded,
          'warna': Colors.blue.shade700,
          'halaman': const HalamanJamDunia(),
          'tag': 'Waktu Toko',
        },
        {
          'judul': 'Peta & Titik Temu LBS',
          'subjudul': 'Tentukan pos serah terima barang COD dengan pemesan via GPS',
          'ikon': Icons.location_on_rounded,
          'warna': Colors.redAccent.shade700,
          'halaman': const HalamanPetaLokasi(),
          'tag': 'LBS / GPS',
        },
        {
          'judul': 'Dompet & Saldo Rekber Escrow',
          'subjudul': 'Pantau dana tertahan dan pencairan saldo aktif hasil titipan',
          'ikon': Icons.account_balance_wallet_rounded,
          'warna': Colors.teal.shade800,
          'halaman': const HalamanDompetRekber(),
          'tag': 'Rekber Escrow',
        },
      ]);
    } else {
      // ==========================================
      // FITUR KHUSUS SISI PEMESAN (REQUESTER)
      // ==========================================
      menuFitur.addAll([
        {
          'judul': 'Pelacakan Status Pesanan (Pemesan)',
          'subjudul': 'Pantau siklus barang titipan & konfirmasi terima barang',
          'ikon': Icons.local_shipping_rounded,
          'warna': Colors.deepOrange.shade700,
          'halaman': const HalamanStatusPesanan(),
          'tag': 'Sisi Pemesan',
        },
        {
          'judul': 'Rekomendasi Cerdas AI',
          'subjudul': 'Sistem rekomendasi berbasis volume transaksi & kemiripan produk',
          'ikon': Icons.auto_awesome_rounded,
          'warna': Colors.purple,
          'halaman': const HalamanRekomendasiAi(),
          'tag': 'AI Engine',
        },
        {
          'judul': 'Chatbot Asisten Jastip',
          'subjudul': 'Tanya jawab aturan bea cukai & rekomendasi belanja',
          'ikon': Icons.smart_toy_rounded,
          'warna': Colors.teal,
          'halaman': const HalamanChatbot(),
          'tag': 'LLM AI',
        },
        {
          'judul': 'Shake & Win Promo',
          'subjudul': 'Goyangkan HP untuk mengocok diskon ongkos jastip',
          'ikon': Icons.vibration_rounded,
          'warna': Colors.amber.shade800,
          'halaman': const HalamanShakePromo(),
          'tag': 'Sensor Gerak',
        },
        {
          'judul': 'Pencarian Suara (Voice Search)',
          'subjudul': 'Cari produk katalog jastip menggunakan sensor suara mikrofon',
          'ikon': Icons.mic_rounded,
          'warna': Colors.teal.shade700,
          'halaman': const HalamanPencarianSuara(),
          'tag': 'Sensor Suara',
        },
        {
          'judul': 'Mini Game Koper Jastip',
          'subjudul': 'Kuis tebak harga barang untuk bonus diskon jastip',
          'ikon': Icons.videogame_asset_rounded,
          'warna': Colors.indigo.shade700,
          'halaman': const HalamanMiniGame(),
          'tag': 'Mini Game',
        },
        {
          'judul': 'Zona Waktu Dunia',
          'subjudul': 'Pantau jam London, Tokyo, Seoul, WIB, WITA, WIT',
          'ikon': Icons.schedule_rounded,
          'warna': Colors.blue.shade700,
          'halaman': const HalamanJamDunia(),
          'tag': 'Konversi Waktu',
        },
        {
          'judul': 'Kalkulator Kurs Valas',
          'subjudul': 'Konversi JPY, KRW, GBP, USD, SGD ke Rupiah secara live',
          'ikon': Icons.currency_exchange_rounded,
          'warna': Colors.green.shade700,
          'halaman': const HalamanKalkulatorKurs(),
          'tag': 'Mata Uang',
        },
        {
          'judul': 'Peta & Titik Temu LBS',
          'subjudul': 'Cari pos serah terima barang COD terdekat via GPS Google Maps',
          'ikon': Icons.location_on_rounded,
          'warna': Colors.redAccent.shade700,
          'halaman': const HalamanPetaLokasi(),
          'tag': 'LBS / GPS',
        },
      ]);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(adalahTraveler ? 'Fitur Traveler Luar Negeri' : 'Pusat Fitur Cerdas'),
        backgroundColor: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adalahTraveler ? 'Utilitas Kerja Traveler Dimas:' : 'Teknologi & Utilitas JastipGo:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              adalahTraveler
                  ? 'Akses utilitas khusus belanja internasional: kelola pesanan masuk, pantau kurs, cek aturan bagasi koper, dan keamanan saldo rekber.'
                  : 'Seluruh fitur canggih terintegrasi untuk mendukung kenyamanan transaksi titipan belanja mancanegara Anda.',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menuFitur.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = menuFitur[index];
                final Color warna = item['warna'];

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item['halaman']),
                    ).then((_) => _muatPeran());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: warna.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(item['ikon'], color: warna, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['judul'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: warna.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['tag'],
                                      style: TextStyle(
                                        color: warna,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['subjudul'],
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black26),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
