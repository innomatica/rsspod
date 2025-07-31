// app info
const appName = 'RssPod';
const appVersion = '1.0.0+1';
const appId = 'com.innomatic.rsspod';

const developerWebsite = 'https://innomatic.ca';
const sourceRepository = 'https://github.com/innomatica/rsspod';
const favoriteUrl =
    'https://raw.githubusercontent.com/innomatica/rsspod/refs/heads/master/favorites.json';

// podcast index
const pcIdxEndpoint = 'https://api.podcastindex.org/api/1.0';
const pcIdxHost = 'api.podcastindex.org';

// stock images
const defaultChannelImage = 'assets/images/voice-recording.png';
const defaultEpisodeImage = 'assets/images/podcaster.png';

// search engine
const defaultSearchEngineUrl = 'https://ecosia.org';

// retention days
const retentionDays = [30, 60, 90, 180];
const defaultRetentionDays = 90;
final maxRetentionDays = retentionDays.last;

// feed update period
const defaultUpdatePeriod = 1;
const updatePeriods = [1, 2, 3, 4, 5, 6, 7];

// channel thumbnail image file name
const channelImgFname = 'thumbnail';
