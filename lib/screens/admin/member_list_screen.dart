import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

class MemberListScreen extends StatefulWidget {
  final AuthService authService;
  final MemberService memberService;
  final LocaleProvider localeProvider;

  const MemberListScreen({
    super.key,
    required this.authService,
    required this.memberService,
    required this.localeProvider,
  });

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<Member> _members = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool? _filterActive = true; // Default to active members

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.memberService.getMembers(
        activeOnly: _filterActive,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _members = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.members),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addMember,
            onPressed: () {
              Navigator.of(context).pushNamed('/admin/member-form').then((_) => _loadMembers());
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/members',
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.navigationSurface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.searchMembers,
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadMembers();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterChip(
                      selected: _filterActive == true,
                      label: Text(l10n.filterActive),
                      labelStyle: TextStyle(
                        color: _filterActive == true ? AppColors.onPrimary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.elevated,
                      side: const BorderSide(color: AppColors.border),
                      onSelected: (_) {
                        setState(() => _filterActive = true);
                        _loadMembers();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterActive == false,
                      label: Text(l10n.filterInactive),
                      labelStyle: TextStyle(
                        color: _filterActive == false ? AppColors.onPrimary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedColor: AppColors.statusDue,
                      backgroundColor: AppColors.elevated,
                      side: const BorderSide(color: AppColors.border),
                      onSelected: (_) {
                        setState(() => _filterActive = false);
                        _loadMembers();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterActive == null,
                      label: Text(l10n.filterAll),
                      labelStyle: TextStyle(
                        color: _filterActive == null ? AppColors.onPrimary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedColor: AppColors.transfer,
                      backgroundColor: AppColors.elevated,
                      side: const BorderSide(color: AppColors.border),
                      onSelected: (_) {
                        setState(() => _filterActive = null);
                        _loadMembers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _members.isEmpty
                    ? Center(
                        child: Text(
                          'No members found',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadMembers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final m = _members[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: m.isActive
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.statusWaived.withValues(alpha: 0.15),
                                  child: Text(
                                    m.memberCode.replaceAll(RegExp(r'[^0-9]'), '').padLeft(2, '0').substring(0, 2),
                                    style: TextStyle(
                                      color: m.isActive ? AppColors.primary : AppColors.statusWaived,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.fullName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(m.monthlyInstallment, locale: locale, showDecimals: false),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${m.memberCode} • ${m.mobile}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      if (m.address != null && m.address!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          m.address!,
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                  color: AppColors.elevated,
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      Navigator.of(context).pushNamed(
                                        '/admin/member-form',
                                        arguments: m,
                                      ).then((_) => _loadMembers());
                                    } else if (val == 'toggle_active') {
                                      await widget.memberService.toggleMemberActive(m.id, !m.isActive);
                                      _loadMembers();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                                          const SizedBox(width: 8),
                                          Text(l10n.edit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_active',
                                      child: Row(
                                        children: [
                                          Icon(
                                            m.isActive ? Icons.person_off : Icons.person,
                                            size: 18,
                                            color: m.isActive ? AppColors.statusDue : AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(m.isActive ? 'Deactivate' : 'Activate'),
                                        ],
                                      ),
                                    ),
                                  ],
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
