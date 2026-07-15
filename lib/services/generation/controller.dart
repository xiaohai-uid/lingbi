/// GenerationController — 状态机 + Stream 桥接
///
/// 连接纯状态机 (state_machine.dart) 与 UI Stream。
/// UI 层订阅 stateStream 即可实时响应状态变更。
library;

import 'dart:async';
import 'state_machine.dart';

/// 连接纯状态机与 UI Stream 的控制器
class GenerationController {
  GenerationState _state = const IdleState();
  final _stateController = StreamController<GenerationState>.broadcast();

  /// 状态变更流
  Stream<GenerationState> get stateStream => _stateController.stream;

  /// 当前状态
  GenerationState get currentState => _state;

  void _emit(GenerationState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  void setInput(GenerationInput input) {
    _emit(transition(_state, SetInputEvent(input)));
  }

  void startGeneration() {
    _emit(transition(_state, const StartGenerationEvent()));
  }

  void streamChunk(String chunk) {
    _emit(transition(_state, StreamChunkEvent(chunk)));
  }

  void phaseComplete(Object output) {
    _emit(transition(_state, PhaseCompleteEvent(output)));
  }

  void completeAll(NovelResult result) {
    _emit(transition(_state, AllCompleteEvent(result)));
  }

  void confirm({String? feedback}) {
    _emit(transition(_state, ConfirmEvent(feedback: feedback)));
  }

  void reject({String? reason}) {
    _emit(transition(_state, RejectEvent(reason: reason)));
  }

  void cancel() {
    _emit(transition(_state, const CancelEvent()));
  }

  void completeSegment(String content) {
    _emit(transition(_state, CompleteSegmentEvent(content)));
  }

  void selectDirection(int index) {
    _emit(transition(_state, SelectDirectionEvent(index)));
  }

  void pause() {
    _emit(transition(_state, const PauseEvent()));
  }

  void resume() {
    _emit(transition(_state, const ResumeEvent()));
  }

  void retry() {
    _emit(transition(_state, const RetryEvent()));
  }

  void reset() {
    _emit(transition(_state, const ResetEvent()));
  }

  void error(GenerationError err) {
    _emit(transition(_state, ErrorEvent(err)));
  }

  void dispose() {
    _stateController.close();
  }
}
