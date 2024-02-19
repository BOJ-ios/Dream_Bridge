import 'dart:ui';

enum ShapeType { circle, square, triangle }

class AnimatedShape {
  double size;
  Offset position;
  Offset targetPosition;
  ShapeType shapeType;

  AnimatedShape({
    required this.size,
    required this.position,
    required this.targetPosition,
    required this.shapeType,
  });

  void move(double progress) {
    position = Offset(
      position.dx + (targetPosition.dx - position.dx) * progress,
      position.dy + (targetPosition.dy - position.dy) * progress,
    );
  }
}