// // Static ECG Line Painter - matches the design exactly
// class ECGLinePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.grey.shade400
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;

//     final path = Path();
//     final width = size.width;
//     final height = size.height;
//     final centerY = height / 2;

//     // Start from left
//     path.moveTo(0, centerY);

//     // Flat line
//     path.lineTo(width * 0.15, centerY);

//     // Small P wave
//     path.lineTo(width * 0.18, centerY - 5);
//     path.lineTo(width * 0.22, centerY);

//     // Flat
//     path.lineTo(width * 0.28, centerY);

//     // QRS Complex - the main spike
//     path.lineTo(width * 0.30, centerY + 5); // Q dip
//     path.lineTo(width * 0.35, centerY - 35); // R spike up
//     path.lineTo(width * 0.40, centerY + 10); // S dip
//     path.lineTo(width * 0.45, centerY); // back to baseline

//     // Flat
//     path.lineTo(width * 0.55, centerY);

//     // T wave
//     path.lineTo(width * 0.60, centerY - 10);
//     path.lineTo(width * 0.68, centerY);

//     // Flat to end
//     path.lineTo(width, centerY);

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
