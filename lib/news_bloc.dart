import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;

import 'news_model.dart';

class NewsBloc {
  static const String feedUrl = 'https://webcreativeclicks.com/feed';

  final BehaviorSubject<List<NewsModel>> _allNews =
      BehaviorSubject<List<NewsModel>>();
  final BehaviorSubject<List<NewsModel>> _filteredNews =
      BehaviorSubject<List<NewsModel>>();
  final BehaviorSubject<String> _activeCategory =
      BehaviorSubject<String>.seeded('All');
  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  Stream<List<NewsModel>> get news => _filteredNews.stream;
  Stream<String> get activeCategory => _activeCategory.stream;
  Stream<String> get searchQuery => _searchQuery.stream;

  String get currentCategory => _activeCategory.value;
  String get currentSearch => _searchQuery.value;

  List<String> _getAllCategories(List<NewsModel> newsList) {
    final Set<String> cats = {};
    for (final item in newsList) {
      cats.addAll(item.categories.where((c) => c.trim().isNotEmpty));
    }
    final sorted = cats.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get categories {
    final all = _allNews.hasValue ? _allNews.value : <NewsModel>[];
    return _getAllCategories(all);
  }

  /// Safely reads the inner text of the first matching XML element.
  String _xmlText(xml.XmlElement parent, String tag) {
    final elems = parent.findElements(tag);
    if (elems.isEmpty) return '';
    return elems.first.innerText.trim();
  }

  /// Decodes HTML entities (e.g. &apos;, &quot;, &amp;) and strips unwanted HTML tags.
  String _decodeHtmlAndClean(String raw) {
    if (raw.isEmpty) return '';
    try {
      final doc = html.parse(raw);
      final body = doc.body;
      return body != null ? body.text.trim() : raw.trim();
    } catch (_) {
      return raw.trim();
    }
  }

  /// Extracts image URL from enclosure, media tags, image tag, or description.
  String _extractImageUrl(xml.XmlElement item) {
    // 1. RSS 2.0 <enclosure url="..." />
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final enclosureUrl = enclosure.getAttribute('url');
      if (enclosureUrl != null && enclosureUrl.trim().isNotEmpty) {
        return enclosureUrl.trim();
      }
    }

    // 2. <media:content url="..." />
    for (final media in item.findElements('media:content')) {
      final mediaUrl = media.getAttribute('url');
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty) {
        return mediaUrl.trim();
      }
    }

    // 3. <media:thumbnail url="..." />
    for (final media in item.findElements('media:thumbnail')) {
      final mediaUrl = media.getAttribute('url');
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty) {
        return mediaUrl.trim();
      }
    }

    // 4. <image> inner text
    final imageTag = _xmlText(item, 'image');
    if (imageTag.isNotEmpty) {
      return imageTag;
    }

    // 5. <img> tag in description or content:encoded
    for (final tag in ['description', 'content:encoded']) {
      final content = _xmlText(item, tag);
      if (content.isNotEmpty) {
        final parsed = html.parse(content);
        final img = parsed.querySelector('img');
        final src = img?.attributes['src'];
        if (src != null && src.trim().isNotEmpty) {
          return src.trim();
        }
      }
    }

    return '';
  }

  /// Parses RFC 822 / RSS dates and formats nicely as "09 Oct 2026".
  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';

    // Remove trailing GMT, UTC, or timezone offsets
    final cleanDate = rawDate
        .replaceAll(RegExp(r'\s*(GMT|UTC|[+-]\d{4})$'), '')
        .trim();

    DateTime? dateTime;
    final formats = [
      DateFormat("E, dd MMM yyyy HH:mm:ss", "en_US"),
      DateFormat("d MMM yyyy HH:mm:ss", "en_US"),
      DateFormat("E, d MMM yyyy HH:mm:ss", "en_US"),
      DateFormat("dd MMM yyyy HH:mm:ss", "en_US"),
      DateFormat("yyyy-MM-ddTHH:mm:ss", "en_US"),
    ];

    for (final fmt in formats) {
      try {
        dateTime = fmt.parse(cleanDate, true).toLocal();
        break;
      } catch (_) {}
    }

    // Fallback to ISO 8601
    dateTime ??= DateTime.tryParse(rawDate)?.toLocal();

    if (dateTime == null) {
      return rawDate;
    }

    return DateFormat("dd MMM yyyy", "en_US").format(dateTime);
  }

  Future<void> getNews() async {
    try {
      final response = await Dio().get(
        feedUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'WebCreativeClicksApp/1.0 (Flutter; Android/iOS)',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
          },
        ),
      );

      final document = xml.XmlDocument.parse(response.data.toString());
      final channel = document.findAllElements('channel');
      final List<NewsModel> newsList = [];

      for (var node in channel) {
        node.findElements('item').forEach((element) {
          final rawTitle = _xmlText(element, 'title');
          final title = _decodeHtmlAndClean(rawTitle);

          final rawDescription = _xmlText(element, 'description');
          final description = _decodeHtmlAndClean(rawDescription);

          final rawDate = _xmlText(element, 'pubDate');
          final dateFormatted = _formatDate(rawDate);

          final link = _xmlText(element, 'link');
          final image = _extractImageUrl(element);

          // Author / Creator
          String author = _xmlText(element, 'dc:creator');
          if (author.isEmpty) {
            author = _xmlText(element, 'author');
          }
          if (author.isEmpty) {
            author = 'Web Creative Clicks';
          }
          author = _decodeHtmlAndClean(author);

          final List<String> categoryList = element
              .findElements('category')
              .map((e) => _decodeHtmlAndClean(e.innerText))
              .where((c) => c.isNotEmpty)
              .toList();

          newsList.add(
            NewsModel(
              title: title,
              description: description,
              date: dateFormatted,
              link: link,
              image: image,
              categories: categoryList,
              author: author,
            ),
          );
        });
      }

      _allNews.add(newsList);
      _applyFilter();
    } catch (e) {
      _allNews.addError(e);
      _filteredNews.addError(e);
    }
  }

  void filterByCategory(String category) {
    _activeCategory.add(category);
    _applyFilter();
  }

  void searchNews(String query) {
    _searchQuery.add(query.trim());
    _applyFilter();
  }

  void _applyFilter() {
    if (!_allNews.hasValue) return;

    final all = _allNews.value;
    final cat = _activeCategory.value;
    final query = _searchQuery.value.toLowerCase();

    var result = all;

    if (cat != 'All') {
      result = result.where((item) => item.categories.contains(cat)).toList();
    }

    if (query.isNotEmpty) {
      result = result.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.categories.any((c) => c.toLowerCase().contains(query));
      }).toList();
    }

    _filteredNews.add(result);
  }

  Future<void> launchUrlInBrowser(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void dispose() {
    _allNews.close();
    _filteredNews.close();
    _activeCategory.close();
    _searchQuery.close();
  }
}
