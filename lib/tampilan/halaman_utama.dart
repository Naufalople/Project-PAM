import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_otentikasi.dart';
import 'halaman_beranda.dart';
import 'halaman_keranjang.dart';
import 'halaman_kelola_pesanan_traveler.dart';
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
  String _peranAktif = 'PEMESAN';

  @override
  void initState() {
    super.initState();
    _indeksAktif = widget.indeksAwal;
    _muatPeran();
  }

  Future<void> _muatPeran() async {
    final peran = await LayananOtentikasi.ambilPeranAktif();
    if (mounted && peran != _peranAktif) {
      setState(() {
        _peranAktif = peran;
      });
    }
  }

  void _pindahKeTab(int indeks) {
    setState(() {
      _indeksAktif = indeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool adalahTraveler = _peranAktif == 'TRAVELER';

    final List<Widget> daftarHalaman = [
      HalamanBeranda(padaPindahTab: _pindahKeTab),
      adalahTraveler
          ? const HalamanKelolaPesananTraveler()
          : HalamanKeranjang(padaPindahTab: _pindahKeTab),
      HalamanFiturCerdas(peranOverride: _peranAktif),
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
            _muatPeran();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            adalahTraveler
                ? BottomNavigationBarItem(
                    icon: ValueListenableBuilder<Box>(
                      valueListenable: Hive.box(LayananBasisDataLokal.namaKotakPesanan).listenable(),
                      builder: (context, box, child) {
                        return Badge(
                          isLabelVisible: box.isNotEmpty,
                          label: Text('${box.length}'),
                          child: const Icon(Icons.assignment_outlined),
                        );
                      },
                    ),
                    activeIcon: ValueListenableBuilder<Box>(
                      valueListenable: Hive.box(LayananBasisDataLokal.namaKotakPesanan).listenable(),
                      builder: (context, box, child) {
                        return Badge(
                          isLabelVisible: box.isNotEmpty,
                          label: Text('${box.length}'),
                          child: const Icon(Icons.assignment_rounded),
                        );
                      },
                    ),
                    label: 'Kelola Titipan',
                  )
                : BottomNavigationBarItem(
                    icon: ValueListenableBuilder<Box>(
                      valueListenable: Hive.box(LayananBasisDataLokal.namaKotakKeranjang).listenable(),
                      builder: (context, box, child) {
                        return Badge(
                          isLabelVisible: box.isNotEmpty,
                          label: Text('${box.length}'),
                          child: const Icon(Icons.shopping_bag_outlined),
                        );
                      },
                    ),
                    activeIcon: ValueListenableBuilder<Box>(
                      valueListenable: Hive.box(LayananBasisDataLokal.namaKotakKeranjang).listenable(),
                      builder: (context, box, child) {
                        return Badge(
                          isLabelVisible: box.isNotEmpty,
                          label: Text('${box.length}'),
                          child: const Icon(Icons.shopping_bag_rounded),
                        );
                      },
                    ),
                    label: 'Keranjang',
                  ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Fitur Cerdas',
            ),
            const BottomNavigationBarItem(
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
