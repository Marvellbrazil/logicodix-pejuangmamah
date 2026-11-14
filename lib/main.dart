import 'package:flutter/material.dart';

import 'application/ask_assistant.dart';
import 'infrastructure/api_assistant.dart';
import 'infrastructure/api_auth.dart';
import 'infrastructure/api_chats.dart';
import 'infrastructure/api_client.dart';
import 'infrastructure/api_jobs.dart';
import 'infrastructure/api_profile.dart';
import 'infrastructure/google_token_provider.dart';
import 'infrastructure/secure_token_store.dart';
import 'presentation/app.dart';
import 'presentation/app_state.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = ApiClient(baseUrl: _apiBaseUrl);
  final google = GoogleTokenProvider(serverClientId: _googleServerClientId);
  final tokens = const SecureTokenStore();

  runApp(
    KerjaqueueApp(
      state: AppState(
        client: client,
        auth: ApiAuth(client),
        profiles: ApiProfile(client),
        jobs: ApiJobs(client),
        applications: ApiJobs(client),
        chats: ApiChats(client),
        tokens: tokens,
      ),
      askAssistant: AskAssistant(ApiAssistantGateway(client)),
      google: google,
    ),
  );
}
