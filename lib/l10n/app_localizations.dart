import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Kaki Empat'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In id, this message translates to:
  /// **'Butuh pengasuh atau ingin jadi mitra?'**
  String get tagline;

  /// No description provided for @wwwOwnerCta.
  ///
  /// In id, this message translates to:
  /// **'Cari Pengasuh'**
  String get wwwOwnerCta;

  /// No description provided for @wwwPartnerCta.
  ///
  /// In id, this message translates to:
  /// **'Jadi Pengasuh'**
  String get wwwPartnerCta;

  /// No description provided for @wwwHeroTitle.
  ///
  /// In id, this message translates to:
  /// **'Hewanmu bahagia, kamu tenang. Kami temukan pengasuh terbaik di dekatmu.'**
  String get wwwHeroTitle;

  /// No description provided for @wwwHeroSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Dari jalan pagi sampai menginap, semua ada. Sitter sudah terverifikasi, kamu tinggal pilih.'**
  String get wwwHeroSubtitle;

  /// No description provided for @wwwValueVerified.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh terverifikasi'**
  String get wwwValueVerified;

  /// No description provided for @wwwValueTransparent.
  ///
  /// In id, this message translates to:
  /// **'Biaya transparan'**
  String get wwwValueTransparent;

  /// No description provided for @wwwValueSecure.
  ///
  /// In id, this message translates to:
  /// **'Aman & terpercaya'**
  String get wwwValueSecure;

  /// No description provided for @wwwServicesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Satu platform untuk semua kebutuhan hewan peliharaan Anda.'**
  String get wwwServicesSubtitle;

  /// No description provided for @wwwHowItWorksTitle.
  ///
  /// In id, this message translates to:
  /// **'Cara kerja'**
  String get wwwHowItWorksTitle;

  /// No description provided for @wwwHowStep1.
  ///
  /// In id, this message translates to:
  /// **'Daftar & buat profil hewan'**
  String get wwwHowStep1;

  /// No description provided for @wwwHowStep2.
  ///
  /// In id, this message translates to:
  /// **'Pilih pengasuh terdekat'**
  String get wwwHowStep2;

  /// No description provided for @wwwHowStep3.
  ///
  /// In id, this message translates to:
  /// **'Booking & bayar di aplikasi'**
  String get wwwHowStep3;

  /// No description provided for @subdomainComingSoonTitle.
  ///
  /// In id, this message translates to:
  /// **'{app} — segera hadir'**
  String subdomainComingSoonTitle(String app);

  /// No description provided for @subdomainComingSoonBody.
  ///
  /// In id, this message translates to:
  /// **'Kami meluncurkan fitur secara bertahap. Mulai booking layanan lewat aplikasi Pemilik Hewan.'**
  String get subdomainComingSoonBody;

  /// No description provided for @subdomainComingSoonOwnerCta.
  ///
  /// In id, this message translates to:
  /// **'Buka aplikasi Pemilik'**
  String get subdomainComingSoonOwnerCta;

  /// No description provided for @ownerActionOffersBanner.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{1 permintaan punya penawaran baru} other{{count} permintaan punya penawaran baru}}'**
  String ownerActionOffersBanner(int count);

  /// No description provided for @ownerActionOffersBannerBody.
  ///
  /// In id, this message translates to:
  /// **'Terima penawaran untuk lanjut ke pembayaran dan konfirmasi jadwal.'**
  String get ownerActionOffersBannerBody;

  /// No description provided for @ownerViewOffers.
  ///
  /// In id, this message translates to:
  /// **'Lihat penawaran'**
  String get ownerViewOffers;

  /// No description provided for @wwwOwnerCtaLong.
  ///
  /// In id, this message translates to:
  /// **'Saya Pemilik Hewan'**
  String get wwwOwnerCtaLong;

  /// No description provided for @wwwPartnerCtaLong.
  ///
  /// In id, this message translates to:
  /// **'Saya Calon Pengasuh'**
  String get wwwPartnerCtaLong;

  /// No description provided for @wwwServicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get wwwServicesTitle;

  /// No description provided for @wwwServiceWalkingTitle.
  ///
  /// In id, this message translates to:
  /// **'Dog Walking'**
  String get wwwServiceWalkingTitle;

  /// No description provided for @wwwServiceWalkingDesc.
  ///
  /// In id, this message translates to:
  /// **'Jalan-jalan rutin dengan pengasuh berpengalaman.'**
  String get wwwServiceWalkingDesc;

  /// No description provided for @wwwServiceSittingTitle.
  ///
  /// In id, this message translates to:
  /// **'Pet Sitting'**
  String get wwwServiceSittingTitle;

  /// No description provided for @wwwServiceSittingDesc.
  ///
  /// In id, this message translates to:
  /// **'Perawatan di rumah Anda saat Anda bepergian.'**
  String get wwwServiceSittingDesc;

  /// No description provided for @wwwServiceGroomingTitle.
  ///
  /// In id, this message translates to:
  /// **'Grooming'**
  String get wwwServiceGroomingTitle;

  /// No description provided for @wwwServiceGroomingDesc.
  ///
  /// In id, this message translates to:
  /// **'Mandi, potong kuku, dan perawatan dasar.'**
  String get wwwServiceGroomingDesc;

  /// No description provided for @wwwServiceTrainingTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelatihan'**
  String get wwwServiceTrainingTitle;

  /// No description provided for @wwwServiceTrainingDesc.
  ///
  /// In id, this message translates to:
  /// **'Sesi pelatihan dasar dan sosialisasi.'**
  String get wwwServiceTrainingDesc;

  /// No description provided for @wwwPricingTitle.
  ///
  /// In id, this message translates to:
  /// **'Harga & biaya platform'**
  String get wwwPricingTitle;

  /// No description provided for @wwwPricingOwnerNote.
  ///
  /// In id, this message translates to:
  /// **'Pemilik membayar harga layanan + biaya platform 5%.'**
  String get wwwPricingOwnerNote;

  /// No description provided for @wwwPricingSitterNote.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh menerima harga layanan − biaya platform 8%. Pencairan < 1 hari.'**
  String get wwwPricingSitterNote;

  /// No description provided for @wwwTestimonialsTitle.
  ///
  /// In id, this message translates to:
  /// **'Testimoni'**
  String get wwwTestimonialsTitle;

  /// No description provided for @wwwTestimonial1Name.
  ///
  /// In id, this message translates to:
  /// **'Rina, Jakarta'**
  String get wwwTestimonial1Name;

  /// No description provided for @wwwTestimonial1Quote.
  ///
  /// In id, this message translates to:
  /// **'Mudah cari pengasuh untuk kucing saya. Proses booking dan bayar jelas.'**
  String get wwwTestimonial1Quote;

  /// No description provided for @wwwTestimonial2Name.
  ///
  /// In id, this message translates to:
  /// **'Budi, Bandung'**
  String get wwwTestimonial2Name;

  /// No description provided for @wwwTestimonial2Quote.
  ///
  /// In id, this message translates to:
  /// **'Sebagai sitter, pendapatan masuk cepat dan klien ramah.'**
  String get wwwTestimonial2Quote;

  /// No description provided for @wwwTestimonial3Name.
  ///
  /// In id, this message translates to:
  /// **'Dewi, Surabaya'**
  String get wwwTestimonial3Name;

  /// No description provided for @wwwTestimonial3Quote.
  ///
  /// In id, this message translates to:
  /// **'Anjing saya senang setiap kali jalan dengan pengasuh dari Kaki Empat.'**
  String get wwwTestimonial3Quote;

  /// No description provided for @wwwCtaTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap mulai?'**
  String get wwwCtaTitle;

  /// No description provided for @wwwCtaSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar sebagai pemilik hewan atau ajukan diri jadi mitra pengasuh.'**
  String get wwwCtaSubtitle;

  /// No description provided for @wwwSignupSitterTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar jadi mitra pengasuh'**
  String get wwwSignupSitterTitle;

  /// No description provided for @wwwSignupSitterDesc.
  ///
  /// In id, this message translates to:
  /// **'Isi formulir di bawah. Setelah daftar, lanjutkan ke portal pengasuh untuk lengkapi profil dan verifikasi.'**
  String get wwwSignupSitterDesc;

  /// No description provided for @wwwSignupSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pendaftaran berhasil! Lanjut ke portal pengasuh untuk melengkapi profil.'**
  String get wwwSignupSuccess;

  /// No description provided for @wwwSignupGoSitter.
  ///
  /// In id, this message translates to:
  /// **'Buka portal pengasuh'**
  String get wwwSignupGoSitter;

  /// No description provided for @wwwBlogTitle.
  ///
  /// In id, this message translates to:
  /// **'Tips & info'**
  String get wwwBlogTitle;

  /// No description provided for @wwwBlog1Title.
  ///
  /// In id, this message translates to:
  /// **'Cara memilih pengasuh yang tepat'**
  String get wwwBlog1Title;

  /// No description provided for @wwwBlog1Desc.
  ///
  /// In id, this message translates to:
  /// **'Periksa ulasan, layanan yang ditawarkan, dan jarak dari lokasi Anda.'**
  String get wwwBlog1Desc;

  /// No description provided for @wwwBlog2Title.
  ///
  /// In id, this message translates to:
  /// **'Persiapan hewan sebelum booking'**
  String get wwwBlog2Title;

  /// No description provided for @wwwBlog2Desc.
  ///
  /// In id, this message translates to:
  /// **'Catat kebiasaan makan, alergi, dan kontak dokter hewan di profil hewan.'**
  String get wwwBlog2Desc;

  /// No description provided for @ownerLoginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk - Pemilik Hewan'**
  String get ownerLoginTitle;

  /// No description provided for @ownerHomePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Dashboard Pemilik'**
  String get ownerHomePlaceholder;

  /// No description provided for @sitterHero.
  ///
  /// In id, this message translates to:
  /// **'Kamu sayang hewan? Dapatkan penghasilan dari sini.'**
  String get sitterHero;

  /// No description provided for @sitterLandingSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Tentukan sendiri jadwal dan harga. Komisi cuma 8%. Uang langsung masuk wallet, bisa ditarik kapan saja.'**
  String get sitterLandingSubtitle;

  /// No description provided for @sitterStartNow.
  ///
  /// In id, this message translates to:
  /// **'Mulai Sekarang'**
  String get sitterStartNow;

  /// No description provided for @sitterBenefitsLine.
  ///
  /// In id, this message translates to:
  /// **'🕐 Fleksibel • 💰 Komisi 8% • ⚡ Cair < 1 hari'**
  String get sitterBenefitsLine;

  /// No description provided for @sitterTestimonial1Name.
  ///
  /// In id, this message translates to:
  /// **'Putri'**
  String get sitterTestimonial1Name;

  /// No description provided for @sitterTestimonial1Quote.
  ///
  /// In id, this message translates to:
  /// **'Awalnya cuma coba-coba, sekarang tiap minggu pasti ada aja yang booking. Paling seneng bisa sambil olahraga, bonusnya dapet duit!'**
  String get sitterTestimonial1Quote;

  /// No description provided for @sitterTestimonial2Name.
  ///
  /// In id, this message translates to:
  /// **'Rian'**
  String get sitterTestimonial2Name;

  /// No description provided for @sitterTestimonial2Quote.
  ///
  /// In id, this message translates to:
  /// **'Alat grooming udah numpuk di rumah, eh ternyata banyak yang butuh jasa grooming panggilan. Sekarang aku bisa buka layanan dari rumah.'**
  String get sitterTestimonial2Quote;

  /// No description provided for @sitterHeroSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Komisi hanya 8%, pencairan kurang dari 1 hari, kerja fleksibel sesuai waktumu.'**
  String get sitterHeroSubtitle;

  /// No description provided for @sitterStatActive.
  ///
  /// In id, this message translates to:
  /// **'50+ sitter aktif'**
  String get sitterStatActive;

  /// No description provided for @sitterStatBookings.
  ///
  /// In id, this message translates to:
  /// **'10+ booking/bulan'**
  String get sitterStatBookings;

  /// No description provided for @sitterBadgeNew.
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get sitterBadgeNew;

  /// No description provided for @sitterNewRequestsSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Ada {count} permintaan baru di sekitarmu'**
  String sitterNewRequestsSubtitle(int count);

  /// No description provided for @sitterPlatformFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya platform 8%'**
  String get sitterPlatformFee;

  /// No description provided for @sitterPayout.
  ///
  /// In id, this message translates to:
  /// **'Pencairan < 1 hari'**
  String get sitterPayout;

  /// No description provided for @sitterRegisterCta.
  ///
  /// In id, this message translates to:
  /// **'Daftar Jadi Mitra'**
  String get sitterRegisterCta;

  /// No description provided for @adminLoginTitle.
  ///
  /// In id, this message translates to:
  /// **'Panel Admin'**
  String get adminLoginTitle;

  /// No description provided for @adminPanelPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Panel Admin - Coming Soon'**
  String get adminPanelPlaceholder;

  /// No description provided for @authLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get authRegister;

  /// No description provided for @authPhone.
  ///
  /// In id, this message translates to:
  /// **'Nomor WA'**
  String get authPhone;

  /// No description provided for @authPhoneHint.
  ///
  /// In id, this message translates to:
  /// **'0812, 62812, atau +62812'**
  String get authPhoneHint;

  /// No description provided for @authPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Min. 6 karakter'**
  String get authPasswordHint;

  /// No description provided for @authName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get authName;

  /// No description provided for @authRole.
  ///
  /// In id, this message translates to:
  /// **'Pilih peran'**
  String get authRole;

  /// No description provided for @authRoleOwner.
  ///
  /// In id, this message translates to:
  /// **'Pemilik hewan'**
  String get authRoleOwner;

  /// No description provided for @authRoleSitter.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh'**
  String get authRoleSitter;

  /// No description provided for @authNoAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun?'**
  String get authHasAccount;

  /// No description provided for @authInvalidPhone.
  ///
  /// In id, this message translates to:
  /// **'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi minimal 6 karakter.'**
  String get authInvalidPassword;

  /// No description provided for @authNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi.'**
  String get authNameRequired;

  /// No description provided for @authFailed.
  ///
  /// In id, this message translates to:
  /// **'Permintaan gagal. Coba lagi.'**
  String get authFailed;

  /// No description provided for @authLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get authLogout;

  /// No description provided for @authForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nomor WA terdaftar. Kode reset dikirim ke notifikasi in-app Anda.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authSendResetCode.
  ///
  /// In id, this message translates to:
  /// **'Kirim kode reset'**
  String get authSendResetCode;

  /// No description provided for @authHaveResetCode.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya kode reset?'**
  String get authHaveResetCode;

  /// No description provided for @authBackToLogin.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke masuk'**
  String get authBackToLogin;

  /// No description provided for @authResetPassword.
  ///
  /// In id, this message translates to:
  /// **'Reset kata sandi'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Masukkan nomor, kode reset dari notifikasi, dan kata sandi baru.'**
  String get authResetPasswordSubtitle;

  /// No description provided for @authResetCode.
  ///
  /// In id, this message translates to:
  /// **'Kode reset'**
  String get authResetCode;

  /// No description provided for @authResetCodeRequired.
  ///
  /// In id, this message translates to:
  /// **'Kode reset wajib diisi.'**
  String get authResetCodeRequired;

  /// No description provided for @authNewPassword.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru'**
  String get authNewPassword;

  /// No description provided for @authResetSuccess.
  ///
  /// In id, this message translates to:
  /// **'Kata sandi berhasil diubah. Silakan masuk.'**
  String get authResetSuccess;

  /// No description provided for @wwwOpenApp.
  ///
  /// In id, this message translates to:
  /// **'Buka aplikasi'**
  String get wwwOpenApp;

  /// No description provided for @authAccessDenied.
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak untuk domain ini.'**
  String get authAccessDenied;

  /// No description provided for @actionSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get actionSave;

  /// No description provided for @actionNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjut ke Dashboard'**
  String get actionContinue;

  /// No description provided for @actionEditProfile.
  ///
  /// In id, this message translates to:
  /// **'Edit Profil'**
  String get actionEditProfile;

  /// No description provided for @loadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data. Tarik untuk muat ulang.'**
  String get loadFailed;

  /// No description provided for @saveFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan. Coba lagi.'**
  String get saveFailed;

  /// No description provided for @sitterOnboardingTitle.
  ///
  /// In id, this message translates to:
  /// **'Onboarding Pengasuh'**
  String get sitterOnboardingTitle;

  /// No description provided for @sitterOnboardingStepServices.
  ///
  /// In id, this message translates to:
  /// **'Pilih Layanan'**
  String get sitterOnboardingStepServices;

  /// No description provided for @sitterOnboardingStepProfile.
  ///
  /// In id, this message translates to:
  /// **'Isi Profil'**
  String get sitterOnboardingStepProfile;

  /// No description provided for @sitterOnboardingStepVerify.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi'**
  String get sitterOnboardingStepVerify;

  /// No description provided for @sitterOnboardingSelectServices.
  ///
  /// In id, this message translates to:
  /// **'Pilih layanan yang Anda tawarkan'**
  String get sitterOnboardingSelectServices;

  /// No description provided for @sitterOnboardingServicesRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal satu layanan.'**
  String get sitterOnboardingServicesRequired;

  /// No description provided for @sitterOnboardingBio.
  ///
  /// In id, this message translates to:
  /// **'Cerita & pengalaman'**
  String get sitterOnboardingBio;

  /// No description provided for @sitterOnboardingAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get sitterOnboardingAddress;

  /// No description provided for @sitterOnboardingAddressRequired.
  ///
  /// In id, this message translates to:
  /// **'Alamat wajib diisi.'**
  String get sitterOnboardingAddressRequired;

  /// No description provided for @sitterOnboardingBioRequired.
  ///
  /// In id, this message translates to:
  /// **'Bio wajib diisi.'**
  String get sitterOnboardingBioRequired;

  /// No description provided for @sitterOnboardingSubmit.
  ///
  /// In id, this message translates to:
  /// **'Ajukan Verifikasi'**
  String get sitterOnboardingSubmit;

  /// No description provided for @sitterOnboardingWaitingTitle.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Verifikasi'**
  String get sitterOnboardingWaitingTitle;

  /// No description provided for @sitterOnboardingWaitingMessage.
  ///
  /// In id, this message translates to:
  /// **'Profil Anda sedang ditinjau tim Kaki Empat. Kami akan memberi tahu setelah disetujui.'**
  String get sitterOnboardingWaitingMessage;

  /// No description provided for @sitterHomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Beranda Pengasuh'**
  String get sitterHomeTitle;

  /// No description provided for @sitterGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, {name}! 🌟 Ada {count} permintaan baru di dekatmu.'**
  String sitterGreeting(String name, int count);

  /// No description provided for @sitterGreetingNoRequests.
  ///
  /// In id, this message translates to:
  /// **'Halo, {name}! 🌟 Siap menerima permintaan hari ini?'**
  String sitterGreetingNoRequests(String name);

  /// No description provided for @sitterMonthlyEarnings.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini: {amount}'**
  String sitterMonthlyEarnings(String amount);

  /// No description provided for @sitterOfferPrice.
  ///
  /// In id, this message translates to:
  /// **'Tawarkan Harga'**
  String get sitterOfferPrice;

  /// No description provided for @sitterRequestDistanceFromYou.
  ///
  /// In id, this message translates to:
  /// **'📍 {km} km dari kamu'**
  String sitterRequestDistanceFromYou(String km);

  /// No description provided for @sitterHomePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang! Dashboard pengasuh akan segera hadir di sini.'**
  String get sitterHomePlaceholder;

  /// No description provided for @sitterProfileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil Pengasuh'**
  String get sitterProfileTitle;

  /// No description provided for @sitterProfileBio.
  ///
  /// In id, this message translates to:
  /// **'Bio'**
  String get sitterProfileBio;

  /// No description provided for @sitterProfileAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get sitterProfileAddress;

  /// No description provided for @sitterProfileServices.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get sitterProfileServices;

  /// No description provided for @sitterProfileStatus.
  ///
  /// In id, this message translates to:
  /// **'Status verifikasi'**
  String get sitterProfileStatus;

  /// No description provided for @sitterStatusDraft.
  ///
  /// In id, this message translates to:
  /// **'Draft'**
  String get sitterStatusDraft;

  /// No description provided for @sitterStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu verifikasi'**
  String get sitterStatusPending;

  /// No description provided for @sitterStatusApproved.
  ///
  /// In id, this message translates to:
  /// **'Disetujui'**
  String get sitterStatusApproved;

  /// No description provided for @sitterStatusRejected.
  ///
  /// In id, this message translates to:
  /// **'Ditolak'**
  String get sitterStatusRejected;

  /// No description provided for @ownerProfileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil Pemilik'**
  String get ownerProfileTitle;

  /// No description provided for @ownerProfileOnboardingHint.
  ///
  /// In id, this message translates to:
  /// **'Isi alamat dan tambahkan minimal satu hewan untuk mulai memesan layanan.'**
  String get ownerProfileOnboardingHint;

  /// No description provided for @ownerProfileAddress.
  ///
  /// In id, this message translates to:
  /// **'Alamat rumah'**
  String get ownerProfileAddress;

  /// No description provided for @ownerProfileAddressEmpty.
  ///
  /// In id, this message translates to:
  /// **'Alamat belum diisi'**
  String get ownerProfileAddressEmpty;

  /// No description provided for @ownerProfileAddressHint.
  ///
  /// In id, this message translates to:
  /// **'Alamat digunakan untuk layanan di lokasi Anda.'**
  String get ownerProfileAddressHint;

  /// No description provided for @ownerProfilePets.
  ///
  /// In id, this message translates to:
  /// **'Hewan Peliharaan'**
  String get ownerProfilePets;

  /// No description provided for @ownerProfilePetsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada hewan terdaftar.'**
  String get ownerProfilePetsEmpty;

  /// No description provided for @ownerProfileAddPet.
  ///
  /// In id, this message translates to:
  /// **'Tambah Hewan'**
  String get ownerProfileAddPet;

  /// No description provided for @addPetTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Hewan'**
  String get addPetTitle;

  /// No description provided for @petName.
  ///
  /// In id, this message translates to:
  /// **'Nama hewan'**
  String get petName;

  /// No description provided for @petSpecies.
  ///
  /// In id, this message translates to:
  /// **'Spesies'**
  String get petSpecies;

  /// No description provided for @petSpeciesHint.
  ///
  /// In id, this message translates to:
  /// **'Anjing, kucing, dll.'**
  String get petSpeciesHint;

  /// No description provided for @petBreed.
  ///
  /// In id, this message translates to:
  /// **'Ras'**
  String get petBreed;

  /// No description provided for @petAge.
  ///
  /// In id, this message translates to:
  /// **'Usia'**
  String get petAge;

  /// No description provided for @petWeight.
  ///
  /// In id, this message translates to:
  /// **'Berat (kg)'**
  String get petWeight;

  /// No description provided for @petNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan perilaku'**
  String get petNotes;

  /// No description provided for @petNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi.'**
  String get petNameRequired;

  /// No description provided for @petSpeciesRequired.
  ///
  /// In id, this message translates to:
  /// **'Spesies wajib diisi.'**
  String get petSpeciesRequired;

  /// No description provided for @catalogLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat katalog layanan.'**
  String get catalogLoadFailed;

  /// No description provided for @valueEmpty.
  ///
  /// In id, this message translates to:
  /// **'—'**
  String get valueEmpty;

  /// No description provided for @ownerHomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get ownerHomeTitle;

  /// No description provided for @ownerHomeSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Layanan Populer'**
  String get ownerHomeSubtitle;

  /// No description provided for @ownerGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, {name}! 🐾 Mau ajak siapa hari ini?'**
  String ownerGreeting(String name);

  /// No description provided for @ownerViewAllServices.
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua Layanan'**
  String get ownerViewAllServices;

  /// No description provided for @ownerActiveBookings.
  ///
  /// In id, this message translates to:
  /// **'Booking Aktif'**
  String get ownerActiveBookings;

  /// No description provided for @ownerPetQuickWalk.
  ///
  /// In id, this message translates to:
  /// **'Jalan pagi'**
  String get ownerPetQuickWalk;

  /// No description provided for @ownerPetQuickBath.
  ///
  /// In id, this message translates to:
  /// **'Mandi'**
  String get ownerPetQuickBath;

  /// No description provided for @ownerPetQuickCheckup.
  ///
  /// In id, this message translates to:
  /// **'Periksa'**
  String get ownerPetQuickCheckup;

  /// No description provided for @ownerGreetingSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Mau ajak jalan siapa hari ini?'**
  String get ownerGreetingSubtitle;

  /// No description provided for @ownerActiveBookingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Booking Aktif'**
  String get ownerActiveBookingsTitle;

  /// No description provided for @ownerActiveBookingsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada booking aktif.'**
  String get ownerActiveBookingsEmpty;

  /// No description provided for @ownerFavoriteSittersTitle.
  ///
  /// In id, this message translates to:
  /// **'Sitter Favorit'**
  String get ownerFavoriteSittersTitle;

  /// No description provided for @ownerFavoriteSittersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada sitter favorit. Simpan dari penawaran masuk.'**
  String get ownerFavoriteSittersEmpty;

  /// No description provided for @ownerCategoryServiceCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{1 layanan} other{{count} layanan}}'**
  String ownerCategoryServiceCount(int count);

  /// No description provided for @ownerServicesInCategory.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get ownerServicesInCategory;

  /// No description provided for @ownerMyBookings.
  ///
  /// In id, this message translates to:
  /// **'Booking Saya'**
  String get ownerMyBookings;

  /// No description provided for @ownerOnboardingBannerTitle.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi profil Anda'**
  String get ownerOnboardingBannerTitle;

  /// No description provided for @ownerOnboardingBannerBody.
  ///
  /// In id, this message translates to:
  /// **'Isi alamat dan tambahkan minimal satu hewan sebelum memesan.'**
  String get ownerOnboardingBannerBody;

  /// No description provided for @ownerFillAddress.
  ///
  /// In id, this message translates to:
  /// **'Isi Alamat'**
  String get ownerFillAddress;

  /// No description provided for @ownerAddPet.
  ///
  /// In id, this message translates to:
  /// **'Tambah Hewan'**
  String get ownerAddPet;

  /// No description provided for @createRequestTitle.
  ///
  /// In id, this message translates to:
  /// **'Cari Pengasuh'**
  String get createRequestTitle;

  /// No description provided for @createRequestPet.
  ///
  /// In id, this message translates to:
  /// **'Pilih hewan'**
  String get createRequestPet;

  /// No description provided for @createRequestDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get createRequestDate;

  /// No description provided for @createRequestTime.
  ///
  /// In id, this message translates to:
  /// **'Waktu mulai'**
  String get createRequestTime;

  /// No description provided for @createRequestDuration.
  ///
  /// In id, this message translates to:
  /// **'Durasi'**
  String get createRequestDuration;

  /// No description provided for @createRequestDurationHours.
  ///
  /// In id, this message translates to:
  /// **'{hours, plural, =1{1 jam} other{{hours} jam}}'**
  String createRequestDurationHours(int hours);

  /// No description provided for @createRequestLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi'**
  String get createRequestLocation;

  /// No description provided for @createRequestNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get createRequestNotes;

  /// No description provided for @createRequestPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga yang ditawarkan (Rp)'**
  String get createRequestPrice;

  /// No description provided for @createRequestSubmit.
  ///
  /// In id, this message translates to:
  /// **'Cari Pengasuh'**
  String get createRequestSubmit;

  /// No description provided for @createRequestSuccess.
  ///
  /// In id, this message translates to:
  /// **'✅ Booking berhasil! Sitter akan segera merespons.'**
  String get createRequestSuccess;

  /// No description provided for @ownerOpenRequestsTitle.
  ///
  /// In id, this message translates to:
  /// **'Permintaan Aktif'**
  String get ownerOpenRequestsTitle;

  /// No description provided for @ownerOpenRequestsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada permintaan terbuka.'**
  String get ownerOpenRequestsEmpty;

  /// No description provided for @ownerPendingOffers.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Tidak ada penawaran} =1{1 penawaran} other{{count} penawaran}}'**
  String ownerPendingOffers(int count);

  /// No description provided for @ownerRequestOffersTitle.
  ///
  /// In id, this message translates to:
  /// **'Penawaran Pengasuh'**
  String get ownerRequestOffersTitle;

  /// No description provided for @ownerRequestOffersHeading.
  ///
  /// In id, this message translates to:
  /// **'Penawaran masuk'**
  String get ownerRequestOffersHeading;

  /// No description provided for @ownerRequestOffersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada penawaran untuk permintaan ini.'**
  String get ownerRequestOffersEmpty;

  /// No description provided for @ownerAcceptOfferTitle.
  ///
  /// In id, this message translates to:
  /// **'Terima Penawaran'**
  String get ownerAcceptOfferTitle;

  /// No description provided for @ownerAcceptOfferConfirm.
  ///
  /// In id, this message translates to:
  /// **'Terima penawaran dari {sitterName} seharga {price}?'**
  String ownerAcceptOfferConfirm(String sitterName, String price);

  /// No description provided for @ownerAcceptOfferAction.
  ///
  /// In id, this message translates to:
  /// **'Terima Penawaran'**
  String get ownerAcceptOfferAction;

  /// No description provided for @ownerAcceptOfferSuccess.
  ///
  /// In id, this message translates to:
  /// **'Penawaran diterima. Booking dibuat.'**
  String get ownerAcceptOfferSuccess;

  /// No description provided for @createRequestSelectPet.
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal satu hewan.'**
  String get createRequestSelectPet;

  /// No description provided for @createRequestSelectDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal.'**
  String get createRequestSelectDate;

  /// No description provided for @createRequestSelectTime.
  ///
  /// In id, this message translates to:
  /// **'Pilih waktu mulai.'**
  String get createRequestSelectTime;

  /// No description provided for @createRequestLocationRequired.
  ///
  /// In id, this message translates to:
  /// **'Lokasi wajib diisi.'**
  String get createRequestLocationRequired;

  /// No description provided for @createRequestServiceRequired.
  ///
  /// In id, this message translates to:
  /// **'Layanan wajib dipilih.'**
  String get createRequestServiceRequired;

  /// No description provided for @createRequestPriceHint.
  ///
  /// In id, this message translates to:
  /// **'Tarif yang Anda tawarkan'**
  String get createRequestPriceHint;

  /// No description provided for @createRequestPriceRequired.
  ///
  /// In id, this message translates to:
  /// **'Harga harus lebih dari nol.'**
  String get createRequestPriceRequired;

  /// No description provided for @ownerProfileLocationHint.
  ///
  /// In id, this message translates to:
  /// **'Izinkan lokasi browser agar pengasuh di sekitar dapat menemukan permintaan Anda.'**
  String get ownerProfileLocationHint;

  /// No description provided for @sitterAvailabilityTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap terima pesanan'**
  String get sitterAvailabilityTitle;

  /// No description provided for @sitterAvailabilityOffHint.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif — permintaan baru tidak ditampilkan.'**
  String get sitterAvailabilityOffHint;

  /// No description provided for @requestSkipOffer.
  ///
  /// In id, this message translates to:
  /// **'Lewati permintaan'**
  String get requestSkipOffer;

  /// No description provided for @sitterRequestsTitle.
  ///
  /// In id, this message translates to:
  /// **'Permintaan Tersedia'**
  String get sitterRequestsTitle;

  /// No description provided for @sitterRequestsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada permintaan di sekitarmu. Cek lagi nanti ☕'**
  String get sitterRequestsEmpty;

  /// No description provided for @sitterFilterService.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get sitterFilterService;

  /// No description provided for @sitterFilterAllServices.
  ///
  /// In id, this message translates to:
  /// **'Semua layanan'**
  String get sitterFilterAllServices;

  /// No description provided for @sitterFilterRadius.
  ///
  /// In id, this message translates to:
  /// **'Radius (km)'**
  String get sitterFilterRadius;

  /// No description provided for @sitterFilterRadiusAll.
  ///
  /// In id, this message translates to:
  /// **'Semua jarak'**
  String get sitterFilterRadiusAll;

  /// No description provided for @sitterRequestDistance.
  ///
  /// In id, this message translates to:
  /// **'{km} km'**
  String sitterRequestDistance(String km);

  /// No description provided for @sitterBroadcastRadiusBadge.
  ///
  /// In id, this message translates to:
  /// **'Dalam Radius 7km'**
  String get sitterBroadcastRadiusBadge;

  /// No description provided for @sitterPollingSearching.
  ///
  /// In id, this message translates to:
  /// **'Mencari permintaan baru...'**
  String get sitterPollingSearching;

  /// No description provided for @sitterNewRequestsBadge.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{1 permintaan baru} other{{count} permintaan baru}}'**
  String sitterNewRequestsBadge(int count);

  /// No description provided for @sitterRequestsInRadius.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Tidak ada permintaan dalam radius} =1{1 permintaan dalam radius} other{{count} permintaan dalam radius}}'**
  String sitterRequestsInRadius(int count);

  /// No description provided for @createRequestSitterEstimate.
  ///
  /// In id, this message translates to:
  /// **'Estimasi ~{count} pengasuh dalam radius 7 km akan melihat permintaan ini'**
  String createRequestSitterEstimate(int count);

  /// No description provided for @createRequestSitterEstimateLoading.
  ///
  /// In id, this message translates to:
  /// **'Menghitung pengasuh terdekat…'**
  String get createRequestSitterEstimateLoading;

  /// No description provided for @createRequestSuccessBroadcast.
  ///
  /// In id, this message translates to:
  /// **'Permintaan dikirim. ~{count} pengasuh dalam radius 7 km akan melihat permintaan ini.'**
  String createRequestSuccessBroadcast(int count);

  /// No description provided for @requestDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Permintaan'**
  String get requestDetailTitle;

  /// No description provided for @requestDetailOwner.
  ///
  /// In id, this message translates to:
  /// **'Pemilik hewan'**
  String get requestDetailOwner;

  /// No description provided for @requestDetailPets.
  ///
  /// In id, this message translates to:
  /// **'Hewan'**
  String get requestDetailPets;

  /// No description provided for @requestDetailSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal'**
  String get requestDetailSchedule;

  /// No description provided for @requestDetailLocation.
  ///
  /// In id, this message translates to:
  /// **'Lokasi'**
  String get requestDetailLocation;

  /// No description provided for @requestDetailNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get requestDetailNotes;

  /// No description provided for @requestDetailPrice.
  ///
  /// In id, this message translates to:
  /// **'Anggaran pemilik'**
  String get requestDetailPrice;

  /// No description provided for @requestOfferPrice.
  ///
  /// In id, this message translates to:
  /// **'Penawaran Anda (Rp)'**
  String get requestOfferPrice;

  /// No description provided for @requestOfferMessage.
  ///
  /// In id, this message translates to:
  /// **'Pesan (opsional)'**
  String get requestOfferMessage;

  /// No description provided for @requestOfferSubmit.
  ///
  /// In id, this message translates to:
  /// **'Tawarkan Harga'**
  String get requestOfferSubmit;

  /// No description provided for @requestOfferSuccess.
  ///
  /// In id, this message translates to:
  /// **'💰 Tawaran terkirim! Menunggu respons pemilik.'**
  String get requestOfferSuccess;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Booking'**
  String get bookingDetailTitle;

  /// No description provided for @bookingDetailStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get bookingDetailStatus;

  /// No description provided for @bookingDetailTimeline.
  ///
  /// In id, this message translates to:
  /// **'Linimasa'**
  String get bookingDetailTimeline;

  /// No description provided for @bookingDetailService.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get bookingDetailService;

  /// No description provided for @bookingDetailSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal'**
  String get bookingDetailSchedule;

  /// No description provided for @bookingDetailAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get bookingDetailAmount;

  /// No description provided for @bookingDetailPay.
  ///
  /// In id, this message translates to:
  /// **'Bayar Sekarang'**
  String get bookingDetailPay;

  /// No description provided for @bookingDetailConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Booking'**
  String get bookingDetailConfirm;

  /// No description provided for @bookingDetailEnRoute.
  ///
  /// In id, this message translates to:
  /// **'Tandai Dalam Perjalanan'**
  String get bookingDetailEnRoute;

  /// No description provided for @bookingDetailStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai Layanan'**
  String get bookingDetailStart;

  /// No description provided for @bookingDetailComplete.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan Layanan'**
  String get bookingDetailComplete;

  /// No description provided for @bookingDetailCancel.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Booking'**
  String get bookingDetailCancel;

  /// No description provided for @bookingDetailActionSuccess.
  ///
  /// In id, this message translates to:
  /// **'Booking diperbarui.'**
  String get bookingDetailActionSuccess;

  /// No description provided for @bookingStatusOpen.
  ///
  /// In id, this message translates to:
  /// **'Menunggu pengasuh'**
  String get bookingStatusOpen;

  /// No description provided for @bookingStatusMatched.
  ///
  /// In id, this message translates to:
  /// **'Sudah ditugaskan'**
  String get bookingStatusMatched;

  /// No description provided for @bookingStatusPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu konfirmasi'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusAwaitingPayment.
  ///
  /// In id, this message translates to:
  /// **'Menunggu pembayaran'**
  String get bookingStatusAwaitingPayment;

  /// No description provided for @bookingStatusPendingVerification.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi pembayaran'**
  String get bookingStatusPendingVerification;

  /// No description provided for @bookingStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get bookingStatusPaid;

  /// No description provided for @bookingStatusPaymentRejected.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran ditolak'**
  String get bookingStatusPaymentRejected;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusEnRoute.
  ///
  /// In id, this message translates to:
  /// **'Dalam perjalanan'**
  String get bookingStatusEnRoute;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In id, this message translates to:
  /// **'Sedang berlangsung'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai 🎉'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingTimelineCreated.
  ///
  /// In id, this message translates to:
  /// **'Permintaan dibuat'**
  String get bookingTimelineCreated;

  /// No description provided for @bookingTimelineMatched.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh ditugaskan'**
  String get bookingTimelineMatched;

  /// No description provided for @bookingTimelinePaid.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran diterima'**
  String get bookingTimelinePaid;

  /// No description provided for @bookingTimelineConfirmed.
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi pengasuh'**
  String get bookingTimelineConfirmed;

  /// No description provided for @bookingTimelineEnRoute.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh dalam perjalanan'**
  String get bookingTimelineEnRoute;

  /// No description provided for @bookingTimelineInProgress.
  ///
  /// In id, this message translates to:
  /// **'Layanan dimulai'**
  String get bookingTimelineInProgress;

  /// No description provided for @bookingTimelineCompleted.
  ///
  /// In id, this message translates to:
  /// **'Layanan selesai'**
  String get bookingTimelineCompleted;

  /// No description provided for @ownerBookingsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada booking'**
  String get ownerBookingsEmpty;

  /// No description provided for @sitterMyBookings.
  ///
  /// In id, this message translates to:
  /// **'Booking Saya'**
  String get sitterMyBookings;

  /// No description provided for @sitterVerificationRequired.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi profil diperlukan untuk melihat permintaan.'**
  String get sitterVerificationRequired;

  /// No description provided for @requestPetCount.
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{1 hewan} other{{count} hewan}}'**
  String requestPetCount(int count);

  /// No description provided for @createRequestTotalPreview.
  ///
  /// In id, this message translates to:
  /// **'Total dibayar: {total} (termasuk biaya platform {fee})'**
  String createRequestTotalPreview(String total, String fee);

  /// No description provided for @actionCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get actionDelete;

  /// No description provided for @bookingDetailCancelConfirm.
  ///
  /// In id, this message translates to:
  /// **'Yakin batalkan booking ini? 🥺'**
  String get bookingDetailCancelConfirm;

  /// No description provided for @sitterActiveBookingsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada booking aktif.'**
  String get sitterActiveBookingsEmpty;

  /// No description provided for @chatTitle.
  ///
  /// In id, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesan'**
  String get chatEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik pesan…'**
  String get chatInputHint;

  /// No description provided for @chatSendFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim pesan. Coba lagi.'**
  String get chatSendFailed;

  /// No description provided for @bookingDetailChat.
  ///
  /// In id, this message translates to:
  /// **'Buka Chat'**
  String get bookingDetailChat;

  /// No description provided for @notificationsTitle.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada notifikasi'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In id, this message translates to:
  /// **'Tandai Semua Dibaca'**
  String get notificationsMarkAllRead;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Panel Admin Kaki Empat'**
  String get adminDashboardTitle;

  /// No description provided for @adminSummarySitters.
  ///
  /// In id, this message translates to:
  /// **'Total Sitter'**
  String get adminSummarySitters;

  /// No description provided for @adminSummaryOwners.
  ///
  /// In id, this message translates to:
  /// **'Total Owner'**
  String get adminSummaryOwners;

  /// No description provided for @adminSummaryBookings.
  ///
  /// In id, this message translates to:
  /// **'Total Booking'**
  String get adminSummaryBookings;

  /// No description provided for @adminSummaryPending.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Pending'**
  String get adminSummaryPending;

  /// No description provided for @adminTabSitters.
  ///
  /// In id, this message translates to:
  /// **'Pengasuh'**
  String get adminTabSitters;

  /// No description provided for @adminTabOwners.
  ///
  /// In id, this message translates to:
  /// **'Pemilik'**
  String get adminTabOwners;

  /// No description provided for @adminTabBookings.
  ///
  /// In id, this message translates to:
  /// **'Booking'**
  String get adminTabBookings;

  /// No description provided for @adminTabWithdrawals.
  ///
  /// In id, this message translates to:
  /// **'Pencairan'**
  String get adminTabWithdrawals;

  /// No description provided for @adminTabPayments.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get adminTabPayments;

  /// No description provided for @adminApprove.
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get adminReject;

  /// No description provided for @adminActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get adminActive;

  /// No description provided for @adminInactive.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get adminInactive;

  /// No description provided for @adminSittersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pengasuh menunggu verifikasi.'**
  String get adminSittersEmpty;

  /// No description provided for @adminOwnersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pemilik terdaftar.'**
  String get adminOwnersEmpty;

  /// No description provided for @adminBookingsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada booking.'**
  String get adminBookingsEmpty;

  /// No description provided for @adminWithdrawalsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada permintaan pencairan pending.'**
  String get adminWithdrawalsEmpty;

  /// No description provided for @adminSitterApproved.
  ///
  /// In id, this message translates to:
  /// **'{name} disetujui'**
  String adminSitterApproved(String name);

  /// No description provided for @adminSitterRejected.
  ///
  /// In id, this message translates to:
  /// **'{name} ditolak'**
  String adminSitterRejected(String name);

  /// No description provided for @adminWithdrawalApproved.
  ///
  /// In id, this message translates to:
  /// **'Pencairan disetujui.'**
  String get adminWithdrawalApproved;

  /// No description provided for @paymentTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get paymentTitle;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In id, this message translates to:
  /// **'WISE / REVOLUT / TRANSFER BANK INTERNASIONAL'**
  String get paymentMethodTitle;

  /// No description provided for @paymentTabWise.
  ///
  /// In id, this message translates to:
  /// **'Wise'**
  String get paymentTabWise;

  /// No description provided for @paymentTabRevolut.
  ///
  /// In id, this message translates to:
  /// **'Revolut'**
  String get paymentTabRevolut;

  /// No description provided for @paymentTabBankTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer Bank'**
  String get paymentTabBankTransfer;

  /// No description provided for @paymentWiseStep1.
  ///
  /// In id, this message translates to:
  /// **'Buka aplikasi Wise di ponsel Anda.'**
  String get paymentWiseStep1;

  /// No description provided for @paymentWiseStep2.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kirim Uang → Transfer internasional → penerima IDR.'**
  String get paymentWiseStep2;

  /// No description provided for @paymentWiseStep3.
  ///
  /// In id, this message translates to:
  /// **'Masukkan detail rekening SeaBank kami di atas.'**
  String get paymentWiseStep3;

  /// No description provided for @paymentWiseStep4.
  ///
  /// In id, this message translates to:
  /// **'Kirim nominal persis seperti di bawah, termasuk kode unik.'**
  String get paymentWiseStep4;

  /// No description provided for @paymentRevolutStep1.
  ///
  /// In id, this message translates to:
  /// **'Buka aplikasi Revolut di ponsel Anda.'**
  String get paymentRevolutStep1;

  /// No description provided for @paymentRevolutStep2.
  ///
  /// In id, this message translates to:
  /// **'Pilih Kirim → Transfer internasional → penerima IDR.'**
  String get paymentRevolutStep2;

  /// No description provided for @paymentRevolutStep3.
  ///
  /// In id, this message translates to:
  /// **'Masukkan detail rekening SeaBank kami di atas.'**
  String get paymentRevolutStep3;

  /// No description provided for @paymentRevolutStep4.
  ///
  /// In id, this message translates to:
  /// **'Kirim nominal persis seperti di bawah, termasuk kode unik.'**
  String get paymentRevolutStep4;

  /// No description provided for @paymentBankStep1.
  ///
  /// In id, this message translates to:
  /// **'Gunakan aplikasi mobile banking atau internet banking Anda.'**
  String get paymentBankStep1;

  /// No description provided for @paymentBankStep2.
  ///
  /// In id, this message translates to:
  /// **'Pilih transfer internasional atau SWIFT ke Indonesia (IDR).'**
  String get paymentBankStep2;

  /// No description provided for @paymentBankStep3.
  ///
  /// In id, this message translates to:
  /// **'Masukkan detail rekening SeaBank kami di atas.'**
  String get paymentBankStep3;

  /// No description provided for @paymentBankStep4.
  ///
  /// In id, this message translates to:
  /// **'Kirim nominal persis seperti di bawah, termasuk kode unik.'**
  String get paymentBankStep4;

  /// No description provided for @paymentMethodDescription.
  ///
  /// In id, this message translates to:
  /// **'Kami menerima transfer peer-to-peer via Wise atau Revolut. Tarif layanan ditambah biaya platform {feePercent}% sudah termasuk di total di bawah.'**
  String paymentMethodDescription(String feePercent);

  /// No description provided for @paymentBankDetailsTitle.
  ///
  /// In id, this message translates to:
  /// **'DETAIL REKENING PENERIMA (INDONESIA)'**
  String get paymentBankDetailsTitle;

  /// No description provided for @paymentBankName.
  ///
  /// In id, this message translates to:
  /// **'Nama Bank'**
  String get paymentBankName;

  /// No description provided for @paymentBankCode.
  ///
  /// In id, this message translates to:
  /// **'Kode Bank'**
  String get paymentBankCode;

  /// No description provided for @paymentAccountNo.
  ///
  /// In id, this message translates to:
  /// **'No. Rekening'**
  String get paymentAccountNo;

  /// No description provided for @paymentAccountName.
  ///
  /// In id, this message translates to:
  /// **'Nama Rekening'**
  String get paymentAccountName;

  /// No description provided for @paymentHowToPay.
  ///
  /// In id, this message translates to:
  /// **'CARA BAYAR'**
  String get paymentHowToPay;

  /// No description provided for @paymentAmountToSend.
  ///
  /// In id, this message translates to:
  /// **'Nominal Transfer'**
  String get paymentAmountToSend;

  /// No description provided for @paymentServiceRate.
  ///
  /// In id, this message translates to:
  /// **'Tarif Layanan'**
  String get paymentServiceRate;

  /// No description provided for @paymentPlatformFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya Platform ({percent}%)'**
  String paymentPlatformFee(String percent);

  /// No description provided for @paymentExactAmountHint.
  ///
  /// In id, this message translates to:
  /// **'Harap kirim nominal PERSIS termasuk kode unik untuk aktivasi otomatis.'**
  String get paymentExactAmountHint;

  /// No description provided for @paymentReferenceLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode Referensi Transfer Wise/Revolut'**
  String get paymentReferenceLabel;

  /// No description provided for @paymentReferenceHint.
  ///
  /// In id, this message translates to:
  /// **'contoh TRANSFER-123456789'**
  String get paymentReferenceHint;

  /// No description provided for @paymentReferenceRequired.
  ///
  /// In id, this message translates to:
  /// **'Kode referensi transfer wajib diisi.'**
  String get paymentReferenceRequired;

  /// No description provided for @paymentUploadProof.
  ///
  /// In id, this message translates to:
  /// **'Upload Bukti Transfer'**
  String get paymentUploadProof;

  /// No description provided for @paymentProofSelected.
  ///
  /// In id, this message translates to:
  /// **'Bukti: {fileName}'**
  String paymentProofSelected(String fileName);

  /// No description provided for @paymentConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Pembayaran'**
  String get paymentConfirm;

  /// No description provided for @paymentSubmitFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim bukti pembayaran. Coba lagi.'**
  String get paymentSubmitFailed;

  /// No description provided for @paymentCopied.
  ///
  /// In id, this message translates to:
  /// **'Disalin ke clipboard'**
  String get paymentCopied;

  /// No description provided for @paymentWaitingVerification.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Verifikasi Admin'**
  String get paymentWaitingVerification;

  /// No description provided for @paymentWaitingVerificationId.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Verifikasi'**
  String get paymentWaitingVerificationId;

  /// No description provided for @paymentWaitingVerificationBody.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran Anda telah diterima. Tim kami akan memverifikasi transfer Anda segera.'**
  String get paymentWaitingVerificationBody;

  /// No description provided for @paymentSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Berhasil'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessId.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Berhasil'**
  String get paymentSuccessId;

  /// No description provided for @paymentBackToDashboard.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Dashboard'**
  String get paymentBackToDashboard;

  /// No description provided for @paymentDetails.
  ///
  /// In id, this message translates to:
  /// **'Rincian Pembayaran'**
  String get paymentDetails;

  /// No description provided for @paymentTotalPaid.
  ///
  /// In id, this message translates to:
  /// **'Total Dibayar'**
  String get paymentTotalPaid;

  /// No description provided for @walletTitle.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get walletTitle;

  /// No description provided for @walletAvailableBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo Tersedia'**
  String get walletAvailableBalance;

  /// No description provided for @walletWithdraw.
  ///
  /// In id, this message translates to:
  /// **'Tarik Saldo'**
  String get walletWithdraw;

  /// No description provided for @walletEarningsBreakdown.
  ///
  /// In id, this message translates to:
  /// **'Rincian Pendapatan'**
  String get walletEarningsBreakdown;

  /// No description provided for @walletGrossIncome.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Kotor'**
  String get walletGrossIncome;

  /// No description provided for @walletPlatformFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya Platform ({percent}%)'**
  String walletPlatformFee(String percent);

  /// No description provided for @walletNetIncome.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Bersih'**
  String get walletNetIncome;

  /// No description provided for @walletWithdrawalRequests.
  ///
  /// In id, this message translates to:
  /// **'Permintaan Penarikan'**
  String get walletWithdrawalRequests;

  /// No description provided for @walletWithdrawalsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada permintaan penarikan.'**
  String get walletWithdrawalsEmpty;

  /// No description provided for @walletTransactionHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Transaksi'**
  String get walletTransactionHistory;

  /// No description provided for @walletTransactionsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi.'**
  String get walletTransactionsEmpty;

  /// No description provided for @walletWithdrawDialogTitle.
  ///
  /// In id, this message translates to:
  /// **'Tarik Saldo'**
  String get walletWithdrawDialogTitle;

  /// No description provided for @walletAmountLabel.
  ///
  /// In id, this message translates to:
  /// **'Nominal (IDR)'**
  String get walletAmountLabel;

  /// No description provided for @walletAmountHint.
  ///
  /// In id, this message translates to:
  /// **'Min. 10.000'**
  String get walletAmountHint;

  /// No description provided for @walletMethodLabel.
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get walletMethodLabel;

  /// No description provided for @walletMethodQris.
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get walletMethodQris;

  /// No description provided for @walletMethodBank.
  ///
  /// In id, this message translates to:
  /// **'Rekening Bank'**
  String get walletMethodBank;

  /// No description provided for @walletDestinationLabel.
  ///
  /// In id, this message translates to:
  /// **'Tujuan'**
  String get walletDestinationLabel;

  /// No description provided for @walletDestinationHint.
  ///
  /// In id, this message translates to:
  /// **'Kode QRIS atau nomor rekening'**
  String get walletDestinationHint;

  /// No description provided for @walletWithdrawSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get walletWithdrawSubmit;

  /// No description provided for @walletWithdrawSent.
  ///
  /// In id, this message translates to:
  /// **'Permintaan penarikan dikirim.'**
  String get walletWithdrawSent;

  /// No description provided for @walletWithdrawPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Diproses'**
  String get walletWithdrawPending;

  /// No description provided for @walletWithdrawPendingId.
  ///
  /// In id, this message translates to:
  /// **'Menunggu Diproses'**
  String get walletWithdrawPendingId;

  /// No description provided for @walletLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat dompet.'**
  String get walletLoadFailed;

  /// No description provided for @errorStateTitle.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data'**
  String get errorStateTitle;

  /// No description provided for @errorStateRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get errorStateRetry;

  /// No description provided for @errorStateBody.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan. Periksa koneksi internet Anda dan coba lagi.'**
  String get errorStateBody;

  /// No description provided for @loadMore.
  ///
  /// In id, this message translates to:
  /// **'Muat lebih banyak'**
  String get loadMore;

  /// No description provided for @filterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAll;

  /// No description provided for @filterLast7Days.
  ///
  /// In id, this message translates to:
  /// **'7 hari'**
  String get filterLast7Days;

  /// No description provided for @filterLast30Days.
  ///
  /// In id, this message translates to:
  /// **'30 hari'**
  String get filterLast30Days;

  /// No description provided for @filterLast90Days.
  ///
  /// In id, this message translates to:
  /// **'90 hari'**
  String get filterLast90Days;

  /// No description provided for @bookingHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Booking'**
  String get bookingHistoryTitle;

  /// No description provided for @bookingHistoryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat booking.'**
  String get bookingHistoryEmpty;

  /// No description provided for @bookingHistoryFilterDate.
  ///
  /// In id, this message translates to:
  /// **'Filter tanggal'**
  String get bookingHistoryFilterDate;

  /// No description provided for @bookingHistoryFilterStatus.
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get bookingHistoryFilterStatus;

  /// No description provided for @reviewTitle.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana pengalamanmu?'**
  String get reviewTitle;

  /// No description provided for @reviewForSitter.
  ///
  /// In id, this message translates to:
  /// **'Ulasan untuk {sitterName}'**
  String reviewForSitter(String sitterName);

  /// No description provided for @reviewRatingLabel.
  ///
  /// In id, this message translates to:
  /// **'Rating'**
  String get reviewRatingLabel;

  /// No description provided for @reviewCommentLabel.
  ///
  /// In id, this message translates to:
  /// **'Komentar'**
  String get reviewCommentLabel;

  /// No description provided for @reviewCommentHint.
  ///
  /// In id, this message translates to:
  /// **'Ceritakan pengalaman Anda...'**
  String get reviewCommentHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim Ulasan'**
  String get reviewSubmit;

  /// No description provided for @reviewSubmitSuccess.
  ///
  /// In id, this message translates to:
  /// **'Ulasan berhasil dikirim.'**
  String get reviewSubmitSuccess;

  /// No description provided for @reviewLeaveAction.
  ///
  /// In id, this message translates to:
  /// **'Beri ulasan'**
  String get reviewLeaveAction;

  /// No description provided for @reviewAlreadySubmitted.
  ///
  /// In id, this message translates to:
  /// **'Ulasan sudah dikirim'**
  String get reviewAlreadySubmitted;

  /// No description provided for @darkModeTitle.
  ///
  /// In id, this message translates to:
  /// **'Mode gelap'**
  String get darkModeTitle;

  /// No description provided for @profileStatsTitle.
  ///
  /// In id, this message translates to:
  /// **'Statistik'**
  String get profileStatsTitle;

  /// No description provided for @profileStatsBookings.
  ///
  /// In id, this message translates to:
  /// **'{count} booking'**
  String profileStatsBookings(int count);

  /// No description provided for @profileStatsPets.
  ///
  /// In id, this message translates to:
  /// **'{count} hewan'**
  String profileStatsPets(int count);

  /// No description provided for @profileStatsEarnings.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan bersih'**
  String get profileStatsEarnings;

  /// No description provided for @profileBookingHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat booking'**
  String get profileBookingHistory;

  /// No description provided for @profileEditPet.
  ///
  /// In id, this message translates to:
  /// **'Edit hewan'**
  String get profileEditPet;

  /// No description provided for @deletePetConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus hewan ini dari profil?'**
  String get deletePetConfirm;

  /// No description provided for @sortLabel.
  ///
  /// In id, this message translates to:
  /// **'Urutkan'**
  String get sortLabel;

  /// No description provided for @sortPriceLow.
  ///
  /// In id, this message translates to:
  /// **'Harga terendah'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In id, this message translates to:
  /// **'Harga tertinggi'**
  String get sortPriceHigh;

  /// No description provided for @sortRating.
  ///
  /// In id, this message translates to:
  /// **'Rating tertinggi'**
  String get sortRating;

  /// No description provided for @favoriteAdd.
  ///
  /// In id, this message translates to:
  /// **'Simpan favorit'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus favorit'**
  String get favoriteRemove;

  /// No description provided for @favoritesTitle.
  ///
  /// In id, this message translates to:
  /// **'Sitter favorit'**
  String get favoritesTitle;

  /// No description provided for @inAppNotificationsHint.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi real-time via polling API (tanpa Firebase).'**
  String get inAppNotificationsHint;

  /// No description provided for @onboardingOwnerTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang, Owner!'**
  String get onboardingOwnerTitle;

  /// No description provided for @onboardingOwnerStep1.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi alamat dan tambahkan hewan peliharaan.'**
  String get onboardingOwnerStep1;

  /// No description provided for @onboardingOwnerStep2.
  ///
  /// In id, this message translates to:
  /// **'Pilih layanan, buat permintaan, dan terima penawaran sitter.'**
  String get onboardingOwnerStep2;

  /// No description provided for @onboardingOwnerStep3.
  ///
  /// In id, this message translates to:
  /// **'Bayar, lacak booking, dan beri ulasan setelah selesai.'**
  String get onboardingOwnerStep3;

  /// No description provided for @onboardingSitterTitle.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang, Sitter!'**
  String get onboardingSitterTitle;

  /// No description provided for @onboardingSitterStep1.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi profil dan layanan yang Anda tawarkan.'**
  String get onboardingSitterStep1;

  /// No description provided for @onboardingSitterStep2.
  ///
  /// In id, this message translates to:
  /// **'Setelah disetujui admin, lihat permintaan di sekitar Anda.'**
  String get onboardingSitterStep2;

  /// No description provided for @onboardingSitterStep3.
  ///
  /// In id, this message translates to:
  /// **'Kirim penawaran, kelola booking, dan tarik pendapatan.'**
  String get onboardingSitterStep3;

  /// No description provided for @onboardingGotIt.
  ///
  /// In id, this message translates to:
  /// **'Mengerti'**
  String get onboardingGotIt;

  /// No description provided for @onboardingNext.
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get onboardingNext;

  /// No description provided for @tooltipNotifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi in-app'**
  String get tooltipNotifications;

  /// No description provided for @tooltipProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil & pengaturan'**
  String get tooltipProfile;

  /// No description provided for @tooltipBookingHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat booking'**
  String get tooltipBookingHistory;

  /// No description provided for @tooltipLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun'**
  String get tooltipLogout;

  /// No description provided for @tooltipWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet & pencairan'**
  String get tooltipWallet;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari...'**
  String get searchHint;

  /// No description provided for @sitterActiveBookingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Booking Aktif'**
  String get sitterActiveBookingsTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Senang bertemu lagi! Masuk untuk melanjutkan perawatan hewan Anda.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun gratis dan temukan pengasuh terpercaya di dekat Anda.'**
  String get authRegisterSubtitle;

  /// No description provided for @authLoginSuccess.
  ///
  /// In id, this message translates to:
  /// **'Login berhasil! Mengalihkan…'**
  String get authLoginSuccess;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In id, this message translates to:
  /// **'Pendaftaran berhasil! Selamat datang di Kaki Empat.'**
  String get authRegisterSuccess;

  /// No description provided for @authNameHint.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap Anda'**
  String get authNameHint;

  /// No description provided for @wwwAuthHubTitle.
  ///
  /// In id, this message translates to:
  /// **'Akun Kaki Empat'**
  String get wwwAuthHubTitle;

  /// No description provided for @wwwNavBrand.
  ///
  /// In id, this message translates to:
  /// **'Kaki Empat'**
  String get wwwNavBrand;

  /// No description provided for @wwwNavMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get wwwNavMenu;

  /// No description provided for @wwwNavHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get wwwNavHome;

  /// No description provided for @wwwNavServices.
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get wwwNavServices;

  /// No description provided for @wwwNavPricing.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get wwwNavPricing;

  /// No description provided for @wwwNavSignup.
  ///
  /// In id, this message translates to:
  /// **'Jadi Pengasuh'**
  String get wwwNavSignup;

  /// No description provided for @wwwNavBlog.
  ///
  /// In id, this message translates to:
  /// **'Tips'**
  String get wwwNavBlog;

  /// No description provided for @wwwNavTestimonials.
  ///
  /// In id, this message translates to:
  /// **'Testimoni'**
  String get wwwNavTestimonials;

  /// No description provided for @wwwNavApps.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi'**
  String get wwwNavApps;

  /// No description provided for @wwwOpenOwnerApp.
  ///
  /// In id, this message translates to:
  /// **'Buka app pemilik'**
  String get wwwOpenOwnerApp;

  /// No description provided for @wwwOpenSitterApp.
  ///
  /// In id, this message translates to:
  /// **'Buka app pengasuh'**
  String get wwwOpenSitterApp;

  /// No description provided for @wwwOpenAdminApp.
  ///
  /// In id, this message translates to:
  /// **'Buka panel admin'**
  String get wwwOpenAdminApp;

  /// No description provided for @wwwOpenStagingApp.
  ///
  /// In id, this message translates to:
  /// **'Staging (QA)'**
  String get wwwOpenStagingApp;

  /// No description provided for @wwwFooterTagline.
  ///
  /// In id, this message translates to:
  /// **'Platform pengasuhan hewan terpercaya di Indonesia.'**
  String get wwwFooterTagline;

  /// No description provided for @wwwFooterSections.
  ///
  /// In id, this message translates to:
  /// **'Halaman'**
  String get wwwFooterSections;

  /// No description provided for @wwwFooterCopyright.
  ///
  /// In id, this message translates to:
  /// **'© {year} {appName}. Semua hak dilindungi.'**
  String wwwFooterCopyright(int year, String appName);

  /// No description provided for @ownerPetsTitle.
  ///
  /// In id, this message translates to:
  /// **'Hewan peliharaan'**
  String get ownerPetsTitle;

  /// No description provided for @ownerAddFirstPetCta.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan hewan pertama Anda!'**
  String get ownerAddFirstPetCta;

  /// No description provided for @ownerCreateRequestFab.
  ///
  /// In id, this message translates to:
  /// **'Cari Pengasuh'**
  String get ownerCreateRequestFab;

  /// No description provided for @ownerCreateRequestFabHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih layanan lalu buat permintaan baru'**
  String get ownerCreateRequestFabHint;

  /// No description provided for @sitterRequestsEmptyTip.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi profil untuk dapat lebih banyak permintaan'**
  String get sitterRequestsEmptyTip;

  /// No description provided for @sitterCompleteProfileCta.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi profil'**
  String get sitterCompleteProfileCta;

  /// No description provided for @sitterFaqTitle.
  ///
  /// In id, this message translates to:
  /// **'Tips & Bantuan'**
  String get sitterFaqTitle;

  /// No description provided for @sitterFaqIntro.
  ///
  /// In id, this message translates to:
  /// **'Jawaban singkat untuk pertanyaan umum pengasuh Kaki Empat.'**
  String get sitterFaqIntro;

  /// No description provided for @sitterFaqQ1.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara mendapat lebih banyak permintaan?'**
  String get sitterFaqQ1;

  /// No description provided for @sitterFaqA1.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi bio, alamat, dan layanan yang Anda tawarkan. Profil yang jelas dan foto menarik membantu owner memilih Anda.'**
  String get sitterFaqA1;

  /// No description provided for @sitterFaqQ2.
  ///
  /// In id, this message translates to:
  /// **'Berapa harga penawaran yang wajar?'**
  String get sitterFaqQ2;

  /// No description provided for @sitterFaqA2.
  ///
  /// In id, this message translates to:
  /// **'Lihat harga permintaan owner sebagai patokan. Sesuaikan dengan pengalaman dan jarak tempuh. Terlalu tinggi bisa mengurangi peluang diterima.'**
  String get sitterFaqA2;

  /// No description provided for @sitterFaqQ3.
  ///
  /// In id, this message translates to:
  /// **'Kapan pendapatan masuk ke dompet?'**
  String get sitterFaqQ3;

  /// No description provided for @sitterFaqA3.
  ///
  /// In id, this message translates to:
  /// **'Setelah booking selesai dan owner memberi ulasan (atau otomatis setelah 48 jam), pendapatan bersih masuk ke dompet Anda.'**
  String get sitterFaqA3;

  /// No description provided for @sitterFaqQ4.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara tarik saldo?'**
  String get sitterFaqQ4;

  /// No description provided for @sitterFaqA4.
  ///
  /// In id, this message translates to:
  /// **'Buka menu Dompet, masukkan jumlah dan rekening/QRIS tujuan. Pencairan diproses dalam 1×24 jam kerja.'**
  String get sitterFaqA4;

  /// No description provided for @sitterOfferPriceTip.
  ///
  /// In id, this message translates to:
  /// **'Tips: mulai dari harga permintaan owner, lalu sesuaikan dengan pengalaman Anda.'**
  String get sitterOfferPriceTip;

  /// No description provided for @sitterEarningsEstimate.
  ///
  /// In id, this message translates to:
  /// **'Estimasi pendapatan bersih: {amount} (setelah biaya platform 8%)'**
  String sitterEarningsEstimate(String amount);

  /// No description provided for @ownerGuideTip1.
  ///
  /// In id, this message translates to:
  /// **'Pilih sitter dengan rating tinggi dan ulasan positif.'**
  String get ownerGuideTip1;

  /// No description provided for @ownerGuideTip2.
  ///
  /// In id, this message translates to:
  /// **'Bayar hanya melalui rekening resmi Kaki Empat — jangan transfer langsung ke sitter.'**
  String get ownerGuideTip2;

  /// No description provided for @ownerGuideTip3.
  ///
  /// In id, this message translates to:
  /// **'Siapkan makanan, leash, dan catatan kesehatan hewan sebelum jadwal dimulai.'**
  String get ownerGuideTip3;

  /// No description provided for @adminStatSitters.
  ///
  /// In id, this message translates to:
  /// **'{count} Sitter'**
  String adminStatSitters(int count);

  /// No description provided for @adminStatOwners.
  ///
  /// In id, this message translates to:
  /// **'{count} Owner'**
  String adminStatOwners(int count);

  /// No description provided for @adminStatPendingVerify.
  ///
  /// In id, this message translates to:
  /// **'{count} Perlu Verifikasi'**
  String adminStatPendingVerify(int count);

  /// No description provided for @adminStatTransactions.
  ///
  /// In id, this message translates to:
  /// **'{amount} Transaksi'**
  String adminStatTransactions(String amount);

  /// No description provided for @adminPendingActionsTitle.
  ///
  /// In id, this message translates to:
  /// **'Perlu Tindakan'**
  String get adminPendingActionsTitle;

  /// No description provided for @adminActionNewSitter.
  ///
  /// In id, this message translates to:
  /// **'📋 Sitter baru: {name} ({services})'**
  String adminActionNewSitter(String name, String services);

  /// No description provided for @adminActionPayment.
  ///
  /// In id, this message translates to:
  /// **'💳 Pembayaran: {amount} dari {owner}'**
  String adminActionPayment(String amount, String owner);

  /// No description provided for @adminActionWithdrawal.
  ///
  /// In id, this message translates to:
  /// **'🏧 Pencairan: {amount} ke {destination}'**
  String adminActionWithdrawal(String amount, String destination);

  /// No description provided for @pullRefreshSearching.
  ///
  /// In id, this message translates to:
  /// **'Mencari permintaan baru...'**
  String get pullRefreshSearching;

  /// No description provided for @statsBookingsLabel.
  ///
  /// In id, this message translates to:
  /// **'booking berhasil'**
  String get statsBookingsLabel;

  /// No description provided for @statsRatingLabel.
  ///
  /// In id, this message translates to:
  /// **'rating sitter'**
  String get statsRatingLabel;

  /// No description provided for @statsCitiesValue.
  ///
  /// In id, this message translates to:
  /// **'3 kota'**
  String get statsCitiesValue;

  /// No description provided for @statsCitiesLabel.
  ///
  /// In id, this message translates to:
  /// **'Denpasar, Surabaya, Jakarta'**
  String get statsCitiesLabel;

  /// No description provided for @statsPayoutLabel.
  ///
  /// In id, this message translates to:
  /// **'disalurkan ke mitra'**
  String get statsPayoutLabel;

  /// No description provided for @sitterTestimonialsTitle.
  ///
  /// In id, this message translates to:
  /// **'Cerita dari Mitra Kami'**
  String get sitterTestimonialsTitle;

  /// No description provided for @sitterTestimonial1Role.
  ///
  /// In id, this message translates to:
  /// **'Dog Walker'**
  String get sitterTestimonial1Role;

  /// No description provided for @sitterTestimonial1City.
  ///
  /// In id, this message translates to:
  /// **'Denpasar'**
  String get sitterTestimonial1City;

  /// No description provided for @sitterTestimonial2Role.
  ///
  /// In id, this message translates to:
  /// **'Grooming'**
  String get sitterTestimonial2Role;

  /// No description provided for @sitterTestimonial2City.
  ///
  /// In id, this message translates to:
  /// **'Surabaya'**
  String get sitterTestimonial2City;

  /// No description provided for @sitterTestimonial3Name.
  ///
  /// In id, this message translates to:
  /// **'Dewi'**
  String get sitterTestimonial3Name;

  /// No description provided for @sitterTestimonial3Role.
  ///
  /// In id, this message translates to:
  /// **'Vet'**
  String get sitterTestimonial3Role;

  /// No description provided for @sitterTestimonial3City.
  ///
  /// In id, this message translates to:
  /// **'Jakarta'**
  String get sitterTestimonial3City;

  /// No description provided for @sitterTestimonial3Quote.
  ///
  /// In id, this message translates to:
  /// **'Jadi lebih fleksibel. Owner senang karena hewannya nggak perlu stres ke klinik.'**
  String get sitterTestimonial3Quote;

  /// No description provided for @ownerStoriesTitle.
  ///
  /// In id, this message translates to:
  /// **'Cerita Pemilik Hewan'**
  String get ownerStoriesTitle;

  /// No description provided for @ownerStory1Name.
  ///
  /// In id, this message translates to:
  /// **'Maya'**
  String get ownerStory1Name;

  /// No description provided for @ownerStory1Subtitle.
  ///
  /// In id, this message translates to:
  /// **'Pemilik Milo'**
  String get ownerStory1Subtitle;

  /// No description provided for @ownerStory1Quote.
  ///
  /// In id, this message translates to:
  /// **'Milo anjingnya hiperaktif, susah banget ditinggal kerja. Sejak pakai Kaki Empat, tiap siang ada yang ngajak jalan. Sekarang Milo udah nggak ngerusak sofa lagi!'**
  String get ownerStory1Quote;

  /// No description provided for @ownerStory2Name.
  ///
  /// In id, this message translates to:
  /// **'Alex'**
  String get ownerStory2Name;

  /// No description provided for @ownerStory2Subtitle.
  ///
  /// In id, this message translates to:
  /// **'Bule di Bali'**
  String get ownerStory2Subtitle;

  /// No description provided for @ownerStory2Quote.
  ///
  /// In id, this message translates to:
  /// **'I was worried leaving my dog at a pet hotel. But the sitter sent me photos every hour. I could enjoy my vacation without feeling guilty.'**
  String get ownerStory2Quote;

  /// No description provided for @ownerStory3Name.
  ///
  /// In id, this message translates to:
  /// **'Sari'**
  String get ownerStory3Name;

  /// No description provided for @ownerStory3Subtitle.
  ///
  /// In id, this message translates to:
  /// **'Jakarta'**
  String get ownerStory3Subtitle;

  /// No description provided for @ownerStory3Quote.
  ///
  /// In id, this message translates to:
  /// **'Kucingku perlu grooming rutin tapi males ke salon. Ada sitter yang datang ke rumah, selesai dalam 1 jam. Kucingku happy, aku happy!'**
  String get ownerStory3Quote;

  /// No description provided for @storiFeedTitle.
  ///
  /// In id, this message translates to:
  /// **'Cerita Harian'**
  String get storiFeedTitle;

  /// No description provided for @storiFeedSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas mitra pengasuh di lapangan'**
  String get storiFeedSubtitle;

  /// No description provided for @storiViewFeed.
  ///
  /// In id, this message translates to:
  /// **'Lihat cerita harian'**
  String get storiViewFeed;

  /// No description provided for @storiPost1Author.
  ///
  /// In id, this message translates to:
  /// **'Putri · Dog Walker'**
  String get storiPost1Author;

  /// No description provided for @storiPost1Caption.
  ///
  /// In id, this message translates to:
  /// **'Jalan pagi bareng Milo 🐕. Dia seneng banget ketemu temen baru di taman.'**
  String get storiPost1Caption;

  /// No description provided for @storiPost2Author.
  ///
  /// In id, this message translates to:
  /// **'Rian · Grooming'**
  String get storiPost2Author;

  /// No description provided for @storiPost2Caption.
  ///
  /// In id, this message translates to:
  /// **'Hasil grooming hari ini! Coco sekarang kinclong ✨✂️'**
  String get storiPost2Caption;

  /// No description provided for @storiPost3Author.
  ///
  /// In id, this message translates to:
  /// **'Dewi · Vet'**
  String get storiPost3Author;

  /// No description provided for @storiPost3Caption.
  ///
  /// In id, this message translates to:
  /// **'Kunjungan ke rumah Bu Sari. Kucingnya manis banget, langsung nurut pas dikasih vitamin.'**
  String get storiPost3Caption;

  /// No description provided for @storiPost4Author.
  ///
  /// In id, this message translates to:
  /// **'Andi · Pet Taxi'**
  String get storiPost4Author;

  /// No description provided for @storiPost4Caption.
  ///
  /// In id, this message translates to:
  /// **'First time pet taxi! Jemput Max dari vet, dia tenang banget di perjalanan 🚗'**
  String get storiPost4Caption;

  /// No description provided for @storiTime2h.
  ///
  /// In id, this message translates to:
  /// **'2 jam lalu'**
  String get storiTime2h;

  /// No description provided for @storiTime5h.
  ///
  /// In id, this message translates to:
  /// **'5 jam lalu'**
  String get storiTime5h;

  /// No description provided for @storiTime1d.
  ///
  /// In id, this message translates to:
  /// **'1 hari lalu'**
  String get storiTime1d;

  /// No description provided for @storiTime2d.
  ///
  /// In id, this message translates to:
  /// **'2 hari lalu'**
  String get storiTime2d;

  /// No description provided for @storiLikes.
  ///
  /// In id, this message translates to:
  /// **'{count} suka'**
  String storiLikes(int count);

  /// No description provided for @storiComments.
  ///
  /// In id, this message translates to:
  /// **'{count} komentar'**
  String storiComments(int count);

  /// No description provided for @onboardingSkip.
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get onboardingSkip;

  /// No description provided for @badgeVerified.
  ///
  /// In id, this message translates to:
  /// **'Terverifikasi'**
  String get badgeVerified;

  /// No description provided for @sitterReviewsTitle.
  ///
  /// In id, this message translates to:
  /// **'Ulasan'**
  String get sitterReviewsTitle;

  /// No description provided for @sitterReviewsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada ulasan.'**
  String get sitterReviewsEmpty;

  /// No description provided for @reviewNoComment.
  ///
  /// In id, this message translates to:
  /// **'Tanpa komentar'**
  String get reviewNoComment;

  /// No description provided for @helpFaqTitle.
  ///
  /// In id, this message translates to:
  /// **'FAQ'**
  String get helpFaqTitle;

  /// No description provided for @faqSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari pertanyaan...'**
  String get faqSearchHint;

  /// No description provided for @helpRepeatTutorial.
  ///
  /// In id, this message translates to:
  /// **'Ulangi panduan singkat'**
  String get helpRepeatTutorial;

  /// No description provided for @faqNoResults.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pertanyaan yang cocok.'**
  String get faqNoResults;

  /// No description provided for @faqQ1.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara membuat permintaan booking?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In id, this message translates to:
  /// **'Pilih layanan di beranda, isi jadwal dan detail hewan, lalu kirim permintaan. Sitter akan mengirim penawaran harga.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana memilih sitter terbaik?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In id, this message translates to:
  /// **'Perhatikan badge Terverifikasi, rating, ulasan, dan harga penawaran. Buka profil sitter untuk melihat riwayat ulasan.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana cara membayar booking?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In id, this message translates to:
  /// **'Setelah menerima penawaran, ikuti panduan pembayaran ke rekening resmi Kaki Empat. Unggah bukti transfer untuk verifikasi.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In id, this message translates to:
  /// **'Berapa lama verifikasi pembayaran?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In id, this message translates to:
  /// **'Tim admin memverifikasi bukti pembayaran dalam 1×24 jam kerja. Anda akan mendapat notifikasi saat disetujui.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana sitter menarik pendapatan?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In id, this message translates to:
  /// **'Buka menu Dompet, masukkan jumlah dan rekening/QRIS tujuan. Permintaan diproses admin dalam 1×24 jam kerja.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In id, this message translates to:
  /// **'Berapa biaya platform?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In id, this message translates to:
  /// **'Kaki Empat memotong 8% dari pendapatan kotor sitter. Sisa 92% masuk ke dompet sitter sebagai pendapatan bersih.'**
  String get faqA6;

  /// No description provided for @faqQ7.
  ///
  /// In id, this message translates to:
  /// **'Bisakah membatalkan booking?'**
  String get faqQ7;

  /// No description provided for @faqA7.
  ///
  /// In id, this message translates to:
  /// **'Booking dapat dibatalkan sebelum layanan dimulai. Status dan kebijakan refund mengikuti tahap booking saat itu.'**
  String get faqA7;

  /// No description provided for @faqQ8.
  ///
  /// In id, this message translates to:
  /// **'Kapan bisa memberi ulasan?'**
  String get faqQ8;

  /// No description provided for @faqA8.
  ///
  /// In id, this message translates to:
  /// **'Setelah booking berstatus selesai, pemilik dapat memberi rating 1–5 bintang dan komentar di halaman detail booking.'**
  String get faqA8;

  /// No description provided for @faqQ9.
  ///
  /// In id, this message translates to:
  /// **'Apa itu program loyalitas?'**
  String get faqQ9;

  /// No description provided for @faqA9.
  ///
  /// In id, this message translates to:
  /// **'Setiap booking selesai +10 poin. 100 poin dapat ditukar diskon Rp 10.000 di profil Anda.'**
  String get faqA9;

  /// No description provided for @faqQ10.
  ///
  /// In id, this message translates to:
  /// **'Bagaimana referral bekerja?'**
  String get faqQ10;

  /// No description provided for @faqA10.
  ///
  /// In id, this message translates to:
  /// **'Bagikan kode referral unik Anda. Pengundang dapat bonus Rp 20.000, pengguna baru diskon 10% booking pertama.'**
  String get faqA10;

  /// No description provided for @tipsArticlesTitle.
  ///
  /// In id, this message translates to:
  /// **'Tips Perawatan Hewan'**
  String get tipsArticlesTitle;

  /// No description provided for @tipsArticlesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Artikel singkat untuk pemilik hewan — dapat diperluas nanti.'**
  String get tipsArticlesSubtitle;

  /// No description provided for @tipsArticle1Title.
  ///
  /// In id, this message translates to:
  /// **'Nutrisi Seimbang untuk Anjing'**
  String get tipsArticle1Title;

  /// No description provided for @tipsArticle1Summary.
  ///
  /// In id, this message translates to:
  /// **'Pilih pakan sesuai usia dan aktivitas. Hindari makanan manusia berlebihan.'**
  String get tipsArticle1Summary;

  /// No description provided for @tipsArticle2Title.
  ///
  /// In id, this message translates to:
  /// **'Rutinitas Jalan Pagi'**
  String get tipsArticle2Title;

  /// No description provided for @tipsArticle2Summary.
  ///
  /// In id, this message translates to:
  /// **'20–30 menit jalan pagi membantu energi anjing terkontrol sepanjang hari.'**
  String get tipsArticle2Summary;

  /// No description provided for @tipsArticle3Title.
  ///
  /// In id, this message translates to:
  /// **'Grooming di Rumah'**
  String get tipsArticle3Title;

  /// No description provided for @tipsArticle3Summary.
  ///
  /// In id, this message translates to:
  /// **'Sisir bulu rutin mengurangi kusut dan menjaga kulit sehat.'**
  String get tipsArticle3Summary;

  /// No description provided for @tipsArticle4Title.
  ///
  /// In id, this message translates to:
  /// **'Vaksin & Cacing'**
  String get tipsArticle4Title;

  /// No description provided for @tipsArticle4Summary.
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan vaksin dan obat cacing sesuai rekomendasi dokter hewan.'**
  String get tipsArticle4Summary;

  /// No description provided for @tipsArticle5Title.
  ///
  /// In id, this message translates to:
  /// **'Stimulasi Mental Kucing'**
  String get tipsArticle5Title;

  /// No description provided for @tipsArticle5Summary.
  ///
  /// In id, this message translates to:
  /// **'Mainan interaktif dan permainan singkat mencegah stres pada kucing indoor.'**
  String get tipsArticle5Summary;

  /// No description provided for @petGalleryTitle.
  ///
  /// In id, this message translates to:
  /// **'Galeri Hewan'**
  String get petGalleryTitle;

  /// No description provided for @petGalleryUpload.
  ///
  /// In id, this message translates to:
  /// **'Unggah Foto'**
  String get petGalleryUpload;

  /// No description provided for @petGalleryEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada foto di galeri. Jadilah yang pertama!'**
  String get petGalleryEmpty;

  /// No description provided for @petGalleryUploadSuccess.
  ///
  /// In id, this message translates to:
  /// **'Foto berhasil diunggah.'**
  String get petGalleryUploadSuccess;

  /// No description provided for @earningsReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan Penghasilan'**
  String get earningsReportTitle;

  /// No description provided for @earningsTotalBookings.
  ///
  /// In id, this message translates to:
  /// **'Total booking'**
  String get earningsTotalBookings;

  /// No description provided for @earningsAvgRating.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata rating'**
  String get earningsAvgRating;

  /// No description provided for @earningsNetIncome.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan bersih'**
  String get earningsNetIncome;

  /// No description provided for @earningsWeekly.
  ///
  /// In id, this message translates to:
  /// **'Mingguan'**
  String get earningsWeekly;

  /// No description provided for @earningsMonthly.
  ///
  /// In id, this message translates to:
  /// **'Bulanan'**
  String get earningsMonthly;

  /// No description provided for @earningsNoData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data pendapatan.'**
  String get earningsNoData;

  /// No description provided for @achievementsTitle.
  ///
  /// In id, this message translates to:
  /// **'Target & Pencapaian'**
  String get achievementsTitle;

  /// No description provided for @achievementsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan booking untuk mendapat lencana!'**
  String get achievementsEmpty;

  /// No description provided for @promoTitle.
  ///
  /// In id, this message translates to:
  /// **'Promosi Sitter'**
  String get promoTitle;

  /// No description provided for @promoCreate.
  ///
  /// In id, this message translates to:
  /// **'Buat Kupon'**
  String get promoCreate;

  /// No description provided for @promoEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kupon promo.'**
  String get promoEmpty;

  /// No description provided for @promoCreateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Kupon promo berhasil dibuat.'**
  String get promoCreateSuccess;

  /// No description provided for @promoDiscountLabel.
  ///
  /// In id, this message translates to:
  /// **'Diskon {percent}% booking pertama'**
  String promoDiscountLabel(int percent);

  /// No description provided for @promoActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get promoActive;

  /// No description provided for @promoUsed.
  ///
  /// In id, this message translates to:
  /// **'Terpakai'**
  String get promoUsed;

  /// No description provided for @sitterVerificationKtp.
  ///
  /// In id, this message translates to:
  /// **'Foto KTP'**
  String get sitterVerificationKtp;

  /// No description provided for @sitterVerificationSelfie.
  ///
  /// In id, this message translates to:
  /// **'Selfie dengan KTP'**
  String get sitterVerificationSelfie;

  /// No description provided for @sitterVerificationUpload.
  ///
  /// In id, this message translates to:
  /// **'Unggah Dokumen'**
  String get sitterVerificationUpload;

  /// No description provided for @sitterVerificationDocsRequired.
  ///
  /// In id, this message translates to:
  /// **'Unggah KTP dan selfie terlebih dahulu.'**
  String get sitterVerificationDocsRequired;

  /// No description provided for @loyaltyPointsTitle.
  ///
  /// In id, this message translates to:
  /// **'Poin Loyalitas'**
  String get loyaltyPointsTitle;

  /// No description provided for @loyaltyRedeem.
  ///
  /// In id, this message translates to:
  /// **'Tukar Poin'**
  String get loyaltyRedeem;

  /// No description provided for @referralTitle.
  ///
  /// In id, this message translates to:
  /// **'Kode Referral'**
  String get referralTitle;

  /// No description provided for @referralShareHint.
  ///
  /// In id, this message translates to:
  /// **'Bagikan kode ini ke teman. Anda dapat bonus Rp 20.000!'**
  String get referralShareHint;

  /// No description provided for @adminViewDocuments.
  ///
  /// In id, this message translates to:
  /// **'Lihat Dokumen'**
  String get adminViewDocuments;

  /// No description provided for @adminVerificationDocs.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Dokumen'**
  String get adminVerificationDocs;

  /// No description provided for @ownerMenuCommunity.
  ///
  /// In id, this message translates to:
  /// **'Komunitas'**
  String get ownerMenuCommunity;

  /// No description provided for @ownerMenuHelp.
  ///
  /// In id, this message translates to:
  /// **'Bantuan'**
  String get ownerMenuHelp;

  /// No description provided for @storiPost5Author.
  ///
  /// In id, this message translates to:
  /// **'Maya · Owner'**
  String get storiPost5Author;

  /// No description provided for @storiPost5Caption.
  ///
  /// In id, this message translates to:
  /// **'Milo seneng banget jalan pagi bareng sitter 🐾'**
  String get storiPost5Caption;

  /// No description provided for @storiPost6Author.
  ///
  /// In id, this message translates to:
  /// **'Budi · Dog Walker'**
  String get storiPost6Author;

  /// No description provided for @storiPost6Caption.
  ///
  /// In id, this message translates to:
  /// **'Latihan duduk dan stay — progress bagus hari ini!'**
  String get storiPost6Caption;

  /// No description provided for @storiPost7Author.
  ///
  /// In id, this message translates to:
  /// **'Sari · Owner'**
  String get storiPost7Author;

  /// No description provided for @storiPost7Caption.
  ///
  /// In id, this message translates to:
  /// **'Si Belang grooming hari ini, bulu kinclong ✨'**
  String get storiPost7Caption;

  /// No description provided for @storiPost8Author.
  ///
  /// In id, this message translates to:
  /// **'Lia · Boarding'**
  String get storiPost8Author;

  /// No description provided for @storiPost8Caption.
  ///
  /// In id, this message translates to:
  /// **'Tamu boarding baru: Coco si anjing lucu 🏠'**
  String get storiPost8Caption;

  /// No description provided for @storiPost9Author.
  ///
  /// In id, this message translates to:
  /// **'Hendra · Owner'**
  String get storiPost9Author;

  /// No description provided for @storiPost9Caption.
  ///
  /// In id, this message translates to:
  /// **'Booking pertama di Kaki Empat — pengalaman lancar!'**
  String get storiPost9Caption;

  /// No description provided for @storiPost10Author.
  ///
  /// In id, this message translates to:
  /// **'Nina · Grooming'**
  String get storiPost10Author;

  /// No description provided for @storiPost10Caption.
  ///
  /// In id, this message translates to:
  /// **'Tips: sisir bulu sebelum mandi mengurangi kusut 🛁'**
  String get storiPost10Caption;

  /// No description provided for @storiTime3d.
  ///
  /// In id, this message translates to:
  /// **'3 hari lalu'**
  String get storiTime3d;

  /// No description provided for @storiTime4d.
  ///
  /// In id, this message translates to:
  /// **'4 hari lalu'**
  String get storiTime4d;

  /// No description provided for @storiTime1w.
  ///
  /// In id, this message translates to:
  /// **'1 minggu lalu'**
  String get storiTime1w;

  /// No description provided for @adminTabLaunch.
  ///
  /// In id, this message translates to:
  /// **'Peluncuran'**
  String get adminTabLaunch;

  /// No description provided for @launchMetricsPhaseTitle.
  ///
  /// In id, this message translates to:
  /// **'Fase {current} → {next}'**
  String launchMetricsPhaseTitle(String current, String next);

  /// No description provided for @launchMetricsReadyBody.
  ///
  /// In id, this message translates to:
  /// **'Semua kriteria exit terpenuhi. Anda dapat naik fase peluncuran berikutnya di MvpScope.'**
  String get launchMetricsReadyBody;

  /// No description provided for @launchMetricsNotReadyBody.
  ///
  /// In id, this message translates to:
  /// **'Beberapa kriteria exit belum terpenuhi. Stabilkan funnel owner sebelum naik fase.'**
  String get launchMetricsNotReadyBody;

  /// No description provided for @launchMetricsPendingPayments.
  ///
  /// In id, this message translates to:
  /// **'{count} bukti bayar menunggu persetujuan admin.'**
  String launchMetricsPendingPayments(int count);

  /// No description provided for @launchMetricsChecksTitle.
  ///
  /// In id, this message translates to:
  /// **'Kriteria exit (30 hari)'**
  String get launchMetricsChecksTitle;

  /// No description provided for @launchMetricUnitHours.
  ///
  /// In id, this message translates to:
  /// **'jam'**
  String get launchMetricUnitHours;

  /// No description provided for @launchMetricsSnapshot.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan: {completed} selesai · {sitters} sitter terverifikasi · {total} booking (non-batal)'**
  String launchMetricsSnapshot(int completed, int sitters, int total);

  /// No description provided for @appSwitcherTooltip.
  ///
  /// In id, this message translates to:
  /// **'Ganti aplikasi'**
  String get appSwitcherTooltip;

  /// No description provided for @appSwitcherOwner.
  ///
  /// In id, this message translates to:
  /// **'App pemilik'**
  String get appSwitcherOwner;

  /// No description provided for @appSwitcherSitter.
  ///
  /// In id, this message translates to:
  /// **'App pengasuh'**
  String get appSwitcherSitter;

  /// No description provided for @appSwitcherAdmin.
  ///
  /// In id, this message translates to:
  /// **'Panel admin'**
  String get appSwitcherAdmin;

  /// No description provided for @appShellHome.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get appShellHome;

  /// No description provided for @appShellBookings.
  ///
  /// In id, this message translates to:
  /// **'Booking'**
  String get appShellBookings;

  /// No description provided for @appShellMessages.
  ///
  /// In id, this message translates to:
  /// **'Pesan'**
  String get appShellMessages;

  /// No description provided for @discoverTitle.
  ///
  /// In id, this message translates to:
  /// **'Jelajahi'**
  String get discoverTitle;

  /// No description provided for @discoverEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada layanan partner.'**
  String get discoverEmpty;

  /// No description provided for @discoverComingSoon.
  ///
  /// In id, this message translates to:
  /// **'Layanan partner terbuka di fase peluncuran penuh.'**
  String get discoverComingSoon;

  /// No description provided for @growthHubTitle.
  ///
  /// In id, this message translates to:
  /// **'Ekosistem growth'**
  String get growthHubTitle;

  /// No description provided for @growthHubSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Komunitas, loyalitas, dan tips perawatan hewan'**
  String get growthHubSubtitle;

  /// No description provided for @growthHubGallery.
  ///
  /// In id, this message translates to:
  /// **'Galeri hewan'**
  String get growthHubGallery;

  /// No description provided for @growthHubStori.
  ///
  /// In id, this message translates to:
  /// **'Stori'**
  String get growthHubStori;

  /// No description provided for @growthHubTips.
  ///
  /// In id, this message translates to:
  /// **'Tips'**
  String get growthHubTips;

  /// No description provided for @ownerRecommendationsTitle.
  ///
  /// In id, this message translates to:
  /// **'Rekomendasi untuk Anda'**
  String get ownerRecommendationsTitle;

  /// No description provided for @ownerOffersForRequest.
  ///
  /// In id, this message translates to:
  /// **'{service} · {count, plural, =1{1 penawaran} other{{count} penawaran}}'**
  String ownerOffersForRequest(String service, int count);

  /// No description provided for @offerBestValue.
  ///
  /// In id, this message translates to:
  /// **'Harga terbaik'**
  String get offerBestValue;

  /// No description provided for @referralCopyAction.
  ///
  /// In id, this message translates to:
  /// **'Salin kode referral'**
  String get referralCopyAction;

  /// No description provided for @referralCopied.
  ///
  /// In id, this message translates to:
  /// **'Kode referral disalin'**
  String get referralCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
