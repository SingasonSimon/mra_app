import 'package:flutter/material.dart';

class PageEnterTransition extends StatefulWidget {
  const PageEnterTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.delay,
    this.beginOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Offset beginOffset;
  final Curve curve;
  final Curve reverseCurve;

  @override
  State<PageEnterTransition> createState() => _PageEnterTransitionState();
}

class _PageEnterTransitionState extends State<PageEnterTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay != null && widget.delay! > Duration.zero) {
      Future<void>.delayed(widget.delay!, _controller.forward);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

