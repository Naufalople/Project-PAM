import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman LBS (Location Based Service): Titik Temu COD & Pos Penyerahan Jastip Terdekat
class HalamanPetaLokasi extends StatefulWidget {
  const HalamanPetaLokasi({super.key});

  @override
  State<HalamanPetaLokasi> createState() => _HalamanPetaLokasiState();
}

class _HalamanPetaLokasiState extends State<HalamanPetaLokasi> {
  Position? _posisiPengguna;
  bool _sedangMencariLokasi = false;
  String _statusLokasi = 'Menunggu deteksi sinyal GPS...';

  // Daftar Titik Temu / Cabang Hub Traveler JastipGo
  final List<Map<String, dynamic>> _daftarTitikTemu = [
    {
      'nama': 'Hub JastipGo UPN Veteran Yogyakarta',
      'alamat': 'Jl. SWK 104 Condongcatur, Sleman, D.I. Yogyakarta',
      'lat': -7.7602,
      'lng': 110.4089,
      'traveler': 'Mas Dimas (Baru landing dari Tokyo)',
      'status': 'Buka (08:00 - 20:00 WIB)',
      'telepon': '081234567890',
    },
    {
      'nama': 'Pick-up Hub Bandara YIA (Kulon Progo)',
      'alamat': 'Terminal Kedatangan Internasional YIA, Yogyakarta',
      'lat': -7.9029,
      'lng': 110.0573,
      'traveler': 'Mbak Sarah (Baru landing dari London Heathrow)',
      'status': 'Buka 24 Jam',
      'telepon': '082198765432',
    },
    {
      'nama': 'Hub Drop-Off Malioboro Center',
      'alamat': 'Kawasan Malioboro No. 45, Danurejan, Yogyakarta',
      'lat': -7.7928,
      'lng': 110.3658,
      'traveler': 'Kak Rian (Baru landing dari Seoul Incheon)',
      'status': 'Buka (10:00 - 22:00 WIB)',
      'telepon': '081377889900',
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
          _statusLokasi = 'Izin lokasi ditolak permanen. Gunakan lokasi simulasi Kampus UPN.';
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
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('LBS: Titik Temu COD'),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Penjelasan Fitur LBS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.near_me_rounded, color: Colors.teal.shade800, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Location Based Service (LBS):\nAplikasi mendeteksi posisi GPS Anda dan menampilkan pos pengambilan barang titipan (*Pick-Up Hub*) terdekat untuk serah terima barang langsung.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kartu Status GPS Pengguna
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.redAccent.shade700, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Posisi Koordinat Anda Saat Ini:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      if (_sedangMencariLokasi)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _posisiPengguna != null
                        ? 'Latitude: ${_posisiPengguna!.latitude.toStringAsFixed(5)}, Longitude: ${_posisiPengguna!.longitude.toStringAsFixed(5)}'
                        : 'Mendeteksi satelit GPS...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_statusLokasi, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Daftar Pos Pengambilan Terdekat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _daftarTitikTemu.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final hub = _daftarTitikTemu[index];
                final jarak = _hitungJarakKm(hub['lat'], hub['lng']);

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      const Divider(height: 20),
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
                          const Icon(Icons.access_time, size: 16, color: Colors.black45),
                          const SizedBox(width: 6),
                          Text(hub['status'], style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade800,
                            side: BorderSide(color: Colors.teal.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            LayananNotifikasi.kirimNotifikasi(
                              context,
                              judul: 'Titik Temu Terpilih',
                              pesan: 'Anda memilih penyerahan barang di ${hub['nama']}',
                              ikon: Icons.place,
                              warna: Colors.teal,
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Pilih Titik Temu Ini'),
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
