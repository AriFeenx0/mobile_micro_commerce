import 'package:flutter/material.dart';

class VolumeSelector extends StatelessWidget {
  const VolumeSelector({
    super.key,
    required this.volumes,
    required this.selectedVolume,
    required this.onChanged,
  });

  final List<String> volumes;
  final String? selectedVolume;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedVolume,
      items: volumes
          .map((volume) => DropdownMenuItem(value: volume, child: Text(volume)))
          .toList(),
      onChanged: onChanged,
    );
  }
}