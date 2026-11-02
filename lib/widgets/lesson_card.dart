import 'package:flutter/material.dart';
import '../models/models.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int index;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: lesson.isCompleted
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: lesson.isCompleted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: lesson.isCompleted
              ? Colors.green
              : Theme.of(context).colorScheme.primaryContainer,
          child: lesson.isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          lesson.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: lesson.isCompleted ? TextDecoration.none : null,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                lesson.duration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (lesson.isCompleted) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(
          lesson.isCompleted ? Icons.play_circle_outline : Icons.play_circle_fill,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        onTap: onTap,
      ),
    );
  }
}
