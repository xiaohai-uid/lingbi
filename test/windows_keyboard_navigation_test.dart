import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/ui_v2/services/command_palette_service.dart';
import 'package:lingbi/ui_v2/components/command_palette.dart';
import 'package:flutter/material.dart';

void main() {
  group('Windows command routing', () {
    test('maps all P0 keyboard commands', () {
      final service = CommandPaletteService();
      expect(
        service.resolve(
          LogicalKeyboardKey.keyN,
          control: true,
        ),
        AppCommand.newProject,
      );
      expect(
        service.resolve(LogicalKeyboardKey.keyO, control: true),
        AppCommand.openProject,
      );
      expect(
        service.resolve(LogicalKeyboardKey.keyK, control: true),
        AppCommand.commandPalette,
      );
      expect(
        service.resolve(
          LogicalKeyboardKey.keyA,
          control: true,
          shift: true,
        ),
        AppCommand.toggleAi,
      );
      expect(
        service.resolve(LogicalKeyboardKey.comma, control: true),
        AppCommand.settings,
      );
      expect(
        service.resolve(LogicalKeyboardKey.keyS, control: true),
        AppCommand.save,
      );
    });

    test('Escape closes transient UI without becoming a destructive command',
        () {
      final service = CommandPaletteService();
      expect(service.resolve(LogicalKeyboardKey.escape), AppCommand.dismiss);
      expect(service.resolve(LogicalKeyboardKey.delete), isNull);
    });
  });

  group('Windows responsive policy', () {
    test('preserves at least 600 px for the editor', () {
      expect(WorkspaceLayoutPolicy.forWidth(1440).editorMinWidth, 600);
      expect(WorkspaceLayoutPolicy.forWidth(1280).aiPresentation,
          AiPresentation.collapsible);
      expect(WorkspaceLayoutPolicy.forWidth(1024).aiPresentation,
          AiPresentation.overlay);
    });
  });

  testWidgets('command palette takes focus and Escape dismisses it',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => CommandPalette.show(
            context,
            onSelected: (_) {},
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(CommandPalette), findsNothing);
  });
}
