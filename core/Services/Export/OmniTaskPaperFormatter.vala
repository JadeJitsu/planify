/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.Export.OmniTaskPaperFormatter : GLib.Object {

    public string format (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        string today = new GLib.DateTime.now_local ().format ("%Y-%m-%d");
        string current_project = null;

        foreach (var row in rows) {
            if (row == null) continue;

            if (row.project_name != current_project) {
                current_project = row.project_name;
                sb.append (current_project);
                sb.append (":\n");
            }

            var item = row.item;
            string context = row.section_name != "" ? row.section_name : row.project_name;

            sb.append ("\t- ");
            sb.append (item.content);

            if (item.due.date != "") {
                sb.append (" @due("); sb.append (item.due.date); sb.append (")");
            }
            string plabel = Services.Export.CsvFormatter.priority_to_label (item.priority);
            if (plabel != "") {
                sb.append (" @priority("); sb.append (plabel); sb.append (")");
            }
            if (context != "") {
                sb.append (" @context("); sb.append (context); sb.append (")");
            }
            if (item.checked) {
                string done_date = (item.completed_at != "" && item.completed_at.length >= 10)
                    ? item.completed_at.substring (0, 10)
                    : today;
                sb.append (" @done("); sb.append (done_date); sb.append (")");
            }
            sb.append_c ('\n');
        }

        return sb.str;
    }
}
