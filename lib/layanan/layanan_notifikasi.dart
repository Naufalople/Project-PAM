import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

// Layanan Notifikasi Berbasis Mobile & Status Bar Android OS
class LayananNotifikasi {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _terinisialisasi = false;

  // Inisialisasi Android Notification Channel & Settings
  static Future<void> inisialisasiNotifikasiSistem() async {
    if (_terinisialisasi) return;

    try {
      const AndroidInitializationSettings inisialisasiAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings inisialisasiIos =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings pengaturanInisialisasi =
          InitializationSettings(
        android: inisialisasiAndroid,
        iOS: inisialisasiIos,
      );

      await _localNotifications.initialize(
        settings: pengaturanInisialisasi,
      );

      // Minta izin Android 13+ (POST_NOTIFICATIONS)
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _terinisialisasi = true;
    } catch (_) {
      // Menghindari crash pada test runner lingkungan non-perangkat
    }
  }

  // Tampilkan notifikasi di Notification Tray / Status Bar Sistem
  static Future<void> tampilkanNotifikasiStatusBar({
    required String judul,
    required String pesan,
    int? id,
  }) async {
    try {
      if (!_terinisialisasi) {
        await inisialisasiNotifikasiSistem();
      }

      const AndroidNotificationDetails rincianAndroid =
          AndroidNotificationDetails(
        'jastipgo_channel_id',
        'Notifikasi JastipGo',
        channelDescription:
            'Saluran resmi notifikasi status pesanan, kupon promo, dan keamanan sesi JastipGo',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails rincianIos = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails rincianNotifikasi = NotificationDetails(
        android: rincianAndroid,
        iOS: rincianIos,
      );

      final int notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
      await _localNotifications.show(
        id: notifId,
        title: judul,
        body: pesan,
        notificationDetails: rincianNotifikasi,
      );
    } catch (_) {
      // Non-Android fallback
    }
  }

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

  // Pemicu Notifikasi Real-Time Sistem OS & Penyimpan Riwayat (Dapat dipanggil dari Background Sync tanpa BuildContext)
  static Future<void> picuNotifikasiSistem({
    required String judul,
    required String pesan,
    IconData ikon = Icons.notifications_active,
    Color warna = Colors.blue,
  }) async {
    final notifBaru = ModelNotifikasi(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      judul: judul,
      pesan: pesan,
      waktu: DateTime.now(),
      ikon: ikon,
      warna: warna,
    );

    _riwayatNotifikasi.insert(0, notifBaru);
    await tampilkanNotifikasiStatusBar(judul: judul, pesan: pesan);
  }

  // Tampilkan notifikasi Heads-Up / Pop-up Banner pada aplikasi DAN pemicu status bar OS
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

    // 1. Pemicu Notifikasi Nyata di Notification Tray / Status Bar Sistem OS
    tampilkanNotifikasiStatusBar(judul: judul, pesan: pesan);

    // 2. Tampilkan SnackBar / Banner Notifikasi di atas layar
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
