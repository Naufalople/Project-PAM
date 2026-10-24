import 'package:flutter/material.dart';
import '../model/model_barang_jastip.dart';
import '../layanan/layanan_konversi.dart';

// Widget Kartu Barang Jastip Reusable
class KartuBarang extends StatelessWidget {
  final ModelBarangJastip barang;
  final VoidCallback saatDitekan;
  final VoidCallback saatTombolTitip;
  final bool bisaTitip;

  const KartuBarang({
    super.key,
    required this.barang,
    required this.saatDitekan,
    required this.saatTombolTitip,
    this.bisaTitip = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saatDitekan,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Gambar & Lencana Negara
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    barang.fotoUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 95),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${barang.benderaNegara} ${barang.negara}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          barang.rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Detail Informasi Barang
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            barang.kategori,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          barang.namaBarang,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          LayananKonversi.formatRupiah(barang.estimasiHargaIdr),
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.0,
                          ),
                        ),
                        Text(
                          LayananKonversi.formatMataUangAsing(barang.hargaAsli, barang.kodeMataUang),
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bisaTitip ? Colors.teal.shade600 : Colors.indigo.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: bisaTitip ? saatTombolTitip : saatDitekan,
                        icon: Icon(bisaTitip ? Icons.add_shopping_cart : Icons.info_outline, size: 14),
                        label: Text(
                          bisaTitip ? 'Titip' : 'Detail',
                          style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
