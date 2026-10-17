// Model data untuk Item di dalam Pesanan Jastip
class ModelItemPesanan {
  final String namaBarang;
  final String fotoUrl;
  final String negara;
  final String namaToko;
  final int jumlah;
  final int hargaIdr;

  ModelItemPesanan({
    required this.namaBarang,
    required this.fotoUrl,
    required this.negara,
    required this.namaToko,
    required this.jumlah,
    required this.hargaIdr,
  });

  factory ModelItemPesanan.dariMap(Map<dynamic, dynamic> map) {
    return ModelItemPesanan(
      namaBarang: map['namaBarang'] as String? ?? '',
      fotoUrl: map['fotoUrl'] as String? ?? '',
      negara: map['negara'] as String? ?? '',
      namaToko: map['namaToko'] as String? ?? '',
      jumlah: (map['jumlah'] as num?)?.toInt() ?? 1,
      hargaIdr: (map['hargaIdr'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> keMap() {
    return {
      'namaBarang': namaBarang,
      'fotoUrl': fotoUrl,
      'negara': negara,
      'namaToko': namaToko,
      'jumlah': jumlah,
      'hargaIdr': hargaIdr,
    };
  }
}

// Model data untuk Pesanan Jastip Lengkap (Disimpan di Hive)
class ModelPesananJastip {
  final String idPesanan;
  final DateTime tanggal;
  final String negaraAsal;
  final String namaTraveler;
  String lokasiTerkini;
  int tahapStatus; // 1: Rekber Ditahan, 2: Di-ACC, 3: Sudah Dibeli, 4: Penerbangan, 5: Tiba di RI, 6: Selesai
  String metodePenyerahan; // 'COD_LBS' atau 'KURIR_ANTAR'
  String alamatPengiriman;
  final int totalHargaIdr;
  final List<ModelItemPesanan> daftarBarang;

  ModelPesananJastip({
    required this.idPesanan,
    required this.tanggal,
    required this.negaraAsal,
    required this.namaTraveler,
    required this.lokasiTerkini,
    this.tahapStatus = 1,
    this.metodePenyerahan = 'COD_LBS',
    this.alamatPengiriman = 'Hub Kampus UPN Veteran Yogyakarta (Titik Temu LBS)',
    required this.totalHargaIdr,
    required this.daftarBarang,
  });

  factory ModelPesananJastip.dariMap(Map<dynamic, dynamic> map) {
    final listRaw = map['daftarBarang'] as List<dynamic>? ?? [];
    final List<ModelItemPesanan> barangList = listRaw
        .whereType<Map>()
        .map((e) => ModelItemPesanan.dariMap(e))
        .toList();

    return ModelPesananJastip(
      idPesanan: map['idPesanan'] as String? ?? 'PO-JSTP-000000',
      tanggal: map['tanggal'] != null
          ? DateTime.parse(map['tanggal'] as String)
          : DateTime.now(),
      negaraAsal: map['negaraAsal'] as String? ?? 'Jepang 🇯🇵',
      namaTraveler: map['namaTraveler'] as String? ?? 'Dimas Pratama',
      lokasiTerkini: map['lokasiTerkini'] as String? ?? 'Luar Negeri',
      tahapStatus: (map['tahapStatus'] as num?)?.toInt() ?? 1,
      metodePenyerahan: map['metodePenyerahan'] as String? ?? 'COD_LBS',
      alamatPengiriman: map['alamatPengiriman'] as String? ?? 'Hub Kampus UPN Veteran Yogyakarta (Titik Temu LBS)',
      totalHargaIdr: (map['totalHargaIdr'] as num?)?.toInt() ?? 0,
      daftarBarang: barangList,
    );
  }

  Map<String, dynamic> keMap() {
    return {
      'idPesanan': idPesanan,
      'tanggal': tanggal.toIso8601String(),
      'negaraAsal': negaraAsal,
      'namaTraveler': namaTraveler,
      'lokasiTerkini': lokasiTerkini,
      'tahapStatus': tahapStatus,
      'metodePenyerahan': metodePenyerahan,
      'alamatPengiriman': alamatPengiriman,
      'totalHargaIdr': totalHargaIdr,
      'daftarBarang': daftarBarang.map((b) => b.keMap()).toList(),
    };
  }
}
