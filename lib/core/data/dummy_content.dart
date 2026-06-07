import 'package:flutter/material.dart';
import 'package:kaki_empat/l10n/app_localizations.dart';

class DummyTestimonial {
  const DummyTestimonial({
    required this.name,
    required this.role,
    required this.city,
    required this.quote,
    required this.rating,
    required this.initials,
    required this.avatarColor,
  });

  final String name;
  final String role;
  final String city;
  final String quote;
  final double rating;
  final String initials;
  final Color avatarColor;
}

class DummyOwnerStory {
  const DummyOwnerStory({
    required this.name,
    required this.subtitle,
    required this.quote,
    required this.initials,
    required this.avatarColor,
  });

  final String name;
  final String subtitle;
  final String quote;
  final String initials;
  final Color avatarColor;
}

class DummyStoriPost {
  const DummyStoriPost({
    required this.authorName,
    required this.caption,
    required this.icon,
    required this.gradientColors,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });

  final String authorName;
  final String caption;
  final IconData icon;
  final List<Color> gradientColors;
  final int likes;
  final int comments;
  final String timeAgo;
}

abstract final class DummyContent {
  static List<DummyTestimonial> sitterTestimonials(AppLocalizations l10n) => [
        DummyTestimonial(
          name: l10n.sitterTestimonial1Name,
          role: l10n.sitterTestimonial1Role,
          city: l10n.sitterTestimonial1City,
          quote: l10n.sitterTestimonial1Quote,
          rating: 5,
          initials: 'P',
          avatarColor: const Color(0xFF81C784),
        ),
        DummyTestimonial(
          name: l10n.sitterTestimonial2Name,
          role: l10n.sitterTestimonial2Role,
          city: l10n.sitterTestimonial2City,
          quote: l10n.sitterTestimonial2Quote,
          rating: 4.9,
          initials: 'R',
          avatarColor: const Color(0xFF64B5F6),
        ),
        DummyTestimonial(
          name: l10n.sitterTestimonial3Name,
          role: l10n.sitterTestimonial3Role,
          city: l10n.sitterTestimonial3City,
          quote: l10n.sitterTestimonial3Quote,
          rating: 5,
          initials: 'D',
          avatarColor: const Color(0xFFBA68C8),
        ),
      ];

  static List<DummyOwnerStory> ownerStories(AppLocalizations l10n) => [
        DummyOwnerStory(
          name: l10n.ownerStory1Name,
          subtitle: l10n.ownerStory1Subtitle,
          quote: l10n.ownerStory1Quote,
          initials: 'M',
          avatarColor: const Color(0xFFFFB74D),
        ),
        DummyOwnerStory(
          name: l10n.ownerStory2Name,
          subtitle: l10n.ownerStory2Subtitle,
          quote: l10n.ownerStory2Quote,
          initials: 'A',
          avatarColor: const Color(0xFF4DB6AC),
        ),
        DummyOwnerStory(
          name: l10n.ownerStory3Name,
          subtitle: l10n.ownerStory3Subtitle,
          quote: l10n.ownerStory3Quote,
          initials: 'S',
          avatarColor: const Color(0xFFF06292),
        ),
      ];

  static List<DummyStoriPost> storiPosts(AppLocalizations l10n) => [
        DummyStoriPost(
          authorName: l10n.storiPost1Author,
          caption: l10n.storiPost1Caption,
          icon: Icons.directions_walk,
          gradientColors: const [Color(0xFF1F5C4A), Color(0xFF4CAF82)],
          likes: 24,
          comments: 5,
          timeAgo: l10n.storiTime2h,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost2Author,
          caption: l10n.storiPost2Caption,
          icon: Icons.content_cut,
          gradientColors: const [Color(0xFF5C6BC0), Color(0xFF7986CB)],
          likes: 41,
          comments: 8,
          timeAgo: l10n.storiTime5h,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost3Author,
          caption: l10n.storiPost3Caption,
          icon: Icons.home_outlined,
          gradientColors: const [Color(0xFF8D6E63), Color(0xFFA1887F)],
          likes: 18,
          comments: 3,
          timeAgo: l10n.storiTime1d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost4Author,
          caption: l10n.storiPost4Caption,
          icon: Icons.local_taxi,
          gradientColors: const [Color(0xFF00838F), Color(0xFF26A69A)],
          likes: 32,
          comments: 6,
          timeAgo: l10n.storiTime2d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost5Author,
          caption: l10n.storiPost5Caption,
          icon: Icons.pets,
          gradientColors: const [Color(0xFFFF8A65), Color(0xFFFFAB91)],
          likes: 15,
          comments: 4,
          timeAgo: l10n.storiTime3d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost6Author,
          caption: l10n.storiPost6Caption,
          icon: Icons.school_outlined,
          gradientColors: const [Color(0xFF7E57C2), Color(0xFF9575CD)],
          likes: 28,
          comments: 7,
          timeAgo: l10n.storiTime3d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost7Author,
          caption: l10n.storiPost7Caption,
          icon: Icons.auto_awesome,
          gradientColors: const [Color(0xFFEC407A), Color(0xFFF48FB1)],
          likes: 36,
          comments: 9,
          timeAgo: l10n.storiTime4d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost8Author,
          caption: l10n.storiPost8Caption,
          icon: Icons.home_outlined,
          gradientColors: const [Color(0xFF5D4037), Color(0xFF8D6E63)],
          likes: 22,
          comments: 5,
          timeAgo: l10n.storiTime4d,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost9Author,
          caption: l10n.storiPost9Caption,
          icon: Icons.celebration_outlined,
          gradientColors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
          likes: 19,
          comments: 3,
          timeAgo: l10n.storiTime1w,
        ),
        DummyStoriPost(
          authorName: l10n.storiPost10Author,
          caption: l10n.storiPost10Caption,
          icon: Icons.bathtub_outlined,
          gradientColors: const [Color(0xFF00695C), Color(0xFF26A69A)],
          likes: 44,
          comments: 12,
          timeAgo: l10n.storiTime1w,
        ),
      ];
}
