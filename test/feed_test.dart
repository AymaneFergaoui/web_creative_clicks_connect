import 'package:flutter_test/flutter_test.dart';
import 'package:web_creative_clicks_connect/news_bloc.dart';

void main() {
  test('NewsBloc loads live feed, parses items, images, dates and categories', () async {
    final bloc = NewsBloc();
    expect(bloc.currentCategory, 'All');

    // Fetch news from live feed
    await bloc.getNews();

    final categories = bloc.categories;
    expect(categories.contains('All'), isTrue);
    expect(categories.length, greaterThan(1));

    // Wait for news stream
    final newsList = await bloc.news.first;
    expect(newsList.isNotEmpty, isTrue);

    final first = newsList.first;
    expect(first.title.isNotEmpty, isTrue);
    expect(first.link.startsWith('http'), isTrue);
    expect(first.image.startsWith('http'), isTrue);
    expect(first.author, 'Web Creative Clicks');
    expect(first.date.isNotEmpty, isTrue);

    // Verify filter by category
    final sampleCategory = categories[1]; // non-All category
    bloc.filterByCategory(sampleCategory);
    final filtered = await bloc.news.first;
    expect(filtered.every((item) => item.categories.contains(sampleCategory)), isTrue);

    // Verify search
    bloc.filterByCategory('All');
    bloc.searchNews('tech');
    final searched = await bloc.news.first;
    expect(searched.isNotEmpty, isTrue);

    bloc.dispose();
  });
}
