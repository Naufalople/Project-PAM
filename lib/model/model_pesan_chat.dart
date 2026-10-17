// Model data untuk Pesan Percakapan Chatbot & Komunikasi
class ModelPesanChat {
  final String id;
  final String teks;
  final bool adalahPengguna;
  final DateTime waktu;

  ModelPesanChat({
    required this.id,
    required this.teks,
    required this.adalahPengguna,
    required this.waktu,
  });

  factory ModelPesanChat.dariJson(Map<String, dynamic> json) {
    return ModelPesanChat(
      id: json['id'] ?? '',
      teks: json['teks'] ?? '',
      adalahPengguna: json['adalahPengguna'] ?? false,
      waktu: json['waktu'] != null
          ? DateTime.parse(json['waktu'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> keJson() {
    return {
      'id': id,
      'teks': teks,
      'adalahPengguna': adalahPengguna,
      'waktu': waktu.toIso8601String(),
    };
  }
}
