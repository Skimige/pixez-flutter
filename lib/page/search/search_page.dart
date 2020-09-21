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

import 'dart:io';
import 'dart:ui';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pixez/component/pixiv_image.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/tags.dart';
import 'package:pixez/page/picture/illust_page.dart';
import 'package:pixez/page/preview/preview_page.dart';
import 'package:pixez/page/search/result_page.dart';
import 'package:pixez/page/search/suggest/search_suggestion_page.dart';
import 'package:pixez/page/search/trend_tags_store.dart';
import 'package:pixez/page/user/users_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  String editString = "";
  TrendTagsStore _trendTagsStore;
  AnimationController _animationController;
  Animation animation;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.forward();
  }

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    animation = Tween(begin: 0.0, end: 0.25).animate(_animationController);

    _trendTagsStore = TrendTagsStore();
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    tagHistoryStore.fetch();
    _trendTagsStore.fetch();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildFirstRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            child: Padding(
              child: Text(
                I18n.of(context).search,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                    color: Theme.of(context).textTheme.headline6.color),
              ),
              padding: EdgeInsets.only(left: 16.0, bottom: 10.0),
            ),
          ),
        ],
      ),
    );
  }

  judgePushPage(Uri link) {
    if (link.host.contains('illusts')) {
      var idSource = link.pathSegments.last;
      try {
        int id = int.parse(idSource);
        Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (context) {
          return IllustPage(
            id: id,
          );
        }));
      } catch (e) {}
      return;
    }
    if (link.host.contains('user')) {
      var idSource = link.pathSegments.last;
      try {
        int id = int.parse(idSource);
        Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (context) {
          return UsersPage(
            id: id,
          );
        }));
      } catch (e) {}
      return;
    }
    if (link.host.contains('pixiv')) {
      if (link.path.contains("artworks")) {
        List<String> paths = link.pathSegments;
        int index = paths.indexOf("artworks");
        if (index != -1) {
          try {
            int id = int.parse(paths[index + 1]);
            Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(builder: (context) {
              return IllustPage(id: id);
            }));
            return;
          } catch (e) {}
        }
      }
      if (link.path.contains("users")) {
        List<String> paths = link.pathSegments;
        int index = paths.indexOf("users");
        if (index != -1) {
          try {
            int id = int.parse(paths[index + 1]);
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                builder: (context) => UsersPage(
                      id: id,
                    )));
          } catch (e) {
            print(e);
          }
        }
      }
      if (link.queryParameters['illust_id'] != null) {
        try {
          var id = link.queryParameters['illust_id'];
          Navigator.of(context, rootNavigator: true)
              .push(MaterialPageRoute(builder: (context) {
            return IllustPage(id: int.parse(id));
          }));

          return;
        } catch (e) {}
      }
      if (link.queryParameters['id'] != null) {
        try {
          var id = link.queryParameters['id'];
          Navigator.of(context, rootNavigator: true)
              .push(MaterialPageRoute(builder: (context) {
            return UsersPage(
              id: int.parse(id),
            );
          }));

          return;
        } catch (e) {}
      }
      if (link.pathSegments.length >= 2) {
        String i = link.pathSegments[link.pathSegments.length - 2];
        if (i == "i") {
          try {
            int id = int.parse(link.pathSegments[link.pathSegments.length - 1]);
            Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(builder: (context) {
              return IllustPage(id: id);
            }));
            return;
          } catch (e) {}
        }

        if (i == "u") {
          try {
            int id = int.parse(link.pathSegments[link.pathSegments.length - 1]);
            Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(builder: (context) {
              return UsersPage(
                id: id,
              );
            }));
            return;
          } catch (e) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (accountStore.now != null)
        return RefreshIndicator(
          onRefresh: () {
            return _trendTagsStore.fetch();
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 0.0,
                titleSpacing: 0.0,
                automaticallyImplyLeading: false,
                leading: RotationTransition(
                  alignment: Alignment.center,
                  turns: animation,
                  child: IconButton(
                      icon: Icon(Icons.dashboard,
                          color: Theme.of(context).textTheme.bodyText1.color),
                      onPressed: () async {
                        try {
                          var clipData =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (clipData != null) {
                            print(clipData.text ?? '');
                            final query = clipData.text ?? '';
                            if (query.startsWith('http')) {
                              judgePushPage(Uri.parse(query));
                            } else {
                              BotToast.showCustomText(
                                  onlyOne: true,
                                  duration: Duration(seconds: 1),
                                  toastBuilder: (textCancel) => Align(
                                        alignment: Alignment(0, 0.8),
                                        child: Card(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.dashboard,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 8.0),
                                                child: Text(I18n.of(context)
                                                    .not_the_correct_link),
                                              )
                                            ],
                                          ),
                                        ),
                                      ));
                            }
                          }
                        } catch (e) {}
                      }),
                ),
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search,
                        color: Theme.of(context).textTheme.bodyText1.color),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SearchSuggestionPage()));
                    },
                  )
                ],
              ),
              SliverToBoxAdapter(
                child: _buildFirstRow(context),
              ),
              SliverToBoxAdapter(
                child: Observer(builder: (context) {
                  if (tagHistoryStore.tags.isNotEmpty)
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            I18n.of(context).history,
                            style: TextStyle(
                                fontSize: 16.0,
                                color: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .color),
                          ),
                          Visibility(
                            visible: false,
                            child: Text(
                              I18n.of(context).clear,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .color),
                            ),
                          ),
                        ],
                      ),
                    );
                  else
                    return Container();
                }),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverToBoxAdapter(
                  child: Observer(
                    builder: (BuildContext context) {
                      if (tagHistoryStore.tags.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Wrap(
                            children: [
                              for (var f in tagHistoryStore.tags)
                                buildActionChip(f, context),
                            ],
                            runSpacing: 0.0,
                            spacing: 3.0,
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Observer(builder: (context) {
                  if (tagHistoryStore.tags.isNotEmpty)
                    return InkWell(
                      onTap: () {
                        tagHistoryStore.deleteAll();
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18.0,
                                color:
                                    Theme.of(context).textTheme.caption.color,
                              ),
                              Text(
                                I18n.of(context).clear_search_tag_history,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText2
                                    .copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .color),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  return Container();
                }),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    I18n.of(context).recommand_tag,
                    style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).textTheme.headline6.color),
                  ),
                ),
              ),
              if (_trendTagsStore.trendTags.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.all(8.0),
                  sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tags = _trendTagsStore.trendTags;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context, rootNavigator: true)
                                .push(MaterialPageRoute(builder: (_) {
                              return ResultPage(
                                word: tags[index].tag,
                              );
                            }));
                          },
                          onLongPress: () {
                            Navigator.of(context, rootNavigator: true)
                                .push(MaterialPageRoute(builder: (_) {
                              return IllustPage(id: tags[index].illust.id);
                            }));
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0))),
                            child: Stack(
                              children: <Widget>[
                                PixivImage(
                                  tags[index].illust.imageUrls.squareMedium,
                                  fit: BoxFit.cover,
                                ),
                                Opacity(
                                  opacity: 0.4,
                                  child: Container(
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                  ),
                                ),
                                Align(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          tags[index].tag,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: _trendTagsStore.trendTags.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3)),
                )
            ],
          ),
        );
      return Column(children: <Widget>[
        AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            I18n.of(context).search,
            style: Theme.of(context).textTheme.headline6,
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.search,
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (context) => SearchSuggestionPage()));
              },
            )
          ],
        ),
        Expanded(child: LoginInFirst())
      ]);
    });
  }

  Widget buildActionChip(TagsPersist f, BuildContext context) {
    return InkWell(
      onLongPress: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('${I18n.of(context).delete}?'),
                actions: [
                  FlatButton(
                      onPressed: () {
                        tagHistoryStore.delete(f.id);
                        Navigator.of(context).pop();
                      },
                      child: Text(I18n.of(context).ok)),
                  FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(I18n.of(context).cancel)),
                ],
              );
            });
      },
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
            builder: (context) => ResultPage(
                  word: f.name,
                  translatedName: f.translatedName ?? '',
                )));
      },
      child: Chip(
        padding: EdgeInsets.all(0.0),
        label: Text(
          f.name,
          style: TextStyle(fontSize: 12.0),
        ),
      ),
    );
  }

  TabController _tabController;
}
