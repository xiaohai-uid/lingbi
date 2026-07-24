import 'package:flutter/material.dart';
import 'package:lingbi/core/models/project.dart';

/// 项目 Tab 模型
class ProjectTab {

  ProjectTab({required this.project}) : id = project.id;
  final Project project;
  final String id;
}

/// 多项目 Tab 控制器
class ProjectTabController extends ChangeNotifier {
  final List<ProjectTab> _tabs = [];
  int _activeIndex = 0;

  List<ProjectTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  ProjectTab? get activeTab => _tabs.isNotEmpty ? _tabs[_activeIndex] : null;
  bool get isEmpty => _tabs.isEmpty;

  /// 打开项目（如果已存在则切换到该 Tab）
  void openProject(Project project) {
    final existingIndex = _tabs.indexWhere((t) => t.id == project.id);
    if (existingIndex >= 0) {
      _activeIndex = existingIndex;
    } else {
      _tabs.add(ProjectTab(project: project));
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  /// 切换到指定 Tab
  void switchTo(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  /// 关闭 Tab
  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _activeIndex = -1;
    } else if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    } else if (index < _activeIndex) {
      _activeIndex--;
    }
    notifyListeners();
  }

  /// 关闭除当前外的所有 Tab
  void closeOtherTabs(int index) {
    if (_tabs.length <= 1) return;
    final keep = _tabs[index];
    _tabs.clear();
    _tabs.add(keep);
    _activeIndex = 0;
    notifyListeners();
  }

  /// 关闭所有 Tab
  void closeAll() {
    _tabs.clear();
    _activeIndex = -1;
    notifyListeners();
  }
}
