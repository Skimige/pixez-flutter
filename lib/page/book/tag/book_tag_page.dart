/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along with
 *  this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/page/search/result_illust_list.dart';

class BookTagPage extends StatefulWidget {
  @override
  _BookTagPageState createState() => _BookTagPageState();
}

class _BookTagPageState extends State<BookTagPage>
    with TickerProviderStateMixin {
  bool edit = false;

  TabController _tabController;

  @override
  void initState() {
    _tabController =
        TabController(length: bookTagStore.bookTagList.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (edit)
      return Container(
        child: Column(
          children: [
            AppBar(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              title: Text(I18n.of(context).choice_you_like),
              actions: [
                IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () {
                      setState(() {
                        edit = false;
                      });
                    })
              ],
            ),
            Expanded(child: _buildTagChip())
          ],
        ),
      );
    return Observer(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          title: TabBar(
            isScrollable: true,
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              for (var i in bookTagStore.bookTagList)
                Tab(
                  text: i,
                )
            ],
          ),
          actions: [
            IconButton(
                icon: Icon(
                  Icons.undo,
                ),
                onPressed: () {
                  setState(() {
                    edit = true;
                  });
                }),
          ],
        ),
        body: TabBarView(controller: _tabController, children: [
          for (var j in bookTagStore.bookTagList)
            ResultIllustList(
              word: j,
            )
        ]),
        endDrawer: Drawer(
          child: ListView(
            children: [
              for (var j in bookTagStore.bookTagList)
                ListTile(
                  title: Text(j),
                  onTap: () {
                    _tabController
                        .animateTo(bookTagStore.bookTagList.indexOf(j));
                  },
                )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTagChip() {
    return Container(
      child: Wrap(
        spacing: 2.0,
        children: [
          for (var i in bookTagStore.bookTagList)
            FilterChip(
                label: Text(i),
                selected: true,
                onSelected: (v) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(I18n.of(context).delete + "$i?"),
                          actions: [
                            FlatButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(I18n.of(context).cancel)),
                            FlatButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  bookTagStore.unBookTag(i);
                                },
                                child: Text(I18n.of(context).ok)),
                          ],
                        );
                      });
                })
        ],
      ),
    );
  }
}
