import 'package:flutter/material.dart';

class AcademicShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AcademicShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Colors.black12),
          const SizedBox(height: 16),
          const AcademicShimmer(width: 180, height: 24, borderRadius: 4),
          const SizedBox(height: 8),
          const AcademicShimmer(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(
              6,
              (_) => const AcademicShimmer(height: 100, borderRadius: 16),
            ),
          ),
          const SizedBox(height: 24),
          const AcademicShimmer(height: 100, borderRadius: 12),
          const SizedBox(height: 12),
          const AcademicShimmer(height: 100, borderRadius: 12),
          const SizedBox(height: 12),
          const AcademicShimmer(height: 100, borderRadius: 12),
        ],
      ),
    );
  }
}
