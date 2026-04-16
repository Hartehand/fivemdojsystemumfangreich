# doj_casehub

Produktionsreifes DOJ Case-Management für ESX + oxmysql mit eigener `doj_*` Datenhaltung, Tablet-NUI und optionalen Integrationen zu `wasabi_mdt` und `vms_cityhall`.

## Architektur

- **Client**: `/doj`, Tablet-Lifecycle (Prop/Anim/Cleanup), NUI-Callbacks.
- **Server Core**: abgesicherte ESX-Callbacks, Dashboard, Fehlerbehandlung, Audit/Timeline.
- **Domain-Module**:
  - `cases`: Case-Workflow, Filter/Suche, Parent/Child, Tasks, Seal/Unseal
  - `calendar` + `hearings`: Gerichtskalender + serverseitige Konfliktprüfung
  - `evidence`: Chain-of-Custody mit Hash-Kette
  - `documents` + `signatures`: versionierte Dokumente + digitale Signaturen
  - `templates`: Fallvorlagen (Verkehrsunfall, Raub, Mord)
  - `export`: strukturierter Fall-Export + Export-Logging
- **DB**: Vollständige `sql/doj_casehub.sql` mit FK/Index/Soft-Delete und erweiterten Tabellen für Templates, Signaturen, Exporte.

## Kernmerkmale

- Zwei Falltypen: `criminal_case`, `court_case`
- Parent/Child Case-Beziehungen
- Vollständige Link-Tabellen (`doj_case_people`, `doj_case_vehicles`, ...)
- Globale Suche + Saved Filters
- Dashboard-Kacheln (offene Fälle, Hearings heute, neue Beweise, versiegelte Fälle, überfällige Tasks)
- Court-Calendar mit Konfliktprüfung (Richter/Prosecutor/Defense/Courtroom + Buffer)
- Revisionssichere Evidence Chain (`previous_hash`, `entry_hash`, Verify)
- Dokumentversionierung + versionsbezogene digitale Signaturen
- Seal/Unseal mit High-Role-Prüfung und Audit
- Exportprofile (compact/full/redacted) + Print/PDF-fähige Ausgabe über Print-View

## Installation

1. Resource als `doj_casehub` in den resources-Ordner legen
2. `sql/doj_casehub.sql` importieren
3. In `server.cfg`:
   - `ensure oxmysql`
   - `ensure es_extended`
   - `ensure doj_casehub`
4. `config.lua` auf deinen Stack abstimmen
