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
      final response = await Dio().get(
        'https://webcreativeclicks.com/feed/mobile',
      );
      final document = xml.XmlDocument.parse(response.toString());
      final channel = document.findAllElements('channel');
      List<NewsModel> newsList = [];
      for (var node in channel) {
        node.findElements('item').forEach((element) {
          String title = _xmlText(element, 'title');
          String description = _xmlText(element, 'description');
          String date = _xmlText(element, 'pubDate');
          String link = _xmlText(element, 'link');
          String image = _xmlText(element, 'image');

          List<String> categoryList =
              element.findElements('category').map((e) => e.innerText).toList();

          DateFormat format = DateFormat("E, dd MMM yyyy HH:mm:ss");
          DateTime? dateTime;
          try {
            dateTime = format.parse(date, true).toLocal();
          } catch (_) {
            dateTime = null;
          }
          String dateFormatted = date;
          if (dateTime != null) {
            String suffix;
            switch (dateTime.day) {
              case 1:
              case 21:
              case 31:
                suffix = "'st'";
                break;
              case 2:
              case 22:
                suffix = "'nd'";
                break;
              case 3:
              case 23:
                suffix = "'rd'";
                break;
              default:
                suffix = "'th'";
                break;
            }
            format = DateFormat("dd$suffix MMM");
            dateFormatted = format.format(dateTime).replaceAll("'", '');
          }
          var documentHtml = html.parse(description);
          String parsedDescription =
              html.parse(documentHtml.body?.text ?? '').documentElement?.text ??
              '';
          newsList.add(
            NewsModel(
              title: title,
              description: parsedDescription,
              date: dateFormatted,
              link: link,
              image: image,
              categories: categoryList,
            ),
          );
        });
      }
      _allNews.add(newsList);
      filterByCategory(_activeCategory.value);
    } catch (e) {
      _allNews.addError(e);
      _filteredNews.addError(e);
    }
  }

  void filterByCategory(String category) {
    _activeCategory.add(category);
    if (!_allNews.hasValue) return;

    if (category == 'All') {
      _filteredNews.add(_allNews.value);
    } else {
      final filtered = _allNews.value
          .where((item) => item.categories.contains(category))
          .toList();
      _filteredNews.add(filtered);
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
