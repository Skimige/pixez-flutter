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

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pixez/generated/l10n.dart';

const Map<String, String> PixivHeader = {
  "referer": "https://app-api.pixiv.net/",
  "User-Agent": "PixivIOSApp/5.8.0"
};

class PixivImage extends HookWidget {
  final String url;
  final Widget placeWidget;
  final bool fade;
  final BoxFit fit;
  final bool enableMemoryCache;
  final double height;
  final double width;

  PixivImage(this.url,
      {this.placeWidget,
      this.fade = true,
      this.fit,
      this.enableMemoryCache,
      this.height,
      this.width});

  bool already = false;

  @override
  Widget build(BuildContext context) {
    final _controller = useAnimationController(
        duration: const Duration(milliseconds: 500),
        lowerBound: 0.2,
        upperBound: 1.0);
    return ExtendedImage.network(
      url,
      height: height,
      width: width,
      fit: fit ?? BoxFit.fitWidth,
      headers: PixivHeader,
      enableMemoryCache: enableMemoryCache ?? true,
      loadStateChanged: (ExtendedImageState state) {
        if (state.extendedImageLoadState == LoadState.loading) {
          if (!_controller.isCompleted) _controller?.reset();
          return placeWidget;
        }
        if (state.extendedImageLoadState == LoadState.completed) {
          if (already) {
            return null;
          }
          already = true;
          if (!_controller.isCompleted) _controller?.forward();
          if (!fade)
            return ExtendedRawImage(
              fit: fit ?? BoxFit.fitWidth,
              image: state.extendedImageInfo?.image,
            );
          return FadeTransition(
            opacity: _controller,
            child: ExtendedRawImage(
              fit: BoxFit.fitWidth,
              image: state.extendedImageInfo?.image,
            ),
          );
        }
        if (state.extendedImageLoadState == LoadState.failed) {
          if (!_controller.isCompleted) _controller?.reset();
          return Container(
            height: 150,
            child: GestureDetector(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Icon(Icons.error),
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Text(
                      I18n.of(context).load_image_failed_click_to_reload,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
              onTap: () {
                state.reLoadImage();
              },
            ),
          );
        }
        return null;
      },
    );
  }
}

class PixivProvider {
  static ExtendedNetworkImageProvider url(String url) {
    return ExtendedNetworkImageProvider(url, headers: PixivHeader);
  }
}
