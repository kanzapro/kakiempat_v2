// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaki Empat';

  @override
  String get tagline => 'Need a sitter or want to become a partner?';

  @override
  String get wwwOwnerCta => 'Find a Sitter';

  @override
  String get wwwPartnerCta => 'Become a Sitter';

  @override
  String get wwwHeroTitle =>
      'Happy pets, peace of mind. We find the best sitter near you.';

  @override
  String get wwwHeroSubtitle =>
      'From morning walks to overnight stays — all covered. Verified sitters, you just pick.';

  @override
  String get wwwValueVerified => 'Verified sitters';

  @override
  String get wwwValueTransparent => 'Transparent fees';

  @override
  String get wwwValueSecure => 'Safe & trusted';

  @override
  String get wwwServicesSubtitle => 'One platform for all your pet care needs.';

  @override
  String get wwwHowItWorksTitle => 'How it works';

  @override
  String get wwwHowStep1 => 'Sign up & add your pets';

  @override
  String get wwwHowStep2 => 'Choose a nearby sitter';

  @override
  String get wwwHowStep3 => 'Book & pay in the app';

  @override
  String subdomainComingSoonTitle(String app) {
    return '$app — coming soon';
  }

  @override
  String get subdomainComingSoonBody =>
      'We\'re rolling out features in phases. Start booking through the Pet Owner app.';

  @override
  String get subdomainComingSoonOwnerCta => 'Open Owner app';

  @override
  String ownerActionOffersBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests have new offers',
      one: '1 request has new offers',
    );
    return '$_temp0';
  }

  @override
  String get ownerActionOffersBannerBody =>
      'Accept an offer to continue to payment and confirm your schedule.';

  @override
  String get ownerViewOffers => 'View offers';

  @override
  String get wwwOwnerCtaLong => 'I\'m a Pet Owner';

  @override
  String get wwwPartnerCtaLong => 'I Want to Be a Sitter';

  @override
  String get wwwServicesTitle => 'Services';

  @override
  String get wwwServiceWalkingTitle => 'Dog Walking';

  @override
  String get wwwServiceWalkingDesc =>
      'Regular walks with experienced caregivers.';

  @override
  String get wwwServiceSittingTitle => 'Pet Sitting';

  @override
  String get wwwServiceSittingDesc => 'In-home care while you are away.';

  @override
  String get wwwServiceGroomingTitle => 'Grooming';

  @override
  String get wwwServiceGroomingDesc => 'Baths, nail trims, and basic grooming.';

  @override
  String get wwwServiceTrainingTitle => 'Training';

  @override
  String get wwwServiceTrainingDesc =>
      'Basic training and socialization sessions.';

  @override
  String get wwwPricingTitle => 'Pricing & platform fees';

  @override
  String get wwwPricingOwnerNote =>
      'Owners pay service rate + 5% platform fee.';

  @override
  String get wwwPricingSitterNote =>
      'Sitters receive service rate − 8% platform fee. Payout in under 1 day.';

  @override
  String get wwwTestimonialsTitle => 'Testimonials';

  @override
  String get wwwTestimonial1Name => 'Rina, Jakarta';

  @override
  String get wwwTestimonial1Quote =>
      'Easy to find a sitter for my cat. Booking and payment are straightforward.';

  @override
  String get wwwTestimonial2Name => 'Budi, Bandung';

  @override
  String get wwwTestimonial2Quote =>
      'As a sitter, earnings arrive quickly and clients are friendly.';

  @override
  String get wwwTestimonial3Name => 'Dewi, Surabaya';

  @override
  String get wwwTestimonial3Quote =>
      'My dog loves every walk with a Kaki Empat sitter.';

  @override
  String get wwwCtaTitle => 'Ready to start?';

  @override
  String get wwwCtaSubtitle =>
      'Sign up as a pet owner or apply to become a partner sitter.';

  @override
  String get wwwSignupSitterTitle => 'Apply as a partner sitter';

  @override
  String get wwwSignupSitterDesc =>
      'Fill in the form below. After signing up, continue to the sitter portal to complete your profile and verification.';

  @override
  String get wwwSignupSuccess =>
      'Registration successful! Continue to the sitter portal to complete your profile.';

  @override
  String get wwwSignupGoSitter => 'Open sitter portal';

  @override
  String get wwwBlogTitle => 'Tips & info';

  @override
  String get wwwBlog1Title => 'How to choose the right sitter';

  @override
  String get wwwBlog1Desc =>
      'Check reviews, offered services, and distance from your location.';

  @override
  String get wwwBlog2Title => 'Prepare your pet before booking';

  @override
  String get wwwBlog2Desc =>
      'Note feeding habits, allergies, and vet contact in your pet profile.';

  @override
  String get ownerLoginTitle => 'Sign in - Pet Owner';

  @override
  String get ownerHomePlaceholder => 'Owner Dashboard';

  @override
  String get sitterHero => 'Love animals? Earn from it.';

  @override
  String get sitterLandingSubtitle =>
      'Set your own schedule and rates. Only 8% commission. Earnings go straight to your wallet.';

  @override
  String get sitterStartNow => 'Get Started';

  @override
  String get sitterBenefitsLine => '🕐 Flexible • 💰 8% fee • ⚡ Payout < 1 day';

  @override
  String get sitterTestimonial1Name => 'Putri';

  @override
  String get sitterTestimonial1Quote =>
      'I started just to try it out — now I get bookings every week. I love staying active, and the extra income is a bonus!';

  @override
  String get sitterTestimonial2Name => 'Rian';

  @override
  String get sitterTestimonial2Quote =>
      'I already had grooming tools at home, and it turned out many people need mobile grooming. Now I run my service from home.';

  @override
  String get sitterHeroSubtitle =>
      'Only 8% commission, payout in under 1 day, flexible hours.';

  @override
  String get sitterStatActive => '50+ active sitters';

  @override
  String get sitterStatBookings => '10+ bookings/month';

  @override
  String get sitterBadgeNew => 'New';

  @override
  String sitterNewRequestsSubtitle(int count) {
    return '$count new requests near you';
  }

  @override
  String get sitterPlatformFee => '8% platform fee';

  @override
  String get sitterPayout => 'Payout in under 1 day';

  @override
  String get sitterRegisterCta => 'Register as Partner';

  @override
  String get adminLoginTitle => 'Admin Panel';

  @override
  String get adminPanelPlaceholder => 'Admin Panel - Coming Soon';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authPhone => 'WhatsApp number';

  @override
  String get authPhoneHint => '0812, 62812, or +62812';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Min. 6 characters';

  @override
  String get authName => 'Name';

  @override
  String get authRole => 'Choose role';

  @override
  String get authRoleOwner => 'Pet owner';

  @override
  String get authRoleSitter => 'Pet sitter';

  @override
  String get authNoAccount => 'No account yet?';

  @override
  String get authHasAccount => 'Already have an account?';

  @override
  String get authInvalidPhone =>
      'Unrecognized number. Use 08xx, 62xx, or +62xx.';

  @override
  String get authInvalidPassword => 'Password must be at least 6 characters.';

  @override
  String get authNameRequired => 'Name is required.';

  @override
  String get authFailed => 'Request failed. Please try again.';

  @override
  String get authLogout => 'Log out';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your registered WhatsApp number. A reset code is sent via in-app notification.';

  @override
  String get authSendResetCode => 'Send reset code';

  @override
  String get authHaveResetCode => 'Already have a reset code?';

  @override
  String get authBackToLogin => 'Back to sign in';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String get authResetPasswordSubtitle =>
      'Enter your number, reset code from notification, and new password.';

  @override
  String get authResetCode => 'Reset code';

  @override
  String get authResetCodeRequired => 'Reset code is required.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authResetSuccess => 'Password updated. Please sign in.';

  @override
  String get wwwOpenApp => 'Open app';

  @override
  String get authAccessDenied => 'Access denied for this domain.';

  @override
  String get actionSave => 'Save';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Go to Dashboard';

  @override
  String get actionEditProfile => 'Edit Profile';

  @override
  String get loadFailed => 'Failed to load data. Pull to refresh.';

  @override
  String get saveFailed => 'Failed to save. Please try again.';

  @override
  String get sitterOnboardingTitle => 'Sitter Onboarding';

  @override
  String get sitterOnboardingStepServices => 'Choose Services';

  @override
  String get sitterOnboardingStepProfile => 'Your Profile';

  @override
  String get sitterOnboardingStepVerify => 'Verification';

  @override
  String get sitterOnboardingSelectServices => 'Select the services you offer';

  @override
  String get sitterOnboardingServicesRequired => 'Select at least one service.';

  @override
  String get sitterOnboardingBio => 'Bio & experience';

  @override
  String get sitterOnboardingAddress => 'Address';

  @override
  String get sitterOnboardingAddressRequired => 'Address is required.';

  @override
  String get sitterOnboardingBioRequired => 'Bio is required.';

  @override
  String get sitterOnboardingSubmit => 'Submit for Verification';

  @override
  String get sitterOnboardingWaitingTitle => 'Awaiting Verification';

  @override
  String get sitterOnboardingWaitingMessage =>
      'Your profile is being reviewed by the Kaki Empat team. We will notify you once approved.';

  @override
  String get sitterHomeTitle => 'Sitter Home';

  @override
  String sitterGreeting(String name, int count) {
    return 'Hello, $name! 🌟 $count new requests near you.';
  }

  @override
  String sitterGreetingNoRequests(String name) {
    return 'Hello, $name! 🌟 Ready for requests today?';
  }

  @override
  String sitterMonthlyEarnings(String amount) {
    return 'This month: $amount';
  }

  @override
  String get sitterOfferPrice => 'Make an Offer';

  @override
  String sitterRequestDistanceFromYou(String km) {
    return '📍 $km km from you';
  }

  @override
  String get sitterHomePlaceholder =>
      'Welcome! Your sitter dashboard will appear here soon.';

  @override
  String get sitterProfileTitle => 'Sitter Profile';

  @override
  String get sitterProfileBio => 'Bio';

  @override
  String get sitterProfileAddress => 'Address';

  @override
  String get sitterProfileServices => 'Services';

  @override
  String get sitterProfileStatus => 'Verification status';

  @override
  String get sitterStatusDraft => 'Draft';

  @override
  String get sitterStatusPending => 'Awaiting verification';

  @override
  String get sitterStatusApproved => 'Approved';

  @override
  String get sitterStatusRejected => 'Rejected';

  @override
  String get ownerProfileTitle => 'Owner Profile';

  @override
  String get ownerProfileOnboardingHint =>
      'Add your address and at least one pet before booking services.';

  @override
  String get ownerProfileAddress => 'Home address';

  @override
  String get ownerProfileAddressEmpty => 'Address not set';

  @override
  String get ownerProfileAddressHint =>
      'Your address is used for on-site services.';

  @override
  String get ownerProfilePets => 'Pets';

  @override
  String get ownerProfilePetsEmpty => 'No pets registered yet.';

  @override
  String get ownerProfileAddPet => 'Add Pet';

  @override
  String get addPetTitle => 'Add Pet';

  @override
  String get petName => 'Pet name';

  @override
  String get petSpecies => 'Species';

  @override
  String get petSpeciesHint => 'Dog, cat, etc.';

  @override
  String get petBreed => 'Breed';

  @override
  String get petAge => 'Age';

  @override
  String get petWeight => 'Weight (kg)';

  @override
  String get petNotes => 'Behavior notes';

  @override
  String get petNameRequired => 'Name is required.';

  @override
  String get petSpeciesRequired => 'Species is required.';

  @override
  String get catalogLoadFailed => 'Failed to load service catalog.';

  @override
  String get valueEmpty => '—';

  @override
  String get ownerHomeTitle => 'Home';

  @override
  String get ownerHomeSubtitle => 'Popular Services';

  @override
  String ownerGreeting(String name) {
    return 'Hello, $name! 🐾 Who are we taking out today?';
  }

  @override
  String get ownerViewAllServices => 'See All Services';

  @override
  String get ownerActiveBookings => 'Active Bookings';

  @override
  String get ownerPetQuickWalk => 'Morning walk';

  @override
  String get ownerPetQuickBath => 'Bath';

  @override
  String get ownerPetQuickCheckup => 'Check-up';

  @override
  String get ownerGreetingSubtitle => 'Who are we walking today?';

  @override
  String get ownerActiveBookingsTitle => 'Active Bookings';

  @override
  String get ownerActiveBookingsEmpty => 'No active bookings yet.';

  @override
  String get ownerFavoriteSittersTitle => 'Favorite Sitters';

  @override
  String get ownerFavoriteSittersEmpty =>
      'No favorites yet. Save from incoming offers.';

  @override
  String ownerCategoryServiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
    );
    return '$_temp0';
  }

  @override
  String get ownerServicesInCategory => 'Services';

  @override
  String get ownerMyBookings => 'My Bookings';

  @override
  String get ownerOnboardingBannerTitle => 'Complete your profile';

  @override
  String get ownerOnboardingBannerBody =>
      'Add your address and at least one pet before booking.';

  @override
  String get ownerFillAddress => 'Add Address';

  @override
  String get ownerAddPet => 'Add Pet';

  @override
  String get createRequestTitle => 'Find a Sitter';

  @override
  String get createRequestPet => 'Select pet(s)';

  @override
  String get createRequestDate => 'Date';

  @override
  String get createRequestTime => 'Start time';

  @override
  String get createRequestDuration => 'Duration';

  @override
  String createRequestDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get createRequestLocation => 'Location';

  @override
  String get createRequestNotes => 'Notes (optional)';

  @override
  String get createRequestPrice => 'Offered price (IDR)';

  @override
  String get createRequestSubmit => 'Find a Sitter';

  @override
  String get createRequestSuccess =>
      '✅ Booking sent! Your sitter will respond soon.';

  @override
  String get ownerOpenRequestsTitle => 'Active Requests';

  @override
  String get ownerOpenRequestsEmpty => 'No open requests yet.';

  @override
  String ownerPendingOffers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
      zero: 'No offers',
    );
    return '$_temp0';
  }

  @override
  String get ownerRequestOffersTitle => 'Sitter Offers';

  @override
  String get ownerRequestOffersHeading => 'Incoming offers';

  @override
  String get ownerRequestOffersEmpty => 'No offers for this request yet.';

  @override
  String get ownerAcceptOfferTitle => 'Accept Offer';

  @override
  String ownerAcceptOfferConfirm(String sitterName, String price) {
    return 'Accept offer from $sitterName for $price?';
  }

  @override
  String get ownerAcceptOfferAction => 'Accept Offer';

  @override
  String get ownerAcceptOfferSuccess => 'Offer accepted. Booking created.';

  @override
  String get createRequestSelectPet => 'Select at least one pet.';

  @override
  String get createRequestSelectDate => 'Select a date.';

  @override
  String get createRequestSelectTime => 'Select a start time.';

  @override
  String get createRequestLocationRequired => 'Location is required.';

  @override
  String get createRequestServiceRequired => 'Service is required.';

  @override
  String get createRequestPriceHint => 'Suggested rate for this service';

  @override
  String get createRequestPriceRequired => 'Price must be greater than zero.';

  @override
  String get ownerProfileLocationHint =>
      'Allow browser location so nearby sitters can find your requests.';

  @override
  String get sitterAvailabilityTitle => 'Available for orders';

  @override
  String get sitterAvailabilityOffHint => 'Off — new requests are hidden.';

  @override
  String get requestSkipOffer => 'Skip request';

  @override
  String get sitterRequestsTitle => 'Available Requests';

  @override
  String get sitterRequestsEmpty =>
      'No requests nearby yet. Check again later ☕';

  @override
  String get sitterFilterService => 'Service';

  @override
  String get sitterFilterAllServices => 'All services';

  @override
  String get sitterFilterRadius => 'Radius (km)';

  @override
  String get sitterFilterRadiusAll => 'Any distance';

  @override
  String sitterRequestDistance(String km) {
    return '$km km away';
  }

  @override
  String get sitterBroadcastRadiusBadge => 'Within 7 km radius';

  @override
  String get sitterPollingSearching => 'Looking for new requests...';

  @override
  String sitterNewRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new requests',
      one: '1 new request',
    );
    return '$_temp0';
  }

  @override
  String sitterRequestsInRadius(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests in radius',
      one: '1 request in radius',
      zero: 'No requests in radius',
    );
    return '$_temp0';
  }

  @override
  String createRequestSitterEstimate(int count) {
    return 'About $count sitters within 7 km may see this request';
  }

  @override
  String get createRequestSitterEstimateLoading => 'Counting nearby sitters…';

  @override
  String createRequestSuccessBroadcast(int count) {
    return 'Request sent. About $count sitters within 7 km will see it.';
  }

  @override
  String get requestDetailTitle => 'Request Details';

  @override
  String get requestDetailOwner => 'Pet owner';

  @override
  String get requestDetailPets => 'Pets';

  @override
  String get requestDetailSchedule => 'Schedule';

  @override
  String get requestDetailLocation => 'Location';

  @override
  String get requestDetailNotes => 'Notes';

  @override
  String get requestDetailPrice => 'Owner budget';

  @override
  String get requestOfferPrice => 'Your offer (IDR)';

  @override
  String get requestOfferMessage => 'Message (optional)';

  @override
  String get requestOfferSubmit => 'Make an Offer';

  @override
  String get requestOfferSuccess =>
      '💰 Offer sent! Waiting for the owner\'s response.';

  @override
  String get bookingDetailTitle => 'Booking Details';

  @override
  String get bookingDetailStatus => 'Status';

  @override
  String get bookingDetailTimeline => 'Timeline';

  @override
  String get bookingDetailService => 'Service';

  @override
  String get bookingDetailSchedule => 'Schedule';

  @override
  String get bookingDetailAmount => 'Amount';

  @override
  String get bookingDetailPay => 'Pay Now';

  @override
  String get bookingDetailConfirm => 'Confirm Booking';

  @override
  String get bookingDetailEnRoute => 'Mark En Route';

  @override
  String get bookingDetailStart => 'Start Service';

  @override
  String get bookingDetailComplete => 'Complete Service';

  @override
  String get bookingDetailCancel => 'Cancel Booking';

  @override
  String get bookingDetailActionSuccess => 'Booking updated.';

  @override
  String get bookingStatusOpen => 'Awaiting sitter';

  @override
  String get bookingStatusMatched => 'Assigned';

  @override
  String get bookingStatusPending => 'Awaiting confirmation';

  @override
  String get bookingStatusAwaitingPayment => 'Awaiting payment';

  @override
  String get bookingStatusPendingVerification => 'Payment verification';

  @override
  String get bookingStatusPaid => 'Paid';

  @override
  String get bookingStatusPaymentRejected => 'Payment rejected';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusEnRoute => 'En route';

  @override
  String get bookingStatusInProgress => 'In progress';

  @override
  String get bookingStatusCompleted => 'Done 🎉';

  @override
  String get bookingTimelineCreated => 'Request created';

  @override
  String get bookingTimelineMatched => 'Sitter assigned';

  @override
  String get bookingTimelinePaid => 'Payment received';

  @override
  String get bookingTimelineConfirmed => 'Confirmed by sitter';

  @override
  String get bookingTimelineEnRoute => 'Sitter en route';

  @override
  String get bookingTimelineInProgress => 'Service started';

  @override
  String get bookingTimelineCompleted => 'Service completed';

  @override
  String get ownerBookingsEmpty => 'No bookings yet';

  @override
  String get sitterMyBookings => 'My Bookings';

  @override
  String get sitterVerificationRequired =>
      'Profile verification is required to view requests.';

  @override
  String requestPetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pets',
      one: '1 pet',
    );
    return '$_temp0';
  }

  @override
  String createRequestTotalPreview(String total, String fee) {
    return 'Total you pay: $total (incl. $fee platform fee)';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get bookingDetailCancelConfirm =>
      'Sure you want to cancel this booking? 🥺';

  @override
  String get sitterActiveBookingsEmpty => 'No active bookings yet.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatInputHint => 'Type a message…';

  @override
  String get chatSendFailed => 'Could not send message. Please try again.';

  @override
  String get bookingDetailChat => 'Open Chat';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsMarkAllRead => 'Mark All Read';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminSummarySitters => 'Total Sitter';

  @override
  String get adminSummaryOwners => 'Total Owner';

  @override
  String get adminSummaryBookings => 'Total Booking';

  @override
  String get adminSummaryPending => 'Verifikasi Pending';

  @override
  String get adminTabSitters => 'Sitters';

  @override
  String get adminTabOwners => 'Owners';

  @override
  String get adminTabBookings => 'Bookings';

  @override
  String get adminTabWithdrawals => 'Withdrawals';

  @override
  String get adminTabPayments => 'Payments';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminActive => 'Active';

  @override
  String get adminInactive => 'Inactive';

  @override
  String get adminSittersEmpty => 'No sitters awaiting verification.';

  @override
  String get adminOwnersEmpty => 'No owners registered yet.';

  @override
  String get adminBookingsEmpty => 'No bookings found.';

  @override
  String get adminWithdrawalsEmpty => 'No pending withdrawal requests.';

  @override
  String adminSitterApproved(String name) {
    return '$name approved';
  }

  @override
  String adminSitterRejected(String name) {
    return '$name rejected';
  }

  @override
  String get adminWithdrawalApproved => 'Withdrawal approved.';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentMethodTitle =>
      'WISE / REVOLUT / INTERNATIONAL BANK TRANSFER';

  @override
  String get paymentTabWise => 'Wise';

  @override
  String get paymentTabRevolut => 'Revolut';

  @override
  String get paymentTabBankTransfer => 'Bank Transfer';

  @override
  String get paymentWiseStep1 => 'Open the Wise app on your phone.';

  @override
  String get paymentWiseStep2 =>
      'Select Send Money → International transfer → IDR recipient.';

  @override
  String get paymentWiseStep3 => 'Enter our SeaBank account details above.';

  @override
  String get paymentWiseStep4 =>
      'Send the exact amount shown below, including the unique code.';

  @override
  String get paymentRevolutStep1 => 'Open the Revolut app on your phone.';

  @override
  String get paymentRevolutStep2 =>
      'Select Send → International transfer → IDR recipient.';

  @override
  String get paymentRevolutStep3 => 'Enter our SeaBank account details above.';

  @override
  String get paymentRevolutStep4 =>
      'Send the exact amount shown below, including the unique code.';

  @override
  String get paymentBankStep1 =>
      'Use your bank\'s mobile or internet banking app.';

  @override
  String get paymentBankStep2 =>
      'Choose international or SWIFT transfer to Indonesia (IDR).';

  @override
  String get paymentBankStep3 => 'Enter our SeaBank account details above.';

  @override
  String get paymentBankStep4 =>
      'Send the exact amount shown below, including the unique code.';

  @override
  String paymentMethodDescription(String feePercent) {
    return 'We accept direct peer-to-peer transfers via Wise or Revolut. Service rate plus a $feePercent% platform fee is included in the total below.';
  }

  @override
  String get paymentBankDetailsTitle =>
      'OUR RECEIVING BANK DETAILS (INDONESIA)';

  @override
  String get paymentBankName => 'Bank Name';

  @override
  String get paymentBankCode => 'Bank Code';

  @override
  String get paymentAccountNo => 'Account No.';

  @override
  String get paymentAccountName => 'Account Name';

  @override
  String get paymentHowToPay => 'HOW TO PAY';

  @override
  String get paymentAmountToSend => 'Amount to Send';

  @override
  String get paymentServiceRate => 'Service Rate';

  @override
  String paymentPlatformFee(String percent) {
    return 'Platform Fee ($percent%)';
  }

  @override
  String get paymentExactAmountHint =>
      'Please send the EXACT total amount for instant auto-activation.';

  @override
  String get paymentReferenceLabel => 'Wise/Revolut Transfer Reference Code';

  @override
  String get paymentReferenceHint => 'e.g. TRANSFER-123456789';

  @override
  String get paymentReferenceRequired => 'Transfer reference code is required.';

  @override
  String get paymentUploadProof => 'Upload Transfer Proof';

  @override
  String paymentProofSelected(String fileName) {
    return 'Proof: $fileName';
  }

  @override
  String get paymentConfirm => 'Confirm Payment';

  @override
  String get paymentSubmitFailed =>
      'Could not submit payment proof. Please try again.';

  @override
  String get paymentCopied => 'Copied to clipboard';

  @override
  String get paymentWaitingVerification => 'Awaiting Admin Verification';

  @override
  String get paymentWaitingVerificationId => 'Menunggu Verifikasi';

  @override
  String get paymentWaitingVerificationBody =>
      'Your payment proof has been received. Our team will verify your transfer shortly.';

  @override
  String get paymentSuccess => 'Payment Successful';

  @override
  String get paymentSuccessId => 'Pembayaran Berhasil';

  @override
  String get paymentBackToDashboard => 'Back to Dashboard';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get paymentTotalPaid => 'Total Paid';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletAvailableBalance => 'Available Balance';

  @override
  String get walletWithdraw => 'Withdraw Balance';

  @override
  String get walletEarningsBreakdown => 'Earnings Breakdown';

  @override
  String get walletGrossIncome => 'Gross Income';

  @override
  String walletPlatformFee(String percent) {
    return 'Platform Fee ($percent%)';
  }

  @override
  String get walletNetIncome => 'Net Income';

  @override
  String get walletWithdrawalRequests => 'Withdrawal Requests';

  @override
  String get walletWithdrawalsEmpty => 'No withdrawal requests yet.';

  @override
  String get walletTransactionHistory => 'Transaction History';

  @override
  String get walletTransactionsEmpty => 'No transactions yet.';

  @override
  String get walletWithdrawDialogTitle => 'Withdraw Balance';

  @override
  String get walletAmountLabel => 'Amount (IDR)';

  @override
  String get walletAmountHint => 'Min. 10,000';

  @override
  String get walletMethodLabel => 'Method';

  @override
  String get walletMethodQris => 'QRIS';

  @override
  String get walletMethodBank => 'Bank Account';

  @override
  String get walletDestinationLabel => 'Destination';

  @override
  String get walletDestinationHint => 'QRIS code or account number';

  @override
  String get walletWithdrawSubmit => 'Submit';

  @override
  String get walletWithdrawSent => 'Withdrawal request submitted.';

  @override
  String get walletWithdrawPending => 'Awaiting Processing';

  @override
  String get walletWithdrawPendingId => 'Menunggu Diproses';

  @override
  String get walletLoadFailed => 'Failed to load wallet.';

  @override
  String get errorStateTitle => 'Failed to load data';

  @override
  String get errorStateRetry => 'Try again';

  @override
  String get errorStateBody =>
      'Something went wrong. Check your internet connection and try again.';

  @override
  String get loadMore => 'Load more';

  @override
  String get filterAll => 'All';

  @override
  String get filterLast7Days => '7 days';

  @override
  String get filterLast30Days => '30 days';

  @override
  String get filterLast90Days => '90 days';

  @override
  String get bookingHistoryTitle => 'Booking History';

  @override
  String get bookingHistoryEmpty => 'No booking history yet.';

  @override
  String get bookingHistoryFilterDate => 'Date filter';

  @override
  String get bookingHistoryFilterStatus => 'Status';

  @override
  String get reviewTitle => 'How was your experience?';

  @override
  String reviewForSitter(String sitterName) {
    return 'Review for $sitterName';
  }

  @override
  String get reviewRatingLabel => 'Rating';

  @override
  String get reviewCommentLabel => 'Comment';

  @override
  String get reviewCommentHint => 'Share your experience...';

  @override
  String get reviewSubmit => 'Submit Review';

  @override
  String get reviewSubmitSuccess => 'Review submitted successfully.';

  @override
  String get reviewLeaveAction => 'Leave review';

  @override
  String get reviewAlreadySubmitted => 'Review already submitted';

  @override
  String get darkModeTitle => 'Dark mode';

  @override
  String get profileStatsTitle => 'Statistics';

  @override
  String profileStatsBookings(int count) {
    return '$count bookings';
  }

  @override
  String profileStatsPets(int count) {
    return '$count pets';
  }

  @override
  String get profileStatsEarnings => 'Net earnings';

  @override
  String get profileBookingHistory => 'Booking history';

  @override
  String get profileEditPet => 'Edit pet';

  @override
  String get deletePetConfirm => 'Remove this pet from your profile?';

  @override
  String get sortLabel => 'Sort by';

  @override
  String get sortPriceLow => 'Lowest price';

  @override
  String get sortPriceHigh => 'Highest price';

  @override
  String get sortRating => 'Highest rating';

  @override
  String get favoriteAdd => 'Save favorite';

  @override
  String get favoriteRemove => 'Remove favorite';

  @override
  String get favoritesTitle => 'Favorite sitters';

  @override
  String get inAppNotificationsHint =>
      'Real-time notifications via API polling (no Firebase).';

  @override
  String get onboardingOwnerTitle => 'Welcome, Owner!';

  @override
  String get onboardingOwnerStep1 => 'Complete your address and add your pets.';

  @override
  String get onboardingOwnerStep2 =>
      'Pick a service, create a request, and accept sitter offers.';

  @override
  String get onboardingOwnerStep3 =>
      'Pay, track bookings, and leave a review when done.';

  @override
  String get onboardingSitterTitle => 'Welcome, Sitter!';

  @override
  String get onboardingSitterStep1 =>
      'Complete your profile and offered services.';

  @override
  String get onboardingSitterStep2 =>
      'Once approved, browse nearby owner requests.';

  @override
  String get onboardingSitterStep3 =>
      'Send offers, manage bookings, and withdraw earnings.';

  @override
  String get onboardingGotIt => 'Got it';

  @override
  String get onboardingNext => 'Next';

  @override
  String get tooltipNotifications => 'In-app notifications';

  @override
  String get tooltipProfile => 'Profile & settings';

  @override
  String get tooltipBookingHistory => 'Riwayat booking';

  @override
  String get tooltipLogout => 'Keluar dari akun';

  @override
  String get tooltipWallet => 'Dompet & pencairan';

  @override
  String get searchHint => 'Search...';

  @override
  String get sitterActiveBookingsTitle => 'Booking Aktif';

  @override
  String get authLoginSubtitle =>
      'Welcome back! Sign in to continue caring for your pets.';

  @override
  String get authRegisterSubtitle =>
      'Create a free account and find trusted sitters near you.';

  @override
  String get authLoginSuccess => 'Signed in! Redirecting…';

  @override
  String get authRegisterSuccess =>
      'Registration successful! Welcome to Kaki Empat.';

  @override
  String get authNameHint => 'Your full name';

  @override
  String get wwwAuthHubTitle => 'Kaki Empat account';

  @override
  String get wwwNavBrand => 'Kaki Empat';

  @override
  String get wwwNavMenu => 'Menu';

  @override
  String get wwwNavHome => 'Home';

  @override
  String get wwwNavServices => 'Services';

  @override
  String get wwwNavPricing => 'Pricing';

  @override
  String get wwwNavSignup => 'Become a sitter';

  @override
  String get wwwNavBlog => 'Tips';

  @override
  String get wwwNavTestimonials => 'Reviews';

  @override
  String get wwwNavApps => 'Apps';

  @override
  String get wwwOpenOwnerApp => 'Open owner app';

  @override
  String get wwwOpenSitterApp => 'Open sitter app';

  @override
  String get wwwOpenAdminApp => 'Open admin panel';

  @override
  String get wwwOpenStagingApp => 'Staging (QA)';

  @override
  String get wwwFooterTagline => 'Trusted pet care platform in Indonesia.';

  @override
  String get wwwFooterSections => 'Pages';

  @override
  String wwwFooterCopyright(int year, String appName) {
    return '© $year $appName. All rights reserved.';
  }

  @override
  String get ownerPetsTitle => 'Your pets';

  @override
  String get ownerAddFirstPetCta => 'Add your first pet!';

  @override
  String get ownerCreateRequestFab => 'Find a Sitter';

  @override
  String get ownerCreateRequestFabHint =>
      'Pick a service and create a new request';

  @override
  String get sitterRequestsEmptyTip =>
      'Complete your profile to receive more requests';

  @override
  String get sitterCompleteProfileCta => 'Complete profile';

  @override
  String get sitterFaqTitle => 'Tips & Help';

  @override
  String get sitterFaqIntro =>
      'Quick answers to common sitter questions on Kaki Empat.';

  @override
  String get sitterFaqQ1 => 'How do I get more requests?';

  @override
  String get sitterFaqA1 =>
      'Complete your bio, address, and offered services. A clear profile helps owners choose you.';

  @override
  String get sitterFaqQ2 => 'What price should I offer?';

  @override
  String get sitterFaqA2 =>
      'Use the owner\'s listed price as a guide. Adjust for experience and travel. Very high offers may be declined.';

  @override
  String get sitterFaqQ3 => 'When do earnings reach my wallet?';

  @override
  String get sitterFaqA3 =>
      'After the booking completes and the owner leaves a review (or automatically after 48 hours), net earnings are credited.';

  @override
  String get sitterFaqQ4 => 'How do I withdraw balance?';

  @override
  String get sitterFaqA4 =>
      'Open Wallet, enter amount and bank/QRIS destination. Payouts are processed within 1 business day.';

  @override
  String get sitterOfferPriceTip =>
      'Tip: start from the owner\'s price and adjust for your experience.';

  @override
  String sitterEarningsEstimate(String amount) {
    return 'Estimated net earnings: $amount (after 8% platform fee)';
  }

  @override
  String get ownerGuideTip1 =>
      'Choose sitters with high ratings and positive reviews.';

  @override
  String get ownerGuideTip2 =>
      'Pay only through Kaki Empat\'s official account — never transfer directly to sitters.';

  @override
  String get ownerGuideTip3 =>
      'Prepare food, leash, and health notes before the scheduled visit.';

  @override
  String adminStatSitters(int count) {
    return '$count Sitters';
  }

  @override
  String adminStatOwners(int count) {
    return '$count Owners';
  }

  @override
  String adminStatPendingVerify(int count) {
    return '$count Need Verification';
  }

  @override
  String adminStatTransactions(String amount) {
    return '$amount Transactions';
  }

  @override
  String get adminPendingActionsTitle => 'Needs Action';

  @override
  String adminActionNewSitter(String name, String services) {
    return '📋 New sitter: $name ($services)';
  }

  @override
  String adminActionPayment(String amount, String owner) {
    return '💳 Payment: $amount from $owner';
  }

  @override
  String adminActionWithdrawal(String amount, String destination) {
    return '🏧 Withdrawal: $amount to $destination';
  }

  @override
  String get pullRefreshSearching => 'Looking for new requests...';

  @override
  String get statsBookingsLabel => 'successful bookings';

  @override
  String get statsRatingLabel => 'sitter rating';

  @override
  String get statsCitiesValue => '3 cities';

  @override
  String get statsCitiesLabel => 'Denpasar, Surabaya, Jakarta';

  @override
  String get statsPayoutLabel => 'paid to partners';

  @override
  String get sitterTestimonialsTitle => 'Stories from Our Partners';

  @override
  String get sitterTestimonial1Role => 'Dog Walker';

  @override
  String get sitterTestimonial1City => 'Denpasar';

  @override
  String get sitterTestimonial2Role => 'Grooming';

  @override
  String get sitterTestimonial2City => 'Surabaya';

  @override
  String get sitterTestimonial3Name => 'Dewi';

  @override
  String get sitterTestimonial3Role => 'Vet';

  @override
  String get sitterTestimonial3City => 'Jakarta';

  @override
  String get sitterTestimonial3Quote =>
      'Much more flexible now. Owners are happy because their pets don\'t have to stress out at the clinic.';

  @override
  String get ownerStoriesTitle => 'Pet Owner Stories';

  @override
  String get ownerStory1Name => 'Maya';

  @override
  String get ownerStory1Subtitle => 'Milo\'s owner';

  @override
  String get ownerStory1Quote =>
      'Milo is hyperactive and hard to leave during work hours. Since using Kaki Empat, someone walks him every afternoon. He doesn\'t destroy the sofa anymore!';

  @override
  String get ownerStory2Name => 'Alex';

  @override
  String get ownerStory2Subtitle => 'Expat in Bali';

  @override
  String get ownerStory2Quote =>
      'I was worried leaving my dog at a pet hotel. But the sitter sent me photos every hour. I could enjoy my vacation without feeling guilty.';

  @override
  String get ownerStory3Name => 'Sari';

  @override
  String get ownerStory3Subtitle => 'Jakarta';

  @override
  String get ownerStory3Quote =>
      'My cat needs regular grooming but I hate going to the salon. A sitter comes to my home and finishes in an hour. Happy cat, happy me!';

  @override
  String get storiFeedTitle => 'Daily Stories';

  @override
  String get storiFeedSubtitle => 'What partner sitters are up to';

  @override
  String get storiViewFeed => 'View daily stories';

  @override
  String get storiPost1Author => 'Putri · Dog Walker';

  @override
  String get storiPost1Caption =>
      'Morning walk with Milo 🐕. He was so happy meeting new friends at the park.';

  @override
  String get storiPost2Author => 'Rian · Grooming';

  @override
  String get storiPost2Caption =>
      'Today\'s grooming result! Coco is sparkling now ✨✂️';

  @override
  String get storiPost3Author => 'Dewi · Vet';

  @override
  String get storiPost3Caption =>
      'Home visit for Mrs. Sari. Her cat was so sweet and calm when given vitamins.';

  @override
  String get storiPost4Author => 'Andi · Pet Taxi';

  @override
  String get storiPost4Caption =>
      'First pet taxi ride! Picked up Max from the vet — he stayed calm the whole trip 🚗';

  @override
  String get storiTime2h => '2 hours ago';

  @override
  String get storiTime5h => '5 hours ago';

  @override
  String get storiTime1d => '1 day ago';

  @override
  String get storiTime2d => '2 days ago';

  @override
  String storiLikes(int count) {
    return '$count likes';
  }

  @override
  String storiComments(int count) {
    return '$count comments';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get badgeVerified => 'Verified';

  @override
  String get sitterReviewsTitle => 'Reviews';

  @override
  String get sitterReviewsEmpty => 'No reviews yet.';

  @override
  String get reviewNoComment => 'No comment';

  @override
  String get helpFaqTitle => 'FAQ';

  @override
  String get faqSearchHint => 'Search questions...';

  @override
  String get helpRepeatTutorial => 'Repeat quick tutorial';

  @override
  String get faqNoResults => 'No matching questions.';

  @override
  String get faqQ1 => 'How do I create a booking request?';

  @override
  String get faqA1 =>
      'Pick a service on home, fill schedule and pet details, then submit. Sitters will send price offers.';

  @override
  String get faqQ2 => 'How do I pick the best sitter?';

  @override
  String get faqA2 =>
      'Check Verified badge, rating, reviews, and offer price. Open sitter profile for full review history.';

  @override
  String get faqQ3 => 'How do I pay for a booking?';

  @override
  String get faqA3 =>
      'After accepting an offer, follow the payment guide to Kaki Empat official account. Upload transfer proof.';

  @override
  String get faqQ4 => 'How long is payment verification?';

  @override
  String get faqA4 =>
      'Admin verifies payment proof within 1 business day. You get a notification when approved.';

  @override
  String get faqQ5 => 'How do sitters withdraw earnings?';

  @override
  String get faqA5 =>
      'Open Wallet, enter amount and bank/QRIS destination. Admin processes within 1 business day.';

  @override
  String get faqQ6 => 'What is the platform fee?';

  @override
  String get faqA6 =>
      'Kaki Empat takes 8% of gross sitter income. The remaining 92% is net wallet credit.';

  @override
  String get faqQ7 => 'Can I cancel a booking?';

  @override
  String get faqA7 =>
      'Bookings can be cancelled before service starts. Refund policy depends on current booking stage.';

  @override
  String get faqQ8 => 'When can I leave a review?';

  @override
  String get faqA8 =>
      'After booking is completed, owners can rate 1–5 stars and comment on the booking detail page.';

  @override
  String get faqQ9 => 'What is the loyalty program?';

  @override
  String get faqA9 =>
      'Each completed booking earns +10 points. 100 points redeem Rp 10,000 discount on your profile.';

  @override
  String get faqQ10 => 'How does referral work?';

  @override
  String get faqA10 =>
      'Share your unique code. Referrer gets Rp 20,000 bonus; new user gets 10% off first booking.';

  @override
  String get tipsArticlesTitle => 'Pet Care Tips';

  @override
  String get tipsArticlesSubtitle =>
      'Short articles for pet owners — expandable later.';

  @override
  String get tipsArticle1Title => 'Balanced Dog Nutrition';

  @override
  String get tipsArticle1Summary =>
      'Choose food by age and activity. Avoid excessive human food.';

  @override
  String get tipsArticle2Title => 'Morning Walk Routine';

  @override
  String get tipsArticle2Summary =>
      '20–30 minutes morning walk helps manage dog energy all day.';

  @override
  String get tipsArticle3Title => 'Home Grooming';

  @override
  String get tipsArticle3Summary =>
      'Regular brushing reduces mats and keeps skin healthy.';

  @override
  String get tipsArticle4Title => 'Vaccines & Deworming';

  @override
  String get tipsArticle4Summary =>
      'Schedule vaccines and deworming per your vet\'s advice.';

  @override
  String get tipsArticle5Title => 'Cat Mental Stimulation';

  @override
  String get tipsArticle5Summary =>
      'Interactive toys and short play sessions reduce indoor cat stress.';

  @override
  String get petGalleryTitle => 'Pet Gallery';

  @override
  String get petGalleryUpload => 'Upload Photo';

  @override
  String get petGalleryEmpty => 'No photos yet. Be the first!';

  @override
  String get petGalleryUploadSuccess => 'Photo uploaded successfully.';

  @override
  String get earningsReportTitle => 'Earnings Report';

  @override
  String get earningsTotalBookings => 'Total bookings';

  @override
  String get earningsAvgRating => 'Average rating';

  @override
  String get earningsNetIncome => 'Net income';

  @override
  String get earningsWeekly => 'Weekly';

  @override
  String get earningsMonthly => 'Monthly';

  @override
  String get earningsNoData => 'No earnings data yet.';

  @override
  String get achievementsTitle => 'Goals & Achievements';

  @override
  String get achievementsEmpty => 'Complete bookings to earn badges!';

  @override
  String get promoTitle => 'Sitter Promotions';

  @override
  String get promoCreate => 'Create Coupon';

  @override
  String get promoEmpty => 'No promo coupons yet.';

  @override
  String get promoCreateSuccess => 'Promo coupon created.';

  @override
  String promoDiscountLabel(int percent) {
    return '$percent% off first booking';
  }

  @override
  String get promoActive => 'Active';

  @override
  String get promoUsed => 'Used';

  @override
  String get sitterVerificationKtp => 'ID card photo';

  @override
  String get sitterVerificationSelfie => 'Selfie with ID';

  @override
  String get sitterVerificationUpload => 'Upload documents';

  @override
  String get sitterVerificationDocsRequired => 'Upload ID and selfie first.';

  @override
  String get loyaltyPointsTitle => 'Loyalty Points';

  @override
  String get loyaltyRedeem => 'Redeem Points';

  @override
  String get referralTitle => 'Referral Code';

  @override
  String get referralShareHint => 'Share this code. You earn Rp 20,000 bonus!';

  @override
  String get adminViewDocuments => 'View documents';

  @override
  String get adminVerificationDocs => 'Document verification';

  @override
  String get ownerMenuCommunity => 'Community';

  @override
  String get ownerMenuHelp => 'Help';

  @override
  String get storiPost5Author => 'Maya · Owner';

  @override
  String get storiPost5Caption => 'Milo loved the morning walk with sitter 🐾';

  @override
  String get storiPost6Author => 'Budi · Dog Walker';

  @override
  String get storiPost6Caption =>
      'Sit and stay training — great progress today!';

  @override
  String get storiPost7Author => 'Sari · Owner';

  @override
  String get storiPost7Caption => 'Belang got groomed today, shiny coat ✨';

  @override
  String get storiPost8Author => 'Lia · Boarding';

  @override
  String get storiPost8Caption => 'New boarding guest: cute Coco 🏠';

  @override
  String get storiPost9Author => 'Hendra · Owner';

  @override
  String get storiPost9Caption =>
      'First booking on Kaki Empat — smooth experience!';

  @override
  String get storiPost10Author => 'Nina · Grooming';

  @override
  String get storiPost10Caption => 'Tip: brush before bath to reduce mats 🛁';

  @override
  String get storiTime3d => '3 days ago';

  @override
  String get storiTime4d => '4 days ago';

  @override
  String get storiTime1w => '1 week ago';

  @override
  String get adminTabLaunch => 'Launch';

  @override
  String launchMetricsPhaseTitle(String current, String next) {
    return 'Phase $current → $next';
  }

  @override
  String get launchMetricsReadyBody =>
      'All exit criteria met. You may advance to the next launch phase in MvpScope.';

  @override
  String get launchMetricsNotReadyBody =>
      'Some exit criteria are not met yet. Stabilize the owner funnel before advancing.';

  @override
  String launchMetricsPendingPayments(int count) {
    return '$count payment proofs awaiting admin approval.';
  }

  @override
  String get launchMetricsChecksTitle => 'Exit criteria (30 days)';

  @override
  String get launchMetricUnitHours => 'hours';

  @override
  String launchMetricsSnapshot(int completed, int sitters, int total) {
    return 'Snapshot: $completed completed · $sitters verified sitters · $total bookings (non-cancelled)';
  }

  @override
  String get appSwitcherTooltip => 'Switch app';

  @override
  String get appSwitcherOwner => 'Owner app';

  @override
  String get appSwitcherSitter => 'Sitter app';

  @override
  String get appSwitcherAdmin => 'Admin panel';

  @override
  String get appShellHome => 'Home';

  @override
  String get appShellBookings => 'Bookings';

  @override
  String get appShellMessages => 'Messages';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverEmpty => 'No partner services yet.';

  @override
  String get discoverBusinessesTitle => 'Verified business partners';

  @override
  String get discoverServicesTitle => 'Partner mini-services';

  @override
  String get discoverComingSoon =>
      'Partner services unlock in the full launch phase.';

  @override
  String get growthHubTitle => 'Growth ecosystem';

  @override
  String get growthHubSubtitle => 'Community, loyalty, and pet care tips';

  @override
  String get growthHubGallery => 'Pet gallery';

  @override
  String get growthHubStori => 'Stories';

  @override
  String get growthHubTips => 'Tips';

  @override
  String get ownerRecommendationsTitle => 'Recommended for you';

  @override
  String ownerOffersForRequest(String service, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
    );
    return '$service · $_temp0';
  }

  @override
  String get offerBestValue => 'Best value';

  @override
  String get referralCopyAction => 'Copy referral code';

  @override
  String get referralCopied => 'Referral code copied';

  @override
  String get appShellProfile => 'Profile';

  @override
  String get petTimelineTitle => 'Pet timeline';

  @override
  String get petTimelineSubtitle => 'Activity history';

  @override
  String get petTimelineEmpty => 'No activity yet for this pet.';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterBooking => 'Bookings';

  @override
  String get notificationsFilterPayment => 'Payments';

  @override
  String get notificationsFilterChat => 'Chat';

  @override
  String get notificationsFilterLoyalty => 'Loyalty';

  @override
  String get categoryFormHealthTitle => 'Health visit details';

  @override
  String get categoryFormHealthSymptoms => 'Symptoms or concerns';

  @override
  String get categoryFormHealthUrgent => 'Urgent — needs same-day attention';

  @override
  String get categoryFormGroomingTitle => 'Grooming preferences';

  @override
  String get categoryFormGroomingPackage => 'Package or style';

  @override
  String get categoryFormGroomingPackageHint =>
      'e.g. full bath, nail trim, breed cut';

  @override
  String get categoryFormTransportTitle => 'Transport details';

  @override
  String get categoryFormTransportPickup => 'Pickup address';

  @override
  String get categoryFormTransportDropoff => 'Drop-off address';

  @override
  String get categoryFormTransportCrate => 'Crate size';

  @override
  String get categorySupplyUnavailable =>
      'This service category is not yet available in your area.';

  @override
  String get appSwitcherPartner => 'Partner dashboard';
}
