
class PageJsonData {
  final int page;
  final List<DrawingData> jsonData;

  PageJsonData({required this.page, required this.jsonData});

  factory PageJsonData.fromJson(Map<String, dynamic> json) {
    return PageJsonData(
      page: json['page'] as int,
      jsonData: (json['jsonData'] as List)
          .map((item) => DrawingData.fromJson(item))
          .toList(),
    );
  }
}

class DrawingData {
  final String type;
  final PathData path;
  final PaintData paint;

  DrawingData({required this.type, required this.path, required this.paint});

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      type: json['type'] as String,
      path: PathData.fromJson(json['path']),
      paint: PaintData.fromJson(json['paint']),
    );
  }
}

class PathData {
  final int fillType;
  final List<PathStep> steps;

  PathData({required this.fillType, required this.steps});

  factory PathData.fromJson(Map<String, dynamic> json) {
    return PathData(
      fillType: json['fillType'] as int,
      steps: (json['steps'] as List)
          .map((step) => PathStep.fromJson(step))
          .toList(),
    );
  }
}

class PathStep {
  final String type;
  final double x;
  final double y;

  PathStep({required this.type, required this.x, required this.y});

  factory PathStep.fromJson(Map<String, dynamic> json) {
    return PathStep(
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

class PaintData {
  final int blendMode;
  final int color;
  final int filterQuality;
  final bool invertColors;
  final bool isAntiAlias;
  final int strokeCap;
  final int strokeJoin;
  final double strokeWidth;
  final int style;

  PaintData({
    required this.blendMode,
    required this.color,
    required this.filterQuality,
    required this.invertColors,
    required this.isAntiAlias,
    required this.strokeCap,
    required this.strokeJoin,
    required this.strokeWidth,
    required this.style,
  });

  factory PaintData.fromJson(Map<String, dynamic> json) {
    return PaintData(
      blendMode: json['blendMode'] as int,
      color: json['color'] as int,
      filterQuality: json['filterQuality'] as int,
      invertColors: json['invertColors'] as bool,
      isAntiAlias: json['isAntiAlias'] as bool,
      strokeCap: json['strokeCap'] as int,
      strokeJoin: json['strokeJoin'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      style: json['style'] as int,
    );
  }
}
