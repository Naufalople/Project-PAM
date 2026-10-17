import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman LBS (Location Based Service): Integrasi Peta Google Maps & Navigasi Rute Titik Temu COD
class HalamanPetaLokasi extends StatefulWidget {
  const HalamanPetaLokasi({super.key});

  @override
  State<HalamanPetaLokasi> createState() => _HalamanPetaLokasiState();
}

class _HalamanPetaLokasiState extends State<HalamanPetaLokasi> {
  Position? _posisiPengguna;
  bool _sedangMencariLokasi = false;
  String _statusLokasi = 'Menunggu deteksi sinyal GPS...';
  int _indeksTitikTerpilih = 0; // Default memilih Hub UPN Veteran Yogyakarta

  // Daftar Titik Temu / Cabang Hub Traveler JastipGo
  final List<Map<String, dynamic>> _daftarTitikTemu = [
    {
      'nama': 'Hub JastipGo Kampus UPN Condongcatur',
      'alamat': 'Jl. SWK 104 Condongcatur, Sleman, D.I. Yogyakarta',
      'lat': -7.7602,
      'lng': 110.4089,
      'traveler': 'Mas Dimas (Baru landing dari Tokyo)',
      'status': 'Buka (08:00 - 20:00 WIB)',
      'telepon': '081234567890',
      'estimasiWaktu': '7 Menit Berkendara',
      'rutePetunjuk': [
        'Mulai dari posisi Anda saat ini',
        'Ikuti Jl. Babarsari menuju Jl. Ring Road Utara',
        'Belok kiri ke Jl. SWK menuju Kampus UPN Condongcatur',
        'Tiba di Pos Serah Terima JastipGo UPN (Depan Gedung Rektorat)',
      ],
    },
    {
      'nama': 'Pick-up Hub Bandara Internasional YIA',
      'alamat': 'Terminal Kedatangan Internasional YIA, Kulon Progo, Yogyakarta',
      'lat': -7.9029,
      'lng': 110.0573,
      'traveler': 'Mbak Sarah (Baru landing dari London Heathrow)',
      'status': 'Buka 24 Jam Non-Stop',
      'telepon': '082198765432',
      'estimasiWaktu': '45 Menit Berkendara',
      'rutePetunjuk': [
        'Ambil jalur Jl. Wates menuju Bandara YIA',
        'Masuk ke area Drop Zone / Terminal Kedatangan Internasional',
        'Tiba di Pos Koper JastipGo Counter 3B (Samping Pintu Keluar Bea Cukai)',
      ],
    },
    {
      'nama': 'Drop-Off Center Malioboro Yogyakarta',
      'alamat': 'Kawasan Malioboro No. 45, Danurejan, Kota Yogyakarta',
      'lat': -7.7928,
      'lng': 110.3658,
      'traveler': 'Kak Rian (Baru landing dari Seoul Incheon)',
      'status': 'Buka (10:00 - 22:00 WIB)',
      'telepon': '081377889900',
      'estimasiWaktu': '15 Menit Berkendara',
      'rutePetunjuk': [
        'Melaju ke arah barat menuju Stasiun Tugu',
        'Masuk jalur pedestrian Malioboro',
        'Tiba di Pos JastipGo Tourist Information Center Malioboro',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _ambilKoordinatGps();
  }

  // Mengambil Koordinat GPS Nyata Pengguna
  Future<void> _ambilKoordinatGps() async {
    setState(() {
      _sedangMencariLokasi = true;
      _statusLokasi = 'Mencari titik koordinat GPS HP...';
    });

    try {
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      if (izin == LocationPermission.deniedForever) {
        setState(() {
          _statusLokasi = 'Izin lokasi ditolak permanen. Gunakan koordinat simulasi Kampus UPN.';
          _posisiPengguna = Position(
            latitude: -7.7602,
            longitude: 110.4089,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 150,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _sedangMencariLokasi = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      setState(() {
        _posisiPengguna = pos;
        _statusLokasi = 'Koordinat GPS Berhasil Ditemukan!';
        _sedangMencariLokasi = false;
      });
    } catch (e) {
      // Fallback ke titik default Kampus UPN Veteran Yogyakarta jika di emulator
      setState(() {
        _posisiPengguna = Position(
          latitude: -7.7602,
          longitude: 110.4089,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 150,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _statusLokasi = 'Menggunakan koordinat simulasi Kampus UPN Yogyakarta.';
        _sedangMencariLokasi = false;
      });
    }
  }

  // Hitung jarak garis lurus dalam kilometer
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

  // Membuka Google Maps secara langsung dengan rute navigasi turn-by-turn
  Future<void> _bukaNavigasiGoogleMaps(double latTujuan, double lngTujuan, String namaTujuan) async {
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;

    // URL standar Google Maps Directions Turn-by-Turn
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
    } catch (e) {
      if (!mounted) return;
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Membuka Google Maps',
        pesan: 'Mengarahkan rute perjalanan ke $namaTujuan',
        ikon: Icons.map_rounded,
        warna: Colors.blue.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
    final jarakTerpilih = _hitungJarakKm(hubTerpilih['lat'], hubTerpilih['lng']);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('LBS & Navigasi Titik Temu COD'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan GPS',
            icon: const Icon(Icons.my_location),
            onPressed: _ambilKoordinatGps,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Deteksi GPS Pengguna
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Icon(
                    _sedangMencariLokasi ? Icons.gps_not_fixed : Icons.gps_fixed,
                    size: 15,
                    color: _sedangMencariLokasi ? Colors.orange : Colors.teal.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusLokasi,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
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

            // Peta Simulasi Interaktif Ala Google Maps (Visual Route Canvas)
            Container(
              height: 220,
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
                  // Pola Garis Jalan Peta (Grid Ala Google Maps)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PetaJalanPainter(),
                    ),
                  ),

                  // Info Rute Aktif di Bagian Atas Peta
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rute ke: ${hubTerpilih['nama']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${jarakTerpilih.toStringAsFixed(1)} KM',
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

                  // Marker Posisi Pengguna (Titik Biru Berkedip / GPS HP)
                  Positioned(
                    bottom: 40,
                    left: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Lokasi Anda', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  // Marker Titik Temu Hub Terpilih (Pin Merah Google Maps)
                  Positioned(
                    top: 60,
                    right: 45,
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
                          child: const Text('Titik Temu COD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Cepat Buka Google Maps Nyata di Sudut Kanan Bawah Peta
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade900,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _bukaNavigasiGoogleMaps(
                        hubTerpilih['lat'],
                        hubTerpilih['lng'],
                        hubTerpilih['nama'],
                      ),
                      icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 18),
                      label: const Text('Navigasi Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Petunjuk Arah Rute Jalan Menuju Titik Temu
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
                      Icon(Icons.alt_route_rounded, color: Colors.teal.shade800, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Panduan Rute Jalan Belokan demi Belokan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  ...List.generate(
                    (hubTerpilih['rutePetunjuk'] as List<String>).length,
                    (idx) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.teal.shade100,
                            child: Text('${idx + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (hubTerpilih['rutePetunjuk'] as List<String>)[idx],
                              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Pilih Pos Penyerahan / Titik Temu Terdekat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Daftar Pos Titik Temu
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _daftarTitikTemu.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final hub = _daftarTitikTemu[index];
                final jarak = _hitungJarakKm(hub['lat'], hub['lng']);
                final bool sedangDipilih = _indeksTitikTerpilih == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _indeksTitikTerpilih = index),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                                  fontSize: 14,
                                  color: sedangDipilih ? Colors.teal.shade900 : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${jarak.toStringAsFixed(1)} KM',
                                style: TextStyle(
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(hub['alamat'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.person_pin, size: 16, color: Colors.teal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hub['traveler'],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.black45),
                            const SizedBox(width: 6),
                            Text('${hub['status']} • Estimasi: ${hub['estimasiWaktu']}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _bukaNavigasiGoogleMaps(
                                  hub['lat'],
                                  hub['lng'],
                                  hub['nama'],
                                ),
                                icon: const Icon(Icons.navigation_rounded, size: 16),
                                label: const Text('Buka di Google Maps', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal.shade800,
                                side: BorderSide(color: Colors.teal.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                setState(() => _indeksTitikTerpilih = index);
                                LayananNotifikasi.kirimNotifikasi(
                                  context,
                                  judul: 'Titik Temu Terpilih',
                                  pesan: 'Rute diarahkan ke ${hub['nama']}',
                                  ikon: Icons.place,
                                  warna: Colors.teal,
                                );
                              },
                              child: Text(sedangDipilih ? '✓ Aktif' : 'Pilih Rute', style: const TextStyle(fontSize: 11)),
                            ),
                          ],
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
    );
  }
}

// Custom Painter untuk Menggambar Jalur Jalan & Rute ala Google Maps
class _PetaJalanPainter extends CustomPainter {
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
      ..color = const Color(0xFF1A73E8) // Biru Khas Google Maps Route
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Gambar Jalan Raya Utama
    final jalanPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.3);

    canvas.drawPath(jalanPath, paintJalan);
    canvas.drawPath(jalanPath, paintGarisTengah);

    // Jalan Cabang
    final jalanCabang = Path()
      ..moveTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height);
    canvas.drawPath(jalanCabang, paintJalan);

    // Gambar Garis Rute Navigasi Google Maps (Dotted/Solid Blue Path)
    final rutePath = Path()
      ..moveTo(70, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width - 60, size.height * 0.3);

    canvas.drawPath(rutePath, paintRuteGoogleMaps);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
