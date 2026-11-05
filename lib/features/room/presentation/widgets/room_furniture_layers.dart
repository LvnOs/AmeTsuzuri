import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/furniture_reaction.dart';
import 'package:flutter/material.dart';

class RoomFurnitureLayers extends StatelessWidget {
  const RoomFurnitureLayers._({super.key, required this.child});

  factory RoomFurnitureLayers.hanging({
    required Future<List<Furniture>> furnituresFuture,
    required String? furnitureId,
    required double roomWidth,
    required GlobalKey<FurnitureReactionState> reactionKey,
  }) {
    return RoomFurnitureLayers._(
      key: const ValueKey('roomFurnitureHangingSection'),
      child: _FurnitureImageLayer(
        key: const ValueKey('roomWindowHangingDecorAsyncFurnitureLayer'),
        layerKey: const ValueKey('windowHangingDecorFurnitureLayer'),
        furnituresFuture: furnituresFuture,
        furnitureId: furnitureId,
        roomWidth: roomWidth,
        alignment: _windowHangingDecorFurnitureAlignment,
        scale: _windowHangingDecorFurnitureScale,
        scaleCorrections: _windowHangingDecorScaleCorrections,
        supportedFurnitureIds: _windowHangingDecorFurnitureIds,
        reactionKey: reactionKey,
      ),
    );
  }

  factory RoomFurnitureLayers.surfaces({
    required Future<List<Furniture>> furnituresFuture,
    required double roomWidth,
    required String? floorRugFurnitureId,
    required String? curtainFurnitureId,
    required String? windowShelfDecorFurnitureId,
    required String? deskSurfaceLeftFurnitureId,
    required String? deskSurfaceRightFurnitureId,
  }) {
    return RoomFurnitureLayers._(
      key: const ValueKey('roomFurnitureSurfaceSection'),
      child: Stack(
        key: const ValueKey('roomFurnitureSurfaceLayers'),
        fit: StackFit.expand,
        children: [
          _RugLayer(
            key: const ValueKey('roomRugAsyncFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: floorRugFurnitureId,
            roomWidth: roomWidth,
          ),
          _CurtainLayer(
            key: const ValueKey('roomCurtainAsyncFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: curtainFurnitureId,
            roomWidth: roomWidth,
          ),
          _FurnitureImageLayer(
            key: const ValueKey('roomWindowShelfAsyncFurnitureLayer'),
            layerKey: const ValueKey('windowShelfDecorFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: windowShelfDecorFurnitureId,
            roomWidth: roomWidth,
            alignment: _windowShelfDecorFurnitureAlignment,
            scale: _windowShelfDecorFurnitureScale,
            scaleCorrections: _windowShelfDecorScaleCorrections,
            supportedFurnitureIds: _windowShelfDecorFurnitureIds,
          ),
          _FurnitureImageLayer(
            key: const ValueKey('roomDeskLeftAsyncFurnitureLayer'),
            layerKey: const ValueKey('deskSurfaceLeftFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: deskSurfaceLeftFurnitureId,
            roomWidth: roomWidth,
            alignment: _deskSurfaceLeftFurnitureAlignment,
            scale: _deskSurfaceLeftFurnitureScale,
            scaleCorrections: _deskSurfaceLeftScaleCorrections,
            supportedFurnitureIds: _deskSurfaceFurnitureIds,
          ),
          _FurnitureImageLayer(
            key: const ValueKey('roomDeskRightAsyncFurnitureLayer'),
            layerKey: const ValueKey('deskSurfaceRightFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: deskSurfaceRightFurnitureId,
            roomWidth: roomWidth,
            alignment: _deskSurfaceRightFurnitureAlignment,
            scale: _deskSurfaceRightFurnitureScale,
            scaleCorrections: _deskSurfaceRightScaleCorrections,
            supportedFurnitureIds: _deskSurfaceFurnitureIds,
          ),
        ],
      ),
    );
  }

  factory RoomFurnitureLayers.flowerAndVase({
    required Future<List<Furniture>> furnituresFuture,
    required String? furnitureId,
    required double roomWidth,
    required GlobalKey<FurnitureReactionState> reactionKey,
  }) {
    return RoomFurnitureLayers._(
      key: const ValueKey('roomFurnitureFlowerAndVaseSection'),
      child: Stack(
        key: const ValueKey('roomFlowerAndVaseLayers'),
        fit: StackFit.expand,
        children: [
          _FlowerLayer(
            key: const ValueKey('roomFlowerAsyncFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: furnitureId,
            roomWidth: roomWidth,
            reactionKey: reactionKey,
          ),
          Align(
            alignment: _vaseAlignment,
            child: SizedBox(
              width: roomWidth * _vaseScale,
              child: Image.asset(
                'assets/images/room/vase.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  factory RoomFurnitureLayers.chairAndReactionAreas({
    required Future<List<Furniture>> furnituresFuture,
    required double roomWidth,
    required String? windowHangingDecorFurnitureId,
    required String? flowerFurnitureId,
    required String? chairFurnitureId,
    required GlobalKey<FurnitureReactionState> windowHangingReactionKey,
    required GlobalKey<FurnitureReactionState> flowerReactionKey,
    required GlobalKey<FurnitureReactionState> chairReactionKey,
  }) {
    return RoomFurnitureLayers._(
      key: const ValueKey('roomFurnitureChairAndReactionSection'),
      child: Stack(
        key: const ValueKey('roomChairAndReactionLayers'),
        fit: StackFit.expand,
        children: [
          _ChairLayer(
            key: const ValueKey('roomChairAsyncFurnitureLayer'),
            furnituresFuture: furnituresFuture,
            furnitureId: chairFurnitureId,
            roomWidth: roomWidth,
            reactionKey: chairReactionKey,
          ),
          if (windowHangingDecorFurnitureId != null &&
              furnitureReactionTypeFor(windowHangingDecorFurnitureId) != null)
            _FurnitureReactionTapArea(
              furnitureId: windowHangingDecorFurnitureId,
              alignment: _windowHangingDecorFurnitureAlignment,
              width:
                  roomWidth *
                  _windowHangingDecorFurnitureScale *
                  (_windowHangingDecorScaleCorrections[windowHangingDecorFurnitureId] ??
                      1),
              aspectRatio: _windowHangingDecorFurnitureAspectRatio,
              onTap: () => windowHangingReactionKey.currentState?.play(),
            ),
          if (flowerFurnitureId != null &&
              furnitureReactionTypeFor(flowerFurnitureId) != null)
            _FurnitureReactionTapArea(
              furnitureId: flowerFurnitureId,
              alignment: _flowerAlignment,
              width: roomWidth * _flowerScale,
              aspectRatio: _flowerAspectRatio,
              onTap: () => flowerReactionKey.currentState?.play(),
            ),
          if (chairFurnitureId != null &&
              furnitureReactionTypeFor(chairFurnitureId) != null)
            _FurnitureReactionTapArea(
              furnitureId: chairFurnitureId,
              alignment: _chairAlignment,
              width: roomWidth * _chairScale,
              aspectRatio: _chairAspectRatio,
              onTap: () => chairReactionKey.currentState?.play(),
            ),
        ],
      ),
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

const _curtainAlignment = Alignment(0, -0.83);
const _curtainWidthScale = 0.91;
const _curtainHeightScale = 1.3;

const _vaseAlignment = Alignment(0.33, -0.16);
const _vaseScale = 0.091;

const _flowerAlignment = Alignment(0.34, -0.26);
const _flowerScale = 0.13;
const _flowerAspectRatio = 256 / 384;
const _windowVaseSlotId = 'living_room_window_vase';
const _flowerFurnitureIds = {
  'small_white_flower',
  'blue_violet_flower',
  'pale_yellow_flower',
};

const _deskSurfaceFurnitureIds = {
  'wooden_mug',
  'ink_bottle',
  'wooden_fox_figure',
};
const _deskSurfaceLeftFurnitureAlignment = Alignment(-0.65, 0.02);
const _deskSurfaceLeftFurnitureScale = 0.25;
const _deskSurfaceLeftScaleCorrections = {
  'wooden_mug': 1.0,
  'ink_bottle': 0.9,
  'wooden_fox_figure': 1.05,
};
const _deskSurfaceRightFurnitureAlignment = Alignment(0.70, 0.02);
const _deskSurfaceRightFurnitureScale = 0.25;
const _deskSurfaceRightScaleCorrections = {
  'wooden_mug': 1.0,
  'ink_bottle': 0.9,
  'wooden_fox_figure': 1.05,
};

const _windowShelfDecorFurnitureAlignment = Alignment(-0.55, -0.15);
const _windowShelfDecorFurnitureScale = 0.16;
const _windowShelfDecorFurnitureIds = {
  'small_houseplant',
  'wooden_bird_figure',
  'small_glass_ornament',
};
const _windowShelfDecorScaleCorrections = {
  'small_houseplant': 1.0,
  'wooden_bird_figure': 0.85,
  'small_glass_ornament': 0.78,
};

const _windowHangingDecorFurnitureAlignment = Alignment(0.57, -0.93);
const _windowHangingDecorFurnitureScale = 0.18;
const _windowHangingDecorFurnitureAspectRatio = 256 / 384;
const _windowHangingDecorFurnitureIds = {
  'wind_chime',
  'teru_teru_bozu',
  'moon_mobile',
};
const _windowHangingDecorScaleCorrections = {
  'wind_chime': 0.9,
  'teru_teru_bozu': 0.88,
  'moon_mobile': 0.92,
};

const _chairAlignment = Alignment(0, 0.72);
const _chairScale = 0.47;
const _chairAspectRatio = 512 / 679;
const _chairSlotId = 'living_room_chair';
const _chairFurnitureIds = {'wooden_chair', 'cushioned_chair', 'rocking_chair'};

const _curtainSlotId = 'living_room_window_curtain';

const _rugAlignment = Alignment(0.25, 1.035);
const _rugWidthScale = 0.800;
const _rugHeightScale = 0.75;

class _FlowerLayer extends StatelessWidget {
  const _FlowerLayer({
    super.key,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
    required this.reactionKey,
  });

  static const _initialFlowerAssetPath =
      'assets/images/room/flower_initial.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;
  final GlobalKey<FurnitureReactionState> reactionKey;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null || !_flowerFurnitureIds.contains(selectedId)) {
      return _buildFlower(_initialFlowerAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId &&
              furniture.slotIds.contains(_windowVaseSlotId)) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _initialFlowerAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildFlower(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildFlower(String imagePath, {String? furnitureId}) {
    final image = Image.asset(
      imagePath,
      key: ValueKey(
        furnitureId == null
            ? 'roomInitialFlowerImage'
            : 'roomFurnitureImage-$furnitureId',
      ),
      fit: BoxFit.contain,
      errorBuilder: furnitureId == null
          ? null
          : (context, error, stackTrace) => Image.asset(
              _initialFlowerAssetPath,
              key: const ValueKey('roomInitialFlowerImage'),
              fit: BoxFit.contain,
            ),
    );
    return Align(
      key: const ValueKey('roomFlowerLayer'),
      alignment: _flowerAlignment,
      child: SizedBox(
        width: roomWidth * _flowerScale,
        child: _withFurnitureReaction(image, furnitureId, reactionKey),
      ),
    );
  }
}

class _ChairLayer extends StatelessWidget {
  const _ChairLayer({
    super.key,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
    required this.reactionKey,
  });

  static const _fixedChairAssetPath = 'assets/images/room/chair.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;
  final GlobalKey<FurnitureReactionState> reactionKey;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null || !_chairFurnitureIds.contains(selectedId)) {
      return _buildChair(_fixedChairAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId &&
              furniture.slotIds.contains(_chairSlotId)) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _fixedChairAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildChair(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildChair(String imagePath, {String? furnitureId}) {
    final image = Image.asset(
      imagePath,
      key: ValueKey(
        furnitureId == null
            ? 'roomFixedChairImage'
            : 'roomFurnitureImage-$furnitureId',
      ),
      fit: BoxFit.contain,
      errorBuilder: furnitureId == null
          ? null
          : (context, error, stackTrace) => Image.asset(
              _fixedChairAssetPath,
              key: const ValueKey('roomFixedChairImage'),
              fit: BoxFit.contain,
            ),
    );
    return Align(
      key: const ValueKey('roomChairLayer'),
      alignment: _chairAlignment,
      child: SizedBox(
        width: roomWidth * _chairScale,
        child: _withFurnitureReaction(image, furnitureId, reactionKey),
      ),
    );
  }
}

class _CurtainLayer extends StatelessWidget {
  const _CurtainLayer({
    super.key,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
  });

  static const _initialCurtainAssetPath = 'assets/images/room/curtain.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null) {
      return _buildCurtain(_initialCurtainAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId &&
              furniture.slotIds.contains(_curtainSlotId)) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _initialCurtainAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildCurtain(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildCurtain(String imagePath, {String? furnitureId}) {
    return Align(
      key: const ValueKey('roomCurtainLayer'),
      alignment: _curtainAlignment,
      child: Transform.scale(
        scaleX: _curtainWidthScale,
        scaleY: _curtainHeightScale,
        child: SizedBox(
          width: roomWidth,
          child: Image.asset(
            imagePath,
            key: ValueKey(
              furnitureId == null
                  ? 'roomInitialCurtainImage'
                  : 'roomFurnitureImage-$furnitureId',
            ),
            fit: BoxFit.contain,
            errorBuilder: furnitureId == null
                ? null
                : (context, error, stackTrace) => Image.asset(
                    _initialCurtainAssetPath,
                    key: const ValueKey('roomInitialCurtainImage'),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RugLayer extends StatelessWidget {
  const _RugLayer({
    super.key,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
  });

  static const _fixedRugAssetPath = 'assets/images/room/rug.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null) {
      return _buildRug(_fixedRugAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _fixedRugAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildRug(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildRug(String imagePath, {String? furnitureId}) {
    return Align(
      key: const ValueKey('roomRugLayer'),
      alignment: _rugAlignment,
      child: Transform.scale(
        scaleY: _rugHeightScale,
        child: SizedBox(
          width: roomWidth * _rugWidthScale,
          child: Image.asset(
            imagePath,
            key: ValueKey(
              furnitureId == null
                  ? 'roomFixedRugImage'
                  : 'roomFurnitureImage-$furnitureId',
            ),
            fit: BoxFit.contain,
            errorBuilder: furnitureId == null
                ? null
                : (context, error, stackTrace) => Image.asset(
                    _fixedRugAssetPath,
                    key: const ValueKey('roomFixedRugImage'),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FurnitureImageLayer extends StatelessWidget {
  const _FurnitureImageLayer({
    super.key,
    required this.layerKey,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
    required this.alignment,
    required this.scale,
    required this.scaleCorrections,
    required this.supportedFurnitureIds,
    this.reactionKey,
  });

  final Key layerKey;
  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;
  final Alignment alignment;
  final double scale;
  final Map<String, double> scaleCorrections;
  final Set<String> supportedFurnitureIds;
  final GlobalKey<FurnitureReactionState>? reactionKey;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null || !supportedFurnitureIds.contains(selectedId)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        final furnitures = snapshot.data;
        if (furnitures == null) {
          return const SizedBox.shrink();
        }

        Furniture? selectedFurniture;
        for (final furniture in furnitures) {
          if (furniture.id == selectedId) {
            selectedFurniture = furniture;
            break;
          }
        }
        if (selectedFurniture == null) {
          return const SizedBox.shrink();
        }

        final scaleCorrection = scaleCorrections[selectedId] ?? 1;
        final image = Image.asset(
          'assets/images/${selectedFurniture.imagePath}',
          key: ValueKey('roomFurnitureImage-$selectedId'),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
        return Align(
          key: layerKey,
          alignment: alignment,
          child: SizedBox(
            width: roomWidth * scale * scaleCorrection,
            child: _withFurnitureReaction(image, selectedId, reactionKey),
          ),
        );
      },
    );
  }
}

Widget _withFurnitureReaction(
  Widget child,
  String? furnitureId,
  GlobalKey<FurnitureReactionState>? reactionKey,
) {
  if (furnitureId == null) {
    return child;
  }
  final reactionType = furnitureReactionTypeFor(furnitureId);
  if (reactionType == null) {
    return child;
  }
  return FurnitureReaction(
    key: reactionKey ?? ValueKey('furnitureReactionState-$furnitureId'),
    furnitureId: furnitureId,
    type: reactionType,
    child: child,
  );
}

class _FurnitureReactionTapArea extends StatelessWidget {
  const _FurnitureReactionTapArea({
    required this.furnitureId,
    required this.alignment,
    required this.width,
    required this.aspectRatio,
    required this.onTap,
  });

  final String furnitureId;
  final Alignment alignment;
  final double width;
  final double aspectRatio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        key: ValueKey('furnitureReactionTapArea-$furnitureId'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: width, height: width / aspectRatio),
      ),
    );
  }
}
