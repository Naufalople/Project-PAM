import 'package:flutter_test/flutter_test.dart';
import 'package:project_pam/main.dart';

void main() {
  testWidgets('Uji pemuatan awal aplikasi JastipGo', (WidgetTester tester) async {
    // Bangun aplikasi JastipGo dan picu frame awal
    await tester.pumpWidget(const AplikasiJastipGo(sudahMasuk: false));

    // Verifikasi bahwa judul aplikasi JastipGo muncul di layar
    expect(find.text('JastipGo'), findsOneWidget);
  });
}
