import 'package:flutter/material.dart';
import '../layanan/layanan_konversi.dart';

// Halaman Kalkulator Kurs Mata Uang Asing ke Rupiah (Valuta Asing Jastip)
class HalamanKalkulatorKurs extends StatefulWidget {
  const HalamanKalkulatorKurs({super.key});

  @override
  State<HalamanKalkulatorKurs> createState() => _HalamanKalkulatorKursState();
}

class _HalamanKalkulatorKursState extends State<HalamanKalkulatorKurs> {
  final TextEditingController _inputNominalController = TextEditingController(text: '1000');
  String _mataUangPilihan = 'JPY';
  int _hasilKonversiRupiah = 0;
  bool _sedangMemuatKurs = false;

  final List<Map<String, String>> _daftarMataUang = [
    {'kode': 'JPY', 'nama': 'Yen Jepang', 'bendera': '🇯🇵', 'simbol': '¥'},
    {'kode': 'KRW', 'nama': 'Won Korea Selatan', 'bendera': '🇰🇷', 'simbol': '₩'},
    {'kode': 'GBP', 'nama': 'Poundsterling Inggris / London', 'bendera': '🇬🇧', 'simbol': '£'},
    {'kode': 'USD', 'nama': 'Dollar Amerika Serikat', 'bendera': '🇺🇸', 'simbol': '\$'},
    {'kode': 'SGD', 'nama': 'Dollar Singapura', 'bendera': '🇸🇬', 'simbol': 'S\$'},
    {'kode': 'CNY', 'nama': 'Yuan China', 'bendera': '🇨🇳', 'simbol': '¥'},
  ];

  @override
  void initState() {
    super.initState();
    _ambilKursLive();
    _hitungKonversi();
  }

  Future<void> _ambilKursLive() async {
    setState(() => _sedangMemuatKurs = true);
    await LayananKonversi.perbaruiKursDariApi();
    if (mounted) {
      setState(() {
        _sedangMemuatKurs = false;
        _hitungKonversi();
      });
    }
  }

  @override
  void dispose() {
    _inputNominalController.dispose();
    super.dispose();
  }

  void _hitungKonversi() {
    final double nominal = double.tryParse(_inputNominalController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _hasilKonversiRupiah = LayananKonversi.konversiKeRupiah(nominal, _mataUangPilihan);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Kalkulator Kurs Valas Jastip'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _sedangMemuatKurs
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Perbarui Kurs Live',
            onPressed: _sedangMemuatKurs ? null : _ambilKursLive,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Sinkronisasi Web Service Kurs Live
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: LayananKonversi.statusOnlineTerhubung ? Colors.teal.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: LayananKonversi.statusOnlineTerhubung ? Colors.teal.shade200 : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LayananKonversi.statusOnlineTerhubung ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    color: LayananKonversi.statusOnlineTerhubung ? Colors.teal.shade800 : Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LayananKonversi.statusOnlineTerhubung
                          ? 'Kurs Live REST API (open.er-api.com) • Diperbarui: ${LayananKonversi.waktuPembaruanTerakhir ?? "Baru saja"}'
                          : 'Mode Offline (Cache Tersimpan) • Tekan tombol refresh untuk update.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LayananKonversi.statusOnlineTerhubung ? Colors.teal.shade900 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Panel Input Konversi
            Container(
              padding: const EdgeInsets.all(22),
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
                  const Text(
                    'Pilih Mata Uang Negara Singgah:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _mataUangPilihan,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    items: _daftarMataUang.map((m) {
                      return DropdownMenuItem(
                        value: m['kode'],
                        child: Text(
                          '${m['bendera']} ${m['kode']} - ${m['nama']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _mataUangPilihan = val);
                        _hitungKonversi();
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Nominal Belanjaan Asing:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inputNominalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => _hitungKonversi(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _mataUangPilihan,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hasil Konversi ke Rupiah
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade800, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimasi Nilai Tukar Rupiah (IDR):',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LayananKonversi.formatRupiah(_hasilKonversiRupiah),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurs: 1 $_mataUangPilihan = ${LayananKonversi.formatRupiah(LayananKonversi.nilaiKursKeRupiah[_mataUangPilihan]!.toInt())}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daftar Tabel Kurs Lengkap
            const Text(
              'Tabel Referensi Kurs Resmi (Live):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _daftarMataUang.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _daftarMataUang[index];
                final kurs = LayananKonversi.nilaiKursKeRupiah[item['kode']] ?? 1.0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(item['bendera']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(item['kode']!, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '1 ${item['kode']} = ${LayananKonversi.formatRupiah(kurs.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.right,
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
