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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pixez/constants.dart';
import 'package:pixez/document_plugin.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'directory_page.dart';

class SaveModeChoicePage extends StatefulWidget {
  bool isFirst;
  SaveModeChoicePage({Key key, this.isFirst}) : super(key: key);

  @override
  _SaveModeChoicePageState createState() => _SaveModeChoicePageState();
}

class _SaveModeChoicePageState extends State<SaveModeChoicePage>
    with SingleTickerProviderStateMixin {
  int groupValue = 0;
  AnimationController _animationController;

  Animation _animation;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = ColorTween(begin: Colors.blue, end: Colors.red)
        .animate(_animationController);
    _animationController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          icon: Icon(Icons.next_plan, color: Colors.white),
          onPressed: () async {
            if (groupValue == 0) {
              await _saffun(context);
            }
            if (groupValue == 1) {
              await _helplessfun(context, isFirst: widget.isFirst);
            }
            Navigator.of(context).pop();
          },
          backgroundColor: _animation.value,
          label: Text(
            I18n.of(context).start,
            style: TextStyle(color: Colors.white),
          )),
      body: Builder(builder: (context) {
        return SafeArea(
          child: Card(
            margin: EdgeInsets.all(0.0),
            elevation: 16.0,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16.0))),
            child: Column(
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                  title: CupertinoSlidingSegmentedControl(
                      groupValue: groupValue,
                      children: {
                        0: Text(
                          'SAF',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(fontSize: 16.0),
                        ),
                        1: Text(
                          I18n.of(context).old_way,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(fontSize: 16.0),
                        )
                      },
                      onValueChanged: (v) {
                        setState(() {
                          this.groupValue = v;
                        });
                        if (groupValue == 0) {
                          _animationController.reverse();
                        }
                        if (groupValue == 1) {
                          _animationController.forward();
                        }
                      }),
                  actions: [
                    IconButton(
                        icon: Icon(Icons.question_answer),
                        onPressed: () {
                          Constants.isGooglePlay || userSetting.disableBypassSni
                              ? launch(
                                  "https://developer.android.com/training/data-storage/shared/documents-files")
                              : launch(
                                  "https://developer.android.google.cn/training/data-storage/shared/documents-files");
                          Navigator.of(context).pop();
                        }),
                    IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        })
                  ],
                ),
                if (groupValue == 0)
                  Expanded(
                    child: Stack(
                      children: [
                        ListView(
                          padding: EdgeInsets.all(16.0),
                          children: [
                            Text(I18n.of(context).saf_hint),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(I18n.of(context).step + 1.toString()),
                            ),
                            Image.asset(
                              'assets/images/step1.png',
                              fit: BoxFit.fitWidth,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(I18n.of(context).step + 2.toString()),
                            ),
                            Image.asset(
                              'assets/images/step2.png',
                              fit: BoxFit.fitWidth,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (groupValue == 1)
                  Expanded(
                      child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(I18n.of(context).old_way_message),
                      )
                    ],
                  ))
              ],
            ),
          ),
        );
      }),
    );
  }
}

showPathDialog(BuildContext context, {bool isFirst = false}) async {
  return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SaveModeChoicePage(
            isFirst: isFirst,
          )));
}

Future _saffun(BuildContext context) async {
  await userSetting.setIsHelplessWay(false);
  await DocumentPlugin.choiceFolder();
}

Future _helplessfun(BuildContext context, {bool isFirst = false}) async {
  await userSetting.setIsHelplessWay(true);
  String initPath =
      isFirst ? "/storage/emulated/0/Pictures/pixez" : null; //过时api只能硬编码
  final path = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DirectoryPage(
            initPath: initPath,
          )));
  if (path != null) {
    final _preferences = await SharedPreferences.getInstance();
    await _preferences.setString('store_path', path);
  }
}
