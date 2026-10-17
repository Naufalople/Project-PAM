import 'package:flutter/material.dart';
import '../model/model_pengguna.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_biometrik.dart';
import 'halaman_masuk.dart';
import 'halaman_saran_kesan.dart';
import 'halaman_sertifikat_blockchain.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_status_pesanan.dart';

// Halaman Profil Pengguna: Informasi Akun, Foto, Sertifikat Blockchain, dan Logout
class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  ModelPengguna? _profilPengguna;
  bool _biometrikAktif = false;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final profil = await LayananOtentikasi.ambilProfilAktif();
    bool biometrikAktif = false;
    if (profil != null) {
      biometrikAktif = await LayananBiometrik.apakahBiometrikAktifUntukAkun(profil.email);
    }
    if (!mounted) return;
    setState(() {
      _profilPengguna = profil;
      _biometrikAktif = biometrikAktif;
    });
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
                        radius: 46,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: NetworkImage(fotoUrl),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ],
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
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_shipping_rounded, color: Colors.deepOrange.shade800),
                    ),
                    title: const Text('Pesanan Saya & Rekber Escrow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Lacak status barang & perlindungan dana', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanStatusPesanan()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.link_rounded, color: Colors.blueGrey),
                    ),
                    title: const Text('Buku Besar Blockchain', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Bukti transaksi & keaslian struk belanja', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanSertifikatBlockchain()),
                      );
                    },
                  ),
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
