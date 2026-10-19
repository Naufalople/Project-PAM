import 'package:flutter/material.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_keranjang.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
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
      if (!mounted) return;
      setState(() {
        _peranAktif = peran;
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

  // Tambahkan barang langsung ke keranjang Hive
  Future<void> _tambahBarangKeKeranjang(ModelBarangJastip barang) async {
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
                        const Text(
                          'London • Tokyo • Seoul • SG',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
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
                          ? 'Pantau pesanan belanja masuk dari pemesan, cek batas bawaan koper, dan pantau harga pasar.'
                          : 'Jaminan 100% Original dengan Sertifikat Struk Blockchain & Kurs Terkini.',
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
                    suffixIcon: _pencarianController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _pencarianController.clear();
                              _muatDataBarang();
                            },
                          )
                        : null,
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
