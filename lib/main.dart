import 'package:flutter/material.dart';
import 'layanan/layanan_basisdata_lokal.dart';
import 'layanan/layanan_rekber.dart';
import 'layanan/layanan_otentikasi.dart';
import 'layanan/layanan_notifikasi.dart';
import 'layanan/layanan_sinkronisasi_online.dart';
import 'layanan/layanan_supabase.dart';
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

  // Inisialisasi Database Online Utama Supabase Real-Time (TODO_PERUBAHAN_DATABASE)
  await LayananSupabase.inisialisasi();

  // Inisialisasi Sinkronisasi Real-Time Online Lintas Perangkat (Strictly Non-Firebase)
  await LayananSinkronisasiOnline.inisialisasi();

  // Periksa apakah ada sesi login aktif yang tersimpan di penyimpanan lokal
  // Sesi bersifat persisten: pengguna TIDAK AKAN logout kecuali menekan tombol logout
  final bool sudahMasuk = await LayananOtentikasi.cekApakahSudahMasuk();

  runApp(AplikasiJastipGo(sudahMasuk: sudahMasuk));
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
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi kembali aktif, sinkronkan data online secara mulus di latar belakang
      LayananSinkronisasiOnline.sinkronkanPesananOnline();
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
