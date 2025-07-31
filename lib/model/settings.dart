import '../util/constants.dart';

class Settings {
  int? id;
  int? retentionPeriod;
  String? searchEngineUrl;

  Settings({this.id, this.retentionPeriod, this.searchEngineUrl});

  @override
  String toString() {
    return {
      "id": id,
      "retentionPeriod": retentionPeriod,
      "searchEngineUrl": searchEngineUrl,
    }.toString();
  }

  factory Settings.init() {
    return Settings(
      retentionPeriod: defaultRetentionDays,
      searchEngineUrl: defaultSearchEngineUrl,
    );
  }

  factory Settings.fromSqlite(Map<String, Object?> row) {
    return Settings(
      id: row['id'] as int,
      retentionPeriod:
          row['retention_period'] != null
              ? row['retention_period'] as int
              : null,
      searchEngineUrl: row['search_engine_url'] as String?,
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      "id": id,
      "retention_period": retentionPeriod,
      "search_engine_url": searchEngineUrl,
    };
  }
}
