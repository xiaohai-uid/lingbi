/// Persisted schema versions used by project and settings migrations.
///
/// Bump a value only when its corresponding migration and legacy fixture
/// tests are committed in the same change.
abstract final class SchemaVersions {
  static const int project = 2;
  static const int settings = 2;
  static const int portablePackage = 1;
}
