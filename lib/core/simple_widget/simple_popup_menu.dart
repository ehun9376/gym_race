import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/animated_popup_reveal.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

enum PopMenuAction { edit, delete, report, block, share, camera, gallery }

extension PopMenuActionExtension on PopMenuAction {
  String get actionString {
    switch (this) {
      case PopMenuAction.edit:
        return "Edit";
      case PopMenuAction.delete:
        return "Delete";
      case PopMenuAction.report:
        return "Report";
      case PopMenuAction.block:
        return "Block";
      case PopMenuAction.share:
        return "Share";
      case PopMenuAction.camera:
        return "Camera";
      case PopMenuAction.gallery:
        return "Gallery";
    }
  }
}

class SimplePopupMenu extends StatefulWidget {
  final List<PopMenuAction> actions;
  final Function(PopMenuAction) onSelected;
  final Widget? button;

  const SimplePopupMenu({
    super.key,
    this.button,
    required this.actions,
    required this.onSelected,
  });

  @override
  State<SimplePopupMenu> createState() => _SimplePopupMenuState();
}

class _SimplePopupMenuState extends State<SimplePopupMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _toggleMenu() {
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _removeMenu();
    }
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // 計算最長文字寬度
    double maxWidth = 0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.of(context).textScaler,
    );

    for (var action in widget.actions) {
      textPainter.text = TextSpan(
        text: action.actionString,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      if (textPainter.width > maxWidth) {
        maxWidth = textPainter.width;
      }
    }

    // 加上左右padding的寬度(16 * 2 = 32)
    maxWidth += 32;

    //判斷renderBox的位置
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final isOnLeft = offset.dx < screenSize.width / 2;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 👇 背景透明區塊，點擊會移除 menu
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeMenu,
              onVerticalDragUpdate: (details) {
                _removeMenu();
              },
              onHorizontalDragUpdate: (details) {
                _removeMenu();
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.black.withAlpha(50)),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(isOnLeft ? 0 : -maxWidth / 2, size.height),
            showWhenUnlinked: false,
            child: AnimatedPopupReveal(
              alignment: isOnLeft ? Alignment.topLeft : Alignment.topRight,
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.actions.map((e) {
                    return SimpleText(
                          text: e.actionString,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        )
                        .padding(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        )
                        .inkWell(
                          onTap: () {
                            _removeMenu();
                            widget.onSelected(e);
                          },
                        );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child:
            widget.button ??
            Icon(Icons.more_horiz, size: 24, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }
}
