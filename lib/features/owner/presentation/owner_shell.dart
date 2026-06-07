import 'package:flutter/material.dart';
import 'package:kaki_empat/core/services/owner_v2_service.dart';
import 'package:kaki_empat/core/web/domain_router.dart';
import 'package:kaki_empat/features/owner/presentation/owner_home_page.dart';
import 'package:kaki_empat/features/owner/presentation/owner_profile_page.dart';
import 'package:kaki_empat/features/shared/widgets/v2_app_shell.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';

/// Router pemilik: profil/onboarding atau dashboard.
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  bool _loading = true;
  bool _needsOnboarding = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await OwnerV2Service.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _needsOnboarding = profile.needsOnboarding;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _needsOnboarding = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: V2GridSkeleton());
    }
    if (_needsOnboarding) {
      return OwnerProfilePage(onComplete: _load);
    }
    return V2AppShell(
      role: V2AppShellRole.owner,
      home: OwnerHomePage(
        awaitingPaymentBookingId: DomainRouter.bookingIdFromUri(),
      ),
    );
  }
}
