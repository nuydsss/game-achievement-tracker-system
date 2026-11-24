import 'package:flutter/material.dart';

import '../../core/utils/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/game.dart';
import '../../models/player_game.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../services/library_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import 'game_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final Stream<List<Game>> _games = GameService.instance.watchGames();
  late final Stream<List<PlayerGame>> _library =
      LibraryService.instance.watchLibrary(AuthService.instance.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: StreamBuilder<List<Game>>(
        stream: _games,
        builder: (context, gamesSnap) {
          if (gamesSnap.hasError) return ErrorView(message: friendlyError(gamesSnap.error!));
          if (!gamesSnap.hasData) return const LoadingView();
          final catalog = {for (final g in gamesSnap.data!) g.gameId: g};

          return StreamBuilder<List<PlayerGame>>(
            stream: _library,
            builder: (context, libSnap) {
              if (libSnap.hasError) return ErrorView(message: friendlyError(libSnap.error!));
              if (!libSnap.hasData) return const LoadingView();
              final entries = libSnap.data!;
              if (entries.isEmpty) {
                return const EmptyView(
                  icon: Icons.videogame_asset_outlined,
                  message: 'Your library is empty.\nGo to Browse to add your first game.',
                );
              }

              final points = entries.fold<int>(0, (s, e) => s + e.totalPointsEarned);
              final hours = entries.fold<double>(0, (s, e) => s + e.playtimeHours);

              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _Summary(games: entries.length, points: points, hours: hours),
                  for (final e in entries)
                    _EntryCard(entry: e, game: catalog[e.gameId]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.games, required this.points, required this.hours});
  final int games;
  final int points;
  final double hours;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          stat('Games', '$games'),
          stat('Points', '$points'),
          stat('Playtime', formatHours(hours)),
        ]),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.game});
  final PlayerGame entry;
  final Game? game;

  @override
  Widget build(BuildContext context) {
    final g = game;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(g?.gameName ?? 'Unknown game'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: entry.status),
              Text(formatHours(entry.playtimeHours)),
              Text('${entry.totalPointsEarned} pts'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: g == null
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GameDetailScreen(game: g, playerGameId: entry.playerGameId),
                )),
      ),
    );
  }
}
