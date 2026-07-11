# 灵笔 v4.0 — API 契约

> 基于 gRPC Protobuf v3 | 所有服务间通信走内部 gRPC (:50051 偏移)
> Flutter → API Gateway → 微服务

---

## 文件结构

```
protos/
├── common/
│   └── common.proto          # 共享类型 (UUID, Timestamp, Empty)
├── project/
│   └── project.proto         # World/Work/Volume/Chapter/Scene
├── document/
│   └── document.proto         # .md 文档读写 + 搜索
├── ai/
│   ├── ai_provider.proto     # LLM 调用抽象
│   └── novel_engine.proto    # 三层生成管线
├── canon/
│   └── canon.proto           # 角色/地点/传说/规则 + 关系图
├── quality/
│   └── quality.proto         # 质量审查
├── settings/
│   └── settings.proto        # 用户设置
└── export/
    └── export.proto          # 导出服务
```

## Complete Protobuf Definitions

### common/common.proto

```protobuf
syntax = "proto3";
package lingbi.common;
option go_package = "github.com/xiaohai-uid/lingbi/protos/common";

message Empty {}

message UUID {
  string value = 1;
}

message Timestamp {
  int64 seconds = 1;
  int32 nanos = 2;
}

message Pagination {
  int32 page = 1;
  int32 page_size = 2;
}

message PaginatedResponse {
  int32 total = 1;
  int32 page = 2;
  int32 page_size = 3;
}
```

### project/project.proto

```protobuf
syntax = "proto3";
package lingbi.project;
option go_package = "github.com/xiaohai-uid/lingbi/protos/project";

import "common/common.proto";

// --- 数据模型 ---

message World {
  string id = 1;
  string name = 2;
  string description = 3;
  repeated string genres = 4;
  int64 created_at = 5;
  int64 updated_at = 6;
}

message Work {
  string id = 1;
  string world_id = 2;
  string title = 3;
  string description = 4;
  int32 volume_count = 5;
  int64 created_at = 6;
  int64 updated_at = 7;
}

message Volume {
  string id = 1;
  string work_id = 2;
  string title = 3;
  string summary = 4;
  int32 chapter_count = 5;
  int32 sort_order = 6;
}

message Chapter {
  string id = 1;
  string volume_id = 2;
  string title = 3;
  string summary = 4;
  int32 scene_count = 5;
  int32 sort_order = 6;
}

message Scene {
  string id = 1;
  string chapter_id = 2;
  string title = 3;
  string summary = 4;
  string document_id = 5;
  int32 sort_order = 6;
}

message WorldTree {
  Work work = 1;
  repeated Volume volumes = 2;
  map<string, ChapterList> chapters = 3;
  map<string, SceneList> scenes = 4;
}

message ChapterList {
  repeated Chapter chapters = 1;
}

message SceneList {
  repeated Scene scenes = 1;
}

// --- RPC ---

service ProjectService {
  // World CRUD
  rpc CreateWorld(CreateWorldRequest) returns (World);
  rpc GetWorld(GetWorldRequest) returns (World);
  rpc ListWorlds(ListWorldsRequest) returns (ListWorldsResponse);
  rpc UpdateWorld(UpdateWorldRequest) returns (World);
  rpc DeleteWorld(DeleteWorldRequest) returns (common.Empty);

  // Work CRUD
  rpc CreateWork(CreateWorkRequest) returns (Work);
  rpc GetWork(GetWorkRequest) returns (Work);
  rpc ListWorks(ListWorksRequest) returns (ListWorksResponse);
  rpc UpdateWork(UpdateWorkRequest) returns (Work);
  rpc DeleteWork(DeleteWorkRequest) returns (common.Empty);

  // Volume CRUD
  rpc CreateVolume(CreateVolumeRequest) returns (Volume);
  rpc ListVolumes(ListVolumesRequest) returns (ListVolumesResponse);
  rpc ReorderVolumes(ReorderVolumesRequest) returns (common.Empty);

  // Chapter CRUD
  rpc CreateChapter(CreateChapterRequest) returns (Chapter);
  rpc ListChapters(ListChaptersRequest) returns (ListChaptersResponse);
  rpc ReorderChapters(ReorderChaptersRequest) returns (common.Empty);

  // Scene CRUD
  rpc CreateScene(CreateSceneRequest) returns (Scene);
  rpc ListScenes(ListScenesRequest) returns (ListScenesResponse);
  rpc ReorderScenes(ReorderScenesRequest) returns (common.Empty);

  // Tree
  rpc GetWorldTree(GetWorldTreeRequest) returns (WorldTree);
}

message CreateWorldRequest {
  string name = 1;
  string description = 2;
  repeated string genres = 3;
}

message GetWorldRequest { string id = 1; }

message ListWorldsRequest {
  common.Pagination pagination = 1;
}

message ListWorldsResponse {
  repeated World worlds = 1;
  common.PaginatedResponse pagination = 2;
}

message UpdateWorldRequest {
  string id = 1;
  string name = 2;
  string description = 3;
  repeated string genres = 4;
}

message DeleteWorldRequest { string id = 1; }

message CreateWorkRequest {
  string world_id = 1;
  string title = 2;
  string description = 3;
}

message GetWorkRequest { string id = 1; }

message ListWorksRequest {
  string world_id = 1;
}

message ListWorksResponse {
  repeated Work works = 1;
}

message UpdateWorkRequest {
  string id = 1;
  string title = 2;
  string description = 3;
}

message DeleteWorkRequest { string id = 1; }

message CreateVolumeRequest {
  string work_id = 1;
  string title = 2;
  string summary = 3;
}

message ListVolumesRequest {
  string work_id = 1;
}

message ListVolumesResponse {
  repeated Volume volumes = 1;
}

message ReorderVolumesRequest {
  string work_id = 1;
  repeated string volume_ids = 2;
}

message CreateChapterRequest {
  string volume_id = 1;
  string title = 2;
  string summary = 3;
}

message ListChaptersRequest {
  string volume_id = 1;
}

message ListChaptersResponse {
  repeated Chapter chapters = 1;
}

message ReorderChaptersRequest {
  string volume_id = 1;
  repeated string chapter_ids = 2;
}

message CreateSceneRequest {
  string chapter_id = 1;
  string title = 2;
  string summary = 3;
}

message ListScenesRequest {
  string chapter_id = 1;
}

message ListScenesResponse {
  repeated Scene scenes = 1;
}

message ReorderScenesRequest {
  string chapter_id = 1;
  repeated string scene_ids = 2;
}

message GetWorldTreeRequest {
  string world_id = 1;
}
```

### ai/ai_provider.proto

```protobuf
syntax = "proto3";
package lingbi.ai;
option go_package = "github.com/xiaohai-uid/lingbi/protos/ai";

service AIProviderService {
  rpc GenerateText(GenerateTextRequest) returns (GenerateTextResponse);
  rpc StreamText(StreamTextRequest) returns (stream StreamChunk);
  rpc GenerateStructured(GenerateStructuredRequest) returns (GenerateStructuredResponse);
  rpc ListModels(ListModelsRequest) returns (ListModelsResponse);
  rpc GetModelConfig(GetModelConfigRequest) returns (ModelConfig);
  rpc Embed(EmbedRequest) returns (EmbedResponse);
}

message GenerateTextRequest {
  string provider = 1;
  string model = 2;
  string system_prompt = 3;
  string user_prompt = 4;
  double temperature = 5;
  int32 max_tokens = 6;
}

message GenerateTextResponse {
  string text = 1;
  int32 prompt_tokens = 2;
  int32 completion_tokens = 3;
  int64 latency_ms = 4;
}

message StreamTextRequest {
  string provider = 1;
  string model = 2;
  string system_prompt = 3;
  string user_prompt = 4;
  double temperature = 5;
  int32 max_tokens = 6;
}

message StreamChunk {
  string text = 1;
  bool done = 2;
  int32 prompt_tokens = 3;
  int32 completion_tokens = 4;
}

message GenerateStructuredRequest {
  string provider = 1;
  string model = 2;
  string system_prompt = 3;
  string user_prompt = 4;
  string schema_json = 5;
  double temperature = 6;
}

message GenerateStructuredResponse {
  string json = 1;
  int32 prompt_tokens = 2;
  int32 completion_tokens = 3;
}

message ListModelsRequest {}
message ListModelsResponse {
  repeated ModelInfo models = 1;
}

message ModelInfo {
  string name = 1;
  string provider = 2;
  bool supports_stream = 3;
  bool supports_structured = 4;
}

message GetModelConfigRequest {
  string provider = 1;
}

message ModelConfig {
  string api_key = 1;
  string base_url = 2;
  string default_model = 3;
}

message EmbedRequest {
  string provider = 1;
  string model = 2;
  repeated string texts = 3;
}

message EmbedResponse {
  repeated Embedding embeddings = 1;
}

message Embedding {
  repeated float values = 1;
}
```

### ai/novel_engine.proto

```protobuf
syntax = "proto3";
package lingbi.ai;
option go_package = "github.com/xiaohai-uid/lingbi/protos/ai";

import "common/common.proto";

service NovelEngineService {
  rpc GenerateLayer1(GenerateLayer1Request) returns (SynopsisAndCharacters);
  rpc GenerateLayer2(GenerateLayer2Request) returns (ChapterOutline);
  rpc StreamLayer3(StreamLayer3Request) returns (stream ai_provider.StreamChunk);
  rpc ContinueWriting(ContinueWritingRequest) returns (stream ai_provider.StreamChunk);
  rpc Analyze(GenerateLayer1Request) returns (AnalysisResult);
}

message GenerateLayer1Request {
  string user_idea = 1;
  string genre = 2;
  string style = 3;
  int32 num_characters = 4;
}

message SynopsisAndCharacters {
  string synopsis = 1;
  repeated CharacterBrief characters = 2;
}

message CharacterBrief {
  string name = 1;
  string role = 2;
  string description = 3;
  string arc = 4;
}

message GenerateLayer2Request {
  string synopsis = 1;
  repeated CharacterBrief characters = 2;
  int32 chapter_count = 3;
}

message ChapterOutline {
  repeated ChapterSummary chapters = 1;
}

message ChapterSummary {
  string title = 1;
  string summary = 2;
  repeated string characters = 3;
  string location = 4;
  string mood = 5;
  string conflict = 6;
}

message StreamLayer3Request {
  SceneOutline scene = 1;
  string synopsis = 2;
  string character_context = 3;
  string chapter_context = 4;
}

message SceneOutline {
  string title = 1;
  string summary = 2;
  repeated string characters = 3;
  string location = 4;
  string mood = 5;
  string conflict = 6;
}

message ContinueWritingRequest {
  string text = 1;
  string context = 2;
  int32 max_new_tokens = 3;
}

message AnalysisResult {
  repeated CharacterAnalysis characters = 1;
  repeated HookPoint hooks = 2;
  string pacing = 3;
  StyleScore style = 4;
}

message CharacterAnalysis {
  string name = 1;
  int32 appearance_count = 2;
  double consistency_score = 3;
  repeated string issues = 4;
}

message HookPoint {
  int32 position = 1;
  string type = 2;
  int32 intensity = 3;
}

message StyleScore {
  double grammar = 1;
  double readability = 2;
  double genre_match = 3;
}
```

### canon/canon.proto

```protobuf
syntax = "proto3";
package lingbi.canon;
option go_package = "github.com/xiaohai-uid/lingbi/protos/canon";

import "common/common.proto";

service CanonService {
  rpc CreateCharacter(CreateCharacterRequest) returns (Character);
  rpc GetCharacter(GetCharacterRequest) returns (Character);
  rpc ListCharacters(ListCharactersRequest) returns (ListCharactersResponse);
  rpc UpdateCharacter(UpdateCharacterRequest) returns (Character);
  rpc DeleteCharacter(DeleteCharacterRequest) returns (common.Empty);

  rpc CreateLocation(CreateLocationRequest) returns (Location);
  rpc ListLocations(ListLocationsRequest) returns (ListLocationsResponse);

  rpc CreateLore(CreateLoreRequest) returns (Lore);
  rpc ListLores(ListLoresRequest) returns (ListLoresResponse);

  rpc CreateWorldRule(CreateWorldRuleRequest) returns (WorldRule);
  rpc ListWorldRules(ListWorldRulesRequest) returns (ListWorldRulesResponse);

  rpc GetRelations(GetRelationsRequest) returns (CharacterGraph);
  rpc AddRelation(AddRelationRequest) returns (CharacterEdge);
  rpc RemoveRelation(RemoveRelationRequest) returns (common.Empty);

  rpc SearchCanon(SearchCanonRequest) returns (SearchCanonResponse);
  rpc CreateTimelineEvent(CreateTimelineEventRequest) returns (TimelineEvent);
  rpc ListTimelineEvents(ListTimelineEventsRequest) returns (ListTimelineEventsResponse);
}

message Character {
  string id = 1;
  string world_id = 2;
  string name = 3;
  string description = 4;
  repeated Identity identities = 5;
  string arc = 6;
  int32 weight = 7;
}

message Identity {
  string id = 1;
  string character_id = 2;
  string name = 3;
  string period = 4;
  string description = 5;
}

message Location {
  string id = 1;
  string world_id = 2;
  string name = 3;
  string description = 4;
  double latitude = 5;
  double longitude = 6;
}

message Lore {
  string id = 1;
  string world_id = 2;
  string title = 3;
  string content = 4;
  string category = 5;
}

message WorldRule {
  string id = 1;
  string world_id = 2;
  string name = 3;
  string description = 4;
  string scope = 5;
}

message CharacterEdge {
  string source_id = 1;
  string target_id = 2;
  RelationshipType type = 3;
  int32 strength = 4;
}

enum RelationshipType {
  UNKNOWN = 0;
  ALLY = 1;
  RIVAL = 2;
  FAMILY = 3;
  ROMANCE = 4;
  MASTER = 5;
  SUBORDINATE = 6;
  NEUTRAL = 7;
}

message CharacterGraph {
  repeated Character characters = 1;
  repeated CharacterEdge edges = 2;
}

message TimelineEvent {
  string id = 1;
  string world_id = 2;
  string title = 3;
  string description = 4;
  int64 story_time = 5;
  repeated string involved_character_ids = 6;
}
```

## Generated Code

All `.proto` files will be used to generate:
- **Go**: `protoc-gen-go-grpc` → `go/pkg/lingbi-proto/`
- **Rust**: `tonic-build` → `rust/crates/lingbi-proto/src/`
- **Dart**: `protoc-gen-dart` → `lib/grpc/generated/`