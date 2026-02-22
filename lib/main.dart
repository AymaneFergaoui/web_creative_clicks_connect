import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'news_bloc.dart';
import 'news_model.dart';

void main() {
  runApp(const MyApp());
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppColors {
  static const primary = Color(0xFF0D47A1); // Deep brand blue
  static const accent = Color(0xFFFF6F00); // Vibrant amber/orange
  static const surface = Color(0xFFF5F7FA);
  static const cardLight = Colors.white;

  // Dark mode
  static const darkBg = Color(0xFF0A0E1A);
  static const darkCard = Color(0xFF141929);
  static const darkSurface = Color(0xFF1C2238);
}

ThemeData _buildLight() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

ThemeData _buildDark() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
        primary: const Color(0xFF4FC3F7),
        secondary: AppColors.accent,
        surface: AppColors.darkCard,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );

// ─── App Root ─────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  bool get isDark => _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Web Creative Clicks',
      theme: _buildLight(),
      darkTheme: _buildDark(),
      themeMode: _themeMode,
      home: const NewsHomePage(),
    );
  }
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  late final NewsBloc _bloc;
  final ScrollController _scrollController = ScrollController();
  List<String> _categories = ['All'];
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _bloc = NewsBloc();
    _loadNews();
  }

  Future<void> _loadNews() async {
    await _bloc.getNews();
    if (mounted) {
      setState(() {
        _categories = _bloc.categories;
        _firstLoad = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _firstLoad = true);
    await _loadNews();
  }

  @override
  void dispose() {
    _bloc.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final isDark = appState.isDark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'W',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web Creative Clicks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Digital Marketing Insights',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkBg, AppColors.darkSurface]
                        : [AppColors.primary, const Color(0xFF1565C0)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'Light mode' : 'Dark mode',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: Colors.white,
                  ),
                ),
                onPressed: appState.toggleTheme,
              ),
            ],
          ),

          // Category Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryBarDelegate(
              child: _CategoryBar(
                categories: _categories,
                bloc: _bloc,
                onSelected: (cat) {
                  _bloc.filterByCategory(cat);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: scheme.primary,
          child: _firstLoad
              ? _SkeletonList()
              : StreamBuilder<List<NewsModel>>(
                  stream: _bloc.news,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return _SkeletonList();
                    }
                    if (snapshot.hasError) {
                      return _ErrorView(
                        message: snapshot.error.toString(),
                        onRetry: _refresh,
                      );
                    }
                    final news = snapshot.data ?? [];
                    if (news.isEmpty) {
                      return const _EmptyView();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: news.length,
                      itemBuilder: (context, index) =>
                          _NewsCard(item: news[index], bloc: _bloc),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ─── Category Bar ─────────────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final NewsBloc bloc;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.bloc,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.of(context).isDark;
    return Container(
      height: 50,
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: StreamBuilder<String>(
        stream: bloc.activeCategory,
        initialData: 'All',
        builder: (context, snapshot) {
          final active = snapshot.data ?? 'All';
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected = cat == active;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelected(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF0F4FF)),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.blueGrey.shade100),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.blueGrey),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _CategoryBarDelegate({required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_CategoryBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}

// ─── News Card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsModel item;
  final NewsBloc bloc;

  const _NewsCard({required this.item, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.of(context).isDark;
    final hasImage = item.image.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => bloc.launchUrlInBrowser(item.link),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (hasImage)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: item.image,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor:
                        isDark ? const Color(0xFF1E2640) : Colors.grey.shade200,
                    highlightColor:
                        isDark ? const Color(0xFF2A3554) : Colors.grey.shade100,
                    child: Container(
                        height: 190, color: Colors.grey.shade300),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  if (item.categories.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: item.categories
                          .take(2)
                          .map((cat) => _CategoryPill(cat))
                          .toList(),
                    ),
                  if (item.categories.isNotEmpty)
                    const SizedBox(height: 8),

                  // Title
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: isDark ? Colors.white : const Color(0xFF0D1B40),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? Colors.white54
                            : Colors.blueGrey.shade600,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Footer: date + read more
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.white38
                              : Colors.blueGrey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white38
                              : Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Read more',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Skeleton Loading ─────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.of(context).isDark;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: 5,
      itemBuilder: (context, _) => _SkeletonCard(isDark: isDark),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  Widget _box(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A2033) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF2E3D5F) : Colors.grey.shade50,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 180,
                color: Colors.grey,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(80, 14),
                  const SizedBox(height: 10),
                  _box(double.infinity, 16),
                  const SizedBox(height: 6),
                  _box(double.infinity, 16),
                  const SizedBox(height: 6),
                  _box(200, 16),
                  const SizedBox(height: 12),
                  _box(double.infinity, 13),
                  const SizedBox(height: 4),
                  _box(260, 13),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _box(100, 12),
                      const Spacer(),
                      _box(80, 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error & Empty Views ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text(
              'Could not load news',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined,
              size: 64, color: Colors.blueGrey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No articles found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category.',
            style: TextStyle(color: Colors.blueGrey.shade400),
          ),
        ],
      ),
    );
  }
}
