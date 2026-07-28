import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppCommand {
  newProject,
  openProject,
  commandPalette,
  toggleAi,
  settings,
  save,
  dismiss,
}

enum AiPresentation { docked, collapsible, overlay }

class WorkspaceLayoutPolicy {
  const WorkspaceLayoutPolicy({
    required this.aiPresentation,
    required this.editorMinWidth,
  });

  factory WorkspaceLayoutPolicy.forWidth(double width) {
    if (width <= 1024) {
      return const WorkspaceLayoutPolicy(
        aiPresentation: AiPresentation.overlay,
        editorMinWidth: 600,
      );
    }
    if (width < 1440) {
      return const WorkspaceLayoutPolicy(
        aiPresentation: AiPresentation.collapsible,
        editorMinWidth: 600,
      );
    }
    return const WorkspaceLayoutPolicy(
      aiPresentation: AiPresentation.docked,
      editorMinWidth: 600,
    );
  }

  final AiPresentation aiPresentation;
  final double editorMinWidth;
}

class CommandPaletteService {
  final ValueNotifier<AppCommand?> events = ValueNotifier(null);

  AppCommand? resolve(
    LogicalKeyboardKey key, {
    bool control = false,
    bool shift = false,
  }) {
    if (key == LogicalKeyboardKey.escape) return AppCommand.dismiss;
    if (!control) return null;
    if (key == LogicalKeyboardKey.keyN && !shift) return AppCommand.newProject;
    if (key == LogicalKeyboardKey.keyO && !shift) return AppCommand.openProject;
    if (key == LogicalKeyboardKey.keyK && !shift) {
      return AppCommand.commandPalette;
    }
    if (key == LogicalKeyboardKey.keyA && shift) return AppCommand.toggleAi;
    if (key == LogicalKeyboardKey.comma && !shift) return AppCommand.settings;
    if (key == LogicalKeyboardKey.keyS && !shift) return AppCommand.save;
    return null;
  }

  void dispatch(AppCommand command) {
    events.value = null;
    events.value = command;
  }

  void dispose() => events.dispose();
}
