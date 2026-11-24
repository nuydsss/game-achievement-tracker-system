import 'package:flutter/material.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/app_exception.dart';
import '../core/utils/formatters.dart';
import '../core/utils/validators.dart';
import '../models/player_game.dart';
import '../services/library_service.dart';

/// Edit a library entry's status and playtime. Pops `true` when saved.
class EditEntryDialog extends StatefulWidget {
  const EditEntryDialog({super.key, required this.entry});
  final PlayerGame entry;

  @override
  State<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends State<EditEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hours;
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = widget.entry.playtimeHours;
    _hours = TextEditingController(
        text: h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1));
    _status = widget.entry.status;
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await LibraryService.instance.updateEntry(
        widget.entry.playerGameId,
        status: _status,
        playtimeHours: double.parse(_hours.text.trim()),
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
    return AlertDialog(
      title: const Text('Edit game'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in GameStatus.all)
                  DropdownMenuItem(value: s, child: Text(GameStatus.label(s))),
              ],
              onChanged: _saving ? null : (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hours,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Playtime (hours)',
                helperText: 'Currently ${formatHours(widget.entry.playtimeHours)}',
              ),
              validator: Validators.playtimeHours,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
