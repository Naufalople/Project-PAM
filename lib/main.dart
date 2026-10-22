import 'package:flutter/material.dart';
import 'layanan/layanan_basisdata_lokal.dart';
import 'layanan/layanan_rekber.dart';
import 'layanan/layanan_otentikasi.dart';
import 'layanan/layanan_notifikasi.dart';
import 'layanan/layanan_sinkronisasi_online.dart';
import 'tampilan/halaman_masuk.dart';
import 'tampilan/halaman_utama.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Basis Data Lokal Hive (NoSQL)
  await LayananBasisDataLokal.inisialisasi();

  // Inisialisasi Sistem Keamanan Rekber (Escrow)
  await LayananRekber.inisialisasi();

  // Inisialisasi Layanan Notifikasi Status Bar Sistem OS
  await LayananNotifikasi.inisialisasiNotifikasiSistem();

  // Inisialisasi Sinkronisasi Real-Time Online Lintas Perangkat (Strictly Non-Firebase)
  await LayananSinkronisasiOnline.inisialisasi();

  // Reset sesi aktif saat aplikasi dibuka dari keadaan mati (Cold Start)
  // Menjamin jika apk ditutup/dibersihkan dari recent apps, pengguna diwajibkan login ulang
  await LayananOtentikasi.tanganiColdStart();

  runApp(const AplikasiJastipGo(sudahMasuk: false));
}

// Aplikasi Utama JastipGo dengan Pemantauan Siklus Hidup (AppLifecycle & Auto-Logout)
class AplikasiJastipGo extends StatefulWidget {
  final bool sudahMasuk;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const AplikasiJastipGo({super.key, this.sudahMasuk = false});

  @override
  State<AplikasiJastipGo> createState() => _AplikasiJastipGoState();
}

class _AplikasiJastipGoState extends State<AplikasiJastipGo> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 1. Simpan timestamp saat aplikasi diminimalkan / masuk background
      LayananOtentikasi.catatWaktuMasukBackground();
    } else if (state == AppLifecycleState.resumed) {
      // 2. Saat aplikasi kembali aktif, periksa apakah sudah lebih dari 15 menit
      _periksaTimeoutBackground();
    } else if (state == AppLifecycleState.detached) {
      // 3. Saat aplikasi dimatikan/dibersihkan dari recent apps, langsung hapus sesi
      LayananOtentikasi.keluarSesi();
    }
  }

  Future<void> _periksaTimeoutBackground() async {
    final bool kedaluwarsa = await LayananOtentikasi.apakahSesiKedaluwarsa();
    if (kedaluwarsa) {
      await LayananOtentikasi.keluarSesi();
      AplikasiJastipGo.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HalamanMasuk(pesanSesiKedaluwarsa: true),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AplikasiJastipGo.navigatorKey,
      title: 'JastipGo - Smart Global Jastip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal.shade800,
          secondary: Colors.amber.shade700,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: widget.sudahMasuk ? const HalamanUtama() : const HalamanMasuk(),
    );
  }
}
