import 'package:flutter/material.dart';
import 'halaman_beranda.dart';
import 'halaman_keranjang.dart';
import 'halaman_fitur_cerdas.dart';
import 'halaman_profil.dart';

// Halaman Utama dengan Bottom Navigation Bar (Indexed Navigation Sesuai Modul 4)
class HalamanUtama extends StatefulWidget {
  final int indeksAwal;

  const HalamanUtama({super.key, this.indeksAwal = 0});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  late int _indeksAktif;

  @override
  void initState() {
    super.initState();
    _indeksAktif = widget.indeksAwal;
  }

  void _pindahKeTab(int indeks) {
    setState(() {
      _indeksAktif = indeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> daftarHalaman = [
      HalamanBeranda(padaPindahTab: _pindahKeTab),
      HalamanKeranjang(padaPindahTab: _pindahKeTab),
      const HalamanFiturCerdas(),
      const HalamanProfil(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _indeksAktif,
        children: daftarHalaman,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _indeksAktif,
          onTap: (index) {
            setState(() {
              _indeksAktif = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal.shade800,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Keranjang',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Fitur Cerdas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
