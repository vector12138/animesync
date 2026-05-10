
import 'package:flutter/material.dart';
import '../models/models.dart';

class AnimeCard extends StatelessWidget {
  final AnimeProgress anime;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIncrement;

  const AnimeCard({
    super.key,
    required this.anime,
    this.onEdit,
    this.onDelete,
    this.onIncrement,
  });

  static Color statusColor(String status) {
    switch (status) {
      case 'watching': return const Color(0xFF4CAF50);
      case 'completed': return const Color(0xFF2196F3);
      case 'plan_to_watch': return const Color(0xFFFFC107);
      case 'on_hold': return const Color(0xFFFF9800);
      case 'dropped': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = statusColor(anime.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: anime.coverUrl != null
                    ? Image.network(anime.coverUrl!, width: 56, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(theme, color))
                    : _placeholder(theme, color),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Progress bar
                    if (anime.totalEpisodes != null && anime.totalEpisodes! > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: anime.progress,
                          minHeight: 6,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${anime.watchedEpisodes}/${anime.totalEpisodes} 集',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ] else ...[
                      Text('${anime.watchedEpisodes} 集',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(AnimeProgress.statusLabel(anime.status),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              Column(
                children: [
                  if (anime.status == 'watching' && onIncrement != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50)),
                      onPressed: onIncrement,
                      tooltip: '+1',
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, Color color) {
    return Container(
      width: 56, height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.videocam, color: color),
    );
  }
}
