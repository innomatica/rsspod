enum PCIndexSearch { byTerm, byTitle, byCategories }

class PCIndexFeed {
  int id;
  String podcastGuid;
  String title;
  String url;
  String originalUrl;
  String link;
  String description;
  String author;
  String ownerName;
  String image;
  String artwork;
  int lastUpdateTime;
  int lastCrawlTime;
  int lastParseTime;
  int lastGoodHttpStatusTime;
  int lastHttpStatus;
  String contentType;
  int? itunesId;
  String generator;
  String language;
  bool explicit;
  int type;
  String medium;
  int dead;
  int episodeCount;
  int crawlErrors;
  int parseErrors;
  Map<int, String> categories;
  int locked;
  int imageUrlHash;
  int newestItemPubdate;

  PCIndexFeed({
    required this.id,
    required this.podcastGuid,
    required this.title,
    required this.url,
    required this.originalUrl,
    required this.link,
    required this.description,
    required this.author,
    required this.ownerName,
    required this.image,
    required this.artwork,
    required this.lastUpdateTime,
    required this.lastCrawlTime,
    required this.lastParseTime,
    required this.lastGoodHttpStatusTime,
    required this.lastHttpStatus,
    required this.contentType,
    this.itunesId,
    required this.generator,
    required this.language,
    required this.explicit,
    required this.type,
    required this.medium,
    required this.dead,
    required this.episodeCount,
    required this.crawlErrors,
    required this.parseErrors,
    required this.categories,
    required this.locked,
    required this.imageUrlHash,
    required this.newestItemPubdate,
  });
}
