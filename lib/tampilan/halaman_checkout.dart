import 'package:flutter/material.dart';
import '../model/model_keranjang.dart';
import '../model/model_blok_transaksi.dart';
import '../model/model_pesanan_jastip.dart';
import '../layanan/layanan_basisdata_lokal.dart';
import '../layanan/layanan_konversi.dart';
import '../layanan/layanan_biometrik.dart';
import '../layanan/layanan_blockchain.dart';
import '../layanan/layanan_notifikasi.dart';
import '../layanan/layanan_otentikasi.dart';
import '../layanan/layanan_api.dart';
import '../widget/dialog_sukses.dart';
import '../widget/dialog_peringatan.dart';
import 'halaman_status_pesanan.dart';

// Halaman Pembayaran (Checkout) dengan Verifikasi Biometrik Sidik Jari & Pencatatan Blockchain
class HalamanCheckout extends StatefulWidget {
  final List<ModelKeranjang> daftarItem;

  const HalamanCheckout({super.key, required this.daftarItem});

  @override
  State<HalamanCheckout> createState() => _HalamanCheckoutState();
}

class _HalamanCheckoutState extends State<HalamanCheckout> {
  String _metodePembayaran = 'QRIS'; // 'QRIS' atau 'Transfer Bank'
  String _bankPilihan = 'BCA';
  bool _sedangMemproses = false;

  // 1. Metode Serah Terima Barang (Dipilih & Ditentukan Oleh Pemesan saat Checkout)
  String _metodePenyerahan = 'COD_LBS'; // 'COD_LBS' atau 'KURIR_ANTAR'
  final TextEditingController _alamatController = TextEditingController(
    text: 'Jl. Babarsari No. 12, Caturtunggal, Sleman, D.I. Yogyakarta',
  );

  // 2. Voucher & Promo (Bisa Didapat dari Shake Promo / Mini Game)
  List<ModelVoucher> _daftarVoucherTersedia = [];
  ModelVoucher? _voucherTerpilih;
  final TextEditingController _kodePromoManualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatDaftarVoucher();
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _kodePromoManualController.dispose();
    super.dispose();
  }

  void _muatDaftarVoucher() {
    final list = LayananBasisDataLokal.ambilSemuaVoucher();
    setState(() {
      _daftarVoucherTersedia = list;
    });
  }

  void _terapkanKodePromoManual() {
    final kode = _kodePromoManualController.text.trim().toUpperCase();
    if (kode.isEmpty) return;

    final voucher = _daftarVoucherTersedia.where((v) => v.kode.toUpperCase() == kode).toList();
    if (voucher.isNotEmpty) {
      setState(() {
        _voucherTerpilih = voucher.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Promo "${voucher.first.judul}" aktif! Hemat ${LayananKonversi.formatRupiah(voucher.first.potonganIdr)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode promo tidak valid atau sudah digunakan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  int get _subtotal {
    int total = 0;
    for (var item in widget.daftarItem) {
      total += item.totalHargaIdr;
    }
    return total;
  }

  int get _biayaJasaTitip => (_subtotal * 0.05).round(); // Biaya jastip 5%
  int get _potonganVoucher => _voucherTerpilih?.potonganIdr ?? 0;
  int get _totalBayar {
    final total = _subtotal + _biayaJasaTitip - _potonganVoucher;
    return total > 0 ? total : 0;
  }

  // Proses Pembayaran dengan Sensor Biometrik Sidik Jari
  Future<void> _prosesKonfirmasiPembayaran() async {
    setState(() => _sedangMemproses = true);

    // 1. Minta Autentikasi Sensor Sidik Jari
    final bool sidikJariValid = await LayananBiometrik.autentikasiSidikJari(
      pesanAlasan: 'Tempelkan sidik jari untuk mengonfirmasi pembayaran titipan sebesar ${LayananKonversi.formatRupiah(_totalBayar)}',
    );

    if (!mounted) return;

    if (!sidikJariValid) {
      setState(() => _sedangMemproses = false);
      showDialog(
        context: context,
        builder: (context) => const DialogPeringatan(
          judul: 'Otorisasi Gagal',
          deskripsi: 'Sidik jari tidak cocok. Pembayaran tidak dapat diproses demi keamanan akun Anda.',
        ),
      );
      return;
    }

    // 2. Ambil data profil pembeli
    final profil = await LayananOtentikasi.ambilProfilAktif();
    final String namaPembeli = profil?.nama ?? 'Pengguna JastipGo';
    final String idPesanan = 'PO-JSTP-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final List<String> namaBarangList = widget.daftarItem.map((e) => '${e.namaBarang} (x${e.jumlah})').toList();
    final String negaraAsal = widget.daftarItem.isNotEmpty ? widget.daftarItem.first.negara : 'Global';

    // 3. Catat Transaksi ke Blockchain (Menghasilkan Blok Hash SHA-256)
    final ModelBlokTransaksi blokBaru = await LayananBlockchain.catatTransaksiBaru(
      idPesanan: idPesanan,
      namaPembeli: namaPembeli,
      totalHargaIdr: _totalBayar,
      daftarBarang: namaBarangList,
      negaraAsal: negaraAsal,
    );

    // 4. Buat dan Simpan Objek Pesanan Lengkap ke Hive
    final ModelPesananJastip pesananBaru = ModelPesananJastip(
      idPesanan: idPesanan,
      tanggal: DateTime.now(),
      negaraAsal: negaraAsal,
      namaTraveler: 'Dimas Pratama (Traveler Terverifikasi)',
      lokasiTerkini: 'Sedang di Toko Resmi $negaraAsal (Menunggu Traveler Meng-ACC)',
      tahapStatus: 1, // Dana Ditahan Rekber
      metodePenyerahan: _metodePenyerahan,
      alamatPengiriman: _metodePenyerahan == 'KURIR_ANTAR' ? _alamatController.text.trim() : '',
      totalHargaIdr: _totalBayar,
      daftarBarang: widget.daftarItem
          .map((item) => ModelItemPesanan(
                namaBarang: item.namaBarang,
                fotoUrl: item.fotoUrl,
                negara: item.negara,
                namaToko: 'Official Flagship Store',
                jumlah: item.jumlah,
                hargaIdr: item.totalHargaIdr,
              ))
          .toList(),
    );
    await LayananBasisDataLokal.tambahPesanan(pesananBaru);

    // 4b. Sinkronkan pertambahan barang terjual ke Database Online & Lokal (Audit Poin 1)
    await LayananApi.catatPembelianOnline(
      widget.daftarItem
          .map((item) => {
                'namaBarang': item.namaBarang,
                'jumlah': item.jumlah,
              })
          .toList(),
    );

    // 5. Jika voucher digunakan, hapus voucher dari database agar hilang setelah dipakai
    if (_voucherTerpilih != null) {
      await LayananBasisDataLokal.gunakanVoucher(_voucherTerpilih!.kode);
    }

    // 6. Kosongkan Keranjang Lokal Hive
    await LayananBasisDataLokal.kosongkanKeranjang();

    if (!mounted) return;

    // 7. Picu Notifikasi Mobile
    LayananNotifikasi.kirimNotifikasi(
      context,
      judul: 'Pembayaran Jastip Berhasil! 🎉',
      pesan: 'Pesanan #$idPesanan telah terbit di Blockchain dengan Hash: ${blokBaru.hash.substring(0, 16)}...',
      ikon: Icons.verified_rounded,
      warna: Colors.green,
    );

    setState(() => _sedangMemproses = false);

    // 8. Tampilkan Dialog Sukses & Arahkan ke Pelacakan Pesanan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogSukses(
        judul: 'Transaksi Berhasil & Terenkripsi!',
        deskripsi: 'Pembayaran Anda telah diverifikasi biometrik dan sertifikat struk resmi telah dicatat ke Blockchain.\n\nHash ID: ${blokBaru.hash.substring(0, 20)}...',
        saatKlikOke: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HalamanStatusPesanan(
                idPesananTerpilih: idPesanan,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Konfirmasi & Pembayaran'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rincian Barang yang Dititip
            const Text(
              'Rincian Barang Titipan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.daftarItem.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final item = widget.daftarItem[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.fotoUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(
                      item.namaBarang,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${item.negara} • ${LayananKonversi.formatMataUangAsing(item.hargaAsli, item.kodeMataUang)} x ${item.jumlah}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    trailing: Text(
                      LayananKonversi.formatRupiah(item.totalHargaIdr),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Pilihan Cara Serah Terima Barang (Oleh Pemesan)
            const Text(
              'Cara Serah Terima Barang (Opsi Pemesan):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tentukan cara Anda mengambil pesanan. Traveler luar negeri akan menyesuaikan pilihan Anda.',
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                children: [
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    activeColor: Colors.teal.shade800,
                    value: 'COD_LBS',
                    // ignore: deprecated_member_use
                    groupValue: _metodePenyerahan,
                    title: const Text('📍 Ambil Sendiri / Ketemuan COD (LBS Google Maps)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    subtitle: const Text('Ketemuan di Hub Kampus UPN Condongcatur / Bandara YIA dengan petunjuk rute Google Maps.', style: TextStyle(fontSize: 10.5)),
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _metodePenyerahan = val!),
                  ),
                  const Divider(height: 1),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    activeColor: Colors.teal.shade800,
                    value: 'KURIR_ANTAR',
                    // ignore: deprecated_member_use
                    groupValue: _metodePenyerahan,
                    title: const Text('🚚 Diantar Kurir ke Rumah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    subtitle: const Text('Traveler mengirimkan paket titipan lewat JNE / SiCepat ke alamat rumah Anda.', style: TextStyle(fontSize: 10.5)),
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _metodePenyerahan = val!),
                  ),
                  if (_metodePenyerahan == 'KURIR_ANTAR') ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _alamatController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Alamat Rumah Tujuan Pengiriman',
                          labelStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.home_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pilihan Metode Pembayaran
            const Text(
              'Metode Pembayaran (Simulasi):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _metodePembayaran = 'QRIS'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _metodePembayaran == 'QRIS' ? Colors.teal.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _metodePembayaran == 'QRIS' ? Colors.teal.shade700 : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.teal.shade700, size: 32),
                          const SizedBox(height: 6),
                          const Text('QRIS Nasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _metodePembayaran = 'Transfer Bank'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _metodePembayaran == 'Transfer Bank' ? Colors.teal.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _metodePembayaran == 'Transfer Bank' ? Colors.teal.shade700 : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance, color: Colors.teal.shade700, size: 32),
                          const SizedBox(height: 6),
                          const Text('Virtual Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilan Detail Pembayaran Sesuai Metode
            if (_metodePembayaran == 'QRIS') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Scan Kode QRIS Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text('NMID: ID102008691234 • JastipGo Merchant', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Rekening Bank Tujuan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _bankPilihan,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['BCA', 'Mandiri', 'BNI', 'BRI'].map((b) {
                        return DropdownMenuItem(value: b, child: Text('Bank $b Virtual Account'));
                      }).toList(),
                      onChanged: (val) => setState(() => _bankPilihan = val!),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nomor Rekening Virtual:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text('8273 0812 3456 7890', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              LayananNotifikasi.kirimNotifikasi(
                                context,
                                judul: 'Nomor VA Disalin',
                                pesan: 'Nomor Virtual Account Bank $_bankPilihan berhasil disalin.',
                                ikon: Icons.copy,
                              );
                            },
                            child: const Text('SALIN'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Kupon Diskon & Voucher Promo Jastip
            const Text(
              'Voucher & Diskon Promo Jastip:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gunakan voucher dari Shake Promo atau Mini Game untuk memotong total biaya titip.',
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_voucherTerpilih != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _voucherTerpilih!.judul,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'Hemat ${LayananKonversi.formatRupiah(_voucherTerpilih!.potonganIdr)} (${_voucherTerpilih!.kode})',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                            onPressed: () => setState(() => _voucherTerpilih = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_daftarVoucherTersedia.isNotEmpty) ...[
                    const Text(
                      'Pilih Voucher yang Tersedia:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _daftarVoucherTersedia.map((v) {
                          final isSelected = _voucherTerpilih?.kode == v.kode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              backgroundColor: isSelected ? Colors.amber.shade200 : Colors.amber.shade50,
                              avatar: Icon(Icons.card_giftcard, size: 16, color: Colors.amber.shade900),
                              label: Text(
                                '${v.kode} (-${LayananKonversi.formatRupiah(v.potonganIdr)})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _voucherTerpilih = isSelected ? null : v;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kodePromoManualController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Ketik kode promo (misal: SHAKE50)',
                            hintStyle: const TextStyle(fontSize: 11.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _terapkanKodePromoManual,
                        child: const Text('PAKAI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan Pembayaran
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Harga Barang:', style: TextStyle(color: Colors.black54)),
                      Text(LayananKonversi.formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Biaya Penanganan Jastip (5%):', style: TextStyle(color: Colors.black54)),
                      Text(LayananKonversi.formatRupiah(_biayaJasaTitip), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_voucherTerpilih != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Potongan Diskon (${_voucherTerpilih!.kode}):', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('- ${LayananKonversi.formatRupiah(_potonganVoucher)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan Akhir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        LayananKonversi.formatRupiah(_totalBayar),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Konfirmasi dengan Sensor Sidik Jari
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                onPressed: _sedangMemproses ? null : _prosesKonfirmasiPembayaran,
                icon: const Icon(Icons.fingerprint, size: 24),
                label: _sedangMemproses
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'BAYAR DENGAN SIDIK JARI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '🔒 Transaksi diamankan dengan Kriptografi Hash SHA-256 Blockchain',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
