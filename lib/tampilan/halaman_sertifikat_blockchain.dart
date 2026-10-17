import 'package:flutter/material.dart';
import '../model/model_blok_transaksi.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_blockchain.dart';
import '../layanan/layanan_konversi.dart';
import '../widget/dialog_sukses.dart';

// Halaman Blockchain: Buku Besar Digital & Sertifikat Struk Belanja Anti-Palsu
class HalamanSertifikatBlockchain extends StatefulWidget {
  const HalamanSertifikatBlockchain({super.key});

  @override
  State<HalamanSertifikatBlockchain> createState() => _HalamanSertifikatBlockchainState();
}

class _HalamanSertifikatBlockchainState extends State<HalamanSertifikatBlockchain> {
  List<ModelBlokTransaksi> _rantaiBlok = [];

  @override
  void initState() {
    super.initState();
    _muatRantaiBlockchain();
  }

  void _muatRantaiBlockchain() {
    setState(() {
      _rantaiBlok = LayananBasisDataLokal.ambilRantaiBlockchain();
    });
  }

  // Verifikasi Validitas Kriptografi SHA-256
  void _jalankanVerifikasiIntegritas() {
    final bool valid = LayananBlockchain.verifikasiIntegritasBlockchain();

    showDialog(
      context: context,
      builder: (context) => DialogSukses(
        judul: valid ? 'Struk Asli & Terverifikasi!' : 'Peringatan Manipulasi!',
        deskripsi: valid
            ? 'Hasil Verifikasi: VALID 100%\n\n'
                'Tujuan Fitur Blockchain:\n'
                'Setiap bukti struk belanja luar negeri dikunci menggunakan Hash SHA-256 berantai. Verifikasi ini membuktikan bahwa struk barang Anda ASLI dari toko resmi dan datanya tidak pernah direkayasa oleh traveler!'
            : 'Terdeteksi pemutusan rantai blok! Data transaksi telah diubah secara ilegal.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Buku Besar Blockchain (SHA-256)'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Verifikasi Integritas',
            icon: const Icon(Icons.verified_user),
            onPressed: _jalankanVerifikasiIntegritas,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Penjelasan Konsep Blockchain untuk Dosen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, color: Colors.blueGrey.shade900, size: 36),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Pemanfaatan Blockchain Sederhana:\nSetiap transaksi titipan dienkripsi dan dikaitkan ke blok sebelumnya menggunakan hash SHA-256 sebagai sertifikat keaslian struk belanja toko resmi luar negeri anti-barang KW.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Rantai Blok (${_rantaiBlok.length} Blok):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _jalankanVerifikasiIntegritas,
                  icon: const Icon(Icons.check_circle_outline, size: 15),
                  label: const Text('Cek Keaslian', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _rantaiBlok.length,
              separatorBuilder: (context, index) => Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Icon(Icons.link, color: Colors.blueGrey, size: 24),
              ),
              itemBuilder: (context, index) {
                final blok = _rantaiBlok[index];
                final bool isGenesis = blok.indeks == 0;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isGenesis ? Colors.amber.shade400 : Colors.blueGrey.shade100,
                      width: isGenesis ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
                              color: isGenesis ? Colors.amber.shade100 : Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isGenesis ? 'BLOK #0 (GENESIS)' : 'BLOK #${blok.indeks}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isGenesis ? Colors.amber.shade900 : Colors.blueGrey.shade900,
                              ),
                            ),
                          ),
                          Text(
                            blok.waktuStempel.length >= 19 ? blok.waktuStempel.substring(0, 19) : blok.waktuStempel,
                            style: const TextStyle(fontSize: 11, color: Colors.black45),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Isi Data Transaksi
                      const Text('Data Transaksi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (blok.dataTransaksi.containsKey('idPesanan'))
                              Text('ID Pesanan: ${blok.dataTransaksi['idPesanan']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            if (blok.dataTransaksi.containsKey('namaPembeli'))
                              Text('Pembeli: ${blok.dataTransaksi['namaPembeli']}',
                                  style: const TextStyle(fontSize: 12)),
                            if (blok.dataTransaksi.containsKey('totalHargaIdr'))
                              Text('Total: ${LayananKonversi.formatRupiah(blok.dataTransaksi['totalHargaIdr'] as int)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                            if (blok.dataTransaksi.containsKey('keaslianStruk'))
                              Text('Jaminan: ${blok.dataTransaksi['keaslianStruk']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hash Sebelumnya
                      const Text('Previous Hash:', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      Text(
                        blok.hashSebelumnya,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Hash Blok Saat Ini (SHA-256)
                      const Text('Block Hash (SHA-256):', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          blok.hash,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
