/// Extension methods for Volume to provide child collection access
library;

import '../../../data/database/world_database.dart';

extension VolumeExtensions on Volume {
  /// Get chapters for this volume (empty list placeholder)
  List<Chapter> get chapters => [];
}

/// Extension methods for Chapter to provide child collection access
extension ChapterExtensions on Chapter {
  /// Get scenes for this chapter (empty list placeholder)
  List<Scene> get scenes => [];
}
