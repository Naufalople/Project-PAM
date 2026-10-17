import 'package:flutter/material.dart';
import 'layanan/layanan_basisdata_lokal.dart';
import 'layanan/layanan_blockchain.dart';
import 'layanan/layanan_otentikasi.dart';
import 'tampilan/halaman_masuk.dart';
import 'tampilan/halaman_utama.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Basis Data Lokal Hive (NoSQL)
  await LayananBasisDataLokal.inisialisasi();

  // Inisialisasi Blok Awal Blockchain (Genesis Block)
  await LayananBlockchain.inisialisasiBlockchain();

  // Cek apakah ada sesi pengguna yang tersimpan di SharedPreferences
  final bool sudahMasuk = await LayananOtentikasi.cekApakahSudahMasuk();

  runApp(AplikasiJastipGo(sudahMasuk: sudahMasuk));
}

// Aplikasi Utama JastipGo
class AplikasiJastipGo extends StatelessWidget {
  final bool sudahMasuk;

  const AplikasiJastipGo({super.key, required this.sudahMasuk});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: sudahMasuk ? const HalamanUtama() : const HalamanMasuk(),
    );
  }
}
