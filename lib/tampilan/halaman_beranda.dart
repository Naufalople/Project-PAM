import 'package:flutter/material.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_keranjang.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_sensor.dart';
import '../widget/kartu_barang.dart';
import 'halaman_detail_barang.dart';
import 'halaman_chat_traveler.dart';

// Halaman Beranda: Katalog Jastip, Filter Negara Singgah, dan Pencarian Live
class HalamanBeranda extends StatefulWidget {
  final Function(int)? padaPindahTab;

  const HalamanBeranda({super.key, this.padaPindahTab});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  final TextEditingController _pencarianController = TextEditingController();
  String _negaraDipilih = 'Semua';
  String _kategoriDipilih = 'Semua';
  String _urutanHarga = 'Normal';
  List<ModelBarangJastip> _daftarBarang = [];
  bool _sedangMemuat = true;
  String? _pesanError;
  String _peranAktif = 'PEMESAN';
  String _destinasiTraveler = 'Jepang';

  final List<String> _daftarKategori = [
    'Semua',
    'Kuliner',
    'Skincare',
    'Fashion',
    'Hobi & Anime',
  ];

  @override
  void initState() {
    super.initState();
    _muatDataBarang();
  }

  @override
  void dispose() {
    _pencarianController.dispose();
    super.dispose();
  }

  void _bukaDialogPencarianSuara() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalPencarianSuara(
        onKataKunciDidapat: (kataKunci) {
          setState(() {
            _pencarianController.text = kataKunci;
          });
          _muatDataBarang();
          LayananNotifikasi.kirimNotifikasi(
            context,
            judul: 'Pencarian Suara 🎙️',
            pesan: 'Mencari produk dengan kata kunci: "$kataKunci"',
            ikon: Icons.mic_rounded,
            warna: Colors.teal.shade800,
          );
        },
      ),
    );
  }

  Future<void> _muatDataBarang() async {
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });
    try {
      final hasil = await LayananApi.filterBarang(
        negara: _negaraDipilih,
        kategori: _kategoriDipilih,
        kataKunci: _pencarianController.text,
        urutanHarga: _urutanHarga,
      );
      final peran = await LayananOtentikasi.ambilPeranAktif();
      final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
      if (!mounted) return;
      setState(() {
        _peranAktif = peran;
        _destinasiTraveler = destinasi;
        _daftarBarang = hasil;
        _sedangMemuat = false;
        _pesanError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sedangMemuat = false;
        _pesanError = 'Gagal memuat katalog: $e';
      });
    }
  }

  // Tambahkan barang langsung ke keranjang Hive dengan validasi rute destinasi (Poin 4)
  Future<void> _tambahBarangKeKeranjang(ModelBarangJastip barang) async {
    final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
    if (!LayananOtentikasi.apakahNegaraSesuai(barang.negara, destinasi)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.flight_land_rounded, color: Colors.deepOrange.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Rute Berbeda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Traveler saat ini sedang aktif bertugas pada rute perjalanan $destinasi.\n\nAnda hanya dapat menitip barang yang berasal dari $destinasi untuk rute perjalanan ini.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final itemKeranjang = ModelKeranjang(
      idBarang: barang.id,
      namaBarang: barang.namaBarang,
      negara: barang.negara,
      kodeMataUang: barang.kodeMataUang,
      hargaAsli: barang.hargaAsli,
      hargaIdr: barang.estimasiHargaIdr,
      jumlah: 1,
      fotoUrl: barang.fotoUrl,
    );

    await LayananBasisDataLokal.tambahKeKeranjang(itemKeranjang);

    if (!mounted) return;

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Ditambahkan ke Keranjang',
      pesan: '${barang.namaBarang} berhasil masuk ke daftar belanja lokal Anda.',
      ikon: Icons.shopping_bag_outlined,
      warna: Colors.teal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JastipGo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Global & Domestic Jastip',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: _peranAktif == 'TRAVELER' ? Colors.indigo.shade800 : Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Poin 4: Shortcut Obrolan (Chat) di Header Beranda tepat di samping keranjang
          IconButton(
            tooltip: _peranAktif == 'TRAVELER' ? 'Kotak Masuk Chat Pemesan' : 'Chat Traveler',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanChatTraveler(),
                ),
              );
            },
          ),
          if (_peranAktif != 'TRAVELER')
            IconButton(
              tooltip: 'Keranjang',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                if (widget.padaPindahTab != null) {
                  widget.padaPindahTab!(1); // Pindah ke tab keranjang
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muatDataBarang,
        color: _peranAktif == 'TRAVELER' ? Colors.indigo : Colors.teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Rekomendasi / Informasi Negara Singgah Sesuai Peran (Poin 2)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _peranAktif == 'TRAVELER'
                        ? [Colors.indigo.shade800, Colors.indigo.shade500]
                        : [Colors.teal.shade800, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_peranAktif == 'TRAVELER' ? Colors.indigo : Colors.teal).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _peranAktif == 'TRAVELER' ? '✈️ MODE TRAVELER AKTIF' : '✈️ OPEN PO AKTIF',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📍 Rute: $_destinasiTraveler',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _peranAktif == 'TRAVELER'
                          ? 'Kelola Titipan & Riset Barang'
                          : 'Titip Barang Impian Dari Luar Negeri',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _peranAktif == 'TRAVELER'
                          ? 'Rute tugas aktif: $_destinasiTraveler. Anda dapat mengubah destinasi di menu Profil.'
                          : 'Traveler saat ini melayani rute: $_destinasiTraveler. Jaminan 100% Produk Original & Bergaransi.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Kotak Pencarian Live (Search Bar)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _pencarianController,
                  onChanged: (val) => _muatDataBarang(),
                  decoration: InputDecoration(
                    hintText: 'Cari barang, oleh-oleh, atau toko...',
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_pencarianController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _pencarianController.clear();
                              _muatDataBarang();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.mic_rounded, color: Colors.teal),
                          tooltip: 'Pencarian Suara (Voice Search)',
                          onPressed: _bukaDialogPencarianSuara,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pilihan Negara Singgah (Filter Negara)
              const Text(
                '📍 Pilih Negara Singgah:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: LayananApi.daftarNegaraSinggah.map((neg) {
                    final bool aktif = _negaraDipilih == neg['nama'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${neg['bendera']} ${neg['nama']}'),
                        selected: aktif,
                        selectedColor: Colors.teal.shade700,
                        labelStyle: TextStyle(
                          color: aktif ? Colors.white : Colors.black87,
                          fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (bool selected) {
                          setState(() {
                            _negaraDipilih = neg['nama']!;
                          });
                          _muatDataBarang();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Pilihan Kategori & Filter Urutan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Kategori
                  DropdownButton<String>(
                    value: _kategoriDipilih,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.category_outlined, size: 18, color: Colors.teal),
                    style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                    items: _daftarKategori.map((k) {
                      return DropdownMenuItem(value: k, child: Text('Kategori: $k'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _kategoriDipilih = val);
                        _muatDataBarang();
                      }
                    },
                  ),

                  // Filter Urutan Harga
                  DropdownButton<String>(
                    value: _urutanHarga,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, size: 18, color: Colors.teal),
                    style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                    items: ['Normal', 'Termurah', 'Termahal', 'Populer'].map((u) {
                      return DropdownMenuItem(value: u, child: Text('Urut: $u'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _urutanHarga = val);
                        _muatDataBarang();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Daftar Barang (Grid 2 Kolom dengan State Loading, Error, dan Data Kosong)
              _sedangMemuat
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.teal),
                          const SizedBox(height: 14),
                          Text(
                            'Memuat katalog produk jastip...',
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _pesanError != null
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Gagal Memuat Produk',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _pesanError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _muatDataBarang,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _daftarBarang.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tidak ada barang ditemukan.',
                                    style: TextStyle(color: Colors.black54, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Coba ganti kata kunci atau pilih negara singgah lain.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black38, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                      : GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _daftarBarang.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.52,
                          ),
                          itemBuilder: (context, index) {
                            final barang = _daftarBarang[index];
                            return KartuBarang(
                              barang: barang,
                              bisaTitip: _peranAktif != 'TRAVELER',
                              saatDitekan: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HalamanDetailBarang(barang: barang),
                                  ),
                                );
                              },
                              saatTombolTitip: () => _tambahBarangKeKeranjang(barang),
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

/// Modal Bottom Sheet Sensor Suara untuk Pencarian Cepat di Beranda
class _ModalPencarianSuara extends StatefulWidget {
  final Function(String kataKunci) onKataKunciDidapat;

  const _ModalPencarianSuara({required this.onKataKunciDidapat});

  @override
  State<_ModalPencarianSuara> createState() => _ModalPencarianSuaraState();
}

class _ModalPencarianSuaraState extends State<_ModalPencarianSuara>
    with SingleTickerProviderStateMixin {
  late AnimationController _animasiPulse;
  bool _sedangMendengarkan = false;
  String _teksUcapan = '';
  String _status = 'Mengaktifkan sensor mikrofon...';

  @override
  void initState() {
    super.initState();
    _animasiPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mulaiDengar();
    });
  }

  @override
  void dispose() {
    LayananSensorSuara.berhenti();
    _animasiPulse.dispose();
    super.dispose();
  }

  Future<void> _mulaiDengar() async {
    setState(() {
      _sedangMendengarkan = true;
      _status = '🔴 Mendengarkan suara Anda... Silakan berbicara.';
    });

    await LayananSensorSuara.mulaiMendengarkan(
      bahasa: 'id_ID',
      saatMendengar: (hasilTeks, finalResult) {
        if (!mounted) return;
        setState(() {
          _teksUcapan = hasilTeks;
          if (finalResult) {
            _sedangMendengarkan = false;
            _status = 'Berhasil mengenali: "$hasilTeks"';
          }
        });
        if (finalResult && hasilTeks.trim().isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.pop(context);
              widget.onKataKunciDidapat(hasilTeks);
            }
          });
        }
      },
      saatError: (err) {
        if (!mounted) return;
        setState(() {
          _sedangMendengarkan = false;
          _status = err;
        });
      },
    );
  }

  void _pilihContoh(String contoh) {
    LayananSensorSuara.berhenti();
    Navigator.pop(context);
    widget.onKataKunciDidapat(contoh);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.mic_rounded, color: Colors.teal.shade800, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Pencarian Suara (Voice Search)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tombol Mic Berdenyut
          GestureDetector(
            onTap: () {
              if (_sedangMendengarkan) {
                LayananSensorSuara.berhenti();
                setState(() {
                  _sedangMendengarkan = false;
                  _status = 'Mikrofon dijeda. Ketuk untuk mengulang.';
                });
              } else {
                _mulaiDengar();
              }
            },
            child: AnimatedBuilder(
              animation: _animasiPulse,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _sedangMendengarkan ? Colors.teal.shade700 : Colors.teal.shade800,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(
                          alpha: 0.25 + (_sedangMendengarkan ? _animasiPulse.value * 0.45 : 0),
                        ),
                        blurRadius: 16 + (_sedangMendengarkan ? _animasiPulse.value * 12 : 0),
                        spreadRadius: 2 + (_sedangMendengarkan ? _animasiPulse.value * 6 : 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    _sedangMendengarkan ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          Text(
            _status,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _sedangMendengarkan ? Colors.teal.shade900 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Teks Hasil Live Transkrip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Text(
              _teksUcapan.isNotEmpty
                  ? '"$_teksUcapan"'
                  : 'Katakan nama produk (contoh: Tokyo Banana, Gundam, Matcha)...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontStyle: _teksUcapan.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                color: _teksUcapan.isNotEmpty ? Colors.teal.shade900 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Quick Chips
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Atau pilih contoh suara:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
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
                    onPressed: () => _pilihContoh(contoh),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_teksUcapan.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  LayananSensorSuara.berhenti();
                  Navigator.pop(context);
                  widget.onKataKunciDidapat(_teksUcapan);
                },
                icon: const Icon(Icons.search, size: 18),
                label: Text('Cari "$_teksUcapan" Sekarang'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
