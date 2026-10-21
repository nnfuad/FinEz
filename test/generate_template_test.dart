import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:finez/services/import_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Generate member import template file', () async {
    final dummyClient = SupabaseClient('https://example.supabase.co', 'dummy_anon');
    final importService = ImportService(dummyClient);
    final bytes = importService.generateMemberTemplateBytes();

    expect(bytes, isNotNull);
    final dir = Directory('assets/templates');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('assets/templates/member_import_template.xlsx');
    await file.writeAsBytes(bytes!);
    expect(file.existsSync(), true);
  });
}
