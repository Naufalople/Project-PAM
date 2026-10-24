import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../layanan/layanan_notifikasi.dart';

/// Halaman LBS (Location Based Service) Titik Temu COD JastipGo:
/// Sesuai TODO_PERUBAHAN_DATABASE.txt:
/// 1. Integrasi Peta Interaktif OpenStreetMap (OSM) via flutter_map & latlong2
/// 2. Pelacakan Nyata GPS HP (Geolocator Stream) & perhitungan jarak dinamis
/// 3. Navigasi Mandiri Langsung di Dalam Aplikasi (In-App Routing) via OSRM API & PolylineLayer
/// 4. Panduan navigasi berarah (turn-by-turn instruction, bearing, sisa jarak, & auto-center)
class HalamanPetaLokasi extends StatefulWidget {
  final int indeksTitikAwal;

  const HalamanPetaLokasi({super.key, this.indeksTitikAwal = 0});

  /// Mengambil titik koordinat rute jalan raya via API perutean OSRM (Open Source Routing Machine)
  /// Format OSRM: https://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=geojson
  static Future<List<LatLng>> ambilRuteOsrm({
    required double latAwal,
    required double lngAwal,
    required double latTujuan,
    required double lngTujuan,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$lngAwal,$latAwal;$lngTujuan,$latTujuan?overview=full&geometries=geojson',
      );
      final response = await httpClient
          .get(url, headers: {'User-Agent': 'JastipGoApp/2.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map &&
            decoded['routes'] is List &&
            (decoded['routes'] as List).isNotEmpty) {
          final route = decoded['routes'][0];
          final geometry = route['geometry'];
          if (geometry is Map && geometry['coordinates'] is List) {
            final List<dynamic> coords = geometry['coordinates'];
            final List<LatLng> points = [];
            for (var c in coords) {
              if (c is List && c.length >= 2) {
                final double lng = (c[0] as num).toDouble();
                final double lat = (c[1] as num).toDouble();
                points.add(LatLng(lat, lng));
              }
            }
            if (points.isNotEmpty) {
              return points;
            }
          }
        }
      }
    } catch (_) {
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // Fallback otomatis ke interpolasi geometris jika OSRM timeout / offline
    return buatTitikInterpolasiRute(
      latAwal: latAwal,
      lngAwal: lngAwal,
      latTujuan: latTujuan,
      lngTujuan: lngTujuan,
    );
  }

  /// Generator titik interpolasi rute panduan in-app (Fail-safe routing fallback)
  static List<LatLng> buatTitikInterpolasiRute({
    required double latAwal,
    required double lngAwal,
    required double latTujuan,
    required double lngTujuan,
    int jumlahTitik = 8,
  }) {
    final List<LatLng> list = [];
    for (int i = 0; i <= jumlahTitik; i++) {
      final double t = i / jumlahTitik;
      final double lat = latAwal + (latTujuan - latAwal) * t;
      final double lng = lngAwal + (lngTujuan - lngAwal) * t;
      list.add(LatLng(lat, lng));
    }
    return list;
  }

  /// Fungsi utilitas statis untuk menghitung jarak garis lurus via Geolocator.distanceBetween
  static double hitungJarakLurusKm({
    required double latAwal,
    required double lngAwal,
    required double latTujuan,
    required double lngTujuan,
  }) {
    final double jarakMeter = Geolocator.distanceBetween(
      latAwal,
      lngAwal,
      latTujuan,
      lngTujuan,
    );
    return jarakMeter / 1000.0;
  }

  /// Format URL Google Maps Navigasi Eksternal (Cadangan Opsional)
  static String buatUrlNavigasiGoogleMaps({
    required double latUser,
    required double lngUser,
    required double latCod,
    required double lngCod,
  }) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$latUser,$lngUser&destination=$latCod,$lngCod';
  }

  @override
  State<HalamanPetaLokasi> createState() => _HalamanPetaLokasiState();
}

class _HalamanPetaLokasiState extends State<HalamanPetaLokasi> with SingleTickerProviderStateMixin {
  Position? _posisiPengguna;
  StreamSubscription<Position>? _langgananPosisi;
  bool _sedangMencariLokasi = false;
  String _statusLokasi = 'Menghubungkan sensor GPS HP...';
  late int _indeksTitikTerpilih;

  // State Navigasi Mandiri In-App (TODO_PERUBAHAN_DATABASE.txt)
  bool _modeNavigasiInApp = false;
  List<LatLng> _titikRuteNavigasi = [];
  bool _sedangMemuatRute = false;
  String _instruksiPanduan = '';

  late AnimationController _animasiPulse;
  final MapController _mapController = MapController();

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
    },
  ];

  @override
  void initState() {
    super.initState();
    _indeksTitikTerpilih = widget.indeksTitikAwal.clamp(0, _daftarTitikTemu.length - 1);
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
    _mapController.dispose();
    super.dispose();
  }

  /// Mengambil Koordinat Nyata GPS HP & Memulai Stream Pemantauan Posisi Real-Time
  Future<void> _mulaiPemantauanGpsRealTime() async {
    setState(() {
      _sedangMencariLokasi = true;
      _statusLokasi = 'Menghubungkan sensor GPS HP...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _terapkanFallbackKoordinat('Layanan GPS nonaktif. Menggunakan koordinat Kampus UPN.');
        return;
      }

      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }

      if (izin == LocationPermission.deniedForever || izin == LocationPermission.denied) {
        _terapkanFallbackKoordinat('Izin lokasi tidak diberikan. Menggunakan koordinat Kampus UPN.');
        return;
      }

      // Ambil posisi terakhir yang tersimpan untuk pemuatan instan
      try {
        final posTerakhir = await Geolocator.getLastKnownPosition();
        if (posTerakhir != null && mounted) {
          setState(() {
            _posisiPengguna = posTerakhir;
            _sedangMencariLokasi = false;
            _statusLokasi = 'GPS Siap • ${posTerakhir.latitude.toStringAsFixed(4)}, ${posTerakhir.longitude.toStringAsFixed(4)}';
          });
        }
      } catch (_) {}

      // Stream posisi berkelanjutan real-time (Geolocator.getPositionStream)
      // DILARANG menggunakan getCurrentPosition() statis sesuai aturan sistem
      _langgananPosisi?.cancel();
      _langgananPosisi = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2, // Update setiap berpindah 2 meter
        ),
      ).listen(
        (posisiBaru) {
          if (!mounted) return;
          // Perbarui koordinat marker posisi pengguna secara real-time
          setState(() {
            _posisiPengguna = posisiBaru;
            _sedangMencariLokasi = false;
            _statusLokasi = 'GPS Live • ${posisiBaru.latitude.toStringAsFixed(5)}, ${posisiBaru.longitude.toStringAsFixed(5)}';

            if (_modeNavigasiInApp) {
              final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
              if (_titikRuteNavigasi.isNotEmpty) {
                _titikRuteNavigasi[0] = LatLng(posisiBaru.latitude, posisiBaru.longitude);
              }
              final double sisaKm = HalamanPetaLokasi.hitungJarakLurusKm(
                latAwal: posisiBaru.latitude,
                lngAwal: posisiBaru.longitude,
                latTujuan: hubTerpilih['lat'],
                lngTujuan: hubTerpilih['lng'],
              );
              _instruksiPanduan = 'Lurus mengikuti rute • Sisa ${sisaKm.toStringAsFixed(1)} KM menuju ${hubTerpilih['nama']}.';
            }
          });

          // Kamera mengikuti pengguna jika mode navigasi in-app aktif
          if (_modeNavigasiInApp) {
            _pusatkanKeLokasi(posisiBaru.latitude, posisiBaru.longitude, zoom: 16.5);
          }
        },
        onError: (err) {
          debugPrint('Info getPositionStream: $err');
          if (_posisiPengguna == null && mounted) {
            _terapkanFallbackKoordinat('Menunggu sinyal GPS... Menggunakan koordinat Kampus UPN.');
          }
        },
      );
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

  /// Hitung Jarak Nyata antara GPS HP dan Titik Temu COD (Geolocator.distanceBetween)
  double _hitungJarakKm(double latTujuan, double lngTujuan) {
    if (_posisiPengguna == null) return 1.5;
    return HalamanPetaLokasi.hitungJarakLurusKm(
      latAwal: _posisiPengguna!.latitude,
      lngAwal: _posisiPengguna!.longitude,
      latTujuan: latTujuan,
      lngTujuan: lngTujuan,
    );
  }

  /// Hitung Sudut Kompas (Bearing) dari Pengguna ke Hub Tujuan
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

  /// Memuat garis rute jalan raya via OSRM API (Navigasi In-App)
  Future<void> _muatRuteNavigasi({bool autoStart = false}) async {
    final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;

    setState(() {
      _sedangMemuatRute = true;
    });

    final rute = await HalamanPetaLokasi.ambilRuteOsrm(
      latAwal: userLat,
      lngAwal: userLng,
      latTujuan: hubTerpilih['lat'],
      lngTujuan: hubTerpilih['lng'],
    );

    if (mounted) {
      setState(() {
        _titikRuteNavigasi = rute;
        _sedangMemuatRute = false;
        if (autoStart) {
          _modeNavigasiInApp = true;
          _instruksiPanduan = 'Ikuti garis panduan rute langsung menuju ${hubTerpilih['nama']}.';
        }
      });
      if (autoStart) {
        _pusatkanKePengguna(zoom: 16.5);
        LayananNotifikasi.kirimNotifikasi(
          context,
          judul: 'Navigasi In-App Dimulai 🧭',
          pesan: 'Mengarahkan perjalanan mandiri di peta aplikasi menuju ${hubTerpilih['nama']}.',
          ikon: Icons.navigation_rounded,
          warna: Colors.teal.shade800,
        );
      }
    }
  }

  /// Mengaktifkan / Menutup Navigasi Mandiri In-App (TODO_PERUBAHAN_DATABASE.txt)
  void _toggleNavigasiInApp() {
    if (_modeNavigasiInApp) {
      setState(() {
        _modeNavigasiInApp = false;
        _instruksiPanduan = '';
      });
      final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
      _pusatkanKeLokasi(hubTerpilih['lat'], hubTerpilih['lng'], zoom: 13.5);
    } else {
      final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
      setState(() {
        _modeNavigasiInApp = true;
        _instruksiPanduan = 'Ikuti garis panduan rute langsung menuju ${hubTerpilih['nama']}.';
      });
      _muatRuteNavigasi(autoStart: true);
    }
  }

  /// Pusatkan kamera peta OSM ke koordinat tertentu secara aman
  void _pusatkanKeLokasi(double lat, double lng, {double zoom = 14.5}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(LatLng(lat, lng), zoom);
      } catch (_) {}
    });
  }

  /// Pusatkan kamera peta OSM ke lokasi GPS pengguna
  void _pusatkanKePengguna({double zoom = 15.0}) {
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;
    _pusatkanKeLokasi(userLat, userLng, zoom: zoom);
  }

  /// Zoom In peta OSM
  void _zoomIn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final currentZoom = _mapController.camera.zoom;
        _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(4.0, 18.0));
      } catch (_) {}
    });
  }

  /// Zoom Out peta OSM
  void _zoomOut() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final currentZoom = _mapController.camera.zoom;
        _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(4.0, 18.0));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final hubTerpilih = _daftarTitikTemu[_indeksTitikTerpilih];
    final double jarakTerpilihKm = _hitungJarakKm(hubTerpilih['lat'], hubTerpilih['lng']);
    final double arahBearing = _hitungArahBearing(hubTerpilih['lat'], hubTerpilih['lng']);
    final double userLat = _posisiPengguna?.latitude ?? -7.7602;
    final double userLng = _posisiPengguna?.longitude ?? 110.4089;

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _sedangMencariLokasi ? Icons.gps_not_fixed : Icons.gps_fixed,
                    size: 18,
                    color: _sedangMencariLokasi ? Colors.orange : Colors.teal.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sensor Lokasi Pengguna (GPS HP):',
                          style: TextStyle(fontSize: 10.5, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _statusLokasi,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _sedangMencariLokasi ? Colors.orange.shade800 : Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_sedangMencariLokasi)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.teal),
                      tooltip: 'Refresh GPS',
                      onPressed: _mulaiPemantauanGpsRealTime,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Banner Panduan Navigasi Langsung di Aplikasi (Muncul saat Navigasi Aktif)
            if (_modeNavigasiInApp)
              Container(
                key: const ValueKey('banner_panduan_navigasi_in_app'),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade900],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.amberAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAVIGASI IN-APP AKTIF 🧭',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _instruksiPanduan.isNotEmpty
                                ? _instruksiPanduan
                                : 'Menuju ${hubTerpilih['nama']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sisa: ${jarakTerpilihKm.toStringAsFixed(1)} KM • Arah ${_terjemahkanArahKompas(arahBearing)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hentikan Navigasi',
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: _toggleNavigasiInApp,
                    ),
                  ],
                ),
              ),

            // ====================================================================
            // WIDGET PETA INTERAKTIF OPENSTREETMAP (OSM)
            // ====================================================================
            Container(
              height: 310,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFE5ECE9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Peta Nyata OSM Menggunakan flutter_map & TileLayer OpenStreetMap
                  FlutterMap(
                    key: const ValueKey('peta_osm_lbs'),
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(userLat, userLng),
                      initialZoom: 13.0,
                      minZoom: 4.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // OpenStreetMap Standard Tile Layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.jastipgo.app',
                        maxZoom: 19,
                      ),

                      // Layer Garis Panduan Rute In-App OSRM (TODO_PERUBAHAN_DATABASE.txt)
                      if (_modeNavigasiInApp || _titikRuteNavigasi.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _titikRuteNavigasi.isNotEmpty
                                  ? _titikRuteNavigasi
                                  : [
                                      LatLng(userLat, userLng),
                                      LatLng(hubTerpilih['lat'], hubTerpilih['lng']),
                                    ],
                              strokeWidth: 5.0,
                              color: Colors.teal.shade700,
                              borderColor: Colors.teal.shade900,
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),

                      // Marker Layer: Lokasi Pengguna & Titik COD Terpilih
                      MarkerLayer(
                        markers: [
                          // Marker A: Lokasi Pengguna Real-Time (GPS HP Live Pulse)
                          Marker(
                            key: const ValueKey('marker_pengguna_lbs'),
                            point: LatLng(userLat, userLng),
                            width: 90,
                            height: 70,
                            child: AnimatedBuilder(
                              animation: _animasiPulse,
                              builder: (context, child) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade900,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                                        ],
                                      ),
                                      child: const Text(
                                        'Lokasi Anda',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(alpha: 0.3 + (_animasiPulse.value * 0.4)),
                                            blurRadius: 8 + (_animasiPulse.value * 6),
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Transform.rotate(
                                        angle: arahBearing * (math.pi / 180),
                                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Marker B: Titik Lokasi COD / Serah Terima yang Dipilih
                          Marker(
                            key: const ValueKey('marker_titik_cod'),
                            point: LatLng(hubTerpilih['lat'], hubTerpilih['lng']),
                            width: 140,
                            height: 75,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade900,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                                    ],
                                  ),
                                  child: Text(
                                    hubTerpilih['nama'].toString().split(' ').take(3).join(' '),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Overlay Atas: Badge OpenStreetMap (OSM) & Kontrol Zoom
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade900.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 14, color: Colors.amberAccent),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'OpenStreetMap (OSM) Interaktif',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Kontrol Zoom In / Zoom Out / Reset Kamera
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _zoomIn,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.add, size: 16, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _zoomOut,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.remove, size: 16, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _pusatkanKePengguna,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.my_location, size: 16, color: Colors.teal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Overlay Bawah: Arah Kompas & Jarak Langsung
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.explore_rounded, size: 14, color: Colors.teal),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${jarakTerpilihKm.toStringAsFixed(1)} KM • ${_terjemahkanArahKompas(arahBearing)}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pin_drop, size: 12, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(
                                _modeNavigasiInApp ? 'Navigasi OSRM Aktif' : '2 Marker (OSM LBS)',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ====================================================================
            // KARTU PERHITUNGAN JARAK LURUS LBS (Geolocator.distanceBetween)
            // ====================================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.straighten_rounded, color: Colors.teal.shade800, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jarak ke titik temu: ${jarakTerpilihKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dihitung via GPS • Arah ${_terjemahkanArahKompas(arahBearing)} • Estimasi ${hubTerpilih['estimasiWaktu']}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ====================================================================
            // TOMBOL UTAMA: NAVIGASI MANDIRI LANGSUNG DI DALAM APLIKASI (IN-APP ROUTING)
            // Sesuai TODO_PERUBAHAN_DATABASE.txt: Navigasi bergerak mandiri di peta internal
            // ====================================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                key: const ValueKey('tombol_navigasi_in_app'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _modeNavigasiInApp ? Colors.red.shade700 : Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _toggleNavigasiInApp,
                icon: _sedangMemuatRute
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        _modeNavigasiInApp ? Icons.stop_circle_rounded : Icons.navigation_rounded,
                        size: 22,
                        color: Colors.amberAccent,
                      ),
                label: Text(
                  _modeNavigasiInApp ? 'Hentikan Navigasi' : 'Mulai Navigasi Langsung di Aplikasi',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // DAFTAR PILIHAN HUB LOKASI TITIK TEMU COD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Titik Temu COD:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                Text(
                  '${_daftarTitikTemu.length} Hub Tersedia',
                  style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Kartu Pilihan Hub Titik Temu COD
            Column(
              children: List.generate(_daftarTitikTemu.length, (index) {
                final hub = _daftarTitikTemu[index];
                final bool terpilih = index == _indeksTitikTerpilih;
                final double jarakKm = _hitungJarakKm(hub['lat'], hub['lng']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: terpilih ? Colors.teal.shade700 : Colors.grey.shade200,
                      width: terpilih ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: terpilih ? 0.06 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _indeksTitikTerpilih = index;
                      });
                      if (_modeNavigasiInApp) {
                        _muatRuteNavigasi(autoStart: true);
                      } else {
                        _pusatkanKeLokasi(hub['lat'], hub['lng']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: terpilih ? Colors.teal.shade50 : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              terpilih ? Icons.location_on : Icons.location_on_outlined,
                              color: terpilih ? Colors.teal.shade800 : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hub['nama'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: terpilih ? Colors.teal.shade900 : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (terpilih)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade700,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'TERPILIH',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hub['alamat'],
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.directions_car, size: 13, color: Colors.teal.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${jarakKm.toStringAsFixed(1)} KM dari posisi Anda',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      hub['estimasiWaktu'],
                                      style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // RINCIAN HUB & TRAVELER YANG BERTUGAS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: Colors.teal.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Serah Terima Hub:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  _bangunBarisInfo(Icons.person_pin_rounded, 'Traveler Bertugas', hubTerpilih['traveler']),
                  const SizedBox(height: 8),
                  _bangunBarisInfo(Icons.schedule_rounded, 'Jam Operasional', hubTerpilih['status']),
                  const SizedBox(height: 8),
                  _bangunBarisInfo(Icons.phone_in_talk_rounded, 'Kontak Petugas', hubTerpilih['telepon']),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade800,
                            side: BorderSide(color: Colors.teal.shade600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final Uri phoneUri = Uri.parse('tel:${hubTerpilih['telepon']}');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          },
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Hubungi Petugas Hub', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _bangunBarisInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
