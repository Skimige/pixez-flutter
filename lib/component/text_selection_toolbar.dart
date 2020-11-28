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

import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pixez/supportor_plugin.dart';

const double _kHandleSize = 21.0;
const double _kToolbarScreenPadding = 3.0;
const double _kToolbarHeight = 31.0;
const double _kToolbarContentDistanceBelow = _kHandleSize - 1.0;
const double _kToolbarContentDistance = 7.0;

class TranslateTextSelectionControls
    extends ExtendedMaterialTextSelectionControls {
  TranslateTextSelectionControls();

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        endpoints.length > 1 ? endpoints[1] : endpoints[0];
    const double closedToolbarHeightNeeded =
        _kToolbarScreenPadding + _kToolbarHeight + _kToolbarContentDistance;
    final double paddingTop = MediaQuery.of(context).padding.top;
    final double availableHeight = globalEditableRegion.top +
        startTextSelectionPoint.point.dy -
        textLineHeight -
        paddingTop;
    final bool fitsAbove = closedToolbarHeightNeeded <= availableHeight;
    final Offset anchor = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      fitsAbove
          ? globalEditableRegion.top +
              startTextSelectionPoint.point.dy -
              textLineHeight -
              _kToolbarContentDistance
          : globalEditableRegion.top +
              endTextSelectionPoint.point.dy +
              _kToolbarContentDistanceBelow,
    );

    return Stack(
      children: <Widget>[
        CustomSingleChildLayout(
          delegate: ExtendedMaterialTextSelectionToolbarLayout(
            anchor,
            _kToolbarScreenPadding + paddingTop,
            fitsAbove,
          ),
          child: TextSelectionToolbar(
            handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
            handleCopy: canCopy(delegate)
                ? () => handleCopy(delegate, clipboardStatus)
                : null,
            handlePaste:
                canPaste(delegate) ? () => handlePaste(delegate) : null,
            handleSelectAll:
                canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
            handleLike: () async {
              final TextEditingValue value = delegate.textEditingValue;
              String selectionText = value.selection.textInside(value.text);
              await SupportorPlugin.start(selectionText);
            },
          ),
        ),
      ],
    );
  }
}

class TextSelectionToolbar extends StatelessWidget {
  const TextSelectionToolbar({
    Key key,
    this.handleCopy,
    this.handleSelectAll,
    this.handleCut,
    this.handlePaste,
    this.handleLike,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final VoidCallback handleLike;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    if (handleCut != null) {
      items.add(FlatButton(
          child: Text(localizations.cutButtonLabel), onPressed: handleCut));
    }
    if (handleCopy != null) {
      items.add(FlatButton(
          child: Text(localizations.copyButtonLabel), onPressed: handleCopy));
    }
    if (handlePaste != null) {
      items.add(FlatButton(
        child: Text(localizations.pasteButtonLabel),
        onPressed: handlePaste,
      ));
    }
    if (handleSelectAll != null) {
      items.add(FlatButton(
          child: Text(localizations.selectAllButtonLabel),
          onPressed: handleSelectAll));
    }

    if (handleLike != null) {
      items.add(FlatButton(
          child: const Icon(Icons.translate), onPressed: handleLike));
    }

    if (items.isEmpty) {
      return Container(width: -1.0, height: 0.0);
    }

    return Material(
      elevation: 0.0,
      child: Wrap(children: items),
      borderRadius: const BorderRadius.all(Radius.circular(9.0)),
    );
  }
}
