import 'package:flutter_test/flutter_test.dart';
import 'package:financeapp/core/constants/app_constants.dart';

void main() {
  test('reads Supabase configuration from dart defines', () {
    expect(AppConstants.supabaseUrl, isNotEmpty);
    expect(AppConstants.supabaseAnonKey, isNotEmpty);
  });
}
