const dbname = 'podcast.db';
const dbversion = 1;

const migrations = [
  {"version": 1},
];

const fgkeyPragma = "PRAGMA foreign_keys = ON;";

const createEpisodes = '''CREATE TABLE IF NOT EXISTS episodes (
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
  published TIMESTAMP NOT NULL,
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

const createChannels = '''CREATE TABLE IF NOT EXISTS channels (
  id INTEGER PRIMARY KEY,
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

const createTablesV1 = [createEpisodes, createChannels];
