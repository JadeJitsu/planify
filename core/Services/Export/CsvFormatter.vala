/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public enum Services.Export.ExportFormat {
    CSV,
    ODS,
    MARKDOWN,
    OMNI_OPML,
    OMNI_TASKPAPER,
    OMNI_CSV;

    public string extension () {
        switch (this) {
            case CSV:            return "csv";
            case ODS:            return "ods";
            case MARKDOWN:       return "md";
            case OMNI_OPML:      return "opml";
            case OMNI_TASKPAPER: return "taskpaper";
            case OMNI_CSV:       return "csv";
            default:             return "txt";
        }
    }

    public string display_name () {
        switch (this) {
            case CSV:            return _("CSV");
            case ODS:            return _("ODS (Spreadsheet)");
            case MARKDOWN:       return _("Markdown");
            case OMNI_OPML:      return _("OmniFocus OPML");
            case OMNI_TASKPAPER: return _("OmniFocus TaskPaper");
            case OMNI_CSV:       return _("OmniFocus CSV");
            default:             return "Unknown";
        }
    }
}

public struct Services.Export.ExportRow {
    public string project_name;
    public string section_name;
    public Objects.Item item;
}

public class Services.Export.CsvFormatter : GLib.Object {

    public string format (Gee.ArrayList<Services.Export.ExportRow?> rows) {
        var sb = new GLib.StringBuilder ();
        sb.append ("\"Project\",\"Section\",\"Task\",\"Notes\",\"Due Date\",\"Priority\",\"Labels\",\"Completed\"\n");

        foreach (var row in rows) {
            if (row == null) continue;
            var item = row.item;
            sb.append (quote (row.project_name));                    sb.append_c (',');
            sb.append (quote (row.section_name));                    sb.append_c (',');
            sb.append (quote (item.content));                        sb.append_c (',');
            sb.append (quote (item.description));                    sb.append_c (',');
            sb.append (quote (item.due.date));                       sb.append_c (',');
            sb.append (quote (priority_to_label (item.priority)));   sb.append_c (',');
            sb.append (quote (build_labels_string (item)));          sb.append_c (',');
            sb.append (item.checked ? "\"true\"" : "\"false\"");
            sb.append_c ('\n');
        }

        return sb.str;
    }

    internal static string priority_to_label (int priority) {
        if (priority == Constants.PRIORITY_1) return "P1";
        if (priority == Constants.PRIORITY_2) return "P2";
        if (priority == Constants.PRIORITY_3) return "P3";
        return "";
    }

    internal static string build_labels_string (Objects.Item item) {
        var names = new Gee.ArrayList<string> ();
        foreach (var label in item.labels) {
            names.add (label.name);
        }
        return string.joinv (",", names.to_array ());
    }

    internal static string quote (string s) {
        return "\"" + s.replace ("\"", "\"\"") + "\"";
    }

    internal static string escape_xml (string s) {
        return s
            .replace ("&",  "&amp;")
            .replace ("<",  "&lt;")
            .replace (">",  "&gt;")
            .replace ("\"", "&quot;");
    }
}
