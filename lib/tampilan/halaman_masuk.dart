import 'package:flutter/material.dart';

import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_biometrik.dart';
import '../widget/dialog_peringatan.dart';
import 'halaman_daftar.dart';
import 'halaman_utama.dart';

// Halaman Masuk (Login) dengan Password Enkripsi SHA-256 & Biometrik Sidik Jari
class HalamanMasuk extends StatefulWidget {
  final bool pesanSesiKedaluwarsa;

  const HalamanMasuk({super.key, this.pesanSesiKedaluwarsa = false});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final _formKunci = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _sedangMemuat = false;
  bool _sembunyikanPassword = true;

  @override
  void initState() {
    super.initState();
    _muatEmailTerakhir();
  }

  Future<void> _muatEmailTerakhir() async {
    final email = await LayananOtentikasi.ambilEmailTerakhir();
    if (email != null && email.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = email;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi Masuk Akun
  Future<void> _masukDenganEmailPassword() async {
    if (!_formKunci.currentState!.validate()) return;

    setState(() => _sedangMemuat = true);

    final pengguna = await LayananOtentikasi.prosesMasuk(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _sedangMemuat = false);

    if (!mounted) return;

    if (pengguna != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HalamanUtama()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Gagal Masuk',
          deskripsi: 'Email atau password yang Anda masukkan salah. Silakan coba lagi.',
        ),
      );
    }
  }

  // Fungsi Masuk Cepat dengan Sensor Sidik Jari / Biometrik
  Future<void> _masukDenganBiometrik() async {
    // 1. Cek apakah pengguna sudah mendaftarkan sidik jari di menu Profil
    final String? emailTerdaftar = await LayananBiometrik.ambilEmailBiometrikTerdaftar();
    final String? namaTerdaftar = await LayananBiometrik.ambilNamaBiometrikTerdaftar();

    if (!mounted) return;

    if (emailTerdaftar == null) {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Biometrik Belum Didaftarkan',
          deskripsi:
              'Sensor sidik jari belum dihubungkan ke akun manapun.\n\nSilakan masuk terlebih dahulu menggunakan email dan password akun Anda, lalu aktifkan "Otentikasi Sidik Jari" di menu Profil.',
        ),
      );
      return;
    }

    // 2. Jalankan sensor sidik jari
    final bool sukses = await LayananBiometrik.autentikasiSidikJari(
      pesanAlasan: 'Pindai sidik jari Anda untuk masuk sebagai ${namaTerdaftar ?? emailTerdaftar}',
    );

    if (!mounted) return;

    if (sukses) {
      final pengguna = await LayananOtentikasi.masukDenganBiometrik(
        email: emailTerdaftar,
      );
      if (!mounted) return;
      if (pengguna != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HalamanUtama()),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => const DialogPeringatan(
            judul: 'Akun Tidak Ditemukan',
            deskripsi: 'Data akun yang terdaftar pada sidik jari tidak ditemukan di database.',
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Biometrik Gagal',
          deskripsi: 'Otentikasi sidik jari tidak dikenali atau dibatalkan. Silakan gunakan password.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    size: 64,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'JastipGo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.teal.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Global & Domestic Jastip Companion\n(Jepang, Korea, London, Singapura)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Kartu Form Login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKunci,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Masuk Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (widget.pesanSesiKedaluwarsa) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_clock_outlined, color: Colors.amber.shade900, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Sesi telah kedaluwarsa. Demi keamanan akun Anda, silakan masuk kembali.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Input Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Alamat Email',
                            hintText: 'nama@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Input Password
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
                                setState(() {
                                  _sembunyikanPassword = !_sembunyikanPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tombol Masuk
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _sedangMemuat
                              ? null
                              : _masukDenganEmailPassword,
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
                                  'MASUK SEKARANG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Tombol Sensor Biometrik
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade800,
                            side: BorderSide(color: Colors.teal.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _masukDenganBiometrik,
                          icon: const Icon(Icons.fingerprint, size: 26),
                          label: const Text(
                            'Masuk Cepat dengan Sidik Jari',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Uji Coba Cepat Akun DB (Pemesan & Traveler)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilihan Cepat Akun Uji Coba Sesuai Peran:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal.shade800,
                                side: BorderSide(color: Colors.teal.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _emailController.text = 'pemesan@jastipgo.com';
                                  _passwordController.text = 'password123';
                                });
                              },
                              icon: const Icon(Icons.person, size: 14),
                              label: const Text('Akun Pemesan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo.shade800,
                                side: BorderSide(color: Colors.indigo.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _emailController.text = 'traveler.dimas@jastipgo.com';
                                  _passwordController.text = 'password123';
                                });
                              },
                              icon: const Icon(Icons.flight_takeoff, size: 14),
                              label: const Text('Akun Traveler', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link ke Halaman Registrasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun JastipGo? '),
                    GestureDetector(
                      onTap: () async {
                        final String? emailTerdaftar = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HalamanDaftar(),
                          ),
                        );
                        if (emailTerdaftar != null &&
                            emailTerdaftar.isNotEmpty) {
                          setState(() {
                            _emailController.text = emailTerdaftar;
                            _passwordController.clear();
                          });
                        }
                      },
                      child: Text(
                        'Daftar Baru',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
