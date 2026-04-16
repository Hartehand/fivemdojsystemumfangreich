CREATE TABLE IF NOT EXISTS doj_cases (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_number VARCHAR(40) NOT NULL,
  sequence_no INT UNSIGNED NOT NULL,
  case_type VARCHAR(32) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NULL,
  status VARCHAR(64) NOT NULL DEFAULT 'draft',
  priority VARCHAR(32) NOT NULL DEFAULT 'normal',
  category VARCHAR(64) NULL,
  department VARCHAR(128) NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  lead_identifier VARCHAR(80) NULL,
  lead_name VARCHAR(128) NULL,
  tags JSON NULL,
  confidential TINYINT(1) NOT NULL DEFAULT 0,
  is_sealed TINYINT(1) NOT NULL DEFAULT 0,
  sealed_by_identifier VARCHAR(80) NULL,
  sealed_by_name VARCHAR(128) NULL,
  sealed_at TIMESTAMP NULL,
  sealed_reason VARCHAR(255) NULL,
  unsealed_by_identifier VARCHAR(80) NULL,
  unsealed_by_name VARCHAR(128) NULL,
  unsealed_at TIMESTAMP NULL,
  unsealed_reason VARCHAR(255) NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  closed_at TIMESTAMP NULL,
  archived_at TIMESTAMP NULL,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_case_number (case_number),
  KEY idx_case_status (status),
  KEY idx_case_type (case_type),
  KEY idx_case_priority (priority),
  KEY idx_case_created (created_at),
  KEY idx_case_updated (updated_at),
  KEY idx_case_sealed (is_sealed),
  KEY idx_case_department (department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_templates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  template_key VARCHAR(80) NOT NULL,
  display_name VARCHAR(128) NOT NULL,
  case_type VARCHAR(32) NOT NULL,
  default_title VARCHAR(255) NULL,
  default_status VARCHAR(64) NULL,
  default_tags JSON NULL,
  recommended_evidence_types JSON NULL,
  recommended_roles JSON NULL,
  checklist JSON NULL,
  timeline_milestones JSON NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_template_key (template_key),
  KEY idx_template_case_type (case_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_template_tasks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  template_id BIGINT UNSIGNED NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NULL,
  default_status VARCHAR(32) NOT NULL DEFAULT 'open',
  metadata JSON NULL,
  PRIMARY KEY (id),
  KEY idx_template_tasks_template (template_id),
  CONSTRAINT fk_template_tasks_template FOREIGN KEY (template_id) REFERENCES doj_case_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_template_documents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  template_id BIGINT UNSIGNED NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  title VARCHAR(255) NOT NULL,
  document_type VARCHAR(64) NOT NULL,
  metadata JSON NULL,
  PRIMARY KEY (id),
  KEY idx_template_documents_template (template_id),
  CONSTRAINT fk_template_documents_template FOREIGN KEY (template_id) REFERENCES doj_case_templates(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_links (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  linked_case_id BIGINT UNSIGNED NOT NULL,
  relation_type VARCHAR(64) NOT NULL,
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_case_link (case_id, linked_case_id, relation_type),
  KEY idx_case_links_case (case_id),
  KEY idx_case_links_related (linked_case_id),
  CONSTRAINT fk_case_links_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_case_links_related FOREIGN KEY (linked_case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_people (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  citizen_identifier VARCHAR(80) NOT NULL,
  full_name VARCHAR(128) NULL,
  role_type VARCHAR(64) NOT NULL,
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_people_case (case_id),
  KEY idx_case_people_identifier (citizen_identifier),
  CONSTRAINT fk_case_people_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_vehicles (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  plate VARCHAR(16) NOT NULL,
  vin VARCHAR(64) NULL,
  model VARCHAR(80) NULL,
  role_type VARCHAR(64) NOT NULL DEFAULT 'related_vehicle',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_vehicles_case (case_id),
  KEY idx_case_vehicles_plate (plate),
  KEY idx_case_vehicles_vin (vin),
  CONSTRAINT fk_case_vehicles_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_weapons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  serial_number VARCHAR(80) NOT NULL,
  weapon_type VARCHAR(80) NULL,
  role_type VARCHAR(64) NOT NULL DEFAULT 'related_weapon',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_weapons_case (case_id),
  KEY idx_case_weapons_serial (serial_number),
  CONSTRAINT fk_case_weapons_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_evidence (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  evidence_number VARCHAR(40) NOT NULL,
  sequence_no INT UNSIGNED NOT NULL,
  evidence_type VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NULL,
  location_found VARCHAR(255) NULL,
  storage_location VARCHAR(255) NULL,
  status VARCHAR(64) NOT NULL DEFAULT 'checked_in',
  collected_by_identifier VARCHAR(80) NOT NULL,
  collected_by_name VARCHAR(128) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_evidence_number (evidence_number),
  KEY idx_evidence_status (status),
  KEY idx_evidence_type (evidence_type),
  KEY idx_evidence_created (created_at),
  KEY idx_evidence_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_evidence (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  evidence_id BIGINT UNSIGNED NOT NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'supporting_evidence',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_case_evidence (case_id, evidence_id, relation_type),
  KEY idx_case_evidence_case (case_id),
  KEY idx_case_evidence_evidence (evidence_id),
  CONSTRAINT fk_case_evidence_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_case_evidence_evidence FOREIGN KEY (evidence_id) REFERENCES doj_evidence(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_charges (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  charge_id BIGINT UNSIGNED NOT NULL,
  charge_title VARCHAR(255) NULL,
  charge_category VARCHAR(64) NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'related_charge',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_charges_case (case_id),
  KEY idx_case_charges_charge (charge_id),
  CONSTRAINT fk_case_charges_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_incidents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  incident_id BIGINT UNSIGNED NOT NULL,
  incident_number VARCHAR(64) NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'linked_incident',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_incidents_case (case_id),
  KEY idx_case_incidents_incident (incident_id),
  CONSTRAINT fk_case_incidents_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_warrants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  warrant_id BIGINT UNSIGNED NOT NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'linked_warrant',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_warrants_case (case_id),
  KEY idx_case_warrants_warrant (warrant_id),
  CONSTRAINT fk_case_warrants_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_documents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  document_type VARCHAR(64) NOT NULL,
  content LONGTEXT NOT NULL,
  current_version_id BIGINT UNSIGNED NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  is_final TINYINT(1) NOT NULL DEFAULT 0,
  sign_off_role VARCHAR(64) NULL,
  signature_policy JSON NULL,
  final_signature JSON NULL,
  finalised_by_identifier VARCHAR(80) NULL,
  finalised_by_name VARCHAR(128) NULL,
  finalised_at TIMESTAMP NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_documents_type (document_type),
  KEY idx_documents_status (status),
  KEY idx_documents_created (created_at),
  KEY idx_documents_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_document_versions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  document_id BIGINT UNSIGNED NOT NULL,
  version_number INT UNSIGNED NOT NULL,
  content LONGTEXT NOT NULL,
  edited_by_identifier VARCHAR(80) NOT NULL,
  edited_by_name VARCHAR(128) NOT NULL,
  change_note VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_document_version (document_id, version_number),
  CONSTRAINT fk_document_versions_document FOREIGN KEY (document_id) REFERENCES doj_documents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_document_signatures (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  document_id BIGINT UNSIGNED NOT NULL,
  document_version_id BIGINT UNSIGNED NOT NULL,
  signer_identifier VARCHAR(80) NOT NULL,
  signer_name VARCHAR(128) NOT NULL,
  signer_role VARCHAR(64) NOT NULL,
  signed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  signature_hash CHAR(64) NOT NULL,
  note VARCHAR(255) NULL,
  metadata JSON NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_document_signature_slot (document_version_id, signer_role),
  KEY idx_document_signatures_document (document_id),
  KEY idx_document_signatures_version (document_version_id),
  CONSTRAINT fk_document_signatures_document FOREIGN KEY (document_id) REFERENCES doj_documents(id) ON DELETE CASCADE,
  CONSTRAINT fk_document_signatures_version FOREIGN KEY (document_version_id) REFERENCES doj_document_versions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_documents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  document_id BIGINT UNSIGNED NOT NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'related_document',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_case_document (case_id, document_id, relation_type),
  CONSTRAINT fk_case_documents_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_case_documents_document FOREIGN KEY (document_id) REFERENCES doj_documents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_notes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_type VARCHAR(64) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  visibility VARCHAR(16) NOT NULL DEFAULT 'team',
  content LONGTEXT NOT NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_notes_entity (entity_type, entity_id),
  KEY idx_notes_created (created_at),
  KEY idx_notes_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_note_versions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  note_id BIGINT UNSIGNED NOT NULL,
  version_number INT UNSIGNED NOT NULL,
  content LONGTEXT NOT NULL,
  edited_by_identifier VARCHAR(80) NOT NULL,
  edited_by_name VARCHAR(128) NOT NULL,
  change_note VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_note_version (note_id, version_number),
  CONSTRAINT fk_note_versions_note FOREIGN KEY (note_id) REFERENCES doj_notes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_notes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  note_id BIGINT UNSIGNED NOT NULL,
  relation_type VARCHAR(64) NOT NULL DEFAULT 'case_note',
  metadata JSON NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_case_notes_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_case_notes_note FOREIGN KEY (note_id) REFERENCES doj_notes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_courtrooms (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  room_code VARCHAR(32) NOT NULL,
  label VARCHAR(128) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_courtroom_code (room_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_hearings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  hearing_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'scheduled',
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  courtroom_id BIGINT UNSIGNED NULL,
  judge_identifier VARCHAR(80) NULL,
  judge_name VARCHAR(128) NULL,
  prosecutor_identifier VARCHAR(80) NULL,
  prosecutor_name VARCHAR(128) NULL,
  defense_identifier VARCHAR(80) NULL,
  defense_name VARCHAR(128) NULL,
  outcome LONGTEXT NULL,
  notes LONGTEXT NULL,
  reminder_state VARCHAR(32) NULL,
  conflict_override TINYINT(1) NOT NULL DEFAULT 0,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_hearings_case (case_id),
  KEY idx_hearings_status (status),
  KEY idx_hearings_type (hearing_type),
  KEY idx_hearings_start (start_at),
  KEY idx_hearings_end (end_at),
  KEY idx_hearings_judge (judge_identifier),
  KEY idx_hearings_prosecutor (prosecutor_identifier),
  KEY idx_hearings_defense (defense_identifier),
  KEY idx_hearings_courtroom (courtroom_id),
  CONSTRAINT fk_hearings_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE,
  CONSTRAINT fk_hearings_courtroom FOREIGN KEY (courtroom_id) REFERENCES doj_courtrooms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_hearing_participants (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  hearing_id BIGINT UNSIGNED NOT NULL,
  participant_identifier VARCHAR(80) NOT NULL,
  participant_name VARCHAR(128) NOT NULL,
  participant_role VARCHAR(64) NOT NULL,
  attendance_status VARCHAR(32) NOT NULL DEFAULT 'expected',
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_hearing_participants_hearing (hearing_id),
  KEY idx_hearing_participants_identifier (participant_identifier),
  CONSTRAINT fk_hearing_participants_hearing FOREIGN KEY (hearing_id) REFERENCES doj_hearings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_timeline (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  event_label VARCHAR(255) NOT NULL,
  actor_identifier VARCHAR(80) NOT NULL,
  actor_name VARCHAR(128) NOT NULL,
  actor_session VARCHAR(64) NULL,
  old_value JSON NULL,
  new_value JSON NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_case_timeline_case (case_id, created_at),
  CONSTRAINT fk_case_timeline_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_evidence_custody (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  evidence_id BIGINT UNSIGNED NOT NULL,
  action_type VARCHAR(32) NOT NULL,
  from_person_identifier VARCHAR(80) NULL,
  to_person_identifier VARCHAR(80) NULL,
  from_location VARCHAR(255) NULL,
  to_location VARCHAR(255) NULL,
  reason_note LONGTEXT NULL,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  previous_hash CHAR(64) NOT NULL,
  entry_hash CHAR(64) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_custody_evidence (evidence_id, created_at),
  KEY idx_custody_entry_hash (entry_hash),
  CONSTRAINT fk_doj_evidence_custody_evidence FOREIGN KEY (evidence_id) REFERENCES doj_evidence(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_audit_log (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  action VARCHAR(128) NOT NULL,
  entity_type VARCHAR(64) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  actor_identifier VARCHAR(80) NOT NULL,
  actor_name VARCHAR(128) NOT NULL,
  actor_session VARCHAR(64) NULL,
  old_value JSON NULL,
  new_value JSON NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_entity (entity_type, entity_id),
  KEY idx_audit_actor (actor_identifier, created_at),
  KEY idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_exports (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  exported_by_identifier VARCHAR(80) NOT NULL,
  exported_by_name VARCHAR(128) NOT NULL,
  profile VARCHAR(32) NOT NULL,
  format VARCHAR(32) NOT NULL,
  export_payload LONGTEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_case_exports_case (case_id),
  KEY idx_case_exports_created (created_at),
  CONSTRAINT fk_case_exports_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_saved_filters (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_identifier VARCHAR(80) NOT NULL,
  name VARCHAR(80) NOT NULL,
  module VARCHAR(40) NOT NULL DEFAULT 'cases',
  filter_payload JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_saved_filters_owner (owner_identifier),
  KEY idx_saved_filters_module (module)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_tasks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NULL,
  due_at DATETIME NULL,
  assigned_identifier VARCHAR(80) NULL,
  assigned_name VARCHAR(128) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'open',
  reminder_enabled TINYINT(1) NOT NULL DEFAULT 0,
  created_by_identifier VARCHAR(80) NOT NULL,
  created_by_name VARCHAR(128) NOT NULL,
  metadata JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_case_tasks_case (case_id),
  KEY idx_case_tasks_due (due_at),
  KEY idx_case_tasks_status (status),
  CONSTRAINT fk_case_tasks_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS doj_case_watchers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  case_id BIGINT UNSIGNED NOT NULL,
  watcher_identifier VARCHAR(80) NOT NULL,
  watcher_name VARCHAR(128) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_case_watcher (case_id, watcher_identifier),
  KEY idx_case_watchers_identifier (watcher_identifier),
  CONSTRAINT fk_case_watchers_case FOREIGN KEY (case_id) REFERENCES doj_cases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
