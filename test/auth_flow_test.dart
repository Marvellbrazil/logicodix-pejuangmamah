import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pejuangmamah/application/auth_repository.dart';
import 'package:pejuangmamah/application/receipt_parser.dart';
import 'package:pejuangmamah/application/scan_receipt.dart';
import 'package:pejuangmamah/domain/receipt.dart';
import 'package:pejuangmamah/domain/user_account.dart';
import 'package:pejuangmamah/presentation/app.dart';

const _user = UserAccount(
  id: '1',
  email: 'budi@example.com',
  name: 'Budi',
);

class _FakeAuth implements AuthRepository {
  UserAccount? restored;
  UserAccount? next = _user;
  bool fail = false;
  int signOuts = 0;

  @override
  Future<UserAccount?> restore() async => restored;

  @override
  Future<UserAccount?> signIn() async {
    if (fail) throw const AuthFailure('boom');
    return next;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

class _EmptyReceipts implements ReceiptRepository {
  @override
  Future<List<Receipt>> all() async => const [];

  @override
  Future<Receipt> save(Receipt receipt) async => receipt;

  @override
  Future<void> delete(int id) async {}
}

class _NoText implements ReceiptTextReader {
  @override
  Future<List<String>> readRows(String imagePath) async => const [];
}

Future<void> _pumpApp(WidgetTester tester, _FakeAuth auth) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    PejuangMamahApp(
      repository: _EmptyReceipts(),
      scanReceipt: ScanReceipt(_NoText(), ReceiptParser()),
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guest enters home without signing in', (tester) async {
    await _pumpApp(tester, _FakeAuth());

    await tester.tap(find.text('Lanjut sebagai tamu'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada nota'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Tamu'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });

  testWidgets('google sign in shows the account on profile', (tester) async {
    await _pumpApp(tester, _FakeAuth());

    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('failed sign in stays on welcome and explains', (tester) async {
    await _pumpApp(tester, _FakeAuth()..fail = true);

    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal masuk dengan Google'), findsOneWidget);
    expect(find.text('Lanjut sebagai tamu'), findsOneWidget);
  });

  testWidgets('cancelled sign in stays on welcome silently', (tester) async {
    await _pumpApp(tester, _FakeAuth()..next = null);

    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal'), findsNothing);
    expect(find.text('Lanjut sebagai tamu'), findsOneWidget);
  });

  testWidgets('restored session skips the welcome screen', (tester) async {
    await _pumpApp(tester, _FakeAuth()..restored = _user);

    expect(find.text('Belum ada nota'), findsOneWidget);
    expect(find.text('Lanjut sebagai tamu'), findsNothing);
  });

  testWidgets('sign out returns to welcome', (tester) async {
    final auth = _FakeAuth()..restored = _user;
    await _pumpApp(tester, auth);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(find.text('Lanjut sebagai tamu'), findsOneWidget);
  });
}
