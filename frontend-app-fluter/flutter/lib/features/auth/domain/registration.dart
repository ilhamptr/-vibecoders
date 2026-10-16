import 'dart:typed_data';

class RegisteredAccount {
  const RegisteredAccount({required this.id, required this.email});

  final String id;
  final String email;
}

class RegistrationDocument {
  const RegistrationDocument({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
