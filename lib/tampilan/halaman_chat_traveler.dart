import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_sinkronisasi_online.dart';
import '../model/model_barang_jastip.dart';
import '../model/model_pesan_chat.dart';

// Halaman Ruang Obrolan Langsung (Direct Human Chat) Dua Arah Antara Pemesan dan Traveler
// Memenuhi Ketentuan Tambahan Revisi (Poin 5):
// 1. Sisi Pemesan: DILARANG chat ke sesama pemesan; HANYA bisa chat ke Traveler jika memiliki keterikatan transaksi aktif.
// 2. Sisi Traveler: Memiliki tampilan Inbox transparan dari berbagai pemesan dengan badge counter jumlah pemesan aktif chat, melihat identitas masing-masing, dan membalas secara individual.
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
  Timer? _timerChatRealtime;

  String _peranAktif = 'PEMESAN'; // 'PEMESAN' atau 'TRAVELER'
  String _namaPengirimAktif = 'Pemesan';
  String _idPemesanAktif = 'pemesan@jastipgo.com';
  String _userIdAktif = '1';
  String? _idPesananAktif;
  bool _sedangMemuat = true;

  // Nama dan lokasi dinamis lawan bicara (Poin 3: Sinkronisasi nama dinamis)
  String _namaLawanBicaraDinamis = 'Traveler Jastip';
  String _lokasiLawanBicara = 'Sedang di Ginza, Tokyo 🇯🇵';

  // Thread pemesan yang sedang dibuka oleh Traveler (Poin 5)
  ThreadChatPemesan? _threadTerpilih;

  final List<String> _templatePesanPemesan = [
    'Halo kak, apakah koper masih muat untuk titip barang ini?',
    'Minta tolong fotokan struk resmi tokonya ya kak',
    'Kira-kira kapan jadwal mendarat di bandara Indonesia?',
    'Apakah bisa request varian warna atau rasa lainnya?',
  ];

  final List<String> _templatePesanTraveler = [
    'Halo! Stok barangnya masih tersedia banyak di etalase toko resmi.',
    'Siap, struk fisik resmi dari toko sudah saya simpan dan tercatat aman di sistem Rekber Escrow.',
    'Slot koper masih aman kak, saya bungkus dengan bubble wrap tebal ya.',
    'Pesawat saya dijadwalkan tiba di Indonesia lusa, siap COD di Hub Kampus UPN.',
  ];

  @override
  void initState() {
    super.initState();
    _muatProfilPengguna();
    LayananSinkronisasiOnline.sinkronkanChatOnline();
    LayananSinkronisasiOnline.pemicuPembaruanChat.addListener(_padaPembaruanChat);
    _timerChatRealtime = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        LayananSinkronisasiOnline.sinkronkanChatOnline();
      }
    });
  }

  void _padaPembaruanChat() {
    if (mounted) {
      setState(() {});
      _gulirKeBawah();
    }
  }

  Future<void> _muatProfilPengguna() async {
    final profil = await LayananOtentikasi.ambilProfilAktif();
    final semuaAkun = await LayananOtentikasi.ambilSemuaAkun();
    final akunTraveler = semuaAkun.where((a) => a.peran == 'TRAVELER').toList();

    // Dapatkan nama dinamis traveler dari profil akun database
    String namaTravelerResolved = akunTraveler.isNotEmpty ? akunTraveler.first.nama : 'Traveler Jastip';
    String lokasiTravelerResolved = akunTraveler.isNotEmpty ? akunTraveler.first.lokasi : widget.lokasiTraveler;

    // Ambil pesanan milik pengguna yang aktif
    final daftarPesanan = LayananBasisDataLokal.ambilPesananUntukPengguna(
      userId: profil?.id.toString(),
      email: profil?.email,
    );

    if (daftarPesanan.isNotEmpty) {
      if (daftarPesanan.first.namaTraveler.isNotEmpty) {
        namaTravelerResolved = daftarPesanan.first.namaTraveler;
      }
      _idPesananAktif = daftarPesanan.first.idPesanan;
    }

    if (!mounted) return;
    setState(() {
      if (profil != null) {
        _peranAktif = profil.peran == 'TRAVELER' ? 'TRAVELER' : 'PEMESAN';
        _namaPengirimAktif = profil.nama;
        _idPemesanAktif = profil.email.isNotEmpty ? profil.email : 'pemesan@jastipgo.com';
        _userIdAktif = profil.id.toString();
      } else {
        _peranAktif = 'PEMESAN';
        _namaPengirimAktif = 'Pemesan';
        _idPemesanAktif = 'pemesan@jastipgo.com';
        _userIdAktif = '1';
      }

      _namaLawanBicaraDinamis = namaTravelerResolved;
      _lokasiLawanBicara = lokasiTravelerResolved;

      // Jika dibuka dari detail produk spesifik, langsung buka room chat
      if (widget.barang != null) {
        _threadTerpilih = ThreadChatPemesan(
          idPemesan: _idPemesanAktif,
          namaPemesan: _peranAktif == 'TRAVELER' ? 'Pemesan Terdaftar' : _namaPengirimAktif,
          pesanTerakhir: '',
          waktuTerakhir: DateTime.now(),
          totalPesan: 0,
          infoTitipan: widget.barang?.namaBarang,
        );
      }

      _sedangMemuat = false;
    });

    _gulirKeBawah();
  }

  @override
  void dispose() {
    _timerChatRealtime?.cancel();
    LayananSinkronisasiOnline.pemicuPembaruanChat.removeListener(_padaPembaruanChat);
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

  // Kirim Pesan Nyata ke Database Hive & Picu Notifikasi ke Lawan Bicara
  Future<void> _kirimPesanNyata(
    String teks, {
    String? targetIdPemesan,
    String? targetNamaPemesan,
  }) async {
    if (teks.trim().isEmpty) return;
    final String pesanBersih = teks.trim();
    _pesanController.clear();

    final bool adalahTraveler = _peranAktif == 'TRAVELER';
    final targetId = targetIdPemesan ?? _idPemesanAktif;

    // Pastikan namaPemesan selalu menyimpan nama akun asli PEMESAN (Poin 1 TODO_PERBAIKAN_FITUR)
    final String namaAsliPemesan = adalahTraveler
        ? (targetNamaPemesan ?? _threadTerpilih?.namaPemesan ?? 'Pemesan Terdaftar')
        : _namaPengirimAktif;

    // Poin 3: Pastikan senderId dan receiverId tersimpan akurat
    final String senderId = _userIdAktif;
    final String receiverId = adalahTraveler ? targetId : '2';

    final pesanBaru = ModelPesanChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teks: pesanBersih,
      adalahPengguna: !adalahTraveler,
      pengirim: _peranAktif,
      namaPengirim: _namaPengirimAktif,
      waktu: DateTime.now(),
      idPemesan: targetId,
      namaPemesan: namaAsliPemesan,
      userId: adalahTraveler ? targetId : _userIdAktif,
      idPesanan: _idPesananAktif,
      senderId: senderId,
      receiverId: receiverId,
    );

    await LayananBasisDataLokal.kirimPesanChat(pesanBaru);
    _gulirKeBawah();

    if (!mounted) return;

    // Notifikasi Diterima oleh Pihak Lain (Poin 3: Sinkronisasi nama dinamis)
    if (adalahTraveler) {
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Pesan Masuk dari Traveler $_namaPengirimAktif ✈️',
        pesan: 'Untuk $namaAsliPemesan: "$pesanBersih"',
        ikon: Icons.chat_rounded,
        warna: Colors.indigo.shade800,
      );
    } else {
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Pesan Masuk dari Pemesan ($_namaPengirimAktif) 📩',
        pesan: 'Untuk $_namaLawanBicaraDinamis: "$pesanBersih"',
        ikon: Icons.mark_chat_unread_rounded,
        warna: Colors.teal.shade800,
      );
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
    if (_sedangMemuat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ruang Chat Jastip')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool adalahTraveler = _peranAktif == 'TRAVELER';

    // =========================================================================
    // SISI TRAVELER: TAMPILAN INBOX MULTI-PEMESAN (Poin 5)
    // =========================================================================
    if (adalahTraveler && _threadTerpilih == null) {
      return _bangunTampilanInboxTraveler();
    }

    // =========================================================================
    // SISI PEMESAN: TAMPILAN INBOX DAFTAR PESAN (Poin 3)
    // =========================================================================
    if (!adalahTraveler && _threadTerpilih == null) {
      return _bangunTampilanInboxPemesan();
    }

    // =========================================================================
    // RUANG CHAT (ROOM CHAT INDIVIDUAL)
    // =========================================================================
    return _bangunTampilanRuangChat(adalahTraveler);
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN 1: INBOX TRAVELER (Multi-Pemesan dengan Counter Badge)
  // ---------------------------------------------------------------------------
  Widget _bangunTampilanInboxTraveler() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inbox Chat Pemesan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Pesan Masuk dari Berbagai Pemesan', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Chat Online',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyinkronkan obrolan dari server online...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await LayananSinkronisasiOnline.sinkronkanChatOnline();
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Ganti Peran Pengirim (Uji Coba/Demo)',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () async {
              final profil = await LayananOtentikasi.ambilProfilAktif();
              final namaAsli = profil?.nama ?? 'Pemesan Terdaftar';
              setState(() {
                _peranAktif = 'PEMESAN';
                _namaPengirimAktif = namaAsli;
                _threadTerpilih = null;
              });
              _tampilkanSnack('Sekarang beralih ke peran PEMESAN ($namaAsli)');
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box(LayananBasisDataLokal.namaKotakChat).listenable(),
        builder: (context, box, child) {
          final threads = LayananBasisDataLokal.ambilDaftarThreadPemesan(
            travelerId: _userIdAktif,
            emailTraveler: _idPemesanAktif,
          );

          return Column(
            children: [
              // Badge & Counter Jumlah Pemesan Aktif Chat (Poin 5)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade900, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '💬 ${threads.length} Pemesan Sedang Chat',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Aktif',
                                  style: TextStyle(
                                    color: Colors.indigo.shade900,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Transparan: Pilih pemesan untuk melihat detail dan membalas secara individual.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Thread Inbox Pemesan
              Expanded(
                child: threads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Chat Masuk',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Chat dari pemesan barang jastip akan otomatis muncul di sini.',
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: threads.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final thread = threads[index];
                          final waktu = thread.waktuTerakhir;
                          final String waktuStr =
                              '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';

                          return Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _threadTerpilih = thread;
                                });
                                _gulirKeBawah();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.indigo.shade100,
                                          child: Text(
                                            thread.namaPemesan.isNotEmpty
                                                ? thread.namaPemesan.substring(0, 1).toUpperCase()
                                                : 'P',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.indigo.shade800,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  thread.namaPemesan,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                waktuStr,
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          if (thread.infoTitipan != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 3),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.amber.shade200),
                                              ),
                                              child: Text(
                                                '📦 ${thread.infoTitipan}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade900,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Text(
                                            thread.pesanTerakhir,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${thread.totalPesan}',
                                        style: TextStyle(
                                          color: Colors.indigo.shade800,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN 1b: INBOX PEMESAN (Sinkronisasi Nama Dinamis Sesuai Profil Akun)
  // ---------------------------------------------------------------------------
  Widget _bangunTampilanInboxPemesan() {
    final String namaTraveler = _namaLawanBicaraDinamis;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inbox Chat Traveler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Daftar Percakapan & Konsultasi Titipan', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Chat Online',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyinkronkan obrolan dari server online...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await LayananSinkronisasiOnline.sinkronkanChatOnline();
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Ganti Peran Pengirim (Uji Coba/Demo)',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () async {
              final semuaAkun = await LayananOtentikasi.ambilSemuaAkun();
              final akunTraveler = semuaAkun.where((a) => a.peran == 'TRAVELER').toList();
              final namaTravelerDemo = akunTraveler.isNotEmpty ? akunTraveler.first.nama : 'Traveler';
              setState(() {
                _peranAktif = 'TRAVELER';
                _namaPengirimAktif = namaTravelerDemo;
                _threadTerpilih = null;
              });
              _tampilkanSnack('Sekarang beralih ke peran TRAVELER ($namaTravelerDemo ✈️)');
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box(LayananBasisDataLokal.namaKotakChat).listenable(),
        builder: (context, box, child) {
          final pesanan = LayananBasisDataLokal.ambilPesananUntukPengguna(
            userId: _userIdAktif,
            email: _idPemesanAktif,
          );
          final pesanList = LayananBasisDataLokal.ambilPesanChatUntukPemesan(
            _idPemesanAktif,
            userId: _userIdAktif,
          );

          final String pesanTerakhir = pesanList.isNotEmpty
              ? pesanList.last.teks
              : (pesanan.isNotEmpty
                  ? 'Pesanan #${pesanan.first.idPesanan} (${pesanan.first.negaraAsal}) siap dikonsultasikan'
                  : 'Belum ada riwayat pesan dengan traveler.');
          final DateTime waktuTerakhir = pesanList.isNotEmpty
              ? pesanList.last.waktu
              : (pesanan.isNotEmpty ? pesanan.first.tanggal : DateTime.now());
          final String waktuStr =
              '${waktuTerakhir.hour.toString().padLeft(2, '0')}:${waktuTerakhir.minute.toString().padLeft(2, '0')}';

          return Column(
            children: [
              // Header Info Kotak Masuk Pemesan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade900, Colors.teal.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💬 Percakapan Langsung dengan Traveler',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pesanan.isNotEmpty
                                ? 'Terhubung dengan ${pesanan.length} transaksi aktif titipan luar negeri.'
                                : 'Pilih percakapan untuk bernegosiasi atau menanyakan status titipan.',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Thread Inbox Pemesan (Poin 3: Nama Dinamis Sesuai Profil Akun)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _threadTerpilih = ThreadChatPemesan(
                              idPemesan: _idPemesanAktif,
                              namaPemesan: namaTraveler,
                              pesanTerakhir: pesanTerakhir,
                              waktuTerakhir: waktuTerakhir,
                              totalPesan: pesanList.length,
                              infoTitipan: pesanan.isNotEmpty
                                  ? '${pesanan.first.idPesanan} (${pesanan.first.negaraAsal})'
                                  : null,
                            );
                          });
                          _gulirKeBawah();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.teal.shade100,
                                    child: Icon(Icons.flight_takeoff_rounded, color: Colors.teal.shade800, size: 24),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            namaTraveler,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          waktuStr,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    if (pesanan.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.teal.shade200),
                                        ),
                                        child: Text(
                                          '✈️ Traveler Aktif • ${pesanan.first.negaraAsal}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    Text(
                                      pesanTerakhir,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pesanList.length}',
                                  style: TextStyle(
                                    color: Colors.teal.shade800,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAMPILAN 2: RUANG CHAT (Individual untuk Traveler atau Pemesan)
  // ---------------------------------------------------------------------------
  Widget _bangunTampilanRuangChat(bool adalahTraveler) {
    // Validasi Sisi Pemesan: Harus memiliki keterikatan transaksi aktif (Poin 5)
    final daftarPesananPemesan = LayananBasisDataLokal.ambilSemuaPesanan();
    final bool punyaTransaksiAktif = daftarPesananPemesan.isNotEmpty;

    final String targetIdPemesan = adalahTraveler
        ? (_threadTerpilih?.idPemesan ?? 'pemesan@jastipgo.com')
        : _idPemesanAktif;
    final String namaLawanBicara = adalahTraveler
        ? (_threadTerpilih?.namaPemesan ?? 'Pemesan Terdaftar')
        : _namaLawanBicaraDinamis;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (_threadTerpilih != null && widget.barang == null) {
              setState(() {
                _threadTerpilih = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: NetworkImage(
                adalahTraveler
                    ? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400'
                    : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaLawanBicara,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    adalahTraveler
                        ? 'Pemesan Terverifikasi • Indonesia 🇮🇩'
                        : 'Online • $_lokasiLawanBicara',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Chat Online',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyinkronkan obrolan dari server online...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await LayananSinkronisasiOnline.sinkronkanChatOnline();
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Ganti Peran Pengirim (Uji Coba/Demo)',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () async {
              final profil = await LayananOtentikasi.ambilProfilAktif();
              final semuaAkun = await LayananOtentikasi.ambilSemuaAkun();
              final akunTraveler = semuaAkun.where((a) => a.peran == 'TRAVELER').toList();
              final namaTravelerDemo = akunTraveler.isNotEmpty ? akunTraveler.first.nama : 'Traveler';
              final namaAsli = profil?.nama ?? 'Pemesan Terdaftar';
              setState(() {
                if (_peranAktif == 'PEMESAN') {
                  _peranAktif = 'TRAVELER';
                  _namaPengirimAktif = namaTravelerDemo;
                  _threadTerpilih = null; // Menuju inbox
                } else {
                  _peranAktif = 'PEMESAN';
                  _namaPengirimAktif = namaAsli;
                  _threadTerpilih = null;
                }
              });
              _tampilkanSnack(
                'Sekarang Anda mengetik sebagai: ${_peranAktif == "TRAVELER" ? "Traveler ($namaTravelerDemo ✈️)" : namaAsli}',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Peran & Keterikatan Transaksi (Poin 5)
          if (!adalahTraveler && !punyaTransaksiAktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.red.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⛔ Akses Chat Terkunci: Transaksi Belum Ada',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pemesan HANYA bisa mengirim pesan jika telah memiliki transaksi pesanan jastip aktif. Silakan pesan barang terlebih dahulu.',
                          style: TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: adalahTraveler ? Colors.indigo.shade50 : Colors.teal.shade50,
              child: Row(
                children: [
                  Icon(
                    adalahTraveler ? Icons.flight_takeoff : Icons.verified_user_rounded,
                    size: 16,
                    color: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adalahTraveler
                          ? 'Membalas chat individual: $namaLawanBicara'
                          : '✅ Terverifikasi: Diskusi aktif pesanan #${daftarPesananPemesan.first.idPesanan} (${daftarPesananPemesan.first.daftarBarang.first.namaBarang})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: adalahTraveler ? Colors.indigo.shade900 : Colors.teal.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Banner Barang yang Dititip (Jika ada)
          if (widget.barang != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.white,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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

          // Daftar Obrolan Nyata Dua Arah dari Database Hive (Filter Per Pemesan)
          Expanded(
            child: ValueListenableBuilder<Box>(
              valueListenable: Hive.box(LayananBasisDataLokal.namaKotakChat).listenable(),
              builder: (context, box, child) {
                // Ambil pesan percakapan khusus untuk pemesan ini (Poin 3: Sinkronisasi senderId & receiverId)
                List<ModelPesanChat> pesanList =
                    LayananBasisDataLokal.ambilPesanChatUntukPemesan(
                      targetIdPemesan,
                      userId: adalahTraveler ? targetIdPemesan : _userIdAktif,
                    );

                if (pesanList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'Mulai Percakapan Langsung',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kirim pesan atau gunakan template di bawah ini.',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: pesanList.length,
                  itemBuilder: (context, index) {
                    final pesan = pesanList[index];
                    final bool pesanDariSaya = pesan.pengirim == _peranAktif;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment:
                            pesanDariSaya ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!pesanDariSaya) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey.shade300,
                              child: Icon(
                                pesan.pengirim == 'TRAVELER' ? Icons.flight_takeoff : Icons.person,
                                size: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: pesanDariSaya
                                    ? (adalahTraveler ? Colors.indigo.shade700 : Colors.teal.shade800)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(pesanDariSaya ? 16 : 4),
                                  bottomRight: Radius.circular(pesanDariSaya ? 4 : 16),
                                ),
                                border: pesanDariSaya ? null : Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: pesanDariSaya
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pesan.namaPengirim,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: pesanDariSaya ? Colors.amberAccent : Colors.teal.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    pesan.teks,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: pesanDariSaya ? Colors.white : Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pesan.waktu.hour.toString().padLeft(2, '0')}:${pesan.waktu.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: pesanDariSaya ? Colors.white70 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (pesanDariSaya) ...[
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: adalahTraveler ? Colors.indigo.shade100 : Colors.teal.shade100,
                              child: Icon(
                                adalahTraveler ? Icons.flight_takeoff : Icons.person,
                                size: 14,
                                color: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Pilihan Cepat Template Pesan Sesuai Peran Aktif (Hanya jika chat terbuka)
          if (adalahTraveler || punyaTransaksiAktif)
            Container(
              height: 36,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: adalahTraveler ? _templatePesanTraveler.length : _templatePesanPemesan.length,
                itemBuilder: (context, index) {
                  final template = adalahTraveler ? _templatePesanTraveler[index] : _templatePesanPemesan[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      label: Text(
                        template,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      onPressed: () => _kirimPesanNyata(
                        template,
                        targetIdPemesan: targetIdPemesan,
                        targetNamaPemesan: adalahTraveler ? namaLawanBicara : _namaPengirimAktif,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Input Bar Pengiriman Pesan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      enabled: adalahTraveler || punyaTransaksiAktif,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _kirimPesanNyata(
                        val,
                        targetIdPemesan: targetIdPemesan,
                        targetNamaPemesan: adalahTraveler ? namaLawanBicara : _namaPengirimAktif,
                      ),
                      decoration: InputDecoration(
                        hintText: !adalahTraveler && !punyaTransaksiAktif
                            ? 'Chat terkunci (Belum ada pesanan aktif)...'
                            : 'Balas pesan langsung ke $namaLawanBicara...',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.red.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: (!adalahTraveler && !punyaTransaksiAktif)
                          ? Colors.grey.shade400
                          : (adalahTraveler ? Colors.indigo.shade800 : Colors.teal.shade800),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        (!adalahTraveler && !punyaTransaksiAktif) ? Icons.lock : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: (!adalahTraveler && !punyaTransaksiAktif)
                          ? () => _tampilkanSnack(
                              'Pesan belum dapat dikirim. Buat pesanan jastip terlebih dahulu untuk membuka jalur komunikasi dengan Traveler.',
                            )
                          : () => _kirimPesanNyata(
                              _pesanController.text,
                              targetIdPemesan: targetIdPemesan,
                              targetNamaPemesan: adalahTraveler ? namaLawanBicara : _namaPengirimAktif,
                            ),
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
