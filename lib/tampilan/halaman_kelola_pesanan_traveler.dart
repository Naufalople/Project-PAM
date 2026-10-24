import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_firebase.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_rekber.dart';
import '../layanan/layanan_sinkronisasi_online.dart';
import '../model/model_pesanan_jastip.dart';
import 'halaman_dompet_rekber.dart';
import 'halaman_peta_lokasi.dart';

// Halaman Khusus Pengelolaan Pesanan Titipan oleh Pembeli / Traveler di Luar Negeri (Dimas Pratama)
// Fitur Khusus Sisi Traveler:
// 1. Menerima pesanan masuk dari Pemesan dan meng-ACC
// 2. Mengonfirmasi barang sudah dibeli di toko resmi LN & mencatat struk ke Blockchain
// 3. Membawa koper titipan masuk bagasi penerbangan ke Indonesia
// 4. Mengonfirmasi tiba di Indonesia & menyesuaikan metode serah terima pilihan Pemesan (COD LBS / Kurir)
// 5. Chat langsung dua arah dengan Pemesan (Bukan Chat Bot)
class HalamanKelolaPesananTraveler extends StatefulWidget {
  final String? idPesananTerpilih;
  final String? peranOverride;

  const HalamanKelolaPesananTraveler({
    super.key,
    this.idPesananTerpilih,
    this.peranOverride,
  });

  @override
  State<HalamanKelolaPesananTraveler> createState() => _HalamanKelolaPesananTravelerState();
}

class _HalamanKelolaPesananTravelerState extends State<HalamanKelolaPesananTraveler> {
  List<ModelPesananJastip> _daftarPesanan = [];
  ModelPesananJastip? _pesananAktif;
  bool _sedangMemuat = true;
  String _peranAktif = 'TRAVELER';
  String _kategoriTab = 'BELUM_DITERIMA'; // 'BELUM_DITERIMA' atau 'SUDAH_DITERIMA'
  Timer? _timerPesananRealtime;
  StreamSubscription<ModelPesananJastip>? _subPesananStream;
  StreamSubscription<ModelPesananJastip>? _subFirebaseStream;

  @override
  void initState() {
    super.initState();
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _sedangMemuat = false;
      _peranAktif = widget.peranOverride ?? 'TRAVELER';
      _daftarPesanan = LayananBasisDataLokal.ambilSemuaPesanan();
      if (_daftarPesanan.isNotEmpty) {
        final targetId = widget.idPesananTerpilih;
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

    // Continuous Real-Time Stream (SSE Keep-Alive) untuk Traveler
    _subPesananStream = LayananSinkronisasiOnline.streamPesanan.listen((_) {
      if (mounted) {
        _muatDaftarPesanan();
      }
    });

    // Firebase Database Real-Time Stream
    _subFirebaseStream = LayananFirebase.streamPesanan.listen((_) {
      if (mounted) {
        _muatDaftarPesanan();
      }
    });

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
    final peran = widget.peranOverride ?? await LayananOtentikasi.ambilPeranAktif();
    final list = LayananBasisDataLokal.ambilSemuaPesanan();
    if (!mounted) return;
    setState(() {
      _peranAktif = peran;
      _daftarPesanan = list;
      _sedangMemuat = false;

      final pesananBelumDiterima = list.where((p) => p.apakahBelumDiterima).toList();
      final pesananSudahDiterima = list.where((p) => p.apakahSudahDiterima).toList();
      final pesananDibatalkan = list.where((p) => p.apakahDibatalkan).toList();

      final targetId = widget.idPesananTerpilih ?? _pesananAktif?.idPesanan;
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

  // 1. Traveler Meng-ACC Pesanan
  Future<void> _travelerAccPesanan() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 2;
    final lokasiBaru = 'Toko Resmi di ${pesanan.negaraAsal} (Traveler Sedang Menuju Lokasi)';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pesanan #${pesanan.idPesanan} Berhasil Di-ACC! ✅',
      pesan: 'Status pesanan diperbarui. Notifikasi telah dikirim ke pemesan bahwa Anda menyetujui pesanan ini.',
      ikon: Icons.thumb_up_alt_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // 2. Traveler Konfirmasi "Sudah Dibeli di Toko"
  Future<void> _travelerKonfirmasiSudahBeli() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 3;
    final lokasiBaru = 'Kantong Belanja Traveler di ${pesanan.negaraAsal} (Struk Resmi Diverifikasi)';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Barang Berhasil Dibeli di Toko! 🛍️',
      pesan: 'Semua ${pesanan.daftarBarang.length} item telah dibeli. Struk pembelian resmi diverifikasi aman.',
      ikon: Icons.shopping_bag_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // 3. Traveler Bawa Barang Masuk Bagasi Pesawat ke RI
  Future<void> _travelerMulaiPenerbangan() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 4;
    const lokasiBaru = 'Bagasi Pesawat Internasional Menuju Bandara Indonesia ✈️';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Penerbangan Menuju Indonesia ✈️',
      pesan: 'Koper titipan dibawa dalam bagasi penerbangan internasional menuju Indonesia.',
      ikon: Icons.flight_takeoff_rounded,
      warna: Colors.blue.shade800,
    );
  }

  // 4. Traveler Konfirmasi Mendarat di Indonesia
  Future<void> _travelerTibaDiIndonesia() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 5;
    const lokasiBaru = 'Mendarat di Indonesia (Siap COD LBS Hub Kampus UPN Jogja / Bandara) 🇮🇩';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Sudah Mendarat di Indonesia! 🇮🇩',
      pesan: 'Barang titipan siap diserahterimakan sesuai metode pilihan Pemesan.',
      ikon: Icons.place_rounded,
      warna: Colors.orange.shade800,
    );
  }

  // 5. Traveler Menyelesaikan Pesanan & Mencairkan Dana Rekber (Khusus Traveler)
  Future<void> _travelerKonfirmasiSelesai() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 6;
    const lokasiBaru = 'Telah Diserahterimakan ke Pemesan di Lokasi Tujuan (Transaksi Selesai) 🎉';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
      peranPengguna: 'TRAVELER',
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
      _kategoriTab = 'SUDAH_DITERIMA';
      _pesananAktif = pesanan;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Transaksi Selesai & Dana Rekber Cair! 🎉',
      pesan: 'Pesanan #${pesanan.idPesanan} telah berhasil diselesaikan. Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} resmi masuk ke Saldo Aktif Anda!',
      ikon: Icons.monetization_on_rounded,
      warna: Colors.green.shade800,
    );
  }

  // 6. Traveler Membatalkan Pesanan (Barang Tidak Ada) -> Auto-Refund Rekber (TODO_MANAJEMEN_PESANAN.txt Poin 2)
  Future<void> _travelerBatalkanPesananBarangKosong() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Batalkan Pesanan (Barang Kosong)?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda menyatakan barang untuk pesanan #${pesanan.idPesanan} TIDAK TERSEDIA di toko fisik luar negeri?',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SISTEM AUTO-REFUND REKBER:\nDana sebesar Rp ${_formatRupiah(pesanan.totalHargaIdr)} yang saat ini tertahan di Rekber akan OTOMATIS DIKEMBALIKAN 100% ke saldo dompet pemesan (${pesanan.namaPemesan ?? "Pemesan"}) secara real-time via Firebase Database.',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade900, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal / Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan & Auto-Refund'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    await LayananBasisDataLokal.batalkanPesananBarangKosong(
      pesanan.idPesanan,
      alasan: 'Barang tidak tersedia di toko fisik luar negeri',
      peranPengguna: 'TRAVELER',
    );

    setState(() {
      pesanan.tahapStatus = ModelPesananJastip.statusDibatalkan;
      pesanan.lokasiTerkini =
          'Dibatalkan: Barang tidak tersedia di luar negeri (Dana Di-refund 100% ke Dompet Pemesan)';
      _kategoriTab = 'DIBATALKAN';
      _pesananAktif = pesanan;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pesanan #${pesanan.idPesanan} Dibatalkan & Di-refund! 💰',
      pesan: 'Status pesanan berubah menjadi Dibatalkan. Uang Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah 100% dikembalikan dari Rekber ke dompet pemesan.',
      ikon: Icons.cancel_rounded,
      warna: Colors.red.shade800,
    );
  }

  String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  void _dialogTarikDanaTraveler() {
    final saldoTertahan = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: 'Dimas Pratama');
    final saldoAktif = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: 'Dimas Pratama');
    final controllerRek = TextEditingController();
    final controllerNominal = TextEditingController(text: saldoAktif > 0 ? saldoAktif.toString() : '');
    String bankPilihan = 'BCA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pencairan Saldo Traveler',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Banner Penjelasan Rekber
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sistem Rekber (Escrow): Uang pemesan berstatus "Dana Tertahan" (Rp ${_formatRupiah(saldoTertahan)}) dan DILARANG dicairkan sebelum pemesan mengonfirmasi "Sudah Diterima". Hanya Saldo Aktif (Rp ${_formatRupiah(saldoAktif)}) yang dapat dicairkan.',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Input Bank & Rekening
                DropdownButtonFormField<String>(
                  initialValue: bankPilihan,
                  decoration: InputDecoration(
                    labelText: 'Bank Tujuan',
                    prefixIcon: const Icon(Icons.account_balance_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BCA', child: Text('Bank Central Asia (BCA)')),
                    DropdownMenuItem(value: 'Mandiri', child: Text('Bank Mandiri')),
                    DropdownMenuItem(value: 'BNI', child: Text('Bank Negara Indonesia (BNI)')),
                    DropdownMenuItem(value: 'BRI', child: Text('Bank Rakyat Indonesia (BRI)')),
                    DropdownMenuItem(value: 'BSI', child: Text('Bank Syariah Indonesia (BSI)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => bankPilihan = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controllerRek,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nomor Rekening',
                    hintText: 'Contoh: 8820391823',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controllerNominal,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Penarikan (Rp)',
                    hintText: 'Minimal Rp 10.000',
                    prefixIcon: const Icon(Icons.money_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final nominal = int.tryParse(controllerNominal.text.trim()) ?? 0;
                    final noRek = controllerRek.text.trim();

                    if (noRek.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Nomor rekening tujuan wajib diisi.')),
                      );
                      return;
                    }

                    if (nominal <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Nominal penarikan harus lebih dari Rp 0.')),
                      );
                      return;
                    }

                    final hasil = await LayananRekber.tarikDanaKeRekening(
                      namaTraveler: 'Dimas Pratama',
                      jumlahTarik: nominal,
                      namaBank: bankPilihan,
                      nomorRekening: noRek,
                      namaPemilikRekening: 'Dimas Pratama',
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;

                    if (!hasil.berhasil) {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              Icon(Icons.gpp_bad_rounded, color: Colors.red.shade700, size: 28),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Penarikan Ditolak!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hasil.pesan, style: const TextStyle(fontSize: 13, height: 1.4)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Saldo Aktif Siap Cair: Rp ${_formatRupiah(hasil.saldoAktif)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900)),
                                      const SizedBox(height: 2),
                                      Text('Dana Tertahan di Rekber: Rp ${_formatRupiah(hasil.saldoTertahan)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade900)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('MENGERTI'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      setState(() {});
                      LayananNotifikasi.kirimNotifikasi(
                        context,
                        judul: 'Pencairan Dana Berhasil! 💸',
                        pesan: hasil.pesan,
                        ikon: Icons.verified_rounded,
                        warna: Colors.green.shade800,
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text('PROSES PENARIKAN DANA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Pesanan Traveler')),
        body: Center(
          child: Platform.environment.containsKey('FLUTTER_TEST')
              ? const Text('Memuat...')
              : const CircularProgressIndicator(),
        ),
      );
    }

    // Proteksi RBAC: Halaman ini HANYA bisa diakses oleh peran TRAVELER (Poin 1)
    if (_peranAktif != 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Kelola Pesanan Masuk'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red.shade700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akses Dibatasi: Khusus Peran Traveler',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Akun Anda saat ini masuk sebagai Pemesan. Halaman Kelola Pesanan hanya dapat diakses oleh akun Traveler/Jastiper untuk menerima titipan, mengonfirmasi belanja di luar negeri, dan mengatur serah terima barang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('KEMBALI KE BERANDA'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_daftarPesanan.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Kelola Pesanan (Traveler)'),
          backgroundColor: Colors.indigo.shade800,
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
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inbox_outlined, size: 64, color: Colors.indigo.shade600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Pesanan Masuk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada pemesan yang melakukan checkout barang titipan jastip. Begitu pemesan memesan barang, pesanan akan otomatis muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
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
        title: const Text('Kelola Pesanan (Khusus Traveler)'),
        backgroundColor: Colors.indigo.shade800,
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
          IconButton(
            tooltip: 'Dompet & Saldo Rekber Escrow',
            icon: const Icon(Icons.account_balance_wallet_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanDompetRekber()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Peran
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff, color: Colors.indigo.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudut Pandang: Traveler (Dimas Pratama)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo.shade900),
                        ),
                        const Text(
                          'Anda bertindak sebagai pembeli di LN. Konfirmasikan progres pembelian & kepulangan Anda di bawah.',
                          style: TextStyle(fontSize: 10.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ========================================================
            // KARTU DOMPET REKBER TRAVELER (ESCROW PROTECTION)
            // ========================================================
            Builder(
              builder: (context) {
                final saldoTertahan = LayananRekber.hitungSaldoTertahanRekber(namaTraveler: 'Dimas Pratama');
                final saldoAktif = LayananRekber.hitungSaldoAktifTraveler(namaTraveler: 'Dimas Pratama');

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.account_balance_wallet_rounded, color: Colors.indigo.shade800, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Dompet Rekber Traveler',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HalamanDompetRekber()),
                              ).then((_) => setState(() {}));
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Detail Rekber',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: Colors.indigo.shade800),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Kolom Saldo Tertahan (Rekber)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lock_rounded, size: 14, color: Colors.amber.shade900),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Saldo Rekber (Tertahan)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatRupiah(saldoTertahan)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '🔒 Belum bisa dicairkan',
                                    style: TextStyle(fontSize: 9.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Kolom Saldo Aktif (Siap Cair)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade900),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Saldo Aktif (Siap Cair)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${_formatRupiah(saldoAktif)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '✅ Pesanan sudah selesai',
                                    style: TextStyle(fontSize: 9.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Tombol Tarik Saldo
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.indigo.shade700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _dialogTarikDanaTraveler,
                          icon: Icon(Icons.account_balance_rounded, size: 16, color: Colors.indigo.shade800),
                          label: Text(
                            'Tarik Saldo ke Rekening Bank',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.indigo.shade900),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

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
                                color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.indigo.shade800 : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Belum Diterima',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _kategoriTab == 'BELUM_DITERIMA' ? FontWeight.bold : FontWeight.w500,
                                  color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.indigo.shade900 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _kategoriTab == 'BELUM_DITERIMA' ? Colors.indigo.shade800 : Colors.grey.shade400,
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
                          ? Colors.indigo.shade600
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? Colors.green.shade600
                              : Colors.red.shade400),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Tidak Ada Pesanan Belum Selesai'
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? 'Belum Ada Pesanan yang Selesai / Diterima'
                              : 'Tidak Ada Pesanan yang Dibatalkan'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Seluruh pesanan masuk telah berhasil diantar atau dibatalkan.'
                          : (_kategoriTab == 'SUDAH_DITERIMA'
                              ? 'Riwayat pesanan yang telah diselesaikan akan tersimpan di sini.'
                              : 'Tidak ada pesanan yang berstatus dibatalkan.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.4),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Pilihan Pesanan Masuk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _kategoriTab == 'BELUM_DITERIMA'
                          ? 'Pesanan Masuk (Aktif):'
                          : _kategoriTab == 'DIBATALKAN'
                              ? 'Pesanan Masuk (Dibatalkan):'
                              : 'Pesanan Masuk (Selesai):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${listTampil.length} Pesanan',
                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 102,
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
                          color: terpilih ? Colors.indigo.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: terpilih ? Colors.indigo.shade800 : Colors.grey.shade300,
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
                                    color: terpilih ? Colors.indigo.shade700 : Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.daftarBarang.length} Item',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: terpilih ? Colors.white : Colors.indigo.shade900,
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
                                color: terpilih ? Colors.amber.shade300 : Colors.indigo.shade900,
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
              // BANNER KHUSUS PESANAN DIBATALKAN & REFUND REKBER
              if (pesanan.apakahDibatalkan) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: Colors.red.shade800, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PESANAN DIBATALKAN (BARANG KOSONG) ❌',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.red),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dana Rekber Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah 100% DI-REFUND ke saldo dompet pemesan.',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

            // Status Lokasi & Alur Titipan
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade800, Colors.indigo.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.2),
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
                    'Asal Belanja: ${pesanan.negaraAsal} • Kode Order: ${pesanan.idPesanan}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daftar Rincian Barang yang Harus Dibeli
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
                      Expanded(
                        child: Text(
                          'Barang yang Harus Anda Beli (${pesanan.daftarBarang.length} Produk):',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          tahap == 6 ? 'DANA SUDAH CAIR' : 'REKBER ESCROW AMAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tahap == 6 ? Colors.green.shade800 : Colors.amber.shade900,
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
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
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
                                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Total Pembayaran Pemesan:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.indigo.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TIMELINE TINDAKAN TRAVELER
            const Text(
              'Timeline Konfirmasi Traveler:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // STEP 1: Pesanan Masuk & Menunggu ACC
            _bangunItemTimeline(
              nomor: 1,
              judul: '1. Pesanan Dibuat & Menunggu ACC Traveler',
              deskripsi: tahap >= 2
                  ? 'Anda telah menyetujui pesanan ini.'
                  : 'Pesanan baru masuk dari Pemesan. Silakan tinjau barang titipan di atas dan setujui pesanan.',
              ikon: Icons.assignment_turned_in_rounded,
              sudahLewat: tahap >= 2,
              sedangAktif: tahap == 1,
              aksiTambahan: tahap == 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerAccPesanan,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('ACC / SETUJUI PESANAN INI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )
                  : null,
            ),

            // STEP 2: Menuju Toko & Belanja
            _bangunItemTimeline(
              nomor: 2,
              judul: '2. Bergerak ke Toko Resmi di Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Semua barang titipan telah berhasil Anda beli di toko resmi.'
                  : 'Anda sedang menuju toko resmi di ${pesanan.negaraAsal}. Setelah membeli barang, tekan tombol di bawah.',
              ikon: Icons.directions_walk_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 2,
              aksiTambahan: tahap == 2
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerKonfirmasiSudahBeli,
                        icon: const Icon(Icons.shopping_bag, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('KONFIRMASI SUDAH DIBELI DI TOKO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )
                  : null,
            ),

            // STEP 3: Konfirmasi Belanja & Masuk Bagasi
            _bangunItemTimeline(
              nomor: 3,
              judul: '3. Barang Sudah Dibeli di Toko Resmi',
              deskripsi: tahap >= 4
                  ? 'Struk belanja resmi telah diverifikasi aman dan barang siap dibawa pulang ke RI.'
                  : 'Barang sudah dibeli. Silakan konfirmasi untuk memasukkan barang ke bagasi penerbangan menuju Indonesia.',
              ikon: Icons.storefront_rounded,
              sudahLewat: tahap >= 4,
              sedangAktif: tahap == 3,
              aksiTambahan: tahap == 3
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerMulaiPenerbangan,
                        icon: const Icon(Icons.flight_takeoff, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('BAWA MASUK BAGASI PESAWAT KE RI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )
                  : null,
            ),

            // STEP 4: Dalam Penerbangan ke Indonesia
            _bangunItemTimeline(
              nomor: 4,
              judul: '4. Dalam Penerbangan Menuju Indonesia',
              deskripsi: tahap >= 5
                  ? 'Penerbangan telah selesai dan Anda telah mendarat di bandara Indonesia.'
                  : 'Koper titipan sedang dalam penerbangan. Begitu tiba di bandara Indonesia, tekan tombol mendarat.',
              ikon: Icons.airplanemode_active_rounded,
              sudahLewat: tahap >= 5,
              sedangAktif: tahap == 4,
              aksiTambahan: tahap == 4
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerTibaDiIndonesia,
                        icon: const Icon(Icons.flight_land, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('KONFIRMASI MENDARAT DI INDONESIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    )
                  : null,
            ),

            // STEP 5: Mendarat di Indonesia & Eksekusi Penyerahan (Sesuai Pilihan Pemesan)
            _bangunItemTimeline(
              nomor: 5,
              judul: '5. Mendarat di Indonesia & Pelaksanaan Serah Terima',
              deskripsi: tahap >= 6
                  ? 'Proses serah terima barang titipan telah selesai.'
                  : 'Pesawat telah mendarat di Indonesia. Lakukan serah terima barang sesuai metode yang telah dipilih Pemesan saat checkout.',
              ikon: Icons.luggage_rounded,
              sudahLewat: tahap >= 6,
              sedangAktif: tahap == 5,
              aksiTambahan: tahap == 5
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pesanan.metodePenyerahan == 'COD_LBS' ? Icons.location_on : Icons.local_shipping,
                                color: Colors.indigo.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pilihan Serah Terima dari Pemesan: ${pesanan.metodePenyerahan == "COD_LBS" ? "COD Titik Temu (LBS)" : "Kirim Kurir"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (pesanan.metodePenyerahan == 'COD_LBS') ...[
                            const Text(
                              '📍 Pemesan memilih bertemu langsung (COD) di Hub JastipGo Kampus UPN Condongcatur / Bandara.',
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
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
                              label: const Text('Buka Titik Temu di LBS Peta', style: TextStyle(fontSize: 11)),
                            ),
                          ] else ...[
                            Text(
                              '🚚 Pemesan memilih pengiriman kurir ke alamat:\n${pesanan.alamatPengiriman.isNotEmpty ? pesanan.alamatPengiriman : "Jl. Babarsari No. 12, Sleman, Yogyakarta"}',
                              style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kirimkan paket melalui JNE/SiCepat lalu bagikan nomor resi ke Pemesan lewat chat.',
                              style: TextStyle(fontSize: 10.5, color: Colors.black54),
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _travelerKonfirmasiSelesai,
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'SERAH TERIMA SELESAI & CAIRKAN REKBER',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            // STEP 6: Selesai & Pelepasan Dana Rekber
            _bangunItemTimeline(
              nomor: 6,
              judul: '6. Konfirmasi Terima & Pelepasan Dana Rekber',
              deskripsi: tahap == 6
                  ? 'Transaksi Selesai 100%! Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah resmi dilepaskan dari Rekber ke Saldo Aktif Anda.'
                  : 'Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} tersimpan aman di Rekber. Begitu serah terima selesai, tekan tombol di atas untuk mencairkan dana.',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: tahap == 6,
              sedangAktif: tahap == 6,
              garisTerakhir: true,
            ),

            // TOMBOL BATALKAN PESANAN (BARANG KOSONG) KHUSUS TRAVELER (TODO_MANAJEMEN_PESANAN.txt)
            if (pesanan.tahapStatus >= 1 && pesanan.tahapStatus < 6) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _travelerBatalkanPesananBarangKosong,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Batalkan Pesanan (Barang Tidak Ada)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
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
    final Color warnaIndikator = sudahLewat ? Colors.indigo.shade700 : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sudahLewat ? Colors.indigo.shade700 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIndikator, width: 2),
                boxShadow: sedangAktif
                    ? [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.3),
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
                color: sudahLewat ? Colors.indigo.shade600 : Colors.grey.shade300,
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
                  color: sedangAktif ? Colors.indigo.shade900 : Colors.black87,
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
