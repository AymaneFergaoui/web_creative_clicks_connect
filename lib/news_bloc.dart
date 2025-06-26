import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;

import 'news_model.dart';

class NewsBloc {
  final BehaviorSubject<List<NewsModel>> _news = BehaviorSubject<List<NewsModel>>();

  Stream<List<NewsModel>> get news => _news.stream;

  Future<void> getNews() async {
    final response = await Dio().get('https://webcreativeclicks.com/feed/mobile');
    final document = xml.XmlDocument.parse(response.toString());
    final channel = document.findAllElements('channel');
    List<NewsModel> news = [];
    for (var node in channel) {
      node.findElements('item').forEach((element) {
      String title = element.findElements('title').isNotEmpty ? element.findElements('title').first.text : '';
      String description = element.findElements('description').isNotEmpty ? element.findElements('description').first.text : '';
      String date = element.findElements('pubDate').isNotEmpty ? element.findElements('pubDate').first.text : '';
      String link = element.findElements('link').isNotEmpty ? element.findElements('link').first.text : '';
      String image = element.findElements('image').isNotEmpty ? element.findElements('image').first.text : '';
      List<String> categories = element.findElements('category').map((e) => e.text).toList();

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
      String parsedDescription = html.parse(documentHtml.body?.text ?? '').documentElement?.text ?? '';
      news.add(NewsModel(
        title: title,
        description: parsedDescription,
        date: dateFormatted,
        link: link,
        image: image,
        categories: categories,
      ));
    });
    }
    _news.add(news);
  }

  Future launchUrlInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void dispose() {
    _news.close();
  }
} 