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
import 'package:pixez/er/leader.dart';
import 'package:pixez/page/novel/search/novel_result_page.dart';

class NovelSearchPage extends StatefulWidget {
  @override
  _NovelSearchPageState createState() => _NovelSearchPageState();
}

class _NovelSearchPageState extends State<NovelSearchPage> {
  TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: TextField(
              controller: _textEditingController,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  if (_textEditingController.text.isNotEmpty) {
                    Leader.push(
                        context,
                        NovelResultPage(
                          word: _textEditingController.text,
                        ));
                  }
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 400,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      '小说模块的基本功能是做完了，但是很多地方UI交互不知道如何处理,bug也未全面测试，完成度不是很高，放出来逐步完善吧'),
                ),
              ),
            ),
          )

          // SliverGrid(
          //   gridDelegate:
          //       SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          //   delegate: SliverChildBuilderDelegate((context,index){},childCount: ),
          // )
        ],
      ),
    );
  }
}
