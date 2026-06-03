import "dart:convert";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:uuid/uuid.dart";

extension ListExtensions<T> on List<T> {
  List<T> copy() {
    return List<T>.from(this);
  }
}

extension SetExtensions<T> on Set<T> {
  Set<T> copy() {
    return Set<T>.from(this);
  }
}

extension StringToIcon on String {
  bool isValidEmail() {
    // 檢查是否包含空格
    if (contains(' ') || contains('\t') || contains('\n') || isEmpty) {
      return false;
    }

    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this)) {
      return true;
    } else {
      return false;
    }
  }

  bool isImage() {
    return this == "jpg" ||
        this == "jpeg" ||
        this == "png" ||
        this == "gif" ||
        this == "bmp" ||
        this == "tiff" ||
        this == "webp" ||
        this == "heic";
  }

  bool isVideo() {
    return this == "mp4" || this == "avi" || this == "mkv" || this == "mov";
  }

  bool isAudio() {
    return this == "mp3";
  }

  bool isDocument() {
    return this == "pdf" ||
        this == "doc" ||
        this == "docx" ||
        this == "xls" ||
        this == "xlsx" ||
        this == "ppt" ||
        this == "pptx" ||
        this == "txt";
  }

  bool isArchive() {
    return this == "zip" || this == "rar" || this == "7z";
  }

  IconData toFileTypeIcon() {
    switch (this) {
      case "mp3":
        return Icons.music_note;
      case "pdf":
        return Icons.picture_as_pdf;
      case "doc":
        return Icons.description;
      case "docx":
        return Icons.description;
      case "xls":
        return Icons.table_chart;
      case "xlsx":
        return Icons.table_chart;
      case "ppt":
        return Icons.slideshow;
      case "pptx":
        return Icons.slideshow;
      case "txt":
        return Icons.text_fields;
      case "zip":
        return Icons.archive;
      case "rar":
        return Icons.archive;
      case "7z":
        return Icons.archive;
      case "jpg":
        return Icons.image;
      case "jpeg":
        return Icons.image;
      case "png":
        return Icons.image;
      case "gif":
        return Icons.image;
      case "bmp":
        return Icons.image;
      case "tiff":
        return Icons.image;
      case "webp":
        return Icons.image;
      case "heic":
        return Icons.image;
      case "mp4":
        return Icons.movie;
      case "avi":
        return Icons.movie;
      case "mkv":
        return Icons.movie;
      case "mov":
        return Icons.movie;
      default:
        return Icons.insert_drive_file;
    }
  }
}

extension EnumListExtension<T extends Enum> on Iterable<T> {
  /// 從字符串找到對應的枚舉值
  T findEnumFromString(dynamic value) {
    if (value == null) {
      return first;
    }
    return firstWhere(
      (e) => e.name.toLowerCase() == "$value".toLowerCase(),
      orElse: () => first,
    );
  }
}

extension EnumExtension<T extends Enum> on T {
  // returns empty string if value is null
  String enumToString() {
    return toString().split('.').last;
  }
}

extension DoubleFormat on double {
  String distanceFormat() {
    if (this < 1000) {
      return "{distance} m".tr(namedArgs: {"distance": toStringAsFixed(0)});
    } else {
      return "{distance} km".tr(
        namedArgs: {"distance": (this / 1000).toStringAsFixed(1)},
      );
    }
  }
}

extension NumberFormatExtension on num {
  /// 將數字格式化為千分位格式，固定用逗號（不受 locale 影響）。
  /// 例如: 1234567 -> 1,234,567
  /// （NumberFormat("#,###") 的 `,` 是 locale 的 grouping separator，
  /// 在 fr_FR 會變空格、de_DE 會變句點。指定 en_US locale 鎖定為逗號。）
  String toThousandsSeparator() {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(this);
  }
}

extension StringFormatCheck on String {
  bool isEmail() {
    // 檢查是否包含空格
    if (contains(' ') || contains('\t') || contains('\n') || isEmpty) {
      return false;
    }

    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this)) {
      return true;
    } else {
      return false;
    }
  }

  bool isURL() {
    return RegExp(
      r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    ).hasMatch(this);
  }

  String uuidToShortId() {
    if (isEmpty) {
      return this;
    }
    if (this == "null") {
      return this;
    }

    List<int> bytes = Uuid.parse(this);

    var shortId = base64Encode(
      bytes,
    ).substring(0, 22).replaceAll("/", "_").replaceAll("+", "-");
    return shortId;
  }

  String shortIdToUuidString() {
    try {
      final decodedBytes = base64Decode(this);
      return Uuid.unparse(decodedBytes);
    } catch (e) {
      debugPrint(e.toString());
      return '00000000-0000-0000-0000-000000000000';
    }
  }
}

extension Scroll on GlobalKey {
  /// 檢查 widget 是否已經在可視範圍內
  bool _isWidgetVisible(ScrollController scrollController) {
    final context = currentContext;
    if (context == null) return false;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return false;

    final revealedOffset = viewport.getOffsetToReveal(renderObject, 0.0);
    final viewportHeight = scrollController.position.viewportDimension;
    final currentOffset = scrollController.position.pixels;

    // 計算 widget 在 viewport 中的相對位置
    final widgetTop = revealedOffset.offset;
    final widgetBottom = widgetTop + renderObject.semanticBounds.height;

    // 檢查 widget 是否完全在可視範圍內
    final isVisible =
        widgetTop >= currentOffset &&
        widgetBottom <= currentOffset + viewportHeight;

    return isVisible;
  }

  /// 持續向下滾動直到找到這個 key 所屬的 widget
  /// [scrollController] - 必須提供的 ScrollController
  /// [maxScrollDuration] - 最大滾動持續時間（秒），預設 10 秒
  /// [scrollSpeed] - 滾動速度（像素/秒），預設 1200.0
  /// [checkInterval] - 檢查間隔（毫秒），預設 100
  Future<void> keepScrollToFind({
    required ScrollController scrollController,
    int maxScrollDuration = 10,
    double scrollSpeed = 4800.0,
    int checkInterval = 100,
  }) async {
    if (!scrollController.hasClients) {
      debugPrint("keepScrollToFind: ScrollController 沒有客戶端");
      return;
    }

    // 檢查 widget 是否已經在畫面上且可見
    if (_isWidgetVisible(scrollController)) {
      debugPrint("keepScrollToFind: Widget 已經在畫面上，不需要滾動");
      return;
    }

    final startTime = DateTime.now();
    final maxDuration = Duration(seconds: maxScrollDuration);

    // 計算每次檢查間隔應該滾動的距離
    final scrollDistancePerCheck = scrollSpeed * (checkInterval / 1000);
    // 提前檢查時間（毫秒），在滾動完成前提前檢查
    const earlyCheckTime = 200;

    while (DateTime.now().difference(startTime) < maxDuration) {
      // 檢查是否已經到底部
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent) {
        debugPrint('keepScrollToFind: 已滾動到底部，未找到 widget');
        return;
      }

      // 計算下一個滾動位置
      final currentPosition = scrollController.position.pixels;
      final nextPosition = (currentPosition + scrollDistancePerCheck).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );

      try {
        // 開始滾動動畫（非阻塞）
        final animationFuture = scrollController.animateTo(
          nextPosition,
          duration: Duration(milliseconds: checkInterval),
          curve: Curves.linear,
        );

        // 在滾動完成前 0.2 秒檢查是否找到目標 widget
        await Future.delayed(
          Duration(milliseconds: checkInterval - earlyCheckTime),
        );

        final context = currentContext;
        if (context != null) {
          // 找到目標，等待當前滾動完成
          await animationFuture;
          await Future.delayed(Duration(milliseconds: 200));
          scrollToNearTop();
          return;
        }

        // 等待剩餘的滾動時間完成
        await animationFuture;
      } catch (e) {
        debugPrint('keepScrollToFind error: $e');
        return;
      }
    }

    debugPrint('keepScrollToFind: 超時 $maxScrollDuration 秒，未找到 widget');
  }

  void scrollToNearTop() {
    final context = currentContext;
    if (context != null) {
      final renderObject = context.findRenderObject();
      if (renderObject != null && renderObject.attached) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (context.mounted) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.0,
              duration: const Duration(milliseconds: 300),
            );
          }
        });
      }
    }
  }
}

extension MapToJson on Map {
  String toJsonString() {
    return jsonEncode(this);
  }
}

extension GoogleMapControllerFunction on GoogleMapController {
  Future animateCameraTo(LatLng latLng, [double zoom = 15]) async {
    await animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: zoom),
      ),
    );
  }
}
