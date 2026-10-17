import 'package:flutter/material.dart';
import '../layanan/layanan_notifikasi.dart';
import 'halaman_peta_lokasi.dart';
import 'halaman_sertifikat_blockchain.dart';

// Halaman Alur Pesanan & Rekber Escrow JastipGo
// Mengimplementasikan siklus perlindungan dana, konfirmasi pembelian di luar negeri,
// pilihan penjemputan LBS vs antar ekspedisi, serta auto-complete 5 hari.
class HalamanStatusPesanan extends StatefulWidget {
  final String idPesanan;
  final String namaBarang;
  final String negaraAsal;
  final int totalHargaIdr;

  const HalamanStatusPesanan({
    super.key,
    this.idPesanan = 'PO-JSTP-882194',
    this.namaBarang = 'Tokyo Banana Tokyo Station Edition (Isi 8)',
    this.negaraAsal = 'Jepang 🇯🇵',
    this.totalHargaIdr = 285000,
  });

  @override
  State<HalamanStatusPesanan> createState() => _HalamanStatusPesananState();
}

class _HalamanStatusPesananState extends State<HalamanStatusPesanan> {
  // Tahap status pesanan:
  // 1: Dana Ditahan Rekber (Menunggu Traveler Membeli di Luar Negeri)
  // 2: Traveler Konfirmasi "Sudah Dibeli" di Toko Asli Luar Negeri
  // 3: Dalam Penerbangan Internasional Menuju Indonesia
  // 4: Tiba di Indonesia (Pilihan: Dijemput COD via LBS atau Diantar Ekspedisi)
  // 5: Barang Diterima Pemesan & Dana Dilepas ke Traveler (Selesai)
  int _tahapAktif = 1;

  // Pilihan metode penyerahan barang saat di Indonesia
  String _metodePenyerahan = 'COD_LBS'; // 'COD_LBS' atau 'KURIR_ANTAR'

  // Fungsi simulasi traveler menekan tombol "Sudah Dibeli" di luar negeri
  void _travelerKonfirmasiBeli() {
    setState(() => _tahapAktif = 2);

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Barang Anda Sudah Dibeli! 🛍️',
      pesan: 'Traveler telah membeli "${widget.namaBarang}" di ${widget.negaraAsal}. Struk belanja resmi telah dicatat ke Blockchain.',
      ikon: Icons.shopping_bag_rounded,
      warna: Colors.teal.shade800,
    );
  }

  // Fungsi simulasi barang naik ke pesawat
  void _simulasiPenerbangan() {
    setState(() => _tahapAktif = 3);

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Penerbangan Menuju Indonesia ✈️',
      pesan: 'Koper titipan sedang dalam penerbangan internasional menuju Bandara Indonesia.',
      ikon: Icons.flight_takeoff_rounded,
      warna: Colors.blue.shade800,
    );
  }

  // Fungsi simulasi barang mendarat di Indonesia
  void _simulasiTibaDiIndonesia() {
    setState(() => _tahapAktif = 4);

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Barang Sudah Mendarat di Indonesia! 🇮🇩',
      pesan: 'Silakan tentukan apakah ingin dijemput langsung (COD via LBS GPS) atau diantar kurir ke rumah.',
      ikon: Icons.place_rounded,
      warna: Colors.orange.shade800,
    );
  }

  // Fungsi pemesan menekan tombol "Barang Sudah Diterima & Sesuai"
  void _pemesanKonfirmasiDiterima({bool karenaBatasWaktu5Hari = false}) {
    setState(() => _tahapAktif = 5);

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: karenaBatasWaktu5Hari
          ? 'Pesanan Selesai Otomatis (Batas 5 Hari)'
          : 'Barang Berhasil Diterima! 🎉',
      pesan: 'Uang titipan sebesar Rp ${widget.totalHargaIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} resmi dilepas dari Rekber sistem ke traveler.',
      ikon: Icons.verified_rounded,
      warna: Colors.green.shade800,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Status Pesanan & Rekber'),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kartu Ringkasan Pesanan & Proteksi Rekber (Escrow)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.idPesanan,
                          style: TextStyle(
                            color: Colors.teal.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _tahapAktif == 5 ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tahapAktif == 5 ? Colors.green.shade300 : Colors.amber.shade400,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _tahapAktif == 5 ? Icons.check_circle : Icons.shield_rounded,
                              size: 14,
                              color: _tahapAktif == 5 ? Colors.green.shade800 : Colors.amber.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _tahapAktif == 5 ? 'DANA CAIR KE TRAVELER' : 'REKBER ESCROW AKTIF',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _tahapAktif == 5 ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.namaBarang,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asal: ${widget.negaraAsal}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const Divider(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran Ditahan:', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text(
                        'Rp ${widget.totalHargaIdr.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: TextStyle(
                          color: Colors.teal.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Penjelasan Garansi Sistem untuk Dosen
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_clock_rounded, color: Colors.blue.shade800, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sistem Rekening Bersama (Escrow):\nUang pembeli aman ditahan oleh sistem JastipGo. Traveler TIDAK BISA membawa kabur uang karena dana baru dicairkan setelah pembeli konfirmasi barang diterima atau setelah garansi 5 hari.',
                      style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Timeline Pelacakan Alur Pesanan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 14),

            // Item Timeline 1: Pembayaran & Dana Ditahan
            _bangunItemTimeline(
              nomor: 1,
              judul: 'Pembayaran Diverifikasi & Dana Ditahan Sistem',
              deskripsi: 'Uang pembeli berhasil didebit dan disimpan aman di rekening bersama (Escrow). Traveler mendapat notifikasi untuk membeli barang.',
              ikon: Icons.verified_user_rounded,
              sudahLewat: _tahapAktif >= 1,
              sedangAktif: _tahapAktif == 1,
            ),

            // Item Timeline 2: Traveler Membeli Barang di Luar Negeri
            _bangunItemTimeline(
              nomor: 2,
              judul: 'Traveler Membeli Barang di Luar Negeri',
              deskripsi: _tahapAktif >= 2
                  ? 'Traveler telah membeli barang di toko resmi luar negeri. Sertifikat struk asli dicatat di Blockchain.'
                  : 'Traveler sedang menuju pusat perbelanjaan di luar negeri.',
              ikon: Icons.storefront_rounded,
              sudahLewat: _tahapAktif >= 2,
              sedangAktif: _tahapAktif == 2,
              aksiTambahan: _tahapAktif == 1
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _travelerKonfirmasiBeli,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Simulasi: Traveler Klik "Sudah Dibeli"', style: TextStyle(fontSize: 11)),
                    )
                  : null,
            ),

            // Item Timeline 3: Penerbangan Internasional Menuju Indonesia
            _bangunItemTimeline(
              nomor: 3,
              judul: 'Dalam Penerbangan Menuju Indonesia',
              deskripsi: _tahapAktif >= 3
                  ? 'Koper titipan dibawa dalam bagasi pesawat internasional menuju bandara tujuan di Indonesia.'
                  : 'Menunggu jadwal penerbangan pulang traveler ke Indonesia.',
              ikon: Icons.flight_takeoff_rounded,
              sudahLewat: _tahapAktif >= 3,
              sedangAktif: _tahapAktif == 3,
              aksiTambahan: _tahapAktif == 2
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        side: BorderSide(color: Colors.blue.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _simulasiPenerbangan,
                      icon: const Icon(Icons.airplanemode_active, size: 16),
                      label: const Text('Simulasi: Barang Naik Pesawat', style: TextStyle(fontSize: 11)),
                    )
                  : null,
            ),

            // Item Timeline 4: Mendarat di Indonesia & Opsi Penyerahan
            _bangunItemTimeline(
              nomor: 4,
              judul: 'Tiba di Indonesia & Pilihan Penyerahan',
              deskripsi: _tahapAktif >= 4
                  ? 'Barang lolos bea cukai bandara. Pilih metode serah terima barang di bawah ini:'
                  : 'Menunggu konfirmasi kedatangan di terminal kedatangan internasional.',
              ikon: Icons.luggage_rounded,
              sudahLewat: _tahapAktif >= 4,
              sedangAktif: _tahapAktif == 4,
              aksiTambahan: _tahapAktif == 3
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _simulasiTibaDiIndonesia,
                      icon: const Icon(Icons.flight_land, size: 16),
                      label: const Text('Simulasi: Mendarat di Indonesia', style: TextStyle(fontSize: 11)),
                    )
                  : _tahapAktif == 4
                      ? Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Cara Pengambilan Barang:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              RadioListTile<String>(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.teal.shade700,
                                value: 'COD_LBS',
                                groupValue: _metodePenyerahan,
                                title: const Text('📍 Ambil Sendiri / COD (Gunakan LBS GPS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Ambil di Hub Kampus UPN Veteran Jogja atau Bandara YIA', style: TextStyle(fontSize: 10.5)),
                                onChanged: (val) => setState(() => _metodePenyerahan = val!),
                              ),
                              if (_metodePenyerahan == 'COD_LBS') ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 36, bottom: 8),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HalamanPetaLokasi()),
                                      );
                                    },
                                    icon: const Icon(Icons.my_location, size: 14),
                                    label: const Text('Lihat Pos Terdekat & Hitung Jarak (LBS)', style: TextStyle(fontSize: 10.5)),
                                  ),
                                ),
                              ],
                              RadioListTile<String>(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.teal.shade700,
                                value: 'KURIR_ANTAR',
                                groupValue: _metodePenyerahan,
                                title: const Text('🚚 Diantar Kurir Ekspedisi ke Rumah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Traveler mengirimkan lewat JNE / SiCepat ke alamat pemesan', style: TextStyle(fontSize: 10.5)),
                                onChanged: (val) => setState(() => _metodePenyerahan = val!),
                              ),
                            ],
                          ),
                        )
                      : null,
            ),

            // Item Timeline 5: Barang Diterima & Pelepasan Dana
            _bangunItemTimeline(
              nomor: 5,
              judul: 'Konfirmasi Barang Sesuai & Pencairan Dana',
              deskripsi: _tahapAktif == 5
                  ? 'Transaksi Selesai 100%! Barang telah diterima pemesan dengan kondisi baik dan uang ditransfer ke traveler.'
                  : 'Pemesan memeriksa barang. Jika sesuai, pembeli mengonfirmasi atau menunggu auto-complete 5 hari.',
              ikon: Icons.monetization_on_rounded,
              sudahLewat: _tahapAktif == 5,
              sedangAktif: _tahapAktif == 5,
              garisTerakhir: true,
            ),
            const SizedBox(height: 20),

            // Tombol Konfirmasi Selesai & Auto-Complete 5 Hari
            if (_tahapAktif == 4) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Masa Garansi Konfirmasi: 5 Hari',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jika barang sudah sampai dan tidak ada komplain dalam 5 hari, sistem secara otomatis menyelesaikan pesanan dan mencairkan uang ke traveler.',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _pemesanKonfirmasiDiterima(karenaBatasWaktu5Hari: false),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('BARANG SUDAH DITERIMA & SESUAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _pemesanKonfirmasiDiterima(karenaBatasWaktu5Hari: true),
                      icon: const Icon(Icons.fast_forward_rounded, size: 16, color: Colors.black54),
                      label: const Text('Simulasi: Auto-Selesai (Batas 5 Hari Terlampaui)', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ] else if (_tahapAktif == 5) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade800, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaksi Berhasil Selesai!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Dana telah diteruskan ke traveler dan sertifikat struk belanja Blockchain tetap tersimpan abadi sebagai bukti.',
                            style: TextStyle(fontSize: 11.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
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
              width: 38,
              height: 38,
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
                size: 20,
                color: sudahLewat ? Colors.white : Colors.grey.shade400,
              ),
            ),
            if (!garisTerakhir)
              Container(
                width: 2,
                height: aksiTambahan != null ? 110 : 70,
                color: sudahLewat ? Colors.teal.shade600 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: sedangAktif ? Colors.teal.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deskripsi,
                style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.3),
              ),
              if (aksiTambahan != null) ...[
                const SizedBox(height: 8),
                aksiTambahan,
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
