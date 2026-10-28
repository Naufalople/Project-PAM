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
  // Nilai Konstanta Tahap Status Pesanan
  static const int statusDibatalkan = 0;
  static const int statusRekberDitahan = 1;
  static const int statusDiAcc = 2;
  static const int statusSudahDibeli = 3;
  static const int statusPenerbangan = 4;
  static const int statusTibaDiRi = 5;
  static const int statusSelesai = 6;

  final String idPesanan;
  final String? userId; // ID Unik akun pengguna pembuat pesanan
  final String? emailPemesan; // Email akun pemesan untuk isolasi pelacakan
  final String? namaPemesan;
  final String? nomorTeleponPemesan;
  final DateTime tanggal;
  final String negaraAsal;
  final String namaTraveler;
  final String? nomorTeleponTraveler;
  String lokasiTerkini;
  int tahapStatus; // 0: Dibatalkan, 1: Rekber Ditahan, 2: Di-ACC, 3: Sudah Dibeli, 4: Penerbangan, 5: Tiba di RI, 6: Selesai
  String metodePenyerahan; // 'COD_LBS' atau 'KURIR_ANTAR'
  String alamatPengiriman;
  final int totalHargaIdr;
  final List<ModelItemPesanan> daftarBarang;
  String? alasanPembatalan;

  // Kategori Status Penerimaan Pesanan (TODO_MANAJEMEN_PESANAN.txt)
  bool get apakahDibatalkan => tahapStatus == statusDibatalkan;
  bool get apakahSudahDiterima => tahapStatus >= statusSelesai;
  bool get apakahBelumDiterima => tahapStatus >= statusRekberDitahan && tahapStatus < statusSelesai;

  ModelPesananJastip({
    required this.idPesanan,
    this.userId,
    this.emailPemesan,
    this.namaPemesan,
    this.nomorTeleponPemesan,
    required this.tanggal,
    required this.negaraAsal,
    required this.namaTraveler,
    this.nomorTeleponTraveler,
    required this.lokasiTerkini,
    this.tahapStatus = 1,
    this.metodePenyerahan = 'COD_LBS',
    this.alamatPengiriman = 'Hub Kampus UPN Veteran Yogyakarta (Titik Temu LBS)',
    required this.totalHargaIdr,
    required this.daftarBarang,
    this.alasanPembatalan,
  });

  factory ModelPesananJastip.dariMap(Map<dynamic, dynamic> map) {
    final listRaw = map['daftarBarang'] as List<dynamic>? ?? [];
    final List<ModelItemPesanan> barangList = listRaw
        .whereType<Map>()
        .map((e) => ModelItemPesanan.dariMap(e))
        .toList();

    return ModelPesananJastip(
      idPesanan: map['idPesanan'] as String? ?? 'PO-JSTP-000000',
      userId: map['userId']?.toString(),
      emailPemesan: map['emailPemesan']?.toString(),
      namaPemesan: map['namaPemesan']?.toString(),
      nomorTeleponPemesan: map['nomorTeleponPemesan'] as String? ??
          map['teleponPemesan'] as String? ??
          '0812-3456-7890',
      tanggal: map['tanggal'] != null
          ? DateTime.parse(map['tanggal'] as String)
          : DateTime.now(),
      negaraAsal: map['negaraAsal'] as String? ?? 'Jepang 🇯🇵',
      namaTraveler: map['namaTraveler'] as String? ?? 'Dimas Pratama',
      nomorTeleponTraveler: map['nomorTeleponTraveler'] as String? ??
          map['teleponTraveler'] as String? ??
          '0819-8765-4321',
      lokasiTerkini: map['lokasiTerkini'] as String? ?? 'Luar Negeri',
      tahapStatus: (map['tahapStatus'] as num?)?.toInt() ?? 1,
      metodePenyerahan: map['metodePenyerahan'] as String? ?? 'COD_LBS',
      alamatPengiriman: map['alamatPengiriman'] as String? ?? 'Hub Kampus UPN Veteran Yogyakarta (Titik Temu LBS)',
      totalHargaIdr: (map['totalHargaIdr'] as num?)?.toInt() ?? 0,
      daftarBarang: barangList,
      alasanPembatalan: map['alasanPembatalan']?.toString(),
    );
  }

  Map<String, dynamic> keMap() {
    return {
      'idPesanan': idPesanan,
      if (userId != null) 'userId': userId,
      if (emailPemesan != null) 'emailPemesan': emailPemesan,
      if (namaPemesan != null) 'namaPemesan': namaPemesan,
      if (nomorTeleponPemesan != null) 'nomorTeleponPemesan': nomorTeleponPemesan,
      'tanggal': tanggal.toIso8601String(),
      'negaraAsal': negaraAsal,
      'namaTraveler': namaTraveler,
      if (nomorTeleponTraveler != null) 'nomorTeleponTraveler': nomorTeleponTraveler,
      'lokasiTerkini': lokasiTerkini,
      'tahapStatus': tahapStatus,
      'metodePenyerahan': metodePenyerahan,
      'alamatPengiriman': alamatPengiriman,
      'totalHargaIdr': totalHargaIdr,
      'daftarBarang': daftarBarang.map((b) => b.keMap()).toList(),
      if (alasanPembatalan != null) 'alasanPembatalan': alasanPembatalan,
    };
  }
}
