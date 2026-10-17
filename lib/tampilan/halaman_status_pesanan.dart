import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../model/model_pesanan_jastip.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_sertifikat_blockchain.dart';

// Halaman Alur Pesanan, Daftar Barang Titipan, Lokasi Live, & Rekber Escrow JastipGo
// Mengimplementasikan:
// 1. Daftar semua pesanan yang dilakukan pengguna (bukan cuma 1 barang)
// 2. Daftar barang rinci di setiap pesanan beserta lokasinya sedang ada di mana
// 3. Logika peran: Traveler di Luar Negeri yang meng-ACC dan klik "Sudah Dibeli di Toko"
// 4. Pemesan di Indonesia yang menerima notifikasi, memilih opsi COD LBS Google Maps, dan mencairkan dana
class HalamanStatusPesanan extends StatefulWidget {
  final String? idPesananTerpilih;

  // Parameter kompatibilitas
  final String? idPesanan;
  final String? namaBarang;
  final String? negaraAsal;
  final int? totalHargaIdr;

  const HalamanStatusPesanan({
    super.key,
    this.idPesananTerpilih,
    this.idPesanan,
    this.namaBarang,
    this.negaraAsal,
    this.totalHargaIdr,
  });

  @override
  State<HalamanStatusPesanan> createState() => _HalamanStatusPesananState();
}

class _HalamanStatusPesananState extends State<HalamanStatusPesanan> {
  List<ModelPesananJastip> _daftarPesanan = [];
  ModelPesananJastip? _pesananAktif;

  // Sudut pandang tampilan peran:
  // 'TRAVELER' -> Sisi Pembeli/Traveler di LN (Yang Meng-ACC & Klik "Sudah Dibeli di Toko")
  // 'PEMESAN'  -> Sisi Pemesan di Indonesia (Menerima Notifikasi & Mengonfirmasi Terima Barang)
  String _sudutPandang = 'PEMESAN';

  @override
  void initState() {
    super.initState();
    _muatPeranDanPesanan();
  }

  Future<void> _muatPeranDanPesanan() async {
    final peran = await LayananOtentikasi.ambilPeranAktif();
    final list = LayananBasisDataLokal.ambilSemuaPesanan();
    if (!mounted) return;
    setState(() {
      _sudutPandang = peran == 'TRAVELER' ? 'TRAVELER' : 'PEMESAN';
      _daftarPesanan = list;

      final targetId = widget.idPesananTerpilih ?? widget.idPesanan;
      if (targetId != null && targetId.isNotEmpty) {
        _pesananAktif = list.firstWhere(
          (p) => p.idPesanan == targetId,
          orElse: () => list.isNotEmpty ? list.first : _buatPesananDarurat(),
        );
      } else {
        _pesananAktif = list.isNotEmpty ? list.first : _buatPesananDarurat();
      }
    });
  }

  ModelPesananJastip _buatPesananDarurat() {
    return ModelPesananJastip(
      idPesanan: 'PO-JSTP-882194',
      tanggal: DateTime.now(),
      negaraAsal: 'Jepang 🇯🇵',
      namaTraveler: 'Dimas Pratama',
      lokasiTerkini: 'Sedang di Toko Ginza Mitsukoshi, Tokyo 🇯🇵',
      tahapStatus: 2,
      metodePenyerahan: 'COD_LBS',
      totalHargaIdr: 475000,
      daftarBarang: [
        ModelItemPesanan(
          namaBarang: 'Tokyo Banana Tokyo Station Edition (Isi 8)',
          fotoUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=500',
          negara: 'Jepang 🇯🇵',
          namaToko: 'Tokyo Banana Ginza',
          jumlah: 1,
          hargaIdr: 285000,
        ),
      ],
    );
  }

  // ==========================================
  // AKSI SISI TRAVELER (PEMBELI DI LUAR NEGERI)
  // ==========================================

  // 1. Traveler Meng-ACC Pesanan
  Future<void> _travelerAccPesanan() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 2;
    final lokasiBaru = 'Toko Resmi di ${pesanan.negaraAsal} (Traveler Sedang Menuju Lokasi)';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pesanan #${pesanan.idPesanan} Di-ACC! ✅',
      pesan: 'Traveler ${pesanan.namaTraveler} telah menyetujui pesanan Anda dan bersiap menuju toko resmi.',
      ikon: Icons.thumb_up_alt_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // 2. Traveler Konfirmasi "Sudah Dibeli di Toko"
  Future<void> _travelerKonfirmasiSudahBeli() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 3;
    final lokasiBaru = 'Kantong Belanja Traveler di ${pesanan.negaraAsal} (Struk Masuk Blockchain)';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Barang Anda Sudah Dibeli! 🛍️',
      pesan: 'Traveler telah membeli ${pesanan.daftarBarang.length} barang titipan Anda di ${pesanan.negaraAsal}. Struk belanja resmi dicatat ke Blockchain.',
      ikon: Icons.shopping_bag_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // 3. Traveler Bawa Barang Naik Pesawat ke RI
  Future<void> _travelerMulaiPenerbangan() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 4;
    const lokasiBaru = 'Bagasi Pesawat Internasional Menuju Bandara Indonesia ✈️';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Penerbangan Menuju Indonesia ✈️',
      pesan: 'Koper titipan berisi barang Anda sedang dalam penerbangan internasional menuju Indonesia.',
      ikon: Icons.flight_takeoff_rounded,
      warna: Colors.blue.shade800,
    );
  }

  // 4. Traveler Konfirmasi Mendarat di Indonesia
  Future<void> _travelerTibaDiIndonesia() async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 5;
    const lokasiBaru = 'Mendarat di Indonesia (Siap COD LBS Hub Kampus UPN Jogja / Bandara) 🇮🇩';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Barang Sudah Mendarat di Indonesia! 🇮🇩',
      pesan: 'Barang titipan #${pesanan.idPesanan} telah tiba di Indonesia. Pemesan dipersilakan memilih COD via LBS atau diantar kurir.',
      ikon: Icons.place_rounded,
      warna: Colors.orange.shade800,
    );
  }

  // ==========================================
  // AKSI SISI PEMESAN (ORANG DI INDONESIA)
  // ==========================================

  // 5. Pemesan Konfirmasi Barang Diterima & Sesuai
  Future<void> _pemesanKonfirmasiDiterima({bool karenaBatasWaktu5Hari = false}) async {
    if (_pesananAktif == null) return;
    final pesanan = _pesananAktif!;

    const statusBaru = 6;
    const lokasiBaru = 'Telah Diterima Pemesan di Alamat Tujuan (Transaksi Selesai) 🎉';

    await LayananBasisDataLokal.perbaruiStatusPesanan(
      pesanan.idPesanan,
      tahapStatus: statusBaru,
      lokasiTerkini: lokasiBaru,
      metodePenyerahan: pesanan.metodePenyerahan,
    );

    setState(() {
      pesanan.tahapStatus = statusBaru;
      pesanan.lokasiTerkini = lokasiBaru;
    });

    final String formatUang = pesanan.totalHargaIdr.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: karenaBatasWaktu5Hari
          ? 'Pesanan #${pesanan.idPesanan} Selesai Otomatis (5 Hari)'
          : 'Barang Berhasil Diterima Pemesan! 🎉',
      pesan: 'Dana Rp $formatUang resmi dicairkan dari Rekber Escrow sistem ke dompet ${pesanan.namaTraveler}.',
      ikon: Icons.verified_rounded,
      warna: Colors.green.shade800,
    );
  }

  String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_pesananAktif == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Pesanan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pesanan = _pesananAktif!;
    final bool adalahSisiTraveler = _sudutPandang == 'TRAVELER';
    final int tahap = pesanan.tahapStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Pelacakan Pesanan & Rekber'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sertifikat Blockchain Struk',
            icon: const Icon(Icons.link_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanSertifikatBlockchain()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DAFTAR PILIHAN PESANAN SAYA (HORISONTAL SELECTOR)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pesanan Saya:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                Text(
                  '${_daftarPesanan.length} Pesanan Aktif',
                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 74,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _daftarPesanan.length,
                itemBuilder: (context, index) {
                  final p = _daftarPesanan[index];
                  final bool terpilih = p.idPesanan == pesanan.idPesanan;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _pesananAktif = p;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 190,
                      margin: const EdgeInsets.only(right: 10, bottom: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: terpilih ? Colors.teal.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: terpilih ? Colors.teal.shade800 : Colors.grey.shade300,
                          width: terpilih ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: terpilih ? 0.08 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.negaraAsal,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: terpilih ? Colors.white : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: terpilih ? Colors.teal.shade700 : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${p.daftarBarang.length} Item',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: terpilih ? Colors.white : Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.idPesanan,
                            style: TextStyle(
                              fontSize: 10,
                              color: terpilih ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            'Rp ${_formatRupiah(p.totalHargaIdr)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: terpilih ? Colors.amber.shade300 : Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // SAKELAR SIMULASI LOGIKA PERAN
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horizontal_circle_outlined, size: 18, color: Colors.teal.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pilih Sudut Pandang Simulasi Ujian:',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _sudutPandang = 'TRAVELER'),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: adalahSisiTraveler ? Colors.indigo.shade700 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: adalahSisiTraveler ? Colors.indigo.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.flight_takeoff, size: 16, color: adalahSisiTraveler ? Colors.white : Colors.black54),
                                const SizedBox(height: 3),
                                Text(
                                  'Sisi Traveler / Pembeli',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: adalahSisiTraveler ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '(ACC & Beli di Luar Negeri)',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: adalahSisiTraveler ? Colors.white70 : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _sudutPandang = 'PEMESAN'),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !adalahSisiTraveler ? Colors.teal.shade700 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !adalahSisiTraveler ? Colors.teal.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.person, size: 16, color: !adalahSisiTraveler ? Colors.white : Colors.black54),
                                const SizedBox(height: 3),
                                Text(
                                  'Sisi Pemesan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: !adalahSisiTraveler ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '(Lacak & Konfirmasi Terima)',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: !adalahSisiTraveler ? Colors.white70 : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // KARTU LOKASI FISIK BARANG LIVE (PERTANYAAN DOSEN / USER)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade800, Colors.teal.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.2),
                    blurRadius: 10,
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Colors.amberAccent, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'LOKASI FISIK BARANG TITIPAN SAAT INI:',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pesanan.lokasiTerkini,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Traveler: ${pesanan.namaTraveler} • Asal: ${pesanan.negaraAsal}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  if (tahap >= 5) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Buka Titik Temu COD di Google Maps (LBS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // DAFTAR RINCIAN SEMUA BARANG DI PESANAN INI
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Barang (${pesanan.daftarBarang.length} Produk):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tahap == 6 ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tahap == 6 ? Colors.green.shade300 : Colors.amber.shade400,
                          ),
                        ),
                        child: Text(
                          tahap == 6 ? 'DANA SUDAH CAIR' : 'REKBER AKTIF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tahap == 6 ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pesanan.daftarBarang.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.fotoUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.teal.shade50,
                                child: const Icon(Icons.shopping_bag, size: 24, color: Colors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaBarang,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.namaToko} • Jumlah: x${item.jumlah}',
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rp ${_formatRupiah(item.hargaIdr)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Uang Ditahan di Rekber:', style: TextStyle(color: Colors.black54, fontSize: 11.5)),
                      Text(
                        'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                        style: TextStyle(
                          color: Colors.teal.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Timeline Pelacakan & Siklus Rekber:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 14),

            // STEP 1: Pembayaran Selesai & Uang Ditahan Rekber
            _bangunItemTimeline(
              nomor: 1,
              judul: '1. Pembayaran Berhasil & Dana Ditahan Rekber',
              deskripsi: 'Uang Rp ${_formatRupiah(pesanan.totalHargaIdr)} aman disimpan di rekening bersama JastipGo. Traveler menerima notifikasi pesanan masuk.',
              ikon: Icons.lock_rounded,
              sudahLewat: tahap >= 1,
              sedangAktif: tahap == 1,
              aksiTambahan: tahap == 1
                  ? (adalahSisiTraveler
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _travelerAccPesanan,
                          icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                          label: const Text('Traveler: ACC & Terima Pesanan Jastip', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: const Text(
                            'Menunggu Traveler di luar negeri meng-ACC pesanan Anda...',
                            style: TextStyle(fontSize: 10.5, color: Colors.black87, fontStyle: FontStyle.italic),
                          ),
                        ))
                  : null,
            ),

            // STEP 2: Pesanan Di-ACC oleh Traveler
            _bangunItemTimeline(
              nomor: 2,
              judul: '2. Pesanan Di-ACC oleh Traveler',
              deskripsi: tahap >= 2
                  ? 'Traveler telah menyetujui pesanan Anda dan sedang menuju toko fisik di ${pesanan.negaraAsal}.'
                  : 'Pesanan belum di-ACC oleh traveler.',
              ikon: Icons.verified_user_rounded,
              sudahLewat: tahap >= 2,
              sedangAktif: tahap == 2,
              aksiTambahan: tahap == 2
                  ? (adalahSisiTraveler
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _travelerKonfirmasiSudahBeli,
                          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                          label: const Text('Traveler: Klik "Sudah Dibeli di Toko"', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: const Text(
                            'Notifikasi diterima! Traveler sedang belanja di toko luar negeri.',
                            style: TextStyle(fontSize: 10.5, color: Colors.black87),
                          ),
                        ))
                  : null,
            ),

            // STEP 3: Barang Sudah Dibeli di Toko
            _bangunItemTimeline(
              nomor: 3,
              judul: '3. Barang Sudah Dibeli di Toko Resmi Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Semua ${pesanan.daftarBarang.length} barang telah dibeli. Struk fisik dicatat ke SHA-256 Blockchain JastipGo.'
                  : 'Menunggu konfirmasi pembelian barang dari traveler.',
              ikon: Icons.storefront_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 3,
              aksiTambahan: tahap == 3
                  ? (adalahSisiTraveler
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo.shade800,
                            side: BorderSide(color: Colors.indigo.shade400),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _travelerMulaiPenerbangan,
                          icon: const Icon(Icons.flight_takeoff, size: 16),
                          label: const Text('Traveler: Bawa Masuk Bagasi Pesawat ke RI', style: TextStyle(fontSize: 11)),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HalamanSertifikatBlockchain()),
                            );
                          },
                          icon: const Icon(Icons.verified, size: 14),
                          label: const Text('Lihat Bukti Struk di Blockchain', style: TextStyle(fontSize: 10.5)),
                        ))
                  : null,
            ),

            // STEP 4: Dalam Penerbangan ke Indonesia
            _bangunItemTimeline(
              nomor: 4,
              judul: '4. Dalam Penerbangan Menuju Indonesia',
              deskripsi: tahap >= 4
                  ? 'Koper titipan dibawa dalam bagasi pesawat internasional menuju bandara tujuan di Indonesia.'
                  : 'Menunggu jadwal kepulangan traveler ke Indonesia.',
              ikon: Icons.airplanemode_active_rounded,
              sudahLewat: tahap >= 4,
              sedangAktif: tahap == 4,
              aksiTambahan: tahap == 4
                  ? (adalahSisiTraveler
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade900,
                            side: BorderSide(color: Colors.orange.shade400),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _travelerTibaDiIndonesia,
                          icon: const Icon(Icons.flight_land, size: 16),
                          label: const Text('Traveler: Konfirmasi Mendarat di Indonesia', style: TextStyle(fontSize: 11)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            'Pesawat sedang mengudara menuju Indonesia.',
                            style: TextStyle(fontSize: 10.5, color: Colors.black87),
                          ),
                        ))
                  : null,
            ),

            // STEP 5: Tiba di Indonesia & Opsi Pengantaran
            _bangunItemTimeline(
              nomor: 5,
              judul: '5. Mendarat di Indonesia & Pelaksanaan Serah Terima',
              deskripsi: tahap >= 5
                  ? 'Barang titipan telah mendarat di bandara Indonesia. Proses serah terima dilakukan sesuai pilihan Pemesan saat checkout.'
                  : 'Menunggu pesawat mendarat di bandara Indonesia.',
              ikon: Icons.luggage_rounded,
              sudahLewat: tahap >= 5,
              sedangAktif: tahap == 5,
              aksiTambahan: tahap == 5
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pesanan.metodePenyerahan == 'COD_LBS' ? Icons.location_on : Icons.local_shipping,
                                color: Colors.teal.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  adalahSisiTraveler
                                      ? 'Instruksi Serah Terima dari Pemesan:'
                                      : 'Metode Serah Terima Pilihan Anda (Saat Checkout):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (pesanan.metodePenyerahan == 'COD_LBS') ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📍 Titik Temu COD (LBS Google Maps)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    adalahSisiTraveler
                                        ? 'Pemesan memilih COD langsung. Silakan menuju ke Hub Titik Temu JastipGo (Kampus UPN Condongcatur / Bandara YIA).'
                                        : 'Anda memilih untuk mengambil sendiri barang titipan di Hub Titik Temu JastipGo.',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                                      );
                                    },
                                    icon: const Icon(Icons.navigation_rounded, size: 14),
                                    label: const Text('Buka Rute & Lokasi Titik Temu (Google Maps)', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🚚 Pengiriman Kurir Ekspedisi ke Rumah',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Alamat Tujuan Pemesan:\n${pesanan.alamatPengiriman.isNotEmpty ? pesanan.alamatPengiriman : "Jl. Babarsari No. 12, Caturtunggal, Sleman, D.I. Yogyakarta"}',
                                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    adalahSisiTraveler
                                        ? 'Traveler wajib mengirim paket ke alamat di atas melalui JNE / SiCepat.'
                                        : 'Traveler sedang memproses paket untuk dikirim ke alamat rumah Anda.',
                                    style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : null,
            ),

            // STEP 6: Selesai & Pencairan Dana Rekber
            _bangunItemTimeline(
              nomor: 6,
              judul: '6. Konfirmasi Barang Sesuai & Pencairan Dana',
              deskripsi: tahap == 6
                  ? 'Transaksi Selesai 100%! Semua barang telah diterima pemesan dan dana resmi ditransfer ke dompet traveler.'
                  : 'Pemesan memeriksa fisik barang. Jika sesuai, pemesan menekan tombol konfirmasi atau menunggu garansi 5 hari.',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: tahap == 6,
              sedangAktif: tahap == 6,
              garisTerakhir: true,
            ),
            const SizedBox(height: 18),

            // KOTAK KONFIRMASI TERIMA BARANG (HANYA UNTUK SISI PEMESAN)
            if (tahap == 5) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Masa Tunggu Konfirmasi: 5 Hari',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      adalahSisiTraveler
                          ? 'Menunggu pemesan menerima barang dan mengonfirmasi kesesuaian. Jika dalam 5 hari tidak ada klaim, uang otomatis cair ke dompet Anda.'
                          : 'Sesuai ketentuan, jika barang sudah diterima dan tidak ada komplain dalam 5 hari, sistem secara otomatis menyelesaikan pesanan dan mencairkan uang ke traveler.',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    if (!adalahSisiTraveler) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _pemesanKonfirmasiDiterima(karenaBatasWaktu5Hari: false),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('PEMESAN: BARANG SUDAH DITERIMA & SESUAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => _pemesanKonfirmasiDiterima(karenaBatasWaktu5Hari: true),
                        icon: const Icon(Icons.fast_forward_rounded, size: 15, color: Colors.black54),
                        label: const Text('Simulasi: Auto-Selesai (Batas 5 Hari Terlewati)', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (tahap == 6) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade800, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaksi Pesanan Selesai!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uang Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah resmi diteruskan dari Rekber ke traveler ${pesanan.namaTraveler}.',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper Widget Timeline
  Widget _bangunItemTimeline({
    required int nomor,
    required String judul,
    required String deskripsi,
    required IconData ikon,
    required bool sudahLewat,
    required bool sedangAktif,
    bool garisTerakhir = false,
    Widget? aksiTambahan,
  }) {
    final Color warnaIndikator = sudahLewat ? Colors.teal.shade700 : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sudahLewat ? Colors.teal.shade700 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIndikator, width: 2),
                boxShadow: sedangAktif
                    ? [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                ikon,
                size: 18,
                color: sudahLewat ? Colors.white : Colors.grey.shade400,
              ),
            ),
            if (!garisTerakhir)
              Container(
                width: 2,
                height: aksiTambahan != null ? 100 : 64,
                color: sudahLewat ? Colors.teal.shade600 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: sedangAktif ? Colors.teal.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deskripsi,
                style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
              ),
              if (aksiTambahan != null) ...[
                const SizedBox(height: 8),
                aksiTambahan,
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
