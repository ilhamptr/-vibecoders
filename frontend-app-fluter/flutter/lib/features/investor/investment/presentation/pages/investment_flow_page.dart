import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../domain/domain.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investment_math.dart';
import '../../../common/investor_design.dart';
import '../../../common/project_widgets.dart';
import '../../../common/status_view.dart';
import '../../../project_detail/data/project_detail_repository.dart';
import '../../data/investment_repository.dart';
import '../state/investment_flow_controller.dart';

class InvestmentFlowPage extends StatefulWidget {
  const InvestmentFlowPage({
    super.key,
    required this.projectRepository,
    required this.investmentRepository,
    required this.investor,
    required this.projectId,
    this.minimumAmount = InvestmentAmountValidator.minimum,
    this.requireOpenFunding = true,
  });

  final ProjectDetailRepository projectRepository;
  final InvestmentRepository investmentRepository;
  final User investor;
  final String projectId;
  final int minimumAmount;
  final bool requireOpenFunding;

  @override
  State<InvestmentFlowPage> createState() => _InvestmentFlowPageState();
}

class _InvestmentFlowPageState extends State<InvestmentFlowPage> {
  late final InvestmentFlowController controller = InvestmentFlowController(
    projectRepository: widget.projectRepository,
    investmentRepository: widget.investmentRepository,
    investor: widget.investor,
    projectId: widget.projectId,
    minimumAmount: widget.minimumAmount,
    requireOpenFunding: widget.requireOpenFunding,
  )..load();
  final amountField = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    amountField.dispose();
    super.dispose();
  }

  void _primaryAction() {
    if (controller.step == InvestmentStep.review) {
      controller.confirm();
    } else {
      controller.continueToReview();
    }
  }

  @override
  Widget build(BuildContext context) => InvestorPresentation(
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.step == InvestmentStep.success
          ? _SuccessView(investment: controller.createdInvestment!)
          : _buildFlow(context),
    ),
  );

  Widget _buildFlow(BuildContext context) {
    final review = controller.step == InvestmentStep.review;
    final ready =
        controller.projectStatus == LoadStatus.success &&
        !controller.isSubmitting;
    return Scaffold(
      body: SafeArea(
        child: StatusView(
          status: controller.projectStatus,
          onRetry: controller.load,
          emptyMessage: 'Proyek tidak ditemukan.',
          builder: (context) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ProjectHero(project: controller.project!),
              const SizedBox(height: 24),
              if (review)
                _ReviewCard(
                  project: controller.project!,
                  amount: controller.amount!,
                )
              else
                _EntryForm(controller: controller, amountField: amountField),
              if (controller.submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Mode simulasi • Tidak ada transaksi uang nyata',
                style: TextStyle(fontSize: 11, color: InvestorDesign.muted),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppStickyBottomBar(
        showTopBorder: false,
        backgroundColor: InvestorDesign.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignButton(
              label: review ? 'Konfirmasi' : 'Investasi',
              loading: controller.isSubmitting,
              onPressed: ready ? _primaryAction : null,
            ),
            TextButton(
              onPressed: controller.isSubmitting
                  ? null
                  : () => review
                        ? controller.backToEntry()
                        : Navigator.pop(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 6),
                  Text('Kembali'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryForm extends StatelessWidget {
  const _EntryForm({required this.controller, required this.amountField});

  final InvestmentFlowController controller;
  final TextEditingController amountField;

  @override
  Widget build(BuildContext context) {
    final project = controller.project!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignCard(
          child: Column(
            children: [
              DeadlineBanner(project: project),
              const SizedBox(height: 12),
              ProjectStats(project: project),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Jumlah Investasi'),
        const SizedBox(height: 12),
        TextField(
          controller: amountField,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: controller.setAmountText,
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah investasi anda',
            errorText: controller.amountError,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in const {
              100000: '100RB',
              500000: '500RB',
              1000000: '1JT',
              5000000: '5JT',
            }.entries)
              SizedBox(
                width: 84 * MediaQuery.textScalerOf(context).scale(13) / 13,
                child: AppButton(
                  label: entry.value,
                  height: 36,
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    amountField.text = '${entry.key}';
                    controller.setAmountText('${entry.key}');
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          controller.requireOpenFunding
              ? 'Minimum Investasi ${rupiah(controller.minimumAmount, prefix: false)} • '
                    'Sisa pendanaan ${rupiah(InvestmentAmountValidator.remaining(project), prefix: false)}'
              : 'Minimum Investasi ${rupiah(controller.minimumAmount, prefix: false)}',
          style: const TextStyle(fontSize: 11, color: InvestorDesign.muted),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.project, required this.amount});

  final AgricultureProject project;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: InvestorDesign.muted, fontSize: 12);
    const value = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Detail Investasi'),
          const SizedBox(height: 18),
          const Text('Jumlah Investasi', style: label),
          const SizedBox(height: 6),
          Text(rupiah(amount.amount, prefix: false), style: value),
          const SizedBox(height: 18),
          const Text('Estimasi Hasil', style: label),
          const SizedBox(height: 6),
          Text(
            rupiah(estimatedReturnFor(project, amount).amount),
            style: value,
          ),
          const SizedBox(height: 18),
          const Text('Estimasi Panen', style: label),
          const SizedBox(height: 6),
          Text(harvestLabel(project.harvestCycleMonths), style: value),
          const SizedBox(height: 18),
          Text(
            'Perkiraan ROI ${project.roiMinPercent.round()}-${project.roiMaxPercent.round()}%. Hasil tidak dijamin.',
            style: const TextStyle(fontSize: 11, color: InvestorDesign.muted),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.investment});

  final Investment investment;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                '${InvestorDesign.asset}success.png',
                width: double.infinity,
                height: constraints.maxHeight * .7,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              const SizedBox(height: 20),
              const Text(
                'Investasi Lahan Berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 44),
                child: Text(
                  'Pantau terus kemajuan dari investasi anda melalui aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: InvestorDesign.muted),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${rupiah(investment.principal.amount)} • Simulasi',
                style: const TextStyle(
                  color: InvestorDesign.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: AppStickyBottomBar(
      showTopBorder: false,
      backgroundColor: InvestorDesign.background,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: DesignButton(
        label: 'Selesai',
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          InvestorRoutes.portfolio,
          (route) => false,
        ),
      ),
    ),
  );
}
