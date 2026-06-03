import "package:flutter/material.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

class SimplePageView extends StatefulWidget {
  const SimplePageView({
    super.key,
    required this.pageController,
    required this.pages,
    required this.scrollController,
    this.horizentalScroll = false,
    required this.onPageChange,
    this.onPageArriedLast,
  });

  final PageController pageController;
  final List<Widget> pages;
  final ScrollController scrollController;
  final bool horizentalScroll;
  final Function(int) onPageChange;

  final Function(int)? onPageArriedLast;

  @override
  State<SimplePageView> createState() => SimpledPageViewState();
}

class SimpledPageViewState extends State<SimplePageView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      physics: widget.horizentalScroll ? null : NeverScrollableScrollPhysics(),
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        return widget.horizentalScroll
            ? widget.pages[index]
            : CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  widget.pages[index]
                      .padding(EdgeInsets.all(16.0))
                      .sliverToBoxAdapter(),
                ],
              );
      },
      onPageChanged: (index) {
        widget.onPageChange(index);
        if (index == widget.pages.length - 1) {
          widget.onPageArriedLast?.call(index);
        }
      },
    ).inkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
    );
  }
}
