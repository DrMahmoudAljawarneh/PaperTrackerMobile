import 'package:intl/intl.dart';
import 'package:paper_tracker/models/paper.dart';

class PaperExportService {
  PaperExportService._();

  /// Formats a list of papers as standard BibTeX entries suitable for LaTeX.
  static String toBibTeX(List<Paper> papers) {
    final buffer = StringBuffer();

    for (var i = 0; i < papers.length; i++) {
      final paper = papers[i];
      final key = _generateBibKey(paper, i);
      final year = paper.deadline?.year ?? paper.createdAt.year;

      buffer.writeln('@article{$key,');
      buffer.writeln('  title = {${_escapeBib(paper.title)}},');

      if (paper.authors.isNotEmpty) {
        buffer.writeln('  author = {${paper.authors.map(_escapeBib).join(' and ')}},');
      } else if (paper.leadAuthorId.isNotEmpty) {
        buffer.writeln('  author = {${_escapeBib(paper.leadAuthorId)}},');
      }

      if (paper.targetVenue.isNotEmpty) {
        buffer.writeln('  journal = {${_escapeBib(paper.targetVenue)}},');
      }

      buffer.writeln('  year = {$year},');

      if (paper.tags.isNotEmpty) {
        buffer.writeln('  keywords = {${paper.tags.map(_escapeBib).join(', ')}},');
      }

      if (paper.abstract_.isNotEmpty) {
        buffer.writeln('  abstract = {${_escapeBib(paper.abstract_)}},');
      }

      buffer.writeln('  note = {Status: ${paper.status.label}}');
      buffer.writeln('}');
      if (i < papers.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Formats a list of papers as RFC 4180 compliant CSV.
  static String toCSV(List<Paper> papers) {
    final buffer = StringBuffer();
    final headers = [
      'ID',
      'Title',
      'Status',
      'Priority',
      'Target Venue',
      'Lead Author',
      'Authors',
      'Tags',
      'Created Date',
      'Deadline',
    ];

    buffer.writeln(headers.map(_escapeCsv).join(','));

    for (final paper in papers) {
      final row = [
        paper.id,
        paper.title,
        paper.status.label,
        paper.priority.label,
        paper.targetVenue,
        paper.leadAuthorId,
        paper.authors.join('; '),
        paper.tags.join('; '),
        DateFormat('yyyy-MM-dd').format(paper.createdAt),
        paper.deadline != null ? DateFormat('yyyy-MM-dd').format(paper.deadline!) : '',
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    return buffer.toString();
  }

  static String _generateBibKey(Paper paper, int fallbackIndex) {
    final authorPart = paper.authors.isNotEmpty
        ? paper.authors.first.split(' ').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()
        : 'paper';
    final yearPart = (paper.deadline?.year ?? paper.createdAt.year).toString();
    final titleWord = paper.title
        .trim()
        .split(RegExp(r'\s+'))
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();

    if (authorPart.isEmpty && titleWord.isEmpty) {
      return 'ref_$fallbackIndex';
    }
    return '${authorPart}_${yearPart}_$titleWord';
  }

  static String _escapeBib(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}')
        .replaceAll(r'$', r'\$')
        .replaceAll('%', r'\%')
        .replaceAll('&', r'\&');
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
