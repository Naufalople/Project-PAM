import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../model/model_pesanan_jastip.dart';
import 'halaman_chat_traveler.dart';
import 'halaman_kelola_pesanan_traveler.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_sertifikat_blockchain.dart';

// Halaman Khusus Status & Pelacakan Pesanan untuk Pemesan
// Fitur Khusus Sisi Pemesan:
// 1. Menampilkan daftar pesanan aktif yang benar-benar dibuat pengguna
// 2. Memantau rincian barang dan lokasi fisik terkini barang titipan
// 3. Memantau progres pembelian oleh traveler di luar negeri
// 4. Memilih metode penyerahan saat checkout (COD LBS Google Maps / Kurir)
// 5. Mengonfirmasi barang diterima & sesuai untuk mencairkan dana Rekber Escrow
// 6. Chat langsung dua arah dengan Traveler (Bukan Chat Bot)
class HalamanStatusPesanan extends StatefulWidget {
  final String? idPesananTerpilih;

  // Parameter kompatibilitas navigasi sebelumnya
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
  bool _sedangMemuat = true;
  String _peranAktif = 'PEMESAN';

  @override
  void initState() {
    super.initState();
    _muatDaftarPesanan();
  }

  Future<void> _muatDaftarPesanan() async {
    final list = LayananBasisDataLokal.ambilSemuaPesanan();
    final peran = await LayananOtentikasi.ambilPeranAktif();
    if (!mounted) return;
    setState(() {
      _peranAktif = peran;
      _daftarPesanan = list;
      _sedangMemuat = false;

      if (list.isNotEmpty) {
        final targetId = widget.idPesananTerpilih ?? widget.idPesanan;
        if (targetId != null && targetId.isNotEmpty) {
          _pesananAktif = list.firstWhere(
            (p) => p.idPesanan == targetId,
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

  // Pemesan Konfirmasi Barang Diterima & Sesuai
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

    final String formatUang = _formatRupiah(pesanan.totalHargaIdr);

    if (!mounted) return;
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: karenaBatasWaktu5Hari
          ? 'Pesanan #${pesanan.idPesanan} Selesai Otomatis (5 Hari)'
          : 'Barang Berhasil Diterima Pemesan! 🎉',
      pesan: 'Dana Rp $formatUang resmi dicairkan dari Rekber Escrow sistem ke dompet traveler ${pesanan.namaTraveler}.',
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
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Pesanan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Proteksi RBAC: Traveler tidak dapat mengakses pelacakan pesanan (Poin 2)
    if (_peranAktif == 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Status & Pelacakan Pesanan'),
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
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, size: 64, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akses Khusus Pemesan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Halaman Status & Pelacakan Pesanan hanya diperuntukkan bagi akun Pemesan (Requester) untuk memantau barang titipan mereka.\n\nSebagai Traveler, tugas Anda adalah memantau dan memperbarui pesanan masuk dari pemesan melalui menu "Kelola Pesanan Masuk".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HalamanKelolaPesananTraveler(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  label: const Text('Buka Kelola Pesanan Masuk'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Menu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tampilan Bersih jika Pengguna Belum Memesan Barang Apapun
    if (_daftarPesanan.isEmpty || _pesananAktif == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Status & Pelacakan Pesanan'),
          backgroundColor: Colors.teal.shade800,
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
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_outlined, size: 64, color: Colors.teal.shade700),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum Ada Pesanan Aktif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda belum memiliki pesanan jastip aktif. Silakan cari barang impian dari toko luar negeri di Beranda, masukkan ke keranjang, dan lakukan pemesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Jelajahi Produk di Beranda'),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.forum_rounded),
        label: const Text('Chat Traveler (Dimas Pratama)'),
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
            // DAFTAR PILIHAN PESANAN SAYA
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

            // KARTU LOKASI FISIK BARANG LIVE
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
                  if (tahap >= 5 && pesanan.metodePenyerahan == 'COD_LBS') ...[
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
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 52,
                                height: 52,
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
                                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran Titipan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TIMELINE STATUS PESANAN (PERSPEKTIF PEMESAN)
            const Text(
              'Timeline Perjalanan Barang Titipan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // STEP 1: Pesanan Dibuat
            _bangunItemTimeline(
              nomor: 1,
              judul: '1. Pesanan Dibuat & Menunggu ACC Traveler',
              deskripsi: tahap >= 2
                  ? 'Traveler ${pesanan.namaTraveler} telah menyetujui pesanan Anda.'
                  : 'Pesanan telah terkirim. Menunggu persetujuan (ACC) dari traveler ${pesanan.namaTraveler} di ${pesanan.negaraAsal}.',
              ikon: Icons.assignment_turned_in_rounded,
              sudahLewat: tahap >= 2,
              sedangAktif: tahap == 1,
            ),

            // STEP 2: Traveler Bergerak ke Toko
            _bangunItemTimeline(
              nomor: 2,
              judul: '2. Traveler Bersiap ke Toko Resmi di Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Traveler telah tiba di toko dan menyelesaikan pembelian barang titipan Anda.'
                  : (tahap == 2
                      ? 'Traveler ${pesanan.namaTraveler} sedang dalam perjalanan menuju toko resmi di ${pesanan.negaraAsal}.'
                      : 'Menunggu jadwal belanja traveler.'),
              ikon: Icons.directions_walk_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 2,
            ),

            // STEP 3: Barang Sudah Dibeli di Toko
            _bangunItemTimeline(
              nomor: 3,
              judul: '3. Barang Sudah Dibeli di Toko Resmi Luar Negeri',
              deskripsi: tahap >= 3
                  ? 'Semua ${pesanan.daftarBarang.length} barang telah dibeli oleh traveler. Struk belanja fisik dicatat ke SHA-256 Blockchain JastipGo.'
                  : 'Menunggu konfirmasi pembelian barang dari traveler.',
              ikon: Icons.storefront_rounded,
              sudahLewat: tahap >= 3,
              sedangAktif: tahap == 3,
              aksiTambahan: tahap >= 3
                  ? ElevatedButton.icon(
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
                    )
                  : null,
            ),

            // STEP 4: Dalam Penerbangan ke Indonesia
            _bangunItemTimeline(
              nomor: 4,
              judul: '4. Dalam Penerbangan Menuju Indonesia',
              deskripsi: tahap >= 4
                  ? 'Koper titipan dibawa dalam bagasi pesawat internasional menuju bandara tujuan di Indonesia.'
                  : 'Menunggu jadwal penerbangan pulang traveler ke Indonesia.',
              ikon: Icons.airplanemode_active_rounded,
              sudahLewat: tahap >= 4,
              sedangAktif: tahap == 4,
            ),

            // STEP 5: Tiba di Indonesia & Serah Terima
            _bangunItemTimeline(
              nomor: 5,
              judul: '5. Mendarat di Indonesia & Pelaksanaan Serah Terima',
              deskripsi: tahap >= 5
                  ? 'Barang titipan telah mendarat di bandara Indonesia. Proses serah terima dilakukan sesuai pilihan Anda saat checkout.'
                  : 'Menunggu pesawat mendarat di bandara Indonesia.',
              ikon: Icons.luggage_rounded,
              sudahLewat: tahap >= 5,
              sedangAktif: tahap == 5,
              aksiTambahan: tahap == 5
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                                  'Metode Serah Terima Pilihan Anda (Saat Checkout):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                                  const Text(
                                    'Anda memilih untuk mengambil sendiri barang titipan di Hub Titik Temu JastipGo (Kampus UPN Condongcatur / Bandara).',
                                    style: TextStyle(fontSize: 11, color: Colors.black54),
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
                                    label: const Text('Buka Rute & Lokasi Titik Temu (LBS Maps)', style: TextStyle(fontSize: 11)),
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
                                    'Alamat Pengiriman:\n${pesanan.alamatPengiriman.isNotEmpty ? pesanan.alamatPengiriman : "Jl. Babarsari No. 12, Caturtunggal, Sleman, D.I. Yogyakarta"}',
                                    style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Traveler sedang memproses paket untuk dikirimkan melalui kurir.',
                                    style: TextStyle(fontSize: 10.5, color: Colors.black54),
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
                  ? 'Transaksi Selesai 100%! Semua barang telah Anda terima dan dana resmi ditransfer ke dompet traveler.'
                  : 'Periksa fisik barang titipan. Jika sesuai, tekan tombol konfirmasi di bawah atau tunggu auto-selesai garansi 5 hari.',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: tahap == 6,
              sedangAktif: tahap == 6,
              garisTerakhir: true,
            ),
            const SizedBox(height: 18),

            // KOTAK KONFIRMASI TERIMA BARANG PEMESAN
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
                    const Text(
                      'Sesuai ketentuan Rekber Escrow, jika barang sudah diterima dan tidak ada komplain dalam 5 hari, sistem secara otomatis menyelesaikan pesanan dan mencairkan uang ke traveler.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
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
                        label: const Text('BARANG SUDAH DITERIMA & SESUAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => _pemesanKonfirmasiDiterima(karenaBatasWaktu5Hari: true),
                      icon: const Icon(Icons.fast_forward_rounded, size: 15, color: Colors.black54),
                      label: const Text('Simulasi: Auto-Selesai (Batas 5 Hari Terlewati)', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                    ),
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
                            'Uang Rp ${_formatRupiah(pesanan.totalHargaIdr)} telah resmi dicairkan ke dompet traveler ${pesanan.namaTraveler}.',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                height: aksiTambahan != null ? 84 : 54,
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
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
