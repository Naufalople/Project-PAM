// Model data untuk Pengguna: Pemesan (Indonesia) atau Pembeli / Traveler (Luar Negeri)
class ModelPengguna {
  final int id;
  final String nama;
  final String email;
  final String passwordHash;
  final String nomorTelepon;
  final String fotoProfil;
  final String peran; // 'PEMESAN' atau 'TRAVELER'
  final String lokasi; // Misal: 'Yogyakarta, Indonesia 🇮🇩' atau 'Ginza, Tokyo 🇯🇵'

  ModelPengguna({
    required this.id,
    required this.nama,
    required this.email,
    required this.passwordHash,
    required this.nomorTelepon,
    required this.fotoProfil,
    this.peran = 'PEMESAN',
    this.lokasi = 'Indonesia 🇮🇩',
  });

  // Konversi dari JSON ke Objek Pengguna
  factory ModelPengguna.dariJson(Map<String, dynamic> json) {
    return ModelPengguna(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      nomorTelepon: json['nomorTelepon'] ?? '',
      fotoProfil: json['fotoProfil'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      peran: json['peran'] ?? 'PEMESAN',
      lokasi: json['lokasi'] ?? 'Indonesia 🇮🇩',
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
      'peran': peran,
      'lokasi': lokasi,
    };
  }
}
