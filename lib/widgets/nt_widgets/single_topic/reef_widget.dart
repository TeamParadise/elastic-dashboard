import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

// Data for reef widget
class ReefModel extends SingleTopicNTWidgetModel {
  @override
  // Type of widget (basically the name)
  String type = Reef.widgetType;

  // Constructor
  ReefModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    super.dataType,
    super.period,
  }) : super();

  ReefModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required super.jsonData,
  }) : super.fromJson();

  // Method to publish the reef values to NetworkTables, mostly taken from text display
  void publishData(String value) {
    bool publishTopic =
        ntTopic == null || !ntConnection.isTopicPublished(ntTopic!);

    createTopicIfNull();

    if (ntTopic == null) {
      return;
    }

    if (publishTopic) {
      ntConnection.publishTopic(ntTopic!);
    }

    ntConnection.updateDataFromTopic(ntTopic!, value);
  }
}

// The main "reef" widget (what is actually called in the rest of the dashboard)
class Reef extends NTWidget {
  // Widget name/type
  static const String widgetType = 'Reef';

  // Constructor? Just calls super.
  const Reef({super.key}) : super();

  @override
  // Build and draw the widget
  Widget build(BuildContext context) {
    ReefModel model = cast(context.watch<NTWidgetModel>());
    return ValueListenableBuilder(
      valueListenable: model.subscription!,
      builder: (context, data, child) {
        return _ReefWidget(model: model, value: data);
      },
    );
  }
}

// Stateful (adapts baesd on hover and mouse clicks) widgert
class _ReefWidget extends StatefulWidget {
  final ReefModel model;
  final Object? value;
  const _ReefWidget(
      {required this.model, required this.value});

  @override
  State<_ReefWidget> createState() => _HoverableHexWidgetState();
}

// The "state" of the
class _HoverableHexWidgetState extends State<_ReefWidget> {
  Offset? _hoverPosition;
  final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

  @override
  // Widget builder/drawer (again)
  Widget build(BuildContext context) {
    final painter =
        _ReefPainter(_hoverPosition, labels.indexOf(widget.value.toString()));

    return GestureDetector(
      onTapDown: (details) { // Clicked
        // Check which triangle was clicked
        for (int i = 0; i < painter.trianglePaths.length; i++) {
          if (_hoverPosition != null &&
              painter.trianglePaths[i].contains(_hoverPosition!)) {
            widget.model.publishData(labels[i]);
            break;
          }
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/background.png'), // Reef image in the background
            fit: BoxFit.cover,
          ),
        ),
        child: MouseRegion(
          onHover: (event) =>
              setState(() => _hoverPosition = event.localPosition), // Rebuild and draw with new posiiton
          onExit: (_) => setState(() => _hoverPosition = null), // Rebuild and draw with no position
          child: CustomPaint(
            size: Size.infinite,
            painter: painter,
          ),
        ),
      ),
    );
  }
}

// Painter class to draw the reef
class _ReefPainter extends CustomPainter {
  // Hover position and the currently selected triangle index
  final Offset? hoverPosition;
  final int selectedTriangleIndex;

  // "Paints" and colors for drawing the triangles and outline
  final outlinePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final baseTriangleColor = const Color(0x64FFFFFF);
  final List<Path> trianglePaths = [];

  // Constructor?
  _ReefPainter(this.hoverPosition, this.selectedTriangleIndex);

  @override
  // Method that paints/draws the reef on the canvas
  void paint(Canvas canvas, Size size) {
    // Create values that stay constant throughout drawing all the triangles
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = centerX / (2 * 0.866);

    // Calculate the corners of each side of the reef
    final List<Offset> vertices = [
      Offset(centerX - radius * 0.5, centerY + radius * 0.866),
      Offset(centerX + radius * 0.5, centerY + radius * 0.866),
      Offset(centerX + radius, centerY),
      Offset(centerX + radius * 0.5, centerY - radius * 0.866),
      Offset(centerX - radius * 0.5, centerY - radius * 0.866),
      Offset(centerX - radius, centerY),
    ];

    // Draw the triangles (forming a hexagon/the reef)
    for (int i = 0; i < 6; i++) {
      // Find the points of the two triangles we will form
      final start = vertices[i];
      final end = vertices[(i + 1) % 6];
      final center = Offset(centerX, centerY);
      final segmentMid =
          Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      // Draw triangles and provide if they are selected or not
      _drawTriangle(
          canvas, start, segmentMid, center, selectedTriangleIndex == i * 2);
      _drawTriangle(
          canvas, segmentMid, end, center, selectedTriangleIndex == i * 2 + 1);
    }
  }

  // Method to draw the triangles
  void _drawTriangle(
      Canvas canvas, Offset a, Offset b, Offset c, bool selected) {
    // Make path of triaangle
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    // Create the paint color of the triangle based on whether it is selected, hovered, or neither
    final trianglePaint = Paint()
      ..color = selected
          ? Colors.green
          : ((hoverPosition != null && path.contains(hoverPosition!))
              ? Colors.grey
              : baseTriangleColor);
    canvas.drawPath(path, trianglePaint);
    canvas.drawPath(path, outlinePaint);
    trianglePaths.add(path);
  }

  @override
  // Returns if the canvas should be repainted. Checks the values that we pass in (hoverPosition and selectedTriangleIndex) and checks if they have changed
  bool shouldRepaint(_ReefPainter oldDelegate) =>
      hoverPosition != oldDelegate.hoverPosition ||
      selectedTriangleIndex != oldDelegate.selectedTriangleIndex;
}
