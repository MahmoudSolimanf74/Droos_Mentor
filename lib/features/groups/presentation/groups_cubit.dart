import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/groups_repository.dart';
import '../domain/group_model.dart';

abstract class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  final List<GroupModel> groups;
  final String? gradeIdFilter;
  final String searchQuery;

  const GroupsLoaded({
    required this.groups,
    this.gradeIdFilter,
    this.searchQuery = '',
  });

  List<GroupModel> get filteredGroups {
    return groups.where((g) {
      final matchesGrade = gradeIdFilter == null || gradeIdFilter!.isEmpty || g.gradeId == gradeIdFilter;
      final matchesSearch = searchQuery.isEmpty ||
          g.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          g.gradeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          g.joinCode.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesGrade && matchesSearch;
    }).toList();
  }

  GroupsLoaded copyWith({
    List<GroupModel>? groups,
    String? gradeIdFilter,
    String? searchQuery,
    bool clearGradeFilter = false,
  }) {
    return GroupsLoaded(
      groups: groups ?? this.groups,
      gradeIdFilter: clearGradeFilter ? null : (gradeIdFilter ?? this.gradeIdFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [groups, gradeIdFilter, searchQuery];
}

class GroupsError extends GroupsState {
  final String message;

  const GroupsError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupsCubit extends Cubit<GroupsState> {
  final GroupsRepository _repository;

  GroupsCubit(this._repository) : super(GroupsInitial());

  Future<void> loadGroups({String? gradeId}) async {
    emit(GroupsLoading());
    try {
      final groups = await _repository.getGroups(gradeId: gradeId);
      emit(GroupsLoaded(groups: groups, gradeIdFilter: gradeId));
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  void filterByGrade(String? gradeId) {
    if (state is GroupsLoaded) {
      final current = state as GroupsLoaded;
      emit(current.copyWith(gradeIdFilter: gradeId, clearGradeFilter: gradeId == null));
    }
  }

  void searchGroups(String query) {
    if (state is GroupsLoaded) {
      final current = state as GroupsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  Future<void> createGroup({required String name, required String gradeId}) async {
    try {
      await _repository.createGroup(name: name, gradeId: gradeId);
      await loadGroups();
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required String gradeId,
    String? status,
  }) async {
    try {
      await _repository.updateGroup(
        groupId: groupId,
        name: name,
        gradeId: gradeId,
        status: status,
      );
      await loadGroups();
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _repository.deleteGroup(groupId);
      await loadGroups();
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  Future<String> regenerateQrToken(String groupId) async {
    final token = await _repository.regenerateQrToken(groupId);
    await loadGroups();
    return token;
  }

  Future<String> regenerateJoinCode(String groupId) async {
    final code = await _repository.regenerateJoinCode(groupId);
    await loadGroups();
    return code;
  }

  Future<void> toggleActive(String groupId, bool isActive) async {
    await _repository.toggleActive(groupId, isActive);
    await loadGroups();
  }
}
