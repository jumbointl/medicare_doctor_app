import '../model/prescription_pre_field_model.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
class PreFilledCanvas extends StatefulWidget {
  const PreFilledCanvas({super.key});

  @override
  State<PreFilledCanvas> createState() => _PreFilledCanvasState();
}

class _PreFilledCanvasState extends State<PreFilledCanvas> {
  ui.Image? logoImage;
   PrescriptionPreFieldModel? prescriptionPreFieldModel;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PreFilledTextPainter(logoImage,prescriptionPreFieldModel),
      child: Container(),
    );
  }
}

class PreFilledTextPainter extends CustomPainter {
  final ui.Image? logoImage;
  final PrescriptionPreFieldModel? prescriptionPreFieldModel;
  PreFilledTextPainter(this.logoImage, this.prescriptionPreFieldModel);

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    final clinicTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    final smallTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
    );

    void drawText(String text, Offset position, TextStyle style, {bool alignRight = false}) {
      final textSpan = TextSpan(style: style, text: text);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double x = position.dx;
      if (alignRight) {
        x = size.width - textPainter.width - 20; // Aligning text to the right
      }

      textPainter.paint(canvas, Offset(x, position.dy));
    }

    void drawKeyValueText(String label, String value, Offset position, TextStyle style, Canvas canvas, {bool alignRight = false}) {
      final labelSpan = TextSpan(style: style, text: "$label: ");
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final valueSpan = TextSpan(style: style, text: value);
      final valuePainter = TextPainter(
        text: valueSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double xLabel = position.dx;
      double xValue = position.dx + labelPainter.width + 8;

      if (alignRight) {
        xValue = size.width - valuePainter.width - 20;
        xLabel = xValue - labelPainter.width;
      }

      labelPainter.paint(canvas, Offset(xLabel, position.dy));
      valuePainter.paint(canvas, Offset(xValue, position.dy));
    }

    double xPosLeft = 20;
    double yPos = 20;
    final dividerPaint = Paint()..color = Colors.black..strokeWidth = 1;

    // Clinic Details (Left Side)
    drawText(prescriptionPreFieldModel?.clinicName??"", Offset(xPosLeft, yPos), clinicTextStyle);
    yPos += 30;
    drawText(prescriptionPreFieldModel?.clinicAddress??"", Offset(xPosLeft, yPos), smallTextStyle);
    yPos += 20;
    drawText('Phone: ${prescriptionPreFieldModel?.phone??""}', Offset(xPosLeft, yPos), smallTextStyle);
    yPos += 20;
    drawText('Email: ${prescriptionPreFieldModel?.email??""}', Offset(xPosLeft, yPos), smallTextStyle);
    yPos += 20;
    canvas.drawLine(Offset(10, yPos), Offset(size.width - 10, yPos), dividerPaint);
    yPos += 15;
    // **Draw Logo (Right Side)**
    if (logoImage != null) {
      double logoWidth = 80; // Adjust size as needed
      double logoHeight = 80;
      double logoX = size.width - logoWidth - 20; // Position logo at the right
      double logoY = 20; // Align it with clinic details

      canvas.drawImageRect(
        logoImage!,
        Rect.fromLTWH(0, 0, logoImage!.width.toDouble(), logoImage!.height.toDouble()), // Source
        Rect.fromLTWH(logoX, logoY, logoWidth, logoHeight), // Destination
        Paint(),
      );
    }
    // Patient Details (Left Side)
    drawKeyValueText("Patient ID", prescriptionPreFieldModel?.patientId??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 20;
    drawKeyValueText("Appointment ID", prescriptionPreFieldModel?.appointmentID??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 20;
    drawKeyValueText("Name", prescriptionPreFieldModel?.patientName??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 20;
    drawKeyValueText("Age", prescriptionPreFieldModel?.patientAge??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 20;
    drawKeyValueText("Gender", prescriptionPreFieldModel?.patientGender??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 20;
    drawKeyValueText("Phone", prescriptionPreFieldModel?.patientPhone??"", Offset(xPosLeft, yPos), textStyle, canvas);
    yPos += 15;

    // Doctor Details (Right Side, Aligned to Right)
    drawText(prescriptionPreFieldModel?.doctorName??"", Offset(size.width, yPos - 75), textStyle, alignRight: true);
    yPos += 10;
    drawText(prescriptionPreFieldModel?.doctorSpec??"", Offset(size.width, yPos - 60), textStyle, alignRight: true);
    yPos += 10;
    drawText(prescriptionPreFieldModel?.doctorDept??"", Offset(size.width, yPos - 45), textStyle, alignRight: true);
    // yPos += 10;

    // // Final Divider
    // yPos += 20; // Add space before last divider
    canvas.drawLine(Offset(10, yPos), Offset(size.width - 10, yPos), dividerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
