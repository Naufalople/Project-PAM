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
  String? _pesanErrorDuplikasi;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  // Fungsi Proses Pendaftaran dengan Pengecekan Akun Duplikat di Database
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

    setState(() {
      _sedangMemuat = true;
      _pesanErrorDuplikasi = null;
    });

    // 1. Query pengecekan terlebih dahulu ke database (Database Lokal Hive & Database Online REST API)
    final String? duplikasi = await LayananOtentikasi.periksaDuplikasiAkun(
      email: _emailController.text.trim(),
      namaAtauUsername: _namaController.text.trim(),
    );

    // 2. Jika akun sudah ada di database, gagalkan proses registrasi secara langsung
    if (duplikasi != null) {
      setState(() {
        _sedangMemuat = false;
        _pesanErrorDuplikasi = duplikasi;
      });

      if (!mounted) return;

      // Munculkan pesan peringatan/error yang jelas di UI: "Email sudah terdaftar, silakan gunakan email lain"
      showDialog(
        context: context,
        builder: (context) => DialogPeringatan(
          judul: 'Pendaftaran Ditolak',
          deskripsi: duplikasi,
        ),
      );
      return;
    }

    // 3. Pendaftaran hanya boleh berlanjut jika akun benar-benar baru dan belum tercatat di database
    final HasilRegistrasi hasil = await LayananOtentikasi.prosesDaftarAkunBaru(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nomorTelepon: _teleponController.text.trim(),
      peran: 'PEMESAN',
      lokasi: 'Indonesia 🇮🇩',
    );

    setState(() => _sedangMemuat = false);

    if (!mounted) return;

    if (hasil.berhasil) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DialogSukses(
          judul: 'Registrasi Berhasil! 🎉',
          deskripsi: 'Selamat datang, ${_namaController.text.trim()}!\n\nData akun Anda:\n• Nama / Username: ${_namaController.text.trim()}\n• WhatsApp: ${_teleponController.text.trim()}\n• Email: ${_emailController.text.trim()}\n\nAkun Anda telah dienkripsi dengan SHA-256 dan langsung aktif.',
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
      final String pesanGagal = hasil.pesanError ?? 'Email sudah terdaftar, silakan gunakan email lain';
      setState(() {
        _pesanErrorDuplikasi = pesanGagal;
      });

      showDialog(
        context: context,
        builder: (context) => DialogPeringatan(
          judul: 'Pendaftaran Ditolak',
          deskripsi: pesanGagal,
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

                      // Kotak Peringatan Error Duplikasi di UI
                      if (_pesanErrorDuplikasi != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade400, width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Peringatan Email Terdaftar:',
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _pesanErrorDuplikasi!,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Nama Lengkap / Username
                      TextFormField(
                        controller: _namaController,
                        onChanged: (_) {
                          if (_pesanErrorDuplikasi != null) {
                            setState(() => _pesanErrorDuplikasi = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap / Username',
                          hintText: 'Contoh: Siti Nurhaliza atau siti123',
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
                        onChanged: (_) {
                          if (_pesanErrorDuplikasi != null) {
                            setState(() => _pesanErrorDuplikasi = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          hintText: 'contoh@jastipgo.com',
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
