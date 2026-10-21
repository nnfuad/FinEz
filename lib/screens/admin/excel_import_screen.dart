import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/import_service.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

class ExcelImportScreen extends StatefulWidget {
  final AuthService authService;
  final ImportService importService;
  final LocaleProvider localeProvider;

  const ExcelImportScreen({
    super.key,
    required this.authService,
    required this.importService,
    required this.localeProvider,
  });

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  ImportPreviewResult? _preview;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _error;

  Future<void> _pickAndPreviewFile() async {
    setState(() {
      _error = null;
      _statusMessage = null;
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        // Fallback for paths if bytes null
        final path = result.files.first.path;
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          final preview = await widget.importService.previewMemberImport(bytes);
          setState(() {
            _preview = preview;
            _isProcessing = false;
          });
          return;
        }
        throw Exception('Could not read file data.');
      }

      final preview = await widget.importService.previewMemberImport(fileBytes);
      setState(() {
        _preview = preview;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _handleApply() async {
    if (_preview == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await widget.importService.applyImport(_preview!.rows);
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Import Complete: ${result["inserted"]} created, ${result["updated"]} updated.';
        _preview = null;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.importExcel),
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/import',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Member Spreadsheet Import Guidelines',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Supported columns (Row 1):',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Member ID (e.g. FM-0001)\n'
                    '2. Full Name (e.g. Md. Abdul Karim)\n'
                    '3. Address (optional)\n'
                    '4. Mobile (e.g. 01711000000)\n'
                    '5. Monthly Installment (e.g. 2000)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pick File Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickAndPreviewFile,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.selectExcelFile),
            ),
            const SizedBox(height: 16),

            if (_isProcessing)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary))),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusDue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusDue),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.statusDue)),
              ),
              const SizedBox(height: 16),
            ],

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(_statusMessage!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],

            // Preview Section
            if (_preview != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.importSummary,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Rows: ${_preview!.totalRows}', style: const TextStyle(color: AppColors.textSecondary)),
                        Text('New: ${_preview!.newCount}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        Text('Updates: ${_preview!.updateCount}', style: const TextStyle(color: AppColors.statusPartial, fontWeight: FontWeight.bold)),
                        Text('Rejected: ${_preview!.rejectedCount}', style: const TextStyle(color: AppColors.statusDue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preview Row List
              Text('Rows Preview', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ..._preview!.rows.map((row) {
                Color badgeColor = AppColors.primary;
                String badgeText = 'NEW';
                if (row.action == RowAction.update) {
                  badgeColor = AppColors.statusPartial;
                  badgeText = 'UPDATE';
                } else if (row.action == RowAction.unchanged) {
                  badgeColor = AppColors.textMuted;
                  badgeText = 'NO CHANGE';
                } else if (row.action == RowAction.reject) {
                  badgeColor = AppColors.statusDue;
                  badgeText = 'REJECTED';
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                      child: Text(
                        '${row.rowIndex}',
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            row.fullName.isEmpty ? '(Empty Name)' : row.fullName,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${row.memberCode} • ${row.mobile} • ৳${row.monthlyInstallment.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        if (row.rejectionReason != null)
                          Text('Reason: ${row.rejectionReason}', style: const TextStyle(color: AppColors.statusDue, fontSize: 11)),
                        if (row.hasDuplicateMobileWarning)
                          const Text('Warning: Mobile already registered in another record', style: TextStyle(color: AppColors.statusPartial, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Confirm Button
              ElevatedButton(
                onPressed: _preview!.newCount == 0 && _preview!.updateCount == 0 ? null : _handleApply,
                child: Text(l10n.applyImport),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
