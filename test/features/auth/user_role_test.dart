import 'package:flutter_test/flutter_test.dart';
import 'package:meditrackmobile/features/auth/models/user.dart';

void main() {
  User userWithRole(String role) => User(
        nom: 'Doe',
        prenom: 'Alex',
        email: 'alex@example.com',
        role: role,
      );

  test('doctor role is recognized regardless of casing or accent', () {
    expect(userWithRole('medecin').isMedecin, isTrue);
    expect(userWithRole('MEDECIN').isMedecin, isTrue);
    expect(userWithRole('médecin').isMedecin, isTrue);
    expect(userWithRole('Doctor').isMedecin, isTrue);
    expect(userWithRole('patient').isMedecin, isFalse);
  });
}
