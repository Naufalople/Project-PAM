import 'package:flutter/material.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_keranjang.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_ai.dart';
import '../layanan/layanan_api.dart';
import 'halaman_checkout.dart';
import '../layanan/layanan_otentikasi.dart';

// Halaman Detail Barang Jastip & Rekomendasi Cerdas AI
class HalamanDetailBarang extends StatefulWidget {
  final ModelBarangJastip barang;

  const HalamanDetailBarang({super.key, required this.barang});

  @override
  State<HalamanDetailBarang> createState() => _HalamanDetailBarangState();
}

class _HalamanDetailBarangState extends State<HalamanDetailBarang> {
  // Variabel Rekomendasi Cerdas AI (Content-Based & Jaccard Similarity)
  List<RekomendasiBarangAi> _daftarRekomendasi = [];
  bool _memuatRekomendasi = true;
  String _peranAktif = 'PEMESAN';

  @override
  void initState() {
    super.initState();
    _muatRekomendasiAi();
    _muatPeran();
  }

  Future<void> _muatPeran() async {
    final peran = await LayananOtentikasi.ambilPeranAktif();
    if (mounted) {
      setState(() => _peranAktif = peran);
    }
  }

  Future<void> _muatRekomendasiAi() async {
    try {
      final semuaBarang = await LayananApi.ambilSemuaBarang();
      final hasil = LayananAi.rekomendasikanBarang(
        barangAcuan: widget.barang,
        semuaBarang: semuaBarang,
      );
      if (mounted) {
        setState(() {
          _daftarRekomendasi = hasil;
          _memuatRekomendasi = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _memuatRekomendasi = false);
    }
  }

  // Tampilkan Dialog Penolakan Jika Rute Destinasi Tidak Sesuai (Poin 4.2)
  void _tampilkanDialogRuteBeda(String destinasi) {
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
          'Traveler saat ini sedang aktif ditugaskan pada rute perjalanan $destinasi.\n\nAnda hanya dapat memesan atau menitip produk yang berasal dari $destinasi untuk rute ini.',
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
  }

  // Tambah ke Keranjang Lokal Hive dengan Validasi Destinasi Aktif Traveler (Poin 4)
  Future<void> _tambahKeKeranjang() async {
    final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
    if (!LayananOtentikasi.apakahNegaraSesuai(widget.barang.negara, destinasi)) {
      if (!mounted) return;
      _tampilkanDialogRuteBeda(destinasi);
      return;
    }

    final item = ModelKeranjang(
      idBarang: widget.barang.id,
      namaBarang: widget.barang.namaBarang,
      negara: widget.barang.negara,
      kodeMataUang: widget.barang.kodeMataUang,
      hargaAsli: widget.barang.hargaAsli,
      hargaIdr: widget.barang.estimasiHargaIdr,
      jumlah: 1,
      fotoUrl: widget.barang.fotoUrl,
    );

    await LayananBasisDataLokal.tambahKeKeranjang(item);

    if (!mounted) return;

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Berhasil Masuk Keranjang',
      pesan: '${widget.barang.namaBarang} tersimpan di penyimpanan offline.',
      ikon: Icons.check_circle_outline,
      warna: Colors.teal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.barang.namaBarang),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Gambar Produk Jastip
            Container(
              width: double.infinity,
              height: 280,
              color: Colors.black,
              child: Image.network(
                widget.barang.fotoUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 280,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),

            // Informasi Utama Barang
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lencana Negara & Kategori
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.barang.benderaNegara} ${widget.barang.negara}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.barang.kategori,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.people_outline, size: 18, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.barang.jumlahPeminat} Peminat',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nama Barang
                  Text(
                    widget.barang.namaBarang,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Panel Harga (Mata Uang Asing & Konversi Rupiah)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Harga Asli di LN:',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                LayananKonversi.formatMataUangAsing(
                                  widget.barang.hargaAsli,
                                  widget.barang.kodeMataUang,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Estimasi Rupiah:',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                LayananKonversi.formatRupiah(widget.barang.estimasiHargaIdr),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.teal.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Toko & Batas PO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront, color: Colors.brown, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toko Beli: ${widget.barang.namaToko}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Batas Waktu Titip: ${widget.barang.batasWaktuPo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi Barang
                  const Text(
                    'Deskripsi Produk:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.barang.deskripsi,
                    style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // REKOMENDASI CERDAS UNTUK ANDA (FITUR AI - HANYA UNTUK PEMESAN - POIN 3)
                  // ==========================================
                  if (_peranAktif != 'TRAVELER') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Rekomendasi Cerdas untuk Anda',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Text(
                          'AI Similarity',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dihitung dengan algoritma kemiripan atribut negara, kategori, & preferensi titipan:',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 12),

                  _memuatRekomendasi
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.teal),
                          ),
                        )
                      : _daftarRekomendasi.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'Belum ada rekomendasi barang serupa saat ini.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _daftarRekomendasi.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final rek = _daftarRekomendasi[index];
                                  final item = rek.barang;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HalamanDetailBarang(barang: item),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 155,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.teal.shade100),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Image.network(
                                                  item.fotoUrl,
                                                  height: 95,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Container(
                                                    height: 95,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(Icons.image, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade800,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${rek.persentaseCocok}% Cocok',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.namaBarang,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.benderaNegara} ${item.negara}',
                                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                                          ),
                                          const Spacer(),
                                          Text(
                                            LayananKonversi.formatRupiah(item.estimasiHargaIdr),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.teal.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            rek.alasanRekomendasi,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.teal.shade700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  ],
                  const SizedBox(height: 100), // Spasi agar tidak tertutup bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _peranAktif == 'TRAVELER'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flight_takeoff, color: Colors.indigo.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Akun Traveler ✈️',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const Text(
                            'Fitur pemesanan dan checkout dinonaktifkan untuk akun Traveler. Traveler berfokus menerima dan mengelola titipan barang.',
                            style: TextStyle(fontSize: 10.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade800,
                        side: BorderSide(color: Colors.teal.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _tambahKeKeranjang,
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
                        if (!LayananOtentikasi.apakahNegaraSesuai(widget.barang.negara, destinasi)) {
                          if (!context.mounted) return;
                          _tampilkanDialogRuteBeda(destinasi);
                          return;
                        }
                        // Langsung ke checkout untuk item ini
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HalamanCheckout(
                              daftarItem: [
                                ModelKeranjang(
                                  idBarang: widget.barang.id,
                                  namaBarang: widget.barang.namaBarang,
                                  negara: widget.barang.negara,
                                  kodeMataUang: widget.barang.kodeMataUang,
                                  hargaAsli: widget.barang.hargaAsli,
                                  hargaIdr: widget.barang.estimasiHargaIdr,
                                  jumlah: 1,
                                  fotoUrl: widget.barang.fotoUrl,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('TITIP SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
