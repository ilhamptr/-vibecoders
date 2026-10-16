import 'package:flutter/material.dart';

import '../../../../domain/user/user_role.dart';
import '../../../onboarding/role_selection/presentation/widgets/role_selection_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.role,
    required this.name,
    required this.avatar,
    required this.onLogout,
  });

  final UserRole role;
  final String name;
  final ImageProvider avatar;
  final VoidCallback onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserRole _role = widget.role;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFBFFFF),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: const BackButton(),
      centerTitle: true,
      title: const Text(
        'Profil',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        children: [
          _ProfileHeader(
            name: widget.name,
            avatar: widget.avatar,
            role: _role,
            onEdit: () => _notice('Edit Profil'),
          ),
          const SizedBox(height: 12),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFDFFBD2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Text(
                  'KYC Terverifikasi',
                  style: TextStyle(color: Color(0xFF29952E), fontSize: 14),
                ),
                SizedBox(width: 6),
                Icon(Icons.check, color: Color(0xFF29952E), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Peran Saya',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          RoleSelectionCard(
            label: 'Investor',
            image: 'assets/onboarding/role_selection/investor.png',
            selected: _role == UserRole.investor,
            onTap: () => setState(() => _role = UserRole.investor),
          ),
          const SizedBox(height: 12),
          RoleSelectionCard(
            label: 'Petani / Pemilik Lahan',
            image: 'assets/onboarding/role_selection/farmer.png',
            selected: _role == UserRole.farmer,
            onTap: () => setState(() => _role = UserRole.farmer),
          ),
          const SizedBox(height: 24),
          const Text(
            'Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _AccountAction(
            label: 'Edit Profil',
            onTap: () => _notice('Edit Profil'),
          ),
          _AccountAction(
            label: 'Ubah Password',
            onTap: () => _notice('Ubah Password'),
          ),
          _AccountAction(
            label: 'Notifikasi',
            onTap: () => _notice('Notifikasi'),
          ),
          const SizedBox(height: 12),
          _AccountAction(
            label: 'Keluar',
            destructive: true,
            onTap: widget.onLogout,
          ),
        ],
      ),
    ),
  );

  void _notice(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label belum tersedia.')));
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.avatar,
    required this.role,
    required this.onEdit,
  });

  final String name;
  final ImageProvider avatar;
  final UserRole role;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8EAEB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: avatar),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                role == UserRole.investor ? 'Investor' : 'Petani',
                style: TextStyle(color: Color(0xFF999999), fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          tooltip: 'Edit Profil',
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF999999)),
        ),
      ],
    ),
  );
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAEB)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: destructive
                        ? const Color(0xFFD51F3A)
                        : const Color(0xFF20252B),
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    ),
  );
}
