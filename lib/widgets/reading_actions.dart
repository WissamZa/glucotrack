// ReadingActions — popup menu for edit/delete on each reading row.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../providers/providers.dart';

class ReadingActions extends StatelessWidget {
  final Reading reading;
  final bool compact;
  const ReadingActions({super.key, required this.reading, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: compact ? 18 : 20, color: Colors.grey.shade600),
      tooltip: strings.tooltipMoreOptions,
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(strings.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(strings.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (v) async {
        if (v == 'edit') {
          await Navigator.pushNamed(context, '/add', arguments: reading);
          if (context.mounted) unawaited(context.read<ReadingsProvider>().load());
        } else if (v == 'delete') {
          final confirmed = await _confirmDelete(context, strings);
          if (confirmed != true) return;
          if (!context.mounted) return;
          await context.read<ReadingsProvider>().remove(reading.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.get('deleted_success'))),
          );
        }
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppStrings strings) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.get('delete_reading')),
        content: Text(strings.get('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
  }
}
