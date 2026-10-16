import 'package:flutter/material.dart';

import '../../../../app/router/farmer_routes.dart';
import '../../../../app/router/investor_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/domain.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../farmer/common/farmer_media_service.dart';
import '../../auth_session_manager.dart';
import '../../data/fake_registration_repository.dart';
import '../../domain/registration.dart';
import '../../domain/registration_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.role,
    this.repository = const FakeRegistrationRepository(),
    this.mediaService,
  });

  final UserRole role;
  final RegistrationRepository repository;
  final FarmerMediaService? mediaService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel =>
      widget.role == UserRole.farmer ? 'Petani' : 'Investor';

  void _register() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_acceptedTerms) {
      setState(() {});
      return;
    }

    final destination = widget.role == UserRole.farmer
        ? FarmerRoutes.home
        : InvestorRoutes.home;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.farmer) {
      return _FarmerRegistrationPage(
        repository: widget.repository,
        mediaService: widget.mediaService,
      );
    }
    if (widget.role == UserRole.investor) {
      return _InvestorRegistrationPage(
        repository: widget.repository,
        mediaService: widget.mediaService,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            children: [
              const Text(
                'Buat Akun',
                style: TextStyle(
                  color: Color(0xFF123047),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftar sebagai $_roleLabel untuk mulai menggunakan aplikasi.',
                style: const TextStyle(
                  color: Color(0xFF647681),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _RegisterField(
                label: 'Nama lengkap',
                hint: 'Masukkan nama lengkap',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama lengkap wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              _RegisterField(
                label: 'Email',
                hint: 'Masukkan email',
                controller: _emailController,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email wajib diisi';
                  }
                  if (!value.contains('@')) return 'Masukkan email yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _RegisterField(
                label: 'Kata sandi',
                hint: 'Minimal 8 karakter',
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Tampilkan kata sandi'
                      : 'Sembunyikan kata sandi',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Kata sandi minimal 8 karakter'
                    : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                title: const Text(
                  'Saya menyetujui syarat dan ketentuan.',
                  style: TextStyle(color: Color(0xFF435560), fontSize: 14),
                ),
                activeColor: const Color(0xFF006FAE),
              ),
              if (!_acceptedTerms)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'Persetujuan diperlukan untuk melanjutkan',
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                  ),
                ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Daftar',
                height: 54,
                borderRadius: 14,
                backgroundColor: const Color(0xFF006FAE),
                onPressed: _register,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(
                      color: Color(0xFF006FAE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorRegistrationPage extends StatefulWidget {
  const _InvestorRegistrationPage({
    required this.repository,
    this.mediaService,
  });

  final RegistrationRepository repository;
  final FarmerMediaService? mediaService;

  @override
  State<_InvestorRegistrationPage> createState() =>
      _InvestorRegistrationPageState();
}

class _InvestorRegistrationPageState extends State<_InvestorRegistrationPage> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _nik = TextEditingController();
  late final FarmerMediaService _media =
      widget.mediaService ?? FarmerMediaService();
  int _step = 0;
  String? _sex;
  String? _job;
  String? _income;
  FarmerAttachment? _ktp;
  FarmerAttachment? _selfie;
  RegisteredAccount? _account;
  bool _identityCreated = false;
  bool _mediaBusy = false;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    _name.dispose();
    _birthDate.dispose();
    _nik.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0 && !_validateAccount()) return;
    if (_step == 1 && !_validateIdentity()) return;
    if (_step == 2 && !_validateInvestorProfile()) return;

    setState(() => _submitting = true);
    try {
      if (_step == 0) {
        _account ??= await widget.repository.registerAccount(
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        if (!_identityCreated) {
          await widget.repository.createIdentity(
            fullName: _name.text.trim(),
            dateOfBirth: _parseBirthDate(_birthDate.text),
            sex: _sex!,
            nik: _nik.text.trim(),
            identityCard: _document(_ktp!),
            identificationSelfie: _document(_selfie!),
          );
          _identityCreated = true;
        }
        if (mounted) setState(() => _step = 2);
      } else {
        await widget.repository.createInvestorProfile(
          occupation: _job!,
          income: _income!,
        );
        _completeRegistration(UserRole.investor, InvestorRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: ${_errorMessage(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _validateAccount() {
    if (!_email.text.trim().contains('@') ||
        _phone.text.trim().isEmpty ||
        _password.text.length < 8 ||
        _password.text != _confirmation.text) {
      _showValidationError(
        'Isi email dan nomor telepon yang valid, serta password minimal 8 karakter dan sama.',
      );
      return false;
    }
    return true;
  }

  bool _validateIdentity() {
    if (_name.text.trim().isEmpty ||
        _birthDate.text.isEmpty ||
        _sex == null ||
        _nik.text.trim().isEmpty ||
        _ktp == null ||
        _selfie == null) {
      _showValidationError(
        'Lengkapi nama, tanggal lahir, jenis kelamin, NIK, foto KTP, dan selfie.',
      );
      return false;
    }
    return true;
  }

  bool _validateInvestorProfile() {
    if (_job == null || _income == null) {
      _showValidationError('Pilih pekerjaan dan penghasilan per bulan.');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _completeRegistration(UserRole role, String route) {
    final account = _account!;
    AuthSessionManager.instance.setSession(
      AuthSession(
        user: User(
          id: account.id,
          name: _name.text.trim(),
          role: role,
          isVerified: true,
        ),
        authenticatedAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pushReplacementNamed(route);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _selectBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF319AC9),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF20252B),
          ),
        ),
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;
    _birthDate.text =
        '${selected.day.toString().padLeft(2, '0')}/'
        '${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    setState(() {});
  }

  Future<void> _pickPhoto({required bool selfie}) async {
    if (_mediaBusy) return;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selfie ? 'Foto Selfie dengan KTP' : 'Foto KTP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _PhotoOption(
                icon: Icons.camera_alt_outlined,
                label: 'Gunakan Kamera',
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              _PhotoOption(
                icon: Icons.photo_library_outlined,
                label: 'Pilih dari Galeri',
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (camera == null || !mounted) return;

    setState(() => _mediaBusy = true);
    try {
      final attachment = await _media.photo(camera: camera);
      if (!mounted || attachment == null) return;
      setState(() {
        if (selfie) {
          _selfie = attachment;
        } else {
          _ktp = attachment;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto tidak dapat dipilih: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFBFFFF),
    body: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _ProgressIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
              child: _content(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              children: [
                AppButton(
                  label: _step == 2 ? 'Selesai' : 'Selanjutnya',
                  height: 44,
                  borderRadius: 11,
                  backgroundColor: const Color(0xFF319AC9),
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _next,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Kembali'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1698D0),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _content() {
    switch (_step) {
      case 0:
        return _accountStep();
      case 1:
        return _identityStep();
      default:
        return _profileStep();
    }
  }

  Widget _accountStep() => _StepColumn(
    title: 'Halo Sahabat Tani!',
    description: 'Bantu kami untuk menciptakan lingkungan\ninvestasi yang aman',
    children: [
      _field('Email', 'Masukkan nama lengkap', _email),
      _field(
        'Nomor Telefon',
        'Masukkan nomor telfon',
        _phone,
        keyboardType: TextInputType.phone,
      ),
      _field('Password', 'Buat password anda', _password, obscureText: true),
      _field(
        'Konfirmasi Password',
        'Tuliskan ulang password anda',
        _confirmation,
        obscureText: true,
      ),
    ],
  );

  Widget _identityStep() => _StepColumn(
    title: 'Lengkapi Data Diri',
    description: 'Bantu kami dan pengguna lain untuk\nmengenal anda lebih baik',
    children: [
      _field('Nama Lengkap', 'Masukkan nama lengkap', _name),
      _field(
        'Tanggal Lahir',
        '31/12/2000',
        _birthDate,
        icon: Icons.calendar_month_outlined,
        readOnly: true,
        onTap: _selectBirthDate,
      ),
      _field('NIK', 'Masukkan NIK', _nik, keyboardType: TextInputType.number),
      const _SectionLabel('Jenis Kelamin'),
      ...['Laki-Laki', 'Perempuan'].map(
        (value) => _ChoiceTile(
          label: value,
          selected: _sex == value,
          onTap: () => setState(() => _sex = value),
        ),
      ),
      const SizedBox(height: 12),
      _uploadField('Foto KTP', _ktp, () => _pickPhoto(selfie: false)),
      _uploadField(
        'Foto Selfie dengan KTP',
        _selfie,
        () => _pickPhoto(selfie: true),
      ),
    ],
  );

  Widget _profileStep() => _StepColumn(
    title: 'Profil Investasi Anda',
    description:
        'Bantu kami untuk mencarikan investor\nyang sesuai dengan anda',
    children: [
      const _SectionLabel('Pekerjaan'),
      ...[
        'Karyawan Swasta',
        'PNS / BUMN',
        'Wiraswasta',
        'Professional',
        'Lainnya',
      ].map(
        (value) => _ChoiceTile(
          label: value,
          selected: _job == value,
          onTap: () => setState(() => _job = value),
        ),
      ),
      const SizedBox(height: 14),
      const _SectionLabel('Penghasilan per Bulan'),
      ...[
        '< 5,000,000',
        '5,000,000 - 10,000,000',
        '10,000,000 - 25,000,000',
        '> 25,000,000',
      ].map(
        (value) => _ChoiceTile(
          label: value,
          selected: _income == value,
          onTap: () => setState(() => _income = value),
        ),
      ),
    ],
  );

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon, size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _uploadField(
    String label,
    FarmerAttachment? attachment,
    VoidCallback onPressed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (attachment != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              attachment.bytes,
              height: 88,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _mediaBusy ? null : onPressed,
          icon: Icon(
            attachment == null
                ? Icons.camera_alt_outlined
                : Icons.edit_outlined,
          ),
          label: Text(attachment == null ? 'Upload Foto' : 'Edit'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: const Color(0xFF20252B),
            side: const BorderSide(color: Color(0xFFE5E5E5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FarmerRegistrationPage extends StatefulWidget {
  const _FarmerRegistrationPage({required this.repository, this.mediaService});

  final RegistrationRepository repository;
  final FarmerMediaService? mediaService;

  @override
  State<_FarmerRegistrationPage> createState() =>
      _FarmerRegistrationPageState();
}

class _FarmerRegistrationPageState extends State<_FarmerRegistrationPage> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _nik = TextEditingController();
  late final FarmerMediaService _media =
      widget.mediaService ?? FarmerMediaService();
  int _step = 0;
  String? _sex;
  String? _experience;
  String? _commodity;
  FarmerAttachment? _ktp;
  FarmerAttachment? _selfie;
  RegisteredAccount? _account;
  bool _identityCreated = false;
  bool _mediaBusy = false;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _name.dispose();
    _birthDate.dispose();
    _nik.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 0 && !_validateAccount()) return;
    if (_step == 1 && !_validateIdentity()) return;
    if (_step == 2 && !_validateFarmerProfile()) return;

    setState(() => _submitting = true);
    try {
      if (_step == 0) {
        _account ??= await widget.repository.registerAccount(
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        if (!_identityCreated) {
          await widget.repository.createIdentity(
            fullName: _name.text.trim(),
            dateOfBirth: _parseBirthDate(_birthDate.text),
            sex: _sex!,
            nik: _nik.text.trim(),
            identityCard: _document(_ktp!),
            identificationSelfie: _document(_selfie!),
          );
          _identityCreated = true;
        }
        if (mounted) setState(() => _step = 2);
      } else {
        await widget.repository.createFarmerProfile(
          experience: _experience!,
          commodity: _commodity!,
        );
        final account = _account!;
        AuthSessionManager.instance.setSession(
          AuthSession(
            user: User(
              id: account.id,
              name: _name.text.trim(),
              role: UserRole.farmer,
              isVerified: true,
            ),
            authenticatedAt: DateTime.now(),
          ),
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(FarmerRoutes.home);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: ${_errorMessage(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _validateAccount() {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') ||
        _phone.text.trim().isEmpty ||
        password.length < 8 ||
        password != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Isi email dan nomor telepon yang valid, serta pastikan password minimal 8 karakter dan sama.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateIdentity() {
    if (_name.text.trim().isEmpty ||
        _birthDate.text.isEmpty ||
        _sex == null ||
        _nik.text.trim().isEmpty ||
        _ktp == null ||
        _selfie == null) {
      _showValidationError(
        'Lengkapi nama, tanggal lahir, jenis kelamin, NIK, foto KTP, dan selfie.',
      );
      return false;
    }
    return true;
  }

  bool _validateFarmerProfile() {
    if (_experience == null || _commodity == null) {
      _showValidationError('Pilih pengalaman bertani dan satu komoditas.');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _selectBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF319AC9),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF20252B),
          ),
        ),
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;
    _birthDate.text =
        '${selected.day.toString().padLeft(2, '0')}/'
        '${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    setState(() {});
  }

  Future<void> _pickPhoto({required bool selfie}) async {
    if (_mediaBusy) return;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selfie ? 'Foto Selfie dengan KTP' : 'Foto KTP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _PhotoOption(
                icon: Icons.camera_alt_outlined,
                label: 'Gunakan Kamera',
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 40),
              _PhotoOption(
                icon: Icons.photo_library_outlined,
                label: 'Pilih dari Galeri',
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (camera == null || !mounted) return;

    setState(() => _mediaBusy = true);
    try {
      final attachment = await _media.photo(camera: camera);
      if (!mounted || attachment == null) return;
      setState(() {
        if (selfie) {
          _selfie = attachment;
        } else {
          _ktp = attachment;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto tidak dapat dipilih: $error')),
      );
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _ProgressIndicator(step: _step),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
                child: _content(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  AppButton(
                    label: _step == 2 ? 'Selesai' : 'Selanjutnya',
                    height: 44,
                    borderRadius: 11,
                    backgroundColor: const Color(0xFF319AC9),
                    onPressed: _submitting ? null : _next,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Kembali'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1698D0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case 0:
        return _accountStep();
      case 1:
        return _identityStep();
      case 2:
        return _experienceStep();
      default:
        return _experienceStep();
    }
  }

  Widget _accountStep() => _StepColumn(
    title: 'Halo Sahabat Tani!',
    description: 'Bantu kami untuk menciptakan lingkungan\ninvestasi yang aman',
    children: [
      _field('Email', 'Masukkan nama lengkap', _email),
      _field(
        'Nomor Telefon',
        'Masukkan nomor telfon',
        _phone,
        keyboardType: TextInputType.phone,
      ),
      _field('Password', 'Buat password anda', _password, obscureText: true),
      _field(
        'Konfirmasi Password',
        'Tuliskan ulang password anda',
        _confirmPassword,
        obscureText: true,
      ),
    ],
  );

  Widget _identityStep() => _StepColumn(
    title: 'Lengkapi Data Diri',
    description: 'Bantu kami dan pengguna lain untuk\nmengenal anda lebih baik',
    children: [
      _field('Nama Lengkap', 'Masukkan nama lengkap', _name),
      _field(
        'Tanggal Lahir',
        '31/12/2000',
        _birthDate,
        icon: Icons.calendar_month_outlined,
        readOnly: true,
        onTap: _selectBirthDate,
      ),
      _field('NIK', 'Masukkan NIK', _nik, keyboardType: TextInputType.number),
      const _SectionLabel('Jenis Kelamin'),
      ...['Laki-Laki', 'Perempuan'].map(
        (value) => _ChoiceTile(
          label: value,
          selected: _sex == value,
          onTap: () => setState(() => _sex = value),
        ),
      ),
      const SizedBox(height: 12),
      _uploadField('Foto KTP', _ktp, () => _pickPhoto(selfie: false)),
      _uploadField(
        'Foto Selfie dengan KTP',
        _selfie,
        () => _pickPhoto(selfie: true),
      ),
    ],
  );

  Widget _experienceStep() => _StepColumn(
    title: 'Pengalaman Bertani Anda',
    description:
        'Bantu kami untuk mencarikan investor\nyang sesuai dengan anda',
    children: [
      const _SectionLabel('Sudah Berapa Lama Bertani'),
      ...[
        'Baru mulai ( < 1 tahun )',
        '1 - 3 tahun',
        '3 - 10 tahun',
        'Lebih dari 10 tahun',
      ].map(
        (value) => _ChoiceTile(
          label: value,
          selected: _experience == value,
          onTap: () => setState(() => _experience = value),
        ),
      ),
      const SizedBox(height: 14),
      const _SectionLabel('Komoditas yang Sering Ditanam'),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.25,
        children:
            [
                  ['🌾', 'Padi'],
                  ['🥬', 'Sayuran'],
                  ['🌶️', 'Rempah'],
                  ['🍊', 'Buah'],
                  ['🌽', 'Palawija'],
                  ['🌴', 'Perkebunan'],
                ]
                .map(
                  (item) => _CommodityTile(
                    emoji: item[0],
                    label: item[1],
                    selected: _commodity == item[1],
                    onTap: () => setState(() => _commodity = item[1]),
                  ),
                )
                .toList(),
      ),
    ],
  );

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? icon,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon, size: 18),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadField(
    String label,
    FarmerAttachment? attachment,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (attachment != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                attachment.bytes,
                height: 88,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _mediaBusy ? null : onPressed,
            icon: Icon(
              attachment == null
                  ? Icons.camera_alt_outlined
                  : Icons.edit_outlined,
            ),
            label: Text(attachment == null ? 'Upload Foto' : 'Edit'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: const Color(0xFF20252B),
              side: const BorderSide(color: Color(0xFFE5E5E5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _errorMessage(Object error) =>
    error is ApiException ? error.message : error.toString();

RegistrationDocument _document(FarmerAttachment attachment) =>
    RegistrationDocument(bytes: attachment.bytes, filename: attachment.name);

DateTime _parseBirthDate(String value) {
  final parts = value.split('/');
  if (parts.length != 3) {
    throw const FormatException('Format tanggal lahir harus DD/MM/YYYY.');
  }
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    throw const FormatException('Tanggal lahir tidak valid.');
  }
  final date = DateTime(year, month, day);
  if (date.day != day || date.month != month || date.year != year) {
    throw const FormatException('Tanggal lahir tidak valid.');
  }
  return date;
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF20252B),
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 16,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          width: 32,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index <= step + 1
                ? const Color(0xFF319AC9)
                : const Color(0xFFD5EEF6),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: const Color(0xFF20252B),
      side: const BorderSide(color: Color(0xFFE5E5E5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF319AC9) : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected
                  ? const Color(0xFF319AC9)
                  : const Color(0xFF999999),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          ],
        ),
      ),
    ),
  );
}

class _CommodityTile extends StatelessWidget {
  const _CommodityTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF319AC9) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: selected
                    ? const Color(0xFF319AC9)
                    : const Color(0xFF999999),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
  );
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF006FAE)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD7E2E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD7E2E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF006FAE), width: 2),
        ),
      ),
    );
  }
}
