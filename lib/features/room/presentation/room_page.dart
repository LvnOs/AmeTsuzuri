import 'package:flutter/material.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  String _selectedArea = '部屋の中をタップしてみてください';

  void _onAreaTapped(String areaName) {
    setState(() {
      _selectedArea = '$areaNameをタップしました';
    });

    debugPrint('$areaName tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F3A35),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(aspectRatio: 16 / 9, child: _buildRoom()),
              ),
            ),
            _buildMessageArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),

            // 窓
            _buildTapArea(
              name: '窓',
              left: constraints.maxWidth * 0.30,
              top: constraints.maxHeight * 0.06,
              width: constraints.maxWidth * 0.36,
              height: constraints.maxHeight * 0.54,
            ),

            // 本棚
            _buildTapArea(
              name: '本棚',
              left: constraints.maxWidth * 0.055,
              top: constraints.maxHeight * 0.10,
              width: constraints.maxWidth * 0.205,
              height: constraints.maxHeight * 0.72,
            ),

            // 机
            _buildTapArea(
              name: '机',
              left: constraints.maxWidth * 0.60,
              top: constraints.maxHeight * 0.53,
              width: constraints.maxWidth * 0.265,
              height: constraints.maxHeight * 0.42,
            ),

            // 瓶
            _buildTapArea(
              name: '瓶',
              left: constraints.maxWidth * 0.69,
              top: constraints.maxHeight * 0.315,
              width: constraints.maxWidth * 0.105,
              height: constraints.maxHeight * 0.28,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildTapArea({
    required String name,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onAreaTapped(name),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF201F1C),
      child: Text(
        _selectedArea,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFE8E1D4), fontSize: 16),
      ),
    );
  }
}
