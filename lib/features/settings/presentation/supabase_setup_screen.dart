import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/presentation/auth_cubit.dart';

class SupabaseSetupScreen extends StatefulWidget {
  const SupabaseSetupScreen({super.key});

  @override
  State<SupabaseSetupScreen> createState() => _SupabaseSetupScreenState();
}

class _SupabaseSetupScreenState extends State<SupabaseSetupScreen> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  bool _isConnecting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = SupabaseConfig.currentUrl;
    _anonKeyController.text = SupabaseConfig.currentAnonKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  Future<void> _connectSupabase() async {
    final url = _urlController.text.trim();
    final key = _anonKeyController.text.trim();

    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _statusMessage = 'يرجى إدخال رابط المشروع والمفتاح المجهول (Anon Key)';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = null;
    });

    final success = await SupabaseConfig.initialize(
      url: url,
      anonKey: key,
      demoMode: false,
    );

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isSuccess = success;
        _statusMessage = success
            ? 'تم الاتصال بقاعدة بيانات Supabase بنجاح!'
            : 'فشل الاتصال، يرجى التحقق من الرابط والمفتاح والتأكد من إتاحة الإنترنت';
      });
    }
  }

  Future<void> _enableDemoMode() async {
    await SupabaseConfig.enableDemoMode();
    if (mounted) {
      context.read<AuthCubit>().signInDemoMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل وضع المعاينة (Demo Mode) بالبيانات المحلية'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = SupabaseConfig.isDemoMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات الاتصال بـ Supabase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDemo ? AppColors.yellow.withValues(alpha: 0.12) : AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDemo ? AppColors.yellow.withValues(alpha: 0.3) : AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDemo ? Icons.offline_bolt_outlined : Icons.cloud_done_outlined,
                    color: isDemo ? AppColors.yellow : AppColors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDemo ? 'الوضع الحالي: وضع المعاينة (Demo Mode)' : 'الوضع الحالي: متصل بـ Supabase',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDemo ? AppColors.yellow : AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDemo
                              ? 'التطبيق يعمل ببيانات نموذجية محلية لحصص وطلاب البرمجة.'
                              : 'التطبيق متصل مباشرة بقاعدة بيانات PostgreSQL السحابية.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بيانات الاعتماد (Supabase API Credentials)',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تجد هذه البيانات داخل لوحة تحكم مشروعك في Settings -> API',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const Divider(color: AppColors.border, height: 24),

                  CustomTextField(
                    controller: _urlController,
                    label: 'Project URL',
                    hintText: 'https://xxxxxxxx.supabase.co',
                    textDirection: TextDirection.ltr,
                    prefixIcon: Icons.link,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _anonKeyController,
                    label: 'Anon Public Key',
                    hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    textDirection: TextDirection.ltr,
                    maxLines: 2,
                    prefixIcon: Icons.vpn_key_outlined,
                  ),
                  const SizedBox(height: 20),

                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? AppColors.green.withValues(alpha: 0.12) : AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSuccess ? AppColors.green.withValues(alpha: 0.3) : AppColors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                            color: _isSuccess ? AppColors.green : AppColors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _isSuccess ? AppColors.green : AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomButton(
                    text: 'حفظ واختبار الاتصال',
                    icon: Icons.sync,
                    isFullWidth: true,
                    isLoading: _isConnecting,
                    onPressed: _connectSupabase,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Demo Mode fallback box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العمل بدون اتصال (Offline Demo)',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'إذا لم تكن قد أنشأت مشروع Supabase بعد أو لا يتوفر إنترنت، يمكنك التبديل إلى وضع المعاينة التجريبي بضغطة زر واحدة.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('التبديل إلى وضع المعاينة (Demo Mode)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.yellow,
                      side: BorderSide(color: AppColors.yellow.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _enableDemoMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
