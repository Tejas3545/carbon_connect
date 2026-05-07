import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/kyc_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  int _currentStep = 0;
  
  XFile? _panImage;
  XFile? _aadhaarImage;
  
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();

  @override
  void dispose() {
    _accountNoController.dispose();
    _ifscController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  bool _validateIFSC(String ifsc) {
    final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return regex.hasMatch(ifsc);
  }

  void _submitKyc() async {
    final accountNo = _accountNoController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final accountName = _accountNameController.text.trim();
    final bankName = _bankNameController.text.trim();

    if (_panImage == null || _aadhaarImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both PAN and Aadhaar')),
      );
      return;
    }

    if (accountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account holder name is required')));
      return;
    }

    if (accountNo.length < 9 || !RegExp(r'^\d+$').hasMatch(accountNo)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Bank Account Number (9-18 digits)')));
      return;
    }

    if (!_validateIFSC(ifsc)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid IFSC Code. Format: ABCD0123456')));
      return;
    }

    if (bankName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank name is required')));
      return;
    }

    await ref.read(kycProvider.notifier).submitKyc(
      panImage: _panImage!,
      aadhaarImage: _aadhaarImage!,
      accountNo: accountNo,
      ifsc: ifsc,
      accountName: accountName,
      bankName: bankName,
    );

    final kycState = ref.read(kycProvider);
    if (!kycState.hasError && mounted) {
      context.go('/market');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KYC Error: ${kycState.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);

    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb, // Fix for Web "ViewInsets cannot be negative"
      appBar: AppBar(
        title: const Text('Complete KYC'),
        centerTitle: true,
      ),
      body: kycState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitKyc();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              steps: [
                Step(
                  title: const Text('PAN Card'),
                  content: Column(
                    children: [
                      if (_panImage != null)
                        kIsWeb ? Image.network(_panImage!.path, height: 150) : Image.file(File(_panImage!.path), height: 150)
                      else
                        Container(
                          height: 150,
                          color: const Color(0xFF1E2D42),
                          child: const Center(child: Text('No Image Selected')),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final file = await ref.read(kycProvider.notifier).pickImage();
                          if (file != null) setState(() => _panImage = file);
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload PAN'),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Aadhaar Card'),
                  content: Column(
                    children: [
                      if (_aadhaarImage != null)
                        kIsWeb ? Image.network(_aadhaarImage!.path, height: 150) : Image.file(File(_aadhaarImage!.path), height: 150)
                      else
                        Container(
                          height: 150,
                          color: const Color(0xFF1E2D42),
                          child: const Center(child: Text('No Image Selected')),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final file = await ref.read(kycProvider.notifier).pickImage();
                          if (file != null) setState(() => _aadhaarImage = file);
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Aadhaar'),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Bank Details'),
                  content: Column(
                    children: [
                      TextField(
                        controller: _accountNameController,
                        decoration: const InputDecoration(labelText: 'Account Holder Name'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _accountNoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Account Number'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ifscController,
                        decoration: const InputDecoration(labelText: 'IFSC Code'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(labelText: 'Bank Name'),
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
    );
  }
}
