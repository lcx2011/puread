import 'dart:typed_data';

import 'package:epub_parser/epub_parser.dart';
import 'package:flutter/services.dart';

class BookRepository {
  const BookRepository({required this.assetPaths});

  final List<String> assetPaths;

  Future<List<BookData>> loadBooks() async {
    final books = <BookData>[];
    for (final asset in assetPaths) {
      try {
        books.add(await _loadSingleBook(asset));
      } catch (error) {
        books.add(
          BookData(
            title: _fallbackTitleFromPath(asset),
            author: '解析失败',
            chapters: const [],
            coverImage: null,
            errorMessage: error.toString(),
          ),
        );
      }
    }
    return books;
  }

  Future<BookData> _loadSingleBook(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final epubBook = await EpubReader.readBook(bytes);

    final cover = epubBook.CoverImage;
    final chapters = _extractChapters(epubBook.Chapters ?? const []);

    return BookData(
      title: _cleanText(epubBook.Title) ?? _fallbackTitleFromPath(assetPath),
      author: _author(epubBook),
      coverImage: cover,
      chapters: chapters,
      description: _description(epubBook),
    );
  }

  List<BookChapter> _extractChapters(List<EpubChapter> rawChapters,
      [List<BookChapter>? accumulator]) {
    final result = accumulator ?? <BookChapter>[];
    for (final chapter in rawChapters) {
      final title = _cleanText(chapter.Title) ?? '未命名章节';
      final content = _htmlToPlainText(chapter.HtmlContent ?? '');
      if (content.isNotEmpty) {
        result.add(BookChapter(title: title, content: content));
      }
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        _extractChapters(chapter.SubChapters!, result);
      }
    }
    return result;
  }

  String _fallbackTitleFromPath(String assetPath) {
    return assetPath.split('/').last.split('.').first;
  }

  String _author(EpubBook epubBook) {
    final authors = epubBook.AuthorList
        ?.where((a) => (a?.trim().isNotEmpty ?? false))
        .map((a) => a!.trim())
        .toList();
    if (authors != null && authors.isNotEmpty) {
      return authors.join(' · ');
    }
    return _cleanText(epubBook.Author) ?? '佚名';
  }

  String? _description(EpubBook epubBook) {
    final metadataDescription =
        epubBook.Schema?.Package?.Metadata?.Description;
    if (_cleanText(metadataDescription) != null) {
      return _cleanText(metadataDescription);
    }

    final titles = epubBook.Schema?.Navigation?.DocTitle?.Titles;
    final fallbackTitle = titles?.firstWhere(
      (title) => title.trim().isNotEmpty,
      orElse: () => '',
    );
    return _cleanText(fallbackTitle);
  }

  String? _cleanText(String? input) {
    if (input == null) return null;
    final value = input.trim();
    if (value.isEmpty) return null;
    return value;
  }

  String _htmlToPlainText(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }
}

class BookData {
  const BookData({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverImage,
    this.description,
    this.errorMessage,
  });

  final String title;
  final String author;
  final List<BookChapter> chapters;
  final Uint8List? coverImage;
  final String? description;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class BookChapter {
  const BookChapter({required this.title, required this.content});

  final String title;
  final String content;
}
