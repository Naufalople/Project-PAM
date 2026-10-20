/// Model Riwayat Penarikan Dana (Withdrawal) Saldo Aktif Traveler
class ModelPenarikanDana {
  final String id;
  final DateTime tanggal;
  final int jumlahIdr;
  final String namaBank;
  final String nomorRekening;
  final String namaPemilik;
  final String status;
  final String? namaTraveler;

  ModelPenarikanDana({
    required this.id,
    required this.tanggal,
    required this.jumlahIdr,
    required this.namaBank,
    required this.nomorRekening,
    required this.namaPemilik,
    this.status = 'BERHASIL',
    this.namaTraveler,
  });

  Map<String, dynamic> keMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'jumlahIdr': jumlahIdr,
      'namaBank': namaBank,
      'nomorRekening': nomorRekening,
      'namaPemilik': namaPemilik,
      'status': status,
      'namaTraveler': namaTraveler,
    };
  }

  factory ModelPenarikanDana.dariMap(Map<dynamic, dynamic> map) {
    return ModelPenarikanDana(
      id: map['id']?.toString() ?? '',
      tanggal: DateTime.tryParse(map['tanggal']?.toString() ?? '') ?? DateTime.now(),
      jumlahIdr: (map['jumlahIdr'] as num?)?.toInt() ?? 0,
      namaBank: map['namaBank']?.toString() ?? 'BCA',
      nomorRekening: map['nomorRekening']?.toString() ?? '',
      namaPemilik: map['namaPemilik']?.toString() ?? '',
      status: map['status']?.toString() ?? 'BERHASIL',
      namaTraveler: map['namaTraveler']?.toString(),
    );
  }
}

/// Hasil Validasi Penarikan Saldo Traveler (Proteksi Rekber Escrow)
class HasilPenarikanDana {
  final bool berhasil;
  final String pesan;
  final int saldoTertahan;
  final int saldoAktif;

  HasilPenarikanDana({
    required this.berhasil,
    required this.pesan,
    this.saldoTertahan = 0,
    this.saldoAktif = 0,
  });
}
