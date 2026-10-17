import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../layanan/layanan_ai.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_notifikasi.dart';
import '../model/model_keranjang.dart';

// Halaman Pemindai Foto AI (Ala Google Lens) untuk Identifikasi Barang Titipan
class HalamanPemindaiAi extends StatefulWidget {
  const HalamanPemindaiAi({super.key});

  @override
  State<HalamanPemindaiAi> createState() => _HalamanPemindaiAiState();
}

class _HalamanPemindaiAiState extends State<HalamanPemindaiAi> {
  bool _sedangMemindai = false;
  HasilPemindaianAi? _hasilPemindaian;
  int _presetPilihan = 0;
  XFile? _fileFoto;
  final ImagePicker _picker = ImagePicker();

  // Daftar sampel foto barang mancanegara untuk simulasi pemindaian AI
  final List<Map<String, String>> _sampelFoto = [
    {
      'label': 'Kue Tokyo Banana (Jepang)',
      'fotoUrl': 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500',
    },
    {
      'label': 'Lotion Hada Labo (Jepang)',
      'fotoUrl': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
    },
    {
      'label': 'COSRX Snail Essence (Korea)',
      'fotoUrl': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=500',
    },
    {
      'label': 'Album K-Pop BTS (Korea)',
      'fotoUrl': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
    },
    {
      'label': 'Tas Harrods Hijau (London UK)',
      'fotoUrl': 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
    },
    {
      'label': 'Teh Twinings Klasik (London UK)',
      'fotoUrl': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500',
    },
    {
      'label': 'Irvins Salted Egg (Singapura)',
      'fotoUrl': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500',
    },
    {
      'label': 'Pop Mart Skullpanda (China)',
      'fotoUrl': 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=500',
    },
  ];

  Future<void> _ambilFotoDariKamera() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (foto != null) {
        setState(() {
          _fileFoto = foto;
          _hasilPemindaian = null;
        });
        await _jalankanPemindaian();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamera tidak dapat diakses: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pilihFotoDariGaleri() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (foto != null) {
        setState(() {
          _fileFoto = foto;
          _hasilPemindaian = null;
        });
        await _jalankanPemindaian();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Galeri tidak dapat diakses: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _jalankanPemindaian() async {
    setState(() {
      _sedangMemindai = true;
      _hasilPemindaian = null;
    });

    final HasilPemindaianAi hasil;
    if (_fileFoto != null) {
      hasil = await LayananAi.pindaiGambarKamera(
        namaFileAtauPath: _fileFoto!.name,
      );
    } else {
      hasil = await LayananAi.pindaiGambarProduk(presetIndeks: _presetPilihan);
    }

    if (!mounted) return;

    setState(() {
      _hasilPemindaian = hasil;
      _sedangMemindai = false;
    });

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'AI Berhasil Mengenali Barang!',
      pesan: 'Dikenali: ${hasil.namaProduk} (${hasil.negaraAsal}) dengan keyakinan ${(hasil.tingkatKeyakinan * 100).toInt()}%',
      ikon: Icons.auto_awesome,
      warna: Colors.purple,
    );
  }

  // Tambah hasil AI langsung ke keranjang belanja
  Future<void> _tambahLangsungKeKeranjang() async {
    if (_hasilPemindaian == null) return;

    final String foto = _fileFoto != null
        ? _fileFoto!.path
        : _sampelFoto[_presetPilihan]['fotoUrl']!;

    final item = ModelKeranjang(
      idBarang: DateTime.now().millisecondsSinceEpoch % 100000,
      namaBarang: _hasilPemindaian!.namaProduk,
      fotoUrl: foto,
      negara: _hasilPemindaian!.negaraAsal,
      kodeMataUang: _hasilPemindaian!.kodeMataUang,
      hargaAsli: _hasilPemindaian!.estimasiHargaAsli,
      hargaIdr: _hasilPemindaian!.estimasiHargaIdr,
      jumlah: 1,
    );

    await LayananBasisDataLokal.tambahKeKeranjang(item);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${_hasilPemindaian!.namaProduk} berhasil dimasukkan ke Keranjang!'),
        backgroundColor: Colors.teal.shade800,
        action: SnackBarAction(
          label: 'LIHAT KERANJANG',
          textColor: Colors.amberAccent,
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman utama / keranjang
          },
        ),
      ),
    );
  }

  // Tambah hasil AI langsung ke katalog request jastip
  Future<void> _simpanKeKatalogJastip() async {
    if (_hasilPemindaian == null) return;

    final String foto = _fileFoto != null
        ? 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500'
        : _sampelFoto[_presetPilihan]['fotoUrl']!;

    final barang = LayananAi.konversiKeBarangJastip(
      _hasilPemindaian!,
      foto,
    );

    await LayananApi.tambahBarangJastip(barang);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barang berhasil diajukan ke katalog request Open PO JastipGo!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoTerpilih = _sampelFoto[_presetPilihan]['fotoUrl']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('AI Lens Scanner'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Penjelasan Fitur
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.camera_enhance_rounded, color: Colors.purple.shade800, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pindai foto barang impian luar negeri. AI akan membaca objek, negara asal, dan estimasi harga tanpa perlu ketik manual.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Bingkai Kamera / Pemindai Foto
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _fileFoto != null
                        ? Image.file(
                            File(_fileFoto!.path),
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white54,
                            ),
                          )
                        : Image.network(
                            fotoTerpilih,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                  ),

                  // Overlay Bidikan Scanner ala Google Lens
                  Container(
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purpleAccent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  if (_sedangMemindai)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.purpleAccent),
                            SizedBox(height: 12),
                            Text(
                              'AI sedang memindai objek...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Akses Kamera & Galeri HP
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sedangMemindai ? null : _ambilFotoDariKamera,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Buka Kamera HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade800,
                      side: BorderSide(color: Colors.purple.shade400, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sedangMemindai ? null : _pilihFotoDariGaleri,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pemilihan Sampel Foto Barang Alternatif
            const Text(
              'Atau Pilih Sampel Foto Katalog:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_sampelFoto.length, (index) {
                  final item = _sampelFoto[index];
                  final bool terpilih = _fileFoto == null && _presetPilihan == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(item['label']!),
                      selected: terpilih,
                      selectedColor: Colors.purple.shade700,
                      labelStyle: TextStyle(
                        color: terpilih ? Colors.white : Colors.black87,
                        fontWeight: terpilih ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _fileFoto = null;
                          _presetPilihan = index;
                          _hasilPemindaian = null;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Mulai Scan AI
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: _sedangMemindai ? null : _jalankanPemindaian,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'PINDAI DENGAN AI (GOOGLE LENS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Tampilan Hasil Deteksi AI
            if (_hasilPemindaian != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.08),
                      blurRadius: 12,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Akurasi: ${(_hasilPemindaian!.tingkatKeyakinan * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.purple.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '📍 ${_hasilPemindaian!.negaraAsal}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasilPemindaian!.namaProduk,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kategori: ${_hasilPemindaian!.kategori}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Harga Asli:', style: TextStyle(fontSize: 11, color: Colors.black45)),
                            Text(
                              LayananKonversi.formatMataUangAsing(
                                _hasilPemindaian!.estimasiHargaAsli,
                                _hasilPemindaian!.kodeMataUang,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Estimasi Nilai Rupiah:', style: TextStyle(fontSize: 11, color: Colors.black45)),
                            Text(
                              LayananKonversi.formatRupiah(_hasilPemindaian!.estimasiHargaIdr),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasilPemindaian!.deskripsi,
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _tambahLangsungKeKeranjang,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Masukkan Langsung ke Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade800,
                          side: BorderSide(color: Colors.purple.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _simpanKeKatalogJastip,
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Simpan ke Daftar Request Jastip'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
