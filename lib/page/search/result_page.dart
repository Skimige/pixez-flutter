/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/tags.dart';
import 'package:pixez/page/search/result/painter/search_result_painter_page.dart';
import 'package:pixez/page/search/result_illust_list.dart';
import 'package:pixez/page/search/suggest/search_suggestion_page.dart';

class ResultPage extends StatefulWidget {
  final String word;
  final String translatedName;
  const ResultPage({Key key, this.word, this.translatedName = ''})
      : super(key: key);
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    tagHistoryStore.insert(TagsPersist()
      ..name = widget.word
      ..translatedName = widget.translatedName);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            child: Text(widget.word),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SearchSuggestionPage(preword: widget.word,)));
            },
          ),
          bottom: TabBar(tabs: [
            Tab(
              text: I18n.of(context).Illust,
            ),
            Tab(
              text: I18n.of(context).Painter,
            ),
          ]),
        ),
        body: TabBarView(children: [
          ResultIllustList(word: widget.word),
          SearchResultPainterPage(
            word: widget.word,
          ),
        ]),
      ),
    );
  }
}
