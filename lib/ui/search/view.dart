import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../model/pcindex.dart' show PCIndexSearch;
import '../../model/channel.dart';
import 'model.dart';

class SearchView extends StatelessWidget {
  final SearchViewModel model;
  const SearchView({super.key, required this.model});

  // @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          // onPressed: () => context.pop(),
          onPressed: () => context.go('/follow'),
        ),
        title: Text('Podcast Index Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBox(model: model),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: model,
                builder:
                    (context, _) => Column(
                      children:
                          model.channels
                              .map((e) => ChannelTile(channel: e))
                              .toList(),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatefulWidget {
  final SearchViewModel model;
  const SearchBox({super.key, required this.model});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _buttonFocusNode = FocusNode();
  final _kwdController = TextEditingController();

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    _kwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _kwdController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'keywords',
        suffixIcon: MenuAnchor(
          childFocusNode: _buttonFocusNode,
          menuChildren: [
            MenuItemButton(
              onPressed:
                  () => widget.model.search(
                    PCIndexSearch.byTerm,
                    _kwdController.text,
                  ),
              child: const Text('by Term'),
            ),
            MenuItemButton(
              onPressed:
                  () => widget.model.search(
                    PCIndexSearch.byTerm,
                    _kwdController.text,
                  ),
              child: const Text('by Title'),
            ),
            MenuItemButton(
              onPressed:
                  () => widget.model.search(
                    PCIndexSearch.byCategories,
                    _kwdController.text,
                  ),
              child: const Text('by Category'),
            ),
          ],
          builder:
              (_, controller, child) => IconButton(
                focusNode: _buttonFocusNode,
                icon: Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              ),
        ),
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  final Channel channel;
  const ChannelTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        channel.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        channel.author ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        context.go(
          Uri(
            path: '/channel',
            queryParameters: {'url': channel.url},
          ).toString(),
        );
      },
    );
  }
}
