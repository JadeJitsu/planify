/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.Export.MarkdownFormatter : GLib.Object {

    public string format (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        string current_project = null;
        string current_section = null;

        foreach (var row in rows) {
            if (row == null) continue;

            if (row.project_name != current_project) {
                current_project = row.project_name;
                current_section = null;
                sb.append ("\n## "); sb.append (current_project); sb.append ("\n\n");
            }

            if (row.section_name != current_section) {
                current_section = row.section_name;
                if (current_section != "") {
                    sb.append ("### "); sb.append (current_section); sb.append ("\n\n");
                }
            }

            append_task (sb, row.item, "");
        }

        return sb.str.chug ();
    }

    private void append_task (GLib.StringBuilder sb, Objects.Item item, string indent) {
        sb.append (indent);
        sb.append (item.checked ? "- [x] " : "- [ ] ");
        sb.append (item.content);

        var meta = new Gee.ArrayList<string> ();
        if (item.due.date != "") meta.add ("due:" + item.due.date);
        string plabel = Services.Export.CsvFormatter.priority_to_label (item.priority);
        if (plabel != "") meta.add ("priority:" + plabel);
        if (!meta.is_empty) {
            sb.append (" <!-- ");
            sb.append (string.joinv (" ", meta.to_array ()));
            sb.append (" -->");
        }
        sb.append_c ('\n');

        foreach (var sub in item.items) {
            append_task (sb, sub, indent + "  ");
        }
    }
}
