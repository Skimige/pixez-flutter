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
import 'package:extended_image/extended_image.dart';
import 'package:mobx/mobx.dart';
import 'package:pixez/models/recommend.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/picture/illust_store.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

part 'lighting_store.g.dart';

class LightingStore = _LightingStoreBase with _$LightingStore;

typedef Future<Response> FutureGet();

abstract class _LightingStoreBase with Store {
  FutureGet source;
  String nextUrl;
  RefreshController _controller;
  @observable
  ObservableList<IllustStore> iStores = ObservableList();
  dispose() {
    iStores.forEach((element) {
      final provider = ExtendedNetworkImageProvider(
        element.illusts.imageUrls.medium,
      );
      provider.evict();
    });
    iStores.clear();
  }

  @observable
  String errorMessage;
  _LightingStoreBase(this.source, this._controller);

  @action
  Future<bool> fetch() async {
    nextUrl = null;
    errorMessage = null;
    if (_controller?.footerMode != null)
      _controller?.footerMode?.value = LoadStatus.idle;
    try {
      final result = await source();
      Recommend recommend = Recommend.fromJson(result.data);
      nextUrl = recommend.nextUrl;
      iStores.clear();
      iStores.addAll(recommend.illusts.map((e) => IllustStore(e.id, e)));
      _controller.refreshCompleted();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      _controller.refreshFailed();
      return false;
    }
  }

  @action
  update(FutureGet futureGet) async {
    source = futureGet;
    await fetch();
  }

  @action
  Future<bool> fetchNext() async {
    errorMessage = null;
    try {
      if (nextUrl != null && nextUrl.isNotEmpty) {
        Response result = await apiClient.getNext(nextUrl);
        Recommend recommend = Recommend.fromJson(result.data);
        nextUrl = recommend.nextUrl;
        iStores.addAll(recommend.illusts.map((e) => IllustStore(e.id, e)));
        _controller.loadComplete();
      } else {
        _controller.loadNoData();
      }
      return true;
    } catch (e) {
      _controller.loadFailed();
      return false;
    }
  }
}
