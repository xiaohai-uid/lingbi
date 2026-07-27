/// Collaboration roles for studio workflows.
library;

enum CollaborationRole {
  owner,
  editor,
  reviewer,
  viewer;

  bool get canEdit => this == owner || this == editor;
  bool get canReview => this == owner || this == editor || this == reviewer;
  bool get canApprove => this == owner || this == reviewer;
  bool get canManageRoles => this == owner;
  bool get canDelete => this == owner;
}

enum CollaborationAction {
  edit,
  review,
  approve,
  manageRoles,
  delete;

  bool isAllowedBy(CollaborationRole role) => switch (this) {
        CollaborationAction.edit => role.canEdit,
        CollaborationAction.review => role.canReview,
        CollaborationAction.approve => role.canApprove,
        CollaborationAction.manageRoles => role.canManageRoles,
        CollaborationAction.delete => role.canDelete,
      };
}
