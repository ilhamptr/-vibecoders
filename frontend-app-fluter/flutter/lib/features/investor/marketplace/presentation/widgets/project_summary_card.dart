import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../common/investor_design.dart';
import '../../../common/project_widgets.dart';

class ProjectSummaryCard extends StatelessWidget {
  const ProjectSummaryCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final AgricultureProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DesignCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProjectThumbnailHeader(project: project),
        const SizedBox(height: 12),
        ProjectStats(project: project, showRisk: false),
        const SizedBox(height: 12),
        FundingProgress(project: project),
      ],
    ),
  );
}
