// Model data untuk Item Keranjang Belanja Titipan (Disimpan di Hive)
class ModelKeranjang {
  final int idBarang;
  final String namaBarang;
  final String negara;
  final String kodeMataUang;
  final double hargaAsli;
  final int hargaIdr;
  int jumlah;
  final String fotoUrl;
  final String catatanKhusus;

  ModelKeranjang({
    required this.idBarang,
    required this.namaBarang,
    required this.negara,
    required this.kodeMataUang,
    required this.hargaAsli,
    required this.hargaIdr,
    required this.jumlah,
    required this.fotoUrl,
    this.catatanKhusus = '',
  });

  // Hitung total harga item (harga satuan * jumlah)
  int get totalHargaIdr => hargaIdr * jumlah;

  // Konversi dari Map (untuk Hive)
  factory ModelKeranjang.dariMap(Map<dynamic, dynamic> map) {
    return ModelKeranjang(
      idBarang: map['idBarang'] as int? ?? 0,
      namaBarang: map['namaBarang'] as String? ?? '',
      negara: map['negara'] as String? ?? '',
      kodeMataUang: map['kodeMataUang'] as String? ?? 'IDR',
      hargaAsli: (map['hargaAsli'] as num?)?.toDouble() ?? 0.0,
      hargaIdr: (map['hargaIdr'] as num?)?.toInt() ?? 0,
      jumlah: (map['jumlah'] as num?)?.toInt() ?? 1,
      fotoUrl: map['fotoUrl'] as String? ?? '',
      catatanKhusus: map['catatanKhusus'] as String? ?? '',
    );
  }

  // Konversi ke Map (untuk disimpan ke Hive Box)
  Map<String, dynamic> keMap() {
    return {
      'idBarang': idBarang,
      'namaBarang': namaBarang,
      'negara': negara,
      'kodeMataUang': kodeMataUang,
      'hargaAsli': hargaAsli,
      'hargaIdr': hargaIdr,
      'jumlah': jumlah,
      'fotoUrl': fotoUrl,
      'catatanKhusus': catatanKhusus,
    };
  }
}
