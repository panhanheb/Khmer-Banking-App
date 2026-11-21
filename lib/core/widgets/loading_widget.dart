import 'package:flutter/material.dart';

/// Animated shimmer applied to its skeleton children (no external package).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C2848) : const Color(0xFFE6EBF3);
    final highlight = isDark
        ? const Color(0xFF2A3A63)
        : const Color(0xFFF7F9FC);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: const [0.25, 0.5, 0.75],
            transform: _SlideGradient(t),
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

/// Grey placeholder block, meant to be wrapped in a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton loading states.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget._(this._builder, {super.key});

  /// A list of [count] transaction-like rows.
  factory LoadingWidget.list({Key? key, int count = 6}) => LoadingWidget._(
    (context) => Column(
      children: [for (var i = 0; i < count; i++) const _SkeletonRow()],
    ),
    key: key,
  );

  /// A dashboard skeleton (balance card + actions + rows).
  factory LoadingWidget.dashboard({Key? key}) => LoadingWidget._(
    (context) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 160, height: 18),
        SizedBox(height: 8),
        SkeletonBox(width: 220, height: 26),
        SizedBox(height: 20),
        SkeletonBox(height: 150, radius: 24),
        SizedBox(height: 24),
        SkeletonBox(height: 90, radius: 18),
        SizedBox(height: 24),
        _SkeletonRow(),
        _SkeletonRow(),
        _SkeletonRow(),
      ],
    ),
    key: key,
  );

  /// A single card-sized block.
  factory LoadingWidget.card({Key? key, double height = 160}) =>
      LoadingWidget._(
        (context) => SkeletonBox(height: height, radius: 20),
        key: key,
      );

  final WidgetBuilder _builder;

  @override
  Widget build(BuildContext context) => Shimmer(child: _builder(context));
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonBox(width: 44, height: 44, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 160),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 100),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 70, height: 16),
        ],
      ),
    );
  }
}
