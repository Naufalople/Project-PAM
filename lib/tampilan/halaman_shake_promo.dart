import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../layanan/layanan_sensor.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman Sensor Akselerometer: "Goyang HP untuk Diskon Jastip" (Shake Promo)
class HalamanShakePromo extends StatefulWidget {
  const HalamanShakePromo({super.key});

  @override
  State<HalamanShakePromo> createState() => _HalamanShakePromoState();
}

class _HalamanShakePromoState extends State<HalamanShakePromo> with SingleTickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _langgananAkselerometer;
  late AnimationController _animasiKotak;
  String? _voucherDidapat;
  int _jumlahGoyangan = 0;

  final List<String> _daftarVoucher = [
    '🎉 Diskon Ongkos Titip 50% untuk Pengiriman Jepang',
    '🎁 Potongan Rp 100.000 untuk Pembelian di Harrods London',
    '✨ Gratis Kemasan Box & Bubble Wrap Premium Internasional',
    '✈️ Voucher Cashback Rp 50.000 untuk Jastip Skincare Korea',
    '🔥 Diskon Kilat 30% Tanpa Minimum Belanja',
  ];

  @override
  void initState() {
    super.initState();
    _animasiKotak = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _aktifkanSensorGoyang();
  }

  @override
  void dispose() {
    _langgananAkselerometer?.cancel();
    _animasiKotak.dispose();
    super.dispose();
  }

  // Mengaktifkan Sensor Akselerometer untuk Mendeteksi Goyangan HP
  void _aktifkanSensorGoyang() {
    _langgananAkselerometer = LayananSensor.dengarkanGoyanganHp(
      saatGoyanganTerdeteksi: () {
        _picuHadiahPromo();
      },
    );
  }

  void _picuHadiahPromo() {
    _animasiKotak.forward(from: 0.0);
    final random = Random();
    final voucherTerpilih = _daftarVoucher[random.nextInt(_daftarVoucher.length)];

    setState(() {
      _jumlahGoyangan++;
      _voucherDidapat = voucherTerpilih;
    });

    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Voucher Promo Berhasil Diklaim!',
      pesan: voucherTerpilih,
      ikon: Icons.card_giftcard,
      warna: Colors.amber.shade900,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Shake & Win Promo'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kartu Panduan Sensor
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vibration, color: Colors.amber.shade900, size: 36),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Pemanfaatan Sensor Akselerometer:\nGoyangkan HP Anda ke kanan & ke kiri secara nyata untuk mengocok kotak hadiah promo jastip!',
                        style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Animasi Kotak Hadiah
              AnimatedBuilder(
                animation: _animasiKotak,
                builder: (context, child) {
                  final double angle = sin(_animasiKotak.value * pi * 4) * 0.15;
                  return Transform.rotate(
                    angle: angle,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 96,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Goyang HP Anda Sekarang!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total Goyangan Terdeteksi: $_jumlahGoyangan kali',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // Tampilan Voucher yang Didapat
              if (_voucherDidapat != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.amber.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KUPON DISKON ANDA:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black45,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _voucherDidapat!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tombol Simulasi Goyang (Sangat Berguna jika Dosen Menguji di Emulator Laptop)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                  side: BorderSide(color: Colors.amber.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _picuHadiahPromo,
                icon: const Icon(Icons.touch_app),
                label: const Text('Simulasi Goyang HP (Khusus Emulator)'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
