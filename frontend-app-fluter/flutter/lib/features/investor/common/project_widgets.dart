import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import 'investor_design.dart';

class FarmerBadge extends StatelessWidget {
  const FarmerBadge({super.key, required this.project});

  final AgricultureProject project;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: project.farmer.name,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    backgroundColor: const Color(0xFFFAFAFA),
    foregroundColor: InvestorDesign.ink,
    icon: project.farmer.isVerified
        ? const Icon(Icons.check, color: Color(0xFF4AAB45), size: 12)
        : null,
  );
}

/// Photo thumbnail + title + farmer, shared by project and investment cards.
class ProjectThumbnailHeader extends StatelessWidget {
  const ProjectThumbnailHeader({super.key, required this.project});

  final AgricultureProject project;

  @override
  Widget build(BuildContext context) {
    final imageUrl = project.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only render the photo when the project has an image; otherwise the
        // card starts straight at the title (no empty thumbnail).
        if (hasImage) ...[
          _ProjectImage(url: imageUrl),
          const SizedBox(height: 12),
        ],
        Text(
          project.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        FarmerBadge(project: project),
      ],
    );
  }
}

/// Network thumbnail that shows a placeholder while loading and collapses to
/// nothing if the image fails to load, so a broken URL never leaves an empty
/// box in the card.
class _ProjectImage extends StatelessWidget {
  const _ProjectImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.network(
      url,
      height: 92,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 92,
          width: double.infinity,
          color: const Color(0xFFEFF4F6),
          alignment: Alignment.center,
          child: const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox.shrink(),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

class DeadlineBanner extends StatelessWidget {
  const DeadlineBanner({super.key, required this.project});

  final AgricultureProject project;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFD9A521);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: InvestorDesign.yellow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 14, color: color),
          const SizedBox(width: 6),
          const Text(
            'Sisa Waktu',
            style: TextStyle(color: color, fontSize: 12),
          ),
          const Spacer(),
          Text(
            daysLeftLabel(project),
            style: const TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
