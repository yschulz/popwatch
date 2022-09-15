import 'package:flutter/material.dart';

class GaugePainter extends CustomPainter {

	GaugePainter({ required this.percent }) : super();

	final double percent;

	@override
	void paint(Canvas canvas, Size size) {
		// Color color = Color.lerp(Colors.green!, Colors.red!, percent);
    Color color = Color.lerp(Colors.green, Colors.red, percent)!;

		Paint circleBrush = new Paint()
			..strokeWidth = 10.0
			..color = Colors.indigo[400]!.withOpacity(0.4)
			..style = PaintingStyle.stroke;

		Paint elapsedBrush = new Paint()
			..strokeWidth = 8
			..color = color
			..style = PaintingStyle.stroke;

    Offset start = new Offset(0, size.height/2);
    Offset end = new Offset(size.width, size.height/2);
    Offset endOverlay = new Offset(size.width*percent, size.height/2);

    canvas.drawLine(start, end, circleBrush);
    canvas.drawLine(start, endOverlay, elapsedBrush);

	}

	@override
	bool shouldRepaint(CustomPainter oldDelegate) => true;
}