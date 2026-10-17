import 'package:flutter/material.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_pesan_chat.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman Ruang Obrolan (Live Chat) Langsung Antara Pembeli dan Penyedia Jasa (Traveler)
class HalamanChatTraveler extends StatefulWidget {
  final ModelBarangJastip? barang;
  final String namaTraveler;
  final String lokasiTraveler;

  const HalamanChatTraveler({
    super.key,
    this.barang,
    this.namaTraveler = 'Dimas Pratama (Traveler Terverifikasi)',
    this.lokasiTraveler = 'Sedang di Ginza, Tokyo 🇯🇵',
  });

  @override
  State<HalamanChatTraveler> createState() => _HalamanChatTravelerState();
}

class _HalamanChatTravelerState extends State<HalamanChatTraveler> {
  final TextEditingController _pesanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sedangMengetik = false;

  late List<ModelPesanChat> _daftarObrolan;

  final List<String> _pesanCepat = [
    'Kak, slot koper masih muat?',
    'Minta tolong fotoin struk aslinya ya',
    'Bisa cari warna/ukuran lain?',
    'Kira-kira kapan mendarat di Indonesia?',
  ];

  @override
  void initState() {
    super.initState();
    final String namaBarang = widget.barang?.namaBarang ?? 'barang titipan';
    final String negara = widget.barang?.negara ?? 'luar negeri';

    _daftarObrolan = [
      ModelPesanChat(
        id: '1',
        teks: 'Halo! Saya ${widget.namaTraveler}. Saat ini saya ${widget.lokasiTraveler}. Ada yang ingin dititipkan dari $negara?',
        adalahPengguna: false,
        waktu: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      if (widget.barang != null)
        ModelPesanChat(
          id: '2',
          teks: 'Halo kak, saya tertarik untuk menitip "$namaBarang". Apakah barang ini masih tersedia di toko sana?',
          adalahPengguna: true,
          waktu: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      if (widget.barang != null)
        ModelPesanChat(
          id: '3',
          teks: 'Tersedia kak! Tadi saya cek di toko ${widget.barang!.namaToko} stoknya masih aman. Nanti struk pembelian resminya akan saya catat ke sertifikat Blockchain ya 👍',
          adalahPengguna: false,
          waktu: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
    ];
  }

  @override
  void dispose() {
    _pesanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _gulirKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Kirim Pesan ke Traveler
  Future<void> _kirimPesan(String teks) async {
    if (teks.trim().isEmpty) return;

    _pesanController.clear();

    final pesanUser = ModelPesanChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teks: teks,
      adalahPengguna: true,
      waktu: DateTime.now(),
    );

    setState(() {
      _daftarObrolan.add(pesanUser);
      _sedangMengetik = true;
    });

    _gulirKeBawah();

    // Simulasi Balasan Cerdas dari Traveler
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    String balasanTraveler = 'Siap kak, segera saya proses dan fotokan barangnya langsung dari toko ya!';
    final q = teks.toLowerCase();

    if (q.contains('slot') || q.contains('koper') || q.contains('bagasi')) {
      balasanTraveler = 'Masih ada sisa 8 kg slot koper untuk penerbangan besok lusa kak, silakan langsung checkout di aplikasi ya!';
    } else if (q.contains('struk') || q.contains('asli') || q.contains('kw') || q.contains('ori')) {
      balasanTraveler = 'Semua barang dibeli langsung di official store kak. Struk fisik dan bukti keaslian otomatis tercatat di rantai Blockchain JastipGo.';
    } else if (q.contains('kapan') || q.contains('mendarat') || q.contains('sampai')) {
      balasanTraveler = 'Jadwal landing di Bandara YIA / Soekarno Hatta tanggal 8 lusa kak. Pengiriman ke rumah kakak langsung diproses hari itu juga.';
    } else if (q.contains('nego') || q.contains('ongkos') || q.contains('diskon')) {
      balasanTraveler = 'Bisa kak! Kakak bisa goyangkan HP di menu "Shake & Win Promo" untuk dapat kupon diskon ongkos titip hingga 50%!';
    }

    final pesanBalasan = ModelPesanChat(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      teks: balasanTraveler,
      adalahPengguna: false,
      waktu: DateTime.now(),
    );

    setState(() {
      _daftarObrolan.add(pesanBalasan);
      _sedangMengetik = false;
    });

    _gulirKeBawah();

    // Notifikasi Mobile
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pesan Baru dari Traveler',
      pesan: balasanTraveler,
      ikon: Icons.chat_outlined,
      warna: Colors.teal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.shade100,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.namaTraveler,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.lokasiTraveler,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Status Barang yang Dibicarakan (Jika ada)
          if (widget.barang != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.barang!.fotoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag, size: 36),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.barang!.namaBarang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.barang!.benderaNegara} ${widget.barang!.negara} • ${widget.barang!.namaToko}',
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Pesan Chat Antara Pembeli & Traveler
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _daftarObrolan.length,
              itemBuilder: (context, index) {
                final pesan = _daftarObrolan[index];
                final bool dariUser = pesan.adalahPengguna;

                return Align(
                  alignment: dariUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: dariUser ? Colors.teal.shade700 : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(dariUser ? 16 : 4),
                        bottomRight: Radius.circular(dariUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      pesan.teks,
                      style: TextStyle(
                        color: dariUser ? Colors.white : Colors.black87,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Status Mengetik
          if (_sedangMengetik)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal.shade700),
                  ),
                  const SizedBox(width: 8),
                  const Text('Traveler sedang membalas...', style: TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),

          // Tombol Balasan Cepat
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _pesanCepat.length,
              itemBuilder: (context, index) {
                final chip = _pesanCepat[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.teal.shade200),
                    onPressed: () => _kirimPesan(chip),
                  ),
                );
              },
            ),
          ),

          // Kotak Input Teks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesanController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _kirimPesan(val),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan negosiasi / pertanyaan...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade700,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _kirimPesan(_pesanController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
