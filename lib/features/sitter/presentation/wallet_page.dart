import 'package:flutter/material.dart';
import 'package:kaki_empat/core/config/app_config.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/services/sitter_wallet_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/theme/app_colors.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/utils/user_friendly_error.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  SitterWalletSummary? _wallet;
  bool _loading = true;
  Object? _error;
  bool _withdrawing = false;
  WithdrawalV2? _pendingWithdrawal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wallet = await SitterWalletService.instance.getWallet();
      if (!mounted) return;
      WithdrawalV2? pending = _pendingWithdrawal;
      if (wallet.pendingWithdrawals > 0 && pending == null) {
        pending = WithdrawalV2(
          id: '',
          amount: wallet.pendingWithdrawals,
          status: 'pending',
        );
      }
      setState(() {
        _wallet = wallet;
        _pendingWithdrawal = pending;
        _loading = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _requestWithdraw() async {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController();
    final destinationController = TextEditingController();
    var method = 'qris';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.walletWithdrawDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.walletAmountLabel,
                        hintText: l10n.walletAmountHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: InputDecoration(labelText: l10n.walletMethodLabel),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: method,
                          items: [
                            DropdownMenuItem(
                              value: 'qris',
                              child: Text(l10n.walletMethodQris),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text(l10n.walletMethodBank),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => method = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        labelText: l10n.walletDestinationLabel,
                        hintText: l10n.walletDestinationHint,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.walletWithdrawSubmit),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) return;

    final amount = int.tryParse(amountController.text.replaceAll('.', ''));
    final destination = destinationController.text.trim();
    if (amount == null || amount < 10000 || destination.isEmpty) return;

    setState(() => _withdrawing = true);
    try {
      final result = await SitterWalletService.instance.requestWithdraw(
        amount,
        method: method,
        destination: destination,
      );
      if (!mounted) return;
      setState(() => _pendingWithdrawal = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletWithdrawSent)),
      );
      await _load();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(V2UserError.message(context, e))),
      );
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wallet = _wallet;
    final sitterFeePct = (wallet?.platformFeeSitterPercent ??
            AppConfig.platformFeeSitterPercent) *
        100;
    final pending = _pendingWithdrawal;
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2WalletSkeleton()
            : _error != null && wallet == null
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        if (pending != null) ...[
                          Card(
                            color: scheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 36,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.walletWithdrawPending,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    l10n.walletWithdrawPendingId,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(V2Formatters.money(pending.amount)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (wallet != null) ...[
                          Card(
                            color: scheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.walletAvailableBalance,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    V2Formatters.money(wallet.available),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _withdrawing || wallet.available < 10000
                                ? null
                                : _requestWithdraw,
                            icon: _withdrawing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.outbound),
                            label: Text(l10n.walletWithdraw),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.walletEarningsBreakdown, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _BreakdownRow(
                            label: l10n.walletGrossIncome,
                            value: V2Formatters.money(wallet.grossIncome),
                          ),
                          _BreakdownRow(
                            label: l10n.walletPlatformFee(
                              sitterFeePct.toStringAsFixed(0),
                            ),
                            value: V2Formatters.money(wallet.platformFees),
                            isDeduction: true,
                          ),
                          const Divider(height: 24),
                          _BreakdownRow(
                            label: l10n.walletNetIncome,
                            value: V2Formatters.money(wallet.netIncome),
                            emphasized: true,
                          ),
                          const SizedBox(height: 24),
                          Text(l10n.walletWithdrawalRequests, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (wallet.withdrawalEntries.isEmpty &&
                              wallet.pendingWithdrawals <= 0)
                            V2EmptyState(
                              message: l10n.walletWithdrawalsEmpty,
                              icon: Icons.outbound_outlined,
                            )
                          else ...[
                            if (wallet.pendingWithdrawals > 0)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(V2Formatters.money(wallet.pendingWithdrawals)),
                                subtitle: Text(l10n.walletWithdrawPending),
                                trailing: Chip(
                                  label: Text(l10n.walletWithdrawPendingId),
                                ),
                              ),
                            ...wallet.withdrawalEntries.map(
                              (entry) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(V2Formatters.money(entry.amount.abs())),
                                subtitle: Text(V2Formatters.dateTime(entry.createdAt)),
                                trailing: const Icon(Icons.check_circle_outline),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(l10n.walletTransactionHistory, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (wallet.entries.isEmpty)
                            V2EmptyState(
                              message: l10n.walletTransactionsEmpty,
                              icon: Icons.receipt_long_outlined,
                            )
                          else
                            ...wallet.entries.map((entry) {
                              final isCredit = entry.amount > 0;
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.remove_circle_outline,
                                    color: isCredit
                                        ? AppColors.statusSuccess(scheme)
                                        : scheme.error,
                                  ),
                                  title: Text(entry.description),
                                  subtitle: Text(
                                    [
                                      if (entry.bookingId != null)
                                        'Booking #${entry.bookingId}',
                                      V2Formatters.dateTime(entry.createdAt),
                                    ].join(' · '),
                                  ),
                                  trailing: Text(
                                    V2Formatters.money(entry.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isCredit
                                          ? AppColors.statusSuccess(scheme)
                                          : scheme.error,
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool isDeduction;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: (emphasized
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDeduction ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
