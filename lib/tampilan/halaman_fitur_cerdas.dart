import 'package:flutter/material.dart';
import 'halaman_pemindai_ai.dart';
import 'halaman_chatbot.dart';
import 'halaman_shake_promo.dart';
import 'halaman_jam_dunia.dart';
import 'halaman_kalkulator_kurs.dart';
import 'halaman_mini_game.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_sertifikat_blockchain.dart';
import 'halaman_chat_traveler.dart';
import 'halaman_status_pesanan.dart';

// Halaman Hub Fitur Cerdas: Pusat Navigasi Seluruh Fitur Khusus Tugas Akhir
class HalamanFiturCerdas extends StatelessWidget {
  const HalamanFiturCerdas({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuFitur = [
      {
        'judul': 'AI Lens Scanner',
        'subjudul': 'Pindai foto barang impian ala Google Lens',
        'ikon': Icons.camera_enhance_rounded,
        'warna': Colors.purple,
        'halaman': const HalamanPemindaiAi(),
        'tag': 'AI Vision',
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
        'subjudul': 'Goyangkan HP untuk mengocok diskon jastip',
        'ikon': Icons.vibration_rounded,
        'warna': Colors.amber.shade800,
        'halaman': const HalamanShakePromo(),
        'tag': 'Sensor Gerak',
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
        'subjudul': 'Konversi JPY, KRW, GBP, USD, SGD ke Rupiah',
        'ikon': Icons.currency_exchange_rounded,
        'warna': Colors.green.shade700,
        'halaman': const HalamanKalkulatorKurs(),
        'tag': 'Mata Uang',
      },
      {
        'judul': 'Mini Game Koper Jastip',
        'subjudul': 'Kuis tebak harga barang untuk bonus koin jastip',
        'ikon': Icons.videogame_asset_rounded,
        'warna': Colors.indigo.shade700,
        'halaman': const HalamanMiniGame(),
        'tag': 'Mini Game',
      },
      {
        'judul': 'Peta & Titik Temu LBS',
        'subjudul': 'Cari pos serah terima barang COD terdekat via GPS',
        'ikon': Icons.location_on_rounded,
        'warna': Colors.redAccent.shade700,
        'halaman': const HalamanPetaLokasi(),
        'tag': 'LBS / GPS',
      },
      {
        'judul': 'Sertifikat Blockchain',
        'subjudul': 'Verifikasi keaslian struk belanja berantai SHA-256',
        'ikon': Icons.link_rounded,
        'warna': Colors.blueGrey.shade800,
        'halaman': const HalamanSertifikatBlockchain(),
        'tag': 'Web3 Ledger',
      },
      {
        'judul': 'Chat dengan Traveler',
        'subjudul': 'Ruang diskusi dan negosiasi langsung antar pengguna',
        'ikon': Icons.forum_rounded,
        'warna': Colors.teal.shade600,
        'halaman': const HalamanChatTraveler(),
        'tag': 'Komunikasi',
      },
      {
        'judul': 'Pelacak Pesanan & Rekber Escrow',
        'subjudul': 'Pantau siklus titipan, proteksi dana rekber, & LBS',
        'ikon': Icons.local_shipping_rounded,
        'warna': Colors.deepOrange.shade700,
        'halaman': const HalamanStatusPesanan(),
        'tag': 'Alur Bisnis',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Pusat Fitur Cerdas'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teknologi & Utilitas JastipGo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seluruh fitur canggih terintegrasi untuk mendukung kenyamanan transaksi belanja mancanegara Anda.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
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
                    );
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
