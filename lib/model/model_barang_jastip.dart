// Model data untuk Barang Titipan Jastip
class ModelBarangJastip {
  final int id;
  final String namaBarang;
  final String kategori; // Fashion, Skincare, Kuliner, Elektronik, Anime
  final String negara; // Jepang, Korea, London, Singapura
  final String benderaNegara; // 🇯🇵, 🇰🇷, 🇬🇧, 🇸🇬
  final String kodeMataUang; // JPY, KRW, GBP, SGD, USD
  final double hargaAsli;
  final int estimasiHargaIdr;
  final String fotoUrl;
  final String deskripsi;
  final String namaToko;
  final String batasWaktuPo; // Waktu penutupan PO
  final double rating;
  int jumlahPeminat;

  ModelBarangJastip({
    required this.id,
    required this.namaBarang,
    required this.kategori,
    required this.negara,
    required this.benderaNegara,
    required this.kodeMataUang,
    required this.hargaAsli,
    required this.estimasiHargaIdr,
    required this.fotoUrl,
    required this.deskripsi,
    required this.namaToko,
    required this.batasWaktuPo,
    required this.rating,
    required this.jumlahPeminat,
  });

  // Konversi dari JSON ke Objek Barang Jastip
  factory ModelBarangJastip.dariJson(Map<String, dynamic> json) {
    return ModelBarangJastip(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaBarang: json['namaBarang'] ?? '',
      kategori: json['kategori'] ?? '',
      negara: json['negara'] ?? '',
      benderaNegara: json['benderaNegara'] ?? '🌏',
      kodeMataUang: json['kodeMataUang'] ?? 'IDR',
      hargaAsli: (json['hargaAsli'] as num?)?.toDouble() ?? 0.0,
      estimasiHargaIdr: (json['estimasiHargaIdr'] as num?)?.toInt() ?? 0,
      fotoUrl: json['fotoUrl'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      namaToko: json['namaToko'] ?? '',
      batasWaktuPo: json['batasWaktuPo'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      jumlahPeminat: (json['jumlahPeminat'] as num?)?.toInt() ?? 0,
    );
  }

  // Konversi Objek Barang ke Map / JSON
  Map<String, dynamic> keJson() {
    return {
      'id': id,
      'namaBarang': namaBarang,
      'kategori': kategori,
      'negara': negara,
      'benderaNegara': benderaNegara,
      'kodeMataUang': kodeMataUang,
      'hargaAsli': hargaAsli,
      'estimasiHargaIdr': estimasiHargaIdr,
      'fotoUrl': fotoUrl,
      'deskripsi': deskripsi,
      'namaToko': namaToko,
      'batasWaktuPo': batasWaktuPo,
      'rating': rating,
      'jumlahPeminat': jumlahPeminat,
    };
  }
}
