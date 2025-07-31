class Favorite {
  String? title;
  String? url;
  String? link;
  String? description;
  String? keywords;

  Favorite({this.title, this.url, this.link, this.description, this.keywords});

  factory Favorite.fromMap(Map<String, Object?> map) {
    return Favorite(
      title: map['title'] as String?,
      url: map['url'] as String?,
      link: map['link'] as String?,
      description: map['description'] as String?,
      keywords: map['keywords'] as String?,
    );
  }

  @override
  String toString() {
    return {
      "title": title,
      "url": url,
      "link": link,
      "description": description,
      "keywords": keywords,
    }.toString();
  }
}
