import 'package:flutter/material.dart';
import '../layanan/layanan_rekber.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_sinkronisasi_online.dart';
import '../model/model_pesanan_jastip.dart';
import '../model/model_transaksi_rekber.dart';

/// Halaman Dompet & Rekening Bersama (Rekber / Escrow) JastipGo
/// Menggantikan sistem blockchain lama dengan sistem Rekber yang nyata:
/// 1. Saldo Rekber (Tertahan): Uang pemesan yang sedang ditahan di Escrow (dilarang ditarik).
/// 2. Saldo Aktif: Uang pesanan yang telah dikonfirmasi "Sudah Diterima" oleh pemesan (siap ditarik).
/// 3. Form penarikan ke rekening bank dengan validasi proteksi Rekber ketat.
class HalamanDompetRekber extends StatefulWidget {
  final String? peranOverride;

  const HalamanDompetRekber({super.key, this.peranOverride});

  @override
  State<HalamanDompetRekber> createState() => _HalamanDompetRekberState();
}

class _HalamanDompetRekberState extends State<HalamanDompetRekber> {
  int _saldoTertahan = 0;
  int _saldoAktif = 0;
  String _namaTravelerAktif = 'Dimas Pratama';
  String _peranPenggunaAktif = 'TRAVELER';
  List<ModelPesananJastip> _daftarPesanan = [];
  List<ModelPenarikanDana> _riwayatPenarikan = [];
  bool _sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    if (widget.peranOverride != null) {
      _peranPenggunaAktif = widget.peranOverride!;
    }
    _muatDataRekber();
    LayananSinkronisasiOnline.sinkronkanPesananOnline();
    LayananSinkronisasiOnline.sinkronkanRekberOnline();
    LayananSinkronisasiOnline.pemicuPembaruanRekber.addListener(_muatDataRekber);
    LayananSinkronisasiOnline.pemicuPembaruanPesanan.addListener(_muatDataRekber);
  }

  @override
  void dispose() {
    LayananSinkronisasiOnline.pemicuPembaruanRekber.removeListener(_muatDataRekber);
    LayananSinkronisasiOnline.pemicuPembaruanPesanan.removeListener(_muatDataRekber);
    super.dispose();
  }

  Future<void> _muatDataRekber({bool sinkronkanOnline = false}) async {
    if (sinkronkanOnline) {
      await LayananSinkronisasiOnline.sinkronkanPesananOnline();
      await LayananSinkronisasiOnline.sinkronkanRekberOnline();
    }

    final peran = widget.peranOverride ?? await LayananOtentikasi.ambilPeranAktif();
    final profil = peran == 'TRAVELER'
        ? (await LayananOtentikasi.ambilProfilAktif())
        : null;
    final namaTraveler = profil?.nama ?? 'Dimas Pratama';

    final tertahan = LayananRekber.hitungSaldoTertahanRekber(
      namaTraveler: peran == 'TRAVELER' ? namaTraveler : null,
    );
    final aktif = LayananRekber.hitungSaldoAktifTraveler(
      namaTraveler: peran == 'TRAVELER' ? namaTraveler : null,
    );
    final semuaPesanan = LayananBasisDataLokal.ambilSemuaPesanan();
    final riwayat = LayananRekber.ambilRiwayatPenarikan(
      namaTraveler: peran == 'TRAVELER' ? namaTraveler : null,
    );

    if (mounted) {
      setState(() {
        _peranPenggunaAktif = peran;
        _namaTravelerAktif = namaTraveler;
        _saldoTertahan = tertahan;
        _saldoAktif = aktif;
        _daftarPesanan = semuaPesanan;
        _riwayatPenarikan = riwayat;
        _sedangMemuat = false;
      });
    }
  }

  void _bukaModalPenarikanDana() {
    final formKey = GlobalKey<FormState>();
    final nominalController = TextEditingController();
    final rekeningController = TextEditingController(text: '1230984712');
    final pemilikController = TextEditingController(text: _namaTravelerAktif);
    String bankPilihan = 'BCA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: Colors.teal.shade800, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Tarik Saldo ke Rekening Bank',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Info Saldo Saat Ini
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Aktif (Bisa Ditarik):', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              Text(
                                'Rp ${_formatRupiah(_saldoAktif)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Saldo Tertahan Rekber:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              Text(
                                'Rp ${_formatRupiah(_saldoTertahan)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pilih Bank
                    DropdownButtonFormField<String>(
                      initialValue: bankPilihan,
                      decoration: InputDecoration(
                        labelText: 'Pilih Bank Tujuan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BCA', child: Text('Bank Central Asia (BCA)')),
                        DropdownMenuItem(value: 'Mandiri', child: Text('Bank Mandiri')),
                        DropdownMenuItem(value: 'BNI', child: Text('Bank Negara Indonesia (BNI)')),
                        DropdownMenuItem(value: 'BRI', child: Text('Bank Rakyat Indonesia (BRI)')),
                        DropdownMenuItem(value: 'Bank Jago', child: Text('Bank Jago Digital')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => bankPilihan = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Nomor Rekening
                    TextFormField(
                      controller: rekeningController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nomor Rekening',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nomor rekening wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Nama Pemilik
                    TextFormField(
                      controller: pemilikController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pemilik Rekening',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama pemilik rekening wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    // Nominal Tarik
                    TextFormField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Penarikan (Rp)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Masukkan jumlah penarikan';
                        final n = int.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                        if (n == null || n <= 0) return 'Nominal harus lebih dari Rp 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Chip Nominal Cepat
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChipNominal('Semua Saldo Aktif', _saldoAktif, nominalController),
                          const SizedBox(width: 6),
                          _buildChipNominal('Rp 100.000', 100000, nominalController),
                          const SizedBox(width: 6),
                          _buildChipNominal('Rp 250.000', 250000, nominalController),
                          const SizedBox(width: 6),
                          _buildChipNominal('Rp 500.000', 500000, nominalController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Konfirmasi Penarikan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final jumlah = int.tryParse(
                                nominalController.text.replaceAll('.', '').replaceAll(',', ''),
                              ) ??
                              0;

                          Navigator.pop(ctx);
                          await _eksekusiPenarikan(
                            jumlah: jumlah,
                            namaBank: bankPilihan,
                            nomorRekening: rekeningController.text.trim(),
                            namaPemilik: pemilikController.text.trim(),
                          );
                        },
                        child: const Text('Konfirmasi & Cairkan Dana', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChipNominal(String label, int nominal, TextEditingController controller) {
    return ActionChip(
      backgroundColor: const Color(0xFFF0FDF4),
      side: BorderSide(color: Colors.teal.shade200),
      label: Text(label, style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600)),
      onPressed: () {
        controller.text = nominal.toString();
      },
    );
  }

  Future<void> _eksekusiPenarikan({
    required int jumlah,
    required String namaBank,
    required String nomorRekening,
    required String namaPemilik,
  }) async {
    final hasil = await LayananRekber.tarikDanaKeRekening(
      jumlahTarik: jumlah,
      namaBank: namaBank,
      nomorRekening: nomorRekening,
      namaPemilikRekening: namaPemilik,
      namaTraveler: _namaTravelerAktif,
    );

    await _muatDataRekber();

    if (!mounted) return;

    if (hasil.berhasil) {
      LayananNotifikasi.kirimNotifikasi(
        context,
        judul: 'Pencairan Dana Berhasil! 💸',
        pesan: hasil.pesan,
        ikon: Icons.payments_rounded,
        warna: Colors.green.shade800,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Text('Penarikan Berhasil'),
            ],
          ),
          content: Text(hasil.pesan, style: const TextStyle(fontSize: 13, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      // Penarikan Ditolak: Menampilkan penjelasan proteksi Rekber
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.g_mobiledata, size: 0),
              Icon(Icons.lock_clock_rounded, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Penarikan Dana Ditolak', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: Text(hasil.pesan, style: const TextStyle(fontSize: 13, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validasi Peran (Role-Based Access): Halaman & Saldo Rekber EKSKLUSIF Khusus Traveler
    if (!_sedangMemuat && _peranPenggunaAktif != 'TRAVELER') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          title: const Text('Akses Dibatasi'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_rounded, size: 72, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                const Text(
                  'Akses Khusus Traveler',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fitur Dompet & Saldo Rekber hanya diperuntukkan bagi akun Traveler untuk memantau dana pesanan yang ditahan serta pencairan saldo aktif.\n\nSebagai Pemesan, Anda cukup melihat tagihan pesanan dan melakukan pembayaran standar saat checkout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Dompet & Saldo Rekber Escrow'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Segarkan Saldo dari Server Online',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => _muatDataRekber(sinkronkanOnline: true),
          ),
        ],
      ),
      body: _sedangMemuat
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _muatDataRekber(sinkronkanOnline: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Prinsip Rekber Escrow JastipGo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade900, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.25),
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
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 30),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sistem Keamanan Rekber Escrow',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Uang pembayaran pembeli DITAHAN aman di sistem rekening bersama JastipGo. '
                                  'Dana baru cair ke Saldo Aktif Traveler saat pemesan mengonfirmasi bahwa produk telah diterima.',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KARTU SALDO UTAMA TRAVELER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.teal.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // 1. Saldo Rekber (Tertahan)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lock_rounded, size: 14, color: Colors.amber.shade900),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Saldo Rekber (Tertahan)',
                                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rp ${_formatRupiah(_saldoTertahan)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Belum Bisa Ditarik',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2. Saldo Aktif (Siap Ditarik)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade800),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Saldo Aktif (Siap Cair)',
                                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rp ${_formatRupiah(_saldoAktif)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Bisa Ditarik ke Rekening',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Tombol Aksi Tarik Saldo
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade800,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _bukaModalPenarikanDana,
                              icon: const Icon(Icons.account_balance_rounded, size: 18),
                              label: const Text(
                                'Tarik Saldo ke Rekening Bank',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TABEL / DAFTAR ALIRAN DANA REKBER PER PESANAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📋 Status Rekber Pesanan Jastip:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        Text(
                          '${_daftarPesanan.length} Pesanan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_daftarPesanan.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada transaksi pesanan yang tercatat di Rekber.',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _daftarPesanan.map((pesanan) {
                          final bool sudahDiterima = pesanan.tahapStatus >= 6;
                          final String tanggalStr =
                              '${pesanan.tanggal.day}/${pesanan.tanggal.month}/${pesanan.tanggal.year}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sudahDiterima ? Colors.green.shade200 : Colors.amber.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${pesanan.idPesanan} • ${pesanan.namaPemesan ?? "Pemesan"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: sudahDiterima ? Colors.green.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: sudahDiterima ? Colors.green.shade300 : Colors.amber.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        sudahDiterima ? '✅ DANA SUDAH CAIR' : '🔒 DITAHAN REKBER',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: sudahDiterima ? Colors.green.shade800 : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Asal: ${pesanan.negaraAsal}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                        Text('Tanggal: $tanggalStr', style: const TextStyle(fontSize: 10.5, color: Colors.black45)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Nominal Dana:', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                                        Text(
                                          'Rp ${_formatRupiah(pesanan.totalHargaIdr)}',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: sudahDiterima ? Colors.green.shade800 : Colors.orange.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sudahDiterima
                                      ? 'Pemesan telah mengonfirmasi barang diterima. Dana telah resmi cair ke Saldo Aktif Anda.'
                                      : 'Uang pemesan tersimpan aman di Rekber. Menunggu pemesan menerima barang untuk pelepasan dana.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: sudahDiterima ? Colors.green.shade700 : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // RIWAYAT PENARIKAN DANA
                    if (_riwayatPenarikan.isNotEmpty) ...[
                      const Text(
                        '💸 Riwayat Pencairan Dana ke Bank:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: _riwayatPenarikan.map((wd) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_circle_up_rounded, color: Colors.green, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transfer ke ${wd.namaBank} (${wd.nomorRekening})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        'a.n. ${wd.namaPemilik} • ${wd.tanggal.day}/${wd.tanggal.month}/${wd.tanggal.year}',
                                        style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '- Rp ${_formatRupiah(wd.jumlahIdr)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatRupiah(int nominal) {
    return nominal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
