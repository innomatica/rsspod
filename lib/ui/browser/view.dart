import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'model.dart';

class BrowserView extends StatefulWidget {
  final String url;
  final BrowserViewModel model;
  const BrowserView({super.key, required this.url, required this.model});

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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // onNavigationRequest: (request) async {
          //   _log.fine('onNavReq: $request');
          //   widget.model.fetchFeed(request.url);
          //   return NavigationDecision.navigate;
          // },
          onPageFinished: (url) async {
            _log.fine('onPageFinished: $url');
            widget.model.fetchFeed(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
                  onPressed: () => context.go('/subscribed'),
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_left_rounded),
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      _controller.goBack();
                    } else {
                      if (context.mounted) context.pop();
                    }
                  },
                ),
              ],
            ),
            title: Text('Browse to the RSS page'),
          ),
          body: WebViewWidget(controller: _controller),
          floatingActionButton: widget.model.found
              ? FloatingActionButton.extended(
                  onPressed: () async => await widget.model.subscribe(),
                  label: widget.model.subscribed == null
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
