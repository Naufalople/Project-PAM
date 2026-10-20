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
    final List<Map<String, dynamic>> daftarZona = [
      {
        'kota': 'London (UK)',
        'waktu': _dataWaktu['London'] ?? '-',
        'bendera': '🇬🇧',
      },
      {
        'kota': 'WIB - Waktu Indonesia Barat',
        'waktu': _dataWaktu['WIB'] ?? '-',
        'bendera': '🇮🇩',
      },
      {
        'kota': 'WITA - Waktu Indonesia Tengah',
        'waktu': _dataWaktu['WITA'] ?? '-',
        'bendera': '🇮🇩',
      },
      {
        'kota': 'WIT - Waktu Indonesia Timur',
        'waktu': _dataWaktu['WIT'] ?? '-',
        'bendera': '🇮🇩',
      },
      {
        'kota': 'Tokyo (Jepang)',
        'waktu': _dataWaktu['Tokyo'] ?? '-',
        'bendera': '🇯🇵',
      },
      {
        'kota': 'Seoul (Korea Selatan)',
        'waktu': _dataWaktu['Seoul'] ?? '-',
        'bendera': '🇰🇷',
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
            // Header Info Zona Waktu Nyata
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.blue.shade800, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Zona Waktu Nyata Dunia:\nMemantau jam saat ini lintas wilayah jastip internasional dan Indonesia.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Daftar Wilayah & Jam Saat Ini (Live):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: daftarZona.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = daftarZona[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(item['bendera'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['kota'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['waktu'],
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade900,
                          letterSpacing: 0.5,
                        ),
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
