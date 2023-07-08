import 'package:flutter/material.dart';

class RotatingMusicNoteIcon extends StatefulWidget {
  const RotatingMusicNoteIcon(
      {super.key, required this.isPlaying, this.height});
  final bool isPlaying;
  final double? height;

  @override
  State<RotatingMusicNoteIcon> createState() => _RotatingMusicNoteIconState();
}

class _RotatingMusicNoteIconState extends State<RotatingMusicNoteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    animationController.repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaying) {
      animationController.repeat();
    } else {
      animationController.stop();
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          width: (widget.height ?? MediaQuery.sizeOf(context).height * 0.30) +
              (widget.height != null ? 5 : 10),
          height: (widget.height ?? MediaQuery.sizeOf(context).height * 0.30) +
              (widget.height != null ? 5 : 10),
        ),
        AnimatedBuilder(
          animation: animationController,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            width: widget.height ?? MediaQuery.sizeOf(context).height * 0.30,
            height: widget.height ?? MediaQuery.sizeOf(context).height * 0.30,
            alignment: Alignment.center,
            child: Icon(
              Icons.music_note_rounded,
              size: widget.height != null ? 40 : 150,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          builder: (context, child) {
            return Transform.rotate(
              angle: animationController.value * 6.3,
              child: child,
            );
          },
        ),
      ],
    );
  }
}
