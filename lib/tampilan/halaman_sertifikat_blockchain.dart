import 'package:flutter/material.dart';
import 'halaman_dompet_rekber.dart';

/// Halaman Sertifikat Blockchain telah dimigrasikan menjadi Halaman Dompet Rekber (Escrow)
/// sesuai instruksi TODO_PERUBAHAN_REKBER.
/// Widget ini bertindak sebagai drop-in replacement dan alias untuk HalamanDompetRekber.
class HalamanSertifikatBlockchain extends StatelessWidget {
  const HalamanSertifikatBlockchain({super.key});

  @override
  Widget build(BuildContext context) {
    return const HalamanDompetRekber();
  }
}
