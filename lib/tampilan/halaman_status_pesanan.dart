import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_firebase.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_sinkronisasi_online.dart';
import '../model/model_pengguna.dart';
import '../model/model_pesanan_jastip.dart';
import 'halaman_chat_traveler.dart';
import 'halaman_dompet_rekber.dart';
import 'halaman_kelola_pesanan_traveler.dart';
import 'halaman_peta_lokasi.dart';

// Halaman Khusus Status & Pelacakan Pesanan untuk Pemesan
// Fitur Khusus Sisi Pemesan:
// 1. Menampilkan daftar pesanan aktif yang benar-benar dibuat pengguna
// 2. Memantau rincian barang dan lokasi fisik terkini barang titipan
// 3. Memantau progres pembelian oleh traveler di luar negeri
// 4. Memilih metode penyerahan saat checkout (COD LBS Google Maps / Kurir)
// 5. Mengonfirmasi barang diterima & sesuai untuk mencairkan dana Rekber Escrow
// 6. Chat langsung dua arah dengan Traveler (Bukan Chat Bot)
class HalamanStatusPesanan extends StatefulWidget {
  final String? idPesananTerpilih;

  // Parameter kompatibilitas navigasi sebelumnya
  final String? idPesanan;
  final String? namaBarang;
  final String? negaraAsal;
  final int? totalHargaIdr;
  final String? peranOverride;
  final ModelPengguna? profilOverride;

  const HalamanStatusPesanan({
    super.key,
    this.idPesananTerpilih,
    this.idPesanan,
    this.namaBarang,
    this.negaraAsal,
    this.totalHargaIdr,
    this.peranOverride,
    this.profilOverride,
  });

  @override
  State<HalamanStatusPesanan> createState() => _HalamanStatusPesananState();
}

class _HalamanStatusPesananState extends State<HalamanStatusPesanan> {
  List<ModelPesananJastip> _daftarPesanan = [];
  ModelPesananJastip? _pesananAktif;
  bool _sedangMemuat = true;
  String _peranAktif = 'PEMESAN';
  // Kategori filter tab: 'BELUM_DITERIMA' atau 'SUDAH_DITERIMA' (Poin 5)
  String _kategoriTab = 'BELUM_DITERIMA';
  StreamSubscription<ModelPesananJastip>? _subPesananStream;
  StreamSubscription<ModelPesananJastip>? _subFirebaseStream;
  Timer? _timerPesananRealtime;

  @override
  void initState() {
    super.initState();
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _sedangMemuat = false;
      _peranAktif = widget.peranOverride ?? widget.profilOverride?.peran ?? 'PEMESAN';
      final profil = widget.profilOverride;
      _daftarPesanan = profil != null
          ? LayananBasisDataLokal.ambilPesananUntukPengguna(
              userId: profil.id.toString(),
              email: profil.email,
            )
          : LayananBasisDataLokal.ambilSemuaPesanan();
      if (_daftarPesanan.isNotEmpty) {
        final targetId = widget.idPesananTerpilih ?? widget.idPesanan;
        if (targetId != null) {
          _pesananAktif = _daftarPesanan.where((p) => p.idPesanan == targetId).firstOrNull ?? _daftarPesanan.first;
        } else {
          _pesananAktif = _daftarPesanan.first;
        }
        if (_pesananAktif!.apakahDibatalkan) {
          _kategoriTab = 'DIBATALKAN';
        } else if (_pesananAktif!.apakahSudahDiterima) {
          _kategoriTab = 'SUDAH_DITERIMA';
        } else {
          _kategoriTab = 'BELUM_DITERIMA';
        }
      }
    }
    _muatDaftarPesanan();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      LayananSinkronisasiOnline.mulaiKoneksiStreamRealtime();
      LayananSinkronisasiOnline.sinkronkanPesananOnline();
    }
    LayananSinkronisasiOnline.pemicuPembaruanPesanan.addListener(_muatDaftarPesanan);

    // Continuous Real-Time Stream (SSE Keep-Alive) untuk Pemesan
    _subPesananStream = LayananSinkronisasiOnline.streamPesanan.listen((pesananBaru) {
      if (mounted) {
        _muatDaftarPesanan();
      }
    });

    // Firebase Realtime Database Stream
    _subFirebaseStream = LayananFirebase.streamPesanan.listen((_) {
      if (mounted) {
        _muatDaftarPesanan();
      }
    });

    // Fallback polling periodik (2 detik) jika koneksi stream drop
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _timerPesananRealtime = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          LayananSinkronisasiOnline.sinkronkanPesananOnline();
        }
      });
    }
  }

  @override
  void dispose() {
    _timerPesananRealtime?.cancel();
    _subPesananStream?.cancel();
    _subFirebaseStream?.cancel();
    LayananSinkronisasiOnline.pemicuPembaruanPesanan.removeListener(_muatDaftarPesanan);
    super.dispose();
  }

  Future<void> _muatDaftarPesanan() async {
    final profil = widget.profilOverride ?? await LayananOtentikasi.ambilProfilAktif();
    final peran = widget.peranOverride ?? profil?.peran ?? await LayananOtentikasi.ambilPeranAktif();
    final list = LayananBasisDataLokal.ambilPesananUntukPengguna(
      userId: profil?.id.toString(),
      email: profil?.email,
    );
    if (!mounted) return;
    setState(() {
      _peranAktif = peran;
      _daftarPesanan = list;
      _sedangMemuat = false;

      final pesananBelumDiterima = list.where((p) => p.apakahBelumDiterima).toList();
      final pesananSudahDiterima = list.where((p) => p.apakahSudahDiterima).toList();
      final pesananDibatalkan = list.where((p) => p.apakahDibatalkan).toList();

      final targetId = widget.idPesananTerpilih ?? widget.idPesanan ?? _pesananAktif?.idPesanan;
      if (targetId != null && targetId.isNotEmpty) {
        final dicari = list.where((p) => p.idPesanan == targetId).firstOrNull;
        if (dicari != null) {
          _kategoriTab = dicari.apakahDibatalkan
              ? 'DIBATALKAN'
              : (dicari.apakahSudahDiterima ? 'SUDAH_DITERIMA' : 'BELUM_DITERIMA');
          _pesananAktif = dicari;
          return;
        }
      }

      final listTampil = _kategoriTab == 'BELUM_DITERIMA'
          ? pesananBelumDiterima
          : (_kategoriTab == 'SUDAH_DITERIMA' ? pesananSudahDiterima : pesananDibatalkan);

      if (listTampil.isNotEmpty) {
        _pesananAktif = listTampil.first;
      } else if (pesananBelumDiterima.isNotEmpty) {
        _kategoriTab = 'BELUM_DITERIMA';
        _pesananAktif = pesananBelumDiterima.first;
      } else if (pesananSudahDiterima.isNotEmpty) {
        _kategoriTab = 'SUDAH_DITERIMA';
        _pesananAktif = pesananSudahDiterima.first;
      } else if (pesananDibatalkan.isNotEmpty) {
        _kategoriTab = 'DIBATALKAN';
        _pesananAktif = pesananDibatalkan.first;
      } else {
        _pesananAktif = null;
      }
    });
  }

  String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Pesanan')),
        body: Center(
          child: Platform.environment.containsKey('FLUTTER_TEST')
              ? const Text('Memuat...')
              : const CircularProgressIndicator(),
        ),
      );
    }

    // Proteksi RBAC: Traveler tidak dapat mengakses pelacakan pesanan (Poin 2)
    if (_peranAktif == 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Status & Pelacakan Pesanan'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, size: 64, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akses Khusus Pemesan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Halaman Status & Pelacakan Pesanan hanya diperuntukkan bagi akun Pemesan (Requester) untuk memantau barang titipan mereka.\n\nSebagai Traveler, tugas Anda adalah memantau dan memperbarui pesanan masuk dari pemesan melalui menu "Kelola Pesanan Masuk".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HalamanKelolaPesananTraveler(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  label: const Text('Buka Kelola Pesanan Masuk'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Menu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tampilan Bersih jika Pengguna Belum Memesan Barang Apapun
    if (_daftarPesanan.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Pelacakan Status Pesanan'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Sinkronkan Pesanan Online',
              icon: const Icon(Icons.sync_rounded),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menyinkronkan data pesanan dari server online...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                await LayananSinkronisasiOnline.sinkronkanPesananOnline();
                await _muatDaftarPesanan();
              },
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_outlined, size: 64, color: Colors.teal.shade700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Pesanan Aktif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda belum memiliki pesanan jastip aktif. Silakan cari barang impian dari toko luar negeri di Beranda, masukkan ke keranjang, dan lakukan pemesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Jelajahi Produk di Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pesananBelumDiterima = _daftarPesanan.where((p) => p.apakahBelumDiterima).toList();
    final pesananSudahDiterima = _daftarPesanan.where((p) => p.apakahSudahDiterima).toList();
    final pesananDibatalkan = _daftarPesanan.where((p) => p.apakahDibatalkan).toList();
    final listTampil = _kategoriTab == 'BELUM_DITERIMA'
        ? pesananBelumDiterima
        : (_kategoriTab == 'SUDAH_DITERIMA' ? pesananSudahDiterima : pesananDibatalkan);

    ModelPesananJastip? pesanan = _pesananAktif;
    if (pesanan != null && !listTampil.any((p) => p.idPesanan == pesanan!.idPesanan)) {
      pesanan = listTampil.isNotEmpty ? listTampil.first : null;
    } else if (pesanan == null && listTampil.isNotEmpty) {
      pesanan = listTampil.first;
    }

    final int tahap = pesanan?.tahapStatus ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Pelacakan Status Pesanan'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Pesanan Online',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyinkronkan data pesanan dari server online...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await LayananSinkronisasiOnline.sinkronkanPesananOnline();
              await _muatDaftarPesanan();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.forum_rounded),
        label: const Text('Chat Langsung Traveler'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HalamanChatTraveler(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========================================================
            // FILTER KATEGORI PESANAN (POIN 5: BELUM / SUDAH DITERIMA)
            // ========================================================
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _kategoriTab = 'BELUM_DITERIMA';
                          final listFilter = _daftarPesanan.where((p) => p.apakahBelumDiterima).toList();
                          _pesananAktif = listFilter.isNotEmpty ? listFilter.first : null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _kategoriTab == 'BELUM_DITERIMA'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pending_actions_rounded,
                                size: 16,
                                color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.teal.shade800 : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Belum Diterima',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _kategoriTab == 'BELUM_DITERIMA' ? FontWeight.bold : FontWeight.w500,
                                  color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.teal.shade900 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.teal.shade800 : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pesananBelumDiterima.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _kategoriTab = 'SUDAH_DITERIMA';
                          final listFilter = _daftarPesanan.where((p) => p.apakahSudahDiterima).toList();
                          _pesananAktif = listFilter.isNotEmpty ? listFilter.first : null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _kategoriTab == 'SUDAH_DITERIMA' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _kategoriTab == 'SUDAH_DITERIMA'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 15,
                                color: _kategoriTab == 'SUDAH_DITERIMA' ? Colors.green.shade700 : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sudah Diterima',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _kategoriTab == 'SUDAH_DITERIMA' ? FontWeight.bold : FontWeight.w500,
                                  color: _kategoriTab == 'SUDAH_DITERIMA' ? Colors.green.shade800 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _kategoriTab == 'SUDAH_DITERIMA' ? Colors.green.shade700 : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pesananSudahDiterima.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _kategoriTab = 'DIBATALKAN';
                          final listFilter = _daftarPesanan.where((p) => p.apakahDibatalkan).toList();
                          _pesananAktif = listFilter.isNotEmpty ? listFilter.first : null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _kategoriTab == 'DIBATALKAN' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _kategoriTab == 'DIBATALKAN'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 15,
                                color: _kategoriTab == 'DIBATALKAN' ? Colors.red.shade700 : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dibatalkan',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _kategoriTab == 'DIBATALKAN' ? FontWeight.bold : FontWeight.w500,
                                  color: _kategoriTab == 'DIBATALKAN' ? Colors.red.shade800 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _kategoriTab == 'DIBATALKAN' ? Colors.red.shade700 : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pesananDibatalkan.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (listTampil.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? Icons.check_circle_outline_rounded
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? Icons.inventory_2_outlined
                              : Icons.cancel_presentation_rounded),
                      size: 48,
                      color: _kategoriTab == 'BELUM_DITERIMA'
                          ? Colors.teal.shade600
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? Colors.green.shade600
                              : Colors.red.shade400),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Tidak Ada Pesanan yang Sedang Berjalan'
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? 'Belum Ada Pesanan yang Diterima'
                              : 'Tidak Ada Pesanan yang Dibatalkan'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Semua pesanan Anda telah selesai atau dibatalkan.'
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? 'Riwayat pesanan yang telah Anda terima akan muncul di sini.'
                              : 'Bagus! Tidak ada pesanan Anda yang dibatalkan oleh traveler.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // DAFTAR PILIHAN PESANAN DALAM KATEGORI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Pesanan Belum Diterima:'
                          : _kategoriTab == 'DIBATALKAN'
                              ? 'Pesanan Dibatalkan:'
                              : 'Pesanan Sudah Diterima:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${listTampil.length} Pesanan',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 94,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: listTampil.length,
                  itemBuilder: (context, index) {
                    final p = listTampil[index];
                    final bool terpilih = pesanan != null && p.idPesanan == pesanan.idPesanan;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _pesananAktif = p;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 190,
                        margin: const EdgeInsets.only(right: 10, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: terpilih ? Colors.teal.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: terpilih ? Colors.teal.shade800 : Colors.grey.shade300,
                            width: terpilih ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: terpilih ? 0.08 : 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.negaraAsal,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: terpilih ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: terpilih ? Colors.teal.shade700 : Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.daftarBarang.length} Item',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: terpilih ? Colors.white : Colors.teal.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.idPesanan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: terpilih ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${_formatRupiah(p.totalHargaIdr)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: terpilih ? Colors.amber.shade300 : Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (pesanan != null) ...[
              // KARTU KHUSUS STATUS DIBATALKAN (BARANG KOSONG) & AUTO-REFUND REKBER
              if (pesanan.apakahDibatalkan) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.cancel_rounded, color: Colors.red.shade800, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PESANAN DIBATALKAN (BARANG KOSONG) ❌',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.red),
                                ),
                                Text(
                                  pesanan.alasanPembatalan ?? 'Barang tidak tersedia di toko fisik luar negeri',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dana sebesar Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah 100% DIKEMBALIKAN ke Saldo Dompet Anda secara otomatis dari sistem Rekber.',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HalamanDompetRekber()),
                            );
                          },
                          icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                          label: const Text('Lihat Saldo Dompet & Riwayat Refund'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // KARTU LOKASI FISIK BARANG LIVE
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.amberAccent, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'LOKASI FISIK BARANG TITIPAN SAAT INI:',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pesanan.lokasiTerkini,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                  Text(
                    'Traveler: ${pesanan.namaTraveler} • Asal: ${pesanan.negaraAsal}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  if (tahap >= 5 && pesanan.metodePenyerahan == 'COD_LBS') ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Buka Titik Temu COD di Google Maps (LBS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // DAFTAR RINCIAN SEMUA BARANG DI PESANAN INI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Barang (${pesanan.daftarBarang.length} Produk):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tahap == 6 ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tahap == 6 ? Colors.green.shade300 : Colors.amber.shade400,
                          ),
                        ),
                        child: Text(
                          tahap == 6 ? 'SELESAI' : 'DIPROSES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tahap == 6 ? Colors.green.shade800 : Colors.teal.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...pesanan.daftarBarang.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (item.fotoUrl.isNotEmpty && !Platform.environment.containsKey('FLUTTER_TEST'))
                                ? Image.network(
                                    item.fotoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 52,
                                      height: 52,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaBarang,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Toko: ${item.namaToko} (${item.negara})',
                                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Jumlah: ${item.jumlah} pcs', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                    Text('Rp ${_formatRupiah(item.hargaIdr)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Total Pembayaran Titipan:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TIMELINE STATUS PESANAN (PERSPEKTIF PEMESAN)
            const Text(
              'Timeline Perjalanan Barang Titipan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // STEP 1: Pesanan Dibuat
            _bangunItemTimeline(
              nomor: 1,
              judul: '1. Pesanan Dibuat & Menunggu ACC Traveler',
              deskripsi: tahap >= 2
                  ? 'Traveler ${pesanan.namaTraveler} telah menyetujui pesanan Anda.'
                  : 'Pesanan telah terkirim. Menunggu persetujuan (ACC) dari traveler ${pesanan.namaTraveler} di ${pesanan.negaraAsal}.',
              ikon: Icons.assignment_turned_in_rounded,
              sudahLewat: tahap >= 2,
              sedangAktif: tahap == 1,
            ),

            // STEP 2: Traveler Bergerak ke Toko
            _bangunItemTimeline(
              nomor: 2,
              judul: '2. Traveler Bersiap ke Toko Resmi di Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Traveler telah tiba di toko dan menyelesaikan pembelian barang titipan Anda.'
                  : (tahap == 2
                      ? 'Traveler ${pesanan.namaTraveler} sedang dalam perjalanan menuju toko resmi di ${pesanan.negaraAsal}.'
                      : 'Menunggu jadwal belanja traveler.'),
              ikon: Icons.directions_walk_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 2,
            ),

            // STEP 3: Barang Sudah Dibeli di Toko
            _bangunItemTimeline(
              nomor: 3,
              judul: '3. Barang Sudah Dibeli di Toko Resmi Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Semua ${pesanan.daftarBarang.length} barang telah berhasil dibeli oleh traveler di toko resmi.'
                  : 'Menunggu konfirmasi pembelian barang dari traveler.',
              ikon: Icons.storefront_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 3,
            ),

            // STEP 4: Dalam Penerbangan ke Indonesia
            _bangunItemTimeline(
              nomor: 4,
              judul: '4. Dalam Penerbangan Menuju Indonesia',
              deskripsi: tahap >= 4
                  ? 'Koper titipan dibawa dalam bagasi pesawat internasional menuju bandara tujuan di Indonesia.'
                  : 'Menunggu jadwal penerbangan pulang traveler ke Indonesia.',
              ikon: Icons.airplanemode_active_rounded,
              sudahLewat: tahap >= 4,
              sedangAktif: tahap == 4,
            ),

            // STEP 5: Tiba di Indonesia & Serah Terima
            _bangunItemTimeline(
              nomor: 5,
              judul: '5. Mendarat di Indonesia & Pelaksanaan Serah Terima',
              deskripsi: tahap >= 5
                  ? 'Barang titipan telah mendarat di bandara Indonesia. Proses serah terima dilakukan sesuai pilihan Anda saat checkout.'
                  : 'Menunggu pesawat mendarat di bandara Indonesia.',
              ikon: Icons.luggage_rounded,
              sudahLewat: tahap >= 5,
              sedangAktif: tahap == 5,
              aksiTambahan: tahap == 5
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pesanan.metodePenyerahan == 'COD_LBS' ? Icons.location_on : Icons.local_shipping,
                                color: Colors.teal.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Metode Serah Terima Pilihan Anda (Saat Checkout):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (pesanan.metodePenyerahan == 'COD_LBS') ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📍 Titik Temu COD (LBS Google Maps)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Anda memilih untuk mengambil sendiri barang titipan di Hub Titik Temu JastipGo (Kampus UPN Condongcatur / Bandara).',
                                    style: TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                                      );
                                    },
                                    icon: const Icon(Icons.navigation_rounded, size: 14),
                                    label: const Text('Buka Rute & Lokasi Titik Temu (LBS Maps)', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🚚 Pengiriman Kurir Ekspedisi ke Rumah',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Alamat Pengiriman:\n${pesanan.alamatPengiriman.isNotEmpty ? pesanan.alamatPengiriman : "Jl. Babarsari No. 12, Caturtunggal, Sleman, D.I. Yogyakarta"}',
                                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Traveler sedang memproses paket untuk dikirimkan melalui kurir.',
                                    style: TextStyle(fontSize: 10.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : null,
            ),

            // STEP 6: Selesai & Pencairan Dana Rekber
            _bangunItemTimeline(
              nomor: 6,
              judul: '6. Konfirmasi Barang Sesuai & Pencairan Dana',
              deskripsi: tahap == 6
                  ? 'Transaksi Selesai 100%! Semua barang telah Anda terima dan dana resmi ditransfer ke dompet traveler.'
                  : 'Periksa fisik barang titipan. Jika sesuai, tekan tombol konfirmasi di bawah atau tunggu auto-selesai garansi 5 hari.',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: tahap == 6,
              sedangAktif: tahap == 6,
              garisTerakhir: true,
            ),
            const SizedBox(height: 18),

            // ========================================================
            // INFORMASI STATUS PEMESAN (READ-ONLY - KHUSUS TRAVELER DAPAT UBAH)
            // ========================================================
            if (tahap == ModelPesananJastip.statusDibatalkan) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red.shade800, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan Telah Dibatalkan (Barang Kosong)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah 100% dikembalikan dari Rekber ke Dompet Pemesan Anda.',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (tahap < 6) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.remove_red_eye_rounded, color: Colors.indigo.shade800, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Pemantauan Status (Khusus Pemesan)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hanya akun Traveler yang diizinkan memperbarui status pesanan. Setiap progres pembelian dan lokasi terkini disinkronisasikan secara real-time melalui Firebase Database.',
                            style: TextStyle(fontSize: 11, color: Colors.indigo.shade800, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (tahap == 6) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade800, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesanan Sudah Diterima (Selesai)!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13.5),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pesanan ini telah selesai dan tercatat dalam kategori "Sudah Diterima". Terima kasih telah berbelanja via JastipGo.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ], // Penutup if (pesanan != null)
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Helper Widget Timeline
  Widget _bangunItemTimeline({
    required int nomor,
    required String judul,
    required String deskripsi,
    required IconData ikon,
    required bool sudahLewat,
    required bool sedangAktif,
    bool garisTerakhir = false,
    Widget? aksiTambahan,
  }) {
    final Color warnaIndikator = sudahLewat ? Colors.teal.shade700 : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sudahLewat ? Colors.teal.shade700 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIndikator, width: 2),
                boxShadow: sedangAktif
                    ? [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                ikon,
                size: 18,
                color: sudahLewat ? Colors.white : Colors.grey.shade400,
              ),
            ),
            if (!garisTerakhir)
              Container(
                width: 2,
                height: aksiTambahan != null ? 84 : 54,
                color: sudahLewat ? Colors.teal.shade600 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: sedangAktif ? Colors.teal.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deskripsi,
                style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
              ),
              if (aksiTambahan != null) ...[
                const SizedBox(height: 8),
                aksiTambahan,
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
