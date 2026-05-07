import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/bank_details_model.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> fetchUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<BankDetailsModel?> fetchBankDetails(String userId) async {
    final response = await _supabase
        .from('bank_details')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return BankDetailsModel.fromJson(response);
  }

  Stream<UserModel?> streamUserProfile(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) {
          if (event.isEmpty) return null;
          return UserModel.fromJson(event.first);
        });
  }
}
