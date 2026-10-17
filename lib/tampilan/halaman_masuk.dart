import 'package:flutter/material.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_biometrik.dart';
import '../widget/dialog_peringatan.dart';
import 'halaman_daftar.dart';
import 'halaman_utama.dart';

// Halaman Masuk (Login) dengan Password Enkripsi SHA-256 & Biometrik Sidik Jari
class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final _formKunci = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: 'budi@jastipgo.com');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');
  bool _sedangMemuat = false;
  bool _sembunyikanPassword = true;

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
    final bool sukses = await LayananBiometrik.autentikasiSidikJari(
      pesanAlasan: 'Pindai sidik jari Anda untuk masuk cepat ke JastipGo',
    );

    if (!mounted) return;

    if (sukses) {
      // Login langsung menggunakan akun utama
      final semuaAkun = await LayananOtentikasi.ambilSemuaAkun();
      if (semuaAkun.isNotEmpty) {
        await LayananOtentikasi.prosesMasuk(
          email: semuaAkun.first.email,
          password: 'password123',
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HalamanUtama()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Biometrik Gagal',
          deskripsi: 'Otentikasi sidik jari tidak dikenali. Silakan gunakan password biasa.',
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                          onPressed: _sedangMemuat ? null : _masukDenganEmailPassword,
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
                const SizedBox(height: 24),

                // Link ke Halaman Registrasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun JastipGo? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HalamanDaftar()),
                        );
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
