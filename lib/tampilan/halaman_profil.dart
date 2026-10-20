import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/model_pengguna.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_biometrik.dart';
import 'halaman_masuk.dart';
import 'halaman_saran_kesan.dart';
import 'halaman_dompet_rekber.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_status_pesanan.dart';
import 'halaman_kelola_pesanan_traveler.dart';
import 'halaman_chat_traveler.dart';

// Halaman Profil Pengguna: Informasi Akun, Foto, Sertifikat Blockchain, dan Logout
class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  ModelPengguna? _profilPengguna;
  bool _biometrikAktif = false;
  String _destinasiTraveler = 'Jepang';

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final profil = await LayananOtentikasi.ambilProfilAktif();
    final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
    bool biometrikAktif = false;
    if (profil != null) {
      biometrikAktif = await LayananBiometrik.apakahBiometrikAktifUntukAkun(profil.email);
    }
    if (!mounted) return;
    setState(() {
      _profilPengguna = profil;
      _biometrikAktif = biometrikAktif;
      _destinasiTraveler = destinasi;
    });
  }

  // Pengaturan Destinasi Penerbangan Aktif Traveler (Poin 4)
  // Pengaturan Destinasi Penerbangan Aktif Traveler dengan Validasi Status Pesanan (TODO_VALIDASI_DESTINASI)
  Future<void> _ubahDestinasiTraveler() async {
    // 1. Jalankan fungsi pengecekan ke database pesanan
    final String namaTraveler = _profilPengguna?.nama ?? 'Dimas Pratama';
    final pesananBelumDikirim = LayananBasisDataLokal.ambilPesananBelumDikirimTraveler(
      namaTraveler: namaTraveler,
    );

    // 2. Jika masih ada pesanan yang statusnya belum mencapai "Dikirim ke Indonesia" (tahapStatus < 4), gagalkan proses
    if (pesananBelumDikirim.isNotEmpty) {
      if (!mounted) return;

      // Tampilkan pesan peringatan/Snackbar yang jelas di layar sesuai instruksi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda tidak dapat mengubah negara destinasi. Pastikan semua produk pesanan saat ini sudah dikirim ke Indonesia.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );

      // Tampilkan juga dialog penjelasan detail transaksi aktif yang belum dikirim
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Ubah Destinasi Ditolak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anda tidak dapat mengubah negara destinasi. Pastikan semua produk pesanan saat ini sudah dikirim ke Indonesia.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terdapat ${pesananBelumDikirim.length} pesanan aktif yang belum dikirim:',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      const SizedBox(height: 6),
                      ...pesananBelumDikirim.take(3).map((p) => Text(
                            '• ${p.idPesanan} (${p.negaraAsal}) - ${p.lokasiTerkini}',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 11),
                          )),
                      if (pesananBelumDikirim.length > 3)
                        Text(
                          '• Dan ${pesananBelumDikirim.length - 3} pesanan lainnya...',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('MENGERTI'),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Traveler diizinkan jika tidak ada pesanan aktif sama sekali (0 pesanan) ATAU semua sudah "Dikirim ke Indonesia" (tahapStatus >= 4)
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Destinasi Penerbangan Aktif ✈️',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pemesan hanya dapat memesan produk dari negara tujuan ini.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...LayananOtentikasi.daftarDestinasiTersedia.map((d) {
                  final bool terpilih = d['nama'] == _destinasiTraveler;
                  return ListTile(
                    leading: Text(d['bendera']!, style: const TextStyle(fontSize: 24)),
                    title: Text(d['nama']!, style: TextStyle(fontWeight: terpilih ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('Rute Hub: ${d['kota']}'),
                    trailing: terpilih ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                    onTap: () => Navigator.pop(ctx, d['nama']),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );

    if (pilihan != null && pilihan != _destinasiTraveler) {
      final bool sukses = await LayananOtentikasi.simpanDestinasiAktifTraveler(
        pilihan,
        namaTraveler: namaTraveler,
      );

      if (!sukses) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Anda tidak dapat mengubah negara destinasi. Pastikan semua produk pesanan saat ini sudah dikirim ke Indonesia.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final destinasiInfo = LayananOtentikasi.daftarDestinasiTersedia.firstWhere(
        (d) => d['nama'] == pilihan,
        orElse: () => {'nama': pilihan, 'bendera': '✈️', 'kota': pilihan},
      );
      final lokasiBaru = '${destinasiInfo['kota']} ${destinasiInfo['bendera']}';
      if (_profilPengguna != null) {
        await LayananOtentikasi.perbaruiProfilAktif(
          nama: _profilPengguna!.nama,
          nomorTelepon: _profilPengguna!.nomorTelepon,
          lokasi: lokasiBaru,
        );
      }
      await _muatProfil();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✈️ Destinasi penerbangan diubah ke $pilihan! Pemesan kini dibatasi hanya memesan produk dari $pilihan.',
          ),
          backgroundColor: Colors.indigo.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi Mengubah Status Pendaftaran Sidik Jari untuk Akun Ini
  Future<void> _ubahStatusBiometrik(bool aktifkan) async {
    if (_profilPengguna == null) return;

    if (aktifkan) {
      final bool sukses = await LayananBiometrik.autentikasiSidikJari(
        pesanAlasan: 'Pindai sidik jari Anda untuk mengaktifkan login biometrik pada akun ini',
      );
      if (!mounted) return;

      if (sukses) {
        await LayananBiometrik.daftarkanBiometrikAkun(
          email: _profilPengguna!.email,
          nama: _profilPengguna!.nama,
        );
        if (!mounted) return;
        setState(() => _biometrikAktif = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Sidik jari berhasil dihubungkan ke akun ${_profilPengguna!.nama}! Sekarang Anda dapat masuk cepat dengan sidik jari.',
            ),
            backgroundColor: Colors.teal.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi sidik jari dibatalkan atau tidak cocok.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await LayananBiometrik.nonaktifkanBiometrik();
      setState(() => _biometrikAktif = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login biometrik dinonaktifkan untuk akun ini.'),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fungsi Keluar Sesi Akun (Logout)
  Future<void> _keluarAkun() async {
    await LayananOtentikasi.keluarSesi();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HalamanMasuk()),
      (route) => false,
    );
  }

  final ImagePicker _picker = ImagePicker();

  ImageProvider _dapatkanGambarProfil(String urlAtauPath) {
    if (urlAtauPath.startsWith('http://') || urlAtauPath.startsWith('https://')) {
      return NetworkImage(urlAtauPath);
    }
    final file = File(urlAtauPath);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400');
  }

  Future<void> _pilihSumberFotoProfil() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bSheetCtx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.teal),
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.pop(bSheetCtx);
                  _ambilFotoProfil(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.indigo),
                ),
                title: const Text('Pilih dari Galeri HP'),
                onTap: () {
                  Navigator.pop(bSheetCtx);
                  _ambilFotoProfil(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ambilFotoProfil(ImageSource sumber) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: sumber,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (foto != null) {
        await LayananOtentikasi.perbaruiFotoProfilAktif(foto.path);
        await _muatProfil();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto profil kustom berhasil disimpan dan diperbarui!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _dialogEditProfil() async {
    final namaCtrl = TextEditingController(text: _profilPengguna?.nama ?? '');
    final telpCtrl = TextEditingController(text: _profilPengguna?.nomorTelepon ?? '');

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Data Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telpCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (namaCtrl.text.trim().isNotEmpty && telpCtrl.text.trim().isNotEmpty) {
                await LayananOtentikasi.perbaruiProfilAktif(
                  nama: namaCtrl.text.trim(),
                  nomorTelepon: telpCtrl.text.trim(),
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted) {
                  _muatProfil();
                }
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nama = _profilPengguna?.nama ?? 'Pengguna JastipGo';
    final String email = _profilPengguna?.email ?? 'pengguna@jastipgo.com';
    final String telepon = _profilPengguna?.nomorTelepon ?? '-';
    final String fotoUrl = _profilPengguna?.fotoProfil ??
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ubah Data Profil',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _dialogEditProfil,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Kartu Profil Utama dengan Foto
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: _dapatkanGambarProfil(fotoUrl),
                      ),
                      GestureDetector(
                        onTap: _pilihSumberFotoProfil,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade800,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _pilihSumberFotoProfil,
                    icon: const Icon(Icons.photo_camera_back_outlined, size: 14),
                    label: const Text('Ubah Foto Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nama,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '📱 WhatsApp: $telepon',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _profilPengguna?.peran == 'TRAVELER' ? Colors.indigo.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _profilPengguna?.peran == 'TRAVELER' ? Colors.indigo.shade200 : Colors.amber.shade300,
                          ),
                        ),
                        child: Text(
                          _profilPengguna?.peran == 'TRAVELER'
                              ? '✈️ Pembeli (Traveler) • ${_profilPengguna?.lokasi ?? "Tokyo 🇯🇵"}'
                              : '👤 Pemesan • ${_profilPengguna?.lokasi ?? "Indonesia 🇮🇩"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _profilPengguna?.peran == 'TRAVELER' ? Colors.indigo.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Pengaturan Destinasi Penerbangan Aktif Traveler (Poin 4 & TODO_VALIDASI_DESTINASI)
            if (_profilPengguna?.peran == 'TRAVELER') ...[
              Builder(
                builder: (context) {
                  final bool adaPesananBelumDikirim = LayananBasisDataLokal.apakahAdaPesananBelumDikirim(
                    namaTraveler: _profilPengguna?.nama,
                  );

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: adaPesananBelumDikirim
                            ? [Colors.blueGrey.shade900, Colors.indigo.shade900]
                            : [Colors.indigo.shade800, Colors.indigo.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Destinasi Penerbangan Aktif',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: adaPesananBelumDikirim ? Colors.amber.shade400 : Colors.teal.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    adaPesananBelumDikirim ? Icons.lock_rounded : Icons.check_circle_rounded,
                                    size: 11,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    adaPesananBelumDikirim ? 'Rute Terkunci' : 'Open PO',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Rute Saat Ini: $_destinasiTraveler',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adaPesananBelumDikirim
                              ? '🔒 Tombol terkunci karena masih ada pesanan aktif yang belum dikirim ke Indonesia. Pastikan semua produk pesanan saat ini sudah dikirim ke Indonesia sebelum mengubah rute.'
                              : 'Pemesan hanya dapat menitip barang dari negara tujuan ini. Klik tombol di bawah untuk mengganti rute penerbangan aktif.',
                          style: TextStyle(
                            color: adaPesananBelumDikirim ? Colors.amber.shade200 : Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: adaPesananBelumDikirim ? Colors.white.withValues(alpha: 0.95) : Colors.white,
                              foregroundColor: adaPesananBelumDikirim ? Colors.red.shade900 : Colors.indigo.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _ubahDestinasiTraveler,
                            icon: Icon(
                              adaPesananBelumDikirim ? Icons.lock_outline_rounded : Icons.edit_location_alt_rounded,
                              size: 18,
                            ),
                            label: Text(
                              adaPesananBelumDikirim
                                  ? 'Ubah Negara Destinasi (Terkunci)'
                                  : 'Ubah Rute Destinasi Penerbangan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Menu Pengaturan & Navigasi
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_profilPengguna?.peran == 'TRAVELER') ? Colors.indigo.shade50 : Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (_profilPengguna?.peran == 'TRAVELER') ? Icons.flight_takeoff : Icons.local_shipping_rounded,
                        color: (_profilPengguna?.peran == 'TRAVELER') ? Colors.indigo.shade800 : Colors.deepOrange.shade800,
                      ),
                    ),
                    title: Text(
                      (_profilPengguna?.peran == 'TRAVELER')
                          ? 'Kelola Pesanan Masuk (Traveler)'
                          : 'Pesanan Saya',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      (_profilPengguna?.peran == 'TRAVELER')
                          ? 'ACC pesanan titipan & konfirmasi belanja LN'
                          : 'Lacak status perjalanan barang titipan Anda',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => (_profilPengguna?.peran == 'TRAVELER')
                              ? const HalamanKelolaPesananTraveler()
                              : const HalamanStatusPesanan(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.forum_rounded, color: Colors.teal.shade800),
                    ),
                    title: Text(
                      (_profilPengguna?.peran == 'TRAVELER')
                          ? 'Chat Langsung dengan Pemesan'
                          : 'Chat Langsung dengan Traveler',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Obrolan nyata dua arah antar akun manusia (bukan bot)',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanChatTraveler()),
                      );
                    },
                  ),
                  // Fitur Saldo & Dompet Rekber HANYA Muncul Khusus untuk Akun Traveler
                  if (_profilPengguna?.peran == 'TRAVELER') ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: Colors.indigo.shade800),
                      ),
                      title: const Text('Dompet & Saldo Rekber Escrow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Status dana tertahan & pencairan saldo aktif traveler', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HalamanDompetRekber()),
                        );
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.redAccent),
                    ),
                    title: const Text('Titik Temu COD (LBS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Pos penyerahan barang terdekat dari GPS', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _biometrikAktif ? Colors.teal.shade50 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        color: _biometrikAktif ? Colors.teal.shade800 : Colors.grey.shade600,
                      ),
                    ),
                    title: const Text(
                      'Otentikasi Sidik Jari (Biometrik)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _biometrikAktif
                          ? 'Aktif • Sidik jari terhubung ke akun ${_profilPengguna?.nama ?? ""}'
                          : 'Nonaktif • Ketuk sakelar untuk mendaftarkan sidik jari',
                      style: TextStyle(
                        fontSize: 11,
                        color: _biometrikAktif ? Colors.teal.shade700 : Colors.black54,
                      ),
                    ),
                    value: _biometrikAktif,
                    activeTrackColor: Colors.teal.shade300,
                    onChanged: (val) => _ubahStatusBiometrik(val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.rate_review_rounded, color: Colors.teal.shade700),
                    ),
                    title: const Text('Saran & Kesan Matkul PAM', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Menu evaluasi mata kuliah sesuai syarat dosen', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanSaranKesan()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                onPressed: _keluarAkun,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'LOGOUT DARI APLIKASI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
