import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/player_achievement.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.progress,
    required this.onTap,
  });

  final Achievement achievement;
  final PlayerAchievement? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = progress?.progressPercent ?? 0;
    final unlocked = progress?.isUnlocked ?? false;
    final masked = achievement.isHidden && !unlocked;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          unlocked ? Icons.emoji_events : (masked ? Icons.lock : Icons.emoji_events_outlined),
          color: unlocked ? Colors.amber : scheme.outline,
          size: 32,
        ),
        title: Text(masked ? 'Hidden achievement' : achievement.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!masked) Text(achievement.description),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: percent / 100),
            const SizedBox(height: 4),
            Text('$percent%  -  ${achievement.difficulty}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Text('${achievement.points} pts',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        isThreeLine: true,
      ),
    );
  }
}
