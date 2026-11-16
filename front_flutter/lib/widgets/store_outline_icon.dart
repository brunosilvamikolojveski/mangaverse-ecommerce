import 'package:material_ui/material_ui.dart';

enum StoreSymbol { cart, person }

class StoreOutlineIcon extends StatelessWidget {
  const StoreOutlineIcon({
    super.key,
    required this.symbol,
    this.size = 22,
    this.color = Colors.white,
  });

  final StoreSymbol symbol;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _OutlinePainter(symbol, color),
  );
}

class _OutlinePainter extends CustomPainter {
  const _OutlinePainter(this.symbol, this.color);
  final StoreSymbol symbol;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (symbol == StoreSymbol.cart) {
      final cart = Path()
        ..moveTo(3, 4)
        ..lineTo(5, 4)
        ..lineTo(7.1, 15.1)
        ..cubicTo(7.3, 16.1, 8.1, 16.7, 9.1, 16.7)
        ..lineTo(17.6, 16.7)
        ..cubicTo(18.5, 16.7, 19.3, 16.1, 19.5, 15.3)
        ..lineTo(21, 8)
        ..lineTo(6, 8);
      canvas.drawPath(cart, stroke);
      canvas.drawCircle(const Offset(9.5, 20), 1, stroke);
      canvas.drawCircle(const Offset(18, 20), 1, stroke);
    } else {
      canvas.drawCircle(const Offset(12, 8), 3.5, stroke);
      canvas.drawPath(
        Path()
          ..moveTo(4.5, 20)
          ..cubicTo(5.2, 16.8, 7.7, 15, 12, 15)
          ..cubicTo(16.3, 15, 18.8, 16.8, 19.5, 20),
        stroke,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutlinePainter oldDelegate) =>
      oldDelegate.symbol != symbol || oldDelegate.color != color;
}
