import 'package:flutter/material.dart';

// Model Notifikasi Mobile
class ModelNotifikasi {
  final String id;
  final String judul;
  final String pesan;
  final DateTime waktu;
  final IconData ikon;
  final Color warna;

  ModelNotifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.ikon = Icons.notifications_active,
    this.warna = Colors.blue,
  });
}

// Layanan Notifikasi Berbasis Mobile
class LayananNotifikasi {
  // Riwayat notifikasi yang diterima pengguna
  static final List<ModelNotifikasi> _riwayatNotifikasi = [
    ModelNotifikasi(
      id: 'NOTIF-1',
      judul: 'Selamat Datang di JastipGo!',
      pesan: 'Temukan kemudahan titip barang original dari Jepang, Korea, & London.',
      waktu: DateTime.now().subtract(const Duration(hours: 2)),
      ikon: Icons.celebration,
      warna: Colors.amber,
    ),
  ];

  static List<ModelNotifikasi> ambilSemuaNotifikasi() {
    return List.from(_riwayatNotifikasi);
  }

  // Tampilkan notifikasi Heads-Up / Pop-up Banner pada aplikasi
  static void kirimNotifikasi(
    BuildContext context, {
    required String judul,
    required String pesan,
    IconData ikon = Icons.check_circle,
    Color warna = Colors.green,
  }) {
    final notifBaru = ModelNotifikasi(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      judul: judul,
      pesan: pesan,
      waktu: DateTime.now(),
      ikon: ikon,
      warna: warna,
    );

    _riwayatNotifikasi.insert(0, notifBaru);

    // Tampilkan SnackBar / Banner Notifikasi di atas layar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, color: warna, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pesan,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
