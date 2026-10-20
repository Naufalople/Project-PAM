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
  final String? userId; // User ID akun pemesan
  final String? idPesanan; // ID Pesanan titipan terkait
  final String senderId; // ID Pengirim pesan (Poin 3)
  final String receiverId; // ID Penerima pesan (Poin 3)

  ModelPesanChat({
    required this.id,
    required this.teks,
    this.adalahPengguna = true,
    this.pengirim = 'PEMESAN',
    this.namaPengirim = 'Pengguna',
    required this.waktu,
    this.idPemesan = 'pemesan@jastipgo.com',
    this.namaPemesan = 'Pemesan',
    this.userId,
    this.idPesanan,
    String? senderId,
    String? receiverId,
  })  : senderId = senderId ?? (pengirim == 'TRAVELER' ? '2' : (userId ?? idPemesan)),
        receiverId = receiverId ?? (pengirim == 'TRAVELER' ? (userId ?? idPemesan) : '2');

  factory ModelPesanChat.dariMap(Map<dynamic, dynamic> map) {
    final pengirimStr = map['pengirim']?.toString() ?? 'PEMESAN';
    final idPemesanStr = map['idPemesan']?.toString() ?? 'pemesan@jastipgo.com';
    final userIdStr = map['userId']?.toString();

    final sId = map['senderId']?.toString() ??
        (pengirimStr == 'TRAVELER' ? '2' : (userIdStr ?? idPemesanStr));
    final rId = map['receiverId']?.toString() ??
        (pengirimStr == 'TRAVELER' ? (userIdStr ?? idPemesanStr) : '2');

    return ModelPesanChat(
      id: map['id']?.toString() ?? '',
      teks: map['teks']?.toString() ?? '',
      adalahPengguna: map['adalahPengguna'] == true,
      pengirim: pengirimStr,
      namaPengirim: map['namaPengirim']?.toString() ?? 'Pengguna',
      waktu: map['waktu'] != null
          ? DateTime.tryParse(map['waktu'].toString()) ?? DateTime.now()
          : DateTime.now(),
      idPemesan: idPemesanStr,
      namaPemesan: map['namaPemesan']?.toString() ?? (map['namaPengirim']?.toString() ?? 'Pemesan'),
      userId: userIdStr,
      idPesanan: map['idPesanan']?.toString(),
      senderId: sId,
      receiverId: rId,
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
      'senderId': senderId,
      'receiverId': receiverId,
      if (userId != null) 'userId': userId,
      if (idPesanan != null) 'idPesanan': idPesanan,
    };
  }

  // Kompatibilitas JSON
  factory ModelPesanChat.dariJson(Map<String, dynamic> json) => ModelPesanChat.dariMap(json);
  Map<String, dynamic> keJson() => keMap();
}
