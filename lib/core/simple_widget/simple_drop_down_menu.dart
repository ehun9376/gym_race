import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/animated_popup_reveal.dart";
import "package:gym_race/core/simple_widget/simple_image.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/utility/design_color.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

abstract class MenuItemModel {
  late String displayName;
  String? imageName;
  dynamic value;
}

class MenuItem implements MenuItemModel {
  @override
  late String displayName;
  @override
  String? imageName;

  @override
  dynamic value;
  MenuItem({required this.displayName, this.imageName, this.value});
}

/// 自製 dropdown：用 LayerLink + Overlay 控制 popup 寬度與位置。
/// 與 Flutter 內建 [DropdownButton] 相比，popup 寬度保證等於按鈕寬度，
/// 不會在某些 layout 下變成滿螢幕。
class SimpleDropdownMenu<T extends MenuItemModel> extends StatefulWidget {
  const SimpleDropdownMenu({
    super.key,
    required this.onChange,
    required this.options,
    this.notChangeWhenTap,
    this.defaultValue,
    this.onTap,
    this.fontSize,
    this.guideFontStyle,
    this.hint,
    required this.height,
    this.width,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor = Colors.white,
    this.textColor,
    this.hintColor,
    this.alignment = AlignmentDirectional.centerStart,
    this.icon,
    this.iconSize = 24.0,
    this.iconColor,
    this.selectedDisplayOverride,
    this.borderWidth,
    this.dropDownColor,
    this.readOnly = false,
    this.padding,
  });

  @override
  SimpleDropdownMenuState<T> createState() => SimpleDropdownMenuState<T>();

  final Function(T) onChange;
  final Function()? onTap;
  final List<T> options;
  final T? defaultValue;
  final double? fontSize;
  final GuideFontStyle? guideFontStyle;
  final bool? notChangeWhenTap;
  final String? hint;

  final double height;
  final double? width;
  final double? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final AlignmentDirectional alignment;
  final Widget? icon;
  final double iconSize;
  final Color? iconColor;
  final String Function(T)? selectedDisplayOverride;
  final double? borderWidth;
  final Color? dropDownColor;
  final bool readOnly;
  final EdgeInsetsGeometry? padding;
}

class SimpleDropdownMenuState<T extends MenuItemModel>
    extends State<SimpleDropdownMenu<T>> {
  T? _selectedItem;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlay;

  bool get _isOpen => _overlay != null;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.defaultValue;
  }

  @override
  void didUpdateWidget(covariant SimpleDropdownMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) {
      if (!widget.options.contains(_selectedItem)) {
        setState(() {
          _selectedItem = widget.defaultValue;
        });
      }
    }
    if (widget.defaultValue != oldWidget.defaultValue) {
      setState(() {
        _selectedItem = widget.defaultValue;
      });
    }
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle() {
    if (widget.readOnly) return;
    widget.onTap?.call();
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size(0, widget.height);
    _overlay = OverlayEntry(
      builder: (_) => _DropdownPopup<T>(
        layerLink: _layerLink,
        width: size.width,
        topOffset: size.height + 4,
        options: widget.options,
        selected: _selectedItem,
        backgroundColor: widget.dropDownColor ?? Colors.white,
        borderRadius: widget.borderRadius ?? 15,
        fontSize: widget.fontSize,
        guideFontStyle: widget.guideFontStyle,
        onSelected: _handleSelected,
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  void _handleSelected(T item) {
    if (!(widget.notChangeWhenTap ?? false)) {
      setState(() {
        _selectedItem = item;
      });
    }
    widget.onChange(item);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;
    final displayText = selected == null
        ? (widget.hint ?? "").tr()
        : (widget.selectedDisplayOverride != null
              ? widget.selectedDisplayOverride!(selected)
              : selected.displayName);
    final isHint = selected == null;

    final defaultIcon = Icon(
      Icons.arrow_drop_down,
      size: widget.iconSize,
      color: widget.iconColor ?? DesignColor.textPrimary,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
        return CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            height: widget.height,
            width: resolvedWidth,
            child: Container(
              key: _buttonKey,
              padding: widget.padding ?? const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 15),
                border: Border.all(
                  color: widget.borderColor ?? Colors.transparent,
                  width: widget.borderWidth ?? 1.0,
                ),
              ),
              child: Row(
                children: [
                  Align(
                    alignment: widget.alignment,
                    child: Text(
                      displayText,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize:
                            widget.guideFontStyle?.fontSize ?? widget.fontSize,
                        fontWeight: widget.guideFontStyle?.fontWeight,
                        fontFamily: widget.guideFontStyle?.fontFamily,
                        color: isHint ? widget.hintColor : widget.textColor,
                      ),
                    ),
                  ).flexible(),
                  if (!widget.readOnly) widget.icon ?? defaultIcon,
                ],
              ),
            ).inkWell(onTap: _toggle),
          ),
        );
      },
    );
  }
}

class _DropdownPopup<T extends MenuItemModel> extends StatelessWidget {
  final LayerLink layerLink;
  final double width;
  final double topOffset;
  final List<T> options;
  final T? selected;
  final Color backgroundColor;
  final double borderRadius;
  final double? fontSize;
  final GuideFontStyle? guideFontStyle;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  const _DropdownPopup({
    required this.layerLink,
    required this.width,
    required this.topOffset,
    required this.options,
    required this.selected,
    required this.backgroundColor,
    required this.borderRadius,
    required this.fontSize,
    required this.guideFontStyle,
    required this.onSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.35;
    return Stack(
      children: [
        // 點空白處關閉；translucent 讓滑動（scroll）穿透到下層 ScrollView，
        // 只接 tap 觸發 dismiss。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, topOffset),
            child: AnimatedPopupReveal(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(150),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final item = options[i];
                      return Row(
                            children: [
                              if (item.imageName != null)
                                SimpleImage(
                                  imageName: item.imageName,
                                  mediaUrl: item.imageName,
                                  size: const Size(30, 30),
                                  cornerRadius: 5,
                                  fit: BoxFit.contain,
                                ).padding(const EdgeInsets.only(left: 10)),
                              SimpleText(
                                text: item.displayName,
                                fontSize: fontSize,
                                guideFontStyle: guideFontStyle,
                                overflow: TextOverflow.ellipsis,
                              ).flexible(),
                            ],
                          )
                          .padding(
                            const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                          )
                          .inkWell(onTap: () => onSelected(item));
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
