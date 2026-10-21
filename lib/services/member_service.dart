import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member.dart';
import '../utils/formatters.dart';

class MemberService {
  final SupabaseClient _supabase;

  MemberService(this._supabase);

  /// Fetch full member records (Admin access enforced by RLS)
  Future<List<Member>> getMembers({bool? activeOnly, String? search}) async {
    var query = _supabase.from('members').select();

    if (activeOnly != null) {
      query = query.eq('is_active', activeOnly);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,member_code.ilike.%$search%,mobile.ilike.%$search%');
    }

    final response = await query.order('member_code', ascending: true);
    return (response as List).map((json) => Member.fromJson(json)).toList();
  }

  /// Fetch restricted public directory (Names & codes only, safe for all members)
  Future<List<PublicMember>> getPublicMemberList() async {
    final response = await _supabase
        .from('public_members_view')
        .select()
        .order('full_name', ascending: true);
    return (response as List).map((json) => PublicMember.fromJson(json)).toList();
  }

  /// Get single member by ID
  Future<Member?> getMemberById(String id) async {
    final response = await _supabase.from('members').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Member.fromJson(response);
  }

  /// Create new member
  Future<Member> createMember({
    required String memberCode,
    required String fullName,
    required String mobile,
    String? address,
    required double monthlyInstallment,
  }) async {
    final normalizedMobile = Formatters.normalizeMobile(mobile);
    final data = {
      'member_code': memberCode.trim().toUpperCase(),
      'full_name': fullName.trim(),
      'mobile': normalizedMobile,
      'address': address?.trim(),
      'monthly_installment': monthlyInstallment,
      'is_active': true,
    };

    final res = await _supabase.from('members').insert(data).select().single();
    return Member.fromJson(res);
  }

  /// Update existing member
  Future<Member> updateMember(Member member) async {
    final normalizedMobile = Formatters.normalizeMobile(member.mobile);
    final data = {
      'member_code': member.memberCode.trim().toUpperCase(),
      'full_name': member.fullName.trim(),
      'mobile': normalizedMobile,
      'address': member.address?.trim(),
      'monthly_installment': member.monthlyInstallment,
      'is_active': member.isActive,
    };

    final res = await _supabase
        .from('members')
        .update(data)
        .eq('id', member.id)
        .select()
        .single();
    return Member.fromJson(res);
  }

  /// Soft-deactivate a member without deleting historical financial records
  Future<void> toggleMemberActive(String memberId, bool isActive) async {
    await _supabase.from('members').update({'is_active': isActive}).eq('id', memberId);
  }

  /// Safely link an authenticated user profile to a member record
  Future<void> linkMemberProfile({required String userId, required String memberId}) async {
    await _supabase.from('profiles').update({'member_id': memberId}).eq('id', userId);
  }
}
