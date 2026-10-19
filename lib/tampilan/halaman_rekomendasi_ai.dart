import 'package:flutter/material.dart';
import '../layanan/layanan_ai.dart';
import '../layanan/layanan_api.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_notifikasi.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_keranjang.dart';
import 'halaman_detail_barang.dart';

// Halaman Pusat AI Recommendation Engine
// Mengolah data riwayat pembelian (dummy + transaksi nyata) dan kemiripan produk
class HalamanRekomendasiAi extends StatefulWidget {
  const HalamanRekomendasiAi({super.key});

  @override
  State<HalamanRekomendasiAi> createState() => _HalamanRekomendasiAiState();
}

class _HalamanRekomendasiAiState extends State<HalamanRekomendasiAi> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ModelBarangJastip> _semuaBarang = [];
  bool _memuat = true;

  // State untuk mode simulasi interaktif
  ModelBarangJastip? _barangTerpilihSimulasi;
  List<RekomendasiBarangAi> _hasilSimulasi = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _muatDataKatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _muatDataKatalog() async {
    setState(() => _memuat = true);
    try {
      final data = await LayananApi.ambilSemuaBarang();
      if (mounted) {
        setState(() {
          _semuaBarang = data;
          if (_semuaBarang.isNotEmpty) {
            _barangTerpilihSimulasi = _semuaBarang.first;
            _hitungSimulasi(_barangTerpilihSimulasi!);
          }
          _memuat = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _hitungSimulasi(ModelBarangJastip barang) {
    final hasil = LayananAi.rekomendasikanBarang(
      barangAcuan: barang,
      semuaBarang: _semuaBarang,
      batasHasil: 6,
    );
    setState(() {
      _barangTerpilihSimulasi = barang;
      _hasilSimulasi = hasil;
    });
  }

  Future<void> _tambahKeKeranjang(ModelBarangJastip barang) async {
    final item = ModelKeranjang(
      idBarang: barang.id,
      namaBarang: barang.namaBarang,
      fotoUrl: barang.fotoUrl,
      negara: '${barang.negara} ${barang.benderaNegara}',
      kodeMataUang: barang.kodeMataUang,
      hargaAsli: barang.hargaAsli,
      hargaIdr: barang.estimasiHargaIdr,
      jumlah: 1,
    );

    await LayananBasisDataLokal.tambahKeKeranjang(item);

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Dimasukkan ke Keranjang',
      pesan: '${barang.namaBarang} berhasil ditambahkan!',
      ikon: Icons.shopping_cart_checkout_rounded,
      warna: Colors.teal,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${barang.namaBarang} dimasukkan ke Keranjang!'),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Refresh data rekomendasi jika ada perubahan
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('AI Recommendation Engine'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome, size: 20), text: 'Untuk Anda'),
            Tab(icon: Icon(Icons.local_fire_department, size: 20), text: 'Terlaris'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Simulasi AI'),
          ],
        ),
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _bangunTabUntukAnda(),
                _bangunTabTerlaris(),
                _bangunTabSimulasiAi(),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: REKOMENDASI PERSONALISASI UNTUK PENGGUNA
  // ==========================================
  Widget _bangunTabUntukAnda() {
    final rekomendasi = LayananAi.rekomendasikanUntukPengguna(
      semuaBarang: _semuaBarang,
      batasHasil: 8,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bangunKartuInfoAlgoritma(
          judul: 'Personalisasi Cerdas (Collaborative & Content-Based)',
          deskripsi:
              'Rekomendasi dihitung otomatis berdasarkan barang dalam keranjang belanja Anda, riwayat pesanan, volume penjualan platform, serta analisis barang yang sering dibeli bersamaan.',
          ikon: Icons.psychology_rounded,
          warna: Colors.deepPurple,
        ),
        const SizedBox(height: 16),
        const Text(
          'Barang Paling Cocok Untuk Anda:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        if (rekomendasi.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('Belum ada data barang tersedia.'),
            ),
          )
        else
          ...rekomendasi.map((rek) => _bangunKartuItemRekomendasi(rek)),
      ],
    );
  }

  // ==========================================
  // TAB 2: PRODUK TERLARIS BERBASIS TOTAL PEMBELIAN
  // ==========================================
  Widget _bangunTabTerlaris() {
    final terlaris = LayananAi.ambilProdukTerlaris(
      semuaBarang: _semuaBarang,
      batasHasil: 10,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bangunKartuInfoAlgoritma(
          judul: 'Peringkat Berbasis Total Volume Pembelian',
          deskripsi:
              'Peringkat ini menggunakan data riwayat transaksi jastip secara komprehensif. Total unit pembelian setiap barang dijadikan bobot utama penentu tren jastip terpopuler.',
          ikon: Icons.trending_up_rounded,
          warna: Colors.orange.shade800,
        ),
        const SizedBox(height: 16),
        const Text(
          'Peringkat Best-Seller JastipGo:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        ...terlaris.asMap().entries.map((entry) {
          final int rank = entry.key + 1;
          final rek = entry.value;
          return _bangunKartuItemRekomendasi(rek, rankNomor: rank);
        }),
      ],
    );
  }

  // ==========================================
  // TAB 3: SIMULASI ENGINE KEMIRIPAN PRODUK
  // ==========================================
  Widget _bangunTabSimulasiAi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bangunKartuInfoAlgoritma(
          judul: 'Simulasi Perhitungan Engine Rekomendasi',
          deskripsi:
              'Pilih salah satu produk di bawah untuk melihat bagaimana AI menghitung skor kemiripan, relasi co-purchase (dibeli bersamaan), dan bobot volume pembelian.',
          ikon: Icons.tune_rounded,
          warna: Colors.teal.shade700,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Produk Acuan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ModelBarangJastip>(
                initialValue: _barangTerpilihSimulasi,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: _semuaBarang.map((b) {
                  final totalBeli = LayananAi.ambilTotalPembelian(b.id);
                  return DropdownMenuItem<ModelBarangJastip>(
                    value: b,
                    child: Text(
                      '${b.benderaNegara} ${b.namaBarang} ($totalBeli terjual)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _hitungSimulasi(val);
                  }
                },
              ),
              if (_barangTerpilihSimulasi != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _barangTerpilihSimulasi!.fotoUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _barangTerpilihSimulasi!.namaBarang,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_barangTerpilihSimulasi!.negara} • ${_barangTerpilihSimulasi!.kategori} • ${LayananAi.ambilTotalPembelian(_barangTerpilihSimulasi!.id)} Terjual',
                              style: TextStyle(fontSize: 11.5, color: Colors.teal.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Hasil Perhitungan Kemiripan Cerdas AI:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        if (_hasilSimulasi.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Pilih barang untuk melihat hasil analisis.')),
          )
        else
          ..._hasilSimulasi.map((rek) => _bangunKartuItemRekomendasi(rek, tampilkanDetailSkor: true)),
      ],
    );
  }

  // ==========================================
  // WIDGET KARTU PENJELASAN ALGORITMA
  // ==========================================
  Widget _bangunKartuInfoAlgoritma({
    required String judul,
    required String deskripsi,
    required IconData ikon,
    required Color warna,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warna.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: warna.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: warna, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: warna),
                ),
                const SizedBox(height: 4),
                Text(
                  deskripsi,
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET KARTU ITEM REKOMENDASI AI
  // ==========================================
  Widget _bangunKartuItemRekomendasi(
    RekomendasiBarangAi rek, {
    int? rankNomor,
    bool tampilkanDetailSkor = false,
  }) {
    final b = rek.barang;
    final int totalTerjual = rek.totalPembelian > 0 ? rek.totalPembelian : LayananAi.ambilTotalPembelian(b.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HalamanDetailBarang(barang: b)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank badge jika mode terlaris
                    if (rankNomor != null) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: rankNomor == 1
                              ? Colors.amber.shade700
                              : rankNomor == 2
                                  ? Colors.blueGrey.shade400
                                  : rankNomor == 3
                                      ? Colors.brown.shade400
                                      : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$rankNomor',
                            style: TextStyle(
                              color: rankNomor <= 3 ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Foto Produk
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        b.fotoUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info Utama Produk
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${b.benderaNegara} ${b.negara}',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                              const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.black38)),
                              Text(
                                b.kategori,
                                style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                              ),
                              const Spacer(),
                              // Match percentage pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '🤖 ${rek.persentaseCocok}% Match',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.namaBarang,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                LayananKonversi.formatRupiah(b.estimasiHargaIdr),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🔥 $totalTerjual Terjual',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),

                // Alasan Rekomendasi & Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.purple.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rek.alasanRekomendasi,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _tambahKeKeranjang(b),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                      label: const Text('Beli', style: TextStyle(fontSize: 11)),
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
