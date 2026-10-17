import 'package:flutter/material.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman Mini Game Sederhana: "Tebak Harga Koper Jastip"
class HalamanMiniGame extends StatefulWidget {
  const HalamanMiniGame({super.key});

  @override
  State<HalamanMiniGame> createState() => _HalamanMiniGameState();
}

class _HalamanMiniGameState extends State<HalamanMiniGame> {
  int _skor = 0;
  int _nomorSoal = 0;
  bool _kuisSelesai = false;
  ModelVoucher? _voucherHadiah;

  final List<Map<String, dynamic>> _daftarSoal = [
    {
      'pertanyaan': 'Berapa rata-rata harga sekotak kue Tokyo Banana asli isi 8 di stasiun Tokyo?',
      'negara': '🇯🇵 Jepang',
      'pilihan': ['¥500 (~Rp 56.000)', '¥1.200 (~Rp 135.000)', '¥3.500 (~Rp 390.000)'],
      'jawabanBenar': 1,
      'fakta': 'Kue Tokyo Banana asli biasanya dibanderol sekitar 1.200 Yen di Tokyo Station!',
    },
    {
      'pertanyaan': 'Berapa harga tas belanja ikonik Harrods Green Bag di Knightsbridge London?',
      'negara': '🇬🇧 London (UK)',
      'pilihan': ['£10 (~Rp 206.000)', '£35 (~Rp 720.000)', '£95 (~Rp 1.950.000)'],
      'jawabanBenar': 1,
      'fakta': 'Tas belanja Harrods ukuran medium rata-rata dijual seharga £35.',
    },
    {
      'pertanyaan': 'Berapa batas maksimal pembebasan bea cukai barang bawaan pribadi masuk ke Indonesia?',
      'negara': '🇮🇩 Bea Cukai RI',
      'pilihan': ['FOB USD 250', 'FOB USD 500', 'FOB USD 1.000'],
      'jawabanBenar': 1,
      'fakta': 'Sesuai PMK 203/2017, batas pembebasan bea masuk adalah FOB USD 500 per penumpang.',
    },
    {
      'pertanyaan': 'Di distrik manakah surga belanja skincare dan kosmetik paling terkenal di Seoul?',
      'negara': '🇰🇷 Korea Selatan',
      'pilihan': ['Myeongdong', 'Gangnam Station', 'Hongdae Market'],
      'jawabanBenar': 0,
      'fakta': 'Myeongdong adalah pusat gerai kosmetik dan Olive Young terbesar di Korea!',
    },
  ];

  Future<void> _jawabPertanyaan(int indeksPilihan) async {
    final bool benar = indeksPilihan == _daftarSoal[_nomorSoal]['jawabanBenar'];

    int skorBaru = _skor;
    if (benar) {
      skorBaru += 25;
      setState(() => _skor = skorBaru);
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Jawaban Benar! 🎯',
        pesan: '+25 Koin Jastip ditambahkan ke saldo koper Anda.',
        ikon: Icons.stars,
        warna: Colors.amber.shade800,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kurang tepat! Fakta: ${_daftarSoal[_nomorSoal]['fakta']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (_nomorSoal < _daftarSoal.length - 1) {
      setState(() => _nomorSoal++);
    } else {
      ModelVoucher? hadiah;
      if (skorBaru >= 50) {
        hadiah = ModelVoucher(
          kode: 'KUIS50',
          judul: 'Voucher Juara Kuis Rp 50.000',
          potonganIdr: 50000,
          deskripsi: 'Hadiah keberhasilan kuis wawasan koper jastip.',
        );
        await LayananBasisDataLokal.simpanVoucher(hadiah);
        if (!mounted) return;
        LayananNotifikasi.kirimNotifikasi(
          context,
          judul: 'Selamat! Voucher Hadiah Diberikan! 🏆',
          pesan: 'Anda memenangkan Voucher KUIS50 (Potongan Rp 50.000) dan tersimpan di akun Anda!',
          ikon: Icons.card_giftcard,
          warna: Colors.indigo.shade800,
        );
      }

      setState(() {
        _voucherHadiah = hadiah;
        _kuisSelesai = true;
      });
    }
  }

  void _ulangGame() {
    setState(() {
      _skor = 0;
      _nomorSoal = 0;
      _kuisSelesai = false;
      _voucherHadiah = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Mini Game Koper Jastip'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: _kuisSelesai
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 72),
                        const SizedBox(height: 16),
                        const Text(
                          'Permainan Selesai!',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Skor Anda: $_skor Poin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _skor >= 75
                              ? 'Luar biasa! Anda seorang ahli traveler jastip sejati!'
                              : 'Bagus! Tingkatkan lagi wawasan harga jastip Anda.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        if (_voucherHadiah != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.card_giftcard, color: Colors.amber.shade900, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _voucherHadiah!.judul,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'KODE: ${_voucherHadiah!.kode} • POTONGAN ${LayananKonversi.formatRupiah(_voucherHadiah!.potonganIdr)}',
                                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo.shade900, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '✅ Kupon sudah tersimpan dan otomatis bisa dipilih saat Anda memesan barang!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10.5, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _ulangGame,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Main Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Skor & Nomor Soal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Soal ${_nomorSoal + 1} dari ${_daftarSoal.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Skor: $_skor',
                                style: TextStyle(
                                  color: Colors.indigo.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    LinearProgressIndicator(
                      value: (_nomorSoal + 1) / _daftarSoal.length,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.indigo.shade700,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 24),

                    // Kartu Pertanyaan
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _daftarSoal[_nomorSoal]['negara'],
                              style: TextStyle(
                                color: Colors.indigo.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _daftarSoal[_nomorSoal]['pertanyaan'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pilihan Jawaban
                    ...List.generate(
                      (_daftarSoal[_nomorSoal]['pilihan'] as List<String>).length,
                      (index) {
                        final pilihanTeks = (_daftarSoal[_nomorSoal]['pilihan'] as List<String>)[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () => _jawabPertanyaan(index),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.indigo.shade50,
                                  child: Text(
                                    String.fromCharCode(65 + index), // A, B, C
                                    style: TextStyle(
                                      color: Colors.indigo.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pilihanTeks,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
