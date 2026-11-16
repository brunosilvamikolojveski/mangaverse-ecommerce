import 'package:material_ui/material_ui.dart';

import 'store_layout.dart';

class AdminHeading extends StatelessWidget {
  const AdminHeading(
    this.title, {
    super.key,
    required this.subtitle,
    this.action,
    this.eyebrow = 'PAINEL ADMINISTRATIVO',
  });
  final String title;
  final String subtitle;
  final String eyebrow;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: StoreColors.purple,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 7),
      PageHeading(title, subtitle: subtitle, action: action),
    ],
  );
}

class AdminTabs extends StatelessWidget {
  const AdminTabs({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.counts = const {},
  });
  final Map<String, String> labels;
  final Map<String, int> counts;
  final String value;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8E7ED)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Semantics(
                selected: entry.key == value,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: entry.key == value
                        ? StoreColors.purple
                        : Colors.transparent,
                    foregroundColor: entry.key == value
                        ? Colors.white
                        : StoreColors.muted,
                    minimumSize: const Size(40, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(entry.key),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.value),
                      if (counts.containsKey(entry.key)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: entry.key == value
                                ? Colors.white.withValues(alpha: .18)
                                : StoreColors.lavender,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${counts[entry.key]}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.icon = Icons.inventory_2_outlined,
  });
  final String title;
  final String message;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => StorePanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFFAE9DBB)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StoreColors.purple,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StoreColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge(this.active, {super.key});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE5F4E9) : const Color(0xFFF9E7E7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'Ativo' : 'Inativo',
      style: TextStyle(
        color: active ? const Color(0xFF175A35) : const Color(0xFF802E2E),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
