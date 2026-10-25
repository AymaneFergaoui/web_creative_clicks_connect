class NewsModel {
  final String title;
  final String description;
  final String date;
  final String link;
  final String image;
  final List<String> categories;
  final String author;

  NewsModel({
    required this.title,
    required this.description,
    required this.date,
    required this.link,
    required this.image,
    required this.categories,
    this.author = 'Web Creative Clicks',
  });
}