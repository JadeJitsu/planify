# Export Feature — Design Spec
**Date:** 2026-05-29
**Scope:** Sub-project 2 of 2. Sub-project 1 (Claude AI Integration) is a separate spec/branch.

---

## 1. Architecture

New folder: `core/Services/Export/`

| File | Responsibility |
|------|---------------|
| `ExportService.vala` | Singleton. Collects projects + `ExportOptions`, routes to the correct formatter, writes the output file via `GLib.File.replace_contents()`. The only file that touches the filesystem. |
| `CsvFormatter.vala` | Returns `string` — flat UTF-8 CSV, one row per task |
| `OdsFormatter.vala` | Returns `uint8[]` — OpenDocument Spreadsheet ZIP. Requires **libarchive** as a new build dependency (universally available; included in GNOME Flatpak SDK). |
| `MarkdownFormatter.vala` | Returns `string` — `##` project headings, `###` section headings, `- [ ]` / `- [x]` task lines |
| `OmniOpmlFormatter.vala` | Returns `string` — OPML 2.0 XML with nested `<outline>` nodes |
| `OmniTaskPaperFormatter.vala` | Returns `string` — OmniFocus TaskPaper plain text |
| `OmniCsvFormatter.vala` | Returns `string` — OmniFocus-flavored CSV with OmniFocus-specific column names |

**`ExportOptions` struct** (defined in `ExportService.vala`):
```vala
public struct Services.Export.ExportOptions {
    public Gee.ArrayList<Objects.Project> projects;
    public bool include_completed;
}
```

All formatters are **stateless**: `new CsvFormatter().format(projects, options)` — no singletons. No network calls. Works fully offline.

**`ExportFormat` enum** (defined in `ExportService.vala`):
```vala
public enum Services.Export.ExportFormat {
    CSV,
    ODS,
    MARKDOWN,
    OMNI_OPML,
    OMNI_TASKPAPER,
    OMNI_CSV
}
```

**New build dependency:** `libarchive` — required only for ODS. Already present in GNOME Flatpak SDK and packaged on all major distros.

---

## 2. UI Surfaces

### 2a. Export dialog (`src/Dialogs/ExportDialog.vala`, new)

`Adw.Dialog`, `content_width: 560`.

Three rows inside an `Adw.PreferencesGroup`:

- **Scope** — `Adw.ActionRow` (non-activatable), title "Export scope", subtitle = "All projects" or the specific project name. Set at construction time.
- **Format** — `Adw.ComboRow`, title "Format", 6 options in order:
  1. CSV (`.csv`)
  2. ODS (`.ods`)
  3. Markdown (`.md`)
  4. OmniFocus OPML (`.opml`)
  5. OmniFocus TaskPaper (`.taskpaper`)
  6. OmniFocus CSV (`.csv`)
- **Include completed tasks** — `Adw.SwitchRow`, default **off**

An "Export" button (`suggested-action`) below the group. Clicking it:
1. Opens `Gtk.FileDialog.save()` with a default filename of `planify-export.<ext>` (extension determined by selected format)
2. On file chosen: calls `ExportService.export_async()`, shows spinner on button
3. On success: dismisses dialog, shows `Adw.Toast` "Exported to filename" on the main window
4. On error: shows `Adw.Toast` with error message, keeps dialog open

Export button disabled when project list is empty.

**Constructor signature:**
```vala
public ExportDialog (Objects.Project? project = null)
```
`null` = all projects; non-null = single project export.

### 2b. App menu (`src/MainWindow.vala`)

"Export…" added to `build_menu_app()` directly below the existing "Import Tasks…" item. Opens `new ExportDialog (null)`.

### 2c. Per-project context menu (`src/Layouts/ProjectRow.vala`)

"Export project…" added to the project row's existing context menu (find the `build_context_menu()` or equivalent method). Opens `new ExportDialog (project)`.

---

## 3. Data Flow & Format Specs

```
ExportDialog "Export" clicked
  → Gtk.FileDialog.save() → GLib.File chosen
  → ExportService.export_async(file, options, format)
    → formatter.format(options) → string or uint8[]
    → file.replace_contents() or file.replace_contents_bytes()
  → export_completed signal → main window toast
```

### CSV

UTF-8, comma-separated, all fields double-quoted. Header row always included.

```
"Project","Section","Task","Notes","Due Date","Priority","Labels","Completed"
"Work","Inbox","Buy milk","","2026-05-30","4","grocery,food","false"
```

- `Section` is empty string if task has no section
- `Priority` exported as integer (1–4); 1 = none, 4 = urgent (internal Planify scale)
- `Labels` is comma-separated label names
- `Completed` is `"true"` / `"false"`

### ODS

Single sheet named "Tasks". Same column layout as CSV. Assembled as a ZIP via libarchive containing:
- `mimetype` (uncompressed, first entry): `application/vnd.oasis.opendocument.spreadsheet`
- `META-INF/manifest.xml` — standard ODS manifest
- `content.xml` — table rows generated with `GLib.StringBuilder` directly

### Markdown

```markdown
## Work

### Inbox

- [ ] Buy milk <!-- due:2026-05-30 priority:4 -->
- [x] Team standup

### Planning

- [ ] Write report <!-- due:2026-06-01 -->

## Personal

- [ ] Call dentist
```

Due date and priority appended as HTML comments if set. Completed tasks use `- [x]`.

### OmniFocus OPML

Standard OPML 2.0:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head><title>Planify Export</title></head>
  <body>
    <outline text="Work">
      <outline text="Inbox">
        <outline text="Buy milk" due="2026-05-30" priority="4" note=""/>
      </outline>
    </outline>
  </body>
</opml>
```

### OmniFocus TaskPaper

```
Work:
	- Buy milk @due(2026-05-30) @priority(4) @context(Inbox)
	- Team standup @done(2026-05-29)

Personal:
	- Call dentist
```

- Section name used as `@context` value
- Completed tasks get `@done(date)` using `completed_at`; if no date available, uses today

### OmniFocus CSV

Column names exactly as OmniFocus expects:

```
"Task Name","Project","Context","Start Date","Due Date","Flagged","Complete","Notes"
"Buy milk","Work","Inbox","","2026-05-30","true","false",""
```

- `Context` = section name (empty if no section)
- `Flagged` = `"true"` when priority == `Constants.PRIORITY_1` (= int 4, urgent); `"false"` otherwise
- `Complete` = `"true"` / `"false"` based on `item.checked`

---

## 4. Error Handling

| Scenario | Behaviour |
|----------|-----------|
| User cancels file dialog | No action, export dialog stays open |
| File write fails (permissions, disk full) | Toast on export dialog: "Export failed: [error message]"; dialog stays open |
| Project has no tasks | File created with header row only (CSV/ODS) or empty headings (Markdown/OmniFocus); no error |
| libarchive ODS assembly fails | Toast: "ODS export failed — try CSV instead" |
| No projects (all-project export) | "Export" button disabled |

---

## Out of Scope

- Claude AI dependency — all formatters are pure data transformation, no API calls
- Selective task export (by label, date range, etc.) — export always covers full project structure
- Excel `.xlsx` format — ODS covers the spreadsheet use case and opens natively in Excel
