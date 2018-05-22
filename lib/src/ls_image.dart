import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class LSImage extends StatelessWidget {
  LSImage(this.image, {this.height, this.width}) : super();
  final ui.Image image;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return new Container(
        height: height,
        child: new CustomPaint(
            painter: new LSImagePainter(image, width: width, height: height)));
  }
}

class LSImagePainter extends CustomPainter {
  ui.Image image;
  double width;
  double height;
  double _paintWidth;
  double _paintHeight;
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint();
    if (image != null) {
      canvas.drawImageRect(
          image,
          new Rect.fromLTWH(0.0, 0.0, _paintWidth, _paintHeight),
          new Rect.fromLTWH(0.0, 0.0, width ?? image.width.toDouble(),
              height ?? image.height.toDouble()),
          paint);
    }
  }

  LSImagePainter(this.image, {this.height, this.width}) : super() {
    if (image != null) {
      var frameW = width ?? image.width.toDouble();
      var frameH = height ?? image.height.toDouble();
      _paintWidth = image.width.toDouble();
      _paintHeight = _paintWidth * frameH / frameW;
    }
  }
  @override
  bool shouldRepaint(LSImagePainter oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(LSImagePainter oldDelegate) => false;
}
