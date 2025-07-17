import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'model.dart';

// const javaScript = '''
//   let htmlString = window.document.documentElement.innerHTML;
//   return htmlString;
// ''';

class BrowserView extends StatefulWidget {
  final BrowserViewModel model;
  const BrowserView({super.key, required this.model});

  @override
  State<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView> {
  // ignore: unused_field
  final _log = Logger('FeedBrowser');
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              // onNavigationRequest: (request) async {
              //   _log.fine('onNavReq: $request');
              //   widget.model.fetchFeed(request.url);
              //   return NavigationDecision.navigate;
              // },
              onPageFinished: (url) {
                _log.fine('onPageFin: $url');
                // FIXME: fetched twice
                widget.model.fetchFeed(url);
              },
            ),
          );
    // ..loadRequest(Uri.parse(defaultSearchEngineUrl));
    _load();
  }

  Future _load() async {
    final url = await widget.model.getSearchEngineUrl();
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leadingWidth: 100,
            leading: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left_outlined),
                  // onPressed: () => context.pop(),
                  onPressed: () => context.go('/follow'),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_left_rounded),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    } else {
                      // ignore: use_build_context_synchronously
                      context.pop();
                    }
                  },
                ),
              ],
            ),
            title: Text('Browse to the RSS page'),
          ),
          body: WebViewWidget(controller: _controller),
          floatingActionButton:
              widget.model.found
                  ? FloatingActionButton.extended(
                    onPressed: () async => await widget.model.subscribe(),
                    label:
                        widget.model.subscribed == null
                            ? Text('Subscribe')
                            : widget.model.subscribed == true
                            ? Text('Subscribed')
                            : Text('Subscription failed'),
                  )
                  : null,
        );
      },
    );
  }
}
