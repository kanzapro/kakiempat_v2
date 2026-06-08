import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaki_empat/core/config/denpasar_kecamatan.dart';
import 'package:kaki_empat/core/config/mvp_scope.dart';
import 'package:kaki_empat/core/navigation/v2_page_route.dart';
import 'package:kaki_empat/core/models/v2_domain_models.dart';
import 'package:kaki_empat/core/services/booking_v2_service.dart';
import 'package:kaki_empat/core/formatters/v2_formatters.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/services/user_v2_service.dart';
import 'package:kaki_empat/core/services/v2_api_client.dart';
import 'package:kaki_empat/core/theme/theme_notifier.dart';
import 'package:kaki_empat/core/utils/responsive.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/features/owner/presentation/add_pet_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_home_page.dart';
import 'package:kaki_empat/features/shared/presentation/booking_history_page.dart';
import 'package:kaki_empat/features/shared/widgets/kecamatan_dropdown.dart';
import 'package:kaki_empat/features/shared/widgets/v2_empty_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_error_state.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/shared/widgets/v2_pet_avatar.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  String? _kecamatan;

  OwnerProfileResult? _profile;
  int _bookingCount = 0;
  LoyaltyProfile? _loyalty;
  ReferralProfile? _referral;
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await OwnerV2Service.instance.getProfile();
      final bookings = await BookingV2Service.instance.listMyBookings();
      LoyaltyProfile? loyalty;
      ReferralProfile? referral;
      if (!MvpScope.hideLoyaltyReferral) {
        try {
          loyalty = await UserV2Service.instance.getLoyaltyPoints();
        } catch (_) {}
        try {
          referral = await UserV2Service.instance.getReferralCode();
        } catch (_) {}
      }
      if (!mounted) return;
      _address.text = profile.profile?.address ?? '';
      _kecamatan = profile.profile?.kecamatan;
      setState(() {
        _profile = profile;
        _bookingCount = bookings.length;
        _loyalty = loyalty;
        _referral = referral;
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (!DenpasarKecamatan.isValid(_kecamatan)) {
      setState(() => _error = 'Pilih kecamatan Denpasar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await OwnerV2Service.instance.saveProfile(
        address: _address.text.trim(),
        kecamatan: _kecamatan!,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
      });
    } on V2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.saveFailed;
        _saving = false;
      });
    }
  }

  Future<void> _openAddPet() async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute(page: const AddPetPage()),
    );
    if (ok == true) await _load();
  }

  Future<void> _editPet(PetV2 pet) async {
    final ok = await Navigator.of(context).push<bool>(
      V2PageRoute(page: AddPetPage(initialPet: pet)),
    );
    if (ok == true) await _load();
  }

  Future<void> _deletePet(PetV2 pet) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.deletePetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.actionDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OwnerV2Service.instance.deletePet(pet.id);
      if (!mounted) return;
      await _load();
    } on V2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _continueToHome() {
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      V2PageRoute<void>(
        page: OwnerHomePage(
          awaitingPaymentBookingId: DomainRouter.bookingIdFromUri(),
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = _profile;
    final canContinue = profile?.onboardingComplete == true;
    final padding = V2Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ownerProfileTitle)),
      body: V2Responsive.constrain(
        _loading
            ? const V2ListSkeleton()
            : _error != null && profile == null
                ? V2ErrorState.fromError(context, error: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: padding,
                      children: [
                        _StatsRow(
                          bookings: _bookingCount,
                          pets: profile?.pets.length ?? 0,
                        ),
                        if (!MvpScope.hideLoyaltyReferral && _loyalty != null) ...[
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.stars_outlined),
                              title: Text(l10n.loyaltyPointsTitle),
                              subtitle: Text(
                                '${_loyalty!.points} poin · diskon ${V2Formatters.money(_loyalty!.redeemableDiscount)}',
                              ),
                              trailing: _loyalty!.points >= _loyalty!.redeemRate
                                  ? TextButton(
                                      onPressed: () async {
                                        try {
                                          await UserV2Service.instance.redeemLoyalty(
                                            points: _loyalty!.redeemRate,
                                          );
                                          if (!context.mounted) return;
                                          await _load();
                                        } on V2ApiException catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.message)),
                                          );
                                        }
                                      },
                                      child: Text(l10n.loyaltyRedeem),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        if (!MvpScope.hideLoyaltyReferral && _referral != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.card_giftcard_outlined),
                              title: Text(l10n.referralTitle),
                              subtitle: Text(
                                '${_referral!.referralCode}\n${l10n.referralShareHint}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: l10n.referralCopyAction,
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: _referral!.referralCode),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.referralCopied)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.darkModeTitle),
                          secondary: Icon(
                            ThemeNotifier.instance.isDark
                                ? Icons.dark_mode
                                : Icons.light_mode_outlined,
                          ),
                          value: ThemeNotifier.instance.isDark,
                          onChanged: (v) => ThemeNotifier.instance.toggleDark(v),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text(l10n.profileBookingHistory),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              V2PageRoute(page: const BookingHistoryPage()),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        if (profile?.needsOnboarding == true)
                          Card(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(l10n.ownerProfileOnboardingHint)),
                                ],
                              ),
                            ),
                          ),
                        Text(l10n.ownerProfileAddress, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          l10n.ownerProfileLocationHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KecamatanDropdown(
                                value: _kecamatan,
                                onChanged: (value) => setState(() => _kecamatan = value),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _address,
                                decoration: InputDecoration(
                                  labelText: l10n.ownerProfileAddress,
                                  prefixIcon: const Icon(Icons.home_outlined),
                                ),
                                minLines: 2,
                                maxLines: 4,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? l10n.sitterOnboardingAddressRequired
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _saving ? null : _saveAddress,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(l10n.actionSave),
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Text(l10n.ownerProfilePets, style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            FilledButton.tonalIcon(
                              onPressed: _openAddPet,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.ownerProfileAddPet),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (profile?.pets.isEmpty ?? true)
                          V2EmptyState(message: l10n.ownerProfilePetsEmpty, icon: Icons.pets)
                        else
                          ...profile!.pets.map(
                            (pet) => Card(
                              child: ListTile(
                                leading: V2PetAvatar(petId: pet.id, size: 44),
                                title: Text(pet.name),
                                subtitle: Text(
                                  [
                                    pet.species,
                                    if (pet.breed.isNotEmpty) pet.breed,
                                    if (pet.age.isNotEmpty) pet.age,
                                  ].join(' · '),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _editPet(pet);
                                    if (v == 'delete') _deletePet(pet);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'edit', child: Text(l10n.profileEditPet)),
                                    PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (canContinue) ...[
                          const SizedBox(height: 24),
                          FilledButton(onPressed: _continueToHome, child: Text(l10n.actionContinue)),
                        ],
                      ],
                    ),
                  ),
        context,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.bookings, required this.pets});

  final int bookings;
  final int pets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('$bookings', style: theme.textTheme.headlineSmall),
                  Text(l10n.profileStatsBookings(bookings), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('$pets', style: theme.textTheme.headlineSmall),
                  Text(l10n.profileStatsPets(pets), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
