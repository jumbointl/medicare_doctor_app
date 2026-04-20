import 'dart:math';
import 'dart:ui';

import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_drawing_board/paint_extension.dart';

/// Custom drawn triangles
class Triangle extends PaintContent {
  Triangle();

  Triangle.data({
    required this.startPoint,
    required this.A,
    required this.B,
    required this.C,
    required Paint paint,
  }) : super.paint(paint);

  factory Triangle.fromJson(Map<String, dynamic> data) {
    return Triangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      A: jsonToOffset(data['A'] as Map<String, dynamic>),
      B: jsonToOffset(data['B'] as Map<String, dynamic>),
      C: jsonToOffset(data['C'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;

  Offset A = Offset.zero;
  Offset B = Offset.zero;
  Offset C = Offset.zero;

  @override
  String get contentType => 'Triangle';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    A = Offset(
        startPoint.dx + (nowPoint.dx - startPoint.dx) / 2, startPoint.dy);
    B = Offset(startPoint.dx, nowPoint.dy);
    C = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  Triangle copy() => Triangle();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'A': A.toJson(),
      'B': B.toJson(),
      'C': C.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class Arrow extends PaintContent {
  Arrow();

  Arrow.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Arrow.fromJson(Map<String, dynamic> data) {
    return Arrow.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  Offset endPoint = Offset.zero;

  @override
  String get contentType => 'Arrow';

  @override
  void startDraw(Offset startPoint) {
    startPoint = startPoint;
    endPoint = startPoint; // Initialize the endpoint.
  }

  @override
  void drawing(Offset nowPoint) {
    endPoint = nowPoint; // Update the endpoint dynamically.
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = _createArrowPath();
    canvas.drawPath(path, paint);
  }

  Path _createArrowPath() {
    final Path path = Path();
    final Offset direction = endPoint - startPoint;
    final double arrowLength = direction.distance;


    // Define the arrow body line.
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(endPoint.dx, endPoint.dy);

    // Calculate the arrowhead points.
    final double angle = direction.direction; // Angle of the line.
    final double headSize = arrowLength * 0.3;
    final Offset leftHead = Offset(
      endPoint.dx - headSize * cos(angle - pi / 6),
      endPoint.dy - headSize * sin(angle - pi / 6),
    );
    final Offset rightHead = Offset(
      endPoint.dx - headSize * cos(angle + pi / 6),
      endPoint.dy - headSize * sin(angle + pi / 6),
    );

    // Add the arrowhead.
    path.moveTo(endPoint.dx, endPoint.dy);
    path.lineTo(leftHead.dx, leftHead.dy);
    path.moveTo(endPoint.dx, endPoint.dy);
    path.lineTo(rightHead.dx, rightHead.dy);

    return path;
  }

  @override
  Arrow copy() => Arrow();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'endPoint': endPoint.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class FrontArrow extends Arrow {
  @override
  String get contentType => 'FrontArrow';

  @override
  void drawing(Offset nowPoint) {
    // Ensures the arrow points right.
    super.drawing(Offset(nowPoint.dx, startPoint.dy));
  }

  @override
  FrontArrow copy() => FrontArrow();
}

class BackArrow extends Arrow {
  @override
  String get contentType => 'BackArrow';

  @override
  void drawing(Offset nowPoint) {
    // Ensures the arrow points left.
    super.drawing(Offset(startPoint.dx, nowPoint.dy));
  }

  @override
  BackArrow copy() => BackArrow();
}

class Ellipse extends PaintContent {
  Ellipse();

  Ellipse.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Ellipse.fromJson(Map<String, dynamic> data) {
    return Ellipse.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  Offset endPoint = Offset.zero;

  @override
  String get contentType => 'Ellipse';

  @override
  void startDraw(Offset startPoint) {
    startPoint = startPoint;
    endPoint = startPoint; // Initialize the endpoint.
  }

  @override
  void drawing(Offset nowPoint) {
    endPoint = nowPoint; // Update the endpoint dynamically.
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Rect rect = Rect.fromPoints(startPoint, endPoint);
    canvas.drawOval(rect, paint);
  }

  @override
  Ellipse copy() => Ellipse();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'endPoint': endPoint.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class Star extends PaintContent {
  Star();

  Star.data({
    required this.startPoint,
    required this.points,
    required Paint paint,
  }) : super.paint(paint);

  factory Star.fromJson(Map<String, dynamic> data) {
    return Star.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      points: List<Offset>.from((data['points'] as List)
          .map((point) => jsonToOffset(point as Map<String, dynamic>))),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  List<Offset> points = [];

  @override
  String get contentType => 'Star';

  @override
  void startDraw(Offset startPoint) {
    this.startPoint = startPoint;
    points = []; // Reset points for a new star.
  }

  @override
  void drawing(Offset nowPoint) {
    points = calculateStarPoints(startPoint, nowPoint, 5); // 5-pointed star.
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (points.isEmpty) return;

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  Star copy() => Star();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'points': points.map((p) => p.toJson()).toList(),
      'paint': paint.toJson(),
    };
  }

  List<Offset> calculateStarPoints(Offset center, Offset outerPoint, int numPoints) {
    final List<Offset> starPoints = [];
    final double outerRadius =
        (center - outerPoint).distance; // Distance from center to outer point.
    final double innerRadius = outerRadius / 2.5; // Ratio for the inner radius.
    final double angleStep = pi / numPoints; // Half-angle per star point.
    double angle = -pi / 2; // Start angle pointing upwards.

    for (int i = 0; i < numPoints * 2; i++) {
      final double radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      starPoints.add(Offset(x, y));
      angle += angleStep;
    }

    return starPoints;
  }
}