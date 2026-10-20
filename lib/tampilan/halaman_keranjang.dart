import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/model_keranjang.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_otentikasi.dart';
import 'halaman_checkout.dart';

// Halaman Keranjang Belanja Titipan (Penyimpanan Lokal Offline Hive Reaktif)
class HalamanKeranjang extends StatefulWidget {
  final Function(int)? padaPindahTab;

  const HalamanKeranjang({super.key, this.padaPindahTab});

  @override
  State<HalamanKeranjang> createState() => _HalamanKeranjangState();
}

class _HalamanKeranjangState extends State<HalamanKeranjang> {
  // Tambah / Kurang Jumlah Item
  Future<void> _ubahJumlah(int indeks, int jumlahBaru) async {
    await LayananBasisDataLokal.ubahJumlahItem(indeks, jumlahBaru);
  }

  // Hapus Item
  Future<void> _hapusItem(int indeks) async {
    await LayananBasisDataLokal.hapusDariKeranjang(indeks);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box(LayananBasisDataLokal.namaKotakKeranjang).listenable(),
      builder: (context, box, _) {
        final List<ModelKeranjang> daftarKeranjang = LayananBasisDataLokal.ambilSemuaKeranjang();
        final int totalHarga = LayananBasisDataLokal.hitungTotalHargaKeranjang();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: const Text('Keranjang Titipan (Hive)'),
            backgroundColor: Colors.teal.shade800,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (daftarKeranjang.isNotEmpty)
                IconButton(
                  tooltip: 'Kosongkan Keranjang',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () async {
                    await LayananBasisDataLokal.kosongkanKeranjang();
                  },
                ),
            ],
          ),
          body: daftarKeranjang.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 64,
                        color: Colors.teal.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Keranjang Belanja Kosong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih barang impian dari katalog negara singgah atau gunakan pemindai foto AI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (widget.padaPindahTab != null) {
                          widget.padaPindahTab!(0); // Pindah ke tab beranda
                        }
                      },
                      child: const Text('Jelajahi Katalog'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Info Offline Storage Hive
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.teal.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.offline_pin, size: 18, color: Colors.teal.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tersimpan di Basis Data Lokal Hive (${daftarKeranjang.length} barang)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daftar Item Keranjang
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daftarKeranjang.length,
                    itemBuilder: (context, index) {
                      final item = daftarKeranjang[index];
                      return Dismissible(
                        key: ValueKey('keranjang-${item.idBarang}-$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) => _hapusItem(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Foto Barang
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item.fotoUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.shopping_bag, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info Barang
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaBarang,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.negara} • ${LayananKonversi.formatMataUangAsing(item.hargaAsli, item.kodeMataUang)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      LayananKonversi.formatRupiah(item.hargaIdr),
                                      style: TextStyle(
                                        color: Colors.teal.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Pengatur Kuantitas (+ / -)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                                    color: Colors.grey.shade700,
                                    onPressed: () => _ubahJumlah(index, item.jumlah - 1),
                                  ),
                                  Text(
                                    '${item.jumlah}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 22),
                                    color: Colors.teal.shade700,
                                    onPressed: () => _ubahJumlah(index, item.jumlah + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Panel Checkout Bawah
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Text(
                              LayananKonversi.formatRupiah(totalHarga),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final destinasi = await LayananOtentikasi.ambilDestinasiAktifTraveler();
                          final itemTidakCocok = daftarKeranjang.where(
                            (item) => !LayananOtentikasi.apakahNegaraSesuai(item.negara, destinasi),
                          ).toList();

                          if (itemTidakCocok.isNotEmpty) {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    Icon(Icons.flight_land_rounded, color: Colors.deepOrange.shade700),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('Barang Luar Rute Terdeteksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'Traveler saat ini hanya melayani rute perjalanan $destinasi.\n\nKeranjang Anda berisi ${itemTidakCocok.length} barang dari luar rute ($destinasi). Silakan hapus barang tersebut sebelum melanjutkan checkout.',
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

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HalamanCheckout(daftarItem: daftarKeranjang),
                            ),
                          );
                        },
                        child: const Text('CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
