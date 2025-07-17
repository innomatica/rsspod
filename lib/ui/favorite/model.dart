import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../model/favorite.dart';
import '../../util/constants.dart' show favoriteUrl;

class FavoriteViewModel extends ChangeNotifier {
  // ignore: unused_field
  final _log = Logger("FavoriteViewModel");
  List<Favorite> _items = [];
  List<Favorite> get items => _items;

  Future load() async {
    final res = await http.get(Uri.parse(favoriteUrl));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded != null && decoded is List) {
        _items = decoded.map((e) => Favorite.fromMap(e)).toList();
        // _log.fine('items:$_items');
      }
    }
    notifyListeners();
  }
}
