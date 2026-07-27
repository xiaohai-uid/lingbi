import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/modules/context/context_compiler.dart';
import 'package:lingbi/modules/context/context_manifest.dart';

void main() {
  group('ContextCompiler budget allocation', () {
    test('allocates tokens by priority and never exceeds budget', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 4000,
      ));
      final entries = [
        ContextEntry(
          id: 'intent',
          source: 'compass',
          reason: 'Author intent is mandatory',
          timePoint: null,
          priority: ContextPriority.mandatory,
          content: 'Write a xuanhuan opening with a betrayed protagonist.',
        ),
        ContextEntry(
          id: 'recent-text',
          source: 'document:ch-004',
          reason: 'Continuity with previous chapter',
          timePoint: 4,
          priority: ContextPriority.high,
          content: 'A' * 6000,
        ),
        ContextEntry(
          id: 'canon-char',
          source: 'canon:character:ye-lan',
          reason: 'Active character in scene',
          timePoint: 3,
          priority: ContextPriority.medium,
          content: 'B' * 3000,
        ),
        ContextEntry(
          id: 'market',
          source: 'market_intel',
          reason: 'Optional market context',
          timePoint: null,
          priority: ContextPriority.low,
          content: 'C' * 5000,
        ),
      ];

      final result = compiler.compile(entries);

      expect(result.tokenEstimate, lessThanOrEqualTo(4000));
      final intentEntry = result.entries.firstWhere((e) => e.id == 'intent');
      expect(intentEntry.truncationStatus, TruncationStatus.full);
      final marketEntry = result.entries.firstWhere((e) => e.id == 'market');
      expect(marketEntry.truncationStatus, isNot(TruncationStatus.full));
    });

    test('time-aware facts prefer recent chapters over old ones', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 2000,
      ));
      final entries = [
        ContextEntry(
          id: 'old-fact',
          source: 'story_graph:fact-1',
          reason: 'Character was weak in chapter 1',
          timePoint: 1,
          priority: ContextPriority.medium,
          content: 'Old fact ' * 200,
        ),
        ContextEntry(
          id: 'new-fact',
          source: 'story_graph:fact-2',
          reason: 'Character is now powerful in chapter 50',
          timePoint: 50,
          priority: ContextPriority.medium,
          content: 'New fact ' * 200,
        ),
      ];

      final result = compiler.compile(entries, currentChapter: 50);

      final newEntry = result.entries.firstWhere((e) => e.id == 'new-fact');
      final oldEntry = result.entries.firstWhere((e) => e.id == 'old-fact');
      expect(newEntry.allocatedTokens, greaterThanOrEqualTo(oldEntry.allocatedTokens));
    });

    test('mandatory constraints are never omitted even under extreme pressure', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 500,
      ));
      final entries = [
        ContextEntry(
          id: 'constraint',
          source: 'canon:lore:rule-1',
          reason: 'Hard world rule: no resurrection without cost',
          timePoint: null,
          priority: ContextPriority.mandatory,
          content: 'No resurrection without equivalent exchange.' * 10,
        ),
        ContextEntry(
          id: 'filler',
          source: 'document:ch-001',
          reason: 'Old chapter text',
          timePoint: 1,
          priority: ContextPriority.low,
          content: 'X' * 10000,
        ),
      ];

      final result = compiler.compile(entries);

      final constraint = result.entries.firstWhere((e) => e.id == 'constraint');
      expect(constraint.truncationStatus, isNot(TruncationStatus.omitted));
      final filler = result.entries.firstWhere((e) => e.id == 'filler');
      expect(filler.truncationStatus, isNot(TruncationStatus.full));
    });

    test('deterministic truncation produces identical output on repeated calls', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 3000,
      ));
      final entries = List.generate(10, (i) => ContextEntry(
        id: 'entry-$i',
        source: 'source-$i',
        reason: 'Reason $i',
        timePoint: i,
        priority: ContextPriority.values[i % ContextPriority.values.length],
        content: 'Content $i ' * 100,
      ));

      final result1 = compiler.compile(entries, currentChapter: 5);
      final result2 = compiler.compile(entries, currentChapter: 5);

      expect(result1.text, equals(result2.text));
      expect(result1.tokenEstimate, equals(result2.tokenEstimate));
      expect(
        result1.entries.map((e) => e.allocatedTokens).toList(),
        equals(result2.entries.map((e) => e.allocatedTokens).toList()),
      );
    });

    test('omissions are recorded with reason and source', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 1000,
      ));
      final entries = [
        ContextEntry(
          id: 'big-low',
          source: 'rag:vector-search',
          reason: 'Semantic recall',
          timePoint: null,
          priority: ContextPriority.low,
          content: 'Z' * 20000,
        ),
      ];

      final result = compiler.compile(entries);

      expect(result.omissions, isNotEmpty);
      expect(result.omissions.first.sourceId, 'rag:vector-search');
      expect(result.omissions.first.reason, isNotEmpty);
    });
  });

  group('ContextCompiler source display', () {
    test('every entry in the manifest has source, reason, and token cost', () {
      final compiler = ContextCompiler(config: const CompilerConfig(
        tokenBudget: 8000,
      ));
      final entries = [
        ContextEntry(
          id: 'a',
          source: 'canon:character:hero',
          reason: 'Protagonist card',
          timePoint: 10,
          priority: ContextPriority.high,
          content: 'Hero description',
        ),
      ];

      final result = compiler.compile(entries);
      final manifest = result.manifest;

      expect(manifest.entries, hasLength(1));
      expect(manifest.entries.first.source, 'canon:character:hero');
      expect(manifest.entries.first.reason, 'Protagonist card');
      expect(manifest.entries.first.tokenCost, greaterThan(0));
      expect(manifest.totalTokens, equals(result.tokenEstimate));
    });
  });
}
