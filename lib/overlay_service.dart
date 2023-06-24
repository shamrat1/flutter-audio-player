import 'package:audio_test/audio_title_overlay_widget.dart';
import 'package:audio_test/overlay_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverlayService {
  addAudioTitleOverlay(BuildContext context, Widget widget) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => AudioTitleOverlayWidget(
        onClear: () {
          Provider.of<OverlayHandlerProvider>(context, listen: false)
              .removeOverlay(context);
        },
        widget: widget,
      ),
    );

    Provider.of<OverlayHandlerProvider>(context, listen: false)
        .insertOverlay(context, overlayEntry);
  }
}
