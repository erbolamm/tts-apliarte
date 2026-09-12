import 'package:flutter/material.dart';

class SettingsTextField extends StatefulWidget {
  const SettingsTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final String value;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SettingsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      //style: TextStyle(color: Colors.black),
      controller: _controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class SettingsNumberField extends StatefulWidget {
  const SettingsNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final num value;
  final ValueChanged<num> onChanged;

  @override
  State<SettingsNumberField> createState() => _SettingsNumberFieldState();
}

class _SettingsNumberFieldState extends State<SettingsNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant SettingsNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintStyle: TextStyle(color: Colors.black),
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsed = num.tryParse(value);
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}
