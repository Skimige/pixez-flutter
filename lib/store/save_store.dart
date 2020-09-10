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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pixez/document_plugin.dart';
import 'package:pixez/exts.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/models/task_persist.dart';
import 'package:pixez/page/task/job_page.dart';
import 'package:save_in_gallery/save_in_gallery.dart';

part 'save_store.g.dart';

enum SaveState { JOIN, SUCCESS, ALREADY, INQUEUE }

class SaveData {
  Illusts illusts;
  String fileName;
}

class SaveStream {
  SaveState state;
  Illusts data;
  int index;

  SaveStream(this.state, this.data, {this.index});
}

class JobEntity {
  int max;
  int min;
  int status;
}

class SaveStore = _SaveStoreBase with _$SaveStore;

abstract class _SaveStoreBase with Store {
  _SaveStoreBase() {
    streamController = StreamController();
    saveStream = ObservableStream(streamController.stream.asBroadcastStream());

  }

  @override
  void dispose() async {
    await streamController?.close();
  }

  void listenBehavior(SaveStream stream) {
    switch (stream.state) {
      case SaveState.SUCCESS:
        BotToast.showCustomText(
            onlyOne: true,
            duration: Duration(seconds: 1),
            toastBuilder: (textCancel) => Align(
                  alignment: Alignment(0, 0.8),
                  child: Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text(
                              "${stream.data.title} ${I18n.of(context).saved}"),
                        )
                      ],
                    ),
                  ),
                ));
        break;
      case SaveState.JOIN:
        BotToast.showCustomText(
            onlyOne: true,
            duration: Duration(seconds: 1),
            toastBuilder: (textCancel) => Align(
                  alignment: Alignment(0, 0.8),
                  child: Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                            icon: Icon(Icons.arrow_downward),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true)
                                  .push(MaterialPageRoute(builder: (context) {
                                return JobPage();
                              }));
                            }),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text("${I18n.of(context).append_to_query}"),
                        )
                      ],
                    ),
                  ),
                ));
        break;
      case SaveState.INQUEUE:
        BotToast.showCustomText(
            onlyOne: true,
            duration: Duration(seconds: 1),
            toastBuilder: (textCancel) => Align(
                  alignment: Alignment(0, 0.8),
                  child: Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(icon: Icon(Icons.info), onPressed: () {}),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text("${I18n.of(context).already_in_query}"),
                        )
                      ],
                    ),
                  ),
                ));
        break;
      case SaveState.ALREADY:
        BotToast.showCustomText(
            onlyOne: true,
            duration: Duration(seconds: 1),
            toastBuilder: (textCancel) => Align(
                  alignment: Alignment(0, 0.8),
                  child: Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                            icon: Icon(Icons.refresh),
                            onPressed: () {
                              saveStore.redo(stream.data, stream.index);
                            }),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Text("${I18n.of(context).already_saved}"),
                        )
                      ],
                    ),
                  ),
                ));
        break;
      default:
    }
  }

  BuildContext context;

  StreamController<SaveStream> streamController;
  ObservableStream<SaveStream> saveStream;

  Future<String> findLocalPath() async {
    final directory = Platform.isAndroid
        ? (await getTemporaryDirectory()).path
        : (await getApplicationDocumentsDirectory()).path + '/pixez';
    return directory;
  }

  final imageDio = Dio();
  TaskPersistProvider taskPersistProvider = TaskPersistProvider();
  Map<String, JobEntity> jobMaps = Map();

  _joinOnDart(String url, Illusts illusts, String fileName) async {
    await taskPersistProvider.open();
    final result =await taskPersistProvider.getAccount(url);
    if (result != null) {
      streamController.add(SaveStream(SaveState.INQUEUE, illusts));
      return;
    }
    var taskPersist = TaskPersist(
        userId: illusts.user.id,
        userName: illusts.user.name,
        illustId: illusts.id,
        title: illusts.title,
        fileName: fileName,
        status: 0,
        url: url);
    try {
      await taskPersistProvider.insert(taskPersist);
      var savePath = (await getTemporaryDirectory()).path +
          Platform.pathSeparator +
          fileName;
      await imageDio.download(url, savePath,
          onReceiveProgress: (received, total) async {
        if (total != -1) {
          var job = jobMaps[url];
          if (job != null) {
            job
              ..min = received
              ..status = 1
              ..max = total;
          } else {
            jobMaps[url] = JobEntity()
              ..status = 1
              ..min = received
              ..max = total;
          }
          if (received / total == 1) {
            await taskPersistProvider.update(taskPersist..status = 2);
            File file = File(savePath);
            final uint8list = await file.readAsBytes();
            await saveStore.saveToGallery(uint8list, illusts, fileName);
            BotToast.showCustomText(
                onlyOne: true,
                duration: Duration(seconds: 1),
                toastBuilder: (textCancel) => Align(
                      alignment: Alignment(0, 0.8),
                      child: Card(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 8.0),
                              child: Text(
                                  "${illusts.title} ${I18n.of(context).saved}"),
                            )
                          ],
                        ),
                      ),
                    ));
            var job = jobMaps[url];
            if (job != null) {
              job.status = 2;
            } else {
              jobMaps[url] = JobEntity()
                ..status = 2
                ..min = 1
                ..max = 1;
            }
          }
        }
      },
          deleteOnError: true,
          options: Options(headers: {
            "referer": "https://app-api.pixiv.net/",
            "User-Agent": "PixivIOSApp/5.8.0"
          }));
    } catch (e) {
      print(e);
      await taskPersistProvider.update(taskPersist..status = 3);
      var job = jobMaps[url];
      if (job != null) {
        job.status = 3;
      } else {
        jobMaps[url] = JobEntity()
          ..status = 3
          ..min = 1
          ..max = 1;
      }
    }
  }

  _joinQueue(String url, Illusts illusts, String fileName) async {
    _joinOnDart(url, illusts, fileName);
    return;
  }

  _saveInternal(String url, Illusts illusts, String fileName) async {
    if (Platform.isAndroid) {
      try {
        String targetFileName = fileName;
        if (userSetting.singleFolder) {
          targetFileName =
              "${illusts.user.name.toLegal()}_${illusts.user.id}/$fileName";
        }
        final isExist = await DocumentPlugin.exist(targetFileName);
        if (isExist) {
          streamController.add(SaveStream(SaveState.ALREADY, illusts));
          return;
        }
      } catch (e) {}
    }
    streamController.add(SaveStream(SaveState.JOIN, illusts));
    File file = await getCachedImageFile(url);
    if (file == null) {
      _joinQueue(url, illusts, fileName);
    } else {
      saveToGallery(file.readAsBytesSync(), illusts, fileName);
    }
  }

  Future<void> saveToGallery(
      Uint8List uint8list, Illusts illusts, String fileName) async {
    if (Platform.isAndroid) {
      try {
        if (userSetting.singleFolder) {
          String name = illusts.user.name.toLegal();
          String id = illusts.user.id.toString();
          fileName = "${name}_$id/$fileName";
        }
        DocumentPlugin.save(uint8list, fileName);
      } catch (e) {
        print(e);
      }
      return;
    } else {
      final _imageSaver = ImageSaver();
      List<Uint8List> bytesList = [uint8list];
      final res = await _imageSaver.saveImages(
          imageBytes: bytesList, directoryName: 'pxez');
    }
  }

  @action
  void saveChoiceImage(Illusts illusts, List<bool> indexs) {
    if (illusts.pageCount == 1) {
      saveImage(illusts);
    } else {
      for (var i = 0; i < indexs.length; i++) {
        if (indexs[i]) {
          saveImage(illusts, index: i);
        }
      }
    }
  }

  redo(Illusts illusts, int index) async {
    saveImage(illusts, index: index, redo: true);
  }

  String _handleFileName(Illusts illust, int index, String memType) {
    final result = userSetting.format
        .replaceAll("{illust_id}", illust.id.toString())
        .replaceAll("{user_id}", illust.user.id.toString())
        .replaceAll("{part}", index.toString())
        .replaceAll("{user_name}", illust.user.name.toString())
        .replaceAll("{title}", illust.title);
    return "$result$memType".toLegal();
  }

  @action
  Future<void> saveImage(Illusts illusts,
      {int index, bool redo = false}) async {
    String memType;
    if (illusts.pageCount == 1) {
      String url = illusts.metaSinglePage.originalImageUrl;
      memType = url.contains('.png') ? '.png' : '.jpg';
      String fileName = _handleFileName(illusts, 0, memType);
      if (redo) {}
      _saveInternal(url, illusts, fileName);
    } else {
      if (index != null) {
        var url = illusts.metaPages[index].imageUrls.original;
        memType = url.contains('.png') ? '.png' : '.jpg';
        String fileName = _handleFileName(illusts, index, memType);
        if (redo) {}
        _saveInternal(url, illusts, fileName);
      } else {
        int index = 0;
        illusts.metaPages.forEach((f) {
          String url = f.imageUrls.original;
          memType = url.contains('.png') ? '.png' : '.jpg';
          String fileName = _handleFileName(illusts, index, memType);
          if (redo) {}
          _saveInternal(url, illusts, fileName);
          index++;
        });
      }
    }
  }
}
