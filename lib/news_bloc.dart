import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;

import 'news_model.dart';

class NewsBloc {
  final BehaviorSubject<List<NewsModel>> _allNews =
      BehaviorSubject<List<NewsModel>>();
  final BehaviorSubject<List<NewsModel>> _filteredNews =
      BehaviorSubject<List<NewsModel>>();
  final BehaviorSubject<String> _activeCategory =
      BehaviorSubject<String>.seeded('All');

  Stream<List<NewsModel>> get news => _filteredNews.stream;
  Stream<String> get activeCategory => _activeCategory.stream;

  String get currentCategory => _activeCategory.value;

  List<String> _getAllCategories(List<NewsModel> newsList) {
    final Set<String> cats = {};
    for (final item in newsList) {
      cats.addAll(item.categories);
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
    final node = elems.first;
    // XmlElement.innerText returns a non-nullable String (concatenated text nodes)
    return node.innerText;
  }

  Future<void> getNews() async {
    try {
      final response =
          await Dio().get('https://webcreativeclicks.com/feed/mobile');
      final document = xml.XmlDocument.parse(response.toString());
      final channel = document.findAllElements('channel');
      final List<NewsModel> newsList = [];

      for (final node in channel) {
        for (final element in node.findElements('item')) {
          final String title = _xmlText(element, 'title');
          final String rawDescription = _xmlText(element, 'description');
          final String date = _xmlText(element, 'pubDate');

          // Extract link — RSS <link> is tricky: text may be in a CDATA text node
          String link = '';
          for (final child in element.children) {
            if (child is xml.XmlElement && child.name.local == 'link') {
              link = child.innerText;
              if (link.isEmpty) {
                final idx = element.children.indexOf(child);
                if (idx + 1 < element.children.length) {
                  final next = element.children[idx + 1];
                  if (next is xml.XmlText) {
                    link = next.value.trim();
                  }
                }
              }
              break;
            }
          }

          // Extract image URL — try media:content, enclosure, then <img> in description
          String image = '';

          // 1) media:content
          final mediaContent = element.findAllElements('content',
              namespace: 'http://search.yahoo.com/mrss/');
          if (mediaContent.isNotEmpty) {
            image = mediaContent.first.getAttribute('url') ?? '';
          }

          // 2) enclosure
          if (image.isEmpty) {
            final enclosureElems = element.findAllElements('enclosure');
            if (enclosureElems.isNotEmpty) {
              image = enclosureElems.first.getAttribute('url') ?? '';
            }
          }

          // 3) First <img src="..."> inside the description HTML
          if (image.isEmpty && rawDescription.isNotEmpty) {
            final doc = html.parse(rawDescription);
            final img = doc.querySelector('img');
            if (img != null) {
              image = img.attributes['src'] ?? '';
            }
          }

          // Extract categories
          final List<String> cats = element
              .findElements('category')
              .map((e) => e.innerText.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          // Format date
          String dateFormatted = date;
          if (date.isNotEmpty) {
            final format = DateFormat("E, dd MMM yyyy HH:mm:ss");
            DateTime? dateTime;
            try {
              dateTime = format.parse(date, true).toLocal();
            } catch (_) {
              dateTime = null;
            }
            if (dateTime != null) {
              final String suffix;
              switch (dateTime.day % 10) {
                case 1 when dateTime.day != 11:
                  suffix = "st";
                  break;
                case 2 when dateTime.day != 12:
                  suffix = "nd";
                  break;
                case 3 when dateTime.day != 13:
                  suffix = "rd";
                  break;
                default:
                  suffix = "th";
                  break;
              }
              dateFormatted =
                  DateFormat("d'$suffix' MMM yyyy").format(dateTime);
            }
          }

          // Strip HTML tags from description
          final String parsedDescription = () {
            if (rawDescription.isEmpty) return '';
            final doc = html.parse(rawDescription);
            return doc.body?.text ?? '';
          }();

          newsList.add(NewsModel(
            title: title,
            description: parsedDescription,
            date: dateFormatted,
            link: link,
            image: image,
            categories: cats,
          ));
        }
      }

      _allNews.add(newsList);
      _applyFilter();
    } catch (e) {
      _filteredNews.addError(e);
    }
  }

  void filterByCategory(String category) {
    _activeCategory.add(category);
    _applyFilter();
  }

  void _applyFilter() {
    if (!_allNews.hasValue) return;
    final all = _allNews.value;
    final cat = _activeCategory.value;
    if (cat == 'All') {
      _filteredNews.add(all);
    } else {
      _filteredNews
          .add(all.where((n) => n.categories.contains(cat)).toList());
    }
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
  }
}