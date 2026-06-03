import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gym_race/core/image_name/image_name.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:gym_race/core/utility/widget_fixer.dart';
import 'package:video_player/video_player.dart';

class SimpleImage extends StatefulWidget {
  final Color? backgroudColor;
  final String? imageName;
  final String? mediaUrl; // 統一圖片/影片網址
  final File? mediaFile; // 統一本地圖片/影片
  final Size? imageSize;
  final double? cornerRadius;
  final double? borderWidth;
  final IconData? icon;
  final Color? color;
  final double? iconSize;
  final Color? borderColor;
  final BoxFit? fit;
  final bool? schedule;
  final Size? size;

  /// 網路圖片載入失敗時的備援 widget；若未提供則 fallback 到 placeholder 圖。
  final Widget? fallbackWidget;

  const SimpleImage({
    super.key,
    this.size,
    this.imageName,
    this.mediaUrl,
    this.mediaFile,
    this.imageSize,
    this.cornerRadius,
    this.icon,
    this.color,
    this.iconSize,
    this.backgroudColor,
    this.fit,
    this.borderColor,
    this.borderWidth,
    this.schedule = false,
    this.fallbackWidget,
  });

  @override
  State<SimpleImage> createState() => _SimpleImageState();
}

class _SimpleImageState extends State<SimpleImage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final isVideo = _isVideoSource();
    if (isVideo) {
      if (widget.mediaFile != null) {
        _videoController = VideoPlayerController.file(widget.mediaFile!);
        _safeInitVideo(_videoController!);
      } else if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
        try {
          final uri = Uri.parse(widget.mediaUrl!);
          _videoController = VideoPlayerController.networkUrl(uri);
          _safeInitVideo(_videoController!);
        } catch (e) {
          debugPrint("❌ SimpleImage Uri.parse 失敗: $e");
        }
      }
    }
  }

  /// 統一包住所有 VideoPlayerController 初始化錯誤 + 監聽運行時錯誤，
  /// 任何失敗都把狀態切回 placeholder，避免錯誤冒到 root zone 當機
  void _safeInitVideo(VideoPlayerController controller) {
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            _isVideoInitialized = true;
          });
        })
        .catchError((error, stack) {
          debugPrint("❌ SimpleImage 影片初始化失敗: $error");
          if (!mounted) return;
          setState(() {
            _isVideoInitialized = false;
          });
        });
    controller.addListener(() {
      if (!mounted) return;
      if (controller.value.hasError) {
        debugPrint(
          "❌ SimpleImage 影片播放錯誤: ${controller.value.errorDescription}",
        );
        if (_isVideoInitialized || _isPlaying) {
          setState(() {
            _isVideoInitialized = false;
            _isPlaying = false;
          });
        }
      }
    });
  }

  bool _isVideoSource() {
    // 如果有 mediaFile，判斷是否為影片
    if (widget.mediaFile != null) {
      if (kIsWeb) {
        // web 端 File 可能沒有 path，暫時返回 false（假設主要是圖片）
        return false;
      } else {
        // mobile 端使用 path 判斷
        final fileName = widget.mediaFile?.path ?? '';
        final lower = fileName.toLowerCase();
        return lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.webm');
      }
    }

    // 如果沒有 mediaFile，使用 mediaUrl 判斷
    final fileName = widget.mediaUrl ?? '';
    final lower = fileName.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm');
  }

  bool _isImageSource() {
    // 如果有 mediaFile，優先判斷是否為圖片
    if (widget.mediaFile != null) {
      if (kIsWeb) {
        // web 端 File 可能沒有 path，直接假設是圖片
        return true;
      } else {
        // mobile 端使用 path 判斷
        final fileName = widget.mediaFile?.path ?? '';
        final lower = fileName.toLowerCase();
        return lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.bmp') ||
            lower.endsWith('.webp');
      }
    }

    // 如果沒有 mediaFile，使用 mediaUrl 判斷
    final fileName = widget.mediaUrl ?? '';
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp') ||
        fileName.contains("https://picsum.photos");
  }

  // 檢查是否為 production 環境
  bool get _isProduction {
    return kReleaseMode;
  }

  // 針對 production 環境的特殊處理
  Future<Uint8List?> _tryProductionWebFileRead(dynamic file) async {
    try {
      debugPrint("Attempting production-specific file reading");

      // 在 production 環境中，某些 API 可能行為不同
      // 嘗試使用更保守的方法

      if (file != null) {
        // 首先嘗試最直接的方法
        try {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            debugPrint("Production file read success: ${bytes.length} bytes");
            return bytes;
          }
        } catch (e) {
          debugPrint("Production direct read failed: $e");
        }

        // 如果直接讀取失敗，嘗試檢查文件類型並使用替代方法
        final fileType = file.runtimeType.toString();
        debugPrint("Production environment file type: $fileType");

        // 對於 production 環境，可能需要不同的處理策略
        if (fileType.contains('File') || fileType.contains('Blob')) {
          // 嘗試使用更保守的讀取方式
          try {
            debugPrint("Attempting conservative read for production");
            // 在 production 中，直接使用 dynamic 調用可能更安全
            final dynamic readMethod = file.readAsBytes;
            if (readMethod != null) {
              final bytes = await readMethod();
              if (bytes != null && bytes.length > 0) {
                return bytes;
              }
            }
          } catch (e) {
            debugPrint("Conservative read failed: $e");
          }

          // 最後的嘗試：使用 FileReader (需要 JS interop)
          try {
            debugPrint("Attempting FileReader as last resort");
            // 注意：這需要額外的 JS interop 設置
            // 如果專案中有 js package，可以使用 FileReader API
            /*
            final reader = html.FileReader();
            reader.readAsArrayBuffer(file);
            await reader.onLoad.first;
            return reader.result as Uint8List;
            */
          } catch (e) {
            debugPrint("FileReader approach failed: $e");
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Production file read completely failed: $e");
      return null;
    }
  }

  @override
  void didUpdateWidget(SimpleImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 若 mediaFile 或 mediaUrl 改變，需重新初始化 controller
    if (widget.mediaFile != oldWidget.mediaFile ||
        widget.mediaUrl != oldWidget.mediaUrl) {
      _videoController?.dispose();
      _isVideoInitialized = false;
      _isPlaying = false;
      if (_isVideoSource()) {
        if (widget.mediaFile != null) {
          _videoController = VideoPlayerController.file(widget.mediaFile!);
          _safeInitVideo(_videoController!);
        } else if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
          try {
            final uri = Uri.parse(widget.mediaUrl!);
            _videoController = VideoPlayerController.networkUrl(uri);
            _safeInitVideo(_videoController!);
          } catch (e) {
            debugPrint("❌ SimpleImage Uri.parse 失敗: $e");
            _videoController = null;
          }
        } else {
          _videoController = null;
        }
      } else {
        _videoController = null;
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  /// 获取占位符图片 - 添加 errorBuilder 防止崩溃
  Widget _getPlaceholderImage() {
    final assetName = widget.imageName != null
        ? "asset/${widget.imageName}"
        : "asset/${ImageName.logo.path}";

    return Image.asset(
      assetName,
      height: widget.imageSize?.height,
      width: widget.imageSize?.width,
      fit: widget.fit ?? BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image.asset 載入失敗: $assetName');
        debugPrint('錯誤: $error');
        // 返回灰色占位符，不崩溃
        return Container(
          width: widget.imageSize?.width,
          height: widget.imageSize?.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
          ),
          child: Center(
            child: Icon(Icons.person, color: Colors.grey[600], size: 32),
          ),
        );
      },
    );
  }

  // 兼容 web/mobile File 顯示的方法
  Widget _buildFileImage() {
    if (kIsWeb) {
      // Web 端需要特殊處理
      return FutureBuilder<Uint8List>(
        future: _readWebFileAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            debugPrint(
              "Successfully loaded file image, data size: ${snapshot.data!.length}",
            );
            return Image.memory(
              snapshot.data!,
              width: widget.imageSize?.width,
              height: widget.imageSize?.height,
              fit: widget.fit ?? BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                debugPrint("Image.memory error: $error");
                return _getPlaceholderImage();
              },
            );
          } else if (snapshot.hasError) {
            debugPrint("Web file read error: ${snapshot.error}");
            debugPrint("Stack trace: ${snapshot.stackTrace}");
            return _getPlaceholderImage();
          } else {
            return const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ).center();
          }
        },
      );
    } else {
      // Mobile 端使用 Image.file
      return Image.file(
        widget.mediaFile!,
        width: widget.imageSize?.width,
        height: widget.imageSize?.height,
        fit: widget.fit ?? BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Image.file error: $error");
          return _getPlaceholderImage();
        },
      );
    }
  }

  // Web 端安全讀取檔案 bytes 的方法
  Future<Uint8List> _readWebFileAsBytes() async {
    try {
      final dynamic file = widget.mediaFile;

      debugPrint("=== _readWebFileAsBytes Debug Info ===");
      debugPrint("kIsWeb: $kIsWeb");
      debugPrint("file is null: ${file == null}");

      if (kIsWeb && file != null) {
        String fileType = file.runtimeType.toString();
        debugPrint("Web file type: $fileType");

        // 嘗試獲取文件的基本信息
        String fileUrl = '';
        try {
          if (file.toString().isNotEmpty) {
            final fileString = file.toString();
            debugPrint("File toString: $fileString");

            // 從toString()中提取blob URL
            if (fileString.contains('blob:')) {
              final blobStart = fileString.indexOf('blob:');
              debugPrint("Found blob at position: $blobStart");

              // 查找blob URL的結尾 - 可能是單引號或字符串結尾
              int blobEnd = fileString.indexOf("'", blobStart + 1);
              debugPrint("First quote after blob found at: $blobEnd");
              if (blobEnd == -1) {
                // 如果沒有找到單引號，嘗試找雙引號
                blobEnd = fileString.indexOf('"', blobStart + 1);
                debugPrint("Double quote after blob found at: $blobEnd");
              }
              if (blobEnd == -1) {
                // 如果沒有找到引號，取到字符串末尾
                blobEnd = fileString.length;
                debugPrint("No quote found, using string length: $blobEnd");
              }

              fileUrl = fileString.substring(blobStart, blobEnd);
              debugPrint("Raw extracted URL: '$fileUrl'");

              // 清理URL - 移除任何trailing的引號或空格
              fileUrl = fileUrl.trim();
              if (fileUrl.endsWith("'") || fileUrl.endsWith('"')) {
                fileUrl = fileUrl.substring(0, fileUrl.length - 1);
              }
              debugPrint("Cleaned extracted blob URL: '$fileUrl'");
            } else {
              debugPrint("No blob: found in file string");
            }
          } else {
            debugPrint("File toString is empty");
          }
        } catch (e) {
          debugPrint("Cannot get file string representation: $e");
        }

        debugPrint("Final fileUrl: '$fileUrl'");

        // 優先處理blob URL（無論文件類型如何）
        if (fileUrl.isNotEmpty && fileUrl.startsWith('blob:')) {
          debugPrint("Processing blob URL directly: $fileUrl");
          try {
            final response = await http.get(Uri.parse(fileUrl));
            debugPrint("Blob download response status: ${response.statusCode}");
            if (response.statusCode == 200) {
              debugPrint(
                "Blob download success, size: ${response.bodyBytes.length}",
              );
              return response.bodyBytes;
            } else {
              debugPrint(
                "Blob download failed with status: ${response.statusCode}",
              );
            }
          } catch (e) {
            debugPrint("Blob download error: $e");
          }
        }

        if (fileType.contains('XFile')) {
          // XFile 類型 - 通常來自 image_picker
          debugPrint("Processing XFile");
          try {
            final bytes = await file.readAsBytes();
            debugPrint("XFile readAsBytes success, size: ${bytes.length}");
            return bytes;
          } catch (e) {
            debugPrint("XFile readAsBytes failed: $e");
            rethrow;
          }
        } else if (fileType.contains('PickedFile')) {
          // PickedFile 類型 - 舊版 image_picker
          debugPrint("Processing PickedFile");
          try {
            final bytes = await file.readAsBytes();
            debugPrint("PickedFile readAsBytes success, size: ${bytes.length}");
            return bytes;
          } catch (e) {
            debugPrint("PickedFile readAsBytes failed: $e");
            rethrow;
          }
        } else if (fileType == '_File') {
          // 處理 dart:io File 在 web 端的情況
          debugPrint("Processing _File type");
          try {
            // 嘗試直接調用 readAsBytes - 在某些情況下可能有效
            final bytes = await file.readAsBytes();
            debugPrint(
              "_File direct readAsBytes success, size: ${bytes.length}",
            );
            return bytes;
          } catch (e) {
            debugPrint("Direct readAsBytes failed for _File: $e");

            // 作為後備，嘗試其他方法
            try {
              // 檢查是否有路徑信息
              final path = file.path;
              debugPrint("File path: $path");

              // 如果是 blob URL，使用 http package 下載
              if (path != null && path.startsWith('blob:')) {
                debugPrint("Attempting to download blob URL: $path");
                final response = await http.get(Uri.parse(path));
                debugPrint(
                  "Blob download response status: ${response.statusCode}",
                );
                if (response.statusCode == 200) {
                  debugPrint(
                    "Blob download success, size: ${response.bodyBytes.length}",
                  );
                  return response.bodyBytes;
                } else {
                  throw Exception(
                    'Failed to download blob: ${response.statusCode}',
                  );
                }
              } else if (path != null && path.startsWith('http')) {
                // 處理一般的 HTTP URL
                debugPrint("Attempting to download HTTP URL: $path");
                final response = await http.get(Uri.parse(path));
                debugPrint(
                  "HTTP download response status: ${response.statusCode}",
                );
                if (response.statusCode == 200) {
                  debugPrint(
                    "HTTP download success, size: ${response.bodyBytes.length}",
                  );
                  return response.bodyBytes;
                } else {
                  throw Exception(
                    'Failed to download HTTP URL: ${response.statusCode}',
                  );
                }
              }

              throw Exception(
                'Cannot read _File in web environment without valid URL path',
              );
            } catch (e2) {
              debugPrint("Fallback method failed: $e2");
              throw Exception(
                '_File type not supported in web environment. Use image_picker or provide bytes directly.',
              );
            }
          }
        } else {
          // 對於其他未知的檔案類型（包括production中的minified類型），嘗試通用方法
          debugPrint("Processing unknown file type: $fileType");

          // 如果我們已經提取到了blob URL，直接使用它
          if (fileUrl.isNotEmpty && fileUrl.startsWith('blob:')) {
            debugPrint(
              "Using already extracted blob URL for unknown type: $fileUrl",
            );
            try {
              final response = await http.get(Uri.parse(fileUrl));
              debugPrint(
                "Blob download response status: ${response.statusCode}",
              );
              if (response.statusCode == 200) {
                debugPrint(
                  "Blob download success, size: ${response.bodyBytes.length}",
                );
                return response.bodyBytes;
              } else {
                throw Exception(
                  'Failed to download blob: ${response.statusCode}',
                );
              }
            } catch (e) {
              debugPrint("Blob download failed: $e");
            }
          }

          try {
            final bytes = await file.readAsBytes();
            debugPrint("Generic readAsBytes success, size: ${bytes.length}");
            return bytes;
          } catch (e) {
            debugPrint("Generic readAsBytes failed for $fileType: $e");

            // 在 production 環境中嘗試特殊處理
            if (_isProduction) {
              debugPrint("Trying production-specific handling");
              final productionBytes = await _tryProductionWebFileRead(file);
              if (productionBytes != null) {
                return productionBytes;
              }
            }

            // 最後嘗試：檢查是否有其他可用的方法
            try {
              // 嘗試檢查文件是否有其他可用的屬性或方法
              debugPrint("Attempting alternative file reading methods");
              // 在生產環境中，可能需要使用不同的策略
            } catch (streamError) {
              debugPrint("Alternative reading failed: $streamError");
            }

            throw Exception(
              'Unsupported web file type: $fileType. Please use image_picker package for web file selection.',
            );
          }
        }
      }

      throw Exception('File is null or not in web environment');
    } catch (e) {
      debugPrint("=== _readWebFileAsBytes Error ===");
      debugPrint("Error reading web file: $e");
      debugPrint("Error type: ${e.runtimeType}");
      if (e is Error) {
        debugPrint("Stack trace: ${e.stackTrace}");
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideoSource() &&
        (widget.mediaFile != null ||
            (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty))) {
      final double width = widget.size?.width ?? widget.imageSize?.width ?? 120;
      final double height =
          widget.size?.height ?? widget.imageSize?.height ?? 120;
      return GestureDetector(
        onTap: _toggleVideo,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: widget.backgroudColor,
            borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
            border: Border.all(
              width: widget.borderWidth ?? 0.0,
              color: widget.borderColor ?? Colors.transparent,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
            child: _isVideoInitialized
                ? SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        if (!_isPlaying)
                          Icon(
                            Icons.play_circle_fill,
                            size: 48,
                            color: Colors.white.withAlpha(200),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ).center(),
          ),
        ),
      );
    }

    // 圖片顯示
    var widgetImage = Container(
      height: widget.size?.height,
      width: widget.size?.width,
      decoration: BoxDecoration(
        color: widget.backgroudColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
        border: Border.all(
          width: widget.borderWidth ?? 0.0,
          color: widget.borderColor ?? Colors.transparent,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
        child: widget.mediaFile != null && _isImageSource()
            ? _buildFileImage()
            : widget.icon != null
            ? Icon(widget.icon, size: widget.iconSize, color: widget.color)
            : (widget.mediaUrl == null
                  ? Image.asset(
                      'asset/${widget.imageName}',
                      height: widget.imageSize?.height,
                      width: widget.imageSize?.width,
                      fit: widget.fit ?? BoxFit.fill,
                      color: widget.color,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          '❌ Image.asset 載入失敗: asset/${widget.imageName}',
                        );
                        debugPrint('錯誤: $error');
                        return Container(
                          width: widget.imageSize?.width,
                          height: widget.imageSize?.height,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                              widget.cornerRadius ?? 0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[600],
                              size: 32,
                            ),
                          ),
                        );
                      },
                    )
                  : getImageFromNet(widget.mediaUrl)),
      ),
    );

    return widgetImage;
  }

  /// 分析網路錯誤並提供詳細診斷資訊
  void _analyzeNetworkError(String url, Object error) {
    // debugPrint("=== 網路錯誤分析 ===");
    // debugPrint("URL: $url");

    // final errorString = error.toString();
    // debugPrint("  - 錯誤訊息: $errorString");
  }

  Widget getImageFromNet(String? url) {
    if (url == null || url.isEmpty) {
      if (widget.fallbackWidget != null) return widget.fallbackWidget!;
      final assetName = widget.imageName != null
          ? "asset/${widget.imageName}"
          : "asset/placeholder-image.png";
      return Image.asset(
        assetName,
        height: widget.imageSize?.height,
        width: widget.imageSize?.width,
        fit: widget.fit ?? BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Image.asset 載入失敗: $assetName');
          return Container(
            width: widget.imageSize?.width,
            height: widget.imageSize?.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
            ),
            child: Center(
              child: Icon(Icons.person, color: Colors.grey[600], size: 32),
            ),
          );
        },
      );
    }

    // 驗證 URL 格式
    Uri? uri;
    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        // debugPrint("SimpleImage: Invalid URL scheme - $url");
        return widget.fallbackWidget ?? _getPlaceholderImage();
      }
    } catch (e) {
      // debugPrint("SimpleImage: URL parsing error - $url");
      // debugPrint("Parse error: $e");
      return widget.fallbackWidget ?? _getPlaceholderImage();
    }

    // SVG 走 flutter_svg 處理
    if (uri.path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        height: widget.imageSize?.height,
        width: widget.imageSize?.width,
        fit: widget.fit ?? BoxFit.contain,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.black),
        ).center(),
      );
    }

    // debugPrint("SimpleImage: Loading image from URL - $url");

    if (widget.schedule == true) {
      return CachedNetworkImage(
        imageUrl: url,
        height: widget.imageSize?.height,
        width: widget.imageSize?.width,
        fit: widget.fit ?? BoxFit.scaleDown,
        color: widget.color,
        // 加入重試機制
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        placeholder: (context, url) {
          // debugPrint("SimpleImage: Loading image from cache - $url");
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Colors.black),
          ).center();
        },
        errorWidget: (context, url, error) {
          // debugPrint("CachedNetworkImage error for URL: $url");
          // debugPrint("Error: $error");
          // debugPrint("Error type: ${error.runtimeType}");

          // 分析網路錯誤類型
          _analyzeNetworkError(url, error);

          if (widget.fallbackWidget != null) return widget.fallbackWidget!;

          final assetName = widget.imageName != null
              ? "asset/${widget.imageName}"
              : "asset/placeholder-image.png";
          return Image.asset(
            assetName,
            height: widget.imageSize?.height,
            width: widget.imageSize?.width,
            fit: widget.fit ?? BoxFit.scaleDown,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Image.asset 載入失敗 (Cache): $assetName');
              return Container(
                width: widget.imageSize?.width,
                height: widget.imageSize?.height,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(widget.cornerRadius ?? 0),
                ),
                child: Center(
                  child: Icon(Icons.person, color: Colors.grey[600], size: 32),
                ),
              );
            },
          );
        },
      );
    } else {
      return Image.network(
        url,
        height: widget.imageSize?.height,
        width: widget.imageSize?.width,
        fit: widget.fit ?? BoxFit.fill,
        color: widget.color,
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
              // debugPrint("Image.network error for URL: $url");
              // debugPrint("Exception: $exception");
              // debugPrint("Exception type: ${exception.runtimeType}");
              // if (stackTrace != null) {
              //   debugPrint("StackTrace: $stackTrace");
              // }

              // 分析網路錯誤類型
              _analyzeNetworkError(url, exception);

              if (widget.fallbackWidget != null) return widget.fallbackWidget!;

              final assetName = widget.imageName != null
                  ? "asset/${widget.imageName}"
                  : "asset/placeholder-image.png";
              return Image.asset(
                assetName,
                height: widget.imageSize?.height,
                width: widget.imageSize?.width,
                fit: widget.fit ?? BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Image.asset 載入失敗 (Network): $assetName');
                  return Container(
                    width: widget.imageSize?.width,
                    height: widget.imageSize?.height,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                        widget.cornerRadius ?? 0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    ),
                  );
                },
              );
            },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Colors.black),
          ).center();
        },
      );
    }
  }
}
