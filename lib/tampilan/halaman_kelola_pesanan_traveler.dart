import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../model/model_pesanan_jastip.dart';
import 'halaman_chat_traveler.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_sertifikat_blockchain.dart';

// Halaman Khusus Pengelolaan Pesanan Titipan oleh Pembeli / Traveler di Luar Negeri (Dimas Pratama)
// Fitur Khusus Sisi Traveler:
// 1. Menerima pesanan masuk dari Pemesan dan meng-ACC
// 2. Mengonfirmasi barang sudah dibeli di toko resmi LN & mencatat struk ke Blockchain
// 3. Membawa koper titipan masuk bagasi penerbangan ke Indonesia
// 4. Mengonfirmasi tiba di Indonesia & menyesuaikan metode serah terima pilihan Pemesan (COD LBS / Kurir)
// 5. Chat langsung dua arah dengan Pemesan (Bukan Chat Bot)
class HalamanKelolaPesananTraveler extends StatefulWidget {
  final String? idPesananTerpilih;

  const HalamanKelolaPesananTraveler({
    super.key,
    this.idPesananTerpilih,
  });

  @override
  State<HalamanKelolaPesananTraveler> createState() => _HalamanKelolaPesananTravelerState();
}

class _HalamanKelolaPesananTravelerState extends State<HalamanKelolaPesananTraveler> {
  List<ModelPesananJastip> _daftarPesanan = [];
  ModelPesananJastip? _pesananAktif;
  bool _sedangMemuat = true;
  String _peranAktif = 'TRAVELER';

  @override
  void initState() {
    super.initState();
    _muatDaftarPesanan();
  }

  Future<void> _muatDaftarPesanan() async {
    final peran = await LayananOtentikasi.ambilPeranAktif();
    final list = LayananBasisDataLokal.ambilSemuaPesanan();
    if (!mounted) return;
    setState(() {
      _peranAktif = peran;
      _daftarPesanan = list;
      _sedangMemuat = false;

      if (list.isNotEmpty) {
        if (widget.idPesananTerpilih != null) {
          _pesananAktif = list.firstWhere(
            (p) => p.idPesanan == widget.idPesananTerpilih,
            orElse: () => list.first,
          );
        } else {
          _pesananAktif = list.first;
        }
      } else {
        _pesananAktif = null;
      }
    });
  }

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
      judul: 'Pesanan #${pesanan.idPesanan} Berhasil Di-ACC! ✅',
      pesan: 'Status pesanan diperbarui. Notifikasi telah dikirim ke pemesan bahwa Anda menyetujui pesanan ini.',
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
      judul: 'Barang Berhasil Dibeli di Toko! 🛍️',
      pesan: 'Semua ${pesanan.daftarBarang.length} item telah dibeli. Struk pembelian tercatat ke Blockchain.',
      ikon: Icons.shopping_bag_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // 3. Traveler Bawa Barang Masuk Bagasi Pesawat ke RI
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
      pesan: 'Koper titipan dibawa dalam bagasi penerbangan internasional menuju Indonesia.',
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
      judul: 'Sudah Mendarat di Indonesia! 🇮🇩',
      pesan: 'Barang titipan siap diserahterimakan sesuai metode pilihan Pemesan.',
      ikon: Icons.place_rounded,
      warna: Colors.orange.shade800,
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
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Pesanan Traveler')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Proteksi RBAC: Halaman ini HANYA bisa diakses oleh peran TRAVELER (Poin 1)
    if (_peranAktif != 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Kelola Pesanan Masuk'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red.shade700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akses Dibatasi: Khusus Peran Traveler',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Akun Anda saat ini masuk sebagai Pemesan. Halaman Kelola Pesanan hanya dapat diakses oleh akun Traveler/Jastiper untuk menerima titipan, mengonfirmasi belanja di luar negeri, dan mengatur serah terima barang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('KEMBALI KE BERANDA'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_daftarPesanan.isEmpty || _pesananAktif == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Kelola Pesanan (Traveler)'),
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inbox_outlined, size: 64, color: Colors.indigo.shade600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Pesanan Masuk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada pemesan yang melakukan checkout barang titipan jastip. Begitu pemesan memesan barang, pesanan akan otomatis muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HalamanChatTraveler()),
                    );
                  },
                  icon: const Icon(Icons.forum_rounded, size: 18),
                  label: const Text('Buka Ruang Chat Diskusi Pemesan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pesanan = _pesananAktif!;
    final int tahap = pesanan.tahapStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Kelola Pesanan (Khusus Traveler)'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sertifikat Struk Blockchain',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_rounded),
        label: const Text('Chat Pemesan (Manusia Asli)'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HalamanChatTraveler(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Peran
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff, color: Colors.indigo.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudut Pandang: Traveler (Dimas Pratama)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo.shade900),
                        ),
                        const Text(
                          'Anda bertindak sebagai pembeli di LN. Konfirmasikan progres pembelian & kepulangan Anda di bawah.',
                          style: TextStyle(fontSize: 10.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Pilihan Pesanan Masuk (Jika lebih dari 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pesanan Titipan Masuk:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                Text(
                  '${_daftarPesanan.length} Pesanan Masuk',
                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade800, fontWeight: FontWeight.bold),
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
                        color: terpilih ? Colors.indigo.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: terpilih ? Colors.indigo.shade800 : Colors.grey.shade300,
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
                                  color: terpilih ? Colors.indigo.shade700 : Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${p.daftarBarang.length} Item',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: terpilih ? Colors.white : Colors.indigo.shade900,
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
                              color: terpilih ? Colors.amber.shade300 : Colors.indigo.shade900,
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

            // Status Lokasi & Alur Titipan
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade800, Colors.indigo.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.2),
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
                    'Asal Belanja: ${pesanan.negaraAsal} • Kode Order: ${pesanan.idPesanan}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Daftar Rincian Barang yang Harus Dibeli
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
                        'Barang yang Harus Anda Beli (${pesanan.daftarBarang.length} Produk):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                          tahap == 6 ? 'DANA SUDAH CAIR' : 'REKBER ESCROW AMAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tahap == 6 ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
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
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaBarang,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Toko: ${item.namaToko} (${item.negara})',
                                  style: TextStyle(fontSize: 11, color: Colors.indigo.shade800),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Jumlah: ${item.jumlah} pcs', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                    Text('Rp ${_formatRupiah(item.hargaIdr)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran Pemesan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      Text(
                        'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.indigo.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TIMELINE TINDAKAN TRAVELER
            const Text(
              'Timeline Konfirmasi Traveler:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // STEP 1: Pesanan Masuk & Menunggu ACC
            _bangunItemTimeline(
              nomor: 1,
              judul: '1. Pesanan Dibuat & Menunggu ACC Traveler',
              deskripsi: tahap >= 2
                  ? 'Anda telah menyetujui pesanan ini.'
                  : 'Pesanan baru masuk dari Pemesan. Silakan tinjau barang titipan di atas dan setujui pesanan.',
              ikon: Icons.assignment_turned_in_rounded,
              sudahLewat: tahap >= 2,
              sedangAktif: tahap == 1,
              aksiTambahan: tahap == 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerAccPesanan,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('ACC / SETUJUI PESANAN INI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )
                  : null,
            ),

            // STEP 2: Menuju Toko & Belanja
            _bangunItemTimeline(
              nomor: 2,
              judul: '2. Bergerak ke Toko Resmi di Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Semua barang titipan telah berhasil Anda beli di toko resmi.'
                  : 'Anda sedang menuju toko resmi di ${pesanan.negaraAsal}. Setelah membeli barang, tekan tombol di bawah.',
              ikon: Icons.directions_walk_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 2,
              aksiTambahan: tahap == 2
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerKonfirmasiSudahBeli,
                        icon: const Icon(Icons.shopping_bag, size: 18),
                        label: const Text('KONFIRMASI SUDAH DIBELI DI TOKO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )
                  : null,
            ),

            // STEP 3: Catat Struk ke Blockchain & Masuk Koper
            _bangunItemTimeline(
              nomor: 3,
              judul: '3. Barang Sudah Dibeli di Toko Resmi',
              deskripsi: tahap >= 4
                  ? 'Struk belanja resmi telah tercatat di Blockchain dan barang siap dibawa pulang ke RI.'
                  : 'Barang sudah dibeli. Silakan konfirmasi untuk memasukkan barang ke bagasi penerbangan menuju Indonesia.',
              ikon: Icons.storefront_rounded,
              sudahLewat: tahap >= 4,
              sedangAktif: tahap == 3,
              aksiTambahan: tahap == 3
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerMulaiPenerbangan,
                        icon: const Icon(Icons.flight_takeoff, size: 18),
                        label: const Text('BAWA MASUK BAGASI PESAWAT KE RI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )
                  : null,
            ),

            // STEP 4: Dalam Penerbangan ke Indonesia
            _bangunItemTimeline(
              nomor: 4,
              judul: '4. Dalam Penerbangan Menuju Indonesia',
              deskripsi: tahap >= 5
                  ? 'Penerbangan telah selesai dan Anda telah mendarat di bandara Indonesia.'
                  : 'Koper titipan sedang dalam penerbangan. Begitu tiba di bandara Indonesia, tekan tombol mendarat.',
              ikon: Icons.airplanemode_active_rounded,
              sudahLewat: tahap >= 5,
              sedangAktif: tahap == 4,
              aksiTambahan: tahap == 4
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _travelerTibaDiIndonesia,
                        icon: const Icon(Icons.flight_land, size: 18),
                        label: const Text('KONFIRMASI MENDARAT DI INDONESIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )
                  : null,
            ),

            // STEP 5: Mendarat di Indonesia & Eksekusi Penyerahan (Sesuai Pilihan Pemesan)
            _bangunItemTimeline(
              nomor: 5,
              judul: '5. Mendarat di Indonesia & Pelaksanaan Serah Terima',
              deskripsi: tahap >= 6
                  ? 'Proses serah terima barang titipan telah selesai.'
                  : 'Pesawat telah mendarat di Indonesia. Lakukan serah terima barang sesuai metode yang telah dipilih Pemesan saat checkout.',
              ikon: Icons.luggage_rounded,
              sudahLewat: tahap >= 6,
              sedangAktif: tahap == 5,
              aksiTambahan: tahap == 5
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                pesanan.metodePenyerahan == 'COD_LBS' ? Icons.location_on : Icons.local_shipping,
                                color: Colors.indigo.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pilihan Serah Terima dari Pemesan: ${pesanan.metodePenyerahan == "COD_LBS" ? "COD Titik Temu (LBS)" : "Kirim Kurir"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (pesanan.metodePenyerahan == 'COD_LBS') ...[
                            const Text(
                              '📍 Pemesan memilih bertemu langsung (COD) di Hub JastipGo Kampus UPN Condongcatur / Bandara.',
                              style: TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade700,
                                foregroundColor: Colors.white,
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
                              label: const Text('Buka Titik Temu di LBS Peta', style: TextStyle(fontSize: 11)),
                            ),
                          ] else ...[
                            Text(
                              '🚚 Pemesan memilih pengiriman kurir ke alamat:\n${pesanan.alamatPengiriman.isNotEmpty ? pesanan.alamatPengiriman : "Jl. Babarsari No. 12, Sleman, Yogyakarta"}',
                              style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kirimkan paket melalui JNE/SiCepat lalu bagikan nomor resi ke Pemesan lewat chat.',
                              style: TextStyle(fontSize: 10.5, color: Colors.black54),
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
              judul: '6. Konfirmasi Terima & Pencairan Dana ke Dompet',
              deskripsi: tahap == 6
                  ? 'Transaksi Selesai 100%! Dana Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah resmi dicairkan ke saldo dompet Anda.'
                  : 'Menunggu Pemesan memeriksa fisik barang dan mengonfirmasi terima (atau auto-cair setelah 5 hari).',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: tahap == 6,
              sedangAktif: tahap == 6,
              garisTerakhir: true,
            ),
            const SizedBox(height: 80),
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
    final Color warnaIndikator = sudahLewat ? Colors.indigo.shade700 : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sudahLewat ? Colors.indigo.shade700 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: warnaIndikator, width: 2),
                boxShadow: sedangAktif
                    ? [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.3),
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
                height: aksiTambahan != null ? 84 : 54,
                color: sudahLewat ? Colors.indigo.shade600 : Colors.grey.shade300,
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
                  color: sedangAktif ? Colors.indigo.shade900 : Colors.black87,
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
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
