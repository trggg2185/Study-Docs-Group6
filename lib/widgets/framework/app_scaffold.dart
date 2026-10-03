import 'package:flutter/material.dart';

/// Scaffold tái sử dụng cho toàn bộ ứng dụng
/// Cung cấp layout thống nhất: AppBar + body + optional FAB
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: leading,
        actions: actions,
        bottom: bottom,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
