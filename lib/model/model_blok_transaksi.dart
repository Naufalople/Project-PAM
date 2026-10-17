import 'dart:convert';
import 'package:crypto/crypto.dart';

// Model Blok untuk Rantai Blok (Blockchain) Bukti Transaksi Jastip
class ModelBlokTransaksi {
  final int indeks;
  final String waktuStempel;
  final Map<String, dynamic> dataTransaksi;
  final String hashSebelumnya;
  final String hash;

  ModelBlokTransaksi({
    required this.indeks,
    required this.waktuStempel,
    required this.dataTransaksi,
    required this.hashSebelumnya,
    required this.hash,
  });

  // Fungsi untuk menghitung hash SHA-256 dari elemen blok
  static String hitungHash({
    required int indeks,
    required String waktuStempel,
    required Map<String, dynamic> dataTransaksi,
    required String hashSebelumnya,
  }) {
    final String dataMentah =
        '$indeks-$waktuStempel-${jsonEncode(dataTransaksi)}-$hashSebelumnya';
    final List<int> bytes = utf8.encode(dataMentah);
    return sha256.convert(bytes).toString();
  }

  // Buat Blok Baru dengan Hash Terhitung
  factory ModelBlokTransaksi.buatBlokBaru({
    required int indeks,
    required Map<String, dynamic> dataTransaksi,
    required String hashSebelumnya,
  }) {
    final String waktu = DateTime.now().toIso8601String();
    final String hashDihasilkan = hitungHash(
      indeks: indeks,
      waktuStempel: waktu,
      dataTransaksi: dataTransaksi,
      hashSebelumnya: hashSebelumnya,
    );

    return ModelBlokTransaksi(
      indeks: indeks,
      waktuStempel: waktu,
      dataTransaksi: dataTransaksi,
      hashSebelumnya: hashSebelumnya,
      hash: hashDihasilkan,
    );
  }

  // Konversi dari Map (untuk penyimpanan Hive/Lokal)
  factory ModelBlokTransaksi.dariMap(Map<dynamic, dynamic> map) {
    return ModelBlokTransaksi(
      indeks: map['indeks'] as int? ?? 0,
      waktuStempel: map['waktuStempel'] as String? ?? '',
      dataTransaksi: Map<String, dynamic>.from(map['dataTransaksi'] ?? {}),
      hashSebelumnya: map['hashSebelumnya'] as String? ?? '',
      hash: map['hash'] as String? ?? '',
    );
  }

  // Konversi ke Map
  Map<String, dynamic> keMap() {
    return {
      'indeks': indeks,
      'waktuStempel': waktuStempel,
      'dataTransaksi': dataTransaksi,
      'hashSebelumnya': hashSebelumnya,
      'hash': hash,
    };
  }
}
