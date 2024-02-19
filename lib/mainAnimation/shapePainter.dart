import 'package:flutter/material.dart';

import 'package:dream_bridge/mainAnimation/shape.dart';

class ShapePainter extends CustomPainter {
  List<AnimatedShape> shapes;
  double progress;

  ShapePainter(this.shapes, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var shape in shapes) {
      final paint = Paint()..color = Colors.purple.withAlpha(150);
      shape.move(progress);

      switch (shape.shapeType) {
        case ShapeType.circle:
          canvas.drawCircle(shape.position, shape.size, paint);
          break;
        case ShapeType.square:
          final rect = Rect.fromCenter(center: shape.position, width: shape.size, height: shape.size);
          canvas.drawRect(rect, paint);
          break;
        case ShapeType.triangle:
          final path = Path();
          path.moveTo(shape.position.dx, shape.position.dy - shape.size / 2);
          path.lineTo(shape.position.dx - shape.size / 2, shape.position.dy + shape.size / 2);
          path.lineTo(shape.position.dx + shape.size / 2, shape.position.dy + shape.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
