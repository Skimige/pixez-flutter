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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/lighting/lighting_page.dart';
import 'package:pixez/lighting/lighting_store.dart';
import 'package:pixez/main.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/search/result_illust_store.dart';

class ResultIllustList extends StatefulWidget {
  final String word;

  const ResultIllustList({Key key, @required this.word}) : super(key: key);

  @override
  _ResultIllustListState createState() => _ResultIllustListState();
}

class _ResultIllustListState extends State<ResultIllustList> {
  ResultIllustStore resultIllustStore;
  FutureGet futureGet;

  @override
  void initState() {
    futureGet = () => apiClient.getSearchIllust(widget.word);

    super.initState();
  }

  _showMaterialBottom() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setM) {
            return Container(
                child: Column(
              children: <Widget>[
                TabBar(tabs: [
                  Tab(text: 's'),
                  Tab(text: 'x'),
                  Tab(
                    text: 'y',
                  )
                ]),
                TabBar(tabs: [
                  Tab(text: 's'),
                  Tab(text: 'x'),
                  Tab(
                    text: 'y',
                  )
                ]),
                Slider(value: 0, max: 10, onChanged: (value) {})
              ],
            ));
          });
        });
  }

  List<int> starNum = [
    0,
    100,
    250,
    500,
    1000,
    5000,
    10000,
    20000,
    30000,
    50000,
  ];

  final sort = ["date_desc", "date_asc", "popular_desc"];
  static List<String> search_target = [
    "partial_match_for_tags",
    "exact_match_for_tags",
    "title_and_caption"
  ];
  String searchTarget = search_target[0];
  String selectSort = "date_desc";
  int selectStarNum = 0;
  double starValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: () {
                    _buildShowDateRange(context);
                  }),
              IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () {
                    _buildShowBottomSheet(context);
                    // _showMaterialBottom();
                  }),
            ],
          ),
          Expanded(child: LightingList(source: futureGet))
        ],
      ),
    );
  }

  DatePeriod datePeriod = DatePeriod(
      DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 8 * 1000)),
      DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000)));

  Future _buildShowDateRange(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setR) {
            return Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FlatButton(
                        onPressed: () {},
                        child: Text(I18n.of(context).Date_duration)),
                    FlatButton(
                        onPressed: () {
                          setState(() {
                            futureGet = () => apiClient.getSearchIllust(
                                widget.word,
                                search_target: searchTarget,
                                sort: selectSort,
                                start_date: datePeriod.start,
                                end_date: datePeriod.end);
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(I18n.of(context).Apply))
                  ],
                ),
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: RangePicker(
                      datePickerStyles: DatePickerRangeStyles(),
                      firstDate: DateTime.fromMillisecondsSinceEpoch(
                          DateTime.now().millisecondsSinceEpoch -
                              (24 * 60 * 60 * 365 * 1000 * 8)),
                      lastDate: DateTime.now(),
                      onChanged: (DatePeriod value) {
                        setR(() {
                          datePeriod = value;
                        });
                      },
                      selectedPeriod: datePeriod,
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }

  void _buildShowBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.0))),
        builder: (context) {
          return StatefulBuilder(builder: (_, setS) {
            return SafeArea(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton(
                              onPressed: () {},
                              child: Text(I18n.of(context).Filter)),
                          FlatButton(
                              onPressed: () {
                                setState(() {
                                  if (starValue == 0)
                                    futureGet = () => apiClient.getSearchIllust(
                                        widget.word,
                                        search_target: searchTarget,
                                        sort: selectSort);
                                  else
                                    futureGet = () => apiClient.getSearchIllust(
                                        '${widget.word} ${starNum[starValue.toInt()]}users入り',
                                        search_target: searchTarget,
                                        sort: selectSort);
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text(I18n.of(context).Apply)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl(
                            groupValue: search_target.indexOf(searchTarget),
                            children: <int, Widget>{
                              0: Text(I18n.of(context).Partial_Match_for_tag),
                              1: Text(I18n.of(context).Exact_Match_for_tag),
                              2: Text(I18n.of(context).title_and_caption),
                            },
                            onValueChanged: (int index) {
                              setS(() {
                                searchTarget = search_target[index];
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl(
                            groupValue: sort.indexOf(selectSort),
                            children: <int, Widget>{
                              0: Text(I18n.of(context).date_desc),
                              1: Text(I18n.of(context).date_asc),
                              2: Text(I18n.of(context).popular_desc),
                            },
                            onValueChanged: (int index) {
                              if (accountStore.now != null && index == 2) {
                                if (accountStore.now.isPremium == 0) {
                                  BotToast.showText(text: 'not premium');
                                  setState(() {
                                    futureGet = () => apiClient
                                        .getPopularPreview(widget.word);
                                  });
                                  Navigator.of(context).pop();
                                  return;
                                }
                              }
                              setS(() {
                                selectSort = sort[index];
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(starValue != 0
                              ? I18n.of(context).More_then_starNum_Bookmark(
                                  starNum[starValue.toInt()])
                              : 'users入り'),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 16.0),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Slider(
                            activeColor: Theme.of(context).accentColor,
                            onChanged: (double value) {
                              int v = value.toInt();
                              setS(() {
                                starValue = v.toDouble();
                              });
                            },
                            value: starValue,
                            max: 9.0,
                          ),
                        ),
                      ),
                      Container(
                        height: 16,
                      )
                    ],
                  )),
            );
          });
        });
  }
}
