import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/paper.dart';
import 'package:paper_tracker/utils/export_service.dart';

void main() {
  group('PaperExportService Tests', () {
    final samplePapers = <Paper>[
      Paper(
        id: 'p1',
        title: 'Deep Learning in Academic Workflows',
        status: PaperStatus.writing,
        priority: PaperPriority.high,
        targetVenue: 'IEEE Transactions',
        authors: const ['Mahmoud Aljawarneh', 'Jane Doe'],
        leadAuthorId: 'u1',
        authorIds: const ['u1', 'u2'],
        tags: const ['AI', 'Productivity'],
        abstract_: 'An empirical study of AI-driven research workflows.',
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 20),
        deadline: DateTime(2025, 6, 30),
      ),
      Paper(
        id: 'p2',
        title: 'Next-Gen Research: Fast & Secure',
        status: PaperStatus.published,
        priority: PaperPriority.medium,
        targetVenue: 'ACM Computing Surveys',
        authors: const ['Jane Doe'],
        leadAuthorId: 'u2',
        authorIds: const ['u2'],
        tags: const ['Security'],
        abstract_: 'A survey of security techniques.',
        createdAt: DateTime(2024, 5, 1),
        updatedAt: DateTime(2024, 6, 1),
      ),
    ];

    test('toBibTeX formats correctly with keys and fields', () {
      final bib = PaperExportService.toBibTeX(samplePapers);

      expect(bib.contains('@article{aljawarneh_2025_deep,'), isTrue);
      expect(bib.contains('title = {Deep Learning in Academic Workflows}'), isTrue);
      expect(bib.contains('author = {Mahmoud Aljawarneh and Jane Doe}'), isTrue);
      expect(bib.contains('journal = {IEEE Transactions}'), isTrue);
      expect(bib.contains('year = {2025}'), isTrue);
      expect(bib.contains('keywords = {AI, Productivity}'), isTrue);
      expect(bib.contains('note = {Status: Writing}'), isTrue);
      // Escaping test
      expect(bib.contains(r'\&'), isTrue);
    });

    test('toCSV outputs valid header and data rows', () {
      final csv = PaperExportService.toCSV(samplePapers);
      final lines = csv.trim().split('\n');

      expect(lines.length, equals(3));
      expect(lines[0], contains('ID,Title,Status,Priority'));
      expect(lines[1], contains('p1,Deep Learning in Academic Workflows,Writing,High'));
      expect(lines[2], contains('p2,Next-Gen Research: Fast & Secure,Published,Medium'));
    });
  });
}
