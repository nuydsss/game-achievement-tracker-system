import 'package:flutter/material.dart';

import '../../core/utils/app_exception.dart';
import '../../models/game.dart';
import '../../models/player_game.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../services/library_service.dart';
import '../../widgets/state_views.dart';

/// Browse the game catalog and add games to your library.
class BrowseGamesScreen extends StatefulWidget {
  const BrowseGamesScreen({super.key});

  @override
  State<BrowseGamesScreen> createState() => _BrowseGamesScreenState();
}

class _BrowseGamesScreenState extends State<BrowseGamesScreen> {
  late final Stream<List<Game>> _games = GameService.instance.watchGames();
  late final Stream<List<PlayerGame>> _library =
      LibraryService.instance.watchLibrary(AuthService.instance.uid);

  final _search = TextEditingController();
  final Set<String> _adding = {};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Game g) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return g.gameName.toLowerCase().contains(q) ||
        g.genre.toLowerCase().contains(q) ||
        g.developer.toLowerCase().contains(q) ||
        g.tags.any((t) => t.toLowerCase().contains(q));
  }

  Future<void> _add(Game game) async {
    setState(() => _adding.add(game.gameId));
    String message;
    try {
      await LibraryService.instance.addGame(uid: AuthService.instance.uid, gameId: game.gameId);
      message = '${game.gameName} added to your library.';
    } catch (e) {
      message = friendlyError(e);
    }
    if (!mounted) return;
    setState(() => _adding.remove(game.gameId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Games')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search name, genre, developer, tag',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Game>>(
              stream: _games,
              builder: (context, gamesSnap) {
                if (gamesSnap.hasError) return ErrorView(message: friendlyError(gamesSnap.error!));
                if (!gamesSnap.hasData) return const LoadingView();
                final games = gamesSnap.data!.where(_matches).toList();

                return StreamBuilder<List<PlayerGame>>(
                  stream: _library,
                  builder: (context, libSnap) {
                    if (libSnap.hasError) return ErrorView(message: friendlyError(libSnap.error!));
                    if (!libSnap.hasData) return const LoadingView();
                    final owned = {for (final e in libSnap.data!) e.gameId};

                    if (games.isEmpty) {
                      return const EmptyView(icon: Icons.search_off, message: 'No games found.');
                    }
                    return ListView(
                      children: [
                        for (final g in games)
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(g.gameName),
                              subtitle: Text(
                                '${g.genre}  -  ${g.developer}\n${g.totalAchievements} achievements',
                              ),
                              isThreeLine: true,
                              trailing: owned.contains(g.gameId)
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : _adding.contains(g.gameId)
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : FilledButton.tonal(
                                          onPressed: () => _add(g),
                                          child: const Text('Add'),
                                        ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
