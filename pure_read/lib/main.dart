import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/book_repository.dart';

void main() {
  runApp(const PureReadApp());
}

class _AppColors {
  static const background = Color(0xFFF6F1EC);
  static const surface = Color(0xFFFCFAF7);
  static const surfaceElevated = Color(0xFFF0E8DF);
  static const primary = Color(0xFF5563E6);
  static const accent = Color(0xFFED8A63);
  static const textPrimary = Color(0xFF1E1F24);
}

class PureReadApp extends StatelessWidget {
  const PureReadApp({super.key});

  static const _assets = ['assets/epub/仙逆.epub'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      background: _AppColors.background,
      surface: _AppColors.surface,
      primary: _AppColors.primary,
      secondary: _AppColors.accent,
      onSurface: _AppColors.textPrimary,
    );

    return MaterialApp(
      title: 'PureRead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _AppColors.background,
        cardColor: _AppColors.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: _AppColors.surface,
          elevation: 0,
          titleTextStyle: GoogleFonts.notoSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _AppColors.textPrimary,
          ),
          iconTheme: const IconThemeData(color: _AppColors.textPrimary),
        ),
        textTheme: GoogleFonts.notoSansTextTheme().apply(
          bodyColor: _AppColors.textPrimary,
          displayColor: _AppColors.textPrimary,
        ),
      ),
      home: LibraryScreen(
        repository: BookRepository(assetPaths: _assets),
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.repository});

  final BookRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<BookData>>(
        future: repository.loadBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const _ErrorState(message: '未发现任何 EPUB 资源');
          }

          return CustomScrollView(
            slivers: [
              const _LibraryAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      return _BookTile(
                        book: book,
                        index: index,
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryAppBar extends StatelessWidget {
  const _LibraryAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 90,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withOpacity(0.94),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '书架',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.index});

  final BookData book;
  final int index;

  static const _gradients = [
    [Color(0xFF9AA5FF), Color(0xFF6C7BFF)],
    [Color(0xFFFF9E78), Color(0xFFEF6C53)],
    [Color(0xFF6CD4C3), Color(0xFF5FB6AE)],
    [Color(0xFFEDB7F4), Color(0xFFCB9AE4)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: book.coverImage == null
                      ? LinearGradient(colors: gradient)
                      : null,
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: book.coverImage != null
                    ? Image.memory(
                        book.coverImage!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            book.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _AppColors.textPrimary,
            ),
          ),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: _AppColors.textPrimary.withOpacity(0.6),
            ),
          ),
          if (book.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '解析失败',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final BookData book;

  @override
  Widget build(BuildContext context) {
    final hasChapters = book.chapters.isNotEmpty;
    final tabCount = hasChapters ? 2 : 1;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(book.title),
          bottom: TabBar(
            tabs: [
              const Tab(text: '简介'),
              if (hasChapters) const Tab(text: '章节'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookSummary(book: book),
            if (hasChapters)
              _ChapterList(
                book: book,
              ),
          ],
        ),
      ),
    );
  }
}

class _BookSummary extends StatelessWidget {
  const _BookSummary({required this.book});

  final BookData book;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (book.coverImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              book.coverImage!,
              fit: BoxFit.cover,
              height: 260,
            ),
          )
        else
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF9AA5FF), Color(0xFF6C7BFF)],
              ),
            ),
            child: Center(
              child: Text(
                book.title,
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          '作者：${book.author}',
          style: GoogleFonts.notoSans(fontSize: 14),
        ),
        const SizedBox(height: 16),
        Text(
          book.description?.isNotEmpty == true
              ? book.description!
              : '暂无简介。',
          style: GoogleFonts.notoSans(fontSize: 15, height: 1.6),
        ),
      ],
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.book});

  final BookData book;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: book.chapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final chapter = book.chapters[index];
        return ListTile(
          title: Text(chapter.title),
          subtitle: Text(
            '${chapter.content.characters.length} 字',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  book: book,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book, required this.initialIndex});

  final BookData book;
  final int initialIndex;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.book.chapters;

    return Scaffold(
      backgroundColor: _AppColors.surfaceElevated,
      appBar: AppBar(
        title: Text(chapters[_currentIndex].title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ListView(
              children: [
                Text(
                  chapter.title,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  chapter.content,
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    height: 1.7,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
