import 'package:flutter/material.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../domain/domain.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investor_design.dart';
import '../../../common/project_timeline.dart';
import '../../../common/project_widgets.dart';
import '../../../common/status_view.dart';
import '../../data/project_detail_repository.dart';
import '../state/project_detail_controller.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.repository,
    required this.projectId,
  });

  final ProjectDetailRepository repository;
  final String projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late final ProjectDetailController controller = ProjectDetailController(
    widget.repository,
    widget.projectId,
  )..load();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InvestorPresentation(
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StatusView(
          status: controller.status,
          onRetry: controller.load,
          emptyMessage: 'Proyek tidak ditemukan.',
          builder: (context) => _Content(project: controller.project!),
        ),
        bottomNavigationBar: AppStickyBottomBar(
          backgroundColor: InvestorDesign.background,
          showTopBorder: false,
          child: DesignButton(
            label: 'Investasi',
            onPressed: controller.canInvest
                ? () => Navigator.pushNamed(
                    context,
                    InvestorRoutes.invest(widget.projectId),
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.project});

  final AgricultureProject project;

  @override
  Widget build(BuildContext context) {
    final funding = project.funding;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        ProjectHero(project: project),
        const SizedBox(height: 24),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Dana Terkumpul'),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: InvestorDesign.ink,
                  ),
                  children: [
                    TextSpan(
                      text: rupiah(funding.collected.amount, prefix: false),
                    ),
                    TextSpan(
                      text:
                          ' / ${rupiah(funding.target.amount, prefix: false)}',
                      style: const TextStyle(color: InvestorDesign.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FundingProgress(project: project),
              const SizedBox(height: 12),
              DeadlineBanner(project: project),
              const SizedBox(height: 12),
              ProjectStats(project: project),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Tentang Proyek'),
              const SizedBox(height: 12),
              Text(project.description ?? 'Belum ada deskripsi proyek.'),
              const SizedBox(height: 16),
              Text(
                'Petani: ${project.farmer.name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                project.location.displayName,
                style: const TextStyle(color: InvestorDesign.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Jadwal Proyek'),
              const SizedBox(height: 16),
              AppTimeline(
                items: timelineItems(buildProjectTimeline(project.status)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
