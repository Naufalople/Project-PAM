import 'package:flutter/material.dart';
import '../layanan/layanan_firebase.dart';
import '../layanan/layanan_otentikasi.dart';
import '../model/model_pengguna.dart';
import '../widget/dialog_sukses.dart';

/// Halaman Saran dan Kesan Mata Kuliah Pemrograman Aplikasi Mobile (PAM)
/// Terhubung langsung secara online ke Firebase Realtime Database
class HalamanSaranKesan extends StatefulWidget {
  const HalamanSaranKesan({super.key});

  @override
  State<HalamanSaranKesan> createState() => _HalamanSaranKesanState();
}

class _HalamanSaranKesanState extends State<HalamanSaranKesan> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _saranController = TextEditingController();
  final TextEditingController _kesanController = TextEditingController();
  int _bintangKepuasan = 5;

  ModelPengguna? _profilAktif;
  bool _sedangMemuat = true;
  bool _sedangMengirim = false;

  final List<Map<String, dynamic>> _daftarUlasanTersimpan = [];

  // Ulasan default sebagai sampel apabila offline atau belum ada data
  final Map<String, dynamic> _ulasanDefault = {
    'nama': 'Mahasiswa Sistem Informasi UPN',
    'peran': 'MAHASISWA',
    'kesan':
        'Mata kuliah PAM sangat menantang dan membuka wawasan luas seputar teknologi mobile terkini seperti AI, Biometrik, dan Sensor!',
    'saran':
        'Semoga materi praktikum Flutter dan integrasi API cloud semakin diperbanyak porsi studi kasus nyatanya.',
    'rating': 5,
    'tanggal': 'Oktober 2026',
  };

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _saranController.dispose();
    _kesanController.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() => _sedangMemuat = true);
    try {
      // 1. Ambil profil pengguna yang sedang login
      final profil = await LayananOtentikasi.ambilProfilAktif();
      _profilAktif = profil;

      // 2. Ambil data ulasan online dari Firebase Realtime Database
      await _muatUlasanOnline();
    } catch (_) {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  Future<void> _muatUlasanOnline() async {
    try {
      final ulasanOnline = await LayananFirebase.ambilSemuaSaranKesanOnline();
      if (mounted) {
        setState(() {
          _daftarUlasanTersimpan.clear();
          if (ulasanOnline.isNotEmpty) {
            _daftarUlasanTersimpan.addAll(ulasanOnline);
          } else {
            _daftarUlasanTersimpan.add(_ulasanDefault);
          }
          _sedangMemuat = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_daftarUlasanTersimpan.isEmpty) {
            _daftarUlasanTersimpan.add(_ulasanDefault);
          }
          _sedangMemuat = false;
        });
      }
    }
  }

  Future<void> _kirimSaranKesan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sedangMengirim = true);

    final namaPengirim = _profilAktif?.nama.isNotEmpty == true
        ? _profilAktif!.nama
        : 'Pengguna PAM';
    final peranPengirim = _profilAktif?.peran ?? 'PEMESAN';
    final emailPengirim = _profilAktif?.email ?? '';

    final kesanText = _kesanController.text.trim();
    final saranText = _saranController.text.trim();
    final ratingValue = _bintangKepuasan;

    // Kirim ke database online Firebase Realtime Database
    final berhasil = await LayananFirebase.kirimSaranKesanOnline(
      nama: namaPengirim,
      kesan: kesanText,
      saran: saranText,
      rating: ratingValue,
      peran: peranPengirim,
      email: emailPengirim,
    );

    if (!mounted) return;

    setState(() {
      _sedangMengirim = false;
      _saranController.clear();
      _kesanController.clear();
      _bintangKepuasan = 5;
    });

    // Refresh daftar dari database online
    await _muatUlasanOnline();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => DialogSukses(
          judul: 'Evaluasi Terkirim! 🎉',
          deskripsi: berhasil
              ? 'Saran dan kesan Anda telah berhasil disimpan ke Cloud Firebase Realtime Database dan kini dapat dilihat oleh seluruh pengguna.'
              : 'Evaluasi berhasil disimpan secara lokal. Pastikan koneksi internet aktif untuk sinkronisasi cloud.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Saran & Kesan Matkul PAM'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Ulasan Online',
            onPressed: _sedangMemuat ? null : _muatUlasanOnline,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muatUlasanOnline,
        color: Colors.teal.shade800,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade900.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Evaluasi Online Matkul PAM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pemrograman Aplikasi Mobile - Jurusan Informatika / Sistem Informasi UPN "Veteran" Yogyakarta',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Input Saran & Kesan
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Akun Pengirim
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.teal.shade700,
                              child: Text(
                                (_profilAktif?.nama.isNotEmpty == true
                                        ? _profilAktif!.nama[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mengirim sebagai: ${_profilAktif?.nama ?? "Pengguna PAM"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.teal.shade900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Peran: ${_profilAktif?.peran ?? "PEMESAN"} • Terhubung ke Database Online',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.teal.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Rating Pengalaman Belajar:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              index < _bintangKepuasan
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: _sedangMengirim
                                ? null
                                : () => setState(() => _bintangKepuasan = index + 1),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Kesan
                      const Text(
                        'Kesan Selama Perkuliahan PAM:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _kesanController,
                        maxLines: 3,
                        enabled: !_sedangMengirim,
                        decoration: InputDecoration(
                          hintText:
                              'Tuliskan kesan menarik Anda selama belajar Flutter, Dart, dan arsitektur mobile...',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Kesan minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Saran
                      const Text(
                        'Saran untuk Pengembangan Kedepan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _saranController,
                        maxLines: 3,
                        enabled: !_sedangMengirim,
                        decoration: InputDecoration(
                          hintText:
                              'Tuliskan kritik dan saran membangun untuk dosen & asisten laboratorium...',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Saran minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _sedangMengirim ? null : _kirimSaranKesan,
                          icon: _sedangMengirim
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 20),
                          label: Text(
                            _sedangMengirim ? 'MENGIRIM KE CLOUD...' : 'KIRIM EVALUASI ONLINE',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Riwayat Ulasan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ulasan Pengguna di Database:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (_sedangMemuat)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_daftarUlasanTersimpan.isEmpty && !_sedangMemuat)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada ulasan yang tersimpan di cloud database.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _daftarUlasanTersimpan.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = _daftarUlasanTersimpan[index];
                    final String namaUser = u['nama']?.toString() ?? 'Pengguna PAM';
                    final String peranUser = u['peran']?.toString() ?? 'PEMESAN';
                    final String tanggal = u['tanggal']?.toString() ?? '';
                    final int rating = int.tryParse(u['rating']?.toString() ?? '5') ?? 5;
                    final String initial = namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'U';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: peranUser == 'TRAVELER'
                                    ? Colors.blue.shade100
                                    : Colors.teal.shade100,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: peranUser == 'TRAVELER'
                                        ? Colors.blue.shade900
                                        : Colors.teal.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            namaUser,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: peranUser == 'TRAVELER'
                                                ? Colors.blue.shade50
                                                : Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: peranUser == 'TRAVELER'
                                                  ? Colors.blue.shade200
                                                  : Colors.teal.shade200,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            peranUser,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: peranUser == 'TRAVELER'
                                                  ? Colors.blue.shade800
                                                  : Colors.teal.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tanggal.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        tanggal,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  rating.clamp(1, 5),
                                  (i) => const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Text(
                            '💬 Kesan: "${u['kesan'] ?? ''}"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '💡 Saran: "${u['saran'] ?? ''}"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
