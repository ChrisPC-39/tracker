import 'package:flutter/material.dart';

class AnimatedGradient extends StatefulWidget {
  final List<Color> gradientTheme;

  const AnimatedGradient({super.key, required this.gradientTheme});

  @override
  State<AnimatedGradient> createState() =>
      _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      reverseDuration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      ),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.gradientTheme[0], widget.gradientTheme[1], _animation.value)!,
                Color.lerp(widget.gradientTheme[1], widget.gradientTheme[2], _animation.value)!,
                Color.lerp(widget.gradientTheme[2], widget.gradientTheme[3], _animation.value)!,
              ],
            ),
            // borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}
