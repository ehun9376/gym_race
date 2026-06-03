import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gym_race/core/utility/design_color.dart";
import "package:gym_race/core/utility/design_font.dart";

/// OTP 輸入框 - 支持系統鍵盤驗證碼按鈕 + 手動輸入好體驗
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.onCode,
    this.codeCount = 6,
    this.hasError = false,
  });

  final Function(String code) onCode;
  final int codeCount;
  final bool hasError;

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  /// 從外部調用，自動 focus 到第一個驗證碼輸入框
  void focusFirstField() {
    _focusNodes[0].requestFocus();
  }

  /// 從外部調用，清空所有驗證碼輸入格
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.codeCount,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.codeCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    // 如果輸入超過 1 個字元（系統鍵盤自動填充），分配到各個框
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r"[^0-9]"), "");
      for (int i = 0; i < digits.length && index + i < widget.codeCount; i++) {
        _controllers[index + i].text = digits[i];
      }
      // 檢查是否全部填滿，如果是則隱藏鍵盤
      if (digits.length >= widget.codeCount) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // 手動刪除（backspace）→ focus 上一個
      _focusNodes[index - 1].requestFocus();
    } else if (value.isNotEmpty && index < widget.codeCount - 1) {
      // 單位數輸入 → focus 下一個
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == widget.codeCount - 1) {
      // 最後一個框填滿 → 隱藏鍵盤
      FocusManager.instance.primaryFocus?.unfocus();
    }

    final code = _controllers.map((c) => c.text).join();
    widget.onCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: AutofillGroup(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.codeCount, (i) => _buildBox(i)),
        ),
      ),
    );
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: 46,
      height: 50,
      child: TextField(
        cursorColor: DesignColor.textPrimary,
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        // 在所有框上都設定 autofillHints，讓系統識別這是驗證碼輸入組
        autofillHints: const [AutofillHints.oneTimeCode],
        style: TextStyle(
          fontSize: DesignFont.text1Regular.fontSize,
          fontWeight: DesignFont.text1Regular.fontWeight,
          fontFamily: DesignFont.text1Regular.fontFamily,
          color: DesignColor.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: DesignColor.neutral95,
          contentPadding: EdgeInsets.zero,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: widget.hasError ? Colors.red : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: widget.hasError ? Colors.red : DesignColor.textPrimary,
              width: 1.5,
            ),
          ),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) => _onChanged(index, value),
        onEditingComplete: () {
          TextInput.finishAutofillContext();
        },
      ),
    );
  }
}
