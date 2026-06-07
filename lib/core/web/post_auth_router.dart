import 'package:flutter/material.dart';

import 'package:kaki_empat/core/models/auth_user_v2.dart';

import 'package:kaki_empat/core/services/owner_v2_service.dart';

import 'package:kaki_empat/core/services/sitter_v2_service.dart';

import 'package:kaki_empat/core/web/domain_kind.dart';

import 'package:kaki_empat/core/web/domain_router.dart';

import 'package:kaki_empat/features/admin/presentation/admin_dashboard_page.dart';

import 'package:kaki_empat/features/owner/presentation/owner_home_page.dart';

import 'package:kaki_empat/features/owner/presentation/owner_profile_page.dart';

import 'package:kaki_empat/features/shared/widgets/event_notification_shell.dart';

import 'package:kaki_empat/features/sitter/presentation/sitter_home_page.dart';

import 'package:kaki_empat/features/sitter/presentation/sitter_onboarding_page.dart';



/// Menentukan halaman awal setelah login/register berdasarkan role & domain.

abstract final class PostAuthRouter {

  static Future<Widget> homeForUser(

    AuthUserV2 user, {

    WebDomain? domain,

  }) async {

    final d = domain ?? DomainRouter.resolve();



    if (user.isFounder || (d == WebDomain.admin && user.isAdmin)) {

      return const AdminDashboardPage();

    }

    if (user.isAdmin && d == WebDomain.admin) {

      return const AdminDashboardPage();

    }

    if (user.isSitter || d == WebDomain.sitter) {

      final profile = await SitterV2Service.instance.getProfile();

      final child = profile.needsOnboarding

          ? SitterOnboardingPage(onComplete: () {})

          : const SitterHomePage();

      return EventNotificationShell(child: child);

    }



    final profile = await OwnerV2Service.instance.getProfile();

    final child = profile.needsOnboarding

        ? const OwnerProfilePage()

        : OwnerHomePage(

            awaitingPaymentBookingId: DomainRouter.bookingIdFromUri(),

          );

    return EventNotificationShell(child: child);

  }



  static Future<void> navigate(BuildContext context, AuthUserV2 user) async {

    final domain = DomainRouter.resolve();

    final denied = DomainRouter.accessDenied(domain, user);

    if (denied != null) {

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(denied)));

      return;

    }

    final target = await homeForUser(user, domain: domain);

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(

      MaterialPageRoute<void>(builder: (_) => target),

      (_) => false,

    );

  }

}


