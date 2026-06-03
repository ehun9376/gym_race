import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/simple_image.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

class SimpleHorizontalScrollList extends StatefulWidget {
  const SimpleHorizontalScrollList({
    super.key,
    required this.list,
    required this.onTap,
    required this.initText,
    this.scrollTargetToCenter = true,
  });

  final List<String> list;
  final String initText;
  final Function(String) onTap;
  final bool scrollTargetToCenter;

  @override
  SimpleHorizontalScrollListState createState() =>
      SimpleHorizontalScrollListState();
}

class SimpleHorizontalScrollListState
    extends State<SimpleHorizontalScrollList> {
  final screenWidthMaxItemsCount = 4;
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  double itemWidth = 0;
  double totalWidth = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedIndex = widget.list.indexOf(widget.initText);
      _scrollToInitialPosition();
    });
  }

  @override
  void didChangeDependencies() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newIndex = widget.list.indexOf(widget.initText);
      if (newIndex != selectedIndex && mounted) {
        setState(() {
          selectedIndex = newIndex;
        });
        _scrollToInitialPosition();
      }
    });
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant SimpleHorizontalScrollList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // initText 改變，或 list 有異動（例如資料載入後從空變有）
    final listChanged = !listEquals(oldWidget.list, widget.list);
    if (oldWidget.initText != widget.initText || listChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newIndex = widget.list.indexOf(widget.initText);
        if (newIndex >= 0 && newIndex != selectedIndex && mounted) {
          setState(() {
            selectedIndex = newIndex;
          });
          _scrollToInitialPosition();
        }
      });
    }
  }

  void _scrollToInitialPosition() async {
    if (selectedIndex >= 0 && selectedIndex < widget.list.length) {
      if (widget.scrollTargetToCenter && _scrollController.hasClients) {
        final targetOffset = selectedIndex * itemWidth - itemWidth / 2;
        // 檢查是否需要滾動（目標位置與當前位置差異超過閾值）
        if ((_scrollController.offset - targetOffset).abs() > 10) {
          await _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    itemWidth = MediaQuery.of(context).size.width / screenWidthMaxItemsCount;
    totalWidth = itemWidth * widget.list.length;

    return Stack(
      children: [
        SizedBox(
          height: 43,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.1, 0.9, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.list.length,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Container(
                  constraints: BoxConstraints(minWidth: itemWidth),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SimpleText(
                        text: widget.list[index],
                        fontSize: 16,
                        textColor: isSelected ? Colors.black : Colors.grey,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: itemWidth / 2,
                        height: 3,
                        color: isSelected ? Colors.black : Colors.transparent,
                      ),
                    ],
                  ),
                ).inkWell(
                  onTap: () async {
                    setState(() {
                      selectedIndex = index;
                    });
                    await _scrollController.animateTo(
                      index * itemWidth - itemWidth / 2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    widget.onTap(widget.list[index]);
                  },
                );
              },
            ),
          ),
        ),
        webLeftArrowButton().position(left: -10, bottom: -4),
        webRightArrowButton().position(right: -10, bottom: -4),
      ],
    );
  }

  Widget webLeftArrowButton() {
    if (!kIsWeb) {
      return Container();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final shouldShowArrows = totalWidth > screenWidth;

    if (!shouldShowArrows) {
      return Container();
    }

    return SimpleImage(icon: Icons.arrow_left, iconSize: 60).inkWell(
      onTap: () {
        _scrollController.animateTo(
          _scrollController.offset - itemWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget webRightArrowButton() {
    if (!kIsWeb) {
      return Container();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final shouldShowArrows = totalWidth > screenWidth;

    if (!shouldShowArrows) {
      return Container();
    }

    return SimpleImage(icon: Icons.arrow_right, iconSize: 60).inkWell(
      onTap: () {
        _scrollController.animateTo(
          _scrollController.offset + itemWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
