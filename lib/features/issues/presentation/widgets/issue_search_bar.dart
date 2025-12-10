import 'dart:async';

import 'package:flutter/material.dart';
import 'package:siren_app/core/theme/app_colors.dart';

/// Material 3 SearchBar widget for searching issues.
///
/// This widget provides a modern, elegant search interface with:
/// - Material 3 design principles
/// - Debounced search input
/// - Smooth animations
/// - Integrated clear button
/// - Custom styling that matches the app theme
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
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextControllerChange);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextControllerChange() {
    setState(() {
      // Trigger rebuild to update trailing icon visibility
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onTextChanged,
        hintText: widget.hintText,
        hintStyle: WidgetStateProperty.all(
          TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        leading: Icon(
          Icons.search,
          color: _isFocused ? AppColors.primaryPurple : AppColors.iconSecondary,
        ),
        trailing: _controller.text.isNotEmpty
            ? [
                IconButton(
                  icon: Icon(Icons.clear, color: AppColors.iconSecondary),
                  onPressed: _clearSearch,
                  tooltip: 'Clear search',
                ),
              ]
            : null,
        elevation: WidgetStateProperty.resolveWith<double>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return 3.0;
          }
          return 1.0;
        }),
        shadowColor: WidgetStateProperty.all(
          AppColors.primaryPurple.withValues(alpha: 0.2),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return isDark
                ? AppColors.surface.withValues(alpha: 0.9)
                : AppColors.surface;
          }
          return isDark
              ? AppColors.surface.withValues(alpha: 0.7)
              : AppColors.surface;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: _isFocused
                  ? AppColors.primaryPurple.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.5),
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primaryPurple.withValues(alpha: 0.08);
          }
          return null;
        }),
      ),
    );
  }
}
