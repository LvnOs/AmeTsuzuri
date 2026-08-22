import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:flutter/material.dart';

class RoomPage extends StatelessWidget {
  const RoomPage({super.key, this.letterRepository});

  final LetterRepository? letterRepository;

  static const double _designWidth = 390;
  static const double _designHeight = 700;

  // Outdoor composition tuning. Keep x/y in the -1.0 to 1.0 Alignment range.
  static const Alignment _outdoorAlignment = Alignment(0.02, -0.94);
  static const double _outdoorScale = 0.66;

  // Post composition tuning. Scale is relative to the room canvas width.
  static const Alignment _postAlignment = Alignment(-0.50, -0.35);
  static const double _postScale = 0.19;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: _designWidth / _designHeight,
            child: _RoomBackgroundLayers(),
          ),
        ),
      ),
    );
  }
}

class _RoomBackgroundLayers extends StatelessWidget {
  const _RoomBackgroundLayers();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: RoomPage._outdoorScale,
                alignment: RoomPage._outdoorAlignment,
                child: Image.asset(
                  'assets/images/room/outdoor_summer.png',
                  fit: BoxFit.cover,
                  alignment: RoomPage._outdoorAlignment,
                ),
              ),
              Align(
                alignment: RoomPage._postAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._postScale,
                  child: Image.asset(
                    'assets/images/room/post.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Image.asset(
                'assets/images/room/room_base.png',
                fit: BoxFit.cover,
              ),
            ],
          ),
        );
      },
    );
  }
}
