import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:pixez/main.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/Init/init_page.dart';
import 'package:pixez/page/hello/android_hello_page.dart';
import 'package:pixez/page/hello/hello_page.dart';
import 'package:pixez/page/network/network_page.dart';
import 'package:pixez/page/network/network_select.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuidePage extends StatefulWidget {
  @override
  _GuidePageState createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  List<Widget> _pageList;
  int index = 0;
  bool isNext = true;

  @override
  void initState() {
    _pageList = [InitPage(), NetworkSelectPage(), NetworkPage()];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                reverse: !isNext,
                transitionBuilder: (
                  Widget child,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) {
                  return SharedAxisTransition(
                    child: child,
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                  );
                },
                child: _pageList[index],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: index == 0 ? 0 : 1,
                    child: TextButton(
                      onPressed: () {
                        int backValue = index - 1;
                        if (backValue == 1 || backValue == 0) {
                          setState(() {
                            index = backValue;
                            isNext = false;
                          });
                        }
                      },
                      child: const Text('BACK'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      int nextValue = index + 1;
                      if (nextValue == 1) {
                        var prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(
                            'language_num', userSetting.languageNum);
                        //有可能用户啥都没选
                        final languageList = ['en-US', 'zh-CN', 'zh-TW', 'ja'];
                        ApiClient.Accept_Language =
                            languageList[userSetting.languageNum];
                        apiClient.httpClient.options
                                .headers[HttpHeaders.acceptLanguageHeader] =
                            ApiClient.Accept_Language;
                        setState(() {
                          index = nextValue;
                          isNext = true;
                        });
                      } else if (nextValue == 2) {
                        if (userSetting.disableBypassSni) {
                          var prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('guide_enable', false);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => Platform.isIOS
                                    ? HelloPage()
                                    : AndroidHelloPage()),
                            (route) => route == null,
                          );
                        } else {
                          setState(() {
                            index = nextValue;
                            isNext = true;
                          });
                        }
                      } else if (nextValue == 3) {
                        var prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('guide_enable', false);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => Platform.isIOS
                                  ? HelloPage()
                                  : AndroidHelloPage()),
                          (route) => route == null,
                        );
                      }
                    },
                    child: const Text('NEXT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
