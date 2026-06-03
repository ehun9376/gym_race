enum ToastConfigStyle { message, error, success }

/// SnackBar 配置
class ToastConfig {
  final String message;
  final ToastConfigStyle style;

  ToastConfig({required this.message, this.style = ToastConfigStyle.message});
}
