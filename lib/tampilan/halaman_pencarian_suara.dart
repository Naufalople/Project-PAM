import 'package:flutter/material.dart';
import '../layanan/layanan_sensor.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_notifikasi.dart';
import '../model/model_barang_jastip.dart';
import '../widget/kartu_barang.dart';
import 'halaman_detail_barang.dart';

/// Halaman Sensor Suara: Pencarian Produk Jastip Berbasis Mikrofon (Voice Search)
/// Menggantikan sensor giroskop sesuai instruksi TODO_PERBAIKAN_FITUR Poin 3
class HalamanPencarianSuara extends StatefulWidget {
  final String? kataKunciAwal;

  const HalamanPencarianSuara({super.key, this.kataKunciAwal});

  @override
  State<HalamanPencarianSuara> createState() => _HalamanPencarianSuaraState();
}

class _HalamanPencarianSuaraState extends State<HalamanPencarianSuara>
    with SingleTickerProviderStateMixin {
  late AnimationController _animasiPulse;
  bool _sedangMerekam = false;
  String _teksUcapan = '';
  String _statusMikrofon = 'Ketuk ikon mikrofon untuk mulai berbicara...';
  List<ModelBarangJastip> _semuaBarang = [];
  List<ModelBarangJastip> _hasilPencarian = [];
  bool _memuatBarang = true;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animasiPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _muatDaftarBarang();

    if (widget.kataKunciAwal != null && widget.kataKunciAwal!.isNotEmpty) {
      _teksUcapan = widget.kataKunciAwal!;
      _editController.text = _teksUcapan;
    } else {
      // Inisialisasi dan otomatis mulai mendengarkan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mulaiMendengarkanSuara();
      });
    }
  }

  @override
  void dispose() {
    LayananSensorSuara.berhenti();
    _animasiPulse.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _muatDaftarBarang() async {
    try {
      final barang = await LayananApi.ambilSemuaBarang();
      if (mounted) {
        setState(() {
          _semuaBarang = barang;
          _memuatBarang = false;
        });
        if (_teksUcapan.isNotEmpty) {
          _filterBarang(_teksUcapan);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _memuatBarang = false);
    }
  }

  void _filterBarang(String kataKunci) {
    if (kataKunci.trim().isEmpty) {
      setState(() {
        _hasilPencarian = [];
      });
      return;
    }

    final query = kataKunci.toLowerCase().trim();
    final hasil = _semuaBarang.where((b) {
      final nama = b.namaBarang.toLowerCase();
      final toko = b.namaToko.toLowerCase();
      final negara = b.negara.toLowerCase();
      final kategori = b.kategori.toLowerCase();
      return nama.contains(query) ||
          toko.contains(query) ||
          negara.contains(query) ||
          kategori.contains(query);
    }).toList();

    setState(() {
      _hasilPencarian = hasil;
    });
  }

  Future<void> _mulaiMendengarkanSuara() async {
    setState(() {
      _sedangMerekam = true;
      _statusMikrofon = '🔴 Mendengarkan suara Anda... Silakan berbicara.';
    });

    await LayananSensorSuara.mulaiMendengarkan(
      bahasa: 'id_ID',
      saatMendengar: (hasilTeks, finalResult) {
        if (!mounted) return;
        setState(() {
          _teksUcapan = hasilTeks;
          _editController.text = hasilTeks;
          _filterBarang(hasilTeks);
          if (finalResult) {
            _sedangMerekam = false;
            _statusMikrofon = 'Pencarian suara selesai: "$hasilTeks"';
          }
        });
      },
      saatError: (pesanError) {
        if (!mounted) return;
        setState(() {
          _sedangMerekam = false;
          _statusMikrofon = 'Pemberitahuan: $pesanError';
        });
      },
    );
  }

  Future<void> _hentikanMendengarkanSuara() async {
    await LayananSensorSuara.berhenti();
    if (mounted) {
      setState(() {
        _sedangMerekam = false;
        _statusMikrofon = _teksUcapan.isNotEmpty
            ? 'Pencarian suara selesai untuk "$_teksUcapan"'
            : 'Mikrofon dijeda. Ketuk tombol mic untuk mencoba lagi.';
      });
    }
  }

  void _terapkanContohSuara(String teks) {
    setState(() {
      _teksUcapan = teks;
      _editController.text = teks;
      _statusMikrofon = 'Input suara simulasi: "$teks"';
      _sedangMerekam = false;
    });
    LayananSensorSuara.berhenti();
    _filterBarang(teks);

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pencarian Suara Aktif 🎙️',
      pesan: 'Mencari produk dengan kata kunci ucapan: "$teks"',
      ikon: Icons.mic_rounded,
      warna: Colors.teal.shade800,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Pencarian Suara (Voice Search)'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Visual Mikrofon & Gelombang Suara Sensor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade900, Colors.teal.shade700],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tombol Animasi Mikrofon Nyata
                GestureDetector(
                  onTap: () {
                    if (_sedangMerekam) {
                      _hentikanMendengarkanSuara();
                    } else {
                      _mulaiMendengarkanSuara();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animasiPulse,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _sedangMerekam ? Colors.red.shade600 : Colors.teal.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: (_sedangMerekam ? Colors.red : Colors.teal.shade300)
                                  .withValues(alpha: 0.35 + (_sedangMerekam ? _animasiPulse.value * 0.45 : 0)),
                              blurRadius: 16 + (_sedangMerekam ? _animasiPulse.value * 14 : 0),
                              spreadRadius: 2 + (_sedangMerekam ? _animasiPulse.value * 8 : 0),
                            ),
                          ],
                        ),
                        child: Icon(
                          _sedangMerekam ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Status Suara Mikrofon
                Text(
                  _statusMikrofon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Kotak Teks Transkripsi Ucapan Live
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _teksUcapan.isNotEmpty
                              ? '"$_teksUcapan"'
                              : 'Contoh: Ucapkan "Tokyo Banana" atau "Gundam"',
                          style: TextStyle(
                            color: _teksUcapan.isNotEmpty ? Colors.white : Colors.white70,
                            fontStyle: _teksUcapan.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_teksUcapan.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _teksUcapan = '';
                              _editController.clear();
                              _hasilPencarian = [];
                              _statusMikrofon = 'Ketuk mikrofon untuk mulai berbicara kembali.';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Saran Kata Kunci Suara Cepat (Quick Voice Chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🗣️ Coba Ucapkan Cepat:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    Text(
                      'Sensor Mic Suara',
                      style: TextStyle(fontSize: 10, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: LayananSensorSuara.daftarContohSuara.map((contoh) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.mic, size: 14, color: Colors.teal),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: BorderSide(color: Colors.teal.shade200),
                          label: Text(
                            contoh,
                            style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _terapkanContohSuara(contoh),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Hasil Pencarian Katalog Berdasarkan Suara
          Expanded(
            child: _memuatBarang
                ? const Center(child: CircularProgressIndicator())
                : _teksUcapan.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_none_rounded, size: 64, color: Colors.teal.shade200),
                            const SizedBox(height: 12),
                            const Text(
                              'Pencarian Katalog dengan Suara',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gunakan mikrofon atau klik salah satu chip kata kunci di atas.',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : _hasilPencarian.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ada produk dengan kata "$_teksUcapan"',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Coba ucapkan nama oleh-oleh atau produk lain.',
                                  style: TextStyle(fontSize: 11, color: Colors.black45),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _hasilPencarian.length,
                            itemBuilder: (context, index) {
                              final barang = _hasilPencarian[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: KartuBarang(
                                  barang: barang,
                                  saatDitekan: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HalamanDetailBarang(barang: barang),
                                      ),
                                    );
                                  },
                                  saatTombolTitip: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HalamanDetailBarang(barang: barang),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
