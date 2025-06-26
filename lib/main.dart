import 'package:flutter/material.dart';
import 'news_bloc.dart';
import 'news_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Creative Clicks News',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({Key? key}) : super(key: key);

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  late final NewsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = NewsBloc();
    _bloc.getNews();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: _bloc.news,
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        child: Image.network(
                          item.image,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ListTile(
                      title: Text(item.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      onTap: () => _bloc.launchUrlInBrowser(item.link),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
