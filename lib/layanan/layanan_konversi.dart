import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Layanan Konversi Waktu Dunia (WIB, WITA, WIT, London) dan Kurs Mata Uang Asing
class LayananKonversi {
  // ==========================================
  // 1. FITUR KONVERSI ZONA WAKTU DUNIA
  // ==========================================

  // Mendapatkan waktu saat ini berdasarkan zona waktu
  // Offset jam relatif terhadap UTC:
  // London: UTC+1 (BST) / UTC+0 (GMT)
  // WIB: UTC+7
  // WITA: UTC+8
  // WIT: UTC+9
  // Tokyo (JST): UTC+9
  // Seoul (KST): UTC+9
  static Map<String, String> ambilDaftarZonaWaktu() {
    final DateTime sekarangUtc = DateTime.now().toUtc();
    final DateFormat formatWaktu = DateFormat('HH:mm:ss');
    final DateFormat formatTanggal = DateFormat('EEE, dd MMM yyyy');

    DateTime waktuLondon = sekarangUtc.add(const Duration(hours: 1)); // BST
    DateTime waktuWib = sekarangUtc.add(const Duration(hours: 7));
    DateTime waktuWita = sekarangUtc.add(const Duration(hours: 8));
    DateTime waktuWit = sekarangUtc.add(const Duration(hours: 9));
    DateTime waktuTokyo = sekarangUtc.add(const Duration(hours: 9));
    DateTime waktuSeoul = sekarangUtc.add(const Duration(hours: 9));

    return {
      'WIB': '${formatWaktu.format(waktuWib)} (${formatTanggal.format(waktuWib)})',
      'WITA': '${formatWaktu.format(waktuWita)} (${formatTanggal.format(waktuWita)})',
      'WIT': '${formatWaktu.format(waktuWit)} (${formatTanggal.format(waktuWit)})',
      'London': '${formatWaktu.format(waktuLondon)} (${formatTanggal.format(waktuLondon)})',
      'Tokyo': '${formatWaktu.format(waktuTokyo)} (${formatTanggal.format(waktuTokyo)})',
      'Seoul': '${formatWaktu.format(waktuSeoul)} (${formatTanggal.format(waktuSeoul)})',
    };
  }

  // Cek apakah toko di London sedang buka (Asumsi jam operasional 09:00 - 18:00 waktu London)
  static bool apakahTokoLondonBuka() {
    final DateTime sekarangUtc = DateTime.now().toUtc();
    final DateTime waktuLondon = sekarangUtc.add(const Duration(hours: 1));
    return waktuLondon.hour >= 9 && waktuLondon.hour < 18;
  }

  // ==========================================
  // 2. FITUR KONVERSI KURS MATA UANG (VALAS KE RUPIAH)
  // ==========================================

  static const String _kunciCacheKurs = 'cache_kurs_valas_ke_rupiah';
  static const String _kunciWaktuUpdateKurs = 'waktu_terakhir_update_kurs';
  static String? waktuPembaruanTerakhir;
  static bool statusOnlineTerhubung = false;

  // Nilai tukar patokan (diperbarui otomatis dari REST API open.er-api.com)
  static final Map<String, double> nilaiKursKeRupiah = {
    'IDR': 1.0,
    'JPY': 114.3, // 1 Yen = Rp 114.3
    'KRW': 11.8, // 1 Won = Rp 11.8
    'GBP': 24060.0, // 1 Pound London = Rp 24.060
    'USD': 18052.0, // 1 Dollar AS = Rp 18.052
    'SGD': 14109.0, // 1 Dollar Singapura = Rp 14.109
    'CNY': 2230.0, // 1 Yuan China = Rp 2.230
  };

  // Mengambil dan memperbarui data kurs mata uang asing secara live dari REST API Publik (open.er-api.com)
  static Future<bool> perbaruiKursDariApi() async {
    const String urlApi = 'https://open.er-api.com/v6/latest/USD';
    try {
      final response = await http.get(Uri.parse(urlApi)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final Map<String, dynamic> rates = data['rates'];
          final double idrPerUsd = (rates['IDR'] as num?)?.toDouble() ?? 15800.0;

          nilaiKursKeRupiah['IDR'] = 1.0;
          nilaiKursKeRupiah['USD'] = idrPerUsd;

          if (rates['JPY'] != null && (rates['JPY'] as num) > 0) {
            nilaiKursKeRupiah['JPY'] = idrPerUsd / (rates['JPY'] as num).toDouble();
          }
          if (rates['KRW'] != null && (rates['KRW'] as num) > 0) {
            nilaiKursKeRupiah['KRW'] = idrPerUsd / (rates['KRW'] as num).toDouble();
          }
          if (rates['GBP'] != null && (rates['GBP'] as num) > 0) {
            nilaiKursKeRupiah['GBP'] = idrPerUsd / (rates['GBP'] as num).toDouble();
          }
          if (rates['SGD'] != null && (rates['SGD'] as num) > 0) {
            nilaiKursKeRupiah['SGD'] = idrPerUsd / (rates['SGD'] as num).toDouble();
          }
          if (rates['CNY'] != null && (rates['CNY'] as num) > 0) {
            nilaiKursKeRupiah['CNY'] = idrPerUsd / (rates['CNY'] as num).toDouble();
          }

          statusOnlineTerhubung = true;
          waktuPembaruanTerakhir = DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());

          // Simpan ke SharedPreferences sebagai cache offline
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kunciCacheKurs, jsonEncode(nilaiKursKeRupiah));
          await prefs.setString(_kunciWaktuUpdateKurs, waktuPembaruanTerakhir!);

          return true;
        }
      }
    } catch (_) {
      // Fallback offline: muat dari cache lokal jika pernah disimpan sebelumnya
      await _muatCacheKursLokal();
      statusOnlineTerhubung = false;
    }
    return false;
  }

  static Future<void> _muatCacheKursLokal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cache = prefs.getString(_kunciCacheKurs);
      waktuPembaruanTerakhir = prefs.getString(_kunciWaktuUpdateKurs);
      if (cache != null && cache.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cache);
        decoded.forEach((key, val) {
          if (val is num) {
            nilaiKursKeRupiah[key] = val.toDouble();
          }
        });
      }
    } catch (_) {}
  }

  // Konversi dari mata uang asing ke Rupiah (IDR)
  static int konversiKeRupiah(double jumlahMataUangAsing, String kodeMataUang) {
    final double kurs = nilaiKursKeRupiah[kodeMataUang] ?? 1.0;
    return (jumlahMataUangAsing * kurs).round();
  }

  // Konversi dari Rupiah (IDR) ke mata uang asing
  static double konversiDariRupiah(int jumlahRupiah, String kodeMataUangTujuan) {
    final double kurs = nilaiKursKeRupiah[kodeMataUangTujuan] ?? 1.0;
    if (kurs <= 0) return 0.0;
    return jumlahRupiah / kurs;
  }

  // Format angka ke mata uang Rupiah
  static String formatRupiah(int nominal) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(nominal);
  }

  // Format angka ke mata uang Asing
  static String formatMataUangAsing(double nominal, String kodeMataUang) {
    return '$kodeMataUang ${nominal.toStringAsFixed(nominal.truncateToDouble() == nominal ? 0 : 2)}';
  }
}
