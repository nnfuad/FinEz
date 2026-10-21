import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

class PublicDirectoryScreen extends StatefulWidget {
  final AuthService authService;
  final MemberService memberService;
  final LocaleProvider localeProvider;

  const PublicDirectoryScreen({
    super.key,
    required this.authService,
    required this.memberService,
    required this.localeProvider,
  });

  @override
  State<PublicDirectoryScreen> createState() => _PublicDirectoryScreenState();
}

class _PublicDirectoryScreenState extends State<PublicDirectoryScreen> {
  List<PublicMember> _members = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.memberService.getPublicMemberList();
      if (mounted) {
        setState(() {
          _members = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PublicMember> get _filteredList {
    if (_searchQuery.trim().isEmpty) return _members;
    final q = _searchQuery.toLowerCase();
    return _members.where((m) => m.fullName.toLowerCase().contains(q) || m.memberCode.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.publicMemberList),
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/member/directory',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.searchMembers,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredList.isEmpty
                    ? const Center(child: Text('No members found', style: TextStyle(color: AppColors.textMuted)))
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadDirectory,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final m = _filteredList[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  m.fullName,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${l10n.memberCode}: ${m.memberCode}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
