import 'package:flutter/material.dart';
import '../widget/dialog_sukses.dart';

// Halaman Saran dan Kesan Mata Kuliah Pemrograman Aplikasi Mobile (PAM)
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

  final List<Map<String, dynamic>> _daftarUlasanTersimpan = [
    {
      'nama': 'Mahasiswa Sistem Informasi UPN',
      'kesan': 'Mata kuliah PAM sangat menantang dan membuka wawasan luas seputar teknologi mobile terkini seperti AI, Biometrik, dan Sensor!',
      'saran': 'Semoga materi praktikum Flutter dan integrasi API cloud semakin diperbanyak porsi studi kasus nyatanya.',
      'rating': 5,
      'tanggal': 'Oktober 2026',
    },
  ];

  @override
  void dispose() {
    _saranController.dispose();
    _kesanController.dispose();
    super.dispose();
  }

  void _kirimSaranKesan() {
    if (!_formKey.currentState!.validate()) return;

    final baru = {
      'nama': 'Saya (Mahasiswa Praktikan PAM)',
      'kesan': _kesanController.text.trim(),
      'saran': _saranController.text.trim(),
      'rating': _bintangKepuasan,
      'tanggal': 'Hari Ini',
    };

    setState(() {
      _daftarUlasanTersimpan.insert(0, baru);
      _saranController.clear();
      _kesanController.clear();
    });

    showDialog(
      context: context,
      builder: (context) => const DialogSukses(
        judul: 'Terima Kasih!',
        deskripsi: 'Saran dan kesan Anda terhadap mata kuliah Pemrograman Aplikasi Mobile berhasil disimpan ke sistem evaluasi.',
      ),
    );
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
      ),
      body: SingleChildScrollView(
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
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evaluasi Mata Kuliah PAM',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pemrograman Aplikasi Mobile - Jurusan Informatika / Sistem Informasi UPN "Veteran" Yogyakarta',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Input Saran & Kesan
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rating Pengalaman Belajar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            index < _bintangKepuasan ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () => setState(() => _bintangKepuasan = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Kesan
                    const Text('Kesan Selama Perkuliahan PAM:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _kesanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan kesan menarik Anda selama belajar Flutter, Dart, dan arsitektur mobile...',
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
                    const Text('Saran untuk Pengembangan Kedepan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _saranController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan kritik dan saran membangun untuk dosen & asisten laboratorium...',
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _kirimSaranKesan,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('KIRIM EVALUASI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Riwayat Ulasan
            const Text(
              'Ulasan & Saran yang Telah Dikirim:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _daftarUlasanTersimpan.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = _daftarUlasanTersimpan[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(u['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Row(
                            children: List.generate(
                              u['rating'],
                              (i) => const Icon(Icons.star, color: Colors.amber, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('💬 Kesan: "${u['kesan']}"', style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Text('💡 Saran: "${u['saran']}"', style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
