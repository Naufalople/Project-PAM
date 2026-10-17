import 'package:flutter/material.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_biometrik.dart';
import '../layanan/layanan_blockchain.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../widget/dialog_sukses.dart';
import '../widget/dialog_peringatan.dart';
import 'halaman_sertifikat_blockchain.dart';

// Halaman Pembayaran (Checkout) dengan Verifikasi Biometrik Sidik Jari & Pencatatan Blockchain
class HalamanCheckout extends StatefulWidget {
  final List<ModelKeranjang> daftarItem;

  const HalamanCheckout({super.key, required this.daftarItem});

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  String _metodePembayaran = 'QRIS'; // 'QRIS' atau 'Transfer Bank'
  String _bankPilihan = 'BCA';
  bool _sedangMemproses = false;

  int get _subtotal {
    int total = 0;
    for (var item in widget.daftarItem) {
      total += item.totalHargaIdr;
    }
    return total;
  }

  int get _biayaJasaTitip => (_subtotal * 0.05).round(); // Biaya jastip 5%
  int get _totalBayar => _subtotal + _biayaJasaTitip;

  // Proses Pembayaran dengan Sensor Biometrik Sidik Jari
  Future<void> _prosesKonfirmasiPembayaran() async {
    setState(() => _sedangMemproses = true);

    // 1. Minta Autentikasi Sensor Sidik Jari
    final bool sidikJariValid = await LayananBiometrik.autentikasiSidikJari(
      pesanAlasan: 'Tempelkan sidik jari untuk mengonfirmasi pembayaran titipan sebesar ${LayananKonversi.formatRupiah(_totalBayar)}',
    );

    if (!mounted) return;

    if (!sidikJariValid) {
      setState(() => _sedangMemproses = false);
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Otorisasi Gagal',
          deskripsi: 'Sidik jari tidak cocok. Pembayaran tidak dapat diproses demi keamanan akun Anda.',
        ),
      );
      return;
    }

    // 2. Ambil data profil pembeli
    final profil = await LayananOtentikasi.ambilProfilAktif();
    final String namaPembeli = profil?.nama ?? 'Budi Santoso';
    final String idPesanan = 'PO-JSTP-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final List<String> namaBarangList = widget.daftarItem.map((e) => '${e.namaBarang} (x${e.jumlah})').toList();
    final String negaraAsal = widget.daftarItem.isNotEmpty ? widget.daftarItem.first.negara : 'Global';

    // 3. Catat Transaksi ke Blockchain (Menghasilkan Blok Hash SHA-256)
    final ModelBlokTransaksi blokBaru = await LayananBlockchain.catatTransaksiBaru(
      idPesanan: idPesanan,
      namaPembeli: namaPembeli,
      totalHargaIdr: _totalBayar,
      daftarBarang: namaBarangList,
      negaraAsal: negaraAsal,
    );

    // 4. Kosongkan Keranjang Lokal Hive
    await LayananBasisDataLokal.kosongkanKeranjang();

    // 5. Picu Notifikasi Mobile
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pembayaran Jastip Berhasil! 🎉',
      pesan: 'Pesanan #$idPesanan telah terbit di Blockchain dengan Hash: ${blokBaru.hash.substring(0, 16)}...',
      ikon: Icons.verified_rounded,
      warna: Colors.green,
    );

    setState(() => _sedangMemproses = false);

    // 6. Tampilkan Dialog Sukses & Tawarkan Buka Sertifikat Blockchain
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogSukses(
        judul: 'Transaksi Berhasil & Terenkripsi!',
        deskripsi: 'Pembayaran Anda telah diverifikasi biometrik dan sertifikat struk resmi telah dicatat ke Blockchain.\n\nHash ID: ${blokBaru.hash.substring(0, 20)}...',
        saatKlikOke: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HalamanSertifikatBlockchain(),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Konfirmasi & Pembayaran'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rincian Barang yang Dititip
            const Text(
              'Rincian Barang Titipan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.daftarItem.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = widget.daftarItem[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.fotoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(
                      item.namaBarang,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${item.negara} • ${LayananKonversi.formatMataUangAsing(item.hargaAsli, item.kodeMataUang)} x ${item.jumlah}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    trailing: Text(
                      LayananKonversi.formatRupiah(item.totalHargaIdr),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Pilihan Metode Pembayaran
            const Text(
              'Metode Pembayaran (Simulasi):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _metodePembayaran = 'QRIS'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _metodePembayaran == 'QRIS' ? Colors.teal.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _metodePembayaran == 'QRIS' ? Colors.teal.shade700 : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.teal.shade700, size: 32),
                          const SizedBox(height: 6),
                          const Text('QRIS Nasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _metodePembayaran = 'Transfer Bank'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _metodePembayaran == 'Transfer Bank' ? Colors.teal.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _metodePembayaran == 'Transfer Bank' ? Colors.teal.shade700 : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance, color: Colors.teal.shade700, size: 32),
                          const SizedBox(height: 6),
                          const Text('Virtual Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilan Detail Pembayaran Sesuai Metode
            if (_metodePembayaran == 'QRIS') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Scan Kode QRIS Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text('NMID: ID102008691234 • JastipGo Merchant', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Rekening Bank Tujuan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _bankPilihan,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['BCA', 'Mandiri', 'BNI', 'BRI'].map((b) {
                        return DropdownMenuItem(value: b, child: Text('Bank $b Virtual Account'));
                      }).toList(),
                      onChanged: (val) => setState(() => _bankPilihan = val!),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nomor Rekening Virtual:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('8273 0812 3456 7890', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              LayananNotifikasi.kirimNotifikasi(
                                context,
                                judul: 'Nomor VA Disalin',
                                pesan: 'Nomor Virtual Account Bank $_bankPilihan berhasil disalin.',
                                ikon: Icons.copy,
                              );
                            },
                            child: const Text('SALIN'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Ringkasan Pembayaran
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Harga Barang:', style: TextStyle(color: Colors.black54)),
                      Text(LayananKonversi.formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biaya Penanganan Jastip (5%):', style: TextStyle(color: Colors.black54)),
                      Text(LayananKonversi.formatRupiah(_biayaJasaTitip), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan Akhir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        LayananKonversi.formatRupiah(_totalBayar),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Konfirmasi dengan Sensor Sidik Jari
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                onPressed: _sedangMemproses ? null : _prosesKonfirmasiPembayaran,
                icon: const Icon(Icons.fingerprint, size: 24),
                label: _sedangMemproses
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'BAYAR DENGAN SIDIK JARI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '🔒 Transaksi diamankan dengan Kriptografi Hash SHA-256 Blockchain',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
