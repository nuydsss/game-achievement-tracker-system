import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/player.dart';
import '../../models/player_game.dart';
import '../../services/auth_service.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/edit_name_dialog.dart';
import '../../widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final String _uid = AuthService.instance.uid;
  late final Stream<Player?> _player = PlayerService.instance.watchPlayer(_uid);
  late final Stream<List<PlayerGame>> _library = LibraryService.instance.watchLibrary(_uid);

  bool _uploading = false;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePhoto(Player player) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      final url = await StorageService.instance.uploadProfilePicture(
        uid: _uid,
        file: File(picked.path),
        previousUrl: player.photoUrl,
      );
      await PlayerService.instance.updatePhotoUrl(_uid, url);
      if (mounted) _toast('Profile picture updated.');
    } catch (e) {
      if (mounted) _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout), onPressed: _confirmSignOut),
        ],
      ),
      body: StreamBuilder<Player?>(
        stream: _player,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(message: friendlyError(snap.error!));
          final player = snap.data;
          if (player == null) return const LoadingView(); // still being created right after sign-up

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
                      child: player.photoUrl == null
                          ? Text(
                              player.displayName.isEmpty ? '?' : player.displayName[0].toUpperCase(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            )
                          : null,
                    ),
                    if (_uploading)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator()))
                    else
                      IconButton.filled(
                        tooltip: 'Change picture',
                        icon: const Icon(Icons.camera_alt, size: 18),
                        onPressed: () => _changePhoto(player),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(player.displayName, style: Theme.of(context).textTheme.headlineSmall),
              ),
              Center(child: Text('@${player.username}')),
              const SizedBox(height: 16),
              StreamBuilder<List<PlayerGame>>(
                stream: _library,
                builder: (context, libSnap) {
                  final entries = libSnap.data ?? const <PlayerGame>[];
                  final points = entries.fold<int>(0, (s, e) => s + e.totalPointsEarned);
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(child: Column(children: [
                            Text('${entries.length}', style: Theme.of(context).textTheme.titleLarge),
                            const Text('Games'),
                          ])),
                          Expanded(child: Column(children: [
                            Text('$points', style: Theme.of(context).textTheme.titleLarge),
                            const Text('Total points'),
                          ])),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Display name'),
                subtitle: Text(player.displayName),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => showDialog<bool>(
                  context: context,
                  builder: (_) => EditNameDialog(uid: _uid, currentName: player.displayName),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(player.email),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Member since'),
                subtitle: Text(formatDate(player.dateCreated)),
              ),
            ],
          );
        },
      ),
    );
  }
}
