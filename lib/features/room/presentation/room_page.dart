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

  // Curtain composition tuning. Width is relative to the room canvas width.
  static const Alignment _curtainAlignment = Alignment(0, -0.83);
  static const double _curtainWidthScale = 0.91;
  static const double _curtainHeightScale = 1.3;

  // Shared placement values for the bottle and its future water layer.
  static const Alignment _bottleAlignment = Alignment(0.58, -0.18);
  static const double _bottleScale = 0.13;

  // Vase composition tuning. Scale is relative to the room canvas width.
  static const Alignment _vaseAlignment = Alignment(0.33, -0.16);
  static const double _vaseScale = 0.091;

  // Flower composition tuning. Scale is relative to the room canvas width.
  static const Alignment _flowerAlignment = Alignment(0.34, -0.26);
  static const double _flowerScale = 0.13;

  // Letter composition tuning. Scale is relative to the room canvas width.
  static const Alignment _letterAlignment = Alignment(0, 0.07);
  static const double _letterScale = 0.22;

  // Chair composition tuning. Scale is relative to the room canvas width.
  static const Alignment _chairAlignment = Alignment(0, 0.72);
  static const double _chairScale = 0.47;

  // Rug composition tuning. Width and height are independently adjustable.
  static const Alignment _rugAlignment = Alignment(0.53, 0.935);
  static const double _rugWidthScale = 0.898;
  static const double _rugHeightScale = 0.80;

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
              Align(
                alignment: RoomPage._rugAlignment,
                child: Transform.scale(
                  scaleY: RoomPage._rugHeightScale,
                  child: SizedBox(
                    width: constraints.maxWidth * RoomPage._rugWidthScale,
                    child: Image.asset(
                      'assets/images/room/rug.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._curtainAlignment,
                child: Transform.scale(
                  scaleX: RoomPage._curtainWidthScale,
                  scaleY: RoomPage._curtainHeightScale,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Image.asset(
                      'assets/images/room/curtain.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._bottleAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._bottleScale,
                  child: Image.asset(
                    'assets/images/room/bottle.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._flowerAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._flowerScale,
                  child: Image.asset(
                    'assets/images/room/flower_initial.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._vaseAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._vaseScale,
                  child: Image.asset(
                    'assets/images/room/vase.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._letterAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._letterScale,
                  child: Image.asset(
                    'assets/images/room/letter.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._chairAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._chairScale,
                  child: Image.asset(
                    'assets/images/room/chair.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
