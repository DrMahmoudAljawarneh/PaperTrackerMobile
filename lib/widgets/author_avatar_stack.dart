import 'package:flutter/material.dart';
import 'package:paper_tracker/config/theme.dart';

class AuthorAvatarStack extends StatelessWidget {
  final List<String> authors;
  final String activeTurnAuthor;
  final double avatarSize;
  final int maxVisible;

  const AuthorAvatarStack({
    super.key,
    required this.authors,
    this.activeTurnAuthor = '',
    this.avatarSize = 32.0,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();

    final visibleAuthors = authors.take(maxVisible).toList();
    final overflowCount = authors.length - maxVisible;

    return SizedBox(
      height: avatarSize + 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visibleAuthors.asMap().entries.map((entry) {
            final idx = entry.key;
            final name = entry.value;
            final isActiveTurn = activeTurnAuthor.isNotEmpty &&
                name.toLowerCase().contains(activeTurnAuthor.toLowerCase());

            final initials = name.isNotEmpty
                ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                : '?';

            // Generate consistent avatar color based on name string
            final colorIndex = name.hashCode.abs() % _avatarColors.length;
            final bgColor = _avatarColors[colorIndex];

            return Align(
              widthFactor: idx == 0 ? 1.0 : 0.7,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: isActiveTurn ? AppTheme.accentColor : Theme.of(context).cardColor,
                    width: isActiveTurn ? 2.5 : 1.5,
                  ),
                  boxShadow: isActiveTurn
                      ? [
                          BoxShadow(
                            color: AppTheme.accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: avatarSize * 0.38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (overflowCount > 0) ...[
            Align(
              widthFactor: 0.7,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$overflowCount',
                    style: TextStyle(
                      fontSize: avatarSize * 0.35,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const List<Color> _avatarColors = [
  Color(0xFF6C63FF),
  Color(0xFF00D9FF),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
];
