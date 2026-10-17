import 'package:intl/intl.dart';

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

  // Nilai tukar patokan standar (Kurs Referensi Bank)
  static final Map<String, double> nilaiKursKeRupiah = {
    'IDR': 1.0,
    'JPY': 112.5, // 1 Yen = Rp 112.5
    'KRW': 11.8, // 1 Won = Rp 11.8
    'GBP': 20600.0, // 1 Pound London = Rp 20.600
    'USD': 15800.0, // 1 Dollar AS = Rp 15.800
    'SGD': 11950.0, // 1 Dollar Singapura = Rp 11.950
    'CNY': 2230.0, // 1 Yuan China = Rp 2.230
  };

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
