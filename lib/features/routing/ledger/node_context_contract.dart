/// Node-level context contract from Fusion module D.
final class NodeContextContract {
  const NodeContextContract({
    required this.nodeId,
    required this.inputs,
    required this.outputs,
  });

  final String nodeId;
  final List<String> inputs;
  final List<String> outputs;

  /// Returns input keys missing from [context].
  List<String> validateInputs(Map<String, dynamic> context) {
    return inputs.where((key) => !context.containsKey(key)).toList();
  }
}
