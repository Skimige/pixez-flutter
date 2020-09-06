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
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/component/pixiv_image.dart';
import 'package:pixez/lighting/lighting_store.dart';
import 'package:pixez/models/novel_recom_response.dart';
import 'package:pixez/page/novel/component/novel_bookmark_button.dart';
import 'package:pixez/page/novel/component/novel_lighting_store.dart';
import 'package:pixez/page/novel/viewer/novel_viewer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class NovelLightingList extends StatefulWidget {
  final FutureGet futureGet;

  const NovelLightingList({Key key, @required this.futureGet})
      : super(key: key);

  @override
  _NovelLightingListState createState() => _NovelLightingListState();
}

class _NovelLightingListState extends State<NovelLightingList> {
  RefreshController _easyRefreshController;
  NovelLightingStore _store;

  @override
  void initState() {
    _easyRefreshController = RefreshController(initialRefresh: true);
    _store = NovelLightingStore(widget.futureGet, _easyRefreshController);
    super.initState();
  }

  @override
  void didUpdateWidget(NovelLightingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureGet != widget.futureGet) {
      _store.source = widget.futureGet;
      _store.fetch();
    }
  }

  @override
  void dispose() {
    _easyRefreshController?.dispose();
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    if (_store.novels.isNotEmpty) {
      return ListView.builder(
        itemBuilder: (context, index) {
          Novel novel = _store.novels[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(
                        builder: (BuildContext context) => NovelViewerPage(
                              id: novel.id,
                              novel: novel,
                            )));
              },
              child: Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: PixivImage(
                            novel.imageUrls.medium,
                            width: 80,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, left: 8.0),
                              child: Container(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: Text(
                                    novel.title,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                    maxLines: 3,
                                  )),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: Text(
                                  novel.user.name,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(
                                          color: Theme.of(context).accentColor),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    for (var f in novel.tags)
                                      Text(
                                        f.name,
                                        style:
                                            Theme.of(context).textTheme.caption,
                                      )
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 8.0,
                            )
                          ],
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        NovelBookmarkButton(novel: novel),
                        Text('${novel.totalBookmarks}',
                            style: Theme.of(context).textTheme.caption)
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
        itemCount: _store.novels.length,
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      return SmartRefresher(
        onLoading: () => _store.next(),
        onRefresh: () => _store.fetch(),
        enablePullDown: true,
        enablePullUp: true,
        controller: _easyRefreshController,
        child: _buildBody(context),
      );
    });
  }
}
