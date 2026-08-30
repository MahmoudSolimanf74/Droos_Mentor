import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../grades/data/grades_repository.dart';
import '../../grades/domain/grade_model.dart';
import '../domain/group_model.dart';
import 'groups_cubit.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_qr_dialog.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GradeModel> _grades = [];

  @override
  void initState() {
    super.initState();
    context.read<GroupsCubit>().loadGroups();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final grades = await context.read<GradesRepository>().getGrades();
      if (mounted) {
        setState(() => _grades = grades);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.copied),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _confirmDeleteGroup(GroupModel group) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المجموعة',
      message: AppStrings.deleteGroupWarning,
      isDangerous: true,
      confirmText: AppStrings.delete,
    );
    if (confirmed == true && mounted) {
      context.read<GroupsCubit>().deleteGroup(group.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.navGroups, style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppStrings.createGroup,
            onPressed: () {
              CreateGroupDialog.show(
                context,
                onSubmit: (name, gradeId) {
                  context.read<GroupsCubit>().createGroup(name: name, gradeId: gradeId);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.refresh,
            onPressed: () => context.read<GroupsCubit>().loadGroups(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<GroupsCubit, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.sage),
              ),
            );
          } else if (state is GroupsError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<GroupsCubit>().loadGroups(),
            );
          } else if (state is GroupsLoaded) {
            final groups = state.filteredGroups;

            return Column(
              children: [
                // Filter & Search bar
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _searchController,
                              hintText: AppStrings.search,
                              prefixIcon: Icons.search,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<GroupsCubit>().searchGroups('');
                                      },
                                    )
                                  : null,
                              onChanged: (val) => context.read<GroupsCubit>().searchGroups(val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CustomButton(
                            text: 'إنشاء',
                            icon: Icons.add,
                            onPressed: () {
                              CreateGroupDialog.show(
                                context,
                                onSubmit: (name, gradeId) {
                                  context.read<GroupsCubit>().createGroup(name: name, gradeId: gradeId);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      if (_grades.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        // Grade filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('الكل'),
                                selected: state.gradeIdFilter == null,
                                onSelected: (_) => context.read<GroupsCubit>().filterByGrade(null),
                                selectedColor: AppColors.sageLight,
                                labelStyle: AppTextStyles.labelSmall.copyWith(
                                  color: state.gradeIdFilter == null ? AppColors.sageDark : AppColors.textSecondary,
                                  fontWeight: state.gradeIdFilter == null ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ..._grades.map((g) {
                                final isSelected = state.gradeIdFilter == g.id;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: FilterChip(
                                    label: Text(g.name),
                                    selected: isSelected,
                                    onSelected: (_) => context.read<GroupsCubit>().filterByGrade(isSelected ? null : g.id),
                                    selectedColor: AppColors.sageLight,
                                    labelStyle: AppTextStyles.labelSmall.copyWith(
                                      color: isSelected ? AppColors.sageDark : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),

                // Groups List
                Expanded(
                  child: groups.isEmpty
                      ? EmptyStateView(
                          title: 'لا توجد نتائج مطابقة',
                          subtitle: 'جرّب البحث باسم آخر أو إزالة التصفية أو إنشاء مجموعة جديدة',
                          icon: Icons.search_off_outlined,
                          actionText: AppStrings.createGroup,
                          onAction: () {
                            CreateGroupDialog.show(
                              context,
                              onSubmit: (name, gradeId) {
                                context.read<GroupsCubit>().createGroup(name: name, gradeId: gradeId);
                              },
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: groups.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return _buildGroupCard(context, group);
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    return Card(
      child: InkWell(
        onTap: () => context.goNamed(
          RouteNames.groupDetails,
          pathParameters: {'id': group.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              group.gradeName,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: group.isActive ? AppStrings.statusActive : AppStrings.statusInactive,
                    variant: group.isActive ? BadgeVariant.success : BadgeVariant.danger,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Students Count
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.sageDark),
                      const SizedBox(width: 6),
                      Text(
                        '${group.studentsCount} ${AppStrings.studentsCount}',
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  // Actions: Join code, QR Code, Options
                  Row(
                    children: [
                      // Join Code Chip
                      InkWell(
                        onTap: () => _copyJoinCode(group.joinCode),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.key_outlined, size: 14, color: AppColors.bronze),
                              const SizedBox(width: 6),
                              Text(
                                group.joinCode,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_outlined, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // QR Dialog Button
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.primary),
                        tooltip: AppStrings.qrCode,
                        onPressed: () {
                          GroupQrDialog.show(
                            context,
                            group: group,
                            onRegenerateToken: () => context.read<GroupsCubit>().regenerateQrToken(group.id),
                          );
                        },
                      ),

                      // Edit Group Button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: AppStrings.edit,
                        onPressed: () {
                          CreateGroupDialog.show(
                            context,
                            initialGroup: group,
                            onSubmit: (name, gradeId) {
                              context.read<GroupsCubit>().updateGroup(
                                    groupId: group.id,
                                    name: name,
                                    gradeId: gradeId,
                                  );
                            },
                          );
                        },
                      ),

                      // Delete Group Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        tooltip: AppStrings.delete,
                        onPressed: () => _confirmDeleteGroup(group),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
