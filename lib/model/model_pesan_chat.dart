// Model data untuk Pesan Percakapan Langsung Antara Pemesan dan Traveler
class ModelPesanChat {
  final String id;
  final String teks;
  final bool adalahPengguna;
  final String pengirim; // 'PEMESAN' atau 'TRAVELER'
  final String namaPengirim;
  final DateTime waktu;
  final String idPemesan; // Identifikasi thread pemesan (email atau id akun)
  final String namaPemesan;
  final String? idPesanan; // ID Pesanan titipan terkait

  ModelPesanChat({
    required this.id,
    required this.teks,
    this.adalahPengguna = true,
    this.pengirim = 'PEMESAN',
    this.namaPengirim = 'Pemesan',
    required this.waktu,
    this.idPemesan = 'pemesan@jastipgo.com',
    this.namaPemesan = 'Pemesan Jastip',
    this.idPesanan,
  });

  factory ModelPesanChat.dariMap(Map<dynamic, dynamic> map) {
    return ModelPesanChat(
      id: map['id']?.toString() ?? '',
      teks: map['teks']?.toString() ?? '',
      adalahPengguna: map['adalahPengguna'] == true,
      pengirim: map['pengirim']?.toString() ?? 'PEMESAN',
      namaPengirim: map['namaPengirim']?.toString() ?? 'Pengguna',
      waktu: map['waktu'] != null
          ? DateTime.tryParse(map['waktu'].toString()) ?? DateTime.now()
          : DateTime.now(),
      idPemesan: map['idPemesan']?.toString() ?? 'pemesan@jastipgo.com',
      namaPemesan: map['namaPemesan']?.toString() ?? (map['pengirim'] == 'PEMESAN' ? (map['namaPengirim']?.toString() ?? 'Pemesan') : 'Pemesan Jastip'),
      idPesanan: map['idPesanan']?.toString(),
    );
  }

  Map<String, dynamic> keMap() {
    return {
      'id': id,
      'teks': teks,
      'adalahPengguna': adalahPengguna,
      'pengirim': pengirim,
      'namaPengirim': namaPengirim,
      'waktu': waktu.toIso8601String(),
      'idPemesan': idPemesan,
      'namaPemesan': namaPemesan,
      if (idPesanan != null) 'idPesanan': idPesanan,
    };
  }

  // Kompatibilitas JSON
  factory ModelPesanChat.dariJson(Map<String, dynamic> json) => ModelPesanChat.dariMap(json);
  Map<String, dynamic> keJson() => keMap();
}
