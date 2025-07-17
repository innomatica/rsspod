import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../model/feed.dart';
import '../../util/constants.dart';
import '../../util/helpers.dart';
import '../../util/widgets.dart';
import 'model.dart';

class FeedView extends StatelessWidget {
  final FeedViewModel model;
  FeedView({super.key, required this.model});
  // ignore: unused_field
  final _log = Logger('FeedView');

  Widget _buildError(String error) {
    return Center(child: Text(error));
  }

  Widget _buildFeedInfo(Feed data, BuildContext context) {
    final infoStyle = TextStyle(color: Theme.of(context).colorScheme.tertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // spacing: 8.0,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            FutureImage(
              future: model.getChannelImage(),
              height: 160,
              width: double.maxFinite,
              opacity: 0.50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 8.0,
                children: [
                  // title
                  Text(
                    data.channel.title ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                  // author
                  Text(
                    data.channel.author ?? 'author unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                  // categories
                  Text(
                    data.channel.categories ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      // fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.blueGrey, blurRadius: 10.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // last published
        Row(
          spacing: 8,
          children: [
            Text('last published', style: infoStyle),
            Text(
              yymmdd(
                data.channel.published ?? data.channel.updated,
                fallback: 'unknown',
              ),
            ),
          ],
        ),
        // last checked
        Row(
          spacing: 8,
          children: [
            Text('last checked', style: infoStyle),
            Text(daysAgo(data.channel.checked)),
          ],
        ),
        // period
        Row(
          spacing: 6,
          children: [
            Text('update period', style: infoStyle),
            DropdownButton<int>(
              isDense: true,
              elevation: 0,
              value: model.feed?.channel.period ?? defaultUpdatePeriod,
              items:
                  updatePeriods
                      .map(
                        (e) => DropdownMenuItem<int>(
                          value: e,
                          onTap: () {},
                          child: Text('$e d'),
                        ),
                      )
                      .toList(),
              onChanged: (value) async {
                if (value != null) {
                  await model.updatePeriod(value);
                }
              },
            ),
            // Text('day', style: infoStyle),
          ],
        ),
        SizedBox(height: 8),
        Text(removeTags(data.channel.description)),
        // Text(data.channel.language ?? 'language null'),
        Divider(),
        // ...data.episodes.map((e) => Text(e.title ?? '')),
        ...data.episodes.map(
          (e) => ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            title: Text(
              e.title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(yymmdd(e.published)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).colorScheme.primary;
    final unsubColor = Theme.of(context).colorScheme.error;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded),
              // onPressed: () => context.pop(),
              onPressed: () => context.go('/follow'),
            ),
            title: Text("Channel"),
            actions: [
              model.subscribed
                  ? TextButton.icon(
                    label: Text(
                      'unsubscribe',
                      style: TextStyle(color: unsubColor),
                    ),
                    icon: Icon(
                      Icons.unsubscribe_rounded,
                      size: 20,
                      color: unsubColor,
                    ),
                    onPressed: () async {
                      await model.unsubscribe();
                      if (context.mounted) {
                        context.go('/follow');
                      }
                    },
                  )
                  : TextButton.icon(
                    label: Text('subscribe', style: TextStyle(color: subColor)),
                    icon: Icon(
                      Icons.subscriptions_rounded,
                      size: 20,
                      color: subColor,
                    ),
                    onPressed: () async => await model.subscribe(),
                  ),
              IconButton(
                icon: Icon(Icons.content_copy_rounded),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          "Title: ${model.feed?.channel.title}\n"
                          "Author: ${model.feed?.channel.author}\n"
                          "Link: ${model.feed?.channel.link}\n"
                          "URL: ${model.feed?.channel.url}",
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RefreshIndicator(
              onRefresh: model.refreshChannel,
              child: SingleChildScrollView(
                child:
                    model.feed != null
                        ? _buildFeedInfo(model.feed!, context)
                        : model.error != null
                        ? _buildError(model.error!)
                        : const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
