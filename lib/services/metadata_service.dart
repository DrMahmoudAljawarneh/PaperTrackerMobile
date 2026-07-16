import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaperMetadata {
  final String title;
  final List<String> authors;
  final String? abstract;
  final String? venue;
  final String? doi;
  final String? arxivId;
  final DateTime? publishedDate;

  PaperMetadata({
    required this.title,
    required this.authors,
    this.abstract,
    this.venue,
    this.doi,
    this.arxivId,
    this.publishedDate,
  });
}

class MetadataService {
  static const _crossrefApi = 'https://api.crossref.org/works';
  static const _arxivApi = 'https://export.arxiv.org/api/query';

  Future<PaperMetadata?> fetchByDoi(String doi) async {
    try {
      final url = Uri.parse('$_crossrefApi/$doi');
      final response =
          await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'] as Map<String, dynamic>?;
      if (message == null) return null;

      final title = (message['title'] as List?)?.first?.toString() ?? '';
      final authors = (message['author'] as List?)
              ?.map((a) =>
                  '${a['given'] ?? ''} ${a['family'] ?? ''}'.trim())
              .where((n) => n.isNotEmpty)
              .toList() ??
          [];
      final abstract = message['abstract']?.toString();
      final venue =
          (message['container-title'] as List?)?.first?.toString();
      final dateParts =
          message['published-print']?['date-parts']?.first as List?;
      DateTime? publishedDate;
      if (dateParts != null && dateParts.length >= 3) {
        publishedDate =
            DateTime(dateParts[0], dateParts[1], dateParts[2]);
      }

      return PaperMetadata(
        title: title,
        authors: authors,
        abstract: _stripHtmlTags(abstract ?? ''),
        venue: venue,
        doi: doi,
        publishedDate: publishedDate,
      );
    } catch (e) {
      debugPrint('DOI fetch error: $e');
      return null;
    }
  }

  Future<PaperMetadata?> fetchByArxiv(String arxivId) async {
    try {
      final url =
          Uri.parse('$_arxivApi?id_list=$arxivId&max_results=1');
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final xml = response.body;
      final title = _extractXml(xml, 'title')?.trim() ?? '';
      final abstract = _extractXml(xml, 'summary')?.trim() ?? '';
      final authors =
          _extractAllXml(xml, 'name').map((n) => n.trim()).toList();
      final publishedStr = _extractXml(xml, 'published');
      DateTime? publishedDate;
      if (publishedStr != null) {
        publishedDate = DateTime.tryParse(publishedStr);
      }

      return PaperMetadata(
        title: title,
        authors: authors,
        abstract: _stripHtmlTags(abstract),
        arxivId: arxivId,
        publishedDate: publishedDate,
      );
    } catch (e) {
      debugPrint('arXiv fetch error: $e');
      return null;
    }
  }

  Future<PaperMetadata?> fetch(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.startsWith('10.')) {
      return fetchByDoi(trimmed);
    }
    return fetchByArxiv(trimmed);
  }

  String _stripHtmlTags(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  String? _extractXml(String xml, String tag) {
    final match = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true)
        .firstMatch(xml);
    return match?.group(1);
  }

  List<String> _extractAllXml(String xml, String tag) {
    final matches = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true)
        .allMatches(xml);
    return matches.map((m) => m.group(1) ?? '').toList();
  }
}
