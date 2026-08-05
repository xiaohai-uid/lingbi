# LingBi #55 Large-File Split Decision — 2026-08-05

## Context

Issue `#55` asks how to split three large files:

- `lib/features/settings/ui/settings_page.dart`: 1,657 lines / 56,789 bytes
- `lib/ui_v2/components/ai_assistant.dart`: 1,597 lines / 55,721 bytes
- Old `onboarding_wizard.dart`: referenced by `#55`, but already removed from `origin/main`

Current `origin/main` no longer contains `onboarding_wizard.dart`. The onboarding code is split into
`guided_wizard_state_machine.dart` (392 lines), `welcome_page.dart` (287 lines), and small adapters.
No large-file split ticket is needed for onboarding now.

This decision only refactors structure. It does not add payment, subscription, billing, or legal
behavior, and it does not change any feature behavior.

## Decisions

1. Split by functional section and rendering responsibility, not by widget nesting or state.
2. Use a facade/strangler pattern. The public file and public widget remain the entry point.
   Each moved piece lands in a dedicated file behind the facade. Every intermediate state compiles
   and passes tests.
3. Order the work as `settings_page` first, then `ai_assistant`. Settings has low coupling and many
   independent sections; AI Assistant has shared send state and should first extract read-only render
   code.
4. Move section-specific controller ownership into section widgets. The settings facade should not
   own controllers for every section.
5. Existing tests stay as the behavior contract. Add focused widget/model tests only where a moved
   public component needs a direct test seam.

## SettingsPage Target

Keep `lib/features/settings/ui/settings_page.dart` as the facade. It owns the section list, side nav,
and dispatch. Move each section into `lib/features/settings/ui/sections/`:

- `settings_section_scaffold.dart`: shared section scaffold, setting item, and input decoration
- `appearance_settings_section.dart`
- `editor_settings_section.dart`
- `ai_model_settings_section.dart`
- `api_key_settings_section.dart`
- `custom_endpoint_settings_section.dart`
- `shortcuts_settings_section.dart`
- `storage_settings_section.dart`
- `cloud_sync_settings_section.dart`
- `privacy_settings_section.dart`
- `subscription_settings_section.dart`

The subscription section is moved as-is. No new license activation or billing behavior is added.

## AiAssistant Target

Move `lib/ui_v2/components/ai_assistant.dart` into
`lib/ui_v2/components/ai_assistant/`:

- `chat_message.dart`: public `ChatMessage` model moved from `_ChatMessage`
- `ai_assistant_panel.dart`: public `AiAssistantPanel` and its state facade, including the existing
  agent/simple send paths for the first split
- `message_builders.dart`: read-only render helpers for AI, user, clarification, agent question,
  process, and tool-step content
- `chat_input_bar.dart`: `ChatInputBar` and `AgentOpenInput` moved from private widgets

The send paths stay in the panel until rendering and model extraction are proven. A later ticket may
extract a send controller if the file still exceeds the maintainability target.

## Tickets

- `#91`: split `settings_page.dart` by section, keeping the facade
- `#92`: split `ai_assistant.dart` into chat model and render components, keeping send logic in the
  panel facade

Each ticket gets its own branch, focused test changes, PR, and issue close. No cross-ticket code edits.

## Verification

For each split ticket:

- `flutter analyze lib/`
- focused existing tests for the moved feature plus `flutter test test/widget_test.dart`
- `flutter test --exclude-tags network --concurrency=1`
- `git diff --check`
- CI analyze-and-test and Windows build before merge

No behavior change is expected; Windows smoke is required only if a UI behavior regression is
introduced.
