import "dart:isolate";
import "dart:typed_data";
import "package:image/image.dart" as img;

class ImageCompressionUtil {
  // 壓縮圖片到指定大小 (默認 2MB)
  // 在獨立 Isolate 中執行，避免阻塞 UI 線程
  static Future<List<int>> compressImage(
    List<int> imageBytes, {
    int maxSizeInMB = 2,
  }) async {
    return Isolate.run(
      () => _compressSync(imageBytes, maxSizeInMB),
    );
  }

  static List<int> _compressSync(List<int> imageBytes, int maxSizeInMB) {
    int maxSize = maxSizeInMB * 1024 * 1024;

    if (imageBytes.length <= maxSize) {
      return imageBytes;
    }

    // 解碼圖片
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) {
      return imageBytes;
    }

    // 逐步降低質量直到符合大小要求
    int quality = 95;
    while (quality > 10) {
      final compressed = img.encodeJpg(image, quality: quality);
      if (compressed.length <= maxSize) {
        return compressed;
      }
      quality -= 5;
    }

    // 如果還是太大，縮小圖片尺寸
    int width = image.width;
    int height = image.height;

    while (width > 100 && height > 100) {
      width = (width * 0.8).toInt();
      height = (height * 0.8).toInt();
      final resized = img.copyResize(image, width: width, height: height);
      final compressed = img.encodeJpg(resized, quality: 90);
      if (compressed.length <= maxSize) {
        return compressed;
      }
    }

    return img.encodeJpg(image, quality: 50);
  }
}
