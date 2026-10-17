import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_pesan_chat.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';

// Halaman Ruang Obrolan Langsung (Direct Human Chat) Antara Pemesan dan Traveler
// Mendukung simulasi dua arah nyata (tanpa auto-bot) serta tautan WhatsApp langsung.
class HalamanChatTraveler extends StatefulWidget {
  final ModelBarangJastip? barang;
  final String namaTraveler;
  final String lokasiTraveler;
  final String nomorWaTraveler;

  const HalamanChatTraveler({
    super.key,
    this.barang,
    this.namaTraveler = 'Dimas Pratama (Traveler Luar Negeri)',
    this.lokasiTraveler = 'Sedang di Ginza, Tokyo 🇯🇵',
    this.nomorWaTraveler = '6281234567890',
  });

  @override
  State<HalamanChatTraveler> createState() => _HalamanChatTravelerState();
}

class _HalamanChatTravelerState extends State<HalamanChatTraveler> {
  final TextEditingController _pesanController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _namaPemesan = 'Pemesan';
  late List<ModelPesanChat> _daftarObrolan;

  final List<String> _templatePesanPemesan = [
    'Kak Dimas, slot koper masih muat untuk barang ini?',
    'Minta tolong fotoin struk resmi tokonya ya kak',
    'Kira-kira kapan jadwal mendarat di bandara Indonesia?',
    'Bisa tolong carikan varian rasa/warna lainnya?',
  ];

  @override
  void initState() {
    super.initState();
    _muatProfilPemesan();

    final String namaBarang = widget.barang?.namaBarang ?? 'Tokyo Banana Tokyo Station Edition';
    final String negara = widget.barang?.negara ?? 'Jepang';

    _daftarObrolan = [
      ModelPesanChat(
        id: '1',
        teks: 'Halo! Saya ${widget.namaTraveler}. Saat ini saya ${widget.lokasiTraveler}. Ada yang ingin dititipkan dari $negara?',
        adalahPengguna: false,
        waktu: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ModelPesanChat(
        id: '2',
        teks: 'Halo kak Dimas, saya mau titip "$namaBarang". Apakah barang ini masih tersedia di toko resmi sana?',
        adalahPengguna: true,
        waktu: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ModelPesanChat(
        id: '3',
        teks: 'Tersedia kak! Tadi saya cek di toko fisiknya stoknya masih ada. Nanti struk pembelian aslinya akan saya verifikasi ke sistem Blockchain JastipGo ya 👍',
        adalahPengguna: false,
        waktu: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  Future<void> _muatProfilPemesan() async {
    final profil = await LayananOtentikasi.ambilProfilAktif();
    if (!mounted) return;
    if (profil != null) {
      setState(() {
        _namaPemesan = profil.nama;
      });
    }
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

  // Kirim Pesan Langsung dari Pemesan ke Traveler (Dimas Pratama)
  void _kirimPesanLangsung(String teks) {
    if (teks.trim().isEmpty) return;

    final String pesanBersih = teks.trim();
    _pesanController.clear();

    final pesanBaru = ModelPesanChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teks: pesanBersih,
      adalahPengguna: true,
      waktu: DateTime.now(),
    );

    setState(() {
      _daftarObrolan.add(pesanBaru);
    });

    _gulirKeBawah();

    // Notifikasi Pesan Terkirim dari Pemesan
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pesan Terkirim ke ${widget.namaTraveler} 📩',
      pesan: 'Dari $_namaPemesan: "$pesanBersih"',
      ikon: Icons.mark_chat_unread_rounded,
      warna: Colors.teal.shade800,
    );

    // Simulasi Balasan Nyata dari Traveler Luar Negeri dengan Notifikasi Masuk
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      String balasan = 'Baik kak $_namaPemesan, pesan sudah saya terima. Saya segera belikan barangnya di toko resmi ya 👍';
      final lower = pesanBersih.toLowerCase();
      if (lower.contains('struk')) {
        balasan = 'Siap kak $_namaPemesan! Struk fisik toko aslinya akan saya foto dan rekam ke buku besar Blockchain.';
      } else if (lower.contains('koper') || lower.contains('slot')) {
        balasan = 'Slot koper masih muat 5 kg lagi kak, belanjaan Anda akan saya simpan rapi dengan pelindung bubble wrap.';
      } else if (lower.contains('kapan') || lower.contains('mendarat') || lower.contains('jadwal')) {
        balasan = 'Jadwal kepulangan ke Indonesia lusa kak. Nanti saya kabari saat mendarat di bandara ya!';
      } else if (lower.contains('varian') || lower.contains('rasa') || lower.contains('warna')) {
        balasan = 'Ada beberapa varian rasa/warna di rak etalase kak, mau saya fotokan langsung dari toko?';
      }

      final pesanBalasan = ModelPesanChat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        teks: balasan,
        adalahPengguna: false,
        waktu: DateTime.now(),
      );

      setState(() {
        _daftarObrolan.add(pesanBalasan);
      });

      _gulirKeBawah();

      // Notifikasi Pesan Masuk dari Traveler ke Pemesan
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Pesan Baru dari ${widget.namaTraveler} ✈️',
        pesan: 'Untuk $_namaPemesan: "$balasan"',
        ikon: Icons.chat_rounded,
        warna: Colors.indigo.shade800,
      );
    });
  }

  // Buka WhatsApp Langsung ke Traveler
  Future<void> _bukaWhatsAppTraveler() async {
    final String pesanAwal = Uri.encodeComponent(
      'Halo ${widget.namaTraveler}, saya dari aplikasi JastipGo ingin konfirmasi pesanan titipan barang di ${widget.lokasiTraveler}.',
    );
    final Uri waUri = Uri.parse('https://wa.me/${widget.nomorWaTraveler}?text=$pesanAwal');

    try {
      final bool berhasil = await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (!berhasil && mounted) {
        _tampilkanSnack('Tidak dapat membuka WhatsApp. Silakan hubungi via obrolan aplikasi.');
      }
    } catch (_) {
      if (mounted) {
        _tampilkanSnack('Gagal membuka WhatsApp. Fitur chat in-app tetap aktif.');
      }
    }
  }

  void _tampilkanSnack(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks, style: const TextStyle(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal.shade900,
      ),
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
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online • ${widget.lokasiTraveler}',
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
        actions: [
          IconButton(
            tooltip: 'Chat Langsung via WhatsApp',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: _bukaWhatsAppTraveler,
          ),
        ],
      ),
      body: Column(
        children: [

          // Banner Barang yang Dibicarakan (Jika ada)
          if (widget.barang != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.shade50,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.barang!.fotoUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag, size: 34),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.barang!.namaBarang,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
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

          // Daftar Pesan Chat Antara Pemesan & Traveler
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _daftarObrolan.length,
              itemBuilder: (context, index) {
                final pesan = _daftarObrolan[index];
                final bool dariPemesan = pesan.adalahPengguna;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: dariPemesan ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!dariPemesan) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.person, size: 16, color: Colors.teal),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: dariPemesan ? Colors.teal.shade700 : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(dariPemesan ? 14 : 4),
                              bottomRight: Radius.circular(dariPemesan ? 4 : 14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: dariPemesan ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                dariPemesan ? '$_namaPemesan (Pemesan)' : 'Dimas Pratama (Traveler LN)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: dariPemesan ? Colors.teal.shade100 : Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pesan.teks,
                                style: TextStyle(
                                  color: dariPemesan ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (dariPemesan) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.teal.shade800,
                          child: const Icon(Icons.account_circle, size: 16, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Pilihan Pesan Cepat untuk Pemesan
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _templatePesanPemesan.length,
              itemBuilder: (context, index) {
                final teks = _templatePesanPemesan[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: Text(teks, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.teal.shade300),
                    onPressed: () {
                      _pesanController.text = teks;
                    },
                  ),
                );
              },
            ),
          ),

          // Kotak Input Teks Obrolan
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
                      onSubmitted: (val) => _kirimPesanLangsung(val),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan titipan untuk ${widget.namaTraveler}...',
                        hintStyle: const TextStyle(fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.teal.shade300),
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
                      onPressed: () => _kirimPesanLangsung(_pesanController.text),
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
