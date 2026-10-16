import '../../../../domain/domain.dart';

class MockInvestorData {
  const MockInvestorData._();

  static final investor = User(
    id: 'investor-demo',
    name: 'Investor Demo',
    role: UserRole.investor,
    isVerified: true,
  );

  static final farmerBudi = User(
    id: 'farmer-budi',
    name: 'Budi Santoso',
    role: UserRole.farmer,
    isVerified: true,
  );

  static final farmerSari = User(
    id: 'farmer-sari',
    name: 'Sari Wulandari',
    role: UserRole.farmer,
    isVerified: true,
  );

  static List<AgricultureProject> createProjects() {
    final now = DateTime.now();

    return [
      AgricultureProject(
        id: 'project-cabai',
        title: 'Budidaya Cabai Merah',
        farmer: farmerBudi,
        commodity: Commodity.vegetables,
        location: const ProjectLocation(
          province: 'Jawa Barat',
          city: 'Bandung',
        ),
        status: ProjectStatus.openForFunding,
        funding: Funding(
          target: const Money(amount: 10_000_000),
          collected: const Money(amount: 6_500_000),
          investorCount: 12,
          deadline: now.add(const Duration(days: 18)),
        ),
        roiMinPercent: 15,
        roiMaxPercent: 20,
        harvestCycleMonths: 4,
        description: 'Mock project for local frontend development.',
        riskLevel: ProjectRiskLevel.medium,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      AgricultureProject(
        id: 'project-padi',
        title: 'Budidaya Padi',
        farmer: farmerSari,
        commodity: Commodity.rice,
        location: const ProjectLocation(
          province: 'Jawa Tengah',
          city: 'Klaten',
        ),
        status: ProjectStatus.growing,
        funding: Funding(
          target: const Money(amount: 15_000_000),
          collected: const Money(amount: 15_000_000),
          investorCount: 21,
          deadline: now.subtract(const Duration(days: 20)),
        ),
        roiMinPercent: 12,
        roiMaxPercent: 17,
        harvestCycleMonths: 5,
        description: 'Mock active project for portfolio development.',
        riskLevel: ProjectRiskLevel.low,
        createdAt: now.subtract(const Duration(days: 75)),
      ),
      AgricultureProject(
        id: 'project-jahe',
        title: 'Budidaya Jahe',
        farmer: farmerBudi,
        commodity: Commodity.spices,
        location: const ProjectLocation(province: 'Jawa Timur', city: 'Malang'),
        status: ProjectStatus.openForFunding,
        funding: Funding(
          target: const Money(amount: 8_000_000),
          collected: const Money(amount: 2_000_000),
          investorCount: 6,
          deadline: now.add(const Duration(days: 27)),
        ),
        roiMinPercent: 14,
        roiMaxPercent: 19,
        harvestCycleMonths: 6,
        description: 'Mock project for marketplace filtering.',
        riskLevel: ProjectRiskLevel.medium,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  static List<Investment> createInvestments(List<AgricultureProject> projects) {
    final activeProject = projects.firstWhere(
      (project) => project.id == 'project-padi',
    );

    return [
      Investment(
        id: 'investment-demo',
        investor: investor,
        project: activeProject,
        principal: const Money(amount: 1_000_000),
        status: InvestmentStatus.active,
        investedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
