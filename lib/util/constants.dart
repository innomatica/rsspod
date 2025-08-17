// app info
const appName = 'RssPod';
const appVersion = '1.0.2+3';
const appId = 'com.innomatic.rsspod';

const developerWebsite = 'https://innomatic.ca';
const sourceRepository = 'https://github.com/innomatica/rsspod';
const favoriteUrl =
    'https://raw.githubusercontent.com/innomatica/rsspod/refs/heads/master/favorites.json';

// attributions
const pcIdxUrl = "https://podcastindex.org/";
const micIconUrl = "https://www.flaticon.com/free-icons/microphone";

// podcast index
const pcIdxEndpoint = 'https://api.podcastindex.org/api/1.0';
const pcIdxHost = 'api.podcastindex.org';

// stock images
const assetImageRecording = 'assets/images/voice-recording.png';
const assetImagePodcaster = 'assets/images/podcaster.png';
const defaultChannelImage = assetImageRecording;
const defaultEpisodeImage = assetImagePodcaster;
const defaultSearchEngine = 'https://search.brave.com';

// episode display period
const displayPeriods = [30, 60, 90, 120];
const defaultDisplayPeriod = 60;
const pKeyDisplayPeriod = "displayPeriod";
final dataRetentionPeriod = displayPeriods.last;

// feed update period
const defaultUpdatePeriod = 1;
const updatePeriods = [1, 2, 3, 4, 5, 6, 7];

// channel thumbnail image file name
const chnImgFname = 'thumbnail';

// application document directory path
late final String appDocPath;
