import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member.dart';
import '../utils/formatters.dart';

enum RowAction {
  create,
  update,
  unchanged,
  reject,
}

class ImportRowPreview {
  final int rowIndex;
  final String memberCode;
  final String fullName;
  final String mobile;
  final String? address;
  final double monthlyInstallment;
  final RowAction action;
  final String? existingMemberId;
  final String? rejectionReason;
  final bool hasDuplicateMobileWarning;

  ImportRowPreview({
    required this.rowIndex,
    required this.memberCode,
    required this.fullName,
    required this.mobile,
    this.address,
    required this.monthlyInstallment,
    required this.action,
    this.existingMemberId,
    this.rejectionReason,
    this.hasDuplicateMobileWarning = false,
  });
}

class ImportPreviewResult {
  final List<ImportRowPreview> rows;
  final int totalRows;
  final int newCount;
  final int updateCount;
  final int unchangedCount;
  final int rejectedCount;

  ImportPreviewResult({
    required this.rows,
    required this.totalRows,
    required this.newCount,
    required this.updateCount,
    required this.unchangedCount,
    required this.rejectedCount,
  });

  bool get hasErrors => rejectedCount > 0;
}

class ImportService {
  final SupabaseClient _supabase;

  ImportService(this._supabase);

  /// Parse and validate an Excel file bytes
  Future<ImportPreviewResult> previewMemberImport(Uint8List fileBytes) async {
    final excel = Excel.decodeBytes(fileBytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Excel workbook contains no readable sheets or rows.');
    }

    // 1. Fetch existing members for matching
    final existingData = await _supabase.from('members').select();
    final Map<String, Member> existingByCode = {};
    final Set<String> existingMobiles = {};
    for (var json in existingData as List) {
      final m = Member.fromJson(json);
      existingByCode[m.memberCode.toUpperCase()] = m;
      existingMobiles.add(m.mobile);
    }

    final List<ImportRowPreview> previews = [];
    final Set<String> inSheetCodes = {};
    final Set<String> inSheetMobiles = {};

    int newCount = 0;
    int updateCount = 0;
    int unchangedCount = 0;
    int rejectedCount = 0;

    // Identify header row (Row 0 usually)
    // Columns: Member ID | Full Name | Address | Mobile | Monthly Installment
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty || row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) {
        continue; // skip blank rows
      }

      final rawCode = row.isNotEmpty && row[0]?.value != null ? row[0]!.value.toString().trim() : '';
      final rawName = row.length > 1 && row[1]?.value != null ? row[1]!.value.toString().trim() : '';
      final rawAddress = row.length > 2 && row[2]?.value != null ? row[2]!.value.toString().trim() : '';
      final rawMobile = row.length > 3 && row[3]?.value != null ? row[3]!.value.toString().trim() : '';
      final rawInstallment = row.length > 4 && row[4]?.value != null ? row[4]!.value.toString().trim() : '0';

      // Validation
      if (rawCode.isEmpty) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: '',
          fullName: rawName,
          mobile: rawMobile,
          address: rawAddress,
          monthlyInstallment: 0,
          action: RowAction.reject,
          rejectionReason: 'Member Code is missing',
        ));
        rejectedCount++;
        continue;
      }

      final normalizedCode = rawCode.toUpperCase();
      if (inSheetCodes.contains(normalizedCode)) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: normalizedCode,
          fullName: rawName,
          mobile: rawMobile,
          address: rawAddress,
          monthlyInstallment: 0,
          action: RowAction.reject,
          rejectionReason: 'Duplicate Member Code within spreadsheet',
        ));
        rejectedCount++;
        continue;
      }
      inSheetCodes.add(normalizedCode);

      if (rawName.isEmpty) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: normalizedCode,
          fullName: '',
          mobile: rawMobile,
          address: rawAddress,
          monthlyInstallment: 0,
          action: RowAction.reject,
          rejectionReason: 'Full Name is required',
        ));
        rejectedCount++;
        continue;
      }

      final normalizedMobile = Formatters.normalizeMobile(rawMobile);
      if (normalizedMobile.isEmpty || normalizedMobile.length < 11) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: normalizedCode,
          fullName: rawName,
          mobile: rawMobile,
          address: rawAddress,
          monthlyInstallment: 0,
          action: RowAction.reject,
          rejectionReason: 'Invalid mobile number format (must be valid 11-digit phone)',
        ));
        rejectedCount++;
        continue;
      }

      final hasDupMobile = inSheetMobiles.contains(normalizedMobile) || existingMobiles.contains(normalizedMobile);
      inSheetMobiles.add(normalizedMobile);

      final installmentAmount = double.tryParse(rawInstallment);
      if (installmentAmount == null || installmentAmount < 0) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: normalizedCode,
          fullName: rawName,
          mobile: normalizedMobile,
          address: rawAddress,
          monthlyInstallment: 0,
          action: RowAction.reject,
          rejectionReason: 'Monthly Installment must be a valid non-negative number',
        ));
        rejectedCount++;
        continue;
      }

      // Match against existing members
      final existing = existingByCode[normalizedCode];
      if (existing == null) {
        previews.add(ImportRowPreview(
          rowIndex: i + 1,
          memberCode: normalizedCode,
          fullName: rawName,
          mobile: normalizedMobile,
          address: rawAddress,
          monthlyInstallment: installmentAmount,
          action: RowAction.create,
          hasDuplicateMobileWarning: hasDupMobile,
        ));
        newCount++;
      } else {
        // Check if anything changed
        final isDifferent = existing.fullName != rawName ||
            existing.mobile != normalizedMobile ||
            (existing.address ?? '') != rawAddress ||
            existing.monthlyInstallment != installmentAmount;

        if (isDifferent) {
          previews.add(ImportRowPreview(
            rowIndex: i + 1,
            memberCode: normalizedCode,
            fullName: rawName,
            mobile: normalizedMobile,
            address: rawAddress,
            monthlyInstallment: installmentAmount,
            action: RowAction.update,
            existingMemberId: existing.id,
            hasDuplicateMobileWarning: hasDupMobile,
          ));
          updateCount++;
        } else {
          previews.add(ImportRowPreview(
            rowIndex: i + 1,
            memberCode: normalizedCode,
            fullName: rawName,
            mobile: normalizedMobile,
            address: rawAddress,
            monthlyInstallment: installmentAmount,
            action: RowAction.unchanged,
            existingMemberId: existing.id,
          ));
          unchangedCount++;
        }
      }
    }

    return ImportPreviewResult(
      rows: previews,
      totalRows: previews.length,
      newCount: newCount,
      updateCount: updateCount,
      unchangedCount: unchangedCount,
      rejectedCount: rejectedCount,
    );
  }

  /// Apply validated import rows
  Future<Map<String, dynamic>> applyImport(List<ImportRowPreview> rows) async {
    int inserted = 0;
    int updated = 0;

    for (var row in rows) {
      if (row.action == RowAction.create) {
        await _supabase.from('members').insert({
          'member_code': row.memberCode,
          'full_name': row.fullName,
          'mobile': row.mobile,
          'address': row.address,
          'monthly_installment': row.monthlyInstallment,
          'is_active': true,
        });
        inserted++;
      } else if (row.action == RowAction.update && row.existingMemberId != null) {
        await _supabase.from('members').update({
          'full_name': row.fullName,
          'mobile': row.mobile,
          'address': row.address,
          'monthly_installment': row.monthlyInstallment,
        }).eq('id', row.existingMemberId!);
        updated++;
      }
    }

    // Save batch summary to import_batches
    await _supabase.from('import_batches').insert({
      'import_type': 'members_excel',
      'summary': {
        'total': rows.length,
        'inserted': inserted,
        'updated': updated,
      },
    });

    return {
      'inserted': inserted,
      'updated': updated,
      'total': rows.length,
    };
  }

  /// Generate a clean XLSX template bytes
  List<int>? generateMemberTemplateBytes() {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Members_Template'];
    excel.setDefaultSheet('Members_Template');

    sheet.appendRow([
      TextCellValue('Member ID'),
      TextCellValue('Full Name'),
      TextCellValue('Address'),
      TextCellValue('Mobile'),
      TextCellValue('Monthly Installment'),
    ]);

    // Sample row
    sheet.appendRow([
      TextCellValue('FM-0101'),
      TextCellValue('Karim Ahmed'),
      TextCellValue('Dhaka, Bangladesh'),
      TextCellValue('01700000000'),
      IntCellValue(2000),
    ]);

    return excel.encode();
  }
}
