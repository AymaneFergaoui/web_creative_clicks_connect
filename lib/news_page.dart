import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<_NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<List<_NewsItem>> _fetchNews() async {
    final response = await http.get(Uri.parse('https://webcreativeclicks.com/feed/mobile'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load news');
    }
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    return items.map((item) {
      final title = item.getElement('title')?.text ?? '';
      final link = item.getElement('link')?.text ?? '';
      final pubDate = item.getElement('pubDate')?.text ?? '';
      final description = item.getElement('description')?.text ?? '';
      return _NewsItem(
        title: title,
        link: link,
        pubDate: pubDate,
        description: description,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: FutureBuilder<List<_NewsItem>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No news found.'));
          }
          final news = snapshot.data!;
          return ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.pubDate),
                onTap: () async {
                  final url = Uri.parse(item.link);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NewsItem {
  final String title;
  final String link;
  final String pubDate;
  final String description;

  _NewsItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
  });
} 