import 'package:flutter/material.dart';

import '../../core/utils/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/achievement.dart';
import '../../models/game.dart';
import '../../models/player_achievement.dart';
import '../../models/player_game.dart';
import '../../services/achievement_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../services/library_service.dart';
import '../../widgets/achievement_tile.dart';
import '../../widgets/edit_entry_dialog.dart';
import '../../widgets/progress_dialog.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.game, required this.playerGameId});
  final Game game;
  final String playerGameId;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late final Stream<PlayerGame?> _entry =
      LibraryService.instance.watchEntry(widget.playerGameId);
  late final Stream<List<Achievement>> _achievements =
      GameService.instance.watchAchievements(widget.game.gameId);
  late final Stream<Map<String, PlayerAchievement>> _progress =
      AchievementService.instance.watchProgress(
    uid: AuthService.instance.uid,
    playerGameId: widget.playerGameId,
  );

  bool _removing = false;

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from library?'),
        content: Text(
            'This deletes your progress for ${widget.game.gameName}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _removing = true);
    try {
      await LibraryService.instance.removeEntry(
        uid: AuthService.instance.uid,
        playerGameId: widget.playerGameId,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerGame?>(
      stream: _entry,
      builder: (context, entrySnap) {
        final entry = entrySnap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.game.gameName),
            actions: [
              if (entry != null && !_removing) ...[
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => EditEntryDialog(entry: entry),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from library',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _remove,
                ),
              ],
            ],
          ),
          body: _body(entrySnap, entry),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<PlayerGame?> entrySnap, PlayerGame? entry) {
    if (entrySnap.hasError) return ErrorView(message: friendlyError(entrySnap.error!));
    if (_removing || entrySnap.connectionState == ConnectionState.waiting) {
      return const LoadingView();
    }
    if (entry == null) {
      return const EmptyView(icon: Icons.info_outline, message: 'This game is no longer in your library.');
    }

    return StreamBuilder<List<Achievement>>(
      stream: _achievements,
      builder: (context, achSnap) {
        if (achSnap.hasError) return ErrorView(message: friendlyError(achSnap.error!));
        if (!achSnap.hasData) return const LoadingView();
        final achievements = achSnap.data!;

        return StreamBuilder<Map<String, PlayerAchievement>>(
          stream: _progress,
          builder: (context, progSnap) {
            if (progSnap.hasError) return ErrorView(message: friendlyError(progSnap.error!));
            if (!progSnap.hasData) return const LoadingView();
            final progress = progSnap.data!;
            final unlocked = achievements
                .where((a) => progress[a.achievementId]?.isUnlocked ?? false)
                .length;

            return ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.game.genre}  -  ${widget.game.developer}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(status: entry.status),
                            Text(formatHours(entry.playtimeHours)),
                            Text('${entry.totalPointsEarned} pts'),
                            Text('$unlocked / ${achievements.length} unlocked'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (achievements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyView(icon: Icons.emoji_events_outlined, message: 'No achievements for this game yet.'),
                  ),
                for (final a in achievements)
                  AchievementTile(
                    achievement: a,
                    progress: progress[a.achievementId],
                    onTap: () => showDialog<bool>(
                      context: context,
                      builder: (_) => ProgressDialog(
                        playerGameId: widget.playerGameId,
                        achievement: a,
                        currentPercent: progress[a.achievementId]?.progressPercent ?? 0,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
