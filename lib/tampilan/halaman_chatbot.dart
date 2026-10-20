import 'package:flutter/material.dart';
import '../model/model_pesan_chat.dart';
import '../layanan/layanan_ai.dart';

// Halaman LLM Chatbot: Asisten Jastip Cerdas & Konsultasi Bea Cukai
class HalamanChatbot extends StatefulWidget {
  const HalamanChatbot({super.key});

  @override
  State<HalamanChatbot> createState() => _HalamanChatbotState();
}

class _HalamanChatbotState extends State<HalamanChatbot> {
  final TextEditingController _teksController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sedangMengetik = false;

  final List<ModelPesanChat> _daftarPesan = [
    ModelPesanChat(
      id: '1',
      teks: 'Halo! Saya **Asisten Cerdas JastipGo** 🤖\n'
          'Silakan tanyakan apa saja seputar:\n'
          '• Batas bea cukai & pajak impor koper penumpang\n'
          '• Rekomendasi oleh-oleh favorit dari Jepang, Korea, London, & Singapura\n'
          '• Cek kurs mata uang asing dan rute toko belanja.',
      adalahPengguna: false,
      waktu: DateTime.now(),
    ),
  ];

  final List<String> _pertanyaanCepat = [
    'Barang termahal & termurah di aplikasi',
    'Katalog produk jastip',
    'Aturan Bea Cukai & Pajak',
    'Oleh-oleh populer Jepang',
    'Rekomendasi jastip London',
    'Skincare hits Korea Selatan',
    'Kurs mata uang hari ini',
    'Aturan IMEI HP dari luar negeri',
  ];

  @override
  void dispose() {
    _teksController.dispose();
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

  Future<void> _kirimPesan(String teks) async {
    if (teks.trim().isEmpty) return;

    _teksController.clear();

    final pesanUser = ModelPesanChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teks: teks,
      adalahPengguna: true,
      waktu: DateTime.now(),
    );

    setState(() {
      _daftarPesan.add(pesanUser);
      _sedangMengetik = true;
    });

    _gulirKeBawah();

    // Dapatkan respon dari LLM AI
    final responAi = await LayananAi.prosesPesanChatbot(teks);

    if (!mounted) return;

    final pesanBot = ModelPesanChat(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      teks: responAi,
      adalahPengguna: false,
      waktu: DateTime.now(),
    );

    setState(() {
      _daftarPesan.add(pesanBot);
      _sedangMengetik = false;
    });

    _gulirKeBawah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JastipGo Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Online • LLM AI Powered', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Daftar Pesan Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _daftarPesan.length,
              itemBuilder: (context, index) {
                final pesan = _daftarPesan[index];
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
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Indikator Mengetik
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
                  const Text('Asisten sedang menganalisis...', style: TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),

          // Pilihan Pertanyaan Cepat (Chips)
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _pertanyaanCepat.length,
              itemBuilder: (context, index) {
                final q = _pertanyaanCepat[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(q, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.teal.shade200),
                    onPressed: () => _kirimPesan(q),
                  ),
                );
              },
            ),
          ),

          // Bar Input Teks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      controller: _teksController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _kirimPesan(val),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu seputar titipan...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _kirimPesan(_teksController.text),
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
