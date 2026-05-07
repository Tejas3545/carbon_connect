import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

final kycProvider = StateNotifierProvider<KycNotifier, AsyncValue<void>>((ref) {
  return KycNotifier();
});

class KycNotifier extends StateNotifier<AsyncValue<void>> {
  KycNotifier() : super(const AsyncValue.data(null));

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Optimize image size
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<void> submitKyc({
    required XFile panImage,
    required XFile aadhaarImage,
    required String accountNo,
    required String ifsc,
    required String accountName,
    required String bankName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = AsyncValue.error('User not logged in', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      // 1. Upload PAN
      final panBytes = await panImage.readAsBytes();
      // On Web, use the name to get extension, or default to jpg
      final panName = panImage.name;
      final panExt = panName.contains('.') ? panName.split('.').last : 'jpg';
      final panPath = '${user.id}/pan_${DateTime.now().millisecondsSinceEpoch}.$panExt';
      
      await _supabase.storage.from('kyc-docs').uploadBinary(
        panPath,
        panBytes,
        fileOptions: FileOptions(contentType: 'image/$panExt'),
      );

      // 2. Upload Aadhaar
      final aadhaarBytes = await aadhaarImage.readAsBytes();
      final aadhaarName = aadhaarImage.name;
      final aadhaarExt = aadhaarName.contains('.') ? aadhaarName.split('.').last : 'jpg';
      final aadhaarPath = '${user.id}/aadhaar_${DateTime.now().millisecondsSinceEpoch}.$aadhaarExt';
      
      await _supabase.storage.from('kyc-docs').uploadBinary(
        aadhaarPath,
        aadhaarBytes,
        fileOptions: FileOptions(contentType: 'image/$aadhaarExt'),
      );

      // 3. Save Documents to kyc_documents table
      await _supabase.from('kyc_documents').insert([
        {
          'user_id': user.id,
          'doc_type': 'PAN',
          'doc_url': panPath,
          'status': 'PENDING',
        },
        {
          'user_id': user.id,
          'doc_type': 'AADHAAR',
          'doc_url': aadhaarPath,
          'status': 'PENDING',
        }
      ]);

      // 4. Save Bank Details
      await _supabase.from('bank_details').upsert({
        'user_id': user.id,
        'account_number': accountNo,
        'ifsc_code': ifsc,
        'account_holder_name': accountName,
        'bank_name': bankName,
      });

      // 5. Update User Profile & KYC Status (Set to VERIFIED for production demo)
      await _supabase.from('users').update({
        'full_name': accountName,
        'kyc_status': 'VERIFIED',
      }).eq('id', user.id);


      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('KYC Submission Error: $e');
      state = AsyncValue.error(e, st);
    }
  }
}
