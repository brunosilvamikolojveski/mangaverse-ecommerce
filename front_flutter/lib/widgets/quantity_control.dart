import 'package:material_ui/material_ui.dart';

import 'store_layout.dart';

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.value,
    required this.label,
    this.onDecrease,
    this.onIncrease,
  });

  final int value;
  final String label;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: StoreColors.line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Diminuir quantidade de $label',
          onPressed: onDecrease,
          icon: const Icon(Icons.remove, size: 18),
        ),
        Semantics(
          liveRegion: true,
          label: 'Quantidade',
          child: SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Aumentar quantidade de $label',
          onPressed: onIncrease,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}
