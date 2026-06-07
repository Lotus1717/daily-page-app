import 'package:flutter/material.dart';

import '../config/theme.dart';

class ReflectionInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;

  const ReflectionInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<ReflectionInput> createState() => _ReflectionInputState();
}

class _ReflectionInputState extends State<ReflectionInput> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final t = widget.controller.text.trim();
    if (t.isNotEmpty) widget.onSubmit(t);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.highlightLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: AppTheme.highlight.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 18, color: AppTheme.highlight),
              const SizedBox(width: 6),
              Text('写一句感想',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final t = value.trim();
              if (t.isNotEmpty) widget.onSubmit(t);
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: AppTheme.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: AppTheme.textDark),
          ),
          if (!keyboardOpen) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _SaveButton(onPressed: _submit),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.highlight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('记下来'),
    );
  }
}
