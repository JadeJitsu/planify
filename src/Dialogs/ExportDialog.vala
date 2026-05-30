/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Dialogs.ExportDialog : Adw.Dialog {
    private Objects.Project? export_project;
    private Adw.ComboRow format_row;
    private Adw.SwitchRow completed_row;
    private Gtk.Button export_button;
    private Gtk.Spinner spinner;

    private static Services.Export.ExportFormat[] FORMATS = {
        Services.Export.ExportFormat.CSV,
        Services.Export.ExportFormat.ODS,
        Services.Export.ExportFormat.MARKDOWN,
        Services.Export.ExportFormat.OMNI_OPML,
        Services.Export.ExportFormat.OMNI_TASKPAPER,
        Services.Export.ExportFormat.OMNI_CSV
    };

    public ExportDialog (Objects.Project? project = null) {
        Object (
            title: _("Export"),
            content_width: 480
        );
        export_project = project;
    }

    ~ExportDialog () {
        debug ("Destroying - Dialogs.ExportDialog\n");
    }

    construct {
        var scope_row = new Adw.ActionRow () {
            title = _("Export scope"),
            activatable = false
        };

        var names = new string[FORMATS.length];
        for (int i = 0; i < FORMATS.length; i++) {
            names[i] = FORMATS[i].display_name ();
        }
        var format_model = new Gtk.StringList (names);
        format_row = new Adw.ComboRow () {
            title = _("Format"),
            model = format_model,
            selected = 0
        };

        completed_row = new Adw.SwitchRow () {
            title = _("Include completed tasks"),
            active = false
        };

        var group = new Adw.PreferencesGroup ();
        group.add (scope_row);
        group.add (format_row);
        group.add (completed_row);

        spinner = new Gtk.Spinner ();

        export_button = new Gtk.Button.with_label (_("Export")) {
            css_classes = { "suggested-action", "pill" },
            halign = Gtk.Align.CENTER,
            margin_top = 12
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12, margin_bottom = 24,
            margin_start = 12, margin_end = 12
        };
        content_box.append (group);
        content_box.append (spinner);
        content_box.append (export_button);

        var toolbar = new Adw.ToolbarView ();
        toolbar.add_top_bar (new Adw.HeaderBar ());
        toolbar.content = content_box;
        child = toolbar;

        export_button.clicked.connect (on_export_clicked);

        // Set subtitle after the Object() constructor properties are applied
        // (export_project is set in the non-Object constructor, so use map)
        map.connect (() => {
            scope_row.subtitle = export_project != null
                ? export_project.name
                : _("All projects");
        });
    }

    private void on_export_clicked () {
        var format = FORMATS[format_row.selected];

        var file_dialog = new Gtk.FileDialog () {
            initial_name = "planify-export.%s".printf (format.extension ()),
            modal = true
        };

        file_dialog.save.begin (null, null, (obj, res) => {
            GLib.File? file = null;
            try {
                file = file_dialog.save.end (res);
            } catch (Error e) {
                return; // user cancelled
            }

            export_button.sensitive = false;
            spinner.spinning = true;

            Gee.ArrayList<Objects.Project> projects;
            if (export_project != null) {
                projects = new Gee.ArrayList<Objects.Project> ();
                projects.add (export_project);
            } else {
                projects = Services.Store.instance ().projects;
            }

            bool include_completed = completed_row.active;

            Services.ExportService.get_default ().export_to_file_async.begin (
                file, projects, include_completed, format,
                (obj2, res2) =>
            {
                bool ok = Services.ExportService.get_default ()
                    .export_to_file_async.end (res2);

                spinner.spinning = false;
                export_button.sensitive = true;

                string basename = file.get_basename ();
                if (ok) {
                    Services.EventBus.get_default ().send_toast (
                        Util.get_default ().create_toast (
                            _("Exported to %s").printf (basename)));
                    close ();
                } else {
                    Services.EventBus.get_default ().send_toast (
                        Util.get_default ().create_toast (_("Export failed")));
                }
            });
        });
    }
}
