// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Kaki Empat';

  @override
  String get tagline => 'Butuh pengasuh atau ingin jadi mitra?';

  @override
  String get wwwOwnerCta => 'Cari Pengasuh';

  @override
  String get wwwPartnerCta => 'Jadi Pengasuh';

  @override
  String get wwwHeroTitle =>
      'Hewanmu bahagia, kamu tenang. Kami temukan pengasuh terbaik di dekatmu.';

  @override
  String get wwwHeroSubtitle =>
      'Dari jalan pagi sampai menginap, semua ada. Sitter sudah terverifikasi, kamu tinggal pilih.';

  @override
  String get wwwValueVerified => 'Pengasuh terverifikasi';

  @override
  String get wwwValueTransparent => 'Biaya transparan';

  @override
  String get wwwValueSecure => 'Aman & terpercaya';

  @override
  String get wwwServicesSubtitle =>
      'Satu platform untuk semua kebutuhan hewan peliharaan Anda.';

  @override
  String get wwwHowItWorksTitle => 'Cara kerja';

  @override
  String get wwwHowStep1 => 'Daftar & buat profil hewan';

  @override
  String get wwwHowStep2 => 'Pilih pengasuh terdekat';

  @override
  String get wwwHowStep3 => 'Booking & bayar di aplikasi';

  @override
  String subdomainComingSoonTitle(String app) {
    return '$app — segera hadir';
  }

  @override
  String get subdomainComingSoonBody =>
      'Kami meluncurkan fitur secara bertahap. Mulai booking layanan lewat aplikasi Pemilik Hewan.';

  @override
  String get subdomainComingSoonOwnerCta => 'Buka aplikasi Pemilik';

  @override
  String ownerActionOffersBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permintaan punya penawaran baru',
      one: '1 permintaan punya penawaran baru',
    );
    return '$_temp0';
  }

  @override
  String get ownerActionOffersBannerBody =>
      'Terima penawaran untuk lanjut ke pembayaran dan konfirmasi jadwal.';

  @override
  String get ownerViewOffers => 'Lihat penawaran';

  @override
  String get wwwOwnerCtaLong => 'Saya Pemilik Hewan';

  @override
  String get wwwPartnerCtaLong => 'Saya Calon Pengasuh';

  @override
  String get wwwServicesTitle => 'Layanan';

  @override
  String get wwwServiceWalkingTitle => 'Dog Walking';

  @override
  String get wwwServiceWalkingDesc =>
      'Jalan-jalan rutin dengan pengasuh berpengalaman.';

  @override
  String get wwwServiceSittingTitle => 'Pet Sitting';

  @override
  String get wwwServiceSittingDesc =>
      'Perawatan di rumah Anda saat Anda bepergian.';

  @override
  String get wwwServiceGroomingTitle => 'Grooming';

  @override
  String get wwwServiceGroomingDesc =>
      'Mandi, potong kuku, dan perawatan dasar.';

  @override
  String get wwwServiceTrainingTitle => 'Pelatihan';

  @override
  String get wwwServiceTrainingDesc => 'Sesi pelatihan dasar dan sosialisasi.';

  @override
  String get wwwPricingTitle => 'Harga & biaya platform';

  @override
  String get wwwPricingOwnerNote =>
      'Pemilik membayar harga layanan + biaya platform 5%.';

  @override
  String get wwwPricingSitterNote =>
      'Pengasuh menerima harga layanan − biaya platform 8%. Pencairan < 1 hari.';

  @override
  String get wwwTestimonialsTitle => 'Testimoni';

  @override
  String get wwwTestimonial1Name => 'Rina, Jakarta';

  @override
  String get wwwTestimonial1Quote =>
      'Mudah cari pengasuh untuk kucing saya. Proses booking dan bayar jelas.';

  @override
  String get wwwTestimonial2Name => 'Budi, Bandung';

  @override
  String get wwwTestimonial2Quote =>
      'Sebagai sitter, pendapatan masuk cepat dan klien ramah.';

  @override
  String get wwwTestimonial3Name => 'Dewi, Surabaya';

  @override
  String get wwwTestimonial3Quote =>
      'Anjing saya senang setiap kali jalan dengan pengasuh dari Kaki Empat.';

  @override
  String get wwwCtaTitle => 'Siap mulai?';

  @override
  String get wwwCtaSubtitle =>
      'Daftar sebagai pemilik hewan atau ajukan diri jadi mitra pengasuh.';

  @override
  String get wwwSignupSitterTitle => 'Daftar jadi mitra pengasuh';

  @override
  String get wwwSignupSitterDesc =>
      'Isi formulir di bawah. Setelah daftar, lanjutkan ke portal pengasuh untuk lengkapi profil dan verifikasi.';

  @override
  String get wwwSignupSuccess =>
      'Pendaftaran berhasil! Lanjut ke portal pengasuh untuk melengkapi profil.';

  @override
  String get wwwSignupGoSitter => 'Buka portal pengasuh';

  @override
  String get wwwBlogTitle => 'Tips & info';

  @override
  String get wwwBlog1Title => 'Cara memilih pengasuh yang tepat';

  @override
  String get wwwBlog1Desc =>
      'Periksa ulasan, layanan yang ditawarkan, dan jarak dari lokasi Anda.';

  @override
  String get wwwBlog2Title => 'Persiapan hewan sebelum booking';

  @override
  String get wwwBlog2Desc =>
      'Catat kebiasaan makan, alergi, dan kontak dokter hewan di profil hewan.';

  @override
  String get ownerLoginTitle => 'Masuk - Pemilik Hewan';

  @override
  String get ownerHomePlaceholder => 'Dashboard Pemilik';

  @override
  String get sitterHero => 'Kamu sayang hewan? Dapatkan penghasilan dari sini.';

  @override
  String get sitterLandingSubtitle =>
      'Tentukan sendiri jadwal dan harga. Komisi cuma 8%. Uang langsung masuk wallet, bisa ditarik kapan saja.';

  @override
  String get sitterStartNow => 'Mulai Sekarang';

  @override
  String get sitterBenefitsLine =>
      '🕐 Fleksibel • 💰 Komisi 8% • ⚡ Cair < 1 hari';

  @override
  String get sitterTestimonial1Name => 'Putri';

  @override
  String get sitterTestimonial1Quote =>
      'Awalnya cuma coba-coba, sekarang tiap minggu pasti ada aja yang booking. Paling seneng bisa sambil olahraga, bonusnya dapet duit!';

  @override
  String get sitterTestimonial2Name => 'Rian';

  @override
  String get sitterTestimonial2Quote =>
      'Alat grooming udah numpuk di rumah, eh ternyata banyak yang butuh jasa grooming panggilan. Sekarang aku bisa buka layanan dari rumah.';

  @override
  String get sitterHeroSubtitle =>
      'Komisi hanya 8%, pencairan kurang dari 1 hari, kerja fleksibel sesuai waktumu.';

  @override
  String get sitterStatActive => '50+ sitter aktif';

  @override
  String get sitterStatBookings => '10+ booking/bulan';

  @override
  String get sitterBadgeNew => 'Baru';

  @override
  String sitterNewRequestsSubtitle(int count) {
    return 'Ada $count permintaan baru di sekitarmu';
  }

  @override
  String get sitterPlatformFee => 'Biaya platform 8%';

  @override
  String get sitterPayout => 'Pencairan < 1 hari';

  @override
  String get sitterRegisterCta => 'Daftar Jadi Mitra';

  @override
  String get adminLoginTitle => 'Panel Admin';

  @override
  String get adminPanelPlaceholder => 'Panel Admin - Coming Soon';

  @override
  String get authLogin => 'Masuk';

  @override
  String get authRegister => 'Daftar';

  @override
  String get authPhone => 'Nomor WA';

  @override
  String get authPhoneHint => '0812, 62812, atau +62812';

  @override
  String get authPassword => 'Kata sandi';

  @override
  String get authPasswordHint => 'Min. 6 karakter';

  @override
  String get authName => 'Nama';

  @override
  String get authRole => 'Pilih peran';

  @override
  String get authRoleOwner => 'Pemilik hewan';

  @override
  String get authRoleSitter => 'Pengasuh';

  @override
  String get authNoAccount => 'Belum punya akun?';

  @override
  String get authHasAccount => 'Sudah punya akun?';

  @override
  String get authInvalidPhone =>
      'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.';

  @override
  String get authInvalidPassword => 'Kata sandi minimal 6 karakter.';

  @override
  String get authNameRequired => 'Nama wajib diisi.';

  @override
  String get authFailed => 'Permintaan gagal. Coba lagi.';

  @override
  String get authLogout => 'Keluar';

  @override
  String get authForgotPassword => 'Lupa kata sandi?';

  @override
  String get authForgotPasswordSubtitle =>
      'Masukkan nomor WA terdaftar. Kode reset dikirim ke notifikasi in-app Anda.';

  @override
  String get authSendResetCode => 'Kirim kode reset';

  @override
  String get authHaveResetCode => 'Sudah punya kode reset?';

  @override
  String get authBackToLogin => 'Kembali ke masuk';

  @override
  String get authResetPassword => 'Reset kata sandi';

  @override
  String get authResetPasswordSubtitle =>
      'Masukkan nomor, kode reset dari notifikasi, dan kata sandi baru.';

  @override
  String get authResetCode => 'Kode reset';

  @override
  String get authResetCodeRequired => 'Kode reset wajib diisi.';

  @override
  String get authNewPassword => 'Kata sandi baru';

  @override
  String get authResetSuccess => 'Kata sandi berhasil diubah. Silakan masuk.';

  @override
  String get wwwOpenApp => 'Buka aplikasi';

  @override
  String get authAccessDenied => 'Akses ditolak untuk domain ini.';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionNext => 'Lanjut';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionContinue => 'Lanjut ke Dashboard';

  @override
  String get actionEditProfile => 'Edit Profil';

  @override
  String get loadFailed => 'Gagal memuat data. Tarik untuk muat ulang.';

  @override
  String get saveFailed => 'Gagal menyimpan. Coba lagi.';

  @override
  String get sitterOnboardingTitle => 'Onboarding Pengasuh';

  @override
  String get sitterOnboardingStepServices => 'Pilih Layanan';

  @override
  String get sitterOnboardingStepProfile => 'Isi Profil';

  @override
  String get sitterOnboardingStepVerify => 'Verifikasi';

  @override
  String get sitterOnboardingSelectServices =>
      'Pilih layanan yang Anda tawarkan';

  @override
  String get sitterOnboardingServicesRequired => 'Pilih minimal satu layanan.';

  @override
  String get sitterOnboardingBio => 'Cerita & pengalaman';

  @override
  String get sitterOnboardingAddress => 'Alamat';

  @override
  String get sitterOnboardingAddressRequired => 'Alamat wajib diisi.';

  @override
  String get sitterOnboardingBioRequired => 'Bio wajib diisi.';

  @override
  String get sitterOnboardingSubmit => 'Ajukan Verifikasi';

  @override
  String get sitterOnboardingWaitingTitle => 'Menunggu Verifikasi';

  @override
  String get sitterOnboardingWaitingMessage =>
      'Profil Anda sedang ditinjau tim Kaki Empat. Kami akan memberi tahu setelah disetujui.';

  @override
  String get sitterHomeTitle => 'Beranda Pengasuh';

  @override
  String sitterGreeting(String name, int count) {
    return 'Halo, $name! 🌟 Ada $count permintaan baru di dekatmu.';
  }

  @override
  String sitterGreetingNoRequests(String name) {
    return 'Halo, $name! 🌟 Siap menerima permintaan hari ini?';
  }

  @override
  String sitterMonthlyEarnings(String amount) {
    return 'Bulan ini: $amount';
  }

  @override
  String get sitterOfferPrice => 'Tawarkan Harga';

  @override
  String sitterRequestDistanceFromYou(String km) {
    return '📍 $km km dari kamu';
  }

  @override
  String get sitterHomePlaceholder =>
      'Selamat datang! Dashboard pengasuh akan segera hadir di sini.';

  @override
  String get sitterProfileTitle => 'Profil Pengasuh';

  @override
  String get sitterProfileBio => 'Bio';

  @override
  String get sitterProfileAddress => 'Alamat';

  @override
  String get sitterProfileServices => 'Layanan';

  @override
  String get sitterProfileStatus => 'Status verifikasi';

  @override
  String get sitterStatusDraft => 'Draft';

  @override
  String get sitterStatusPending => 'Menunggu verifikasi';

  @override
  String get sitterStatusApproved => 'Disetujui';

  @override
  String get sitterStatusRejected => 'Ditolak';

  @override
  String get ownerProfileTitle => 'Profil Pemilik';

  @override
  String get ownerProfileOnboardingHint =>
      'Isi alamat dan tambahkan minimal satu hewan untuk mulai memesan layanan.';

  @override
  String get ownerProfileAddress => 'Alamat rumah';

  @override
  String get ownerProfileAddressEmpty => 'Alamat belum diisi';

  @override
  String get ownerProfileAddressHint =>
      'Alamat digunakan untuk layanan di lokasi Anda.';

  @override
  String get ownerProfilePets => 'Hewan Peliharaan';

  @override
  String get ownerProfilePetsEmpty => 'Belum ada hewan terdaftar.';

  @override
  String get ownerProfileAddPet => 'Tambah Hewan';

  @override
  String get addPetTitle => 'Tambah Hewan';

  @override
  String get petName => 'Nama hewan';

  @override
  String get petSpecies => 'Spesies';

  @override
  String get petSpeciesHint => 'Anjing, kucing, dll.';

  @override
  String get petBreed => 'Ras';

  @override
  String get petAge => 'Usia';

  @override
  String get petWeight => 'Berat (kg)';

  @override
  String get petNotes => 'Catatan perilaku';

  @override
  String get petNameRequired => 'Nama wajib diisi.';

  @override
  String get petSpeciesRequired => 'Spesies wajib diisi.';

  @override
  String get catalogLoadFailed => 'Gagal memuat katalog layanan.';

  @override
  String get valueEmpty => '—';

  @override
  String get ownerHomeTitle => 'Beranda';

  @override
  String get ownerHomeSubtitle => 'Layanan Populer';

  @override
  String ownerGreeting(String name) {
    return 'Halo, $name! 🐾 Mau ajak siapa hari ini?';
  }

  @override
  String get ownerViewAllServices => 'Lihat Semua Layanan';

  @override
  String get ownerActiveBookings => 'Booking Aktif';

  @override
  String get ownerPetQuickWalk => 'Jalan pagi';

  @override
  String get ownerPetQuickBath => 'Mandi';

  @override
  String get ownerPetQuickCheckup => 'Periksa';

  @override
  String get ownerGreetingSubtitle => 'Mau ajak jalan siapa hari ini?';

  @override
  String get ownerActiveBookingsTitle => 'Booking Aktif';

  @override
  String get ownerActiveBookingsEmpty => 'Belum ada booking aktif.';

  @override
  String get ownerFavoriteSittersTitle => 'Sitter Favorit';

  @override
  String get ownerFavoriteSittersEmpty =>
      'Belum ada sitter favorit. Simpan dari penawaran masuk.';

  @override
  String ownerCategoryServiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count layanan',
      one: '1 layanan',
    );
    return '$_temp0';
  }

  @override
  String get ownerServicesInCategory => 'Layanan';

  @override
  String get ownerMyBookings => 'Booking Saya';

  @override
  String get ownerOnboardingBannerTitle => 'Lengkapi profil Anda';

  @override
  String get ownerOnboardingBannerBody =>
      'Isi alamat dan tambahkan minimal satu hewan sebelum memesan.';

  @override
  String get ownerFillAddress => 'Isi Alamat';

  @override
  String get ownerAddPet => 'Tambah Hewan';

  @override
  String get createRequestTitle => 'Cari Pengasuh';

  @override
  String get createRequestPet => 'Pilih hewan';

  @override
  String get createRequestDate => 'Tanggal';

  @override
  String get createRequestTime => 'Waktu mulai';

  @override
  String get createRequestDuration => 'Durasi';

  @override
  String createRequestDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours jam',
      one: '1 jam',
    );
    return '$_temp0';
  }

  @override
  String get createRequestLocation => 'Lokasi';

  @override
  String get createRequestNotes => 'Catatan (opsional)';

  @override
  String get createRequestPrice => 'Harga yang ditawarkan (Rp)';

  @override
  String get createRequestSubmit => 'Cari Pengasuh';

  @override
  String get createRequestSuccess =>
      '✅ Booking berhasil! Sitter akan segera merespons.';

  @override
  String get ownerOpenRequestsTitle => 'Permintaan Aktif';

  @override
  String get ownerOpenRequestsEmpty => 'Belum ada permintaan terbuka.';

  @override
  String ownerPendingOffers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penawaran',
      one: '1 penawaran',
      zero: 'Tidak ada penawaran',
    );
    return '$_temp0';
  }

  @override
  String get ownerRequestOffersTitle => 'Penawaran Pengasuh';

  @override
  String get ownerRequestOffersHeading => 'Penawaran masuk';

  @override
  String get ownerRequestOffersEmpty =>
      'Belum ada penawaran untuk permintaan ini.';

  @override
  String get ownerAcceptOfferTitle => 'Terima Penawaran';

  @override
  String ownerAcceptOfferConfirm(String sitterName, String price) {
    return 'Terima penawaran dari $sitterName seharga $price?';
  }

  @override
  String get ownerAcceptOfferAction => 'Terima Penawaran';

  @override
  String get ownerAcceptOfferSuccess => 'Penawaran diterima. Booking dibuat.';

  @override
  String get createRequestSelectPet => 'Pilih minimal satu hewan.';

  @override
  String get createRequestSelectDate => 'Pilih tanggal.';

  @override
  String get createRequestSelectTime => 'Pilih waktu mulai.';

  @override
  String get createRequestLocationRequired => 'Lokasi wajib diisi.';

  @override
  String get createRequestServiceRequired => 'Layanan wajib dipilih.';

  @override
  String get createRequestPriceHint => 'Tarif yang Anda tawarkan';

  @override
  String get createRequestPriceRequired => 'Harga harus lebih dari nol.';

  @override
  String get ownerProfileLocationHint =>
      'Izinkan lokasi browser agar pengasuh di sekitar dapat menemukan permintaan Anda.';

  @override
  String get sitterAvailabilityTitle => 'Siap terima pesanan';

  @override
  String get sitterAvailabilityOffHint =>
      'Nonaktif — permintaan baru tidak ditampilkan.';

  @override
  String get requestSkipOffer => 'Lewati permintaan';

  @override
  String get sitterRequestsTitle => 'Permintaan Tersedia';

  @override
  String get sitterRequestsEmpty =>
      'Belum ada permintaan di sekitarmu. Cek lagi nanti ☕';

  @override
  String get sitterFilterService => 'Layanan';

  @override
  String get sitterFilterAllServices => 'Semua layanan';

  @override
  String get sitterFilterRadius => 'Radius (km)';

  @override
  String get sitterFilterRadiusAll => 'Semua jarak';

  @override
  String sitterRequestDistance(String km) {
    return '$km km';
  }

  @override
  String get sitterBroadcastRadiusBadge => 'Dalam Radius 7km';

  @override
  String get sitterPollingSearching => 'Mencari permintaan baru...';

  @override
  String sitterNewRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permintaan baru',
      one: '1 permintaan baru',
    );
    return '$_temp0';
  }

  @override
  String sitterRequestsInRadius(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permintaan dalam radius',
      one: '1 permintaan dalam radius',
      zero: 'Tidak ada permintaan dalam radius',
    );
    return '$_temp0';
  }

  @override
  String createRequestSitterEstimate(int count) {
    return 'Estimasi ~$count pengasuh dalam radius 7 km akan melihat permintaan ini';
  }

  @override
  String get createRequestSitterEstimateLoading =>
      'Menghitung pengasuh terdekat…';

  @override
  String createRequestSuccessBroadcast(int count) {
    return 'Permintaan dikirim. ~$count pengasuh dalam radius 7 km akan melihat permintaan ini.';
  }

  @override
  String get requestDetailTitle => 'Detail Permintaan';

  @override
  String get requestDetailOwner => 'Pemilik hewan';

  @override
  String get requestDetailPets => 'Hewan';

  @override
  String get requestDetailSchedule => 'Jadwal';

  @override
  String get requestDetailLocation => 'Lokasi';

  @override
  String get requestDetailNotes => 'Catatan';

  @override
  String get requestDetailPrice => 'Anggaran pemilik';

  @override
  String get requestOfferPrice => 'Penawaran Anda (Rp)';

  @override
  String get requestOfferMessage => 'Pesan (opsional)';

  @override
  String get requestOfferSubmit => 'Tawarkan Harga';

  @override
  String get requestOfferSuccess =>
      '💰 Tawaran terkirim! Menunggu respons pemilik.';

  @override
  String get bookingDetailTitle => 'Detail Booking';

  @override
  String get bookingDetailStatus => 'Status';

  @override
  String get bookingDetailTimeline => 'Linimasa';

  @override
  String get bookingDetailService => 'Layanan';

  @override
  String get bookingDetailSchedule => 'Jadwal';

  @override
  String get bookingDetailAmount => 'Nominal';

  @override
  String get bookingDetailPay => 'Bayar Sekarang';

  @override
  String get bookingDetailConfirm => 'Konfirmasi Booking';

  @override
  String get bookingDetailEnRoute => 'Tandai Dalam Perjalanan';

  @override
  String get bookingDetailStart => 'Mulai Layanan';

  @override
  String get bookingDetailComplete => 'Selesaikan Layanan';

  @override
  String get bookingDetailCancel => 'Batalkan Booking';

  @override
  String get bookingDetailActionSuccess => 'Booking diperbarui.';

  @override
  String get bookingStatusOpen => 'Menunggu pengasuh';

  @override
  String get bookingStatusMatched => 'Sudah ditugaskan';

  @override
  String get bookingStatusPending => 'Menunggu konfirmasi';

  @override
  String get bookingStatusAwaitingPayment => 'Menunggu pembayaran';

  @override
  String get bookingStatusPendingVerification => 'Verifikasi pembayaran';

  @override
  String get bookingStatusPaid => 'Lunas';

  @override
  String get bookingStatusPaymentRejected => 'Pembayaran ditolak';

  @override
  String get bookingStatusCancelled => 'Dibatalkan';

  @override
  String get bookingStatusConfirmed => 'Dikonfirmasi';

  @override
  String get bookingStatusEnRoute => 'Dalam perjalanan';

  @override
  String get bookingStatusInProgress => 'Sedang berlangsung';

  @override
  String get bookingStatusCompleted => 'Selesai 🎉';

  @override
  String get bookingTimelineCreated => 'Permintaan dibuat';

  @override
  String get bookingTimelineMatched => 'Pengasuh ditugaskan';

  @override
  String get bookingTimelinePaid => 'Pembayaran diterima';

  @override
  String get bookingTimelineConfirmed => 'Dikonfirmasi pengasuh';

  @override
  String get bookingTimelineEnRoute => 'Pengasuh dalam perjalanan';

  @override
  String get bookingTimelineInProgress => 'Layanan dimulai';

  @override
  String get bookingTimelineCompleted => 'Layanan selesai';

  @override
  String get ownerBookingsEmpty => 'Belum ada booking';

  @override
  String get sitterMyBookings => 'Booking Saya';

  @override
  String get sitterVerificationRequired =>
      'Verifikasi profil diperlukan untuk melihat permintaan.';

  @override
  String requestPetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hewan',
      one: '1 hewan',
    );
    return '$_temp0';
  }

  @override
  String createRequestTotalPreview(String total, String fee) {
    return 'Total dibayar: $total (termasuk biaya platform $fee)';
  }

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get bookingDetailCancelConfirm => 'Yakin batalkan booking ini? 🥺';

  @override
  String get sitterActiveBookingsEmpty => 'Belum ada booking aktif.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmpty => 'Belum ada pesan';

  @override
  String get chatInputHint => 'Ketik pesan…';

  @override
  String get chatSendFailed => 'Gagal mengirim pesan. Coba lagi.';

  @override
  String get bookingDetailChat => 'Buka Chat';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get notificationsEmpty => 'Belum ada notifikasi';

  @override
  String get notificationsMarkAllRead => 'Tandai Semua Dibaca';

  @override
  String get adminDashboardTitle => 'Panel Admin Kaki Empat';

  @override
  String get adminSummarySitters => 'Total Sitter';

  @override
  String get adminSummaryOwners => 'Total Owner';

  @override
  String get adminSummaryBookings => 'Total Booking';

  @override
  String get adminSummaryPending => 'Verifikasi Pending';

  @override
  String get adminTabSitters => 'Pengasuh';

  @override
  String get adminTabOwners => 'Pemilik';

  @override
  String get adminTabBookings => 'Booking';

  @override
  String get adminTabWithdrawals => 'Pencairan';

  @override
  String get adminTabPayments => 'Pembayaran';

  @override
  String get adminApprove => 'Setujui';

  @override
  String get adminReject => 'Tolak';

  @override
  String get adminActive => 'Aktif';

  @override
  String get adminInactive => 'Nonaktif';

  @override
  String get adminSittersEmpty => 'Tidak ada pengasuh menunggu verifikasi.';

  @override
  String get adminOwnersEmpty => 'Belum ada pemilik terdaftar.';

  @override
  String get adminBookingsEmpty => 'Tidak ada booking.';

  @override
  String get adminWithdrawalsEmpty => 'Tidak ada permintaan pencairan pending.';

  @override
  String adminSitterApproved(String name) {
    return '$name disetujui';
  }

  @override
  String adminSitterRejected(String name) {
    return '$name ditolak';
  }

  @override
  String get adminWithdrawalApproved => 'Pencairan disetujui.';

  @override
  String get paymentTitle => 'Pembayaran';

  @override
  String get paymentMethodTitle =>
      'WISE / REVOLUT / TRANSFER BANK INTERNASIONAL';

  @override
  String get paymentTabWise => 'Wise';

  @override
  String get paymentTabRevolut => 'Revolut';

  @override
  String get paymentTabBankTransfer => 'Transfer Bank';

  @override
  String get paymentWiseStep1 => 'Buka aplikasi Wise di ponsel Anda.';

  @override
  String get paymentWiseStep2 =>
      'Pilih Kirim Uang → Transfer internasional → penerima IDR.';

  @override
  String get paymentWiseStep3 =>
      'Masukkan detail rekening SeaBank kami di atas.';

  @override
  String get paymentWiseStep4 =>
      'Kirim nominal persis seperti di bawah, termasuk kode unik.';

  @override
  String get paymentRevolutStep1 => 'Buka aplikasi Revolut di ponsel Anda.';

  @override
  String get paymentRevolutStep2 =>
      'Pilih Kirim → Transfer internasional → penerima IDR.';

  @override
  String get paymentRevolutStep3 =>
      'Masukkan detail rekening SeaBank kami di atas.';

  @override
  String get paymentRevolutStep4 =>
      'Kirim nominal persis seperti di bawah, termasuk kode unik.';

  @override
  String get paymentBankStep1 =>
      'Gunakan aplikasi mobile banking atau internet banking Anda.';

  @override
  String get paymentBankStep2 =>
      'Pilih transfer internasional atau SWIFT ke Indonesia (IDR).';

  @override
  String get paymentBankStep3 =>
      'Masukkan detail rekening SeaBank kami di atas.';

  @override
  String get paymentBankStep4 =>
      'Kirim nominal persis seperti di bawah, termasuk kode unik.';

  @override
  String paymentMethodDescription(String feePercent) {
    return 'Kami menerima transfer peer-to-peer via Wise atau Revolut. Tarif layanan ditambah biaya platform $feePercent% sudah termasuk di total di bawah.';
  }

  @override
  String get paymentBankDetailsTitle => 'DETAIL REKENING PENERIMA (INDONESIA)';

  @override
  String get paymentBankName => 'Nama Bank';

  @override
  String get paymentBankCode => 'Kode Bank';

  @override
  String get paymentAccountNo => 'No. Rekening';

  @override
  String get paymentAccountName => 'Nama Rekening';

  @override
  String get paymentHowToPay => 'CARA BAYAR';

  @override
  String get paymentAmountToSend => 'Nominal Transfer';

  @override
  String get paymentServiceRate => 'Tarif Layanan';

  @override
  String paymentPlatformFee(String percent) {
    return 'Biaya Platform ($percent%)';
  }

  @override
  String get paymentExactAmountHint =>
      'Harap kirim nominal PERSIS termasuk kode unik untuk aktivasi otomatis.';

  @override
  String get paymentReferenceLabel => 'Kode Referensi Transfer Wise/Revolut';

  @override
  String get paymentReferenceHint => 'contoh TRANSFER-123456789';

  @override
  String get paymentReferenceRequired => 'Kode referensi transfer wajib diisi.';

  @override
  String get paymentUploadProof => 'Upload Bukti Transfer';

  @override
  String paymentProofSelected(String fileName) {
    return 'Bukti: $fileName';
  }

  @override
  String get paymentConfirm => 'Konfirmasi Pembayaran';

  @override
  String get paymentSubmitFailed =>
      'Gagal mengirim bukti pembayaran. Coba lagi.';

  @override
  String get paymentCopied => 'Disalin ke clipboard';

  @override
  String get paymentWaitingVerification => 'Menunggu Verifikasi Admin';

  @override
  String get paymentWaitingVerificationId => 'Menunggu Verifikasi';

  @override
  String get paymentWaitingVerificationBody =>
      'Bukti pembayaran Anda telah diterima. Tim kami akan memverifikasi transfer Anda segera.';

  @override
  String get paymentSuccess => 'Pembayaran Berhasil';

  @override
  String get paymentSuccessId => 'Pembayaran Berhasil';

  @override
  String get paymentBackToDashboard => 'Kembali ke Dashboard';

  @override
  String get paymentDetails => 'Rincian Pembayaran';

  @override
  String get paymentTotalPaid => 'Total Dibayar';

  @override
  String get walletTitle => 'Dompet';

  @override
  String get walletAvailableBalance => 'Saldo Tersedia';

  @override
  String get walletWithdraw => 'Tarik Saldo';

  @override
  String get walletEarningsBreakdown => 'Rincian Pendapatan';

  @override
  String get walletGrossIncome => 'Pendapatan Kotor';

  @override
  String walletPlatformFee(String percent) {
    return 'Biaya Platform ($percent%)';
  }

  @override
  String get walletNetIncome => 'Pendapatan Bersih';

  @override
  String get walletWithdrawalRequests => 'Permintaan Penarikan';

  @override
  String get walletWithdrawalsEmpty => 'Belum ada permintaan penarikan.';

  @override
  String get walletTransactionHistory => 'Riwayat Transaksi';

  @override
  String get walletTransactionsEmpty => 'Belum ada transaksi.';

  @override
  String get walletWithdrawDialogTitle => 'Tarik Saldo';

  @override
  String get walletAmountLabel => 'Nominal (IDR)';

  @override
  String get walletAmountHint => 'Min. 10.000';

  @override
  String get walletMethodLabel => 'Metode';

  @override
  String get walletMethodQris => 'QRIS';

  @override
  String get walletMethodBank => 'Rekening Bank';

  @override
  String get walletDestinationLabel => 'Tujuan';

  @override
  String get walletDestinationHint => 'Kode QRIS atau nomor rekening';

  @override
  String get walletWithdrawSubmit => 'Kirim';

  @override
  String get walletWithdrawSent => 'Permintaan penarikan dikirim.';

  @override
  String get walletWithdrawPending => 'Menunggu Diproses';

  @override
  String get walletWithdrawPendingId => 'Menunggu Diproses';

  @override
  String get walletLoadFailed => 'Gagal memuat dompet.';

  @override
  String get errorStateTitle => 'Gagal memuat data';

  @override
  String get errorStateRetry => 'Coba lagi';

  @override
  String get errorStateBody =>
      'Terjadi kesalahan. Periksa koneksi internet Anda dan coba lagi.';

  @override
  String get loadMore => 'Muat lebih banyak';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterLast7Days => '7 hari';

  @override
  String get filterLast30Days => '30 hari';

  @override
  String get filterLast90Days => '90 hari';

  @override
  String get bookingHistoryTitle => 'Riwayat Booking';

  @override
  String get bookingHistoryEmpty => 'Belum ada riwayat booking.';

  @override
  String get bookingHistoryFilterDate => 'Filter tanggal';

  @override
  String get bookingHistoryFilterStatus => 'Status';

  @override
  String get reviewTitle => 'Bagaimana pengalamanmu?';

  @override
  String reviewForSitter(String sitterName) {
    return 'Ulasan untuk $sitterName';
  }

  @override
  String get reviewRatingLabel => 'Rating';

  @override
  String get reviewCommentLabel => 'Komentar';

  @override
  String get reviewCommentHint => 'Ceritakan pengalaman Anda...';

  @override
  String get reviewSubmit => 'Kirim Ulasan';

  @override
  String get reviewSubmitSuccess => 'Ulasan berhasil dikirim.';

  @override
  String get reviewLeaveAction => 'Beri ulasan';

  @override
  String get reviewAlreadySubmitted => 'Ulasan sudah dikirim';

  @override
  String get darkModeTitle => 'Mode gelap';

  @override
  String get profileStatsTitle => 'Statistik';

  @override
  String profileStatsBookings(int count) {
    return '$count booking';
  }

  @override
  String profileStatsPets(int count) {
    return '$count hewan';
  }

  @override
  String get profileStatsEarnings => 'Pendapatan bersih';

  @override
  String get profileBookingHistory => 'Riwayat booking';

  @override
  String get profileEditPet => 'Edit hewan';

  @override
  String get deletePetConfirm => 'Hapus hewan ini dari profil?';

  @override
  String get sortLabel => 'Urutkan';

  @override
  String get sortPriceLow => 'Harga terendah';

  @override
  String get sortPriceHigh => 'Harga tertinggi';

  @override
  String get sortRating => 'Rating tertinggi';

  @override
  String get favoriteAdd => 'Simpan favorit';

  @override
  String get favoriteRemove => 'Hapus favorit';

  @override
  String get favoritesTitle => 'Sitter favorit';

  @override
  String get inAppNotificationsHint =>
      'Notifikasi real-time via polling API (tanpa Firebase).';

  @override
  String get onboardingOwnerTitle => 'Selamat datang, Owner!';

  @override
  String get onboardingOwnerStep1 =>
      'Lengkapi alamat dan tambahkan hewan peliharaan.';

  @override
  String get onboardingOwnerStep2 =>
      'Pilih layanan, buat permintaan, dan terima penawaran sitter.';

  @override
  String get onboardingOwnerStep3 =>
      'Bayar, lacak booking, dan beri ulasan setelah selesai.';

  @override
  String get onboardingSitterTitle => 'Selamat datang, Sitter!';

  @override
  String get onboardingSitterStep1 =>
      'Lengkapi profil dan layanan yang Anda tawarkan.';

  @override
  String get onboardingSitterStep2 =>
      'Setelah disetujui admin, lihat permintaan di sekitar Anda.';

  @override
  String get onboardingSitterStep3 =>
      'Kirim penawaran, kelola booking, dan tarik pendapatan.';

  @override
  String get onboardingGotIt => 'Mengerti';

  @override
  String get onboardingNext => 'Lanjut';

  @override
  String get tooltipNotifications => 'Notifikasi in-app';

  @override
  String get tooltipProfile => 'Profil & pengaturan';

  @override
  String get tooltipBookingHistory => 'Riwayat booking';

  @override
  String get tooltipLogout => 'Keluar dari akun';

  @override
  String get tooltipWallet => 'Dompet & pencairan';

  @override
  String get searchHint => 'Cari...';

  @override
  String get sitterActiveBookingsTitle => 'Booking Aktif';

  @override
  String get authLoginSubtitle =>
      'Senang bertemu lagi! Masuk untuk melanjutkan perawatan hewan Anda.';

  @override
  String get authRegisterSubtitle =>
      'Buat akun gratis dan temukan pengasuh terpercaya di dekat Anda.';

  @override
  String get authLoginSuccess => 'Login berhasil! Mengalihkan…';

  @override
  String get authRegisterSuccess =>
      'Pendaftaran berhasil! Selamat datang di Kaki Empat.';

  @override
  String get authNameHint => 'Nama lengkap Anda';

  @override
  String get wwwAuthHubTitle => 'Akun Kaki Empat';

  @override
  String get wwwNavBrand => 'Kaki Empat';

  @override
  String get wwwNavMenu => 'Menu';

  @override
  String get wwwNavHome => 'Beranda';

  @override
  String get wwwNavServices => 'Layanan';

  @override
  String get wwwNavPricing => 'Harga';

  @override
  String get wwwNavSignup => 'Jadi Pengasuh';

  @override
  String get wwwNavBlog => 'Tips';

  @override
  String get wwwNavTestimonials => 'Testimoni';

  @override
  String get wwwNavApps => 'Aplikasi';

  @override
  String get wwwOpenOwnerApp => 'Buka app pemilik';

  @override
  String get wwwOpenSitterApp => 'Buka app pengasuh';

  @override
  String get wwwOpenAdminApp => 'Buka panel admin';

  @override
  String get wwwOpenStagingApp => 'Staging (QA)';

  @override
  String get wwwFooterTagline =>
      'Platform pengasuhan hewan terpercaya di Indonesia.';

  @override
  String get wwwFooterSections => 'Halaman';

  @override
  String wwwFooterCopyright(int year, String appName) {
    return '© $year $appName. Semua hak dilindungi.';
  }

  @override
  String get ownerPetsTitle => 'Hewan peliharaan';

  @override
  String get ownerAddFirstPetCta => 'Tambahkan hewan pertama Anda!';

  @override
  String get ownerCreateRequestFab => 'Cari Pengasuh';

  @override
  String get ownerCreateRequestFabHint =>
      'Pilih layanan lalu buat permintaan baru';

  @override
  String get sitterRequestsEmptyTip =>
      'Lengkapi profil untuk dapat lebih banyak permintaan';

  @override
  String get sitterCompleteProfileCta => 'Lengkapi profil';

  @override
  String get sitterFaqTitle => 'Tips & Bantuan';

  @override
  String get sitterFaqIntro =>
      'Jawaban singkat untuk pertanyaan umum pengasuh Kaki Empat.';

  @override
  String get sitterFaqQ1 => 'Bagaimana cara mendapat lebih banyak permintaan?';

  @override
  String get sitterFaqA1 =>
      'Lengkapi bio, alamat, dan layanan yang Anda tawarkan. Profil yang jelas dan foto menarik membantu owner memilih Anda.';

  @override
  String get sitterFaqQ2 => 'Berapa harga penawaran yang wajar?';

  @override
  String get sitterFaqA2 =>
      'Lihat harga permintaan owner sebagai patokan. Sesuaikan dengan pengalaman dan jarak tempuh. Terlalu tinggi bisa mengurangi peluang diterima.';

  @override
  String get sitterFaqQ3 => 'Kapan pendapatan masuk ke dompet?';

  @override
  String get sitterFaqA3 =>
      'Setelah booking selesai dan owner memberi ulasan (atau otomatis setelah 48 jam), pendapatan bersih masuk ke dompet Anda.';

  @override
  String get sitterFaqQ4 => 'Bagaimana cara tarik saldo?';

  @override
  String get sitterFaqA4 =>
      'Buka menu Dompet, masukkan jumlah dan rekening/QRIS tujuan. Pencairan diproses dalam 1×24 jam kerja.';

  @override
  String get sitterOfferPriceTip =>
      'Tips: mulai dari harga permintaan owner, lalu sesuaikan dengan pengalaman Anda.';

  @override
  String sitterEarningsEstimate(String amount) {
    return 'Estimasi pendapatan bersih: $amount (setelah biaya platform 8%)';
  }

  @override
  String get ownerGuideTip1 =>
      'Pilih sitter dengan rating tinggi dan ulasan positif.';

  @override
  String get ownerGuideTip2 =>
      'Bayar hanya melalui rekening resmi Kaki Empat — jangan transfer langsung ke sitter.';

  @override
  String get ownerGuideTip3 =>
      'Siapkan makanan, leash, dan catatan kesehatan hewan sebelum jadwal dimulai.';

  @override
  String adminStatSitters(int count) {
    return '$count Sitter';
  }

  @override
  String adminStatOwners(int count) {
    return '$count Owner';
  }

  @override
  String adminStatPendingVerify(int count) {
    return '$count Perlu Verifikasi';
  }

  @override
  String adminStatTransactions(String amount) {
    return '$amount Transaksi';
  }

  @override
  String get adminPendingActionsTitle => 'Perlu Tindakan';

  @override
  String adminActionNewSitter(String name, String services) {
    return '📋 Sitter baru: $name ($services)';
  }

  @override
  String adminActionPayment(String amount, String owner) {
    return '💳 Pembayaran: $amount dari $owner';
  }

  @override
  String adminActionWithdrawal(String amount, String destination) {
    return '🏧 Pencairan: $amount ke $destination';
  }

  @override
  String get pullRefreshSearching => 'Mencari permintaan baru...';

  @override
  String get statsBookingsLabel => 'booking berhasil';

  @override
  String get statsRatingLabel => 'rating sitter';

  @override
  String get statsCitiesValue => '3 kota';

  @override
  String get statsCitiesLabel => 'Denpasar, Surabaya, Jakarta';

  @override
  String get statsPayoutLabel => 'disalurkan ke mitra';

  @override
  String get sitterTestimonialsTitle => 'Cerita dari Mitra Kami';

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
      'Jadi lebih fleksibel. Owner senang karena hewannya nggak perlu stres ke klinik.';

  @override
  String get ownerStoriesTitle => 'Cerita Pemilik Hewan';

  @override
  String get ownerStory1Name => 'Maya';

  @override
  String get ownerStory1Subtitle => 'Pemilik Milo';

  @override
  String get ownerStory1Quote =>
      'Milo anjingnya hiperaktif, susah banget ditinggal kerja. Sejak pakai Kaki Empat, tiap siang ada yang ngajak jalan. Sekarang Milo udah nggak ngerusak sofa lagi!';

  @override
  String get ownerStory2Name => 'Alex';

  @override
  String get ownerStory2Subtitle => 'Bule di Bali';

  @override
  String get ownerStory2Quote =>
      'I was worried leaving my dog at a pet hotel. But the sitter sent me photos every hour. I could enjoy my vacation without feeling guilty.';

  @override
  String get ownerStory3Name => 'Sari';

  @override
  String get ownerStory3Subtitle => 'Jakarta';

  @override
  String get ownerStory3Quote =>
      'Kucingku perlu grooming rutin tapi males ke salon. Ada sitter yang datang ke rumah, selesai dalam 1 jam. Kucingku happy, aku happy!';

  @override
  String get storiFeedTitle => 'Cerita Harian';

  @override
  String get storiFeedSubtitle => 'Aktivitas mitra pengasuh di lapangan';

  @override
  String get storiViewFeed => 'Lihat cerita harian';

  @override
  String get storiPost1Author => 'Putri · Dog Walker';

  @override
  String get storiPost1Caption =>
      'Jalan pagi bareng Milo 🐕. Dia seneng banget ketemu temen baru di taman.';

  @override
  String get storiPost2Author => 'Rian · Grooming';

  @override
  String get storiPost2Caption =>
      'Hasil grooming hari ini! Coco sekarang kinclong ✨✂️';

  @override
  String get storiPost3Author => 'Dewi · Vet';

  @override
  String get storiPost3Caption =>
      'Kunjungan ke rumah Bu Sari. Kucingnya manis banget, langsung nurut pas dikasih vitamin.';

  @override
  String get storiPost4Author => 'Andi · Pet Taxi';

  @override
  String get storiPost4Caption =>
      'First time pet taxi! Jemput Max dari vet, dia tenang banget di perjalanan 🚗';

  @override
  String get storiTime2h => '2 jam lalu';

  @override
  String get storiTime5h => '5 jam lalu';

  @override
  String get storiTime1d => '1 hari lalu';

  @override
  String get storiTime2d => '2 hari lalu';

  @override
  String storiLikes(int count) {
    return '$count suka';
  }

  @override
  String storiComments(int count) {
    return '$count komentar';
  }

  @override
  String get onboardingSkip => 'Lewati';

  @override
  String get badgeVerified => 'Terverifikasi';

  @override
  String get sitterReviewsTitle => 'Ulasan';

  @override
  String get sitterReviewsEmpty => 'Belum ada ulasan.';

  @override
  String get reviewNoComment => 'Tanpa komentar';

  @override
  String get helpFaqTitle => 'FAQ';

  @override
  String get faqSearchHint => 'Cari pertanyaan...';

  @override
  String get helpRepeatTutorial => 'Ulangi panduan singkat';

  @override
  String get faqNoResults => 'Tidak ada pertanyaan yang cocok.';

  @override
  String get faqQ1 => 'Bagaimana cara membuat permintaan booking?';

  @override
  String get faqA1 =>
      'Pilih layanan di beranda, isi jadwal dan detail hewan, lalu kirim permintaan. Sitter akan mengirim penawaran harga.';

  @override
  String get faqQ2 => 'Bagaimana memilih sitter terbaik?';

  @override
  String get faqA2 =>
      'Perhatikan badge Terverifikasi, rating, ulasan, dan harga penawaran. Buka profil sitter untuk melihat riwayat ulasan.';

  @override
  String get faqQ3 => 'Bagaimana cara membayar booking?';

  @override
  String get faqA3 =>
      'Setelah menerima penawaran, ikuti panduan pembayaran ke rekening resmi Kaki Empat. Unggah bukti transfer untuk verifikasi.';

  @override
  String get faqQ4 => 'Berapa lama verifikasi pembayaran?';

  @override
  String get faqA4 =>
      'Tim admin memverifikasi bukti pembayaran dalam 1×24 jam kerja. Anda akan mendapat notifikasi saat disetujui.';

  @override
  String get faqQ5 => 'Bagaimana sitter menarik pendapatan?';

  @override
  String get faqA5 =>
      'Buka menu Dompet, masukkan jumlah dan rekening/QRIS tujuan. Permintaan diproses admin dalam 1×24 jam kerja.';

  @override
  String get faqQ6 => 'Berapa biaya platform?';

  @override
  String get faqA6 =>
      'Kaki Empat memotong 8% dari pendapatan kotor sitter. Sisa 92% masuk ke dompet sitter sebagai pendapatan bersih.';

  @override
  String get faqQ7 => 'Bisakah membatalkan booking?';

  @override
  String get faqA7 =>
      'Booking dapat dibatalkan sebelum layanan dimulai. Status dan kebijakan refund mengikuti tahap booking saat itu.';

  @override
  String get faqQ8 => 'Kapan bisa memberi ulasan?';

  @override
  String get faqA8 =>
      'Setelah booking berstatus selesai, pemilik dapat memberi rating 1–5 bintang dan komentar di halaman detail booking.';

  @override
  String get faqQ9 => 'Apa itu program loyalitas?';

  @override
  String get faqA9 =>
      'Setiap booking selesai +10 poin. 100 poin dapat ditukar diskon Rp 10.000 di profil Anda.';

  @override
  String get faqQ10 => 'Bagaimana referral bekerja?';

  @override
  String get faqA10 =>
      'Bagikan kode referral unik Anda. Pengundang dapat bonus Rp 20.000, pengguna baru diskon 10% booking pertama.';

  @override
  String get tipsArticlesTitle => 'Tips Perawatan Hewan';

  @override
  String get tipsArticlesSubtitle =>
      'Artikel singkat untuk pemilik hewan — dapat diperluas nanti.';

  @override
  String get tipsArticle1Title => 'Nutrisi Seimbang untuk Anjing';

  @override
  String get tipsArticle1Summary =>
      'Pilih pakan sesuai usia dan aktivitas. Hindari makanan manusia berlebihan.';

  @override
  String get tipsArticle2Title => 'Rutinitas Jalan Pagi';

  @override
  String get tipsArticle2Summary =>
      '20–30 menit jalan pagi membantu energi anjing terkontrol sepanjang hari.';

  @override
  String get tipsArticle3Title => 'Grooming di Rumah';

  @override
  String get tipsArticle3Summary =>
      'Sisir bulu rutin mengurangi kusut dan menjaga kulit sehat.';

  @override
  String get tipsArticle4Title => 'Vaksin & Cacing';

  @override
  String get tipsArticle4Summary =>
      'Jadwalkan vaksin dan obat cacing sesuai rekomendasi dokter hewan.';

  @override
  String get tipsArticle5Title => 'Stimulasi Mental Kucing';

  @override
  String get tipsArticle5Summary =>
      'Mainan interaktif dan permainan singkat mencegah stres pada kucing indoor.';

  @override
  String get petGalleryTitle => 'Galeri Hewan';

  @override
  String get petGalleryUpload => 'Unggah Foto';

  @override
  String get petGalleryEmpty =>
      'Belum ada foto di galeri. Jadilah yang pertama!';

  @override
  String get petGalleryUploadSuccess => 'Foto berhasil diunggah.';

  @override
  String get earningsReportTitle => 'Laporan Penghasilan';

  @override
  String get earningsTotalBookings => 'Total booking';

  @override
  String get earningsAvgRating => 'Rata-rata rating';

  @override
  String get earningsNetIncome => 'Pendapatan bersih';

  @override
  String get earningsWeekly => 'Mingguan';

  @override
  String get earningsMonthly => 'Bulanan';

  @override
  String get earningsNoData => 'Belum ada data pendapatan.';

  @override
  String get achievementsTitle => 'Target & Pencapaian';

  @override
  String get achievementsEmpty => 'Selesaikan booking untuk mendapat lencana!';

  @override
  String get promoTitle => 'Promosi Sitter';

  @override
  String get promoCreate => 'Buat Kupon';

  @override
  String get promoEmpty => 'Belum ada kupon promo.';

  @override
  String get promoCreateSuccess => 'Kupon promo berhasil dibuat.';

  @override
  String promoDiscountLabel(int percent) {
    return 'Diskon $percent% booking pertama';
  }

  @override
  String get promoActive => 'Aktif';

  @override
  String get promoUsed => 'Terpakai';

  @override
  String get sitterVerificationKtp => 'Foto KTP';

  @override
  String get sitterVerificationSelfie => 'Selfie dengan KTP';

  @override
  String get sitterVerificationUpload => 'Unggah Dokumen';

  @override
  String get sitterVerificationDocsRequired =>
      'Unggah KTP dan selfie terlebih dahulu.';

  @override
  String get loyaltyPointsTitle => 'Poin Loyalitas';

  @override
  String get loyaltyRedeem => 'Tukar Poin';

  @override
  String get referralTitle => 'Kode Referral';

  @override
  String get referralShareHint =>
      'Bagikan kode ini ke teman. Anda dapat bonus Rp 20.000!';

  @override
  String get adminViewDocuments => 'Lihat Dokumen';

  @override
  String get adminVerificationDocs => 'Verifikasi Dokumen';

  @override
  String get ownerMenuCommunity => 'Komunitas';

  @override
  String get ownerMenuHelp => 'Bantuan';

  @override
  String get storiPost5Author => 'Maya · Owner';

  @override
  String get storiPost5Caption =>
      'Milo seneng banget jalan pagi bareng sitter 🐾';

  @override
  String get storiPost6Author => 'Budi · Dog Walker';

  @override
  String get storiPost6Caption =>
      'Latihan duduk dan stay — progress bagus hari ini!';

  @override
  String get storiPost7Author => 'Sari · Owner';

  @override
  String get storiPost7Caption =>
      'Si Belang grooming hari ini, bulu kinclong ✨';

  @override
  String get storiPost8Author => 'Lia · Boarding';

  @override
  String get storiPost8Caption => 'Tamu boarding baru: Coco si anjing lucu 🏠';

  @override
  String get storiPost9Author => 'Hendra · Owner';

  @override
  String get storiPost9Caption =>
      'Booking pertama di Kaki Empat — pengalaman lancar!';

  @override
  String get storiPost10Author => 'Nina · Grooming';

  @override
  String get storiPost10Caption =>
      'Tips: sisir bulu sebelum mandi mengurangi kusut 🛁';

  @override
  String get storiTime3d => '3 hari lalu';

  @override
  String get storiTime4d => '4 hari lalu';

  @override
  String get storiTime1w => '1 minggu lalu';

  @override
  String get adminTabLaunch => 'Peluncuran';

  @override
  String launchMetricsPhaseTitle(String current, String next) {
    return 'Fase $current → $next';
  }

  @override
  String get launchMetricsReadyBody =>
      'Semua kriteria exit terpenuhi. Anda dapat naik fase peluncuran berikutnya di MvpScope.';

  @override
  String get launchMetricsNotReadyBody =>
      'Beberapa kriteria exit belum terpenuhi. Stabilkan funnel owner sebelum naik fase.';

  @override
  String launchMetricsPendingPayments(int count) {
    return '$count bukti bayar menunggu persetujuan admin.';
  }

  @override
  String get launchMetricsChecksTitle => 'Kriteria exit (30 hari)';

  @override
  String get launchMetricUnitHours => 'jam';

  @override
  String launchMetricsSnapshot(int completed, int sitters, int total) {
    return 'Ringkasan: $completed selesai · $sitters sitter terverifikasi · $total booking (non-batal)';
  }

  @override
  String get appSwitcherTooltip => 'Ganti aplikasi';

  @override
  String get appSwitcherOwner => 'App pemilik';

  @override
  String get appSwitcherSitter => 'App pengasuh';

  @override
  String get appSwitcherAdmin => 'Panel admin';

  @override
  String get appShellHome => 'Beranda';

  @override
  String get appShellBookings => 'Booking';

  @override
  String get appShellMessages => 'Pesan';

  @override
  String get discoverTitle => 'Jelajahi';

  @override
  String get discoverEmpty => 'Belum ada layanan partner.';

  @override
  String get discoverComingSoon =>
      'Layanan partner terbuka di fase peluncuran penuh.';

  @override
  String get growthHubTitle => 'Ekosistem growth';

  @override
  String get growthHubSubtitle =>
      'Komunitas, loyalitas, dan tips perawatan hewan';

  @override
  String get growthHubGallery => 'Galeri hewan';

  @override
  String get growthHubStori => 'Stori';

  @override
  String get growthHubTips => 'Tips';

  @override
  String get ownerRecommendationsTitle => 'Rekomendasi untuk Anda';

  @override
  String ownerOffersForRequest(String service, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penawaran',
      one: '1 penawaran',
    );
    return '$service · $_temp0';
  }

  @override
  String get offerBestValue => 'Harga terbaik';

  @override
  String get referralCopyAction => 'Salin kode referral';

  @override
  String get referralCopied => 'Kode referral disalin';
}
