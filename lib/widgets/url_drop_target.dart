import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../core/theme.dart';

class UrlDropTarget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onFetch;

  const UrlDropTarget({
    super.key,
    required this.controller,
    required this.onFetch,
  });

  @override
  State<UrlDropTarget> createState() => _UrlDropTargetState();
}

class _UrlDropTargetState extends State<UrlDropTarget> {
  bool _isDragging = false;

  void _handleDrop(String url) {
    widget.controller.text = url;
    widget.onFetch();
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        for (final file in details.files) {
          final path = file.path;
          if (path.contains('spotify.com') ||
              path.contains('youtube.com') ||
              path.contains('youtu.be')) {
            _handleDrop(path);
            return;
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDragging ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (_isDragging)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Icon(Icons.link, color: AppTheme.primary, size: 32),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: _isDragging
                          ? 'Drop URL here...'
                          : 'Paste Spotify or YouTube URL',
                      prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
                    ),
                    onSubmitted: (_) => widget.onFetch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onFetch,
                  icon: const Icon(Icons.search),
                  label: const Text('Fetch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
