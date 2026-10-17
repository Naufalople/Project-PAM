import 'dart:async';
import 'package:flutter/material.dart';
import '../layanan/layanan_konversi.dart';

// Halaman Konversi Waktu Dunia: WIB, WITA, WIT, London, Tokyo, Seoul
class HalamanJamDunia extends StatefulWidget {
  const HalamanJamDunia({super.key});

  @override
  State<HalamanJamDunia> createState() => _HalamanJamDuniaState();
}

class _HalamanJamDuniaState extends State<HalamanJamDunia> {
  Timer? _timer;
  Map<String, String> _dataWaktu = {};

  @override
  void initState() {
    super.initState();
    _perbaruiWaktu();
    // Perbarui waktu setiap 1 detik secara live
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _perbaruiWaktu();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _perbaruiWaktu() {
    setState(() {
      _dataWaktu = LayananKonversi.ambilDaftarZonaWaktu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool tokoLondonBuka = LayananKonversi.apakahTokoLondonBuka();

    final List<Map<String, dynamic>> daftarZona = [
      {
        'kota': 'London (UK)',
        'kode': 'GMT / BST (UTC+1)',
        'waktu': _dataWaktu['London'] ?? '-',
        'bendera': '🇬🇧',
        'status': tokoLondonBuka ? 'Toko Buka (Operasional)' : 'Toko Tutup (Malam)',
        'warnaStatus': tokoLondonBuka ? Colors.green : Colors.redAccent,
        'catatan': 'Pusat belanja Harrods, Oxford Street, & Covent Garden',
      },
      {
        'kota': 'WIB - Waktu Indonesia Barat',
        'kode': 'Jakarta / Jogja (UTC+7)',
        'waktu': _dataWaktu['WIB'] ?? '-',
        'bendera': '🇮🇩',
        'status': 'Zona Waktu Utama Pemesan',
        'warnaStatus': Colors.teal,
        'catatan': 'Waktu konfirmasi dan pembayaran titipan',
      },
      {
        'kota': 'WITA - Waktu Indonesia Tengah',
        'kode': 'Bali / Makassar (UTC+8)',
        'waktu': _dataWaktu['WITA'] ?? '-',
        'bendera': '🇮🇩',
        'status': 'Zona Waktu Pemesan',
        'warnaStatus': Colors.teal,
        'catatan': 'Waktu penerimaan titipan wilayah tengah',
      },
      {
        'kota': 'WIT - Waktu Indonesia Timur',
        'kode': 'Jayapura / Maluku (UTC+9)',
        'waktu': _dataWaktu['WIT'] ?? '-',
        'bendera': '🇮🇩',
        'status': 'Zona Waktu Pemesan',
        'warnaStatus': Colors.teal,
        'catatan': 'Waktu penerimaan titipan wilayah timur',
      },
      {
        'kota': 'Tokyo (Jepang)',
        'kode': 'JST (UTC+9)',
        'waktu': _dataWaktu['Tokyo'] ?? '-',
        'bendera': '🇯🇵',
        'status': 'Zona Belanja Jastip Asia',
        'warnaStatus': Colors.blue,
        'catatan': 'Pusat belanja Don Quijote, Shibuya, & Akihabara',
      },
      {
        'kota': 'Seoul (Korea Selatan)',
        'kode': 'KST (UTC+9)',
        'waktu': _dataWaktu['Seoul'] ?? '-',
        'bendera': '🇰🇷',
        'status': 'Zona Belanja Jastip Asia',
        'warnaStatus': Colors.indigo,
        'catatan': 'Pusat belanja Olive Young & Myeongdong',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Zona Waktu Dunia Jastip'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Penjelasan Relevansi Fitur untuk Dosen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.blue.shade800, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Sinkronisasi Zona Waktu Nyata:\nMemantau jam buka toko luar negeri (London & Asia) disandingkan dengan 3 zona waktu Indonesia (WIB, WITA, WIT) agar tidak terlewat batas Open PO.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Jam Operasional Lintas Negara (Live):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: daftarZona.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = daftarZona[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item['bendera'], style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['kota'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  item['kode'],
                                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item['warnaStatus'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['status'],
                              style: TextStyle(
                                color: item['warnaStatus'] as Color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['waktu'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Icon(Icons.access_time_filled, size: 18, color: Colors.black26),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['catatan'],
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
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
