import 'package:flutter/material.dart';

import '../core/utils/app_exception.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';

/// Set an achievement's progress (0-100). Pops `true` when saved.
class ProgressDialog extends StatefulWidget {
  const ProgressDialog({
    super.key,
    required this.playerGameId,
    required this.achievement,
    required this.currentPercent,
  });

  final String playerGameId;
  final Achievement achievement;
  final int currentPercent;

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  late double _value = widget.currentPercent.toDouble();
  bool _saving = false;
  String? _error;

  Future<void> _save(int percent) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AchievementService.instance.setProgress(
        uid: AuthService.instance.uid,
        playerGameId: widget.playerGameId,
        achievement: widget.achievement,
        percent: percent,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return AlertDialog(
      title: Text(a.isHidden && widget.currentPercent < 100 ? 'Hidden achievement' : a.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_value.round()}%', style: Theme.of(context).textTheme.headlineMedium),
          Slider(
            value: _value,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_value.round()}%',
            onChanged: _saving ? null : (v) => setState(() => _value = v),
          ),
          Text('Reaching 100% unlocks it and adds ${a.points} points.',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : () => _save(100),
          child: const Text('Mark complete'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(_value.round()),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
