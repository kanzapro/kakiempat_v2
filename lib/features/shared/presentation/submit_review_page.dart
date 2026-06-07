import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/review_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class SubmitReviewPage extends StatefulWidget {
  const SubmitReviewPage({super.key, required this.bookingId, this.sitterName});

  final String bookingId;
  final String? sitterName;

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewV2Service.instance.submitReview(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _comment.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.reviewSubmitSuccess)),
      );
      Navigator.of(context).pop(true);
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.saveFailed;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.sitterName?.isNotEmpty == true)
              Text(
                l10n.reviewForSitter(widget.sitterName!),
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            Text(l10n.reviewRatingLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: theme.colorScheme.primary,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              decoration: InputDecoration(
                labelText: l10n.reviewCommentLabel,
                hintText: l10n.reviewCommentHint,
              ),
              minLines: 3,
              maxLines: 6,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              V2ErrorState(message: _error!, onRetry: _submit),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.reviewSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> openSubmitReview(
  BuildContext context, {
  required String bookingId,
  String? sitterName,
}) {
  return Navigator.of(context).push<bool>(
    V2PageRoute(
      page: SubmitReviewPage(bookingId: bookingId, sitterName: sitterName),
    ),
  );
}
