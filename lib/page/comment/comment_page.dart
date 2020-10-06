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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pixez/exts.dart';
import 'package:pixez/component/painter_avatar.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/comment/comment_store.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CommentPage extends StatefulWidget {
  final int id;

  const CommentPage({Key key, this.id}) : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  TextEditingController _editController;
  int parentCommentId;
  String parentCommentName;
  RefreshController easyRefreshController;
  CommentStore _store;

  @override
  void initState() {
    _editController = TextEditingController();
    easyRefreshController = RefreshController();
    _store = CommentStore(easyRefreshController, widget.id)..fetch();
    super.initState();
  }

  @override
  void dispose() {
    _editController?.dispose();
    easyRefreshController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(I18n.of(context).view_comment),
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              SmartRefresher(
                controller: easyRefreshController,
                enablePullUp: true,
                onRefresh: () => _store.fetch(),
                onLoading: () => _store.next(),
                child: _store.comments.isNotEmpty
                    ? ListView.separated(
                        itemCount: _store.comments.length,
                        itemBuilder: (context, index) {
                          var comment = _store.comments[index];
                          return Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: PainterAvatar(
                                    url: _store.comments[index].user
                                        .profileImageUrls.medium,
                                    id: _store.comments[index].user.id,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            comment.user.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .accentColor),
                                          ),
                                          FlatButton(
                                              onPressed: () {
                                                parentCommentId = comment.id;
                                                setState(() {
                                                  parentCommentName =
                                                      comment.user.name;
                                                });
                                              },
                                              child: Text(
                                                "Reply",
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .accentColor),
                                              ))
                                        ],
                                      ),
                                      ...comment.parentComment.user != null
                                          ? [
                                              Text(
                                                  'To ${comment.parentComment.user.name}')
                                            ]
                                          : [],
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: SelectableText(
                                          comment.comment,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(comment.date
                                            .toString()
                                            .toShortTime()),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Divider(),
                          );
                        },
                      )
                    : Container(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Theme.of(context).dialogBackgroundColor,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.book),
                        onPressed: () {
                          setState(() {
                            parentCommentName = null;
                            parentCommentId = null;
                          });
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 2.0, right: 8.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                                primaryColor: Theme.of(context).accentColor),
                            child: TextField(
                              controller: _editController,
                              decoration: InputDecoration(
                                  labelText:
                                      "Reply to ${parentCommentName == null ? "illust" : parentCommentName}",
                                  suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.reply,
                                      ),
                                      onPressed: () async {
                                        final client = apiClient;
                                        String txt =
                                            _editController.text.trim();
                                        try {
                                          if (txt.isNotEmpty)
                                            Response reponse =
                                                await client.postIllustComment(
                                                    widget.id, txt,
                                                    parent_comment_id:
                                                        parentCommentId);
                                          _editController.clear();
                                          _store.fetch();
                                        } catch (e) {
                                          print(e);
                                        }
                                      })),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
