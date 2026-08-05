import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/features/routing/ledger/node_context_contract.dart';
import 'package:lingbi/features/routing/ledger/token_ledger.dart';

void main() {
  late Directory temp;
  late TokenLedger ledger;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lingbi_fusion_p4_');
    ledger = TokenLedger(basePath: temp.path);
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('NodeContextContract reports missing input keys', () {
    const contract = NodeContextContract(
      nodeId: 'draft',
      inputs: ['context', 'document'],
      outputs: ['text'],
    );

    final missing = contract.validateInputs({'context': 'value'});

    expect(missing, ['document']);
  });

  test('TokenLedger summarizes by run and node', () async {
    ledger.append(const TokenLedgerEntry(
      runId: 'run-1',
      nodeId: 'context',
      attempt: 0,
      promptTokens: 10,
      completionTokens: 20,
      providerId: 'free',
    ));
    ledger.append(const TokenLedgerEntry(
      runId: 'run-1',
      nodeId: 'draft',
      attempt: 0,
      promptTokens: 30,
      completionTokens: 40,
      providerId: 'free',
    ));
    ledger.append(const TokenLedgerEntry(
      runId: 'run-1',
      nodeId: 'draft',
      attempt: 1,
      promptTokens: 5,
      completionTokens: 6,
      providerId: 'free',
    ));

    final run = await ledger.summarize('run-1');
    expect(run.promptTokens, 45);
    expect(run.completionTokens, 66);

    final byNode = await ledger.summarizeByNode('run-1');
    expect(byNode['draft']?.promptTokens, 35);
    expect(byNode['draft']?.completionTokens, 46);
    expect(byNode['context']?.attempts, 1);
  });

  test('ledger keeps attempts independent', () async {
    ledger.append(const TokenLedgerEntry(
      runId: 'run-2',
      nodeId: 'gate',
      attempt: 0,
      promptTokens: 1,
      completionTokens: 2,
      providerId: 'free',
    ));
    ledger.append(const TokenLedgerEntry(
      runId: 'run-2',
      nodeId: 'gate',
      attempt: 1,
      promptTokens: 3,
      completionTokens: 4,
      providerId: 'free',
    ));

    final byNode = await ledger.summarizeByNode('run-2');
    expect(byNode['gate']?.attempts, 2);
  });

  test('ledger panel is wired into toolbox', () {
    expect(
      File('lib/features/routing/ui/token_ledger_panel.dart').existsSync(),
      isTrue,
    );
    final toolbox = File(
      'lib/ui_v2/components/toolbox_page.dart',
    ).readAsLinesSync().join('\n');
    expect(toolbox, contains('Token 账本'));
    expect(toolbox, contains('TokenLedgerPanel'));
  });
}
