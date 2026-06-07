import 'package:flutter/material.dart';

import 'package:kaki_empat/core/services/sitter_v2_service.dart';

import 'package:kaki_empat/features/shared/widgets/v2_app_shell.dart';
import 'package:kaki_empat/features/shared/widgets/v2_loading_skeleton.dart';
import 'package:kaki_empat/features/sitter/presentation/sitter_home_page.dart';

import 'package:kaki_empat/features/sitter/presentation/sitter_onboarding_page.dart';



/// Router pengasuh: onboarding atau dashboard (auth via AuthGate).

class SitterShell extends StatefulWidget {

  const SitterShell({super.key});



  @override

  State<SitterShell> createState() => _SitterShellState();

}



class _SitterShellState extends State<SitterShell> {

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

      final profile = await SitterV2Service.instance.getProfile();

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

      return const Scaffold(body: V2ListSkeleton());

    }

    if (_needsOnboarding) {

      return SitterOnboardingPage(onComplete: _load);

    }

    return const V2AppShell(
      role: V2AppShellRole.sitter,
      home: SitterHomePage(),
    );

  }

}


