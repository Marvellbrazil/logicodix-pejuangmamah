import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pejuangmamah/application/ask_assistant.dart';
import 'package:pejuangmamah/application/api_contracts.dart';
import 'package:pejuangmamah/application/assistant_gateway.dart';
import 'package:pejuangmamah/infrastructure/api_auth.dart';
import 'package:pejuangmamah/infrastructure/api_chats.dart';
import 'package:pejuangmamah/infrastructure/api_client.dart';
import 'package:pejuangmamah/infrastructure/api_jobs.dart';
import 'package:pejuangmamah/infrastructure/api_profile.dart';
import 'package:pejuangmamah/infrastructure/google_token_provider.dart';
import 'package:pejuangmamah/presentation/app.dart';
import 'package:pejuangmamah/presentation/app_state.dart';

const worker = {
  'id': 'u1',
  'fullName': 'Rina Pratiwi',
  'displayName': 'Rina',
  'headline': 'Barista & pelayanan',
  'district': 'Rungkut',
  'bio': '',
  'skills': ['Barista', 'Pelayanan'],
  'experience': <Object>[],
  'role': 'worker',
  'email': 'rina@kerjaqueue.local',
  'phone': '',
  'maxDistanceKm': 6.0,
  'minPay': 90000,
  'startHour': 6,
  'endHour': 18,
  'hasPassword': true,
  'hasGoogle': false,
};

final emptyWorker = <String, dynamic>{
  ...worker,
  'fullName': '',
  'displayName': '',
  'headline': '',
  'district': '',
  'skills': <String>[],
};

const jobPayload = {
  'id': 'j1',
  'employerId': 'e1',
  'title': 'Barista shift pagi',
  'company': 'Kopi Jempol',
  'category': 'Kuliner',
  'description': 'Bantu buka gerai dan seduh kopi manual.',
  'pay': 120000,
  'payPeriod': 'per hari',
  'district': 'Rungkut',
  'distanceKm': 1.2,
  'startHour': 7,
  'endHour': 12,
  'urgency': 'today',
  'skills': ['Barista'],
  'contact': '6281234500011',
  'filled': false,
  'createdAt': '2026-11-14T08:00:00.000Z',
  'employer': {
    'id': 'e1',
    'fullName': 'Budi Santoso',
    'displayName': 'Budi',
    'headline': 'Pemilik Kopi Jempol',
  },
  'application': null,
  'applicantCount': 0,
};

class MemoryTokens implements TokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}

class _NoGoogle extends GoogleTokenProvider {
  _NoGoogle() : super(serverClientId: '');

  @override
  Future<String?> requestIdToken() async => null;
}

class _OfflineGateway implements AssistantGateway {
  @override
  bool get available => false;

  @override
  Future<String> reply({
    required String systemPrompt,
    required List<(String role, String text)> history,
  }) async => '';
}

class Harness {
  Harness({String? initialToken, bool onboarded = true})
    : user = Map<String, dynamic>.from(onboarded ? worker : emptyWorker) {
    tokens.value = initialToken;
  }

  final Map<String, dynamic> user;
  final MemoryTokens tokens = MemoryTokens();
  final List<String> calls = [];
  late ApiClient client;
  late AppState state;

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  MockClient build() => MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');

    if (path == '/api/auth/login') {
      return _json({'token': 'token-1', 'user': user});
    }
    if (path == '/api/auth/register') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      user['fullName'] = body['fullName'];
      user['displayName'] = body['displayName'];
      user['role'] = body['role'];
      user['district'] = '';
      user['skills'] = <String>[];
      return _json({'token': 'token-2', 'user': user}, 201);
    }
    if (path == '/api/me') {
      if (request.method == 'PATCH') {
        final patch = jsonDecode(request.body) as Map<String, dynamic>;
        user.addAll(patch);
        return _json({'user': user});
      }
      return _json({
        'user': user,
        'stats': {'applications': 1, 'jobs': 0, 'chats': 1},
      });
    }
    if (path == '/api/jobs') {
      return _json({
        'jobs': [jobPayload],
        'categories': ['Kuliner'],
      });
    }
    if (path == '/api/jobs/j1' && request.method == 'GET') {
      return _json({'job': jobPayload});
    }
    if (path == '/api/jobs/j1/apply') {
      return _json({
        'application': {
          'id': 'a1',
          'status': 'sent',
          'createdAt': '2026-11-14T09:00:00.000Z',
          'chatId': 'c1',
          'job': {
            'id': 'j1',
            'title': jobPayload['title'],
            'company': jobPayload['company'],
            'pay': jobPayload['pay'],
            'payPeriod': jobPayload['payPeriod'],
            'district': jobPayload['district'],
            'urgency': jobPayload['urgency'],
            'employerId': 'e1',
            'employerName': 'Budi Santoso',
            'employerDisplayName': 'Budi',
          },
        },
        'chatId': 'c1',
      }, 201);
    }
    if (path == '/api/applications/mine') {
      return _json({
        'applications': [
          {
            'id': 'a1',
            'status': 'sent',
            'createdAt': '2026-11-14T09:00:00.000Z',
            'chatId': 'c1',
            'job': {
              'id': 'j1',
              'title': jobPayload['title'],
              'company': jobPayload['company'],
              'pay': jobPayload['pay'],
              'payPeriod': jobPayload['payPeriod'],
              'district': jobPayload['district'],
              'urgency': jobPayload['urgency'],
              'employerId': 'e1',
              'employerName': 'Budi Santoso',
              'employerDisplayName': 'Budi',
            },
          },
        ],
      });
    }
    if (path == '/api/applications/inbox') {
      return _json({'applications': <Object>[]});
    }
    if (path == '/api/chats') {
      return _json({
        'chats': [
          {
            'id': 'c1',
            'jobId': 'j1',
            'applicationId': 'a1',
            'jobTitle': 'Barista shift pagi',
            'company': 'Kopi Jempol',
            'counterpart': {
              'id': 'e1',
              'fullName': 'Budi Santoso',
              'displayName': 'Budi',
            },
            'lastMessage': 'Kapan bisa mulai?',
            'lastMessageAt': '2026-11-14T09:05:00.000Z',
            'lastSenderId': 'e1',
            'unread': 1,
          },
        ],
        'unread': 1,
      });
    }
    if (path == '/api/chats/c1/messages') {
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'message': {
            'id': 'm2',
            'chatId': 'c1',
            'senderId': 'u1',
            'body': body['body'],
            'createdAt': '2026-11-14T09:10:00.000Z',
            'mine': true,
          },
        }, 201);
      }
      return _json({
        'chat': {
          'id': 'c1',
          'jobId': 'j1',
          'jobTitle': 'Barista shift pagi',
          'company': 'Kopi Jempol',
          'counterpart': {
            'id': 'e1',
            'fullName': 'Budi Santoso',
            'displayName': 'Budi',
          },
          'lastMessage': 'Kapan bisa mulai?',
          'lastMessageAt': '2026-11-14T09:05:00.000Z',
          'unread': 1,
        },
        'messages': [
          {
            'id': 'm1',
            'chatId': 'c1',
            'senderId': 'e1',
            'body': 'Kapan bisa mulai?',
            'createdAt': '2026-11-14T09:05:00.000Z',
            'mine': false,
          },
        ],
      });
    }
    if (path == '/api/chats/c1/read') {
      return _json({'ok': true});
    }
    if (path == '/api/users') {
      return _json({
        'people': [
          {
            'id': 'e1',
            'fullName': 'Budi Santoso',
            'displayName': 'Budi',
            'headline': 'Pemilik Kopi Jempol',
            'district': 'Rungkut',
            'bio': '',
            'skills': ['Wirausaha'],
            'experience': <Object>[],
            'role': 'employer',
            'openJobs': 2,
          },
        ],
      });
    }
    if (path.startsWith('/api/users/')) {
      return _json({
        'user': {
          'id': 'e1',
          'fullName': 'Budi Santoso',
          'displayName': 'Budi',
          'headline': 'Pemilik Kopi Jempol',
          'district': 'Rungkut',
          'bio': 'Dua gerai kopi kecil.',
          'skills': ['Wirausaha'],
          'experience': <Object>[],
          'role': 'employer',
        },
        'openJobs': <Object>[],
      });
    }
    if (path == '/api/assistant') {
      return _json({}, 503);
    }
    return _json({
      'error': {'code': 'not_found', 'message': 'Tidak ada: $path'},
    }, 404);
  });

  ApiClient get apiClient => client;

  Future<AppState> boot() async {
    client = ApiClient(baseUrl: 'http://test', client: build());
    state = AppState(
      client: client,
      auth: ApiAuth(client),
      profiles: ApiProfile(client),
      jobs: ApiJobs(client),
      applications: ApiJobs(client),
      chats: ApiChats(client),
      tokens: tokens,
    );
    return state;
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('first run opens landing before account actions', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness();
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    expect(find.text('Kesempatan kerja\\nada di dekatmu.'), findsOneWidget);
    expect(find.text('Buat akun gratis'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Masuk ke Kerjaqueue'), findsNothing);
  });

  testWidgets('landing Masuk membuka login saja', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness();
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Masuk').first);
    await settle(tester);

    expect(find.text('Masuk ke Kerjaqueue'), findsOneWidget);
    expect(find.text('Buat akun profesionalmu'), findsNothing);
  });

  testWidgets('landing buat akun membuka form registrasi', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness();
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Buat akun gratis'));
    await settle(tester);

    expect(find.text('Buat akun profesionalmu'), findsOneWidget);
    expect(find.text('Nama lengkap'), findsOneWidget);
    expect(find.text('Nama panggilan'), findsOneWidget);
  });

  testWidgets('tanpa sesi, layar masuk tampil dengan Google dan email', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1600);
    addTearDown(tester.view.reset);

    final harness = Harness();
    final state = await harness.boot();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => KerjaqueueApp(
            state: state,
            askAssistant: AskAssistant(_OfflineGateway()),
            google: _NoGoogle(),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Masuk ke Kerjaqueue'), findsOneWidget);
    expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
    expect(find.text('Daftar gratis'), findsOneWidget);
    expect(find.text('Lanjutkan sebagai tamu'), findsNothing);
  });

  testWidgets('daftar meminta nama lengkap dan nama panggilan', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1600);
    addTearDown(tester.view.reset);

    final harness = Harness();
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Daftar gratis'));
    await tester.pumpAndSettle();

    expect(find.text('Buat akun profesionalmu'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nama lengkap'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nama panggilan'), findsOneWidget);

    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();
    expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
  });

  testWidgets('masuk lalu onboarding muncul karena profil belum lengkap', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(onboarded: false);
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'rina@kerjaqueue.local',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata sandi'),
      'rahasia123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await settle(tester);

    expect(find.text('Kenalkan dirimu'), findsOneWidget);
    expect(find.text('Langkah 1 dari 3'), findsOneWidget);
  });

  testWidgets('sesi tersimpan membuka beranda dengan kartu lowongan', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    expect(find.text('Kerjaqueue'), findsOneWidget);
    expect(find.text('Halo, Rina'), findsOneWidget);
    expect(find.text('Barista shift pagi'), findsWidgets);
    expect(find.text('ANTREAN HARI INI'), findsOneWidget);
    expect(harness.tokens.value, 'token-1');
  });

  testWidgets('melamar dari beranda membuat lamaran terkirim', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Lamar').first);
    await settle(tester);

    expect(
      harness.calls.contains('POST /api/jobs/j1/apply'),
      true,
      reason: 'lamaran harus dikirim ke server',
    );
    expect(find.textContaining('Lamaran untuk'), findsWidgets);
  });

  testWidgets('tab lamaran menampilkan status lamaran', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Lamaran'));
    await settle(tester);

    expect(find.text('Lamaran saya'), findsOneWidget);
    expect(find.text('Terkirim'), findsWidgets);
    expect(find.text('Tarik lamaran'), findsWidgets);
  });

  testWidgets('tab pesan menampilkan percakapan dengan penghitung', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Pesan'));
    await settle(tester);

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Kapan bisa mulai?'), findsOneWidget);
  });

  testWidgets('profil menampilkan nama lengkap, nama panggilan, statistik', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 2200);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);

    expect(find.text('Rina Pratiwi'), findsOneWidget);
    expect(find.text('“Rina”'), findsOneWidget);
    expect(find.text('Barista & pelayanan'), findsWidgets);
    expect(find.text('Lamaran'), findsWidgets);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('asisten memakai jawaban lokal saat gateway mati', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1900);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Asisten'));
    await settle(tester);

    await tester.tap(find.text('Lowongan apa yang paling cocok untukku?'));
    await settle(tester);

    expect(find.textContaining('Yang paling cocok'), findsOneWidget);
  });

  testWidgets('keluar akun kembali ke layar masuk dan menghapus token', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 2200);
    addTearDown(tester.view.reset);

    final harness = Harness(initialToken: 'token-1');
    final state = await harness.boot();

    await tester.pumpWidget(
      KerjaqueueApp(
        state: state,
        askAssistant: AskAssistant(_OfflineGateway()),
        google: _NoGoogle(),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await settle(tester);

    expect(find.text('Masuk ke Kerjaqueue'), findsOneWidget);
    expect(harness.tokens.value, null);
  });
}
