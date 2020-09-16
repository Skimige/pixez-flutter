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

import 'package:bot_toast/bot_toast.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart' hide NestedScrollView;
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/component/painter_avatar.dart';
import 'package:pixez/component/pixiv_image.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/page/follow/follow_list.dart';
import 'package:pixez/page/shield/shield_page.dart';
import 'package:pixez/page/user/bookmark/bookmark_page.dart';
import 'package:pixez/page/user/detail/user_detail.dart';
import 'package:pixez/page/user/user_store.dart';
import 'package:pixez/page/user/works/works_page.dart';
import 'package:share/share.dart';

class UsersPage extends StatefulWidget {
  final int id;

  const UsersPage({Key key, this.id}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  UserStore userStore;
  TabController _tabController;
  ScrollController _scrollController;
  @override
  void initState() {
    userStore = UserStore(widget.id);
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    super.initState();
    userStore.firstFetch();
    muteStore.fetchBanUserIds();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  int _tabIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (muteStore.banUserIds.isNotEmpty) {
        if (muteStore.banUserIds
            .map((element) => int.parse(element.userId))
            .contains(widget.id)) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
            ),
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('X_X'),
                  RaisedButton(
                    child: Text(I18n.of(context).shielding_settings),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => ShieldPage()));
                    },
                  )
                ],
              ),
            ),
          );
        }
      }

      if (userStore.errorMessage != null) {
        if (userStore.errorMessage == '404')
          return Scaffold(
            appBar: AppBar(),
            body: Container(
                child: Center(
              child: Text('404 not found'),
            )),
          );
        return Scaffold(
          appBar: AppBar(),
          body: Container(
              child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Http error'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    color: Theme.of(context).accentColor,
                    onPressed: () {
                      userStore.errorMessage = null;
                      userStore.firstFetch();
                    },
                    child: Text(I18n.of(context).refresh),
                  ),
                )
              ],
            ),
          )),
        );
      }
      if (userStore.userDetail == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Container(
              child: Center(
            child: CircularProgressIndicator(),
          )),
        );
      }
      return Scaffold(
        body: NestedScrollView(
          pinnedHeaderSliverHeightBuilder: () {
            return MediaQuery.of(context).padding.top + kToolbarHeight + 46.0;
          },
          controller: _scrollController,
          innerScrollPositionKeyBuilder: () {
            var index = "Tab";
            index += _tabController.index.toString();
            return Key(index);
          },
          body: IndexedStack(index: _tabIndex, children: [
            NestedScrollViewInnerScrollPositionKeyWidget(
                Key('Tab0'),
                WorksPage(
                  id: widget.id,
                )),
            NestedScrollViewInnerScrollPositionKeyWidget(
                Key('Tab1'),
                BookmarkPage(
                  isNested: true,
                  id: widget.id,
                )),
            NestedScrollViewInnerScrollPositionKeyWidget(
                Key('Tab2'), UserDetailPage(userDetail: userStore.userDetail)),
          ]),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                elevation: 0.0,
                forceElevated: innerBoxIsScrolled,
                expandedHeight: 280,
                actions: <Widget>[
                  IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share('https://www.pixiv.net/users/${widget.id}');
                      }),
                  PopupMenuButton<int>(
                    onSelected: (index) async {
                      switch (index) {
                        case 0:
                          userStore.follow(needPrivate: true);
                          break;
                        case 1:
                          {
                            final result = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title:
                                        Text('${I18n.of(context).block_user}?'),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop("OK");
                                        },
                                      ),
                                      FlatButton(
                                        child: Text("CANCEL"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      )
                                    ],
                                  );
                                });
                            if (result == "OK") {
                              await muteStore.insertBanUserId(
                                  widget.id.toString(),
                                  userStore.userDetail.user.name);
                              Navigator.of(context).pop();
                            }
                          }
                          break;
                        case 2:
                          {
                            Clipboard.setData(ClipboardData(
                                text:
                                    'painter:${userStore.userDetail?.user?.name ?? ''}\npid:${widget.id}'));
                            BotToast.showText(
                                text: I18n.of(context).copied_to_clipboard);
                            break;
                          }
                        default:
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<int>(
                          value: 0,
                          child: Text(I18n.of(context).quietly_follow),
                        ),
                        PopupMenuItem<int>(
                          value: 1,
                          child: Text(I18n.of(context).block_user),
                        ),
                        PopupMenuItem<int>(
                          value: 2,
                          child: Text(I18n.of(context).copymessage),
                        ),
                      ];
                    },
                  )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    color: Theme.of(context).cardColor,
                    child: Stack(
                      children: <Widget>[
                        Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).padding.top + 160,
                            child: userStore.userDetail.profile
                                        .background_image_url !=
                                    null
                                ? PixivImage(userStore
                                    .userDetail.profile.background_image_url)
                                : Container(
                                    color: Theme.of(context).accentColor,
                                  )),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildHeader(context),
                              Container(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: <Widget>[
                                    _buildNameFollow(context),
                                    _buildComment(context)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: StickyTabBarDelegate(
                    child: TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    setState(() {
                      _tabIndex = index;
                    });
                  },
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(
                      text: I18n.of(context).works,
                    ),
                    Tab(
                      text: I18n.of(context).bookmark,
                    ),
                    Tab(
                      text: I18n.of(context).detail,
                    ),
                  ],
                )),
                pinned: true,
              ),
            ];
          },
        ),
      );
    });
  }

  Widget _buildNameFollow(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SelectableText(
                userStore.userDetail.user.name,
                style: Theme.of(context).textTheme.headline6,
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: Text(I18n.of(context).followed),
                      ),
                      body: FollowList(id: widget.id),
                    );
                  }));
                },
                child: Text(
                  '${userStore.userDetail.profile.total_follow_users} ${I18n.of(context).follow}',
                  style: Theme.of(context).textTheme.caption,
                ),
              )
            ]),
      ),
    );
  }

  Widget _buildComment(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: SingleChildScrollView(
          child: Text(
            '${userStore.userDetail.user.comment}',
            style: Theme.of(context).textTheme.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget w = Container(
      child: Observer(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: PainterAvatar(
                url: userStore.userDetail.user.profile_image_urls.medium,
                size: Size(80, 80),
                onTap: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
              child: userStore.isFollow
                  ? FlatButton(
                      textColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                      color: Theme.of(context).accentColor,
                      onPressed: () {
                        if (accountStore.now != null) {
                          if (int.parse(accountStore.now.userId) != widget.id) {
                            userStore.follow(needPrivate: false);
                          } else {
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Who is the most beautiful person in the world?')));
                          }
                        }
                      },
                      child: Text(I18n.of(context).followed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    )
                  : OutlineButton(
                      borderSide: BorderSide(),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      onPressed: () {
                        if (accountStore.now != null) {
                          if (int.parse(accountStore.now.userId) != widget.id) {
                            userStore.follow(needPrivate: false);
                          } else {
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Who is the most beautiful person in the world?')));
                          }
                        }
                      },
                      child: Text(I18n.of(context).follow),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                    ),
            )
          ],
        ),
      ),
    );
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 25),
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 55.0,
            child: Container(
              color: Theme.of(context).cardColor,
            ),
          ),
        ),
        Align(
          child: w,
          alignment: Alignment.bottomCenter,
        )
      ],
    );
  }
}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  StickyTabBarDelegate({@required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      child: this.child,
      color: Theme.of(context).cardColor,
    );
  }

  @override
  double get maxExtent => this.child.preferredSize.height;

  @override
  double get minExtent => this.child.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
