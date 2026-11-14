import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pejuangmamah/domain/profile.dart';
import 'package:pejuangmamah/infrastructure/api_auth.dart';
import 'package:pejuangmamah/infrastructure/api_chats.dart';
import 'package:pejuangmamah/infrastructure/api_client.dart';
import 'package:pejuangmamah/infrastructure/api_jobs.dart';
import 'package:pejuangmamah/infrastructure/api_profile.dart';

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> userJson({String role = 'worker'}) => {
  'id': 'u1',
  'fullName': 'Rina Pratiwi',
  'displayName': 'Rina',
  'headline': 'Barista',
  'district': 'Rungkut',
  'bio': '',
  'skills': ['Barista'],
  'experience': <Object>[],
  'role': role,
  'email': 'rina@kerjaqueue.local',
  'maxDistanceKm': 5,
  'minPay': 50000,
  'startHour': 8,
  'endHour': 17,
  'hasPassword': true,
  'hasGoogle': false,
};

ApiClient clientWith(MockClient mock) =>
    ApiClient(baseUrl: 'http://test', client: mock);

void main() {
  group('ApiClient', () {
    test('menyertakan Bearer token setelah setToken', () async {
      String? auth;
      final mock = MockClient((request) async {
        auth = request.headers['authorization'];
        return json({'user': userJson()});
      });
      final client = clientWith(mock)..setToken('abc');
      await ApiProfile(client).me('abc');
      expect(auth, 'Bearer abc');
    });

    test('menerjemahkan galat server ke ApiFailure berbahasa Indonesia', () async {
      final client = clientWith(
        MockClient(
          (_) async => json({
            'error': {'code': 'unauthorized', 'message': 'Email atau kata sandi salah.'},
          }, 401),
        ),
      );
      try {
        await ApiAuth(client).login(email: 'a@b.c', password: 'x');
        fail('seharusnya melempar');
      } catch (error) {
        expect('$error', contains('Email atau kata sandi salah.'));
      }
    });

    test('mengulang GET sekali saat server 500', () async {
      var calls = 0;
      final client = clientWith(
        MockClient((_) async {
          calls += 1;
          return calls == 1
              ? json({'error': {'message': 'gagal'}}, 500)
              : json({'user': userJson()});
        }),
      );
      await ApiProfile(client).me('token');
      expect(calls, 2);
    });

    test('melaporkan offline saat koneksi gagal', () async {
      final client = clientWith(
        MockClient((_) async => throw const SocketExceptionStub()),
      );
      try {
        await ApiProfile(client).me('token');
        fail('seharusnya melempar');
      } catch (error) {
        expect('$error', contains('offline'));
      }
    });
  });

  group('ApiAuth', () {
    test('register mengirim nama lengkap dan nama panggilan', () async {
      Map<String, dynamic>? payload;
      final client = clientWith(
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return json({'token': 't', 'user': userJson()}, 201);
        }),
      );
      final session = await ApiAuth(client).register(
        email: 'r@k.local',
        password: 'rahasia123',
        fullName: 'Rina Pratiwi',
        displayName: 'Rina',
        role: UserRole.worker,
      );
      expect(payload?['fullName'], 'Rina Pratiwi');
      expect(payload?['displayName'], 'Rina');
      expect(session.token, 't');
      expect(session.profile.displayName, 'Rina');
    });

    test('google mengirim idToken dan peran', () async {
      Map<String, dynamic>? payload;
      final client = clientWith(
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return json({'token': 'g', 'user': userJson(role: 'employer')}, 201);
        }),
      );
      final session = await ApiAuth(client).googleSignIn(
        idToken: 'id-token-panjang-sekali-ya',
        role: UserRole.employer,
      );
      expect(payload?['role'], 'employer');
      expect(session.profile.isEmployer, true);
    });
  });

  group('ApiJobs', () {
    test('feed memetakan query filter', () async {
      Uri? uri;
      final client = clientWith(
        MockClient((request) async {
          uri = request.url;
          return json({
            'jobs': [
              {
                'id': 'j1',
                'employerId': 'e1',
                'title': 'Barista',
                'company': 'Kopi',
                'category': 'Kuliner',
                'description': 'd',
                'pay': 120000,
                'payPeriod': 'per hari',
                'district': 'Rungkut',
                'distanceKm': 1.2,
                'startHour': 7,
                'endHour': 12,
                'urgency': 'today',
                'skills': <String>[],
                'filled': false,
                'createdAt': '2026-11-14T08:00:00.000Z',
              },
            ],
            'categories': ['Kuliner'],
          });
        }),
      );
      final feed = await ApiJobs(client).feed('t', q: 'barista', category: 'Kuliner');
      expect(uri?.queryParameters['q'], 'barista');
      expect(uri?.queryParameters['category'], 'Kuliner');
      expect(feed.jobs.single.title, 'Barista');
      expect(feed.categories, ['Kuliner']);
    });

    test('apply mengembalikan lamaran dan chatId', () async {
      final client = clientWith(
        MockClient(
          (_) async => json({
            'application': {
              'id': 'a1',
              'status': 'sent',
              'createdAt': '2026-11-14T08:00:00.000Z',
              'job': {
                'id': 'j1',
                'title': 'Barista',
                'company': 'Kopi',
                'pay': 120000,
                'payPeriod': 'per hari',
                'district': 'Rungkut',
                'urgency': 'today',
                'employerId': 'e1',
                'employerName': 'Budi',
                'employerDisplayName': 'Budi',
              },
            },
            'chatId': 'c1',
          }, 201),
        ),
      );
      final (application, chatId) = await ApiJobs(client).apply('t', 'j1');
      expect(application.status.name, 'sent');
      expect(application.jobTitle, 'Barista');
      expect(chatId, 'c1');
    });
  });

  group('ApiChats', () {
    test('list memetakan ringkasan dan jumlah belum dibaca', () async {
      final client = clientWith(
        MockClient(
          (_) async => json({
            'chats': [
              {
                'id': 'c1',
                'jobId': 'j1',
                'applicationId': 'a1',
                'jobTitle': 'Barista',
                'company': 'Kopi',
                'counterpart': {
                  'id': 'e1',
                  'fullName': 'Budi Santoso',
                  'displayName': 'Budi',
                },
                'lastMessage': 'Bisa mulai besok?',
                'lastMessageAt': '2026-11-14T09:00:00.000Z',
                'lastSenderId': 'e1',
                'unread': 2,
              },
            ],
            'unread': 2,
          }),
        ),
      );
      final (chats, unread) = await ApiChats(client).list('t');
      expect(chats.single.counterpart.initials, 'BS');
      expect(chats.single.unread, 2);
      expect(unread, 2);
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
