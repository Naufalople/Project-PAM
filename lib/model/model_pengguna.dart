// Model data untuk Pengguna / Traveler
class ModelPengguna {
  final int id;
  final String nama;
  final String email;
  final String passwordHash;
  final String nomorTelepon;
  final String fotoProfil;

  ModelPengguna({
    required this.id,
    required this.nama,
    required this.email,
    required this.passwordHash,
    required this.nomorTelepon,
    required this.fotoProfil,
  });

  // Konversi dari JSON ke Objek Pengguna
  factory ModelPengguna.dariJson(Map<String, dynamic> json) {
    return ModelPengguna(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      nomorTelepon: json['nomorTelepon'] ?? '',
      fotoProfil: json['fotoProfil'] ?? '',
    );
  }

  // Konversi dari Objek Pengguna ke Map / JSON
  Map<String, dynamic> keJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'passwordHash': passwordHash,
      'nomorTelepon': nomorTelepon,
      'fotoProfil': fotoProfil,
    };
  }
}
