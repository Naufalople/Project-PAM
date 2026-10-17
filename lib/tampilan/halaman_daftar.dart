import 'package:flutter/material.dart';

import '../layanan/layanan_otentikasi.dart';
import '../widget/dialog_sukses.dart';
import '../widget/dialog_peringatan.dart';
import 'halaman_utama.dart';

// Halaman Pendaftaran Akun Baru (Registrasi)
class HalamanDaftar extends StatefulWidget {
  const HalamanDaftar({super.key});

  @override
  State<HalamanDaftar> createState() => _HalamanDaftarState();
}

class _HalamanDaftarState extends State<HalamanDaftar> {
  final _formKunci = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();

  bool _sedangMemuat = false;
  bool _sembunyikanPassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  // Fungsi Proses Pendaftaran
  Future<void> _prosesDaftar() async {
    if (!_formKunci.currentState!.validate()) return;

    if (_passwordController.text != _konfirmasiPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Password Berbeda',
          deskripsi: 'Konfirmasi password tidak cocok dengan password yang Anda masukkan.',
        ),
      );
      return;
    }

    setState(() => _sedangMemuat = true);

    // Pendaftaran akun khusus untuk Pemesan (karena pembeli di LN cukup 1 orang tetap)
    final bool berhasil = await LayananOtentikasi.daftarkanPenggunaBaru(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nomorTelepon: _teleponController.text.trim(),
      peran: 'PEMESAN',
      lokasi: 'Indonesia 🇮🇩',
    );

    setState(() => _sedangMemuat = false);

    if (!mounted) return;

    if (berhasil) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DialogSukses(
          judul: 'Registrasi Berhasil! 🎉',
          deskripsi: 'Selamat datang, ${_namaController.text.trim()}!\n\nData akun Anda:\n• Nama: ${_namaController.text.trim()}\n• WhatsApp: ${_teleponController.text.trim()}\n• Email: ${_emailController.text.trim()}\n\nAkun Anda telah dienkripsi dengan SHA-256 dan langsung aktif.',
          saatKlikOke: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HalamanUtama()),
              (route) => false,
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Email Terdaftar',
          deskripsi: 'Alamat email ini sudah digunakan oleh akun lain. Silakan gunakan email lain.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Daftar Akun Pemesan (Jastiper)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Daftarkan akun Anda untuk menitip barang belanjaan impian dari luar negeri dengan aman dan terverifikasi.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Formulir
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKunci,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Keterangan Peran Akun
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_rounded, size: 20, color: Colors.teal.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Peran Akun: Pemesan Barang (Jastiper Indonesia)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama Lengkap
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Nama minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nomor Telepon (WhatsApp)
                      TextFormField(
                        controller: _teleponController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor WhatsApp',
                          hintText: '0812xxxxxxxx',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Nomor telepon minimal 10 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _sembunyikanPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _sembunyikanPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                () => _sembunyikanPassword =
                                    !_sembunyikanPassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Konfirmasi Password
                      TextFormField(
                        controller: _konfirmasiPasswordController,
                        obscureText: _sembunyikanPassword,
                        decoration: InputDecoration(
                          labelText: 'Ulangi Password',
                          prefixIcon: const Icon(Icons.lock_reset),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tombol Daftar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _sedangMemuat ? null : _prosesDaftar,
                          child: _sedangMemuat
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'DAFTAR AKUN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
