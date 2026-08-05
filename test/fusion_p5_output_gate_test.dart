import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/features/routing/gate/output_gate.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lingbi_fusion_p5_');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('structure gate reports missing JSON fields', () {
    const gate = StructureGate(requiredFields: ['title', 'body']);

    final result = gate.validate('{"title":"ok"}');

    expect(result.passed, isFalse);
    expect(result.errors, contains(contains('body')));
  });

  test('repair loop fixes output within max rounds', () async {
    const gate = StructureGate(requiredFields: ['title', 'body']);
    final result = await gate.repair(
      output: '{"title":"ok"}',
      maxRounds: 2,
      repair: (output, errors) async => '{"title":"ok","body":"fixed"}',
    );

    expect(result.passed, isTrue);
    expect(result.repairedOutput, contains('"body":"fixed"'));
    expect(result.repairRounds, 1);
  });

  test('repair loop returns gate_exhausted after max rounds', () async {
    const gate = StructureGate(requiredFields: ['title', 'body']);
    final result = await gate.repair(
      output: '{"title":"ok"}',
      repair: (output, errors) async => output,
    );

    expect(result.passed, isFalse);
    expect(result.errors, contains('gate_exhausted'));
  });

  test('length gate and style gate return typed errors', () {
    const lengthGate = LengthGate(min: 5, max: 10);
    const styleGate = StyleGate();

    expect(lengthGate.validate('短').errors, isNotEmpty);
    expect(styleGate.validate('首先，然后，总之这是一段AI味很重的文本。').errors, isNotEmpty);
  });

  test('RejectReason serializes and candidate stores it', () async {
    final service = CandidateService(
      projectDir: temp.path,
      mutationProtocol: LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: '${temp.path}/journal'),
        store: FileCanonicalStore(
          projectRoot: temp.path,
          atomicStore: AtomicFileStore(),
        ),
      ),
    );
    final entry = service.createCandidate(
      chapterId: 'chapter-1',
      content: 'text',
    );
    const reason = RejectReason(
      fromNodeId: 'candidate',
      targetNodeId: 'draft',
      reason: '节奏太慢',
    );

    service.reject(entry.id, rejectReason: reason);

    final json = reason.toJson();
    expect(RejectReason.fromJson(json).targetNodeId, 'draft');
    final updated = service.getCandidate(entry.id);
    expect(updated!.metadata['reject_reason'], reason.toJson());
  });
}
