import 'package:flutter/material.dart';

import '../../../../../domain/user/user_role.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../state/role_selection_controller.dart';
import '../widgets/role_selection_card.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key, required this.onContinue});
  final void Function(UserRole) onContinue;
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  final controller = RoleSelectionController();
  late final AnimationController _animationController;
  late final Animation<double> _headerAnimation;
  late final Animation<Offset> _farmerSlideAnimation;
  late final Animation<Offset> _investorSlideAnimation;
  late final Animation<double> _farmerFadeAnimation;
  late final Animation<double> _investorFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, .45, curve: Curves.easeOut),
    );
    _farmerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, .2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(.12, .68, curve: Curves.easeOutCubic),
          ),
        );
    _investorSlideAnimation =
        Tween<Offset>(begin: const Offset(0, .2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(.28, .84, curve: Curves.easeOutCubic),
          ),
        );
    _farmerFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(.12, .68, curve: Curves.easeOut),
    );
    _investorFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(.28, .84, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controller, _animationController]),
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFBFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 26,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RoleProgress(),
                const SizedBox(height: 34),
                FadeTransition(
                  opacity: _headerAnimation,
                  child: const Text(
                    'Saya Ingin Bergabung Sebagai',
                    style: TextStyle(
                      color: Color(0xFF20252B),
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _farmerSlideAnimation,
                  child: FadeTransition(
                    opacity: _farmerFadeAnimation,
                    child: RoleSelectionCard(
                      label: 'Petani / Pemilik Lahan',
                      image: 'assets/onboarding/role_selection/farmer.png',
                      selected: controller.selectedRole == UserRole.farmer,
                      onTap: () => controller.selectRole(UserRole.farmer),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SlideTransition(
                  position: _investorSlideAnimation,
                  child: FadeTransition(
                    opacity: _investorFadeAnimation,
                    child: RoleSelectionCard(
                      label: 'Investor',
                      image: 'assets/onboarding/role_selection/investor.png',
                      selected: controller.selectedRole == UserRole.investor,
                      onTap: () => controller.selectRole(UserRole.investor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: AppButton(
            label: 'Selanjutnya',
            backgroundColor: const Color(0xFF006FAE),
            height: 44,
            borderRadius: 12,
            onPressed: controller.canContinue
                ? () => widget.onContinue(controller.selectedRole!)
                : null,
          ),
        ),
      ),
    ),
  );
}

class _RoleProgress extends StatelessWidget {
  const _RoleProgress();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      4,
      (index) => Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: index == 0
              ? const Color(0xFF319AC9)
              : const Color(0xFFD5EEF6),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
