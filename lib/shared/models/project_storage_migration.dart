/// Summary of a portable-project storage migration.
class ProjectStorageMigrationResult {
  const ProjectStorageMigrationResult({
    required this.migrated,
    required this.failed,
  });

  final int migrated;
  final int failed;
}
