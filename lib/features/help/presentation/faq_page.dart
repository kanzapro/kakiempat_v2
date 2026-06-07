import 'package:flutter/material.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/features/shared/widgets/v2_onboarding.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class FaqEntry {
  const FaqEntry({required this.question, required this.answer, required this.tags});

  final String question;
  final String answer;
  final List<String> tags;
}

abstract final class FaqContent {
  static List<FaqEntry> all(AppLocalizations l10n) => [
        FaqEntry(
          question: l10n.faqQ1,
          answer: l10n.faqA1,
          tags: ['booking', 'permintaan'],
        ),
        FaqEntry(
          question: l10n.faqQ2,
          answer: l10n.faqA2,
          tags: ['booking', 'sitter'],
        ),
        FaqEntry(
          question: l10n.faqQ3,
          answer: l10n.faqA3,
          tags: ['pembayaran', 'payment'],
        ),
        FaqEntry(
          question: l10n.faqQ4,
          answer: l10n.faqA4,
          tags: ['pembayaran', 'bukti'],
        ),
        FaqEntry(
          question: l10n.faqQ5,
          answer: l10n.faqA5,
          tags: ['pencairan', 'withdraw'],
        ),
        FaqEntry(
          question: l10n.faqQ6,
          answer: l10n.faqA6,
          tags: ['pencairan', 'sitter'],
        ),
        FaqEntry(
          question: l10n.faqQ7,
          answer: l10n.faqA7,
          tags: ['booking', 'batal'],
        ),
        FaqEntry(
          question: l10n.faqQ8,
          answer: l10n.faqA8,
          tags: ['ulasan', 'rating'],
        ),
        FaqEntry(
          question: l10n.faqQ9,
          answer: l10n.faqA9,
          tags: ['loyalitas', 'poin'],
        ),
        FaqEntry(
          question: l10n.faqQ10,
          answer: l10n.faqA10,
          tags: ['referral', 'bonus'],
        ),
      ];
}

class FaqPage extends StatefulWidget {
  const FaqPage({super.key, this.isOwner = true});

  final bool isOwner;

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = FaqContent.all(l10n);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? entries
        : entries.where((e) {
            final hay = '${e.question} ${e.answer} ${e.tags.join(' ')}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpFaqTitle)),
      body: V2Responsive.constrain(
        ListView(
          padding: V2Responsive.pagePadding(context),
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.faqSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => widget.isOwner
                  ? V2Onboarding.showOwnerTutorial(context)
                  : V2Onboarding.showSitterTutorial(context),
              icon: const Icon(Icons.school_outlined),
              label: Text(l10n.helpRepeatTutorial),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.faqNoResults, textAlign: TextAlign.center),
              )
            else
              ...filtered.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(e.question,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(e.answer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        context,
      ),
    );
  }
}
