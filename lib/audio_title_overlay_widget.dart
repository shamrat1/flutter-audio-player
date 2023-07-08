import 'package:audio_test/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'overlay_handler.dart';

class AudioTitleOverlayWidget extends StatefulWidget {
  final VoidCallback onClear;
  final Widget widget;

  const AudioTitleOverlayWidget(
      {super.key, required this.onClear, required this.widget});

  @override
  _AudioTitleOverlayWidgetState createState() =>
      _AudioTitleOverlayWidgetState();
}

class _AudioTitleOverlayWidgetState extends State<AudioTitleOverlayWidget> {
  double? width;
  double? oldWidth;
  double? oldHeight;
  double? height;

  bool isInPipMode = false;

  Offset offset = const Offset(0, 0);

  Widget? player;

  _onExitPipMode() {
    Future.microtask(() {
      setState(() {
        isInPipMode = false;
        width = oldWidth;
        height = oldHeight;
        offset = const Offset(0, 0);
      });
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      Provider.of<OverlayHandlerProvider>(context, listen: false).disablePip();
    });
  }

  _onPipMode() {
    double aspectRatio =
        Provider.of<OverlayHandlerProvider>(context, listen: false).aspectRatio;

//    Provider.of<OverlayHandlerProvider>(context, listen: false).enablePip();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        isInPipMode = true;
        width = (oldWidth ?? 0) - 32.0;
        height = Constants.VIDEO_TITLE_HEIGHT_PIP;
        offset = Offset(16,
            (oldHeight ?? 0) - (height ?? 0) - Constants.BOTTOM_PADDING_PIP);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (width == null || height == null) {
      oldWidth = width = MediaQuery.of(context).size.width;
      oldHeight = height = MediaQuery.of(context).size.height;
    }
    return Consumer<OverlayHandlerProvider>(
        builder: (context, overlayProvider, _) {
      if (overlayProvider.inPipMode != isInPipMode) {
        isInPipMode = overlayProvider.inPipMode;
        if (isInPipMode) {
          _onPipMode();
        } else {
          _onExitPipMode();
        }
      }
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 150),
        left: offset.dx,
        top: offset.dy,
        child: Material(
          elevation: isInPipMode ? 3.0 : 0.0,
          borderRadius: BorderRadius.circular(15),
          shadowColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: AnimatedContainer(
            height: height,
            width: width,
            child: widget.widget,
            duration: const Duration(milliseconds: 250),
          ),
        ),
      );
    });
  }
}
