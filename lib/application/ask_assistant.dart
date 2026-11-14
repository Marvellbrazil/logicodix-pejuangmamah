import '../domain/job.dart';
import '../domain/match.dart';
import '../domain/money.dart';
import '../domain/profile.dart';
import 'assistant_gateway.dart';

const assistantSystemPrompt = '''
Kamu adalah Asisten Kerjaqueue, pendamping pencari kerja harian di Indonesia.
Tugasmu:
1. Membantu pengguna melengkapi profil kerja lewat percakapan santai (nama panggilan, keahlian, kecamatan, jam tersedia, upah minimum per hari, pengalaman).
2. Menjelaskan lowongan terdekat dengan alasan konkret memakai skor kecocokan yang diberikan.
3. Memberi saran upah atau cara menegosiasi dengan sopan.
Gunakan bahasa Indonesia sederhana, maksimal 90 kata, dan jangan mengarang lowongan di luar daftar yang ada. Jika informasi kunci belum ada, tanyakan satu hal saja per balasan.''';

class AssistantTurn {
  const AssistantTurn({required this.text, this.status = ''});

  final String text;
  final String status;
}

class AskAssistant {
  const AskAssistant(this._gateway);

  final AssistantGateway _gateway;

  bool get gatewayAvailable => _gateway.available;

  Future<AssistantTurn> call({
    required String question,
    required List<(String role, String text)> history,
    required Profile profile,
    required List<Match> ranked,
  }) async {
    if (!_gateway.available) {
      return AssistantTurn(text: _localAnswer(question, profile, ranked));
    }
    try {
      final reply = await _gateway.reply(
        systemPrompt: '$assistantSystemPrompt\n\n${_jobsBlock(ranked)}',
        history: [...history, ('user', question)],
      );
      final trimmed = reply.trim();
      if (trimmed.isEmpty) {
        return AssistantTurn(
          text: _localAnswer(question, profile, ranked),
          status: 'Jawaban AI kosong, memakai saran lokal.',
        );
      }
      return AssistantTurn(text: trimmed);
    } on AssistantUnavailable {
      return AssistantTurn(
        text: _localAnswer(question, profile, ranked),
        status: 'Asisten AI sedang offline, memakai saran lokal.',
      );
    }
  }

  static String _jobsBlock(List<Match> ranked) {
    if (ranked.isEmpty) return 'Belum ada lowongan aktif.';
    final top = ranked.take(5).map(
      (m) =>
          '- ${m.job.title} di ${m.job.company} (${m.job.district}), '
          '${m.job.money.formatShort()} ${m.job.payPeriod}, ${m.job.distanceKm} km, '
          'skor ${m.score}. Alasan: ${m.reasons.join("; ")}. '
          'Kekurangan: ${m.gaps.join("; ")}.',
    );
    return 'Lowongan teratas:\n${top.join("\n")}';
  }

  static String _localAnswer(
    String question,
    Profile profile,
    List<Match> ranked,
  ) {
    final lower = question.toLowerCase();
    if (!profile.hasSkills) {
      return 'Biar rekomendasinya akurat, isi dulu Profil: keahlianmu, kecamatan, '
          'jam tersedia, dan upah minimum. Setelah itu tanya lagi ya.';
    }
    if (ranked.isEmpty) {
      return 'Belum ada lowongan aktif. Coba cek lagi nanti atau ubah Profil '
          'supaya jangkauanmu lebih luas.';
    }
    final wantsToday =
        lower.contains('hari ini') || lower.contains('sekarang');
    final wantsPay = lower.contains('upah') || lower.contains('gaji');
    final candidates = wantsToday
        ? ranked.where((m) => m.job.urgency == JobUrgency.today).toList()
        : ranked;
    if (wantsPay) {
      final sorted = [...ranked]
        ..sort((a, b) => b.job.pay.compareTo(a.job.pay));
      final top = sorted.first;
      final lines = [
        'Upah tertinggi ${top.job.money.format()} ${top.job.payPeriod} untuk '
            '${top.job.title}, target minimalmu ${Money(profile.minPay).format()}.',
      ];
      for (final m in sorted.skip(1).take(2)) {
        lines.add('Berikutnya ${m.job.title}: ${m.job.money.format()}.');
      }
      return lines.join(' ');
    }

    final pool = (candidates.isEmpty ? ranked : candidates).take(3).toList();
    final top = pool.first;
    final lines = <String>[
      'Yang paling cocok: ${top.job.title} di ${top.job.company}.',
      'Skor ${top.score}/100. ${top.reasons.take(2).join(". ")}.',
      if (top.gaps.isNotEmpty) 'Catatan: ${top.gaps.first}.',
      for (final m in pool.skip(1)) 'Cadangan: ${m.job.title}, skor ${m.score}.',
    ];
    return lines.join(' ');
  }
}
