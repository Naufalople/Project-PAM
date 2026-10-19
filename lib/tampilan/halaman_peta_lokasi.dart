import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman LBS (Location Based Service) JastipGo:
// 1. Integrasi GPS Nyata HP (Geolocator Stream)
// 2. Panduan Rute Turn-by-Turn Lengkap Langsung di Dalam Aplikasi ala Google Maps
// 3. HUD Navigasi Hijau Khas Google Maps dengan Hitung Mundur Jarak, Kecepatan, & Arah Kompas (Bearing)
// 4. Mode Simulasi Perjalanan Langkah demi Langkah untuk Pengujian di Emulator/HP
// 5. Opsi Buka Aplikasi Google Maps Eksternal
class HalamanPetaLokasi extends StatefulWidget {
  const HalamanPetaLokasi({super.key});

  @override
  State<HalamanPetaLokasi> createState() => _HalamanPetaLokasiState();
}

class _HalamanPetaLokasiState extends State<HalamanPetaLokasi> with SingleTickerProviderStateMixin {
  Position? _posisiPengguna;
  StreamSubscription<Position>? _langgananPosisi;
  bool _sedangMencariLokasi = false;
  String _statusLokasi = 'Menunggu deteksi sinyal GPS HP...';
  int _indeksTitikTerpilih = 0; // Default memilih Hub UPN Veteran Yogyakarta

  // Status Navigasi In-App Turn-by-Turn ala Google Maps
  bool _sedangBernavigasi = false;
  int _langkahNavigasiAktif = 0;
  final double _kecepatanKmJam = 28.0;
  late AnimationController _animasiPulse;

  // Daftar Titik Temu / Cabang Hub Traveler JastipGo
  final List<Map<String, dynamic>> _daftarTitikTemu = [
    {
      'nama': 'Hub JastipGo Kampus UPN Condongcatur',
      'alamat': 'Jl. SWK 104 Condongcatur, Sleman, D.I. Yogyakarta',
      'lat': -7.7602,
      'lng': 110.4089,
      'traveler': 'Dimas Pratama (Landing dari Tokyo 🇯🇵)',
      'status': 'Buka (08:00 - 20:00 WIB)',
      'telepon': '081234567890',
      'estimasiWaktu': '7 Menit Berkendara',
      'jarakAwalKm': 1.6,
      'rutePetunjuk': [
        'Mulai dari posisi Anda saat ini',
        'Lurus di Jl. Babarsari sejauh 400 meter',
        'Belok kiri ke Jl. Ring Road Utara menuju Simpang UPN',
        'Belok kiri ke Jl. SWK 104 Condongcatur',
        'Tiba di Pos Serah Terima JastipGo UPN (Depan Gedung Rektorat)',
      ],
      'ikonPetunjuk': [
        Icons.navigation_rounded,
        Icons.straight_rounded,
        Icons.turn_left_rounded,
        Icons.turn_left_rounded,
        Icons.flag_rounded,
      ],
      'jarakPerLangkahMeter': [400, 500, 450, 250, 0],
    },
    {
      'nama': 'Pick-up Hub Bandara Internasional YIA',
      'alamat': 'Terminal Kedatangan Internasional YIA, Kulon Progo, Yogyakarta',
      'lat': -7.9029,
      'lng': 110.0573,
      'traveler': 'Sarah Amelia (Landing dari London Heathrow 🇬🇧)',
      'status': 'Buka 24 Jam Non-Stop',
      'telepon': '082198765432',
      'estimasiWaktu': '45 Menit Berkendara',
      'jarakAwalKm': 42.5,
      'rutePetunjuk': [
        'Mulai dari titik jemput keberangkatan',
        'Ambil jalur Ring Road Barat menuju Jl. Wates',
        'Lurus di Jl. Wates - Purworejo sejauh 35 km',
        'Masuk area Drop Zone Terminal Kedatangan Internasional YIA',
        'Tiba di Pos Koper JastipGo Counter 3B (Samping Pintu Keluar Bea Cukai)',
      ],
      'ikonPetunjuk': [
        Icons.navigation_rounded,
        Icons.turn_right_rounded,
        Icons.straight_rounded,
        Icons.turn_left_rounded,
        Icons.flag_rounded,
      ],
      'jarakPerLangkahMeter': [2500, 35000, 4500, 500, 0],
    },
    {
      'nama': 'Drop-Off Center Malioboro Yogyakarta',
      'alamat': 'Kawasan Malioboro No. 45, Danurejan, Kota Yogyakarta',
      'lat': -7.7928,
      'lng': 110.3658,
      'traveler': 'Rian Santoso (Landing dari Seoul Incheon 🇰🇷)',
      'status': 'Buka (10:00 - 22:00 WIB)',
      'telepon': '081377889900',
      'estimasiWaktu': '15 Menit Berkendara',
      'jarakAwalKm': 5.2,
      'rutePetunjuk': [
        'Mulai dari titik lokasi Anda',
        'Melaju ke barat di Jl. Laksda Adisucipto',
        'Belok kanan ke Jl. Malioboro melintasi Stasiun Tugu',
        'Masuk jalur pedestrian Malioboro',
        'Tiba di Pos JastipGo Tourist Center Malioboro',
      ],
      'ikonPetunjuk': [
        Icons.navigation_rounded,
        Icons.straight_rounded,
        Icons.turn_right_rounded,
        Icons.turn_left_rounded,
        Icons.flag_rounded,
      ],
      'jarakPerLangkahMeter': [800, 3200, 800, 400, 0],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animasiPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _mulaiPemantauanGpsRealTime();
  }

  @override
  void dispose() {
    _langgananPosisi?.cancel();
    _animasiPulse.dispose();
    super.dispose();
  }

  // Mengambil Koordinat Nyata GPS HP & Memulai Stream Pemantauan Posisi
  Future<void> _mulaiPemantauanGpsRealTime() async {
    setState(() {
      _sedangMencariLokasi = true;
      _statusLokasi = 'Menghubungkan sensor GPS HP...';
    });

    try {
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      if (izin == LocationPermission.deniedForever) {
        _terapkanFallbackKoordinat('Izin lokasi ditolak permanen. Menggunakan koordinat Kampus UPN.');
        return;
      }

      // Ambil posisi awal sekali
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (!mounted) return;
      setState(() {
        _posisiPengguna = pos;
        _sedangMencariLokasi = false;
        _statusLokasi = 'GPS Aktif • Koordinat: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });

      // Stream posisi berkelanjutan real time
      _langgananPosisi = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // Update setiap berpindah 2 meter
        ),
      ).listen((posisiBaru) {
        if (!mounted) return;
        setState(() {
          _posisiPengguna = posisiBaru;
          _statusLokasi = 'GPS Live • ${posisiBaru.latitude.toStringAsFixed(4)}, ${posisiBaru.longitude.toStringAsFixed(4)}';
        });
      });
    } catch (_) {
      _terapkanFallbackKoordinat('Sensor GPS fisik tidak terdeteksi. Menggunakan koordinat Kampus UPN.');
    }
  }

  void _terapkanFallbackKoordinat(String pesan) {
    if (!mounted) return;
    setState(() {
      _posisiPengguna = Position(
        latitude: -7.7602,
        longitude: 110.4089,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 150,
        heading: 45,
        speed: 5.5,
        speedAccuracy: 1,
        altitudeAccuracy: 1,
        headingAccuracy: 1,
      );
      _statusLokasi = pesan;
      _sedangMencariLokasi = false;
    });
  }

  // Hitung Jarak Garis Lurus Nyata
  double _hitungJarakKm(double latTujuan, double lngTujuan) {
    if (_posisiPengguna == null) return 1.5;
    final jarakMeter = Geolocator.distanceBetween(
      _posisiPengguna!.latitude,
      _posisiPengguna!.longitude,
      latTujuan,
      lngTujuan,
    );
    return (jarakMeter / 1000);
  }

  // Hitung Arah Sudut Kompas (Bearing) dari Pengguna ke Hub Tujuan
  double _hitungArahBearing(double latTujuan, double lngTujuan) {
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;
    return Geolocator.bearingBetween(userLat, userLng, latTujuan, lngTujuan);
  }

  String _terjemahkanArahKompas(double bearing) {
    double b = bearing;
    if (b < 0) b += 360;
    if (b >= 337.5 || b < 22.5) return 'Utara (N)';
    if (b >= 22.5 && b < 67.5) return 'Timur Laut (NE)';
    if (b >= 67.5 && b < 112.5) return 'Timur (E)';
    if (b >= 112.5 && b < 157.5) return 'Tenggara (SE)';
    if (b >= 157.5 && b < 202.5) return 'Selatan (S)';
    if (b >= 202.5 && b < 247.5) return 'Barat Daya (SW)';
    if (b >= 247.5 && b < 292.5) return 'Barat (W)';
    return 'Barat Laut (NW)';
  }

  // Memulai Mode Navigasi Turn-by-Turn Langsung di Dalam Aplikasi
  void _mulaiNavigasiDalamAplikasi() {
    setState(() {
      _sedangBernavigasi = true;
      _langkahNavigasiAktif = 0;
    });

    final hub = _daftarTitikTemu[_indeksTitikTerpilih];
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Navigasi In-App Dimulai 🧭',
      pesan: 'Mengarahkan rute perjalanan ke ${hub['nama']}. Ikuti petunjuk belokan di layar.',
      ikon: Icons.navigation_rounded,
      warna: Colors.green.shade800,
    );
  }

  // Simulasi Maju ke Langkah Belokan Berikutnya
  void _simulasiLangkahBerikutnya() {
    final hub = _daftarTitikTemu[_indeksTitikTerpilih];
    final petunjuk = hub['rutePetunjuk'] as List<String>;

    if (_langkahNavigasiAktif < petunjuk.length - 1) {
      setState(() {
        _langkahNavigasiAktif++;
      });
      if (_langkahNavigasiAktif == petunjuk.length - 1) {
        LayananNotifikasi.kirimNotifikasi(
          context,
          judul: 'Anda Telah Tiba di Titik Temu! 🏁',
          pesan: 'Anda telah sampai di ${hub['nama']}. Silakan temui traveler ${hub['traveler']}.',
          ikon: Icons.check_circle_rounded,
          warna: Colors.green.shade800,
        );
      }
    } else {
      setState(() {
        _sedangBernavigasi = false;
        _langkahNavigasiAktif = 0;
      });
    }
  }

  // Buka Google Maps Eksternal
  Future<void> _bukaNavigasiGoogleMaps(double latTujuan, double lngTujuan, String namaTujuan) async {
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;

    final Uri urlPeta = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$latTujuan,$lngTujuan&travelmode=driving',
    );

    try {
      final bool bisaBuka = await canLaunchUrl(urlPeta);
      if (bisaBuka) {
        await launchUrl(urlPeta, mode: LaunchMode.externalApplication);
      } else {
        final Uri geoUri = Uri.parse('geo:$latTujuan,$lngTujuan?q=$latTujuan,$lngTujuan($namaTujuan)');
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
    final jarakTerpilihKm = _hitungJarakKm(hubTerpilih['lat'], hubTerpilih['lng']);
    final arahBearing = _hitungArahBearing(hubTerpilih['lat'], hubTerpilih['lng']);

    // TAMPILAN FULLSCREEN TURN-BY-TURN IN-APP NAVIGATION (ALA GOOGLE MAPS)
    if (_sedangBernavigasi) {
      return _bangunTampilanNavigasiGoogleMapsInApp(hubTerpilih, jarakTerpilihKm, arahBearing);
    }

    // TAMPILAN STANDAR DAFTAR HUB & PREVIEW LBS MAPS
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('LBS & Titik Temu COD'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan GPS HP',
            icon: const Icon(Icons.my_location),
            onPressed: _mulaiPemantauanGpsRealTime,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Deteksi GPS Pengguna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    _sedangMencariLokasi ? Icons.gps_not_fixed : Icons.gps_fixed,
                    size: 16,
                    color: _sedangMencariLokasi ? Colors.orange : Colors.teal.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLokasi,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _sedangMencariLokasi ? Colors.orange.shade800 : Colors.teal.shade900,
                      ),
                    ),
                  ),
                  if (_sedangMencariLokasi)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // KANVAS PETA VISUAL DENGAN RUTE AKTIF & KOMPAS
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pola Garis Jalan Peta
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PetaJalanPainter(arahBearing: arahBearing),
                    ),
                  ),

                  // Header Rute Aktif
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rute: ${hubTerpilih['nama']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${jarakTerpilihKm.toStringAsFixed(1)} KM',
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Marker Posisi Pengguna dengan Animasi Denyut GPS
                  Positioned(
                    bottom: 35,
                    left: 45,
                    child: AnimatedBuilder(
                      animation: _animasiPulse,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.2 + (_animasiPulse.value * 0.4)),
                                    blurRadius: 10 + (_animasiPulse.value * 8),
                                    spreadRadius: 2 + (_animasiPulse.value * 4),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: arahBearing * (math.pi / 180),
                                child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Posisi HP Anda', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Marker Titik Temu COD
                  Positioned(
                    top: 55,
                    right: 40,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Titik Temu COD', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Info Arah Kompas (Bearing)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.explore_rounded, size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            'Arah: ${_terjemahkanArahKompas(arahBearing)} (${arahBearing.toStringAsFixed(0)}°)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // TOMBOL UTAMA: MULAI NAVIGASI LANGSUNG DI DALAM APLIKASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade800, Colors.teal.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.teal.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation_rounded, color: Colors.amberAccent, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'NAVIGASI TURN-BY-TURN IN-APP (ALA GOOGLE MAPS)',
                          style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Anda dapat langsung bernavigasi ke titik temu di dalam aplikasi ini tanpa harus keluar membuka aplikasi Google Maps.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _mulaiNavigasiDalamAplikasi,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text(
                            'MULAI NAVIGASI DI APLIKASI',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Petunjuk Belokan Demi Belokan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alt_route_rounded, color: Colors.teal.shade800, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Panduan Rute Jalan Menuju Titik Temu:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  ...List.generate(
                    (hubTerpilih['rutePetunjuk'] as List<String>).length,
                    (idx) {
                      final petunjuk = (hubTerpilih['rutePetunjuk'] as List<String>)[idx];
                      final IconData ikon = (hubTerpilih['ikonPetunjuk'] as List<IconData>)[idx];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(ikon, size: 14, color: Colors.teal.shade800),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                petunjuk,
                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
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
            const SizedBox(height: 20),

            const Text(
              'Pilih Pos Penyerahan / Titik Temu Terdekat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // Daftar Pilihan Titik Temu Hub JastipGo
            ...List.generate(_daftarTitikTemu.length, (index) {
              final hub = _daftarTitikTemu[index];
              final jarak = _hitungJarakKm(hub['lat'], hub['lng']);
              final bool sedangDipilih = _indeksTitikTerpilih == index;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _indeksTitikTerpilih = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sedangDipilih ? Colors.teal.shade700 : Colors.grey.shade200,
                      width: sedangDipilih ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: sedangDipilih ? Colors.teal.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hub['nama'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: sedangDipilih ? Colors.teal.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${jarak.toStringAsFixed(1)} KM',
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(hub['alamat'], style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person_pin, size: 15, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hub['traveler'],
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hub['status']} • Estimasi: ${hub['estimasiWaktu']}',
                        style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sedangDipilih ? Colors.teal.shade800 : Colors.grey.shade200,
                                foregroundColor: sedangDipilih ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() => _indeksTitikTerpilih = index);
                                _mulaiNavigasiDalamAplikasi();
                              },
                              icon: const Icon(Icons.navigation_rounded, size: 16),
                              label: const Text('Navigasi di Aplikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade800,
                              side: BorderSide(color: Colors.blue.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _bukaNavigasiGoogleMaps(hub['lat'], hub['lng'], hub['nama']),
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Maps Luar', style: TextStyle(fontSize: 10.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // WIDGET KHUSUS: TAMPILAN GOOGLE MAPS NAVIGATION HUD LENGKAP DI DALAM APLIKASI
  Widget _bangunTampilanNavigasiGoogleMapsInApp(
    Map<String, dynamic> hub,
    double jarakKm,
    double bearing,
  ) {
    final petunjukList = hub['rutePetunjuk'] as List<String>;
    final ikonList = hub['ikonPetunjuk'] as List<IconData>;
    final jarakLangkahList = hub['jarakPerLangkahMeter'] as List<int>;

    final String petunjukSaatIni = petunjukList[_langkahNavigasiAktif];
    final IconData ikonSaatIni = ikonList[_langkahNavigasiAktif];
    final int jarakKeBelokanBerikutnya = jarakLangkahList[_langkahNavigasiAktif];

    final String? petunjukSelanjutnya = (_langkahNavigasiAktif + 1 < petunjukList.length)
        ? petunjukList[_langkahNavigasiAktif + 1]
        : null;

    final bool adalahLangkahTerakhir = _langkahNavigasiAktif >= petunjukList.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2A32),
      body: SafeArea(
        child: Column(
          children: [
            // TOP GREEN NAVIGATION HUD BAR (Khas Google Maps Turn-by-Turn Navigation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF0F9D58), // Hijau Resmi Google Maps Navigation
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ikonSaatIni, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adalahLangkahTerakhir
                                  ? 'TIBA DI TUJUAN'
                                  : 'Dalam $jarakKeBelokanBerikutnya m',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              petunjukSaatIni,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (petunjukSelanjutnya != null) ...[
                    const Divider(color: Colors.white24, height: 16),
                    Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Lalu: $petunjukSelanjutnya',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // LIVE MAP VIEW & DYNAMIC ROUTE CANVAS
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFE8ECEF),
                      child: CustomPaint(
                        painter: _PetaNavigasiAktifPainter(
                          langkahAktif: _langkahNavigasiAktif,
                          totalLangkah: petunjukList.length,
                          animasi: _animasiPulse.value,
                        ),
                      ),
                    ),
                  ),

                  // Floating Bearing Compass Pill di Atas Kiri
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: bearing * (math.pi / 180),
                            child: const Icon(Icons.navigation_rounded, color: Colors.red, size: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${bearing.toStringAsFixed(0)}° ${_terjemahkanArahKompas(bearing)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Speed & Voice Pill di Atas Kanan
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Colors.teal, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_kecepatanKmJam.toStringAsFixed(0)} km/jam',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Simulasi Maju Langkah Demi Langkah (Untuk Demo/Pengujian Emulator & HP)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progres Belokan: Langkah ${_langkahNavigasiAktif + 1} dari ${petunjukList.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              Text(
                                adalahLangkahTerakhir ? '🏁 Sampai' : '🚗 Berjalan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: adalahLangkahTerakhir ? Colors.green.shade800 : Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_langkahNavigasiAktif + 1) / petunjukList.length,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                adalahLangkahTerakhir ? Colors.green : Colors.teal,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: adalahLangkahTerakhir ? Colors.green.shade700 : Colors.teal.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _simulasiLangkahBerikutnya,
                              icon: Icon(
                                adalahLangkahTerakhir ? Icons.check_circle : Icons.fast_forward_rounded,
                                size: 18,
                              ),
                              label: Text(
                                adalahLangkahTerakhir
                                    ? 'SELESAIKAN & KELUAR NAVIGASI'
                                    : 'SIMULASI LANGKAH MAJU BERIKUTNYA',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
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

            // BOTTOM NAVIGATION STATS BAR (Waktu Tempuh, Jarak, & Tombol Keluar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  // Waktu & Jarak
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              hub['estimasiWaktu'],
                              style: const TextStyle(
                                color: Color(0xFF0F9D58),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${jarakKm.toStringAsFixed(1)} km)',
                              style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          'Tujuan: ${hub['nama']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Keluar Navigasi (Silang Merah Ala Google Maps)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Tutup Navigasi',
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 26),
                      onPressed: () {
                        setState(() {
                          _sedangBernavigasi = false;
                          _langkahNavigasiAktif = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter untuk Rute Standar
class _PetaJalanPainter extends CustomPainter {
  final double arahBearing;
  _PetaJalanPainter({required this.arahBearing});

  @override
  void paint(Canvas canvas, Size size) {
    final paintJalan = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final paintGarisTengah = Paint()
      ..color = const Color(0xFFD6DBDF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintRuteGoogleMaps = Paint()
      ..color = const Color(0xFF1A73E8) // Biru Google Maps
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jalanPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.3);

    canvas.drawPath(jalanPath, paintJalan);
    canvas.drawPath(jalanPath, paintGarisTengah);

    final rutePath = Path()
      ..moveTo(65, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width - 60, size.height * 0.3);

    canvas.drawPath(rutePath, paintRuteGoogleMaps);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter untuk Live Navigation In-App Turn-by-Turn
class _PetaNavigasiAktifPainter extends CustomPainter {
  final int langkahAktif;
  final int totalLangkah;
  final double animasi;

  _PetaNavigasiAktifPainter({
    required this.langkahAktif,
    required this.totalLangkah,
    required this.animasi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintJalan = Paint()
      ..color = Colors.white
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;

    final paintJalanBorder = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke;

    final paintRuteLewat = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintRuteAktif = Paint()
      ..color = const Color(0xFF1E88E5) // Biru Navigasi
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Koordinat Jalur Rute Dinamis
    final p0 = Offset(size.width * 0.2, size.height * 0.8);
    final p1 = Offset(size.width * 0.2, size.height * 0.55);
    final p2 = Offset(size.width * 0.5, size.height * 0.55);
    final p3 = Offset(size.width * 0.5, size.height * 0.3);
    final p4 = Offset(size.width * 0.8, size.height * 0.3);

    final List<Offset> points = [p0, p1, p2, p3, p4];

    // Gambar Jalan
    final pathJalan = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy);

    canvas.drawPath(pathJalan, paintJalanBorder);
    canvas.drawPath(pathJalan, paintJalan);

    // Hitung Posisi Pengguna Saat Ini Berdasarkan Progres Langkah
    final double fraction = points.isNotEmpty ? (langkahAktif / (totalLangkah - 1)).clamp(0.0, 1.0) : 0.0;
    final int segmentIndex = (fraction * (points.length - 1)).floor().clamp(0, points.length - 2);
    final double segmentFraction = (fraction * (points.length - 1)) - segmentIndex;

    final startPoint = points[segmentIndex];
    final endPoint = points[segmentIndex + 1];

    final currentPos = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * segmentFraction,
      startPoint.dy + (endPoint.dy - startPoint.dy) * segmentFraction,
    );

    // Gambar Rute yang Sudah Dilewati
    final pathLewat = Path()..moveTo(p0.dx, p0.dy);
    for (int i = 1; i <= segmentIndex; i++) {
      pathLewat.lineTo(points[i].dx, points[i].dy);
    }
    pathLewat.lineTo(currentPos.dx, currentPos.dy);
    canvas.drawPath(pathLewat, paintRuteLewat);

    // Gambar Sisa Rute Aktif
    final pathAktif = Path()..moveTo(currentPos.dx, currentPos.dy);
    for (int i = segmentIndex + 1; i < points.length; i++) {
      pathAktif.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(pathAktif, paintRuteAktif);

    // Gambar Titik Temu Tujuan (Pin Merah)
    final paintPin = Paint()..color = Colors.redAccent.shade700;
    canvas.drawCircle(p4, 12, paintPin);
    final paintPinInner = Paint()..color = Colors.white;
    canvas.drawCircle(p4, 5, paintPinInner);

    // Gambar Indikator Posisi Mobil / Pengguna yang Sedang Berjalan
    final paintPulsing = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2 + (animasi * 0.4))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 20 + (animasi * 8), paintPulsing);

    final paintUser = Paint()..color = const Color(0xFF1E88E5);
    canvas.drawCircle(currentPos, 10, paintUser);

    final paintUserBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(currentPos, 10, paintUserBorder);
  }

  @override
  bool shouldRepaint(covariant _PetaNavigasiAktifPainter oldDelegate) => true;
}
