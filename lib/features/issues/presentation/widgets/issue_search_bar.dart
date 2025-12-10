import 'dart:async';

import 'package:flutter/material.dart';
import 'package:siren_app/core/theme/app_colors.dart';

class IssueSearchBar extends StatefulWidget {
  const IssueSearchBar({
    super.key,
    this.onSearchChanged,
    this.initialValue,
    this.hintText = 'Search issues...',
  });

  final ValueChanged<String>? onSearchChanged;
  final String? initialValue;
  final String hintText;

  @override
  State<IssueSearchBar> createState() => _IssueSearchBarState();
}

class _IssueSearchBarState extends State<IssueSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged?.call(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, child) {
          return TextField(
            controller: _controller,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(Icons.search, color: AppColors.iconSecondary),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.iconSecondary),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary),
          );
        },
      ),
    );
  }
}
