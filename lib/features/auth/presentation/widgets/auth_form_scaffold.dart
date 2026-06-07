import 'package:flutter/material.dart';
import 'package:kaki_empat/features/auth/presentation/widgets/auth_brand_header.dart';

/// Kerangka form login/register dengan ilustrasi ramah dan pesan error jelas.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.formKey,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    required this.loading,
    this.error,
    this.footer,
    this.appBarActions = const [],
  });

  final String title;
  final String subtitle;
  final IconData illustration;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool loading;
  final String? error;
  final Widget? footer;
  final List<Widget> appBarActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AuthBrandHeader()),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            illustration,
                            size: 56,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...fields,
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      MaterialBanner(
                        content: Text(error!),
                        leading: Icon(Icons.info_outline, color: scheme.error),
                        backgroundColor: scheme.errorContainer,
                        actions: const [SizedBox.shrink()],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: theme.textTheme.titleSmall,
                      ),
                      onPressed: loading ? null : onSubmit,
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(submitLabel),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
