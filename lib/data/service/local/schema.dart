import '../../../util/constants.dart';

const dbname = 'podcast.db';
const dbversion = 1;

const migrations = [
  {"version": 1},
];

const fgkeyPragma = "PRAGMA foreign_keys = ON;";

const episodeSchema = '''CREATE TABLE IF NOT EXISTS episodes (
  id INTEGER PRIMARY KEY,
  guid TEXT NOT NULL UNIQUE,
  title TEXT,
  subtitle TEXT,
  author TEXT,
  description TEXT,
  language TEXT,
  categories TEXT,
  keywords TEXT,
  updated TIMESTAMP,
  published TIMESTAMP,
  link TEXT,
  media_url TEXT,
  media_type TEXT,
  media_size INTEGER,
  media_duration INTEGER,
  media_seek_pos INTEGER,
  image_url TEXT,
  extras TEXT,
  channel_id INTEGER NOT NULL,
  downloaded INTEGER,
  played INTEGER,
  liked INTEGER,
  FOREIGN KEY (channel_id) 
    REFERENCES channels (id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
);''';

// note: channel.id is used as a directory name. it must be unique
const channelSchema = '''CREATE TABLE IF NOT EXISTS channels (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  url TEXT NOT NULL UNIQUE,
  title TEXT,
  subtitle TEXT,
  author TEXT,
  categories TEXT,
  description TEXT,
  language TEXT,
  link TEXT,
  updated TIMESTAMP,
  published TIMESTAMP,
  checked TIMESTAMP,
  period INTEGER,
  image_url TEXT,
  extras TEXT
);''';

const settingsSchema = '''CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY,
  retention_period INTEGER,
  search_engine_url TEXT
);''';

const defaultSettings = """INSERT INTO settings(
  retention_period, 
  search_engine_url) 
  VALUES(
  $defaultRetentionDays, 
  '$defaultSearchEngineUrl'
);""";
