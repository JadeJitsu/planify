/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 * GPL v3 — see LICENSE
 */

public class Services.Export.OmniCsvFormatter : GLib.Object {

    public string format (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        sb.append ("\"Task Name\",\"Project\",\"Context\",\"Start Date\",\"Due Date\",\"Flagged\",\"Complete\",\"Notes\"\n");

        foreach (var row in rows) {
            if (row == null) continue;
            var item = row.item;
            string flagged = (item.priority == Constants.PRIORITY_1) ? "true" : "false";

            sb.append (Services.Export.CsvFormatter.quote (item.content));        sb.append_c (',');
            sb.append (Services.Export.CsvFormatter.quote (row.project_name));    sb.append_c (',');
            sb.append (Services.Export.CsvFormatter.quote (row.section_name));    sb.append_c (',');
            sb.append ("\"\"");                                                     sb.append_c (',');
            sb.append (Services.Export.CsvFormatter.quote (item.due.date));       sb.append_c (',');
            sb.append (Services.Export.CsvFormatter.quote (flagged));             sb.append_c (',');
            sb.append (item.checked ? "\"true\"" : "\"false\"");                  sb.append_c (',');
            sb.append (Services.Export.CsvFormatter.quote (item.description));
            sb.append_c ('\n');
        }

        return sb.str;
    }
}
